\-- -------------------------------------------------------------------

\-- Date: 4-Aug | The Date Warehouse Toolkit  | Topic: Dimension Tables for Descriptive Context

\-- -------------------------------------------------------------------



fact tables - textual context - dimension tables - who/what/how/where/why/when associated with the event

dimension atbles - handful to 100+ attribute columns - but fewer rows - each dimension by single primary key - referential integrity key

attributes - constraints, groupings, etc

usability = attributes should be real words - not codes - improve readability for business users

attributes define quality of data

numerical data can be fact or a dimension- fact when it can have a variety of data- dimension when it is constant and drives constraint and grouping.

dimension tables are denormalized with many to one relationship in one dimension table - normalizing or snawflaking by keep ony  brand cde in a table with lookup to all other attributesfrom separate tables

star join - fact table joined with dimensional tables for each business process



\-- -------------------------------------------------------------------

\-- Date: 8-Aug | The Date Warehouse Toolkit  | Topic: Dimension Tables for Descriptive Context

\-- -------------------------------------------------------------------



simplifying star joins improves performance - index and attack fact tables

dimension models are not built for only type of business of problem; it can be extended for every problem

Kimball's DW/BI archi - ops source sys, ETL system, data presentation sys, and business intel app

ops source sys- no historical data; ERP sys manages that; only for getting data

ETL- reading and understanding source data; cleanses, process engg, makes it ready for final business presentation



\-- -------------------------------------------------------------------

Normalization Spectrum

Form | Structure | Data Redundancy | Best for | Main Weakness

Denormalized | 1 large table | Repeat same data | Quick Reading, Analytics, DWH | Update errors, slow writing

1NF | Flat table, no lists inside cells, single primary key | Row level duplication | Basic spreadsheets | redundant texts

2NF | Multiple tables, no partial dependencies on combined keys | Transitive links still exist | simple relational datasets | Non-key fields still duplicate data

3NF | Highly segmented tables, every column links to primary key | Data stored exactly once | Transactional systems (banking, e-commerce) | Reading requires multiple joins, slower read



Side-by-side normalization comparison

Form | Goal | What it eliminates | Golden rule

1NF | Make data atomic | Repeated groups and duplicate rows | Each cell must hold exactly one value. Every table must have a primary key

2NF | Remove partial links | Partial dependencies (only an issue with composite keys) | Each non-key to link to the entire primary key

3NF | Remove non-key links | Transitive dependencies (columns depending on other non-key columns) | Every non-key column to dependent only on primary key



\-- -------------------------------------------------------------------

Presentation - presented , stored in star schema or OLAP cubes

Feature | Star schema | OLAP

Definition | Fact table (numerical) at center with Dimension tables (customer, product, etc) at star points | Online Analytical Processing  Cube takes data from Star schema and creates immutable outputs of every different combination of parameters.

Data Structure | Fact n Dimension tbls | Multi-dimensional array (hypercube)

Calculation timing | on the fly | pre-calculated and cached

Storage engine | Std relational databases (PostgreSQL) | Multidimensional OLAP engines (Apache Kylin)

Query language | SQL | MDX (Multidimensional eXpressions) or specialized APIs

Query Speeds | Fast | Instantaneous

Flexibility | High (easy to add attributes or change logic) | Low (requires full or partial rebuild)



1\. Always dimensionsional models - relational star schema or OLAP cubes

2\. provide granular data for adhoc user queries

3\. Adherence to the bus architecture or enterprise



\-- -------------------------------------------------------------------

\-- Date: 9-Aug | The Date Warehouse Toolkit  | Topic: Dimension Tables for Descriptive Context

\-- -------------------------------------------------------------------



BI systems

throughput

quality, integrity, consistency

users shouldn't dip into unfinished queries, asking questions which are unpleasant



\-- -------------------------------------------------------------------

\-- Date: 12-Aug | The Date Warehouse Toolkit  | Topic: Customer order delivery from Amazon

