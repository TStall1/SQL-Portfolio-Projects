--Austin Animal Center

--Animal_Intakes (Original File)
--Animal_Outcomes (Original File)
--Intake
--Outcome
--AustinAnimalCenter - joined and partitioned

-- Download Austin Animal Center Intakes CSV file
-- https://data.austintexas.gov/Health-and-Community-Services/Austin-Animal-Center-Intakes/wter-evkm

-- Download Austin Animal Center Outcomes CSV file

SELECT *
FROM dbo.Animal_Intakes

-- Explore unique values and check columns for null entries
-- Verify consistency and explore cleaning opportunities

SELECT AnimalID
FROM dbo.Animal_Intakes
WHERE AnimalID is null

--How many animals have more than one intake date?

SELECT DISTINCT AnimalID, count(AnimalID) as Number_of_Intakes
FROM AustinAnimalCenter.dbo.Animal_Intakes
GROUP BY AnimalID
ORDER BY 2 desc

--Count distinct Intake Types

SELECT DISTINCT Intake_Type, count(*) as  Intake_Type_Total
FROM AustinAnimalCenter.dbo.Animal_Intakes
GROUP BY Intake_Type
ORDER BY 2 desc

--Animal Type: Explore "Other" Animal Type further
--Includes bats, guinea pigs, coyotes, snakes, rabbits, and more

SELECT DISTINCT Animal_Type, count(*) as Animal_Type_Total
FROM AustinAnimalCenter.dbo.Animal_Intakes
GROUP BY Animal_Type
ORDER BY 2 desc


--Add column and convert Date_Time to Date 

ALTER TABLE AustinAnimalCenter.dbo.Animal_Intakes
ADD Intake_Date date

UPDATE AustinAnimalCenter.dbo.Animal_Intakes
SET Intake_Date = CONVERT(date, Date_Time)


ALTER TABLE AustinAnimalCenter.dbo.Animal_Outcomes
ADD Outcome_Date date

UPDATE AustinAnimalCenter.dbo.Animal_Outcomes
SET Outcome_Date = CONVERT(date, Date_Time)


--Look for Duplicates: AnimalID combined with Date_Time creates a unique identifier

SELECT DISTINCT AnimalID, count(*) as Intake_Count, Name, Date_Time, Found_Location, Intake_Type
FROM AustinAnimalCenter.dbo.Animal_Intakes
	GROUP BY AnimalID, Name, Date_Time, Found_Location, Intake_Type
	HAVING COUNT (AnimalID) > 1


-- Identify Duplicates using ROW_NUMBER

WITH RowNumCTEIntake AS(
SELECT *,
	ROW_NUMBER () OVER (
	PARTITION BY AnimalID,
				Name,
				Date_Time,
				Found_Location,
				Intake_Type
				ORDER BY
					AnimalID
					) as row_num
FROM AustinAnimalCenter.dbo.Animal_Intakes
)
SELECT *
FROM RowNumCTEIntake
WHERE row_num>1


--Create INTAKE table with no duplicate entries

DROP TABLE if exists Intake;

WITH RowNumCTEIntake AS(
SELECT *,
	ROW_NUMBER () OVER (
	PARTITION BY AnimalID,
				Name,
				Date_Time,
				Found_Location,
				Intake_Type
				ORDER BY
					AnimalID
					) as row_num
FROM AustinAnimalCenter.dbo.Animal_Intakes
)
SELECT *
INTO Intake
FROM RowNumCTEIntake
WHERE row_num=1


--Create OUTCOME table without duplicates

DROP Table if exists Outcome;

WITH RowNumCTEOutcome AS (
SELECT *,
	ROW_NUMBER () OVER (
	PARTITION BY AnimalID,
			Name,
			Date_Time, 
			Outcome_Type, 
			Outcome_Subtype, 
			Animal_Type, 
			Breed, 
			Color
			ORDER BY AnimalID
			) AS row_num
FROM AustinAnimalCenter.dbo.Animal_Outcomes
)
SELECT *
INTO Outcome
FROM RowNumCTEOutcome
WHERE row_num=1


