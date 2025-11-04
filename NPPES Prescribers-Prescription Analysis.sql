--  Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- 1912011792 David Coffey
SELECT p.npi, pr.total_claim_count
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
ORDER BY total_claim_count DESC;

	
--  Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description, pr.total_claim_count
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
ORDER BY total_claim_count DESC;

--  Which specialty had the most total number of claims (totaled over all drugs)?
-- Family Practice
SELECT p.specialty_description, pr.total_claim_count
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
GROUP BY p.specialty_description, pr.total_claim_count
ORDER BY total_claim_count DESC;

--  Which specialty had the most total number of claims for opioids?
-- Nurse Practicioner
SELECT p.specialty_description, 
    SUM(pr.total_claim_count) AS total_opioid_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
JOIN drug d ON pr.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY p.specialty_description
ORDER BY total_opioid_claims DESC;

-- Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT p.specialty_description, pr.total_claim_count
FROM prescriber p
LEFT JOIN prescription pr ON p.npi = pr.npi
WHERE pr.npi IS NULL
GROUP BY p.specialty_description, pr.total_claim_count;

--  For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT p.specialty_description, 
  ROUND(100.0 * SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN pr.total_claim_count ELSE 0 END) / SUM(pr.total_claim_count), 2) AS opioid_claim_percentage
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
JOIN drug d ON pr.drug_name = d.drug_name
GROUP BY p.specialty_description
ORDER BY opioid_claim_percentage DESC;

-- Which drug (generic_name) had the highest total drug cost?
-- INSULIN GLARGINE,HUM.REC.ANLOG
SELECT d.generic_name, SUM(pr.total_drug_cost) AS total_drug_cost
FROM drug d
JOIN prescription pr ON d.drug_name = pr.drug_name
GROUP BY d.generic_name
ORDER BY total_drug_cost DESC
LIMIT 1;


--  Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
-- LEDIPASVIR/SOFOSBUVIR
SELECT d.generic_name, ROUND(SUM(pr.total_drug_cost / pr.total_30_day_fill_count), 2) AS total_drug_cost_per_day
FROM drug d
JOIN prescription pr ON d.drug_name = pr.drug_name
GROUP BY d.generic_name
ORDER BY total_drug_cost_per_day DESC
LIMIT 1;

--For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name,
    CASE 
        WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type
FROM drug
ORDER BY drug_type;

--  Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
WITH categorized_drugs AS (
    SELECT 
        d.drug_name,
        CASE 
            WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
            ELSE 'neither'
        END AS drug_type
    FROM drug d
)
SELECT 
    cd.drug_type, 
    SUM(pr.total_drug_cost)::MONEY AS total_cost
FROM categorized_drugs cd
JOIN prescription pr ON cd.drug_name = pr.drug_name
GROUP BY cd.drug_type
ORDER BY cd.drug_type;


-- How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT DISTINCT COUNT (c.cbsa) AS cbsa_tn
FROM cbsa c
JOIN fips_county fc USING (fipscounty)
WHERE fc.state = 'TN'

-- Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT c.cbsaname AS cbsaname_tn, SUM(p.population) AS total_population
FROM cbsa c
JOIN fips_county fc USING (fipscounty)
JOIN population p USING (fipscounty)
WHERE fc.state = 'TN'
GROUP BY cbsaname_tn
ORDER BY total_population DESC;

-- What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
WITH county_data AS (
    SELECT fc.county AS county_name_non_cbsa, 
        p.population AS county_pop_non_cbsa
    FROM fips_county fc
    JOIN population p USING (fipscounty) 
    LEFT JOIN cbsa c USING (fipscounty)
    WHERE fc.state = 'TN'
    AND c.fipscounty IS NULL
    ORDER BY county_pop_non_cbsa DESC
    LIMIT 1)

SELECT county_name_non_cbsa, county_pop_non_cbsa AS max_population FROM county_data;


-- Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
WITH high_claim_drugs AS (
    SELECT drug_name, total_claim_count
    FROM prescription
    WHERE total_claim_count >= 3000
    ORDER BY total_claim_count DESC)
	
SELECT d.drug_name,
    CASE 
        WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,
    hc.total_claim_count
FROM high_claim_drugs hc
JOIN drug d ON hc.drug_name = d.drug_name
ORDER BY drug_type;

-- Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
WITH high_claim_drugs AS (
    SELECT drug_name, total_claim_count
    FROM prescription p
    WHERE total_claim_count >= 3000
    ORDER BY total_claim_count DESC)

SELECT d.drug_name, h.total_claim_count,
    CASE 
        WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,
    pr.nppes_provider_first_name,
    pr.nppes_provider_last_org_name
FROM high_claim_drugs h
JOIN drug d ON h.drug_name = d.drug_name
JOIN prescription p ON h.drug_name = p.drug_name 
JOIN prescriber pr ON pr.npi = p.npi
ORDER BY h.total_claim_count DESC;


-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.

--  First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT p.npi, d.drug_name
FROM prescriber p
CROSS JOIN drug d 
WHERE p.specialty_description = 'Pain Management'
AND p.nppes_provider_city = 'NASHVILLE'
AND d.opioid_drug_flag = 'Y';


-- Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
-- Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 

SELECT p.npi,
    d.drug_name,
    COALESCE(SUM(pc.total_claim_count), 0) AS total_claim_count
FROM prescriber p
CROSS JOIN drug d
LEFT JOIN prescription pc ON p.npi = pc.npi AND d.drug_name = pc.drug_name
WHERE p.specialty_description = 'Pain Management'
    AND p.nppes_provider_city = 'NASHVILLE'
    AND d.opioid_drug_flag = 'Y'
GROUP BY p.npi, d.drug_name
ORDER BY total_claim_count DESC;
    
-- Write a query which returns the total number of claims for these two groups.

-- specialty_description         |total_claims|
-- ------------------------------|------------|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|

SELECT p.specialty_description, COUNT(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY p.specialty_description;


-- also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this.

-- specialty_description         |total_claims|
-- ------------------------------|------------|
--                               |      126759|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|

SELECT 'Total' AS specialty_description, SUM(total_claims) AS total_claims
FROM (
    SELECT COUNT(pr.total_claim_count) AS total_claims
    FROM prescriber p
    JOIN prescription pr ON p.npi = pr.npi
    WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
) subquery

UNION ALL

SELECT p.specialty_description, COUNT(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
WHERE p.specialty_description IN ('Interventional Pain Management')
GROUP BY p.specialty_description

UNION ALL

SELECT p.specialty_description, COUNT(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
WHERE p.specialty_description IN ('Pain Management')
GROUP BY p.specialty_description;


-- 3. Now, instead of using UNION, make use of GROUPING SETS to achieve the same output.
SELECT 
    COALESCE(p.specialty_description, 'Total') AS specialty_description,
    COUNT(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
    (p.specialty_description), ());

-- also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

-- specialty_description         |opioid_drug_flag|total_claims|
-- ------------------------------|----------------|------------|
--                               |                |      129726|
--                               |Y               |       76143|
--                               |N               |       53583|
-- Pain Management               |                |       72487|
-- Interventional Pain Management|                |       57239|

SELECT 
    COALESCE(p.specialty_description, 'Total') AS specialty_description,
    COALESCE(d.opioid_drug_flag, 'All') AS opioid_drug_flag,
    COUNT(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
JOIN drug d ON pr.drug_name = d.drug_name
WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
    (p.specialty_description, d.opioid_drug_flag),
    (p.specialty_description),
    ()
)
ORDER BY specialty_description, opioid_drug_flag;


-- Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description).
SELECT 
    COALESCE(p.specialty_description, 'Total') AS specialty_description,
    COALESCE(d.opioid_drug_flag, 'All') AS opioid_drug_flag,
    COUNT(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
JOIN drug d ON pr.drug_name = d.drug_name
WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(opioid_drug_flag, specialty_description)
ORDER BY 
    specialty_description,
    opioid_drug_flag;


-- change query to use the CUBE function instead of ROLLUP. How does this impact the output?
-- totals per category are included
SELECT 
    COALESCE(p.specialty_description, 'Total') AS specialty_description,
    COALESCE(d.opioid_drug_flag, 'All') AS opioid_drug_flag,
    COUNT(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
JOIN drug d ON pr.drug_name = d.drug_name
WHERE p.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE(specialty_description, opioid_drug_flag)
ORDER BY 
    specialty_description,
    opioid_drug_flag;


--  create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

-- city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-- -----------|-------|--------|-----------|--------|---------|-----------|
-- CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
-- KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
-- MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
-- NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT *
FROM crosstab(
    $$
    WITH categorized_drugs AS (
        SELECT 
            d.drug_name,
            CASE 
                WHEN LOWER(d.generic_name) LIKE '%codeine%' THEN 'Codeine'
                WHEN LOWER(d.generic_name) LIKE '%fentanyl%' THEN 'Fentanyl'
                WHEN LOWER(d.generic_name) LIKE '%hydrocodone%' THEN 'Hydrocodone'
                WHEN LOWER(d.generic_name) LIKE '%morphine%' THEN 'Morphine'
                WHEN LOWER(d.generic_name) LIKE '%oxycodone%' THEN 'Oxycodone'
                WHEN LOWER(d.generic_name) LIKE '%oxymorphone%' THEN 'Oxymorphone'
                ELSE 'Other'
            END AS category
        FROM drug d
    )
    SELECT 
        UPPER(p.nppes_provider_city) AS city,
        cd.category,
        SUM(pr.total_claim_count) AS total_claims
    FROM prescriber p
    JOIN prescription pr ON p.npi = pr.npi
    JOIN categorized_drugs cd ON pr.drug_name = cd.drug_name
    WHERE UPPER(p.nppes_provider_city) IN ('CHATTANOOGA', 'KNOXVILLE', 'MEMPHIS', 'NASHVILLE')
    GROUP BY city, category
    ORDER BY city, category
    $$,
    $$VALUES ('Codeine'::text), ('Fentanyl'::text), ('Hydrocodone'::text), ('Morphine'::text), ('Oxycodone'::text), ('Oxymorphone'::text)$$
) AS ct(city text, codeine int, fentanyl int, hydrocodone int, morphine int, oxycodone int, oxymorphone int);