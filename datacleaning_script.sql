-- Duplicate raw table to another
select * from layoffs;
create table layoffs_staging like layoffs;
insert into layoffs_staging(select * from layoffs);
select * from layoffs_staging;

-- Data cleaning
-- 1. Remove duplicates
-- there is no uniques row id so make one using CTE or subquery

select *,row_number() 
over(partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_id 
from layoffs_staging; 

-- using CTE we find rows with row_id more than 1

with CTE_duplicates as (
	select *,row_number() 
	over(partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_id 
	from layoffs_staging
)
select * from CTE_duplicates where row_id>1;
select * from layoffs_staging where company = 'casper';

-- creating another table with row_num as column
 CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into layoffs_staging2 (
select *,row_number() 
over(partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) as row_id 
from layoffs_staging );
select * from layoffs_staging2;
select * from layoffs_staging2 where row_num>1;
delete from layoffs_staging2 where row_num>1;
select * from layoffs_staging2;
-- Duplicates removed!!!

-- 2. Standardize data
-- finding issues in data (columns with text datatype) like unwanted spaces, typos , data type
-- for space
select distinct(company),trim(company) from layoffs_staging2; -- to check if spaces are there
update layoffs_staging2 set company = trim(company);
select * from layoffs_staging2;

select distinct(industry) from layoffs_staging2 order by industry;
select * from layoffs_staging2 where industry like 'crypto%';
update layoffs_staging2 set industry = 'Crypto'
where industry like 'crypto%';
select * from layoffs_staging2;

select distinct(location) from layoffs_staging2 order by location;
select distinct(country) from layoffs_staging2 order by country;
update layoffs_staging2 set country = 'United States'
where country like 'United States%'; -- or use trim(trailing '.' from country) removes the dot at the end
select * from layoffs_staging2;

select `date`, str_to_date(`date`,'%m/%d/%Y') from layoffs_staging2;
update layoffs_staging2 set date = str_to_date(`date`,'%m/%d/%Y');
select * from layoffs_staging2;
alter table layoffs_staging2 modify column `date` date;

-- 3. Null values/blank values
select * from layoffs_staging2 where total_laid_off is null ;
select * from layoffs_staging2 where total_laid_off is null and percentage_laid_off is null;
-- when both columns are null its usually useless and the columns needs to be droped/removed
-- unless we can populate values using similar records
select * from layoffs_staging2 where industry is null or industry = '';
-- update the blanks to null first
update layoffs_staging2 set industry = null where industry = '';
select * from layoffs_staging2 where company = 'Airbnb';
-- to check for records similar 
select t1.industry, t2.industry
from layoffs_staging2 t1 
join layoffs_staging2 t2
	on t1.company = t2.company 
where (t1.industry is null or t1.industry = '') 
and t2.industry is not null;

update layoffs_staging2 t1 
join layoffs_staging2 t2
	on t1.company = t2.company 
set t1.industry=t2.industry
where (t1.industry is null or t1.industry = '') 
and t2.industry is not null;

select * from layoffs_staging2 where industry is null or industry = '';
select * from layoffs_staging2;

-- 4. Remove any columns
select * from layoffs_staging2 where total_laid_off is null and percentage_laid_off is null;
-- when both columns are null its usually useless and the columns needs to be droped/removed
delete from layoffs_staging2 where total_laid_off is null and percentage_laid_off is null;
select * from layoffs_staging2;
alter table layoffs_staging2
drop column row_num;
select * from layoffs_staging2;