\-- -------------------------------------------------------------------



Scenario: Customer orders product. Package travels from Amazon warehouse to delivery station and then to customer doorstep

Kimball questions

Business process: Package delivery

Grain: One row per package delivery attempted/delivered to a customer 

Dimensions: customer, products, warehouses, delivery stations, routes, date, regions, zip codes, driver

Facts: package scan for delivery to a customer; from a warehouse to a delivery station via the optimized route; selling price, discount, sold at price, tax, distance travelled, shipping costs, weight



Star schema layout





dim\_customer



customer\_id (PK)

address

contact





dim\_product			facts\_cust\_orders			dim\_date

&#x09;								

product\_id (PK)			customer\_id (FK)			date (PK)

category			product\_id (FK)				time\_zone

price				warehouse\_id (FK)

&#x09;			date (FK)

&#x09;			<measure>

dim\_warehouse			sold\_at\_price

&#x09;			weight

warehouse\_id(PK)		distance\_travelled

region				shipping\_costs

address





Scenario 2: Customer returns

Business process: customers returning packages ordered from Amazon

Grain: Return package pickup attempt from customer

Dimensions: customer, product, return reason, pickup driver, warehouse, date

Facts: sold price, refund amount, distance travelled, transportation cost



Star schema:



dim\_customer



customer\_id (PK)

address

contact





dim\_product			facts\_cust\_orders			dim\_date

&#x09;								

product\_id (PK)			customer\_id (FK)			date (PK)

category			product\_id (FK)				time\_zone

price				warehouse\_id (FK)

&#x09;			date (FK)

&#x09;			<measure>

dim\_warehouse			sold\_at\_price

&#x09;			weight

warehouse\_id(PK)		distance\_travelled

region				trans\_costs

address				refund\_amt





Refined Star schema with following corrections.

1\. Surrogate keys

2\. Date in integer format

3\. Degenerate dimensions





dim\_customer



customer\_key (INT) (PK)

customer\_id (NK)

address

contact





dim\_product			facts\_cust\_orders			dim\_date

&#x09;								

product\_key (INT) (PK)

product\_id (NK)			customer\_key (FK)			date (INT) (PK)

category			product\_key (FK)			time\_zone

price				warehouse\_key (FK)			year

&#x09;			date (FK)				quarter

&#x09;			<degenerate dimension>			month

&#x09;			return\_reason				week

&#x09;			<measure>				day

dim\_warehouse			sold\_at\_price

&#x09;			weight

warehouse\_key (INT) (PK)

warehouse\_id(NK)		distance\_travelled

region				trans\_costs

address				refund\_amt





Query sample:

Business Question: "Find the top 3 product categories with the highest total refund amount in the 'West' warehouse region during Q2 of 2026."



thinking:

sum refund amt

group by product cat

filter west , Q2, 2026

top 3 using DENSE\_RANK



query:



WITH t\_join AS 

(SELECT p.category, SUM(f.refund\_amt) AS total\_refund

&#x09;FROM facts\_cust\_orders f

&#x09;JOIN dim\_warehouse w

&#x09;on f.warehouse\_key = w.warehouse\_key

&#x09;JOIN dim\_product p

&#x09;ON f.product\_key = p.product\_key

&#x09;JOIN dim\_date d

&#x09;ON f.date = d.date

&#x09;WHERE w.region = 'West' 

&#x09;AND d.year = 2026 --EXTRACT(date, 'Year') = 2026

&#x09;AND d.quarter --EXTRACT(date, 'Quarter') = 2

&#x09;GROUP BY p.category

&#x09;ORDER BY 2 DESC

),

t\_rank AS 

(SELECT category, total\_refund,

&#x09;DENSE\_RANK() OVER (

&#x09;	ORDER BY total\_refund DESC

&#x09;) AS rk

&#x09;FROM t\_join

)



SELECT category, total\_refund

&#x09;FROM t\_rank

