/*
SELECT 
	location, 
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM Portfolio.dbo.CovidDeaths
ORDER BY 1,2;
*/

-- 1. Looking at total cases vs total deaths
-- (Shows what percentage of deaths from Covid)
SELECT 
	location, 
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases)*100 as DeathPercentage
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
-- WHERE location like '%malaysia%'
ORDER BY 1,2;

-- 2. Looking at total cases vs population
-- (Shows what percentage of population got Covid)
SELECT 
	location, 
	date,
	total_cases,
	population,
	(total_cases/population)*100 as TotalCasesPercentage
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
-- WHERE location like '%malaysia%'
ORDER BY 1,2;

-- 3. Look at countries with highest infection rate compared to population
SELECT 
	location, 
	MAX(total_cases) as HighestInfectionCount,
	MAX(population) as population,
	(MAX(total_cases) / MAX(population))*100 AS InfectionRate
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	location
ORDER BY 
	InfectionRate
DESC;

-- 3. Look at countries with highest death rate compared to population
SELECT 
	location, 
	MAX(cast(total_deaths as int)) as TotalDeathCount,
	MAX(population) as population,
	(MAX(total_deaths) / MAX(population))*100 AS DeathRate
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	location
ORDER BY 
	DeathRate
DESC

-- 4. Look at continents with highest death rate
SELECT 
	continent,
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	continent
ORDER BY 
	TotalDeathCount
DESC;

-- 5. Global Numbers for total new cases & total new deaths
SELECT 
	date,
	SUM(new_cases) AS TotalNewCases,
	SUM(cast(new_deaths AS int)) AS TotalNewDeaths,
	(SUM(cast(new_deaths AS int)) / SUM(new_cases))*100 AS DeathPercentage
FROM Portfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
	date
ORDER BY 
	1,2;
	 
-- 6. CovidVaccination (Using Temp table)
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingNewVaccination numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingNewVaccination
FROM  Portfolio.dbo.CovidDeaths Dea
LEFT JOIN Portfolio.dbo.CovidVaccinations Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *,
	(RollingNewVaccination / population ) * 100 AS VaccinationRateAgainstPop
FROM #PercentPopulationVaccinated
ORDER BY 
2,3;

-- 7. Create view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS

SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingNewVaccination
FROM  Portfolio.dbo.CovidDeaths Dea
LEFT JOIN Portfolio.dbo.CovidVaccinations Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL;

SELECT * 
FROM PercentPopulationVaccinated