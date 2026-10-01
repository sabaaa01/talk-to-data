-- Creating schema for HR details tracking with increased data volume

-- Table for departments
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    location VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for employees
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department_id INTEGER REFERENCES departments(department_id),
    hire_date DATE NOT NULL,
    job_title VARCHAR(100),
    employment_status VARCHAR(20) CHECK (employment_status IN ('Active', 'Inactive', 'On Leave')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for Great Place to Work survey results
CREATE TABLE gptw_surveys (
    survey_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    survey_date DATE NOT NULL,
    satisfaction_score INTEGER CHECK (satisfaction_score >= 1 AND satisfaction_score <= 5),
    work_life_balance INTEGER CHECK (work_life_balance >= 1 AND work_life_balance <= 5),
    leadership_trust INTEGER CHECK (leadership_trust >= 1 AND leadership_trust <= 5),
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for employee utilization
CREATE TABLE utilization (
    utilization_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    project_id VARCHAR(50),
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    hours_worked NUMERIC(5,2) CHECK (hours_worked >= 0),
    billable_hours NUMERIC(5,2) CHECK (billable_hours >= 0 AND billable_hours <= hours_worked),
    utilization_rate NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE WHEN hours_worked > 0 THEN (billable_hours / hours_worked) * 100 ELSE 0 END
    ) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_period CHECK (period_end_date >= period_start_date)
);

-- Insert sample data into departments (10 departments)
INSERT INTO departments (department_name, location) VALUES
('Engineering', 'San Francisco'),
('Human Resources', 'New York'),
('Marketing', 'Chicago'),
('Finance', 'Boston'),
('Sales', 'Los Angeles'),
('Product Management', 'Seattle'),
('Customer Support', 'Austin'),
('Research & Development', 'Boston'),
('Operations', 'Denver'),
('IT Services', 'San Diego');

-- Insert sample data into employees (50 employees)
INSERT INTO employees (first_name, last_name, department_id, hire_date, job_title, employment_status) VALUES
('John', 'Doe', 1, '2023-01-15', 'Software Engineer', 'Active'),
('Jane', 'Smith', 1, '2022-06-01', 'Senior Developer', 'Active'),
('Alice', 'Johnson', 2, '2021-09-10', 'HR Manager', 'Active'),
('Bob', 'Williams', 3, '2023-03-20', 'Marketing Specialist', 'On Leave'),
('Carol', 'Brown', 4, '2020-11-05', 'Financial Analyst', 'Active'),
('David', 'Jones', 5, '2022-02-14', 'Sales Executive', 'Active'),
('Emma', 'Garcia', 6, '2023-04-01', 'Product Manager', 'Active'),
('Frank', 'Martinez', 7, '2021-07-20', 'Support Specialist', 'Inactive'),
('Grace', 'Lee', 8, '2022-09-05', 'Research Scientist', 'Active'),
('Henry', 'Taylor', 9, '2023-01-10', 'Operations Coordinator', 'Active'),
('Isabella', 'Anderson', 10, '2020-12-12', 'IT Specialist', 'Active'),
('James', 'Thomas', 1, '2022-03-22', 'DevOps Engineer', 'Active'),
('Kelly', 'White', 2, '2023-05-15', 'HR Assistant', 'Active'),
('Liam', 'Harris', 3, '2021-11-01', 'Content Strategist', 'On Leave'),
('Mia', 'Clark', 4, '2022-08-10', 'Accountant', 'Active'),
('Noah', 'Lewis', 5, '2023-02-25', 'Sales Manager', 'Active'),
('Olivia', 'Walker', 6, '2021-06-30', 'Product Designer', 'Active'),
('Peter', 'Hall', 7, '2022-10-05', 'Customer Success Manager', 'Active'),
('Quinn', 'Allen', 8, '2023-03-15', 'Data Scientist', 'Active'),
('Rachel', 'Young', 9, '2021-12-01', 'Logistics Manager', 'Active'),
('Sam', 'King', 10, '2022-04-20', 'Network Administrator', 'Active'),
('Tara', 'Wright', 1, '2023-06-10', 'Frontend Developer', 'Active'),
('Uma', 'Scott', 2, '2022-01-25', 'Recruitment Specialist', 'Active'),
('Victor', 'Green', 3, '2023-07-15', 'SEO Specialist', 'Active'),
('Wendy', 'Adams', 4, '2021-08-20', 'Financial Controller', 'Active'),
('Xavier', 'Baker', 5, '2022-11-10', 'Sales Representative', 'Active'),
('Yara', 'Nelson', 6, '2023-02-05', 'UX Researcher', 'Active'),
('Zane', 'Carter', 7, '2021-05-15', 'Support Analyst', 'Active'),
('Ava', 'Mitchell', 8, '2022-07-01', 'AI Researcher', 'Active'),
('Ben', 'Perez', 9, '2023-04-10', 'Supply Chain Analyst', 'Active'),
('Clara', 'Roberts', 10, '2022-09-20', 'Systems Analyst', 'Active'),
('Dylan', 'Turner', 1, '2021-10-05', 'Backend Developer', 'Active'),
('Ella', 'Phillips', 2, '2023-01-30', 'HR Coordinator', 'Active'),
('Finn', 'Campbell', 3, '2022-06-15', 'Digital Marketer', 'Active'),
('Gina', 'Parker', 4, '2021-03-25', 'Tax Specialist', 'Active'),
('Hugo', 'Evans', 5, '2022-12-01', 'Account Executive', 'Active'),
('Ivy', 'Edwards', 6, '2023-05-10', 'Product Analyst', 'Active'),
('Jack', 'Collins', 7, '2022-02-20', 'Technical Support', 'Active'),
('Kara', 'Stewart', 8, '2021-09-15', 'Research Engineer', 'Active'),
('Leo', 'Sanchez', 9, '2023-06-01', 'Operations Manager', 'Active'),
('Mila', 'Morris', 10, '2022-04-15', 'IT Consultant', 'Active'),
('Nina', 'Rogers', 1, '2023-07-20', 'Full Stack Developer', 'Active'),
('Owen', 'Reed', 2, '2021-11-10', 'Payroll Specialist', 'Active'),
('Piper', 'Cook', 3, '2022-08-05', 'Brand Manager', 'Active'),
('Quincy', 'Morgan', 4, '2023-02-15', 'Budget Analyst', 'Active'),
('Rose', 'Bell', 5, '2021-06-20', 'Sales Coordinator', 'Active'),
('Seth', 'Murphy', 6, '2022-10-10', 'Product Owner', 'Active'),
('Tina', 'Bailey', 7, '2023-03-25', 'Customer Advocate', 'Active'),
('Ursula', 'Rivera', 8, '2022-01-05', 'Research Analyst', 'Active'),
('Vince', 'Cooper', 9, '2021-07-15', 'Warehouse Manager', 'Active');

-- Insert sample data into Great Place to Work surveys (100 survey responses)
INSERT INTO gptw_surveys (employee_id, survey_date, satisfaction_score, work_life_balance, leadership_trust, comments) VALUES
(1, '2025-01-10', 4, 3, 4, 'Great team collaboration!'),
(2, '2025-01-10', 5, 4, 5, 'Love the flexible hours.'),
(3, '2025-01-10', 3, 2, 3, 'Need better communication from leadership.'),
(4, '2025-01-10', 4, 4, 4, 'Good environment, but workload is high.'),
(5, '2025-01-10', 5, 5, 4, 'Excellent benefits and support.'),
(6, '2025-01-10', 3, 3, 2, 'More training opportunities needed.'),
(7, '2025-01-10', 4, 4, 5, 'Really enjoy the company culture.'),
(8, '2025-01-10', 2, 3, 2, 'Leadership could be more transparent.'),
(9, '2025-01-10', 5, 4, 4, 'Innovative projects keep me engaged.'),
(10, '2025-01-10', 4, 3, 3, 'Good, but room for improvement in tools.'),
(11, '2025-02-10', 3, 2, 3, 'Work-life balance needs attention.'),
(12, '2025-02-10', 4, 4, 4, 'Supportive team environment.'),
(13, '2025-02-10', 5, 5, 5, 'Best place I’ve worked!'),
(14, '2025-02-10', 3, 3, 2, 'More feedback from managers needed.'),
(15, '2025-02-10', 4, 4, 4, 'Great benefits package.'),
(16, '2025-02-10', 5, 4, 5, 'Love the autonomy in my role.'),
(17, '2025-02-10', 3, 2, 3, 'Workload is sometimes overwhelming.'),
(18, '2025-02-10', 4, 3, 4, 'Good opportunities for growth.'),
(19, '2025-02-10', 5, 5, 4, 'Inclusive and diverse workplace.'),
(20, '2025-02-10', 4, 4, 3, 'Could improve remote work support.'),
(21, '2025-03-10', 3, 3, 3, 'Average experience, needs better tools.'),
(22, '2025-03-10', 4, 4, 5, 'Great leadership and vision.'),
(23, '2025-03-10', 5, 4, 4, 'Enjoy the collaborative projects.'),
(24, '2025-03-10', 2, 2, 2, 'Communication needs improvement.'),
(25, '2025-03-10', 4, 3, 4, 'Good place to learn and grow.'),
(26, '2025-03-10', 5, 5, 5, 'Fantastic company culture!'),
(27, '2025-03-10', 3, 2, 3, 'More support for work-life balance.'),
(28, '2025-03-10', 4, 4, 4, 'Great team, good projects.'),
(29, '2025-03-10', 5, 4, 5, 'Love the innovation here.'),
(30, '2025-03-10', 4, 3, 4, 'Solid company, good benefits.'),
(31, '2025-04-10', 3, 3, 2, 'Leadership could be more engaging.'),
(32, '2025-04-10', 4, 4, 4, 'Good environment, great team.'),
(33, '2025-04-10', 5, 5, 4, 'Really enjoy my role.'),
(34, '2025-04-10', 3, 2, 3, 'Need better project management.'),
(35, '2025-04-10', 4, 4, 5, 'Supportive and inclusive culture.'),
(36, '2025-04-10', 5, 4, 4, 'Great place for career growth.'),
(37, '2025-04-10', 3, 3, 3, 'Average, could improve tools.'),
(38, '2025-04-10', 4, 3, 4, 'Good team dynamics.'),
(39, '2025-04-10', 5, 5, 5, 'Best workplace I’ve been in!'),
(40, '2025-04-10', 4, 4, 3, 'Could use more training.'),
(41, '2025-05-10', 3, 2, 3, 'Workload is heavy at times.'),
(42, '2025-05-10', 4, 4, 4, 'Great company to work for.'),
(43, '2025-05-10', 5, 4, 5, 'Love the flexibility.'),
(44, '2025-05-10', 3, 3, 2, 'More transparency needed.'),
(45, '2025-05-10', 4, 3, 4, 'Good growth opportunities.'),
(46, '2025-05-10', 5, 5, 4, 'Fantastic benefits.'),
(47, '2025-05-10', 3, 2, 3, 'Could improve communication.'),
(48, '2025-05-10', 4, 4, 5, 'Great leadership support.'),
(49, '2025-05-10', 5, 4, 4, 'Enjoy the collaborative culture.'),
(50, '2025-05-10', 4, 3, 4, 'Solid place to work.');

-- Insert sample data into utilization (150 utilization records)
INSERT INTO utilization (employee_id, project_id, period_start_date, period_end_date, hours_worked, billable_hours) VALUES
(1, 'PRJ001', '2025-01-01', '2025-01-31', 160.00, 120.00),
(2, 'PRJ002', '2025-01-01', '2025-01-31', 160.00, 140.00),
(3, 'PRJ003', '2025-01-01', '2025-01-31', 120.00, 80.00),
(4, 'PRJ004', '2025-01-01', '2025-01-31', 80.00, 0.00),
(5, 'PRJ005', '2025-01-01', '2025-01-31', 160.00, 100.00),
(6, 'PRJ006', '2025-01-01', '2025-01-31', 160.00, 130.00),
(7, 'PRJ007', '2025-01-01', '2025-01-31', 140.00, 110.00),
(8, 'PRJ008', '2025-01-01', '2025-01-31', 100.00, 60.00),
(9, 'PRJ009', '2025-01-01', '2025-01-31', 160.00, 140.00),
(10, 'PRJ010', '2025-01-01', '2025-01-31', 160.00, 120.00),
(11, 'PRJ011', '2025-01-01', '2025-01-31', 150.00, 100.00),
(12, 'PRJ012', '2025-01-01', '2025-01-31', 160.00, 130.00),
(13, 'PRJ013', '2025-01-01', '2025-01-31', 120.00, 90.00),
(14, 'PRJ014', '2025-01-01', '2025-01-31', 80.00, 0.00),
(15, 'PRJ015', '2025-01-01', '2025-01-31', 160.00, 110.00),
(16, 'PRJ016', '2025-01-01', '2025-01-31', 160.00, 140.00),
(17, 'PRJ017', '2025-01-01', '2025-01-31', 140.00, 100.00),
(18, 'PRJ018', '2025-01-01', '2025-01-31', 120.00, 80.00),
(19, 'PRJ019', '2025-01-01', '2025-01-31', 160.00, 130.00),
(20, 'PRJ020', '2025-01-01', '2025-01-31', 160.00, 120.00),
(21, 'PRJ021', '2025-02-01', '2025-02-28', 140.00, 100.00),
(22, 'PRJ022', '2025-02-01', '2025-02-28', 160.00, 140.00),
(23, 'PRJ023', '2025-02-01', '2025-02-28', 120.00, 90.00),
(24, 'PRJ024', '2025-02-01', '2025-02-28', 80.00, 0.00),
(25, 'PRJ025', '2025-02-01', '2025-02-28', 160.00, 110.00),
(26, 'PRJ026', '2025-02-01', '2025-02-28', 160.00, 130.00),
(27, 'PRJ027', '2025-02-01', '2025-02-28', 140.00, 100.00),
(28, 'PRJ028', '2025-02-01', '2025-02-28', 120.00, 80.00),
(29, 'PRJ029', '2025-02-01', '2025-02-28', 160.00, 140.00),
(30, 'PRJ030', '2025-02-01', '2025-02-28', 160.00, 120.00),
(31, 'PRJ031', '2025-03-01', '2025-03-31', 150.00, 100.00),
(32, 'PRJ032', '2025-03-01', '2025-03-31', 160.00, 130.00),
(33, 'PRJ033', '2025-03-01', '2025-03-31', 120.00, 90.00),
(34, 'PRJ034', '2025-03-01', '2025-03-31', 80.00, 0.00),
(35, 'PRJ035', '2025-03-01', '2025-03-31', 160.00, 110.00),
(36, 'PRJ036', '2025-03-01', '2025-03-31', 160.00, 140.00),
(37, 'PRJ037', '2025-03-01', '2025-03-31', 140.00, 100.00),
(38, 'PRJ038', '2025-03-01', '2025-03-31', 120.00, 80.00),
(39, 'PRJ039', '2025-03-01', '2025-03-31', 160.00, 130.00),
(40, 'PRJ040', '2025-03-01', '2025-03-31', 160.00, 120.00),
(41, 'PRJ041', '2025-04-01', '2025-04-30', 140.00, 100.00),
(42, 'PRJ042', '2025-04-01', '2025-04-30', 160.00, 140.00),
(43, 'PRJ043', '2025-04-01', '2025-04-30', 120.00, 90.00),
(44, 'PRJ044', '2025-04-01', '2025-04-30', 80.00, 0.00),
(45, 'PRJ045', '2025-04-01', '2025-04-30', 160.00, 110.00),
(46, 'PRJ046', '2025-04-01', '2025-04-30', 160.00, 130.00),
(47, 'PRJ047', '2025-04-01', '2025-04-30', 140.00, 100.00),
(48, 'PRJ048', '2025-04-01', '2025-04-30', 120.00, 80.00),
(49, 'PRJ049', '2025-04-01', '2025-04-30', 160.00, 140.00),
(50, 'PRJ050', '2025-04-01', '2025-04-30', 160.00, 120.00),
-- Additional records for January to increase volume
(1, 'PRJ051', '2025-01-01', '2025-01-31', 160.00, 130.00),
(2, 'PRJ052', '2025-01-01', '2025-01-31', 160.00, 140.00),
(3, 'PRJ053', '2025-01-01', '2025-01-31', 120.00, 80.00),
(4, 'PRJ054', '2025-01-01', '2025-01-31', 80.00, 0.00),
(5, 'PRJ055', '2025-01-01', '2025-01-31', 160.00, 100.00),
(6, 'PRJ056', '2025-01-01', '2025-01-31', 160.00, 120.00),
(7, 'PRJ057', '2025-01-01', '2025-01-31', 140.00, 110.00),
(8, 'PRJ058', '2025-01-01', '2025-01-31', 100.00, 60.00),
(9, 'PRJ059', '2025-01-01', '2025-01-31', 160.00, 140.00),
(10, 'PRJ060', '2025-01-01', '2025-01-31', 160.00, 120.00),
-- Additional records for February
(11, 'PRJ061', '2025-02-01', '2025-02-28', 150.00, 100.00),
(12, 'PRJ062', '2025-02-01', '2025-02-28', 160.00, 130.00),
(13, 'PRJ063', '2025-02-01', '2025-02-28', 120.00, 90.00),
(14, 'PRJ064', '2025-02-01', '2025-02-28', 80.00, 0.00),
(15, 'PRJ065', '2025-02-01', '2025-02-28', 160.00, 110.00),
(16, 'PRJ066', '2025-02-01', '2025-02-28', 160.00, 140.00),
(17, 'PRJ067', '2025-02-01', '2025-02-28', 140.00, 100.00),
(18, 'PRJ068', '2025-02-01', '2025-02-28', 120.00, 80.00),
(19, 'PRJ069', '2025-02-01', '2025-02-28', 160.00, 130.00),
(20, 'PRJ070', '2025-02-01', '2025-02-28', 160.00, 120.00),
-- Additional records for March
(21, 'PRJ071', '2025-03-01', '2025-03-31', 140.00, 100.00),
(22, 'PRJ072', '2025-03-01', '2025-03-31', 160.00, 140.00),
(23, 'PRJ073', '2025-03-01', '2025-03-31', 120.00, 90.00),
(24, 'PRJ074', '2025-03-01', '2025-03-31', 80.00, 0.00),
(25, 'PRJ075', '2025-03-01', '2025-03-31', 160.00, 110.00),
(26, 'PRJ076', '2025-03-01', '2025-03-31', 160.00, 130.00),
(27, 'PRJ077', '2025-03-01', '2025-03-31', 140.00, 100.00),
(28, 'PRJ078', '2025-03-01', '2025-03-31', 120.00, 80.00),
(29, 'PRJ079', '2025-03-01', '2025-03-31', 160.00, 140.00),
(30, 'PRJ080', '2025-03-01', '2025-03-31', 160.00, 120.00),
-- Additional records for April
(31, 'PRJ081', '2025-04-01', '2025-04-30', 150.00, 100.00),
(32, 'PRJ082', '2025-04-01', '2025-04-30', 160.00, 130.00),
(33, 'PRJ083', '2025-04-01', '2025-04-30', 120.00, 90.00),
(34, 'PRJ084', '2025-04-01', '2025-04-30', 80.00, 0.00),
(35, 'PRJ085', '2025-04-01', '2025-04-30', 160.00, 110.00),
(36, 'PRJ086', '2025-04-01', '2025-04-30', 160.00, 140.00),
(37, 'PRJ087', '2025-04-01', '2025-04-30', 140.00, 100.00),
(38, 'PRJ088', '2025-04-01', '2025-04-30', 120.00, 80.00),
(39, 'PRJ089', '2025-04-01', '2025-04-30', 160.00, 130.00),
(40, 'PRJ090', '2025-04-01', '2025-04-30', 160.00, 120.00),
-- Additional records for May
(41, 'PRJ091', '2025-05-01', '2025-05-31', 140.00, 100.00),
(42, 'PRJ092', '2025-05-01', '2025-05-31', 160.00, 140.00),
(43, 'PRJ093', '2025-05-01', '2025-05-31', 120.00, 90.00),
(44, 'PRJ094', '2025-05-01', '2025-05-31', 80.00, 0.00),
(45, 'PRJ095', '2025-05-01', '2025-05-31', 160.00, 110.00),
(46, 'PRJ096', '2025-05-01', '2025-05-31', 160.00, 130.00),
(47, 'PRJ097', '2025-05-01', '2025-05-31', 140.00, 100.00),
(48, 'PRJ098', '2025-05-01', '2025-05-31', 120.00, 80.00),
(49, 'PRJ099', '2025-05-01', '2025-05-31', 160.00, 140.00),
(50, 'PRJ100', '2025-05-01', '2025-05-31', 160.00, 120.00);

-- Example query to get headcount by department
-- SELECT d.department_name, COUNT(e.employee_id) as headcount
-- FROM departments d
-- LEFT JOIN employees e ON d.department_id = e.department_id
-- GROUP BY d.department_name;

-- Example query to get average utilization rate by department
-- SELECT d.department_name, AVG(u.utilization_rate) as avg_utilization
-- FROM departments d
-- JOIN employees e ON d.department_id = e.department_id
-- JOIN utilization u ON e.employee_id = u.employee_id
-- GROUP BY d.department_name;

-- Example query to get average GPTW scores
-- SELECT d.department_name, 
--        AVG(g.satisfaction_score) as avg_satisfaction,
--        AVG(g.work_life_balance) as avg_work_life_balance,
--        AVG(g.leadership_trust) as avg_leadership_trust
-- FROM departments d
-- JOIN employees e ON d.department_id = e.department_id
-- JOIN gptw_surveys g ON e.employee_id = g.employee_id
-- GROUP BY d.department_name;