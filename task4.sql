-- пользователи
create table person_data as
with tmp as (select generate_series                   as id,
                    floor(random() * (10)) + 1 as ids,
                    floor(random() * (10)) + 1 as idn,
                    floor(random() * (10)) + 1 as idp,
                    'ROLE_NOVICE'                     as role,
                    '1234'                            as password,
                    generate_series || '@mail.com'    as email,
                    'Программист'                     as post
             from generate_series(1, 10000))
select id,
       (select surname from surnames where id = ids)       as surname,
       (select name from names where id = idn)             as name,
       (select patronymic from patronymics where id = idp) as patronymic,
       role,
       password,
       email,
       post
from tmp;
update person_data set post='HR', role='ROLE_HR' where id % 10 = 0;
select  count(*) from person_data;
-- Запросы
-- 1 запрос
select * from person_data where id = 120;
-- 2 запрос
select email, surname, name from person_data order by id limit 1000;
-- 3 запрос
select distinct surname, name from person_data order by surname desc limit 1000;
-- 4 запрос
select * from person_data where role='ROLE_HR' and surname in ('Новиков', 'Лебедев') order by id limit 1000;
-- 5 запрос
select * from person_data where surname like 'С%' order by id limit 1000;
-- 6 запрос
select * from person_data where char_length(email) < 11 order by id limit 1000;
-- Планы выполненных запросов
explain select * from person_data where id = 120;
explain select email, surname, name from person_data order by id limit 1000;
explain select surname, name from person_data order by surname desc limit 1000;
explain select * from person_data where role='ROLE_HR' and surname in ('Новиков', 'Лебедев') order by id limit 1000;
explain select * from person_data where surname like 'С%' order by id limit 1000;
explain select * from person_data where char_length(email) < 11 order by id limit 1000;
-- Индексы
-- B-дерево тут используется в in
create index surname_index on person_data (surname);
-- Хеш это для сравнения
create index id_index on person_data using hash (id);
-- GIN для array
create index gin_index on table_for_gin using gin (arr);
select * from table_for_gin where arr @> ARRAY['привет'];
explain select * from table_for_gin where arr @> ARRAY['привет'];
-- BRIN
create index role_index on person_data using brin (role);
-- Частичные индексы
create index not_correct_email on person_data (email) where char_length(email) < 11;
-- Планы запросов с индексами
explain select * from person_data where id = 120;
explain select email, surname, name from person_data order by id limit 1000;
explain select surname, name from person_data order by surname desc limit 1000;
explain select * from person_data where role='ROLE_HR' and surname in ('Новиков', 'Лебедев') order by id limit 1000;
explain select * from person_data where surname like 'С%' order by id limit 1000;
explain select * from person_data where char_length(email) < 11 order by id limit 1000;
-- GIST index gist не для json
select * from gist_table;
drop index gist_index;
create index gist_index on gist_table using gin (response jsonb_ops);
explain select * from gist_table where response ? 'error';
insert into gist_table select * from gist_table;