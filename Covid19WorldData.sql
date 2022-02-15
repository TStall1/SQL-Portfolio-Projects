--World Covid Data (01/01/2020 - 01/30/2022)


SELECT *
FROM CovidData.dbo.CovidData
order by 3,4


SELECT location, date, total_cases, total_deaths, population
FROM CovidData.dbo.CovidData
order by 1,2

-- Check location values to see if they are consistent

SELECT continent
FROM CovidData.dbo.CovidData
GROUP BY continent

-- Count of location values by continent

SELECT continent, count(*)
FROM CovidData.dbo.CovidData
GROUP BY continent

-- Explore 9514 values where continent is null

SELECT DISTINCT location
FROM CovidData.dbo.CovidData
WHERE continent is null

-- Remove null continents
-- Null values in continent column include groups such as income 

SELECT continent, location, date, total_cases, total_deaths, population
FROM CovidData.dbo.CovidData
WHERE continent is not null

--Maximum Total Cases

SELECT continent, location, MAX(total_cases) as TotalCaseCount
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY continent, location
ORDER BY continent, location


-- Maximum Total Deaths by Country

SELECT continent, location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY continent, location
ORDER BY 1,2


-- Maximum Total Deaths by Continent 

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidData.dbo.CovidData
WHERE continent is not null
	AND location not in ('World', 'European Union', 'International')
GROUP BY continent
ORDER BY TotalDeathCount desc


-- Compare Maximum Total Case Count and Death Count by Country

SELECT continent, location, MAX(cast(total_cases as int)) as TotalCaseCount, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY continent, location
ORDER BY continent, location


-- Max Totals for each location (Total Cases, Total Deaths, Percentage Deaths)

SELECT location, MAX(total_cases) as total_cases, MAX(cast(total_deaths as int)) as total_deaths, 
		MAX(cast(total_deaths as int))/MAX(total_cases)*100 as MortalityRate
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY location
ORDER BY 1,2


-- Quick check for accuracy
-- Compare sum of new totals to total cases documented

SELECT continent, location, date, total_cases, total_deaths, (cast(total_deaths as int)/total_cases)*100 as Percentage
FROM CovidData.dbo.CovidData
WHERE continent is not null
and location = 'Botswana'
ORDER BY 1,2, 3


SELECT location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
		SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Percentage
FROM CovidData.dbo.CovidData
WHERE continent is not null
AND location = 'Botswana'
GROUP BY location


-- Compare Daily Total Case Count and Death Count by Country (Cumulitive)

SELECT continent, location, date, total_cases, CAST(total_deaths as int) as total_deaths, (CAST(total_deaths as int)/total_cases)*100 as Percentage
FROM CovidData.dbo.CovidData
WHERE continent is not null
ORDER BY 1,2, total_deaths desc


-- Compare global daily Case Count and Death Count (Not Cumulitive)

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Percentage
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Calculate death date and percentage based on daily running total

WITH PopvsDea (Continent, location, date, population, new_deaths, RollingDeathRate) 
as
(
SELECT continent, location, date, population, new_deaths
, SUM(cast(new_deaths as int)) OVER (Partition by location ORDER BY date) as RollingDeathRate
FROM CovidData.dbo.CovidData
WHERE continent is not null
)
SELECT *, (RollingDeathRate/population)*100 as DeathPercentage
FROM PopvsDea


-- Create temp table for Death Percentage

DROP Table if exists #PopulationDeathRate
Create Table #PopulationDeathRate
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_deaths numeric,
RollingDeathRate numeric
)
Insert Into #PopulationDeathRate
SELECT continent, location, date, population, new_deaths, SUM(cast(new_deaths as int)) OVER 
	(Partition by location ORDER BY date) as RollingDeathRate
FROM CovidData.dbo.CovidData
WHERE continent is not null


SELECT *,  (RollingDeathRate/population)*100 as DeathPercentage
FROM  #PopulationDeathRate
ORDER BY 1,2,3


-- Total Number of people vaccinated by country

SELECT location, MAX(population) as population, MAX(total_vaccinations) as Total_vaccinations
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY location
ORDER BY 1


-- New daily vaccinations by country

SELECT continent, location, date, population, new_vaccinations
FROM CovidData.dbo.CovidData
WHERE continent is not null
ORDER BY 2,3


-- Percentage of population vaccinated by country

SELECT location, MAX(population) as population, MAX(total_vaccinations) as Total_vaccinations, 
		MAX(total_vaccinations)/MAX(population)*100 as Percentage_Vaccinated
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY location
ORDER BY 1

-- Partition data to get daily running total of total vaccines by country

SELECT continent, location, date, population, new_vaccinations
, SUM(cast(new_vaccinations as bigint)) OVER (Partition by location ORDER BY date) as RollingPeopleVaccinated
FROM CovidData.dbo.CovidData
WHERE continent is not null



--Explore Data for Visualization

-- Worldwide death rate

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidData.dbo.CovidData
WHERE continent is not null
ORDER BY 1,2

-- Total Death Count by Continent

SELECT continent, SUM(cast(new_deaths as int)) as TotalDeathCount
FROM CovidData.dbo.CovidData
WHERE continent is not null
	AND location not in ('World', 'European Union', 'International')
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Death Rate Percentage By Country

SELECT location, MAX(total_cases) as population, MAX(cast(total_deaths as int)) as total_deaths, 
		MAX(cast(total_deaths as int))/MAX(total_cases)*100 as MortalityRate
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY location

-- Total Deaths by Country - Daily Count

WITH PopvsDea (Continent, location, date, population, new_deaths, RollingMortalityRate) 
as
(
SELECT continent, location, date, population, new_deaths
, SUM(cast(new_deaths as int)) OVER (Partition by location ORDER BY date) as RollingMortalityRate
FROM CovidData.dbo.CovidData
WHERE continent is not null
)
SELECT *, (RollingMortalityRate/population)*100 as DeathPercentage
FROM PopvsDea

-- Percentage Population Infected by Country

SELECT location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population)*100 as PercentagePopulationInfected
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentagePopulationInfected desc

-- Percentage Population Infected by Country - Daily Totals

SELECT location, population, date, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases)/population)*100 as PercentagePopulationInfected
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY location, population, date
ORDER BY PercentagePopulationInfected desc, 3 desc

-- Daily cumulitive case count vs death count

SELECT location, date, population, total_cases, total_deaths
FROM CovidData.dbo.CovidData
WHERE continent is not null
ORDER BY 1,2

-- Percentage Population vaccinated by country 

SELECT continent, location, population, MAX(cast(people_vaccinated as bigint)) as People_vaccinated, 
		(MAX(cast(people_vaccinated as bigint))/population)*100 as Percentage_People_Vaccinated
FROM CovidData.dbo.CovidData
WHERE continent is not null
GROUP BY continent, location, population
ORDER BY 1