&#x09;WHERE rk <= 3





Faster query (not deterministic):

SELECT p.category, SUM(f.refund\_amt) AS total\_refund

&#x09;FROM facts\_cust\_orders f

&#x09;JOIN dim\_warehouse w

&#x09;on f.warehouse\_key = w.warehouse\_key

&#x09;JOIN dim\_product p

&#x09;ON f.product\_key = p.product\_key

&#x09;JOIN dim\_date d

&#x09;ON f.date = d.date

&#x09;WHERE w.region = 'West' 

&#x09;AND d.year = 2026 --EXTRACT(date, 'Year') = 2026

&#x09;AND d.quarter --EXTRACT(date, 'Quarter') = 2

&#x09;GROUP BY p.category

&#x09;ORDER BY 2 DESC

&#x09;LIMIT 3



\-- -------------------------------------------------------------------

\-- Date: 13-Aug | The Date Warehouse Toolkit  | Topic: Slowly changing dimensions Type 2

\-- -------------------------------------------------------------------



To keep historical data intact, we use surrogate keys to record changing parameters like address. We define the periodicity of the parameter and define if its active using boolean.



SCD Type 1 - overwrite

SCD Type 2 - Add new row

SCD Type 3 - Add new column





\-- -------------------------------------------------------------------

\-- Date: 15-Aug | The Date Warehouse Toolkit  | Topic: Slowly changing dimensions Type 2 (code)

\-- -------------------------------------------------------------------



MERGE dim\_customer AS target

USING (

&#x09;SELECT 

&#x09;s.customer\_id,

&#x09;s.address,

&#x09;CURRENT\_DATE AS s.start\_date	

&#x09;FROM cust\_updates s

) AS source

ON target.customer\_id = source.customer\_id

AND target.is\_current = TRUE



\--Step 1: Expire old data



WHEN MATCHED AND target.address <> source.address THEN

UPDATE SET

&#x09;target.end\_date = CURRENT\_DATE,

&#x09;is\_current = FALSE



\--Step 2: Insert new data

WHEN NOT MATCHED THEN

INSERT(

&#x09;customer\_id,

&#x09;address,

&#x09;start\_date,

&#x09;end\_date,

&#x09;is\_current	

)



VALUES (

&#x09;source.customer\_id,

&#x09;source.address,

&#x09;source.start\_date,

&#x09;'9999-12-31'::DATE,

&#x09;TRUE

);



\--Step 3: Insert the new active version of customer details



INSERT INTO dim\_customer(

&#x09;customer\_id,

&#x09;address,

&#x09;start\_date,

&#x09;end\_date,

&#x09;is\_current

)



SELECT 

&#x09;s.customer\_id,

&#x09;s.address,

&#x09;CURRENT\_DATE AS start\_date,

&#x09;'9999-12-31'::DATE AS end\_date,

&#x09;is\_current = TRUE

FROM dim\_customer t

JOIN cust\_updates s

ON t.customer\_id = s.customer\_id

WHERE t.end\_date = CURRENT\_DATE

AND t.is\_currrent = FALSE



\--Important learnings

1\. Do not update SCD Type 2 if address is unchanged

2\. End date has to be updated not as NULL

3\. Surrogate key is autogenerated; Identity(1,1) in Amazon Redshift



\-- -------------------------------------------------------------------

\-- Date: 15-Aug | The Date Warehouse Toolkit  | Topic: Fact table types

\-- -------------------------------------------------------------------



Feature | Transactional | Periodic snapshot | Accumulating snapshot

Time focus | single point in time | regular intervals | lifecycle with milestone dates

Grain | one transaction per row | one row per entity per event | one row per workflow instance

Update behavior | insert only | Insert only | Update heavy

Fact additivity | Fully additive | Semi-additive (cannot sum over time; but can average) | Non-additive

Row count | Very high | High (Predictable) | Moderate (1 row per lifecycle entity)

