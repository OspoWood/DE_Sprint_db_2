-- a.     Попробуйте вывести не просто самую высокую зарплату во всей команде,
-- а вывести именно фамилию сотрудника с самой высокой зарплатой.

explain
select concat(last_name, ' ', first_name, ' ', participant)
from employees
where salary_level = (select max(salary_level) from employees);


-- b.     Попробуйте вывести фамилии сотрудников в алфавитном порядке

select last_name
from employees
order by last_name;


-- c.     Рассчитайте средний стаж для каждого уровня сотрудников

select grade, round(avg(salary_level), 2)
from employees
group by grade;

-- d.     Выведите фамилию сотрудника и название отдела, в котором он работает

select t1.last_name, t2.department_name
from employees t1
         join department t2 on t1.department_id = t2.id;

-- e.     Выведите название отдела и фамилию сотрудника с самой
-- высокой зарплатой в данном отделе и саму зарплату также.

select t2.department_name, t1.last_name, salary_level
from employees t1
         join department t2 on t1.department_id = t2.id
where salary_level = (select max(salary_level) from employees);

-- f.      *Выведите название отдела, сотрудники которого получат наибольшую
--     премию по итогам года. Как рассчитать премию можно узнать в последнем
--     задании предыдущей домашней работы

select t2.department_name, t1.salary_level * t3.coefficient as bonus
from employees t1
         join department t2 on t2.id = t1.department_id
         join estimates t3 on t1.id = t3.employee_id
group by department_name, bonus group by department_name;
with cds as (select t2.department_name, t1.salary_level * t3.coefficient as bonus
             from employees t1
                      join department t2 on t2.id = t1.department_id
                      join estimates t3 on t1.id = t3.employee_id
             group by department_name, bonus),
     gcds as (select cds.department_name, sum(cds.bonus) sum from cds group by cds.department_name)
select department_name
from gcds
where sum = (select max(sum) from gcds);

-- g.    *Проиндексируйте зарплаты сотрудников с учетом
-- коэффициента премии. Для сотрудников с коэффициентом премии больше
-- 1.2 – размер индексации составит 20%,
-- для сотрудников с коэффициентом премии от 1 до 1.2
-- размер индексации составит 10%. Для всех остальных сотрудников
-- индексация не предусмотрена.

update employees as emp
set salary_level = (select case
                               when t2.coefficient > 1.2 then t1.salary_level * 1.2
                               when t2.coefficient < 1.2 and t2.coefficient >= 1 then t1.salary_level * 1.1
                               else t1.salary_level
                               end
                    from employees t1
                             left join estimates t2 on t1.id = t2.employee_id
                    where t1.id = emp.id);


-- h

select dp.department_name,
       dp.leader_name,
       dp.number_employees,
       round(avg((now()::date - em.start_work)))                          avg_exp_days,
       round(avg(salary_level))                                           avg_salary,
       count(grade) filter ( where grade = 'jun')                         cnt_junior,
       count(grade) filter ( where grade = 'middle')                      cnt_middle,
       count(grade) filter ( where grade = 'senior')                      cnt_senior,
       count(grade) filter ( where grade = 'lead')                        cnt_lead,
       round(sum(prev_salary), 2)                                         sum_prev_salary,
       sum(salary_level)                                                  sum_new_salaries,
       count(estimate_1_quarter) filter ( where estimate_1_quarter = 'A') +
       count(estimate_2_quarter) filter ( where estimate_2_quarter = 'A') +
       count(estimate_3_quarter) filter ( where estimate_3_quarter = 'A') +
       count(estimate_4_quarter) filter ( where estimate_4_quarter = 'A') cnt_A,
       count(estimate_1_quarter) filter ( where estimate_1_quarter = 'B') +
       count(estimate_2_quarter) filter ( where estimate_2_quarter = 'B') +
       count(estimate_3_quarter) filter ( where estimate_3_quarter = 'B') +
       count(estimate_4_quarter) filter ( where estimate_4_quarter = 'B') cnt_B,
       count(estimate_1_quarter) filter ( where estimate_1_quarter = 'C') +
       count(estimate_2_quarter) filter ( where estimate_2_quarter = 'C') +
       count(estimate_3_quarter) filter ( where estimate_3_quarter = 'C') +
       count(estimate_4_quarter) filter ( where estimate_4_quarter = 'C') cnt_C,
       count(estimate_1_quarter) filter ( where estimate_1_quarter = 'D') +
       count(estimate_2_quarter) filter ( where estimate_2_quarter = 'D') +
       count(estimate_3_quarter) filter ( where estimate_3_quarter = 'D') +
       count(estimate_4_quarter) filter ( where estimate_4_quarter = 'D') cnt_d,
       count(estimate_1_quarter) filter ( where estimate_1_quarter = 'E') +
       count(estimate_2_quarter) filter ( where estimate_2_quarter = 'E') +
       count(estimate_3_quarter) filter ( where estimate_3_quarter = 'E') +
       count(estimate_4_quarter) filter ( where estimate_4_quarter = 'E') cnt_E,
       round(avg(coefficient), 2)                                         avg_coefficient,
       round(sum(salary_level) * sum(coefficient) * 0.01, 2)              common_bonus,

       round(sum(prev_salary) * 12 + round(sum(salary_level) * sum(coefficient) / 100, 2),
             2)                                                           all_salaries_and_bonus_previus,
       round(sum(salary_level) * 12 + round(sum(salary_level) * sum(coefficient) / 100, 2),
             2)                                                           all_news_salaries_and_bonus,
       round(round(sum(salary_level) * 12 + round(sum(salary_level) * sum(coefficient) / 100, 2),
                   2) / (round(sum(prev_salary) * 12 + round(sum(salary_level) * sum(coefficient) / 100, 2),
                               2) * 0.01) - 100, 2) as                    diff_procent


from department dp
         inner join employees em on dp.id = em.department_id
         join estimates est on em.id = est.employee_id
         join (select t1.id,
                      case
                          when t2.coefficient > 1.2 then t1.salary_level - (t1.salary_level / 120) * 20
                          when t2.coefficient < 1.2 and t2.coefficient >= 1
                              then t1.salary_level - (t1.salary_level / 110) * 10
                          else t1.salary_level
                          end prev_salary
               from employees t1
                        left join estimates t2 on t1.id = t2.employee_id) as prev_sal
              on prev_sal.id = em.id
group by dp.department_name, dp.leader_name, dp.number_employees;