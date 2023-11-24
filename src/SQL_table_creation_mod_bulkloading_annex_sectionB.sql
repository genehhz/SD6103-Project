-- Create a new database named publicationDB
CREATE DATABASE publicationDB;
-- Select the newly created database for use
USE publicationDB;

-- Set the GLOBAL local_infile variable to true to allow for local data loading
SET GLOBAL local_infile = true;

-- Drop any existing tables named authored, publication, and author if they exist to avoid conflicts
DROP TABLE IF EXISTS authored;
DROP TABLE IF EXISTS publication; 
DROP TABLE IF EXISTS author;

-- Create a new table named Publication with specified columns and data types
CREATE TABLE Publication(
    pubid INT NOT NULL,
    pubkey VARCHAR(255),
    pubtype VARCHAR(255),
    title VARCHAR(10000),
    pubyear INT,
    PRIMARY KEY (pubid) -- Sets pubid as the primary key for the table
);

-- Load data into the Publication table from a CSV file located at the given path
-- Note: The LOAD DATA INFILE path should be changed to the actual path where the dblp.csv file is located.
LOAD DATA INFILE 'D://developer_tools//MySQL//MySQL Server 8.0//Uploads//dblp.csv'
INTO TABLE Publication
CHARACTER SET latin1 -- Specifies the character set for the data
FIELDS TERMINATED BY ',' -- Specifies that fields are terminated by commas
OPTIONALLY ENCLOSED BY '"' -- Fields are optionally enclosed by double quotes
LINES TERMINATED BY '\n' -- Specifies that lines are terminated by newlines
IGNORE 1 ROWS -- Ignores the first row, which often contains column headers
(
    -- Temporary variables for each column in the CSV file
    -- The number of @col variables should match the number of columns in your CSV file
    @col1, @col2, @col3, @col4, @col5, @col6, @col7, @col8, @col9, @col10, 
    @col11, @col12, @col13, @col14, @col15, @col16, @col17, @col18, @col19, 
    @col20, @col21, @col22, @col23, @col24, @col25, @col26, @col27,@col28
)
-- Set the actual columns in Publication table based on the temporary variables from the CSV file
set pubid=@col1,pubkey=@col4,pubtype=@col5,title=@col7,pubyear=IF(@col9 = 'NaN',NULL, REPLACE(@col9,' ',''));

-- Modify the Publication table to add additional columns for split pubkey values
ALTER TABLE publication
ADD COLUMN pubkey1 VARCHAR(255),
ADD COLUMN pubkey2 VARCHAR(255),
ADD COLUMN pubkey3 VARCHAR(255);

-- Disable safe updates to allow updates without specifying a WHERE clause
SET sql_safe_updates=0; 
-- Update the Publication table to split pubkey into three separate columns based on '/'
UPDATE publication
SET 
   pubkey1 = SUBSTRING_INDEX(pubkey, '/', 1),
   pubkey2 = SUBSTRING_INDEX(SUBSTRING_INDEX(pubkey, '/', 2), '/', -1),
   pubkey3 = SUBSTRING_INDEX(pubkey, '/', -1);

-- Create a new Author table with authorid and authorname as columns
CREATE TABLE Author(
    authorid INT,
    authorname VARCHAR(255),
    PRIMARY KEY (authorid) -- Sets authorid as the primary key for the table
);

-- Load data into the Author table from a CSV file located at the given path
-- Note: The LOAD DATA INFILE path should be changed to the actual path where the unique_author.csv file is located.
LOAD DATA INFILE 'D://developer_tools//MySQL//MySQL Server 8.0//Uploads//unique_author.csv'
INTO TABLE Author
CHARACTER SET latin1 -- Specifies the character set for the data
FIELDS TERMINATED BY ',' -- Specifies that fields are terminated by commas
OPTIONALLY ENCLOSED BY '"' -- Fields are optionally enclosed by double quotes
LINES TERMINATED BY '\n' -- Specifies that lines are terminated by newlines
IGNORE 1 ROWS -- Ignores the first row as it often contains column headers
(
    -- Temporary variables for each column in the CSV file
    @col1, @col2, @col3
)
-- Set the actual columns in Author table based on the temporary variables from the CSV file
SET authorid=@col3,authorname=@col2;

-- Update a specific record in Author table where authorid is 11 to 'No Author'
UPDATE author
SET authorname = 'No Author'
WHERE authorid = 11;

-- Create a new Authored table to represent a many-to-many relationship between Authors and Publications
CREATE TABLE Authored(
    authorid INT,
    pubid INT,
    FOREIGN KEY (authorid) REFERENCES Author(authorid), -- Defines a foreign key relationship with Author table
    FOREIGN KEY (pubid) REFERENCES Publication(pubid) -- Defines a foreign key relationship with Publication table
);

-- Temporarily disable foreign key checks to allow loading data without constraint checks
SET FOREIGN_KEY_CHECKS=0;

-- Load data into the Authored table from a CSV file located at the given path
-- Note: The LOAD DATA INFILE path should be changed to the actual path where the author.csv file is located.
LOAD DATA INFILE 'D://developer_tools//MySQL//MySQL Server 8.0//Uploads//author.csv'
INTO TABLE Authored
CHARACTER SET latin1 -- Specifies the character set for the data
FIELDS TERMINATED BY ',' -- Specifies that fields are terminated by commas
OPTIONALLY ENCLOSED BY '"' -- Fields are optionally enclosed by double quotes
LINES TERMINATED BY '\n' -- Specifies that lines are terminated by newlines
IGNORE 1 ROWS -- Ignores the first row as it often contains column headers
(
    -- Temporary variables for each column in the CSV file
    @col1, @col2, @col3,@col4,@col5
)
-- Set the actual columns in Authored table based on the temporary variables from the CSV file
set authorid=@col5,pubid=@col2;

-- Re-enable foreign key checks after loading data into Authored table
SET FOREIGN_KEY_CHECKS=1;
