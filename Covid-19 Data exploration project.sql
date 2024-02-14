/*

Portfolio Project

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select * from CovidDeaths
select * from CovidVaccinations

select * from CovidDeaths
where continent is not null 
  /* I use (where continent is not null) ===>  so the data of every continent doesn't appear */
order by 2 Desc , 3

select * from CovidVaccinations
where continent is not null
order by 3 , 4

select * from CovidDeaths 
where continent is null and location like '%ceani%'
order by 2 -- ( where continent is null ) contains the totals of every continent and the whole world 

select location, date ,total_cases, new_cases, total_deaths, population 
from CovidDeaths
where continent is not null 

-- Converting data type of total_deaths and new_deaths columns from nvarchar to Integer

alter table CovidDeaths
alter column total_deaths Integer

alter table CovidDeaths
alter column new_deaths Integer 

-- Case Fatality Rate (the ratio of deaths to the number of cases of a specific disease)

select location, sum(new_cases) as total_cases,
                 sum(new_deaths) as total_deaths, 
				  case 
				   when (sum(new_deaths)/sum(new_cases))*100 is NULL then 0
				   else (sum(new_deaths)/sum(new_cases))*100
				  end as CFR /*CFR ==> Case Fatality Rate*/
from CovidDeaths
where continent is not null 
group by location
order by CFR DESC 

-- Where top 5 CRF Countries are (Yemen, Mexico, Syria, Sudan, Egypt) I didn't include Vanuatu beacuse of thier lack of tests 
select 
top 5 case 
	    when (sum(new_deaths)/sum(new_cases))*100 is NULL then 0
	    else (sum(new_deaths)/sum(new_cases))*100
	   end as CFR /*CFR ==> Case Fatality Rate*/
,location, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths 
from CovidDeaths
where continent is not null 
group by location
order by CFR DESC 

-- Cases per population (Infection Rate)
select location , sum(new_cases) as total_cases , population, 
				  case 
				   when (sum(new_cases)/population)*100 is NULL then 0
				   else (sum(new_cases)/population)*100
				  end as CPP 
from CovidDeaths
where continent is not null 
group by location, population
order by CPP DESC -- Highest infection rate at (Andorra ,Montenegro ,Czechia ,San Marino ,Slovenia) 

--  the death rate (DR)
select location , sum(new_deaths) as total_deaths , population, 
				  case 
				   when (sum(new_deaths)/population)*100 is NULL then 0
				   else (sum(new_deaths)/population)*100
				  end as DR
from CovidDeaths
where continent is not null 
group by location, population
order by DR DESC -- Highest death rate at (Hungary, Czechia, San Marino, Bosnia and Herzegovina, Montenegro) 


-- Let's see Case Fatality Rate (CFR), Cases per Population (CPP), and Death Rate (DR) for every CONTINENT
select location as continent , sum(new_cases) as total_cases,
                 sum(new_deaths) as total_deaths, population,
				  case 
				   when (sum(new_deaths)/sum(new_cases))*100 is NULL then 0
				   else (sum(new_deaths)/sum(new_cases))*100
				  end as CFR,  
				  case 
				   when (sum(new_cases)/population)*100 is NULL then 0
				   else (sum(new_cases)/population)*100
				  end as CPP,
				  case 
				   when (sum(new_deaths)/population)*100 is NULL then 0
				   else (sum(new_deaths)/population)*100
				  end as DR
from CovidDeaths
where continent is null and location != 'International'
group by location, population
order by 1 -- 2, 3, 5, 6, 7
-- same as before but for every country
select location as country,continent ,sum(new_cases) as total_cases,
                 sum(new_deaths) as total_deaths, population,
 case 
	when (sum(new_deaths)/sum(new_cases))*100 is NULL then 0
	else (sum(new_deaths)/sum(new_cases))*100
 end as CFR,  
 case 
    when (sum(new_cases)/population)*100 is NULL then 0
	else (sum(new_cases)/population)*100
	end as CPP,
 case 
	when (sum(new_deaths)/population)*100 is NULL then 0
    else (sum(new_deaths)/population)*100
 end as DR
