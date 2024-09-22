#NIVEL 1
#Crear Base de datos
CREATE DATABASE transactions_db;
USE transactions_db;

# Tabla users
CREATE TABLE IF NOT EXISTS users ( 
    id VARCHAR(3) PRIMARY KEY,
    name VARCHAR(50),
    surname VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(50),
    birth_date VARCHAR(20),
    country VARCHAR(20),
    city VARCHAR(30),
    postal_code VARCHAR(25),
    address VARCHAR(50)
);


#inserción de datos de los 3 archivos csv para users
LOAD DATA  INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv"
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv"
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv"
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;



# Tabla credit_cards
CREATE TABLE IF NOT EXISTS credit_cards (
    id CHAR(8) PRIMARY KEY,
    user_id CHAR(3),
    iban VARCHAR(34),
    pan VARCHAR(19),
    pin CHAR(4),
    cvv CHAR(3),
    track1 VARCHAR(50),
    track2 VARCHAR(50),
    expiring_date VARCHAR(10),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

#carga de datos para credit_cards
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv"
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

# Tabla companies
CREATE TABLE IF NOT EXISTS companies (
    id CHAR(10) PRIMARY KEY,
    company_name VARCHAR(35),
    phone VARCHAR(30),
    email VARCHAR(40),
    country VARCHAR(30),
    website VARCHAR(50)
);

#carga de datos para credit_cards
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv"
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

# Tabla transactions
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(150),
    card_id VARCHAR(100),
    company_id VARCHAR(100),
    timestamp TIMESTAMP,
    amount VARCHAR(100),
    declined VARCHAR(100),
    product_ids VARCHAR(100),
    user_id VARCHAR(100),
    lat FLOAT,
    longitude FLOAT,
    FOREIGN KEY (card_id) REFERENCES credit_cards(id),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Disable foreign key checks
SET FOREIGN_KEY_CHECKS = 0;

#carga de datos para credit_cards
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;


#Ejercicio 1
SELECT name, surname
FROM users
WHERE id IN (
    SELECT user_id
    FROM transactions
    GROUP BY user_id
    HAVING COUNT(id) > 30
);

#Ejercicio 2
SELECT cc.iban, ROUND(AVG(t.amount), 2) AS avg_amount
FROM transactions t
JOIN credit_cards cc ON cc.id = t.card_id
JOIN companies c ON t.company_id = c.id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban;

#NIVEL 2
#Ejercicio 1
CREATE TABLE IF NOT EXISTS card_status (
    card_id CHAR(8) PRIMARY KEY,
    status VARCHAR(20),
    FOREIGN KEY (card_id) REFERENCES credit_cards(id)
);

#Insertar valores de status según las tres últimas transacciones
INSERT INTO card_status (card_id, status)
SELECT card_id, CASE WHEN SUM(declined) = COUNT(*) THEN 'not activated' ELSE 'activated' END AS status
FROM (SELECT card_id, declined, timestamp, 
             ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS row_num
      FROM transactions) AS LastThreeTransactions
WHERE row_num <= 3
GROUP BY card_id;

SELECT *
FROM card_status;

#Número de tarjetas activas
SELECT COUNT(*) AS active_cards
FROM card_status
WHERE status = 'activated';

# NIVEL 3
# Ejercicio 1
CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(100) PRIMARY KEY,
    product_name VARCHAR(50),
    price VARCHAR(20),
    colour CHAR(7),
    weight DECIMAL(4, 1),
    warehouse_id VARCHAR(10)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv"
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

SELECT * 
FROM products;


#Crear un índice en la tabla de referencia si no existe
ALTER TABLE transactions ADD INDEX (id);

# Crear la tabla puente transaction_products
CREATE TABLE IF NOT EXISTS transaction_products (
    transaction_id VARCHAR(255),
    product_id VARCHAR(100),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

# Insertar los resultados descompuestos en la tabla transaction_product
INSERT INTO transaction_products (transaction_id, product_id)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 5 -- Ajustar límite según valor máximo de product_ids por celda
)
SELECT t.id, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.product_ids, ',', n.n), ',', -1)) AS product_id
FROM transactions t
JOIN numbers n 
ON CHAR_LENGTH(t.product_ids) - CHAR_LENGTH(REPLACE(t.product_ids, ',', '')) >= n.n - 1;

SELECT *
FROM transaction_products;


# Consultar el número de ventas por producto
SELECT tp.product_id, p.product_name, COUNT(t.id) AS total_sales
FROM transaction_products tp
JOIN products p ON tp.product_id = p.id
JOIN transactions t ON tp.transaction_id = t.id
WHERE t.declined = 0
GROUP BY tp.product_id
ORDER BY total_sales DESC;
