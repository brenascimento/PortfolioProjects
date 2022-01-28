SELECT * 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--SELECT * 
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY 3, 4

-- Select the data that we are going to be using
SELECT location, date, total_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths in USA
-- Show likelihood of dying if contract covid in USA
SELECT location, date, total_cases, total_deaths, 
		(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths in Brazil
-- Show likelihood of dying if contract covid in USA
SELECT location, date, total_cases, total_deaths, 
		(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Brazil' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Population
-- Show what percentage of population got Covid
SELECT location, date, total_cases, population, 
		(total_cases/population)*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Brazil'
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY CasePercentage DESC

-- Showing Countries with Highest Death Count
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL -- if continent is null, is because, continent or other thing is in location
GROUP BY location, population
ORDER BY TotalDeathCount DESC

--Example of locations that continent is null
SELECT DISTINCT location
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL

--SELECT iso_code, continent, location
--FROM PortfolioProject..CovidDeaths
--WHERE location = 'World' 

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing Continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- verify that world location has same sum of countries by date
--SELECT date, SUM(new_cases) AS max_total_cases
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NOT NULL AND YEAR(date) > 2020
--GROUP BY date
--ORDER BY date;

--SELECT date, SUM(new_cases) AS max_total_cases
--FROM PortfolioProject..CovidDeaths
--WHERE location = 'World' AND YEAR(date) > 2020
--GROUP BY date


-- GLOBAL NUMBER DEATH 
SELECT -- date, 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS
		DeathPercentageByTotalCases
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Looking at Total Population vs Vaccinations

-- Using CTE

WITH PopVsVac(continent, location, date, population, 
				new_vaccinations, rolling_people_vaccinated)
AS 
( 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
			OVER (PARTITION BY dea.location 
				  ORDER BY dea.location, dea.date) 
							AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
			ON dea.location = vac.location
				and dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)

SELECT *, (rolling_people_vaccinated/population)*100 AS vaccinated_percentage
FROM PopVsVac
ORDER BY 1, 2, 3

-- TEMP TABLE

CREATE TABLE #PercentPopulationVaccinated(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date date,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)
--DROP TABLE #PercentPopulationVaccinated
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
			OVER (PARTITION BY dea.location 
				  ORDER BY dea.location, dea.date) 
							AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
			ON dea.location = vac.location
				and dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT * 
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
			OVER (PARTITION BY dea.location 
				  ORDER BY dea.location, dea.date) 
							AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
			ON dea.location = vac.location
				and dea.date = vac.date
WHERE dea.continent IS NOT NULL

GO

SELECT * 
FROM PercentPopulationVaccinated