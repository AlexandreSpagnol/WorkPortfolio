DROP DATABASE solemates;

#____________________________________________________________________________________________
# Creating the database

CREATE DATABASE IF NOT EXISTS solemates;
USE solemates;

#____________________________________________________________________________________________
# Creating the tables

CREATE TABLE IF NOT EXISTS customer(
customer_id INT AUTO_INCREMENT NOT NULL,
first_name VARCHAR(25),
last_name VARCHAR(25),
fiscal_number INT DEFAULT NULL,
customer_city VARCHAR(45) DEFAULT NULL,
address VARCHAR(150) DEFAULT NULL,
zipcode VARCHAR(10) DEFAULT NULL,
age INT DEFAULT NULL,
email VARCHAR(150) DEFAULT NULL,
phone_number VARCHAR(25) DEFAULT NULL,
PRIMARY KEY (customer_id)
);

CREATE TABLE IF NOT EXISTS employee(
employee_id INT AUTO_INCREMENT NOT NULL,
first_name VARCHAR(25) NOT NULL,
last_name VARCHAR(25) NOT NULL,
sex CHAR,
age INT NOT NULL,
address VARCHAR(150) NOT NULL,
month_salary INT NOT NULL,
start_date DATE NOT NULL,
end_date DATE DEFAULT NULL,
store_id INT NOT NULL,
manager_id INT DEFAULT NULL,
PRIMARY KEY (employee_id)
);

CREATE TABLE IF NOT EXISTS store(
store_id INT AUTO_INCREMENT NOT NULL,
store_name VARCHAR(45) NOT NULL,
opened DATE DEFAULT NULL,
manager_id INT,
PRIMARY KEY (store_id)
);

CREATE TABLE IF NOT EXISTS purchase(
purchase_id INT AUTO_INCREMENT NOT NULL,
customer_id INT NOT NULL,
store_id INT NOT NULL,
purchase_date DATETIME DEFAULT NOW(),
PRIMARY KEY (purchase_id)
);

CREATE TABLE IF NOT EXISTS product(
product_id INT AUTO_INCREMENT NOT NULL,
product_name VARCHAR(20),
brand_id INT,
product_price DECIMAL(8, 2),
PRIMARY KEY (product_id)
);

CREATE TABLE IF NOT EXISTS brand(
brand_id INT AUTO_INCREMENT NOT NULL,
brand_name VARCHAR(20),
PRIMARY KEY (brand_id)
);

CREATE TABLE IF NOT EXISTS inventory(
store_id INT NOT NULL,
product_id INT NOT NULL,
quantity INT DEFAULT 0,
PRIMARY KEY (store_id, product_id)
);

CREATE TABLE IF NOT EXISTS purchase_item(
purchase_id INT NOT NULL,
product_id INT NOT NULL,
quantity INT DEFAULT 1,
PRIMARY KEY (purchase_id, product_id)
);

CREATE TABLE IF NOT EXISTS rating(
rating_id INT AUTO_INCREMENT NOT NULL,
customer_id INT NOT NULL,
product_id INT NOT NULL,
store_id INT NOT NULL,
rating_score INT CHECK (rating_score BETWEEN 1 AND 5),
rating_date DATETIME DEFAULT NOW(), 
comments VARCHAR(200) DEFAULT NULL,
PRIMARY KEY (rating_id)
);

CREATE TABLE IF NOT EXISTS log_event(
log_id INT AUTO_INCREMENT NOT NULL,
event_description VARCHAR(250) NOT NULL,
event_timestamp DATETIME DEFAULT NOW(),
PRIMARY KEY (log_id)
);

#____________________________________________________________________________________________
# Defining Foreign Keys