--Join Intake and Outcome Tables and Insert Into AustinAnimalCenter

SELECT COALESCE(a.AnimalID, b.AnimalID) as AnimalID, a.Name, a.Date_Time as DateTimeIntake, a.Intake_Date, a.Intake_Type, a.Intake_Condition, 
	a.Found_Location, a.Animal_Type as AnimalTypeIntake, a.Age_upon_Intake, a.Sex_upon_Intake, b.Outcome_Type, b.Date_Time as DateTimeOutcome, 
	b.Outcome_Date, b.Date_of_Birth, b.Animal_Type as AnimalTypeOutcome, b.Sex_upon_outcome, b.Age_upon_Outcome, b.Breed, b.Color
INTO AustinAnimalCenter
	FROM AustinAnimalCenter.dbo.Intake a
	FULL OUTER JOIN AustinAnimalCenter.dbo.Outcome b ON
		a.AnimalID = b.AnimalID AND 
		a.Intake_Date<b.Outcome_date


--Partition by AnimalID and Intake Date. Delete Row_Number > 1
--Result will include only first match for Intake_Date < Outcome_Date

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER () OVER (
	PARTITION BY AnimalID,
				Intake_Date
			ORDER BY AnimalID, Intake_Date, Outcome_Date
			) AS row_number
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
)
DELETE FROM RowNumCTE
WHERE row_number > 1

--Convert Age_Upon_Intake to Integer. Group by year.

SELECT Age_Upon_Intake_Years, count(*) as Age_Upon_Intake_Count
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
GROUP BY Age_Upon_Intake_Years
ORDER BY 1

ALTER TABLE AustinAnimalCenter.dbo.AustinAnimalCenter
ADD Age_Upon_Intake_Years int

UPDATE AustinAnimalCenter.dbo.AustinAnimalCenter
SET Age_Upon_Intake_Years = (CASE 
		WHEN Age_upon_Intake like '%-1%' THEN CAST('0' AS int)
		WHEN Age_upon_Intake like '%-3%' THEN CAST('2' AS int)
		WHEN Age_upon_Intake like '%-2%' THEN CAST('1' AS int)
		WHEN Age_upon_Intake like '%week%' THEN CAST('0' AS int)
		WHEN Age_upon_Intake like '%month%' THEN CAST('0' AS int)
		WHEN Age_upon_Intake like '%day%' THEN CAST('0' AS int)
		WHEN Age_upon_Intake = '0 years' THEN CAST('0' AS int)
		WHEN Age_upon_Intake = '1 year' THEN CAST('1' AS int)
		WHEN Age_upon_Intake = '2 year' THEN CAST('2' AS int)
		WHEN Age_upon_Intake = '2 years' THEN CAST('2' AS int)
		WHEN Age_upon_Intake = '3 years' THEN CAST('3' AS int)
		WHEN Age_upon_Intake = '4 years' THEN CAST('4' AS int)
		WHEN Age_upon_Intake = '5 years' THEN CAST('5' AS int)
		WHEN Age_upon_Intake = '6 years' THEN CAST('6' AS int)
		WHEN Age_upon_Intake = '7 years' THEN CAST('7' AS int)
		WHEN Age_upon_Intake = '8 years' THEN CAST('8' AS int)
		WHEN Age_upon_Intake = '9 years' THEN CAST('9' AS int)
		WHEN Age_upon_Intake = '10 years' THEN CAST('10' AS int)
		WHEN Age_upon_Intake = '11 years' THEN CAST('11' AS int)
		WHEN Age_upon_Intake = '12 years' THEN CAST('12' AS int)
		WHEN Age_upon_Intake = '13 years' THEN CAST('13' AS int)
		WHEN Age_upon_Intake = '14 years' THEN CAST('14' AS int)
		WHEN Age_upon_Intake = '15 years' THEN CAST('15' AS int)
		WHEN Age_upon_Intake = '16 years' THEN CAST('16' AS int)
		WHEN Age_upon_Intake = '17 years' THEN CAST('17' AS int)
		WHEN Age_upon_Intake = '18 years' THEN CAST('18' AS int)
		WHEN Age_upon_Intake = '19 years' THEN CAST('19' AS int)
		WHEN Age_upon_Intake = '20 years' THEN CAST('20' AS int)
		WHEN Age_upon_Intake = '21 years' THEN CAST('21' AS int)
		WHEN Age_upon_Intake = '22 years' THEN CAST('22' AS int)
		WHEN Age_upon_Intake = '23 years' THEN CAST('23' AS int)
		WHEN Age_upon_Intake = '24 years' THEN CAST('24' AS int)
		WHEN Age_upon_Intake = '25 years' THEN CAST('25' AS int)
		WHEN Age_upon_Intake = '26 years' THEN CAST('26' AS int)
		WHEN Age_upon_Intake = '27 years' THEN CAST('27' AS int)
		WHEN Age_upon_Intake = '28 years' THEN CAST('28' AS int)
		WHEN Age_upon_Intake = '29 years' THEN CAST('29' AS int)
		WHEN Age_upon_Intake = '30 years' THEN CAST('30' AS int)
		END)
