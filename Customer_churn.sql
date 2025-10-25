# Churn - 0 - Stayed , Not churn - 1 - left 
use churn_predection; 

select * from churn_modelling ; 

-- Look at first few rows
SELECT * FROM churn_modelling LIMIT 10;

-- Count rows
SELECT COUNT(*) AS total_rows FROM churn_modelling; 

-- count columns
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'churn_modelling';

-- To describe the table 
DESCRIBE churn_modelling; 

-- Check unique customers
SELECT COUNT(DISTINCT CustomerId) AS unique_customers FROM churn_modelling;

# SUMMARY STATS 

-- Summary for numeric columns
SELECT 
    MIN(CreditScore) AS min_credit,
    MAX(CreditScore) AS max_credit,
    AVG(CreditScore) AS avg_credit,
    STD(CreditScore) AS std_credit,
    MIN(Age) AS min_age,
    MAX(Age) AS max_age,
    AVG(Age) AS avg_age,
    STD(Age) AS std_age,
    MIN(Balance) AS min_balance,
    MAX(Balance) AS max_balance,
    AVG(Balance) AS avg_balance,
    STD(Balance) AS std_balance,
    MIN(EstimatedSalary) AS min_salary,
    MAX(EstimatedSalary) AS max_salary,
    AVG(EstimatedSalary) AS avg_salary,
    STD(EstimatedSalary) AS std_salary
FROM churn_modelling;

# CHURN DISTRUBTION 

-- Count churn vs non-churn
SELECT Exited, COUNT(*) AS cnt, # count of churn 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM churn_modelling),2) AS pct # percentage of churn 
FROM churn_modelling
GROUP BY Exited;

# CHURN BY DEMOGRAPHICS 
-- Gender vs Churn
SELECT Gender, Exited, COUNT(*) AS cnt
FROM churn_modelling
GROUP BY Gender ,Exited
order by Exited;

-- Geography vs Churn
SELECT Geography, Exited, COUNT(*) AS cnt
FROM churn_modelling
GROUP BY Geography, Exited;

-- Age groups vs Churn
SELECT CASE
          WHEN Age BETWEEN 18 AND 25 THEN '18-25'
          WHEN Age BETWEEN 26 AND 35 THEN '26-35'
          WHEN Age BETWEEN 36 AND 45 THEN '36-45'
          WHEN Age BETWEEN 46 AND 55 THEN '46-55'
          ELSE '56+'
       END AS age_group,
       Exited,
       COUNT(*) AS cnt
FROM churn_modelling
GROUP BY age_group, Exited
ORDER BY age_group, Exited

# FEATURE SIGNALS 

-- Average values for churned vs non-churned
SELECT Exited,
       AVG(CreditScore) AS avg_credit,
       AVG(Age) AS avg_age,
       AVG(Balance) AS avg_balance,
       AVG(NumOfProducts) AS avg_products,
       AVG(EstimatedSalary) AS avg_salary
FROM churn_modelling
GROUP BY Exited;

-- Average CreditScore by churn status
SELECT Exited, AVG(CreditScore) AS avg_credit, AVG(Age) AS avg_age, AVG(Balance) AS avg_balance
FROM churn_modelling
GROUP BY Exited;

# Changing the gender column from categrocially to numerical  
set sql_safe_updates = 0 ;
ALTER TABLE churn_modelling ADD COLUMN Gender_Female TINYINT;
ALTER TABLE churn_modelling ADD COLUMN Gender_Male TINYINT;

UPDATE churn_modelling
SET Gender_Female = CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END,
    Gender_Male   = CASE WHEN Gender = 'Male'   THEN 1 ELSE 0 END;
set sql_safe_updates = 1 ; 

# Changing the geographically column from categrocially to numerical  

ALTER TABLE churn_modelling ADD COLUMN Geo_France TINYINT;
ALTER TABLE churn_modelling ADD COLUMN Geo_Spain TINYINT;
ALTER TABLE churn_modelling ADD COLUMN Geo_Germany TINYINT;

UPDATE churn_modelling
SET Geo_France  = CASE WHEN Geography = 'France'  THEN 1 ELSE 0 END,
    Geo_Spain   = CASE WHEN Geography = 'Spain'   THEN 1 ELSE 0 END,
    Geo_Germany = CASE WHEN Geography = 'Germany' THEN 1 ELSE 0 END;