ALTER TABLE employee
ADD CONSTRAINT `employee_1`
FOREIGN KEY (manager_id)
REFERENCES employee (employee_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE store
ADD CONSTRAINT `store_1`
FOREIGN KEY (manager_id)
REFERENCES employee (employee_id)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE purchase
ADD CONSTRAINT `purchase_1`
FOREIGN KEY (customer_id)
REFERENCES customer (customer_id)
ON DELETE RESTRICT
ON UPDATE CASCADE,
ADD CONSTRAINT `purchase_2`
FOREIGN KEY (store_id)
REFERENCES store (store_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE product
ADD CONSTRAINT `product_1`
FOREIGN KEY (brand_id)
REFERENCES brand (brand_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE inventory
ADD CONSTRAINT `inventory_1`
FOREIGN KEY (store_id)
REFERENCES store (store_id)
ON DELETE RESTRICT
ON UPDATE CASCADE,
ADD CONSTRAINT `inventory_2`
FOREIGN KEY (product_id)
REFERENCES product (product_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE purchase_item
ADD CONSTRAINT `purchase_item_1`
FOREIGN KEY (purchase_id)
REFERENCES purchase (purchase_id)
ON DELETE RESTRICT
ON UPDATE CASCADE,
ADD CONSTRAINT `purchase_item_2`
FOREIGN KEY (product_id)
REFERENCES product (product_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

ALTER TABLE rating
ADD CONSTRAINT `rating_1`
FOREIGN KEY (customer_id)
REFERENCES customer (customer_id)
ON DELETE RESTRICT
ON UPDATE CASCADE,
ADD CONSTRAINT `rating_2`
FOREIGN KEY (product_id)
REFERENCES product (product_id)
ON DELETE RESTRICT
ON UPDATE CASCADE,
ADD CONSTRAINT `rating_3`
FOREIGN KEY (store_id)
REFERENCES store (store_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

#____________________________________________________________________________________________
# Create the triggers:

# Updating the inventories
DROP TRIGGER IF EXISTS `solemates`.`product_sold_update`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `product_sold_update` AFTER INSERT ON `purchase_item` FOR EACH ROW BEGIN
UPDATE inventory
SET quantity = quantity - NEW.quantity
WHERE product_id = NEW.product_id;

INSERT INTO log_event (event_description)
VALUES (CONCAT('Product with ID ', NEW.product_id, ' sold ', NEW.quantity, ' units.'));
END$$
DELIMITER ;


# Informing that a new employee has been added to the database
DROP TRIGGER IF EXISTS `solemates`.`new_employee_log`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `new_employee_log` AFTER INSERT ON `employee` FOR EACH ROW BEGIN
INSERT INTO log_event (event_description)
VALUES (CONCAT('New employee ', NEW.first_name, ' ', NEW.last_name, ' added.'));
END$$
DELIMITER ;


# Informing that a new customer has been added to the database
DROP TRIGGER IF EXISTS `solemates`.`new_customer_log`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `new_customer_log` AFTER INSERT ON `customer` FOR EACH ROW BEGIN
INSERT INTO log_event (event_description)
VALUES (CONCAT('New customer ', NEW.first_name, ' ', NEW.last_name, ' added.'));
END$$
DELIMITER ;


# Informing that a new brand has been added to the database
DROP TRIGGER IF EXISTS `solemates`.`new_brand_log`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `new_brand_log` AFTER INSERT ON `brand` FOR EACH ROW BEGIN
INSERT INTO log_event (event_description)
VALUES (CONCAT('New brand ', NEW.brand_name, ' added.'));
END$$
DELIMITER ;


# Informing that a new product has been added to the database
DROP TRIGGER IF EXISTS `solemates`.`new_product_log`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `new_product_log` AFTER INSERT ON `product` FOR EACH ROW BEGIN
INSERT INTO log_event (event_description)
VALUES (CONCAT('New product ', NEW.product_name, ' added.'));
END$$
DELIMITER ;


# Informing that a new rating has been added by a customer
DROP TRIGGER IF EXISTS `solemates`.`new_rating_log`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `new_rating_log` AFTER INSERT ON `rating` FOR EACH ROW BEGIN
INSERT INTO log_event (event_description)
VALUES (CONCAT('New rating added.'));
END$$
DELIMITER ;


# Informing that a new store has been added to the database
DROP TRIGGER IF EXISTS `solemates`.`new_store_log`;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER `new_store_log` AFTER INSERT ON `store` FOR EACH ROW BEGIN
INSERT INTO log_event (event_description)
VALUES (CONCAT('New store ', NEW.store_name, ' added.'));
END$$
DELIMITER ;

#____________________________________________________________________________________________
# Inserting data in the database
INSERT INTO customer (first_name, last_name, fiscal_number, customer_city, address, zipcode, age, email, phone_number) VALUES
('Cristiano', 'Ronaldo', 200000007, 'Funchal', ' Av. Sá Carneiro - Praça do Mar Nº27', '9004-518', 38, 'cr7siu@example.com', NULL),
('José', 'Saramago', 987654321, 'Lanzarote', 'C/ La Tegala, 1', '1 35500', 87, NULL, NULL),
('Amália', 'Rodrigues', 456789123, 'Lisboa', 'Rua de São Bento, 193', '1250-219', NULL, 'amalia@example.com', +351975687321),
('Fernando', 'Pessoa', 654321987, 'Lisboa', NULL, NULL, 47, 'ricardo.reis@example.com', '+351987654321'),
('Eusébio', 'da Silva Ferreira', 789123456, 'Lisboa', 'Avenida Eusébio da Silva Ferreira, 18', '1500-313', 22, NULL, '+351989123456'),
('Eça', 'de Queiros', 369258147, 'Paris', '38, Avenue du Roule', '92200', 20, NULL, '+331369258147'),
('Fernando', 'Pimenta', 258147369, 'Ponte de Lima', NULL, NULL, 32, 'fpimenta@example.com', '+351958147369'),
('Amadeo', 'de Souza Cardoso', 147369258, 'Manhufe', 'Rua Velha de Manhufe, 4', '4605-133', 47, 'amadeo@example.com', '+351947369258'),
('Salvador', 'Sobral', 963852741, 'Lisboa', NULL, NULL, 33, 'salvadoresc@example.com', NULL),
('Catarina', 'Furtado', 852741963, 'Lisboa', NULL, NULL, 49, 'cat.furtado@example.com', '+351952741963'),
('Manuel', 'Alegre', 741963852, 'Porto', 'Rua de Santa Catarina, 56', '4000-442', 84, 'manuelalegre123@example.com', NULL),
('Marisa', 'dos Reis Nunes', 963741852, 'Lisboa', 'Av. dos Cavaleiros 70', '2794-059', 47, 'mariza@example.com', NULL),
('Miguel', 'Torga', 852963741, 'Coimbra', 'Praceta Fernando Pesssoa, nº 3', '3000-170', 19, 'adrocha@example.com', '+351952963741'),
('João', 'Almeida', 245678901, 'Caldas da Rainha', 'Rua do Imaginário, 1', '2500-306', 25, 'jpalmeida@example.com', NULL),
('Ricardo', 'Araújo Pereira', 963741852, 'Lisboa', NULL, NULL, 42, NULL, '+351993741852'),
('Eduardo', 'Souto de Moura', 741963852, 'Porto', 'Praça de Liège, Foz do Douro, 15', '4150-455', 68, 'eduardo@example.com', NULL),
('Luís', 'Figo', 852963741, 'Lisboa', NULL, NULL, 49, 'luisfigo@example.com', '+351952963741'),
('António', 'Variações', 963741852, NULL, NULL, 'Braga', 40, 'antonio@example.com', NULL),
('Afonso', 'Henriques', 741963852, 'Guimarães', 'Rua Conde Dom Henrique, 1', '4800-412', 56, NULL, '+351941963852'),
('José', 'Mourinho', 852963741, 'Setúbal', 'Avenida José Mourinho', '2900-633', 60, 'specialone@example.com', '+351952963741'),
('José', 'Cid', 852963741, 'Lisboa', NULL, NULL, 80, 'cid@example.com', '+351952963741'),
('Telma', 'Monteiro', 963741852, 'Porto', NULL, NULL, 45, 'telma@example.com', '+351953741852');

INSERT INTO brand (brand_name) VALUES
('Abibas'),
('Neke'),
('Pumba'),
('Old Balance'),
('BSICS');

INSERT INTO product (product_name, brand_id, product_price) VALUES
('Easy', 1, 6776.99),
('Fire Force', 2, 5219.99),
('Steve Smith', 1, 5130.00),
('Stickers', 3, 4944.95),
('Past', 3, 5369.95),
('Hot Foam', 4, 7120.00),
('SK', 2, 6284.99),
('500', 4, 5985.00),
('Gran Turismo', 5, 6930.00),
('Jel', 5, 5580.00);

INSERT INTO store (store_name, opened, manager_id) VALUES
('Lisboa', '2021-01-01', NULL),
('Porto', '2021-04-01', NULL),
('Faro', '2021-05-01', NULL),
('Vimioso', NULL, NULL);

INSERT INTO employee (first_name, last_name, sex, age, address, month_salary, start_date, end_date, store_id, manager_id) VALUES
('João', 'Silva', 'M', 28, 'Rua Cabral Antunes, 21', 2000, '2020-12-01', NULL, 1, NULL),
('Maria', 'Santos', 'F', 21, 'Rua Tomé Queirós, 89', 1100, '2021-01-01', NULL, 1, 1),
('Carlos', 'Oliveira', 'M', 30, 'Rua do Pescador, 56', 1100, '2021-01-01', '2021-03-31', 1, 1),
('Ana', 'Pereira', 'F', 26, 'Rua Frei Fortunato, 41', 1100, '2021-02-15', '2021-03-31', 1, 1),
('Pedro', 'Fernandes', 'M', 32, 'Avenida Júlio S. Dias, 24', 2000, '2021-03-01', NULL, 2, NULL),
('Marta', 'Rodrigues', 'F', 29, 'Avenida Cimo Vila, 6', 2000, '2021-04-01', NULL, 3, NULL),
('Manuel', 'Martins', 'M', 31, 'Rua Dr. Luís Sardoeira, 68', 1100, '2021-04-1', NULL, 2, 5),
('Beatriz', 'Sousa', 'F', 22, 'Avenida Desidério Bessa, 117', 1000, '2021-04-01', '2022-08-31', 1, 1),
('Luís', 'Gomes', 'M', 33, 'Praceta Conde Arnoso, 7', 1000, '2021-04-01', NULL, 1, 1),
('Sofia', 'Almeida', 'F', 25, 'Avenida das Forças Armadas, 16', 1000, '2021-04-01', NULL, 1, 1),
('Rafael', 'Lima', 'M', 29, 'Rua do Refugo, 72', 1100, '2021-04-01', NULL, 2, 5),
('Carla', 'Dias', 'F', 23, 'Rua Dr. José Peixoto, 56', 1100, '2021-04-01', '2021-11-30', 3, 6),
('Tiago', 'Barbosa', 'M', 30, 'Avenida Marquês de Tomar, 20', 1100, '2021-04-01', NULL, 3, 6),
('Isabel', 'Cavalcante', 'F', 28, 'Avenida da República, 51', 1100, '2021-04-01', '2021-12-31', 2, 5),
('Fernando', 'Silveira', 'M', 24, 'Rua Manuel Figueiredo, 27', 1000, '2021-12-01', '2022-06-30', 2, 5),
('Camila', 'Nascimento', 'F', 26, 'Rua do Cais, 97', 1000, '2021-12-01', NULL, 3, 6),
('Miguel', 'Costa', 'M', 27, 'Quinta das Fontainhas, 6', 1000, '2022-01-01', NULL, 2, 5),
('Catarina', 'Cardoso', 'F', 20, 'Avenida da Igreja, 47', 1000, '2022-01-01', NULL, 1, 1),
('Leonardo', 'Santana', 'M', 34, 'Rua Dr. Leite de Vasconcellos 23', 1000, '2022-01-01', '2022-04-30', 3, 6),
('José', 'Machado', 'M', 31, 'Estrada Logo Deus, 32', 1000, '2022-03-01', NULL, 3, 6),
('Luciana', 'Pereira', 'F', 18, 'Rua das Nogueiras, 11', 1000, '2022-03-01', NULL, 3, 6),
('Ricardo', 'Alves', 'M', 32, 'Rua Diogo Cão, 13', 1000, '2022-05-01', '2022-09-30', 2, 5),
('André', 'Silva', 'M', 27, 'Avenida António Feijó, 1', 1000, '2022-10-01', NULL, 2, 5);

SET SQL_SAFE_UPDATES=0;

UPDATE store
SET manager_id = CASE
WHEN store_name = 'Lisboa' THEN 1
WHEN store_name = 'Porto' THEN 5
WHEN store_name = 'Faro' THEN 6
ELSE manager_id
END;

SET SQL_SAFE_UPDATES=1;

INSERT INTO inventory (store_id, product_id, quantity) VALUES
(1, 1, 15),
(1, 2, 20),
(1, 3, 12),
(1, 4, 18),
(1, 5, 10),
(1, 6, 25),
(1, 7, 9),
(1, 8, 14),
(1, 9, 22),
(1, 10, 16),
(2, 1, 14),
(2, 2, 23),
(2, 3, 17),
(2, 4, 21),
(2, 5, 13),
(2, 6, 19),
(2, 7, 24),
(2, 8, 9),
(2, 9, 20),
(2, 10, 25),
(3, 1, 22),
(3, 2, 15),
(3, 3, 14),
(3, 4, 9),
(3, 5, 18),
(3, 6, 21),
(3, 7, 16),
(3, 8, 11),
(3, 9, 12),
(3, 10, 23);

INSERT INTO purchase (customer_id, store_id, purchase_date) VALUES
(1, 1, '2021-01-05 11:40:00'),
(2, 1, '2021-01-15 09:35:00'),
(3, 1, '2021-01-22 13:05:00'),
(4, 1, '2021-02-12 15:15:00'),
(5, 1, '2021-03-08 14:19:00'),
(6, 2, '2021-04-25 14:30:00'),
(7, 3, '2021-05-20 15:45:00'),
(8, 3, '2021-06-02 15:55:00'),
(1, 1, '2021-07-12 15:10:00'),
(9, 2, '2021-08-30 14:49:00'),
(10, 3, '2021-09-04 13:46:00'),
(11, 2, '2021-10-29 10:58:00'),
(12, 1, '2021-11-10 12:12:00'),
(7, 3, '2021-12-15 10:29:00'),
(13, 2, '2021-12-27 11:11:00'),
(8, 3, '2021-12-31 09:44:00'),
(14, 3, '2022-01-02 12:31:00'),
(6, 2, '2022-01-14 13:55:00'),
(2, 1, '2022-01-15 15:59:00'),
(15, 2, '2022-01-25 10:05:00'),
(16, 1, '2022-02-12 12:02:00'),
(3, 1, '2022-02-28 16:21:00'),
(17, 2, '2022-03-21 13:21:00'),
(18, 3, '2022-04-05 16:04:00'),
(19, 2, '2022-04-15 18:22:00'),
(17, 2, '2022-05-12 10:40:00'),
(13, 2, '2022-06-30 17:44:00'),
(1, 1, '2022-07-14 16:15:00'),
(20, 1, '2022-08-10 14:41:00'),
(21, 3, '2022-09-22 09:11:00'),
(12, 1, '2021-10-28 12:20:00'),
(15, 2, '2021-11-12 16:31:00'),
(22, 1, '2022-12-01 17:56:00'),
(2, 1, '2022-12-15 16:03:00'),
(14, 3, '2022-12-22 10:07:00'),
(4, 1, '2022-12-31 17:32:00');

INSERT INTO purchase_item (purchase_id, product_id, quantity) VALUES
(1, 2, 1),
(1, 7, 1),
(2, 1, 2),
(3, 5, 1),
(4, 6, 1),
(5, 1, 2),
(6, 3, 1),
(7, 4, 1),
(7, 8, 1),
(7, 2, 1),
(8, 9, 2),
(8, 2, 1),
(9, 7, 1),
(10, 1, 2),
(11, 3, 1),
(11, 4, 1),
(12, 10, 1),
(13, 10, 1),
(14, 5, 2),
(15, 8, 1),
(15, 6, 1),
(16, 1, 1),
(17, 3, 1),
(18, 2, 1),
(19, 4, 1),
(19, 10, 1),
(20, 1, 2),
(21, 9, 1),
(22, 7, 1),
(23, 2, 1),
(24, 8, 1),
(24, 5, 1),
(25, 6, 1),
(26, 3, 1),
(27, 4, 2),
(28, 7, 1),
(29, 1, 2),
(30, 3, 1),
(30, 8, 1),
(31, 3, 1),
(31, 6, 1),
(32, 1, 1),
(33, 9, 2),
(34, 8, 1),
(35, 3, 1),
(36, 5, 1),
(36, 10, 2);

# Maybe we should update this, since we are now a luxury brand
INSERT INTO rating (customer_id, product_id, store_id, rating_score, rating_date, comments) VALUES
(1, 2, 1, 4, '2021-01-05 18:25:12', 'I loved the shoes, but I would not mind waiting a bit more and get an even better product!'),
(3, 5, 1, 5, '2021-01-24 09:45:33', 'Great quality and service, well worth every penny'),
(6, 3, 2, 4, '2021-04-25 20:51:15', 'The employees knew what they were talking about, that was a huge positive point.'),
(7, 4, 3, 5, '2021-05-21 12:08:59', 'Highly recommended these shoes and this store!'),
(9, 2, 2, 5, '2021-08-30 17:32:48', 'My friends are gonna be so jealous!!!'),
(10, 2, 3, 1, '2021-09-04 19:43:21', 'Had a terrible experience here, very disappointed with the service. Will never shop here again, and my manager will know about this!'),
(12, 10, 1, 5, '2021-11-12 23:34:04', 'Excellent :)'),
(14, 3, 3, 3, '2022-01-02 12:31:00', 'Could be better. The shoes were nice but I expected more for the money I paid.'),
(1, 7, 1, 5, '2022-07-15 08:09:31', 'ABSOLUTELY LOVE IT SIUUUUUUU'),
(20, 1, 1, 5, '2022-08-10 14:41:00', 'Outstanding quality! These are the best shoes ever!'),
(22, 9, 1, 5, '2022-12-01 17:56:00', 'Terrific piece of footwear! Whoever designed this wonder deserves all the best!');

#______________
#F)
#1.
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name, p.product_name, pr.purchase_date
FROM customer AS c
JOIN purchase AS pr ON c.customer_id = pr.customer_id
JOIN purchase_item AS pi ON pr.purchase_id = pi.purchase_id
JOIN product AS p ON pi.product_id = p.product_id
WHERE pr.purchase_date BETWEEN '2021-05-01' AND '2022-05-01';

#2.
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name, SUM(p.product_price) AS total_purchase
FROM customer AS c
JOIN purchase AS pr ON c.customer_id = pr.customer_id
JOIN purchase_item AS pi ON pr.purchase_id = pi.purchase_id
JOIN product AS p ON pi.product_id = p.product_id
GROUP BY c.customer_id
ORDER BY total_purchase DESC
LIMIT 3;

#3.
SELECT
CONCAT(MIN(DATE_FORMAT(pr.purchase_date, '%m/%Y')), ' - ', MAX(DATE_FORMAT(pr.purchase_date, '%m/%Y'))) AS PeriodOfSales,
SUM(p.product_price) AS TotalSales,
ROUND(SUM(p.product_price) / (YEAR(MAX(pr.purchase_date)) - YEAR(MIN(pr.purchase_date)) + 1), 2) AS YearlyAverage,
ROUND(SUM(p.product_price) / (DATEDIFF(MAX(pr.purchase_date), MIN(pr.purchase_date)) / 30), 2) AS MonthlyAverage
FROM purchase AS pr
JOIN purchase_item AS pi ON pr.purchase_id = pi.purchase_id
JOIN product AS p ON pi.product_id = p.product_id
WHERE pr.purchase_date BETWEEN '2021-01-01' AND '2022-12-31';

#4.
SELECT s.store_name, SUM(p.product_price) AS total_sales
FROM store AS s
JOIN purchase AS pr ON s.store_id = pr.store_id
JOIN purchase_item AS pi ON pr.purchase_id = pi.purchase_id
JOIN product AS p ON pi.product_id = p.product_id
GROUP BY s.store_name;

#5.
SELECT DISTINCT s.store_name AS stores_with_reviews
FROM store AS s
JOIN purchase AS pr ON s.store_id = pr.store_id
JOIN purchase_item AS pi ON pr.purchase_id = pi.purchase_id
JOIN product AS p ON pi.product_id = p.product_id
WHERE p.product_id IN (SELECT DISTINCT r.product_id FROM rating AS r);

#______________
#G)
CREATE VIEW invoice_head_and_totals AS
SELECT
pr.purchase_id,
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
pr.purchase_date,
s.store_name,
SUM(pi.quantity * p.product_price) AS total_amount
FROM customer AS c
JOIN purchase AS pr ON c.customer_id = pr.customer_id
JOIN store AS s ON pr.store_id = s.store_id
JOIN purchase_item AS pi ON pr.purchase_id = pi.purchase_id
JOIN product AS p ON pi.product_id = p.product_id
GROUP BY pr.purchase_id
ORDER BY pr.purchase_id;

SELECT * FROM invoice_head_and_totals;

SELECT * FROM invoice_head_and_totals
WHERE purchase_id = 1;

CREATE VIEW invoice_details AS
SELECT
pi.purchase_id,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
c.customer_city,
c.fiscal_number,
c.address AS customer_address,
c.email AS customer_email,
c.phone_number AS customer_phone_number,
p.product_id,
p.product_name,
p.product_price,
pi.quantity,
pi.quantity * pr.product_price AS line_total
FROM purchase_item AS pi
JOIN purchase AS pur ON pi.purchase_id = pur.purchase_id
JOIN customer AS c ON pur.customer_id = c.customer_id
JOIN product AS p ON pi.product_id = p.product_id
JOIN product AS pr ON pi.product_id = pr.product_id

ORDER BY pi.purchase_id, p.product_id;

SELECT * FROM invoice_details;

SELECT * FROM invoice_details
WHERE purchase_id = 1;