FROM AustinAnimalCenter.dbo.AustinAnimalCenter


--Explore Outcomes (2020-2021)

--Average age at time of Intake

SELECT AVG(Age_Upon_Intake_Years)
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE YEAR(Intake_date) like '2021'


--Calculate how many days each animal spend at the center

SELECT *, DATEDIFF( day, Intake_Date, Outcome_Date) AS Days_at_Shelter
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
	ORDER BY 6 desc

-- Average days at the center by Animal Type (2021)

SELECT YEAR(Intake_Date) AS YR, AnimalTypeIntake, AVG(DATEDIFF( day, Intake_Date, Outcome_Date)) AS Average_Number_of_Days_at_Shelter
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE YEAR(Intake_Date) like 2021
	GROUP BY YEAR(Intake_Date),  AnimalTypeIntake
	ORDER BY 1,2

--Total Average days at the center. All animals combined (2021)

SELECT YEAR(Intake_Date) AS YR, AVG(DATEDIFF( day, Intake_Date, Outcome_Date)) AS Average_Number_of_Days_at_Shelter
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE YEAR(Intake_Date) like 2021
	GROUP BY YEAR(Intake_Date)
	ORDER BY 1,2

--Maximum number of days at the center by Animal Type (2021)

SELECT YEAR(Intake_Date) AS YR, AnimalTypeIntake, MAX(DATEDIFF( day, Intake_Date, Outcome_Date)) AS MAX_Number_of_Days_at_Shelter
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE YEAR(Intake_Date) like 2021
	GROUP BY YEAR(Intake_Date),  AnimalTypeIntake
	ORDER BY 1,2


-- Count of Total Yearly Outcomes by Outcome Type (2020-2021)

SELECT YEAR(Outcome_Date) AS YR, Outcome_Type, COUNT(*) AS Outcome_Total
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE YEAR(Outcome_Date) like 2021
	OR YEAR(Outcome_Date) like 2020
		GROUP BY YEAR(Outcome_Date), Outcome_Type
		ORDER BY 1,2

---- Count of Total Monthly Outcomes by Outcome Type: RTO/Adoption, Transfer, Death (2020-2021)

SELECT YEAR(Outcome_Date) AS YR, MONTH(Outcome_Date) AS M, COUNT(*) AS Outcome_Total, Outcome_Type
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
	WHERE Outcome_Type is not null AND
	YEAR(Outcome_Date) like 2021
	GROUP BY YEAR(Outcome_Date), MONTH(Outcome_Date), Outcome_Type


--Adoption totals per year. Percentage increase/decrease by year. (2020-2021)

SELECT YEAR(Outcome_Date) AS YR, Outcome_Type, COUNT(*) AS Outcome_Total
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE Outcome_Type = 'Adoption'
	AND (YEAR(Outcome_Date) like 2021
	OR 	YEAR(Outcome_Date) like 2020)
		GROUP BY YEAR(Outcome_Date), Outcome_Type
		ORDER BY 1,2


