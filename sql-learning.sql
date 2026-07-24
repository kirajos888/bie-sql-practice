-- -------------------------------------------------------------------
-- Date: 24-July | ThoughtSpot (Advanced) | Topic: SQL Subqueries: How to Write Nested Queries
-- Problem: Using subqueries to aggregate in multiple stages
-- -------------------------------------------------------------------
SELECT category, AVG(ct) AS cou
FROM
(
  SELECT category, EXTRACT(MONTH FROM date::DATE) AS mon, COUNT(incidnt_num) AS ct
    FROM tutorial.sf_crime_incidents_cleandate
    GROUP BY 1,2
)
GROUP BY 1

-- Problem: Subqueries in conditional logic
SELECT *
FROM tutorial.sf_crime_incidents_cleandate
WHERE date::TIMESTAMP = 
(
  SELECT MIN(date::TIMESTAMP)
    FROM tutorial.sf_crime_incidents_cleandate
    
)

-- IN

SELECT DISTINCT category, date
FROM tutorial.sf_crime_incidents_cleandate
WHERE date::TIMESTAMP IN 
(
  SELECT DISTINCT date::TIMESTAMP
    FROM tutorial.sf_crime_incidents_cleandate
    ORDER BY date::TIMESTAMP
    LIMIT 5
    
)

--Joining subqueries

SELECT t.*, su.inc
FROM tutorial.sf_crime_incidents_cleandate t
JOIN 
(
  SELECT date,
          COUNT(incidnt_num) AS inc
           FROM tutorial.sf_crime_incidents_2014_01 t
          GROUP BY 1
    
) su
ON t.date = su.date
ORDER BY su.inc DESC

--Write a query that displays all rows from the three categories with the fewest incidents reported.

SELECT su.ct, t.*
FROM tutorial.sf_crime_incidents_cleandate t
JOIN 
(
  SELECT category,COUNT(incidnt_num) AS ct,
    RANK() OVER (
      ORDER BY COUNT(incidnt_num)

    )     AS inc
  FROM tutorial.sf_crime_incidents_2014_01
  GROUP BY 1
) su     
ON su.category = t.category
AND su.inc <= 3
ORDER BY 1