Use case | POS sales, web clicks | Bank account | Online orders, insurance claims



\-- -------------------------------------------------------------------

\-- Date: 15-Aug | The Date Warehouse Toolkit  | Topic: Amazon BIE Data Warehousing Technical Scenario - Amazon Merch on Demand Network Expansion

\-- -------------------------------------------------------------------



Order Processing Lifecycle: When a customer orders a custom shirt, the order passes through 4 distinct pipeline milestones: Order Placed, Artwork Printed, Item Packaged, Package Delivered.



Part 1



Fact Table Types

Order processing lifecycle tracking using accumulating snapshot table

Daily warehouse inventory to be tracked by periodic snapshot table



SCD strategy

dim\_fulfillment to be updated using Slowly changing dimension Type 2

warehouse\_key (INT) (PK)

start\_date

end\_date

is\_current



Schema





dim\_customer



customer\_key (INT) (PK)

customer\_id (NK)

address 

phone



dim\_fulfillment			facts\_cycle			dim\_date



warehouse\_key (INT) (PK)	warehouse\_key (FK)		date (INT) (PK)

warehouse\_id (NK)						year

region				customer\_key (FK)		week

address				product\_key (FK)		month

start\_date							day

end\_date							time\_zone

is\_current			Order\_Placed\_date (FK)

&#x09;			Artwork\_Printed\_date (FK)

&#x09;			Item Packaged\_date (FK)

&#x09;			Package\_delivered\_date (FK)

&#x09;			<degenerate dimension>

&#x09;			order\_status

&#x09;			<measures>

&#x09;			fulfillment\_cycle\_time

&#x09;			shipping\_cost

&#x09;			distance\_travelled



dim\_product



product\_key (INT) (PK)

product\_id (NK)

price

category





facts\_inventory\_snapshot



product\_key (FK)

warehouse\_key (FK)

date (FK)

<measure>

qty\_on\_hand





Part 2: Executive Query Request:

"For orders placed in the month of July 2026, find the top 3 Fulfillment Centers (by code/id, e.g., 'BFI4') that had the fastest average delivery time (in hours, between order\_placed and package\_delivered). Handle potential ties at the 3rd spot fairly, and ensure incomplete/undelivered orders do NOT skew or corrupt the average."



thinking

monthly snapshot

FC level

delivery time = delivered - placed

extract hours

dense rank

<= 3, July 2026



join date w facts

filter July 2026 order placed, delivered NOT NULL

join w fc tbls

delivery time = delivered - placed; extract hours

dense rank

<=3

fc ids like bfi4 as op



query:

WITH t\_join AS (

&#x09;SELECT df.warehouse\_id, EXTRACT(EPOCH FROM Package\_delivered\_date - Order\_Placed\_date) AS dlvy\_time

&#x09;FROM facts\_cycle f			

&#x09;JOIN dim\_date d

&#x09;ON f.Order\_Placed\_date = d.date

&#x09;AND d.month = 7

&#x09;AND d.year = 2026

&#x09;AND f.package\_delivered\_date IS NOT NULL

&#x09;JOIN dim\_fulfillment df

&#x09;ON f.warehouse\_key = df.warehouse\_key

),

t\_avg AS (

&#x09;SELECT warehouse\_id, AVG(dlvy\_time) AS a\_dlvy\_time

&#x09;FROM t\_join

&#x09;GROUP BY 1

&#x09;

),

t\_rank AS (

&#x09;SELECT warehouse\_id, a\_dlvy\_time,

&#x09;DENSE\_RANK() OVER (

&#x09;	ORDER BY a\_dlvy\_time

&#x09;) AS rk

&#x09;FROM t\_avg

)



SELECT warehouse\_id

&#x09;FROM t\_rank

&#x09;WHERE rk <= 3





\-- -------------------------------------------------------------------

\-- Date: 16-Aug | The Date Warehouse Toolkit  | Topic: XYZ

\-- -------------------------------------------------------------------





