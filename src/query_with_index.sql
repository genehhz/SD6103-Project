-- Query 1 -- 
-- Composite Index
CREATE INDEX idx1_publication ON publication (pubtype, pubyear);

CREATE INDEX idx1_publication ON publication (pubkey);
CREATE INDEX idx11_publication ON publication (pubyear);
CREATE INDEX idx12_publication ON publication (pubtype);
-- Drop Index
DROP INDEX idx1_publication ON publication;
DROP INDEX idx11_publication ON publication;
DROP INDEX idx12_publication ON publication;

SELECT
   pubtype AS PublicationType,
   COUNT(DISTINCT pubkey) AS PublicationCount
FROM
   publication
WHERE pubyear > 2010
AND pubyear < 2019
GROUP BY pubtype
ORDER BY PublicationCount DESC;

-- Query 2 -- 

-- Create Index

-- Composite Index
CREATE INDEX idx2_publication ON publication (pubkey1, pubkey2, pubyear);

-- Single Column Index
CREATE INDEX idx2_publication ON publication (pubkey1);
CREATE INDEX idx21_publication ON publication (pubkey2);
CREATE INDEX idx22_publication ON publication (pubyear);

-- Drop Index
DROP INDEX idx2_publication ON publication;
DROP INDEX idx21_publication ON publication;
DROP INDEX idx22_publication ON publication;

SELECT DISTINCT ConfName
FROM(
  SELECT 
    pubkey2 AS ConfName, 
        pubyear, 
        COUNT(*) as ConfCount
  FROM publication
  WHERE pubkey1 = 'conf'
  GROUP BY ConfName, pubyear
) tmp
WHERE tmp.ConfCount > 500;

-- Query 3 --

-- Composite INDEX
CREATE INDEX idx3_publication ON publication (pubkey1, pubyear);

-- Single Column INDEX
CREATE INDEX idx3_publication ON publication (pubkey1);
CREATE INDEX idx31_publication ON publication (pubyear);

-- Drop INDEX
DROP INDEX idx3_publication ON publication;
DROP INDEX idx31_publication ON publication;

WITH 
    pubyear_range AS (
        SELECT DISTINCT pubyear
        FROM publication
        WHERE pubyear >= 1970
    ), 

    pubyear_groups AS (
        SELECT 
            pubyear, 
            ((pubyear - 1970) DIV 10) AS group_num
        FROM pubyear_range
    ),
 
    publication_groups AS (
        SELECT 
            pubyear_groups.group_num, 
            COUNT(*) AS num_publications
        FROM pubyear_groups
        JOIN publication ON publication.pubyear = pubyear_groups.pubyear
        WHERE publication.PubKey1 = 'conf'
        GROUP BY pubyear_groups.group_num
    )

SELECT 
    CONCAT('[', 1970 + group_num*10, ', ', 1979 + group_num*10, ']') AS pubyear_range, 
    num_publications
FROM 
    publication_groups
ORDER BY 
    group_num;
    
-- Query 4 --

-- Composite Index
CREATE INDEX idx4_publication ON publication(pubid, pubkey1);
CREATE INDEX idx4_author ON author(authorid, authorname);

-- Single Column Index
CREATE INDEX idx4_publication ON publication(pubkey1);
CREATE INDEX idx4_author ON author(authorname);

-- Drop Index
DROP INDEX idx4_publication ON publication;
DROP INDEX idx4_author ON author;

SELECT 
    a.authorname AS author, 
    COUNT(DISTINCT pa2.authorid) AS collaboratorscount
FROM 
    Author a
JOIN 
    authored pa1 ON a.authorid = pa1.authorid
JOIN 
    Publication p ON pa1.pubid = p.pubid
JOIN 
    authored pa2 ON pa1.pubid = pa2.pubid AND pa1.authorid != pa2.authorid
WHERE 
    (p.pubkey1 = 'journals' OR p.pubkey1 = 'conf')
    AND LOWER(p.title) LIKE '%data%'
GROUP BY 
    a.authorid
ORDER BY 
    collaboratorscount DESC 
LIMIT 10;

SELECT 
    a.authorname AS author, 
    COUNT(DISTINCT pa2.authorid) AS collaboratorscount
FROM 
    Author a
INNER JOIN 
    Authored pa1 ON a.authorid = pa1.authorid
INNER JOIN 
    (SELECT pubid FROM Publication WHERE (pubkey1 = 'journals' OR pubkey1 = 'conf') AND LOWER(title) LIKE '%data%') AS p ON pa1.pubid = p.pubid
INNER JOIN 
    Authored pa2 ON pa1.pubid = pa2.pubid AND pa1.authorid != pa2.authorid
GROUP BY 
    a.authorid, a.authorname
ORDER BY 
    collaboratorscount DESC 
LIMIT 10;

-- Query 5 -- 

-- Composite Index
CREATE INDEX idx5_publication ON publication(pubid, pubkey1, pubyear);
CREATE INDEX idx5_author ON author(authorid, authorname);

