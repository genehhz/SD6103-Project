-- Half Publication, Author and Authored Tables
-- Switch to the publicationdb database
USE publicationdb;

-- Create a new database named halfDB
CREATE DATABASE halfDB;

-- Create a view that selects only the odd rows from the publication table
CREATE VIEW half_publication_view AS
SELECT pubid, pubkey, pubtype, title, pubyear, pubkey1, pubkey2, pubkey3 FROM (
    SELECT *, row_number() OVER (ORDER BY pubid) AS row_num
    FROM publication
) AS temp
WHERE row_num % 2 = 1;

-- Create a new table in halfDB database using the data from the half_publication_view
CREATE TABLE halfDB.half_publication AS
SELECT * 
FROM publicationDB.half_publication_view;

-- Create a view that joins the authored table with the half_publication table based on pubid
CREATE VIEW half_authored_view AS
SELECT au.*
FROM authored au
INNER JOIN halfDB.half_publication p ON au.pubid = p.pubid;

-- Create a new table in halfDB database using the data from the half_authored_view
CREATE TABLE halfDB.half_authored AS
SELECT * 
FROM publicationDB.half_authored_view;

-- Create an index on the half_authored table for the authorid column in halfDB to improve query performance
CREATE INDEX idx_halfauthored_authorid ON halfDB.half_authored(authorid);

-- Create a view that selects distinct authors who have authored publications in the half_authored table
CREATE VIEW half_author_view AS
SELECT DISTINCT a.*
FROM author a
INNER JOIN halfDB.half_authored r ON a.authorid = r.authorid;

-- Create a new table in halfDB database using the data from the half_author_view
CREATE TABLE halfDB.half_author AS
SELECT * 
FROM publicationDB.half_author_view;

-- Switch to the halfDB database for subsequent operations
USE halfDB;

-- Temporarily disable foreign key checks to alter table constraints without errors
SET FOREIGN_KEY_CHECKS=0;

-- Add a foreign key constraint to the pubid column of the half_authored table referencing the half_publication table's pubid column
ALTER TABLE half_authored
ADD CONSTRAINT fk_pubid
FOREIGN KEY (pubid)
REFERENCES half_publication (pubid);

-- Add a foreign key constraint to the authorid column of the half_authored table referencing the half_author table's authorid column
ALTER TABLE half_authored
ADD CONSTRAINT fk_authorid
FOREIGN KEY (authorid)
REFERENCES half_author (authorid);

-- Re-enable foreign key checks after altering table constraints
SET FOREIGN_KEY_CHECKS=1;

-- Set the primary key for the half_publication and half_author tables to ensure uniqueness and improve query performance
ALTER TABLE half_publication ADD PRIMARY KEY (pubid);
ALTER TABLE half_author ADD PRIMARY KEY (authorid);

-- The following queries are for verification and data integrity checks
-- Find any records in HALF_AUTHORED that do not have a corresponding record in HALF_PUBLICATION based on pubid
SELECT half_authored.*
FROM half_authored
LEFT JOIN half_publication ON half_authored.pubid = half_publication.pubid
WHERE half_publication.pubid IS NULL; -- No records returned

-- Quarter the publication, author and authored tables
-- Change the current database to halfDB
USE halfDB;

-- Create a new database named quarterDB
CREATE DATABASE quarterDB;

-- Create a view in halfDB that selects only odd rows from the half_publication table
CREATE VIEW quarter_publication_view AS
SELECT pubid, pubkey, pubtype, title, pubyear, pubkey1, pubkey2, pubkey3 FROM (
    SELECT *, row_number() OVER (ORDER BY pubid) AS row_num
    FROM half_publication
) AS temp
WHERE row_num % 2 = 1;

-- Create a new table in quarterDB database using the data from the quarter_publication_view
CREATE TABLE quarterDB.quarter_publication AS
SELECT * 
FROM halfDB.quarter_publication_view;

-- Create a view in halfDB that joins the half_authored table with the quarter_publication table based on pubid
CREATE VIEW quarter_authored_view AS
SELECT au.*
FROM half_authored au
INNER JOIN quarterDB.quarter_publication p ON au.pubid = p.pubid;

-- Create a new table in quarterDB database using the data from the quarter_authored_view
CREATE TABLE quarterDB.quarter_authored AS
SELECT * 
FROM halfDB.quarter_authored_view;

-- Create a view in halfDB that selects distinct authors who have authored publications in the quarter_authored table
CREATE VIEW quarter_author_view AS
SELECT DISTINCT a.*
FROM half_author a
INNER JOIN quarterDB.quarter_authored r ON a.authorid = r.authorid;

-- Create a new table in quarterDB database using the data from the quarter_author_view
CREATE TABLE quarterDB.quarter_author AS
SELECT * 
FROM halfDB.quarter_author_view;

-- Switch to the quarterDB database for subsequent operations
USE quarterDB;

-- Disable foreign key checks before altering tables to add foreign key constraints
SET FOREIGN_KEY_CHECKS=0;

-- Add a foreign key constraint to the quarter_authored table referencing the pubid column of the quarter_publication table
ALTER TABLE quarter_authored
ADD CONSTRAINT fk_quarter_authored_pubid
FOREIGN KEY (pubid)
REFERENCES quarter_publication (pubid);

-- Add a foreign key constraint to the quarter_authored table referencing the authorid column of the quarter_author table
ALTER TABLE quarter_authored
ADD CONSTRAINT fk_quarter_authored_authorid
FOREIGN KEY (authorid)
REFERENCES quarter_author (authorid);

-- Re-enable foreign key checks after adding constraints
SET FOREIGN_KEY_CHECKS=1;

-- Set the pubid column as the primary key of the quarter_publication table
ALTER TABLE quarter_publication
ADD PRIMARY KEY (pubid);

-- Set the authorid column as the primary key of the quarter_author table
ALTER TABLE quarter_author
ADD PRIMARY KEY (authorid);

-- Query to find any records in the quarter_authored table that do not have a corresponding record in the quarter_publication table
SELECT quarter_authored.*
FROM quarter_authored
LEFT JOIN quarter_publication ON quarter_authored.pubid = quarter_publication.pubid
WHERE quarter_publication.pubid IS NULL;