ALTER TABLE churn_modelling ADD COLUMN AgeGroup VARCHAR(10); 

UPDATE churn_modelling
SET Age = CASE
    WHEN Age BETWEEN 18 AND 25 THEN 1
    WHEN Age BETWEEN 26 AND 35 THEN 2
    WHEN Age BETWEEN 36 AND 45 THEN 3
    WHEN Age BETWEEN 46 AND 55 THEN 4
    ELSE 5
END;


# Train and Test Data 
-- Add a random value column
ALTER TABLE churn_modelling ADD COLUMN rand_val FLOAT;

UPDATE churn_modelling SET rand_val = RAND();

-- Create Train and Test sets
CREATE TABLE churn_train AS
SELECT * FROM churn_modelling WHERE rand_val <= 0.8;

CREATE TABLE churn_test AS
SELECT * FROM churn_modelling WHERE rand_val > 0.8;

-- Check the first few rows of the new column
SELECT CustomerId, rand_val
FROM churn_modelling
LIMIT 10;

-- Check how many rows went into train and test sets
SELECT COUNT(*) AS train_rows FROM churn_train;
SELECT COUNT(*) AS test_rows FROM churn_test;

CREATE TABLE feature_weights AS
SELECT 'CreditScore' AS feature, AVG(CASE WHEN Exited=1 THEN CreditScore ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN CreditScore ELSE NULL END) AS weight
FROM churn_train
UNION ALL
SELECT 'Age', AVG(CASE WHEN Exited=1 THEN Age ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN Age ELSE NULL END)
FROM churn_train
UNION ALL
SELECT 'Balance', AVG(CASE WHEN Exited=1 THEN Balance ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN Balance ELSE NULL END)
FROM churn_train
UNION ALL
SELECT 'Gender_Female', AVG(CASE WHEN Exited=1 THEN Gender_Female ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN Gender_Female ELSE NULL END)
FROM churn_train
UNION ALL
SELECT 'Gender_Male', AVG(CASE WHEN Exited=1 THEN Gender_Male ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN Gender_Male ELSE NULL END)
FROM churn_train
UNION ALL
SELECT 'Geo_France', AVG(CASE WHEN Exited=1 THEN Geo_France ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN Geo_France ELSE NULL END)
FROM churn_train
UNION ALL
SELECT 'Geo_Spain', AVG(CASE WHEN Exited=1 THEN Geo_Spain ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN Geo_Spain ELSE NULL END)
FROM churn_train
UNION ALL
SELECT 'Geo_Germany', AVG(CASE WHEN Exited=1 THEN Geo_Germany ELSE NULL END) - AVG(CASE WHEN Exited=0 THEN Geo_Germany ELSE NULL END)
FROM churn_train;

select * from feature_weights ;  

ALTER TABLE churn_test ADD COLUMN predicted_score FLOAT;

UPDATE churn_test
SET predicted_score = 
    CreditScore * (SELECT weight FROM feature_weights WHERE feature='CreditScore') +
    Age * (SELECT weight FROM feature_weights WHERE feature='Age') +
    Balance * (SELECT weight FROM feature_weights WHERE feature='Balance') +
    Gender_Female * (SELECT weight FROM feature_weights WHERE feature='Gender_Female') +
    Gender_Male * (SELECT weight FROM feature_weights WHERE feature='Gender_Male') +
    Geo_France * (SELECT weight FROM feature_weights WHERE feature='Geo_France') +
    Geo_Spain * (SELECT weight FROM feature_weights WHERE feature='Geo_Spain') +
    Geo_Germany * (SELECT weight FROM feature_weights WHERE feature='Geo_Germany');

ALTER TABLE churn_test ADD COLUMN predicted_churn TINYINT;

UPDATE churn_test
SET predicted_churn = CASE
    WHEN predicted_score >= 0 THEN 1
    ELSE 0
END;

SELECT 
    SUM(CASE WHEN predicted_churn = Exited THEN 1 ELSE 0 END)/COUNT(*) AS accuracy
FROM churn_test;
