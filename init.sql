drop table employees cascade;
drop table estimates cascade;
drop table department cascade;

create table if not exists employees
(
    id            serial not null primary key,
    last_name     varchar,
    first_name    varchar,
    participant   varchar,
    start_work    date,
    position      varchar,
    grade         varchar CHECK (grade in ('jun', 'middle', 'senior', 'lead')),
    salary_level  decimal,
    department_id int,
    rights        boolean
);


create table if not exists department
(
    id               serial primary key not null,
    department_name  varchar unique,
    leader_name      varchar,
    number_employees int default 0
);

ALTER TABLE employees
    DROP CONSTRAINT IF EXISTS fk_department;
alter table employees
    add constraint
        fk_department foreign key (department_id)
            references department (id);


create table if not exists estimates
(
    id                 serial not null primary key,
    employee_id        bigint not null,
    estimate_1_quarter varchar,
    estimate_2_quarter varchar,
    estimate_3_quarter varchar,
    estimate_4_quarter varchar
);


CREATE OR REPLACE FUNCTION count_employee_rolling_change()
    RETURNS trigger AS
$count_employee_rolling_change$
BEGIN
    UPDATE department
    SET number_employees = src.cnt
    FROM (SELECT department_id, count(1) as cnt FROM employees group by department_id) src
    WHERE src.department_id = department.id;
    RETURN NEW;
END;
$count_employee_rolling_change$ LANGUAGE plpgsql;

DROP TRIGGER if exists cnt_employee_rolling_change on employees;

CREATE TRIGGER cnt_employee_rolling_change
    AFTER INSERT
    ON employees
EXECUTE PROCEDURE count_employee_rolling_change();

