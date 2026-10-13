CREATE DATABASE IF NOT EXISTS jamii_savings;
USE jamii_savings;

CREATE TABLE IF NOT EXISTS accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    account_holder VARCHAR(100) NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'KES',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO accounts (account_number, account_holder, balance, currency, status) VALUES
('ACC001', 'John Kamau', 150000.00, 'KES', 'ACTIVE'),
('ACC002', 'Mary Wanjiku', 75000.50, 'KES', 'ACTIVE'),
('ACC003', 'Peter Ochieng', 250000.00, 'KES', 'ACTIVE'),
('ACC004', 'Grace Muthoni', 50000.00, 'KES', 'DORMANT'),
('ACC005', 'David Kiprop', 1000000.00, 'KES', 'ACTIVE');

CREATE USER IF NOT EXISTS 'jamii_user'@'%' IDENTIFIED BY 'jamii_password';
GRANT ALL PRIVILEGES ON jamii_savings.* TO 'jamii_user'@'%';
FLUSH PRIVILEGES;
