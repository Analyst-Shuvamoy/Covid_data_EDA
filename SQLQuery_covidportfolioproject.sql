SELECT *
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
order by 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT
	location, date, total_cases,total_deaths, 
	(total_deaths/total_cases)*100 as DeathPercentage
FROM 
	PortfolioProject..CovidDeaths
WHERE location like '%india%'
ORDER By 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT
	Location, date, Population, total_cases,  
	(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%india%'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT
	location, Population, MAX(total_cases) as HighestInfectionCount,  
	Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

SELECT
	location, Population, MAX(CAST(total_deaths as int)) as HighestDeathCount,  
	Max((total_deaths/population))*100 as PercentPopulationDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location,population
ORDER BY HighestDeathCount DESC


-- Showing contintents with the highest death count per population

SELECT
	location, MAX(CAST(total_deaths as int)) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY HighestDeathCount DESC


-- GLOBAL NUMBERS

Select 
	date,
	SUM(new_cases) as DAILY_total_cases, 
	SUM(cast(new_deaths as int)) as DAILY_total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
Group By date
ORDER BY 1

Select 
	SUM(new_cases) as Total_Cases, 
	SUM(cast(new_deaths as int)) as Total_Deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
where continent is not null 


-- Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3



Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location, dea.Date) as RollingVaccinationCount
From 
	PortfolioProject..CovidDeaths dea
	Join 
	PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- SHOWING TOTAL VACCINES GIVEN IN A COUNTRY AND PERCENT VACCINATED USING CTE

WITH Pop_Vac(Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationCount)
AS 
	(
	Select 
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location, dea.Date)
	From 
		PortfolioProject..CovidDeaths dea
		Join 
		PortfolioProject..CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null 
	
	)

SELECT location, MAX(RollingVaccinationCount) as Total_Vaccinated, (MAX(RollingVaccinationCount)/population)*100 as PercentVaccinated
FROM Pop_Vac
GROUP BY location,population
ORDER BY Location;




-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists PercentPopulationVaccinated

Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100 as percent_vaccinated
From PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinatedView as

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select * from PercentPopulationVaccinatedView