-- Задача 3.1
select distinct oh.old_value                                              "Статус заказа",
                avg(oh.created_at - oh2.created_at)
                over (partition by oh.old_value order by oh.old_value) as "Среднее время заказа в статусе"
from order_history oh
         join order_history oh2
              on oh.old_value = oh2.new_value and oh.field_name = oh2.field_name and oh.order_id = oh2.order_id;
-- Задача 3.2
-- 1)
select id "ID клиента", created_at "Дата последнего визита"
from customer_visit;
-- 2)
select distinct customer_id                                      "ID клиента",
                avg(count(page)) over (partition by customer_id) "Среднее количество просмотров страниц за визит"
from customer_visit
         join customer_visit_page on customer_visit.id = customer_visit_page.visit_id
group by customer_id, visit_id
order by customer_id;
-- 3)
select customer_visit.customer_id "ID клиента",
       page                       "Адреса страниц"
--        ,time_on_page,
--        avg(time_on_page) over (partition by customer_visit.customer_id)
from customer_visit
         join customer_visit_page on customer_visit.id = customer_visit_page.visit_id
         join (select distinct customer_id, avg(time_on_page) over (partition by customer_id) as aver
               from customer_visit
                        join customer_visit_page on customer_visit.id = customer_visit_page.visit_id) as ta
              on customer_visit.customer_id = ta.customer_id and time_on_page > ta.aver
-- Check
select distinct customer_id, avg(time_on_page) over (partition by customer_id) as aver
from customer_visit
         join customer_visit_page on customer_visit.id = customer_visit_page.visit_id
order by customer_id;
-- Задача 3.3
-- ID клиента | Среднее время между заказами
select distinct o1.customer_id                                                        "ID клиента",
                avg(o2.created_at - o1.created_at) over (partition by o1.customer_id) "Среднее время между заказами"
from "order" o1
         join "order" o2 on o1.created_at < o2.created_at and o1.customer_id = o2.customer_id
order by o1.customer_id;
-- ID клиента | Количество визитов | Количество заказов
select distinct visitCount.customer_id "ID клиента",
                ordersCount."Количество заказов",
                visitCount."Количество визитов"
from "order"
         right join (select distinct customer_id,
                                     count(customer_id) over (partition by customer_id) as "Количество заказов"
                     from "order") as ordersCount on "order".customer_id = ordersCount.customer_id
         right join (select distinct customer_id,
                                     count(customer_id) over (partition by customer_id) as "Количество визитов"
                     from customer_visit) as visitCount on "order".customer_id = visitCount.customer_id;
-- Источник трафика | Количество визитов с этим источником | Количество созданных заказов |
-- Количество оплаченных заказов | Количество выполненных заказов
select distinct customer_visit.utm_source "Источник трафика",
                t1."Количество визитов с этим источником",
                t2."Количество созданных заказов",
                t3."Количество оплаченных заказов",
                t4."Количество выполненных заказов"
from customer_visit
         left join (select distinct id,
                                    utm_source,
                                    count(id) over (partition by utm_source)
                                        as "Количество визитов с этим источником"
                    from customer_visit) as t1
                   on t1.id = customer_visit.id
         left join (select distinct customer_id,
                                    utm_source,
                                    count(id) over (partition by utm_source)
                                        as "Количество созданных заказов"
                    from "order") as t2
                   on t2.utm_source = customer_visit.utm_source
         left join (select distinct utm_source,
                                    is_paid,
                                    count(id) over (partition by utm_source)
                                        as "Количество оплаченных заказов"
                    from "order"
                    where is_paid = 'true') as t3
                   on t3.utm_source = customer_visit.utm_source
         left join (select distinct utm_source,
                                    count(id) over (partition by utm_source) as "Количество выполненных заказов"
                    from "order"
                    where status_id = 3)
    as t4 on t4.utm_source = customer_visit.utm_source;
-- ID менеджера | Среднее время выполнения заказов | Доля отмененных заказов | Сумма выполненных заказов | Средняя стоимость заказов
select distinct "order".manager_id                        "ID менеджера",
                avg(t1."Среднее время выполнения заказов")
                over (partition by "order".manager_id) as "Среднее время выполнения заказов",
                t2."Доля отмененных заказов",
                t3."Сумма выполненных заказов",
                t4."Средняя стоимость заказов"
from "order"
         join
     (select o1.order_id,
             avg(o2.created_at - o1.created_at) over (partition by o1.order_id) as "Среднее время выполнения заказов"
      from "order_history" o1
               join "order_history" o2 on o1.order_id = o2.order_id
      where o1.old_value = '0'
        and o1.field_name = 'status_id'
        and o2.new_value = '3')
         as t1 on t1.order_id = "order".id
         left join (select distinct "order".manager_id,
                                    tt1.count::float /
                                    count("order".id) over (partition by "order".manager_id) as "Доля отмененных заказов"
                    from "order"
                             right join (select count(id) over () as "count", manager_id, status_id
                                         from "order"
                                         where status_id = '4')
                        as tt1 on "order".manager_id = tt1.manager_id) as t2 on t2.manager_id = "order".manager_id
         left join (select distinct manager_id,
                                    sum(total_sum) over (partition by manager_id) "Сумма выполненных заказов"
                    from "order"
                    where status_id = 3) as t3 on "order".manager_id = t3.manager_id
         left join (select distinct manager_id,
                                    avg(total_sum) over (partition by manager_id) "Средняя стоимость заказов"
                    from "order") as t4 on "order".manager_id = t4.manager_id;