from CovidDeaths
where continent is not null
group by location, population,continent

-- let's see vaccination coverage : total of people vaccinated in each country 
-- , when and how much people has been vaccinated
select dea.location,dea.date,dea.population, vac.people_vaccinated, 
 case 
	when (vac.people_vaccinated/dea.population)*100 is NULL then 0
	else (vac.people_vaccinated/dea.population)*100
 end as VC
from CovidDeaths as dea
join CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date 
where dea.people_vaccinated is not null and dea.people_vaccinated != 0 and dea.continent is not null
order by location, date

-- total vaccination
select dea.location,dea.date,dea.population,vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.date) as total_vaccinations_2
from CovidDeaths as dea
join CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date 
where dea.continent is not null-- and dea.people_vaccinated is not null and dea.people_vaccinated != 0 and

-- let's see MAX vaccination coverage for each country
 -- using partition by and CTE
With VCTable as (select DISTINCT(dea.location), dea.population,
  case 
   when (max(cast(vac.people_vaccinated as int)) over (partition by dea.location)) is null then 0
   else (max(cast(vac.people_vaccinated as int)) over (partition by dea.location))
  end as max_people_vaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date 
where dea.continent is not null

)
select *, 
 case 
	when (max_people_vaccinated/population)*100 is NULL then 0
	else (max_people_vaccinated/population)*100
 end as VC
from VCTable
order by location

  -- another way without using partition by or CTE 
  -- but using MAX() and temptable - same results

Drop table if exists #VCTable
Create table #VCTable (location nvarchar(255) , population numeric,max_people_vaccinated numeric)
insert into #VCTable 
select dea.location,dea.population, 
  case
    when max(cast(vac.people_vaccinated as int)) is null then 0
    else max(cast(vac.people_vaccinated as int))
  end as max_people_vaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
on dea.location = vac.location and dea.date = vac.date 
where dea.continent is not null
group by dea.location , dea.population
--select * from #VCTable order by 1
select *, 
 case 
	when (max_people_vaccinated/population)*100 is NULL then 0
	else (max_people_vaccinated/population)*100
 end as VC
from #VCTable
order by location

-- a couple of views to make visualisations on PowerBi or Tableau

create view CFR_CPP_DR_CONTINENT as
select location as continent , sum(new_cases) as total_cases,
                 sum(new_deaths) as total_deaths, population,
				  case 
				   when (sum(new_deaths)/sum(new_cases))*100 is NULL then 0
				   else (sum(new_deaths)/sum(new_cases))*100
				  end as CFR,  
				  case 
				   when (sum(new_cases)/population)*100 is NULL then 0
				   else (sum(new_cases)/population)*100
				  end as CPP,
				  case 
				   when (sum(new_deaths)/population)*100 is NULL then 0
				   else (sum(new_deaths)/population)*100
				  end as DR
from CovidDeaths
where continent is null and location != 'International'
group by location, population
------
create view CFR_CPP_DR_COUNTRY as
select location as country,continent ,sum(new_cases) as total_cases,
                 sum(new_deaths) as total_deaths, population,
				  case 
				   when (sum(new_deaths)/sum(new_cases))*100 is NULL then 0
				   else (sum(new_deaths)/sum(new_cases))*100
				  end as CFR,  
				  case 
				   when (sum(new_cases)/population)*100 is NULL then 0
				   else (sum(new_cases)/population)*100
				  end as CPP,
				  case 
				   when (sum(new_deaths)/population)*100 is NULL then 0
				   else (sum(new_deaths)/population)*100
				  end as DR
from CovidDeaths
where continent is not null
group by location, population,continent

select * from CFR_CPP_DR_CONTINENT
select * from CFR_CPP_DR_COUNTRY
