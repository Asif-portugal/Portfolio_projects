--SELECT * 
--FROM CovidDeaths$
--WHERE continent IS NOT NULL
--ORDER BY 3,4

--SELECT * 
--FROM CovidVaccinations$
--ORDER BY 3,4

--select data that we are going to use

--SELECT   location, date, total_cases, new_cases, total_deaths, population
--FROM CovidDeaths$
--WHERE continent IS NOT NULL
--ORDER BY 1,2;

-- TOTAL CASES VS TOTAL DEATHS
-- SHOWS LIKELIHOOD OF DYING IF CONTRACT COVID IN COUNTRY

SELECT   location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage
FROM CovidDeaths$
WHERE location LIKE '%states%'
      AND continent IS NOT NULL
ORDER BY 1,2;

-- TOTAL CASES VS POPULATION
--SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID

SELECT location, date, population,total_cases, (total_cases/population)*100 AS percentagepopulationinfected
FROM CovidDeaths$
WHERE continent IS NULL
ORDER BY 1,2;


-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location, population, MAX(total_cases) AS highestinfectioncount, MAX((total_cases/population))*100 AS percentpopulationinfected
FROM CovidDeaths$
WHERE continent IS NULL
GROUP BY location, population
ORDER BY percentpopulationinfected DESC ;

-- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT location, MAX(CAST(total_deaths AS int)) AS totaldeathcount
FROM CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY totaldeathcount DESC ;

--BY CONTINENT
--CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION
--NEED TO CHANGE TOTAL_DEATH COLUMN FROM VARCHAR TO INT

SELECT continent, MAX(CAST(total_deaths AS int)) AS totaldeathcount
FROM CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totaldeathcount DESC ;



--GLOBAL NUMBERS
-- NEED TO MAKE NEW_DEATHS AS INT

SELECT  SUM(new_cases) AS total_cases, 
        SUM(CAST(new_deaths AS int)) AS total_deaths, 
        SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS deathpercentage
FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2;


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
      SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM CovidDeaths$ AS dea
JOIN CovidVaccinations$ AS vac
   ON dea.location=vac.location
   AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3 ;

--USE CTE
WITH popvsvac ( continent, location, date, population, new_vaccination, rollingpeoplevccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM CovidDeaths$ AS dea
JOIN CovidVaccinations$ AS vac
   ON dea.location=vac.location
   AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rollingpeoplevccinated/population)*100
FROM popvsvac

--TEMP TABLE
DROP TABLE IF EXISTS #percentpopulationvaccinated
CREATE TABLE  #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #percentpopulationvaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
      SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM CovidDeaths$ AS dea
JOIN CovidVaccinations$ AS vac
   ON dea.location=vac.location
   AND dea.date=vac.date

SELECT *, (rollingpeoplevaccinated/population)*100
FROM #percentpopulationvaccinated


--CREATING VIEW TO STORE DATA
CREATE VIEW  percentpopulationvaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
      SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM CovidDeaths$ AS dea
JOIN CovidVaccinations$ AS vac
   ON dea.location=vac.location
   AND dea.date=vac.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM percentpopulationvaccinated