-- Single Column Index
CREATE INDEX idx5_publication ON publication(pubkey1);
CREATE INDEX idx51_publication ON publication(pubyear);
CREATE INDEX idx5_author ON author(authorname);

-- Drop Index
DROP INDEX idx5_publication ON publication;
DROP INDEX idx51_publication ON publication;
DROP INDEX idx5_author ON author;

SELECT 
  author.authorname AS author, 
    COUNT(*) AS num_publications
FROM publication
INNER JOIN authored ON publication.pubid = authored.pubid
INNER JOIN author ON authored.authorID = author.authorid
WHERE publication.pubyear >= YEAR(CURDATE()) - 5
AND publication.title LIKE '%Data%'
AND (publication.PubKey1 = 'conf' OR publication.PubKey1 = 'journals')
GROUP BY author.authorname
ORDER BY num_publications DESC
LIMIT 10;

-- Query 6 -- 

-- Create Composite Index
CREATE INDEX idx6_publication ON publication(pubyear, pubtype, pubkey2);

-- Create Single Column Index
CREATE INDEX idx6_publication ON publication(pubyear);
CREATE INDEX idx61_publication ON publication(pubtype);
CREATE INDEX idx62_publication ON publication(pubkey2);

-- Drop Index
DROP INDEX idx6_publication ON publication;

-- Drop Index
DROP INDEX idx6_publication ON publication;
DROP INDEX idx61_publication ON publication;
DROP INDEX idx62_publication ON publication;

SELECT pubkey2, pubyear, pubtype, COUNT(*) 
FROM publication 
WHERE pubkey2 IN (SELECT DISTINCT(pubkey2)
                  FROM publication
                  WHERE title LIKE '%June%' 
                  AND pubtype = 'inproceedings' 
                  AND pubkey1 LIKE 'conf%')
GROUP BY pubkey2, pubyear, pubtype
HAVING COUNT(*) > 100 
ORDER BY COUNT(*) DESC;

-- Query 7a --
-- Pre-filter publications to only consider those within the last 30 years

-- Create Single Column Index
CREATE INDEX idx7a_publication ON publication(pubyear);
CREATE INDEX idx7a_author ON author(authorname);

-- Create Composite Index
CREATE INDEX idx7a_publication ON publication(pubid, pubyear);
CREATE INDEX idx7a_author ON author(authorid, authorname);

-- Drop Index
DROP INDEX idx7a_publication ON publication;
DROP INDEX idx7a_author ON author;

WITH RecentPublications AS (
    SELECT pubid, pubyear
    FROM publication
    WHERE pubyear >= (SELECT YEAR(CURDATE()) - 29)
),
FilteredAuthors AS (
    SELECT author.authorid, author.authorName
    FROM author
    WHERE SUBSTRING_INDEX(author.authorName, ' ', -1) LIKE 'H%'
)
SELECT 
    fa.authorName AS author
FROM 
    FilteredAuthors fa
INNER JOIN 
    authored au ON fa.authorid = au.authorid
INNER JOIN 
    RecentPublications rp ON rp.pubid = au.pubId
GROUP BY 
    fa.authorName
HAVING 
    COUNT(DISTINCT rp.pubyear) = 30;

-- Query 7b --

-- Single Column Index
CREATE INDEX idx7b_publication ON publication(pubyear);
CREATE INDEX idx7b_author ON author(authorname);

-- Composite Index
CREATE INDEX idx7b_publication ON publication(pubid, pubyear);
CREATE INDEX idx7b_author ON author(authorid, authorname);

-- Drop Index
DROP INDEX idx7b_publication ON publication;
DROP INDEX idx7b_author ON author;

Explain
SELECT A.authorid, A.authorname, COUNT(*)
FROM author A JOIN authored AP
ON A.authorid = AP.authorid
WHERE A.authorid IN (
 -- Get the authors of Publication with the earliest Publication date
 SELECT DISTINCT AP.authorid
 FROM authored AP JOIN publication P ON AP.pubid = P.pubid
 WHERE P.pubyear = (SELECT MIN(pubyear) FROM publication)
 )
GROUP BY A.authorid , A.authorname;

-- Query 8 --

-- Return the top 5 most common first name of the author that published in "US" in the last 2 year.
-- Single Column Index
CREATE INDEX idx8_publication ON publication(pubyear);
CREATE INDEX idx8_author ON author(authorname);

-- Composite Index
CREATE INDEX idx8_publication ON publication(pubid, pubyear);
CREATE INDEX idx8_author ON author(authorid, authorname);

-- Drop Index
DROP INDEX idx8_publication ON publication;
DROP INDEX idx8_author ON author;

SELECT 
  SUBSTRING_INDEX(a.authorname, ' ', 1) AS first_name,
  COUNT(*) AS publication_count
FROM 
  author a
JOIN 
  authored au ON a.authorid = au.authorid
JOIN 
  publication p ON au.pubid = p.pubid
WHERE 
  p.title LIKE '%US%' 
  AND p.pubyear >= YEAR(CURDATE()) - 2
GROUP BY 
  first_name
ORDER BY 
  publication_count DESC
LIMIT 5;