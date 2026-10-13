-- Jamii Savings Bank - Database Schema
-- Part 1a: Account Balance API

CREATE DATABASE IF NOT EXISTS jamii_savings;
USE jamii_savings;

-- Accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    status ENUM('ACTIVE', 'DORMANT', 'CLOSED') NOT NULL DEFAULT 'ACTIVE',
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'KES',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_account_number (account_number),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create application user
CREATE USER IF NOT EXISTS 'jamii_user'@'localhost' IDENTIFIED BY 'jamii_password';
GRANT ALL PRIVILEGES ON jamii_savings.* TO 'jamii_user'@'localhost';
FLUSH PRIVILEGES;
