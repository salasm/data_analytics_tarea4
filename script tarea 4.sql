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

# Tabla companies
CREATE TABLE IF NOT EXISTS companies (
    company_id CHAR(6) PRIMARY KEY,
    company_name VARCHAR(35),
    phone VARCHAR(30),
    email VARCHAR(40),
    country VARCHAR(30),
    website VARCHAR(50)
);

# Tabla transactions
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(55) PRIMARY KEY,
    card_id CHAR(8),
    business_id CHAR(6), 
    timestamp TIMESTAMP,
	amount DECIMAL(10, 2),
    declined BOOLEAN,
    product_ids INT,
    user_id CHAR(3),
    lat FLOAT,
    longitude FLOAT,
    FOREIGN KEY (card_id) REFERENCES credit_cards(id),
    FOREIGN KEY (business_id) REFERENCES companies(company_id), 
    FOREIGN KEY (user_id) REFERENCES users(id)
);

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
JOIN companies c ON t.business_id = c.company_id
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
    id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price VARCHAR(20),
    colour CHAR(7),
    weight DECIMAL(4, 1),
    warehouse_id VARCHAR(10)
);

SELECT * 
FROM products;

#Eliminamos datos para importar archivo limpio, con un solo valor por fila en product_ids
TRUNCATE TABLE transactions;

#Añadimos restricción y clave foránea para relacionar la tabla transactions con products
ALTER TABLE transactions
ADD CONSTRAINT fk_product_ids
FOREIGN KEY (product_ids) REFERENCES products(id);

# número de veces que se ha vendido cada producto
SELECT p.id, p.product_name, COUNT(t.product_ids) AS sales 
FROM transactions t
JOIN products p ON p.id = t.product_ids
WHERE declined = 0
GROUP BY p.id
ORDER BY sales DESC;
