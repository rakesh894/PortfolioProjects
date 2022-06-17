/* 
Covid 19 Data Exploration
Skill used: Joins, CTE's, Temp tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
from PortfolioProject..CovidDeaths
order by 3,4


--Select the data that I am going to be using

Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

--Looking at total cases vs total deaths
--Shows the likelihood of dying of you get Covid in India (Repalace India with your country name)

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%India%'
order by 1,2

--Looking at total cases vs population
--Shows what percentage of population has got covid

Select location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
from PortfolioProject..CovidDeaths
where location like '%India%'
order by 1,2

--Looking at countries with highest infection rate and their death percentage compared to population

Select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentagePopulationInfected, max((total_deaths/total_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
Group by location, population 
order by PercentagePopulationInfected desc;

--Showing countries with highest death count per population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by location
order by TotalDeathCount desc

--BREAKING THINGS DOWN BY CONTINENT
--Showing continents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as NewDeathPercentage 
From PortfolioProject..CovidDeaths 
where continent is not null
order by 1,2


--Looking at total population vs vaccinations using rolling sum

Select death.continent, death.location, death.date, death.population , vacc.new_vaccinations, 
	SUM(cast(vacc.new_vaccinations as float)) over (partition by  death.location order by death.location, death.date) as VaccineRollingCount
From CovidDeaths death
join CovidVaccinations vacc
	on death.location = vacc.location 
	and death.date = vacc.date
where death.continent is not null
order by 2,3



--USE CTE (Common Table Expression) to perform calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, VaccineRollingCount)
as
(
Select death.continent, death.location, death.date, death.population , vacc.new_vaccinations, 
--below code is used to do rolling sum of new vaccination for each country
	SUM(cast(vacc.new_vaccinations as float)) over (partition by  death.location order by death.location, death.date) as VaccineRollingCount
From CovidDeaths death
join CovidVaccinations vacc
	on death.location = vacc.location 
	and death.date = vacc.date
where death.continent is not null
--order by 2,3
)
select * , (VaccineRollingCount/population)*100 as PercentageNewVacc
from PopvsVac



--TEMP TABLE to perform calculation on Partition By in previous query

DROP table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
VaccineRollingCount numeric
)


insert into #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population , vacc.new_vaccinations, 
--below code is used to do rolling sum of new vaccination for each country
	SUM(cast(vacc.new_vaccinations as float)) over (partition by  death.location order by death.location, death.date) as VaccineRollingCount
From CovidDeaths death
join CovidVaccinations vacc
	on death.location = vacc.location 
	and death.date = vacc.date
--where death.continent is not null
--order by 2,3

select * , (VaccineRollingCount/population)*100 as PercentageNewVacc
from #PercentPopulationVaccinated


-- Creating View to store data for later visualization

Create view PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population , vacc.new_vaccinations, 
--below code is used to do rolling sum of new vaccination for each country
	SUM(cast(vacc.new_vaccinations as float)) over (partition by  death.location order by death.location, death.date) as VaccineRollingCount
From CovidDeaths death
join CovidVaccinations vacc
	on death.location = vacc.location 
	and death.date = vacc.date
where death.continent is not null
--order by 2,3

select * 
from PercentPopulationVaccinated