--Count total outcomes by month (2021)

DROP VIEW if exists Total_Monthly_Outcomes;

CREATE VIEW Total_Outcomes_by_Month AS

(
SELECT YEAR(Outcome_Date) AS YR, MONTH(Outcome_Date) AS M, COUNT(*) AS Outcome_Total
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
	WHERE YEAR(Outcome_Date) like 2021
	OR YEAR(Outcome_Date) like 2020
	GROUP BY YEAR(Outcome_Date), MONTH(Outcome_Date)
	)


--Count total intakes by month (2021)

DROP VIEW if exists Total__Intakes_by_Month;

CREATE VIEW Total_Intakes_by_Month AS

(
SELECT YEAR(Intake_Date) AS YR, MONTH(Intake_Date) AS M, COUNT(*) AS Intake_Total
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
	WHERE YEAR(Intake_Date) like 2021
	OR YEAR(Intake_Date) like 2020
	GROUP BY YEAR(Intake_Date), MONTH(Intake_Date)
	)


--Compare Intake and Outcome Totals by Month

SELECT a.YR as Intake_YR, a.M Intake_Month, Intake_Total, Outcome_Total
FROM AustinAnimalCenter.dbo.Total_Intakes_by_Month a
	JOIN AustinAnimalCenter.dbo.Total_Outcomes_by_Month b
		ON a.YR = b.YR
		AND a.M = b.M
		;


--Live Outcomes: Group outcomes by Live Outcome (y/n)

ALTER TABLE  AustinAnimalCenter.dbo.AustinAnimalCenter
ADD Live_Outcome nvarchar(255)


UPDATE AustinAnimalCenter.dbo.AustinAnimalCenter
SET Live_Outcome = CASE
	WHEN Outcome_Type = 'Adoption' THEN 'Yes'
	WHEN Outcome_Type = 'Return to Owner' THEN 'Yes'
	WHEN Outcome_Type = 'rto-adopt' THEN 'Yes'
	WHEN Outcome_Type = 'Transfer' THEN 'Yes'
	WHEN Outcome_Type = 'Relocate' THEN 'Yes'
	WHEN Outcome_Type = 'Disposal' THEN 'No'
	WHEN Outcome_Type = 'Died' THEN 'No'
	WHEN Outcome_Type = 'Euthanasia' THEN 'No'
	WHEN Outcome_Type = 'Missing' THEN 'No'
	END
FROM AustinAnimalCenter.dbo.AustinAnimalCenter


--Count Live Outcomes by Month

DROP VIEW Live_Outcomes_by_Month

CREATE VIEW Live_Outcomes_by_Month AS

(
SELECT YEAR(Outcome_Date) AS YR, MONTH(Outcome_Date) as M, Live_Outcome as live_outcome, count(Outcome_Date) as Total_Outcome_by_Month
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE Outcome_Type is not null AND
	YEAR(Outcome_Date) like 2021
	OR YEAR(Outcome_Date) like 2020
	GROUP BY YEAR(Outcome_Date), MONTH(Outcome_Date), Live_Outcome
	)


--Monthly Live Outcome rate as a percentage

SELECT a.YR, a.M, a.live_outcome, a.Total_Outcome_by_Month as Live_Total, b.Outcome_Total, 
CAST(a.Total_Outcome_by_Month as float)/CAST(b.Outcome_Total as float)*100 as Percentage
FROM AustinAnimalCenter.dbo.Live_Outcomes_by_Month a
JOIN AustinAnimalCenter.dbo.Total_Outcomes_by_Month b
		ON a.YR = b.YR
		AND a.M = b.M
GROUP BY a.YR, a.M, a.live_outcome, a.Total_Outcome_by_Month, b.Outcome_Total


-- Data for Tableau

SELECT *, DATEDIFF( day, Intake_Date, Outcome_Date) AS Days_at_Shelter
FROM AustinAnimalCenter.dbo.AustinAnimalCenter
WHERE Intake_Date >= '2017-01-01'
AND Intake_Date <= '2021-12-31'