-- ID менеджера | Рейтинг менеджера

select distinct "order".manager_id,
                t1."Доля выполненных менеджером заказов",
                avg(t1."Доля выполненных менеджером заказов") over () "Доля выполненных заказов в среднем"
from "order"
         join (select distinct manager_id,
                               count(status_id) over (partition by manager_id)::float /
                               count(id) over () "Доля выполненных менеджером заказов"
               from "order"
               where status_id = 3)
    as t1 on t1.manager_id = "order".manager_id
where status_id = 3;

select distinct "order".manager_id,
                (count(id) over (partition by "order".manager_id))::float /
                (tt1."Всего заказов") "Доля выполненных менеджером заказов"
from "order"
         join (select distinct manager_id, count(id) over (partition by manager_id) as "Всего заказов"
               from "order") as tt1 on tt1.manager_id = "order".manager_id
where status_id = 3;
-- 1 ()
select distinct "order".manager_id,
                tt2."Доля выполненных менеджером заказов" -
                round(avg(tt2."Доля выполненных менеджером заказов") over ()::numeric, 2) "Рейтинг1"
from "order"
         join (select distinct "order".manager_id,
                               (count(id) over (partition by "order".manager_id))::float /
                               (tt1."Всего заказов") "Доля выполненных менеджером заказов"
               from "order"
                        join (select distinct manager_id, count(id) over (partition by manager_id) as "Всего заказов"
                              from "order") as tt1 on tt1.manager_id = "order".manager_id
               where status_id = 3) as tt2
              on "order".manager_id = tt2.manager_id;
-- 2()
select distinct "order".manager_id                                                                "ID менеджера",
                extract('epoch' from ((avg(t1."Среднее время выполнения заказов")
                                       over (partition by "order".manager_id))) -
                                     (avg(t1."Среднее время выполнения заказов") over ())) / 3600 "Рейтинг2"
from "order"
         join
     (select o1.order_id,
             avg(o2.created_at - o1.created_at) over (partition by o1.order_id) as "Среднее время выполнения заказов"
      from "order_history" o1
               join "order_history" o2 on o1.order_id = o2.order_id
      where o1.old_value = '0'
        and o1.field_name = 'status_id'
        and o2.new_value = '3')
         as t1 on t1.order_id = "order".id;
-- 3()
select distinct "order".manager_id,
                tt1.count::float /
                count("order".id) over (partition by "order".manager_id) -
                round((tt2.count::float / count("order".id) over ())::numeric, 2) "Рейтинг 3"
from "order"
         left join (select count(status_id) over (partition by manager_id) as "count",
                           manager_id,
                           status_id
                    from "order"
                    where status_id = '4')
    as tt1 on "order".manager_id = tt1.manager_id
         left join (select count(id) over () as "count",
                           manager_id
                    from "order"
                    where status_id = '4') as tt2 on "order".manager_id = tt2.manager_id;
--
select distinct "order".manager_id,
                r1."Рейтинг1" + r2."Рейтинг2" -
                case
                    when r3."Рейтинг 3" is null then 0
                    else r3."Рейтинг 3" end
                    "Рейтинг менеджера"
from "order"
         left join (select distinct "order".manager_id,
                                    tt2."Доля выполненных менеджером заказов" -
                                    round(avg(tt2."Доля выполненных менеджером заказов") over ()::numeric, 2) "Рейтинг1"
                    from "order"
                             join (select distinct "order".manager_id,
                                                   (count(id) over (partition by "order".manager_id))::float /
                                                   (tt1."Всего заказов") "Доля выполненных менеджером заказов"
                                   from "order"
                                            join (select distinct manager_id,
                                                                  count(id) over (partition by manager_id) as "Всего заказов"
                                                  from "order") as tt1 on tt1.manager_id = "order".manager_id
                                   where status_id = 3) as tt2
                                  on "order".manager_id = tt2.manager_id) as r1 on r1.manager_id = "order".manager_id
         left join (select distinct "order".manager_id "ID менеджера",
                                    extract('epoch' from ((avg(t1."Среднее время выполнения заказов")
                                                           over (partition by "order".manager_id))) -
                                                         (avg(t1."Среднее время выполнения заказов") over ())) /
                                    3600               "Рейтинг2"
                    from "order"
                             join
                         (select o1.order_id,
                                 avg(o2.created_at - o1.created_at) over (partition by o1.order_id) as "Среднее время выполнения заказов"
                          from "order_history" o1
                                   join "order_history" o2 on o1.order_id = o2.order_id
                          where o1.old_value = '0'
                            and o1.field_name = 'status_id'
                            and o2.new_value = '3')
                             as t1 on t1.order_id = "order".id) as r2 on r2."ID менеджера" = "order".manager_id
         left join (select distinct "order".manager_id,
                                    tt1.count::float /
                                    count("order".id) over (partition by "order".manager_id) -
                                    round((tt2.count::float / count("order".id) over ())::numeric, 2) "Рейтинг 3"
                    from "order"
                             left join (select count(status_id) over (partition by manager_id) as "count",
                                               manager_id,
                                               status_id
                                        from "order"
                                        where status_id = '4')
                        as tt1 on "order".manager_id = tt1.manager_id
                             left join (select count(id) over () as "count", manager_id
                                        from "order"
                                        where status_id = '4') as tt2 on "order".manager_id = tt2.manager_id) as r3
                   on r3.manager_id = "order".manager_id;
