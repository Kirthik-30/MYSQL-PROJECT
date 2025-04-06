create database project;
use project;


SELECT * FROM customer_income;

set autocommit=off;
start transaction;


create table customer_grades_percent select *,
case
when (ApplicantIncome > 15000) then "Grade A"
when (ApplicantIncome > 9000)  then "Grade B"
when (ApplicantIncome > 5000) then "Middle Class Customer"
else "Low Class Customer"
end as "Customer Grades",
case 
when (ApplicantIncome <5000 and Property_Area = "Urban") then 5
when (ApplicantIncome <5000 and Property_Area = "Semiurban") then 3.5
when (ApplicantIncome <5000 and Property_Area = "rural") then 3
when (ApplicantIncome <5000 and Property_Area = "semiurban") then 2.5
else 7
end "Montly_Interst_Percentage"
from customer_income ;

SELECT * FROM customer_grades_percent;  -- TABLE 1
-- sheet 2

create table dummy( loan_id varchar (10),customer_id varchar (15),loan_amount text (25),loan_amount_term int, cibil_score int, primary key (loan_id));
SELECT * FROM loan_status;
drop table loan_status;
-- primary table 
create table loan_status( loan_id varchar (10),customer_id varchar (15),loan_amount text (25),
 loan_amount_term int, cibil_score int, primary key (loan_id));
drop table loan_status;
select * from loan_status;
select count(*) from loan_status;

-- secondaty table
create table cibil_score (loan_id varchar(40), loan_amount varchar(100),
cibil_score int, cibil_score_status varchar(100));
desc cibil_score;
drop table cibil_score;

select * from cibil_score;

-- row level trigger

delimiter //
create trigger loan_amount before insert on loan_status for each row
begin 
if new.loan_amount is null then set new.loan_amount = 'Loan Still Processing';
end if;	
end //
delimiter ;
show triggers;

-- statement level trigger 

Delimiter //
create trigger cibil_score_trigger after insert on loan_status for each row
begin
insert into  cibil_score (loan_id, loan_amount, cibil_score, cibil_score_status)
values (new.loan_id,new.loan_amount,new.cibil_score,
case
when new.cibil_score > 900 then 'High cibil score'
when new.cibil_score > 750 then 'No penalty'
when new.cibil_score > 0 then 'Penalty customers'
else 'Reject customers (Cannot apply loan)'
end);
end //
Delimiter ;

insert into loan_status (loan_id,customer_id ,loan_amount,
 loan_amount_term , cibil_score) select  loan_id,customer_id,loan_amount ,
 loan_amount_term , cibil_score from dummy;

select count(*) from cibil_score;

 select * from cibil_score; -- table 2
 
 -- deleting the loan still processing and reject customers
delete from cibil_score where loan_amount= 'loan still processing' ;
delete from cibil_score where cibil_score_status='Reject customers (Cannot apply loan)'; 

select count(*) from cibil_score;

-- Update loan as integers
alter table cibil_score modify loan_amount int;

-- caluclation monthly interest
create table monthly_interest 
select cgp.*,c.loan_amount,c.cibil_score,c.cibil_score_status,
case 
when applicantIncome<5000 and Property_Area = "rural" then (c.loan_amount *(3/100))
when applicantIncome<5000 and Property_Area = "rural" then (c.loan_amount *(3.5/100))
when applicantIncome<5000 and Property_Area = "urban" then (c.loan_amount * (5/100))
when applicantIncome<5000 and Property_Area = "semi urban" then (c.loan_amount* (2.5/100))
else (c.loan_amount*(7/100))
end as monthly_interest_calc from customer_grades_percent cgp inner join cibil_score c  on c.loan_id=cgp.loan_id;

-- annual intererst calculation
create table annual_interest as select *,monthly_interest_calc*12 
as anuual_interest_calc from monthly_interest ;
select * from annual_interest;-- table 3
-- customer info table 
-- Update gender and age based on customer id 
select * from customer_det; -- table - 4 

update customer_det
set Gender = case
when Customer_id in ('IP43006', 'IP43016', 'IP43508', 'IP43577', 'IP43589', 'IP43593') then 'Female'
when Customer_id in ('IP43018', 'IP43038') then 'Male'
else Gender
end,
Age = case 
when Customer_ID = 'IP43007' then 45
when Customer_ID = 'IP43009' then  32
else Age
end;

-- Join all the 5 tables without repeating the fields - output 1 
drop table output_1;

create table output_1 select cgp.loan_id,cgp.customer_id,cgp.applicantincome,cgp.coapplicantincome,cgp.property_area,cgp.loan_status,cgp.Customer_Grades,
cgp.Montly_Interst_Percentage d, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from customer_grades_percent cgp
inner join annual_interest ai on cgp.loan_id=ai.loan_id
inner join cibil_score c on ai.loan_id=c.loan_id
inner join customer_det d on cgp.customer_id=d.customer_id
inner join country_state cs on cgp.customer_id=cs.customer_id
inner join region_info r on r.region_id=cs.region_id;

select * from output_1;
select count(*) from output_1;


-- output 2 
-- find the mismatch details using joins - output 2

select * from region_info;
select * from country_state;
select * from customer_det;

create table output_2 select r.*,cs.customer_id,cs.Loan_ID,cs.customer_name,cs.postal_code,cs.segment,cs.state,
cd.gender,cd.age,cd.married,cd.education,cd.self_employed from region_info r 
left join country_state cs on r.region_id=cs.region_id
left join customer_det cd on r.region_id=cd.region_id where cs.customer_id is null;

select * from output_2;
-- Filter high cibil score - output 3

create table output_3 select cgp.loan_id,cgp.customer_id,cgp.applicantincome,cgp.coapplicantincome,cgp.property_area,cgp.loan_status,cgp.Customer_Grades,
cgp.Montly_Interst_Percentage d, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from customer_grades_percent cgp
inner join annual_interest ai on cgp.loan_id=ai.loan_id
inner join cibil_score c on ai.loan_id=c.loan_id
inner join customer_det d on cgp.customer_id=d.customer_id
inner join country_state cs on cgp.customer_id=cs.customer_id
inner join region_info r on r.region_id=cs.region_id where ai.cibil_score_status = "High cibil score";

select * from output_3;
select count(*) from output_3 ;

-- Filter home office and corporate - output 4
create table output_4 select cgp.loan_id,cgp.customer_id,cgp.applicantincome,cgp.coapplicantincome,cgp.property_area,cgp.loan_status,cgp.Customer_Grades,
cgp.Montly_Interst_Percentage d, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from customer_grades_percent cgp
inner join annual_interest ai on cgp.loan_id=ai.loan_id
inner join cibil_score c on ai.loan_id=c.loan_id
inner join customer_det d on cgp.customer_id=d.customer_id
inner join country_state cs on cgp.customer_id=cs.customer_id
inner join region_info r on r.region_id=cs.region_id where segment in("Home office", "corporate");

select * from output_4;
select count(*) from output_4;

-- Store all the outputs as procedure

delimiter // 

create procedure final_output ()
select * from annual_interest;
select * from customer_grades_percent;
select * from cibil_score;
select * from country_state;
select * from customer_det;
select * from customer_income;
select * from dummy;
select * from loan_status;
select * from monthly_interest;
select* from region_info;
select * from output_1;
select * from output_2;
select * from output_3;
select * from output_4;
end //
delimiter ;
drop procedure final_output;
call final_output();
select count(*) from cibil_score;
commit;