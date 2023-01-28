select * 
from covid_analysis..covid_death
where continent is NOT NULL 
order by 3,4;

select * 
from covid_analysis..covid_vaccination
order by 3,4;

USE covid_analysis
-- Lets select the data that we are going to be using

select location, date, new_cases, total_cases, total_deaths, population
from covid_death
where continent is NOT NULL
order by 1,2;

-- Total cases vs Total deaths

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_percentage  
from covid_death
where location = 'India' and continent is NOT NULL
order by 1,2;

-- Inference 
-- From this we can infer that, if someone tested positive from india in near days then their chance of death is less than 2%.


-- Looking at total cases vs population and also the highest infected location
select location, Population, MAX(total_cases) as Total_cases, MAX((total_cases)/(population))*100 as Positive_percentage
from covid_death
where continent is NOT NULL
group by location, population
order by Positive_percentage DESC;

-- Inference 
-- We can see that "Cyprus" is the most infecteed location in the latest data provided.
-- almost 71% of the population of Cyprus has been tested COVID 19 positive. 


-- Countries having highest death count per population (%)
select location, population, MAX(cast(total_deaths as bigint)) as Total_death_count, (MAX(cast(total_deaths as bigint))/population)*100 as Death_ratio
from covid_death
where continent is NOT NULL
group by location, population
order by Death_ratio DESC;



-- CONTINENTs
--Query 1
select location, MAX(cast(total_deaths as bigint)) as Total_death_count
from covid_death
where continent is NULL
group by location
order by Total_death_count DESC;
-- It is weird now i understand that while entering the total data all continent was added in the location column.

--Query 2
select continent, MAX(cast(total_deaths as bigint)) as Total_death_count
from covid_death
where continent is NOT NULL
group by continent
order by Total_death_count DESC;
-- Query 2 contains data from only those entries where continent is not null but query 1 has total data may 
-- it also includes countries like canada, england, scotland and many more.


-- Continents with highest deathcount per population
select continent, Max(cast(total_deaths as int)) as TotalDeath_count
from covid_death
where continent is not null
group by continent
order by TotalDeath_count desc;

--global numbers
select sum(new_cases) as Total_cases, sum(cast(new_deaths as bigint)) as Total_deaths, 
sum(cast(new_deaths as bigint))/sum(new_cases) as DeathPercentage
from covid_death
where continent is not null
order by 1,2;


--we'll look at total pouplation vs vaccinations


-- 1. Below sql query is fetching overall population of specific country and
-- also the data about number of vaccinations on specific date.
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
from covid_death cd
join covid_vaccination cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3;


-- 2. Here I have used windows function to add up the new vaccination count on the next day's vaccination count
-- ultimately giving rolling total vaccinated count on each day
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, sum(convert(bigint, cv.new_vaccinations)) over (Partition by cd.location order by cd.location, cd.date ) as Rolling_total_vaccinated_count
from covid_death cd
join covid_vaccination cv 
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3;


-- 3. I wanted to get the total population vs current vaccination percentage so added 
-- CTE in above sql query (To use it as temp table)
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, sum(convert(bigint, cv.new_vaccinations)) over (Partition by cd.location order by cd.location, cd.date ) as Rolling_total_vaccinated_count
from covid_death cd
join covid_vaccination cv 
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3;

-- Total population vs vaccination

select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(convert(bigint, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as Total_vaccinations_till_date 
from covid_vaccination cv
join covid_death cd
	on cv.location = cd.location 
	and cv.date = cd.date
where cd.continent is not null
order by 2,3;

-- Using a CTE to create a a temporary column
with PopvsVac (Continent, Location, Date, Population, new_vaccinations, Total_vaccinations_till_date)
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(convert(bigint, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as Total_vaccinations_till_date 
from covid_vaccination cv
join covid_death cd
	on cv.location = cd.location 
	and cv.date = cd.date
where cd.continent is not null
)
select *, (Total_vaccinations_till_date/Population)*100
from PopvsVac
order by Location, date;


-- Now creating temp table

Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Total_vaccinations_till_date numeric
)

Insert into #PercentPopulationVaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(convert(bigint, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as Total_vaccinations_till_date 
from covid_vaccination cv
join covid_death cd
	on cv.location = cd.location 
	and cv.date = cd.date
where cd.continent is not null

select *, (Total_vaccinations_till_date/Population)*100
from #PercentPopulationVaccinated


-- Creating view to store data for later visualization

create view PercentPopulationVaccinated as 
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(convert(bigint, cv.new_vaccinations)) OVER (Partition by cd.location order by cd.location, cd.date) as Total_vaccinations_till_date 
from covid_vaccination cv
join covid_death cd
	on cv.location = cd.location 
	and cv.date = cd.date
where cd.continent is not null
--order by 2,3


select *
from PercentPopulationVaccinated