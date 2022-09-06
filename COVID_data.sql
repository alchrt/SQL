/* SQL Data exploration project based on Alex The Analyst's Portfolio Project series using COVID data from https://ourworldindata.org/covid-deaths */

-- Checking if the data was imported correctly

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

-- Showing only data for countries, not continents or the entire world

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4;

-- Replacing empty strings/blanks with NULL values

SELECT 'UPDATE CovidDeaths SET ' + name + ' = NULL WHERE ' + name + ' = '''';'
FROM syscolumns
WHERE id = object_id('CovidDeaths')
	AND isnullable = 1;
	
-- Running the result of the above query, which is:

UPDATE CovidDeaths SET iso_code = NULL WHERE iso_code = '';
UPDATE CovidDeaths SET continent = NULL WHERE continent = '';
UPDATE CovidDeaths SET location = NULL WHERE location = '';
UPDATE CovidDeaths SET date = NULL WHERE date = '';
UPDATE CovidDeaths SET population = NULL WHERE population = '';
UPDATE CovidDeaths SET total_cases = NULL WHERE total_cases = '';
UPDATE CovidDeaths SET new_cases = NULL WHERE new_cases = '';
UPDATE CovidDeaths SET new_cases_smoothed = NULL WHERE new_cases_smoothed = '';
UPDATE CovidDeaths SET total_deaths = NULL WHERE total_deaths = '';
UPDATE CovidDeaths SET new_deaths = NULL WHERE new_deaths = '';
UPDATE CovidDeaths SET new_deaths_smoothed = NULL WHERE new_deaths_smoothed = '';
UPDATE CovidDeaths SET total_cases_per_million = NULL WHERE total_cases_per_million = '';
UPDATE CovidDeaths SET new_cases_per_million = NULL WHERE new_cases_per_million = '';
UPDATE CovidDeaths SET new_cases_smoothed_per_million = NULL WHERE new_cases_smoothed_per_million = '';
UPDATE CovidDeaths SET total_deaths_per_million = NULL WHERE total_deaths_per_million = '';
UPDATE CovidDeaths SET new_deaths_per_million = NULL WHERE new_deaths_per_million = '';
UPDATE CovidDeaths SET new_deaths_smoothed_per_million = NULL WHERE new_deaths_smoothed_per_million = '';
UPDATE CovidDeaths SET reproduction_rate = NULL WHERE reproduction_rate = '';
UPDATE CovidDeaths SET icu_patients = NULL WHERE icu_patients = '';
UPDATE CovidDeaths SET icu_patients_per_million = NULL WHERE icu_patients_per_million = '';
UPDATE CovidDeaths SET hosp_patients = NULL WHERE hosp_patients = '';
UPDATE CovidDeaths SET hosp_patients_per_million = NULL WHERE hosp_patients_per_million = '';
UPDATE CovidDeaths SET weekly_icu_admissions = NULL WHERE weekly_icu_admissions = '';
UPDATE CovidDeaths SET weekly_icu_admissions_per_million = NULL WHERE weekly_icu_admissions_per_million = '';
UPDATE CovidDeaths SET weekly_hosp_admissions = NULL WHERE weekly_hosp_admissions = '';
UPDATE CovidDeaths SET weekly_hosp_admissions_per_million = NULL WHERE weekly_hosp_admissions_per_million = '';

-- Same thing repeated for the CovidVacc table:

SELECT 'UPDATE CovidVacc SET ' + name + ' = NULL WHERE ' + name + ' = '''';'
FROM syscolumns
WHERE id = object_id('CovidVacc')
	AND isnullable = 1;
	

-- Selecting the data that will be used and ordering it by location and date

SELECT location,
	   date,
	   total_cases,
	   new_cases,
	   total_deaths,
	   population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

-- DATA FOR POLAND
-- Looking at the total cases vs total deaths: showing the likelihood of dying if one contracts COVID in Poland (as of August 30th, 2022)

SELECT location,
	   date,
	   total_cases,
	   total_deaths,
	   (total_deaths/total_cases)*100 AS 'death%'
FROM PortfolioProject..CovidDeaths
WHERE location = 'Poland'
ORDER BY 2;

/*

Error: Operand data type nvarchar is invalid for divide operator.
Solution: Converting into a numeric data type with CAST or CONVERT.

*/

SELECT location,
	   date,
	   total_deaths,
	   total_cases,
	   (CONVERT(float,total_deaths)/CONVERT(float,total_cases))*100 AS 'death%'
FROM PortfolioProject..CovidDeaths
WHERE location = 'Poland'
ORDER BY 2;

-- Looking at total cases vs population
-- Showing what % of the population of Poland has gotten COVID so far (as of August 30th, 2022)

SELECT location,
	   date,
	   total_cases,
	   population,
	   (CONVERT(float,total_cases)/population)*100 AS '%population_infected'
FROM PortfolioProject..CovidDeaths
WHERE location = 'Poland'
ORDER BY 2;


-- GLOBAL DATA
-- Looking at countries with the highest infection rate compared to the population

SELECT location,
	   population,
	   MAX(CONVERT(float,total_cases)) AS highest_infection_count,
	   (MAX(CONVERT(float,total_cases))/population)*100 AS '%population_infected'
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;

-- Showing countries with the highest death count per population

SELECT location,
	   MAX(CONVERT(float,total_deaths)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Showing the continents with the highest death count per population, including World, EU and International data

SELECT location,
	   MAX(CONVERT(float,total_deaths)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
	AND NOT location LIKE '%income'
GROUP BY location
ORDER BY total_death_count DESC;

-- Breaking things down based on income

SELECT location,
	   population,
	   MAX(CONVERT(float,total_deaths)) AS total_death_count,
	   (MAX(CONVERT(float,total_cases))/population)*100 AS '%population_infected'
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL
	AND location LIKE '%income'
GROUP BY location, population
ORDER BY total_death_count DESC;

-- Using aggregate functions for worldwide numbers

SELECT date,
	   SUM(CAST(new_cases AS float)) AS total_new_cases,
	   SUM(CAST(new_deaths AS float)) AS total_new_deaths,
	   SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS 'death%'
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1;


-- VACCINATION DATA
-- Looking at total population vs vaccinations using CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacc vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100 AS 'rolling_people_vaccinated%'
FROM PopvsVac
ORDER BY 2,3;


--Looking at total population vs vaccinations using a Temp Table

DROP TABLE if exists #percent_population_vaccinated;

CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
);

INSERT INTO #percent_population_vaccinated
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacc vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL;

SELECT *, (rolling_people_vaccinated/population)*100 AS 'rolling_people_vaccinated%'
FROM #percent_population_vaccinated;

-- Storing some data for later visualizations

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacc vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL;
