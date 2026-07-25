# bie-sql-practice — SQL Practice Problems and Solutions

Welcome! This repository contains SQL practice problems with example schemas, queries, and explanations to help you learn and test SQL skills.

How to use
- Pick a problem, create the sample tables in your database (Postgres, SQLite, MySQL, etc.), insert the sample rows, and run the provided query.
- Each problem includes: a short description, sample schema + data, the query solution, and a brief explanation.

Problem 1 — Simple SELECT and WHERE
Description: Get all customers from "New York".

Schema:
```sql
CREATE TABLE customers (
  id INTEGER PRIMARY KEY,
  name TEXT,
  city TEXT
);

INSERT INTO customers (id, name, city) VALUES
(1, 'Alice', 'New York'),
(2, 'Bob', 'Chicago'),
(3, 'Carol', 'New York');
