-- Посчитать всех сотрудников
select row_number() OVER (), *
from "user";
-- Посчитать сотрудников отдельно по ролям
SELECT ROW_NUMBER() OVER (PARTITION BY role ORDER BY surname) no, role, email, name, surname
FROM "user"
ORDER BY role, surname;
-- Карманные расходы
select number,
       price,
       abs(price * 100 / sum(price) over ()) "Percent",
       round(avg(price) over (), 0)          "Average spending"
from pocket_money
order by number;
-- Карманные расходы
select number,
       price,
       abs(price * 100 / (sum(price) over w)) "Percent",
       round(avg(price) over w, 0)            "Average spending"
from pocket_money
window w as ()
order by number;
-- Только траты
select number,
               price,
               abs(price * 100 / (sum(price) over w)) "Percent",
               round(avg(price) over w, 0)            "Average spending"
        from pocket_money
        where price >= (select min(price) from pocket_money where price > 0)
        window w as ()
        order by number;
-- Задача 3.1



