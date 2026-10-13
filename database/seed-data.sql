-- Jamii Savings Bank - Seed Data
-- Sample accounts for testing

USE jamii_savings;

-- Clear existing data
TRUNCATE TABLE accounts;

-- Insert sample accounts
INSERT INTO accounts (account_number, customer_name, status, balance, currency) VALUES
('1001001001', 'John Kamau', 'ACTIVE', 50000.00, 'KES'),
('1001001002', 'Mary Wanjiku', 'ACTIVE', 125000.50, 'KES'),
('1001001003', 'Peter Ochieng', 'DORMANT', 5000.00, 'KES'),
('1001001004', 'Grace Muthoni', 'CLOSED', 0.00, 'KES'),
('1001001005', 'James Kiprop', 'ACTIVE', 750000.00, 'KES'),
('1001001006', 'Sarah Njeri', 'ACTIVE', 32500.75, 'KES'),
('1001001007', 'David Mwangi', 'DORMANT', 1500.00, 'KES'),
('1001001008', 'Faith Akinyi', 'ACTIVE', 89000.00, 'KES');

-- Verify data
SELECT * FROM accounts;
