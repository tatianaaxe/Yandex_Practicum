-- 1. Отобразите все записи из таблицы company по компаниям, которые закрылись.
SELECT COUNT(status)
FROM company
WHERE status = 'closed'
;

-- 2. Отобразите количество привлечённых средств для новостных компаний США. Используйте данные из таблицы company. Отсортируйте таблицу по убыванию значений в поле funding_total.
SELECT funding_total
FROM company
WHERE category_code = 'news' AND country_code='USA'
--GROUP BY category_code
ORDER BY funding_total DESC
;

-- 3. Найдите общую сумму сделок по покупке одних компаний другими в долларах. Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.
SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash' AND (EXTRACT(YEAR FROM acquired_at) BETWEEN 2011 AND 2013)
;

-- 4. Отобразите имя, фамилию и названия аккаунтов людей в поле network_username, у которых названия аккаунтов начинаются на 'Silver'.
SELECT first_name,
last_name,
twitter_username
FROM people
WHERE twitter_username LIKE ('Silver%')
;

-- 5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в поле network_username содержат подстроку 'money', а фамилия начинается на 'K'.
SELECT *
FROM people
WHERE twitter_username LIKE ('%money%') AND last_name LIKE 'K%'
;

-- 6. Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране. Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируйте данные по убыванию суммы.
SELECT country_code,
SUM(funding_total)
FROM company
--WHERE twitter_username LIKE ('%money%') AND last_name LIKE 'K%'
GROUP BY 1
ORDER BY 2 DESC
;

-- 7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
-- Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.
SELECT funded_at,
MIN(raised_amount),
MAX(raised_amount)
FROM funding_round
GROUP BY 1
HAVING (MIN(raised_amount) != 0) AND (MIN(raised_amount) != MAX(raised_amount))
;

-- 8. Создайте поле с категориями:
-- Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
-- Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
-- Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
-- Отобразите все поля таблицы fund и новое поле с категориями.
SELECT *,
case
WHEN invested_companies >= 100 THEN 'high_activity'
WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
WHEN invested_companies < 20 THEN 'low_activity'
END
FROM fund
;

-- 9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего.
SELECT ROUND(AVG(investment_rounds)) as avg_rounds,
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund
GROUP BY activity
ORDER BY avg_rounds
;

-- 10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
-- Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно. Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
-- Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. Затем добавьте сортировку по коду страны в лексикографическом порядке.
SELECT country_code,
       MIN(invested_companies) AS min_count,
       MAX(invested_companies) AS max_count,
       AVG(invested_companies) AS avg_count
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) BETWEEN 2010 AND 2012 
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY avg_count DESC
LIMIT 10;

-- 11. Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.
SELECT p.first_name,
p.last_name,
e.instituition
FROM people as p
LEFT JOIN education as e on p.id=e.person_id;

-- 12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. Выведите название компании и число уникальных названий учебных заведений. Составьте топ-5 компаний по количеству университетов.
SELECT c.name,
COUNT(DISTINCT e.instituition)
FROM company as c
LEFT JOIN people as p ON c.id=p.company_id
JOIN education as e on p.id=e.person_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5
;

-- 13. Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним.
SELECT name
FROM company
WHERE status='closed'
  AND id IN 

(SELECT company_id
FROM funding_round
WHERE is_first_round=1 AND is_last_round=1);

-- 14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.
SELECT id
FROM people
WHERE company_id in
(SELECT id
FROM company
WHERE status='closed'
  AND id IN 

(SELECT company_id
FROM funding_round
WHERE is_first_round=1 AND is_last_round=1));

-- 15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник.
SELECT DISTINCT p.id,
e.instituition
FROM people as p
JOIN education as e on p.id=e.person_id
WHERE company_id in
(SELECT id
FROM company
WHERE status='closed'
  AND id IN 

(SELECT company_id
FROM funding_round
WHERE is_first_round=1 AND is_last_round=1));

-- 16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.
SELECT DISTINCT p.id,
COUNT(e.instituition)
FROM people as p
JOIN education as e on p.id=e.person_id
WHERE company_id in
(SELECT id
FROM company
WHERE status='closed'
  AND id IN 

(SELECT company_id
FROM funding_round
WHERE is_first_round=1 AND is_last_round=1))
GROUP BY p.id;

-- 17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится.
SELECT AVG(ei)
FROM
(SELECT  p.id,
COUNT(e.instituition) as ei
FROM people as p
JOIN education as e on p.id=e.person_id
WHERE company_id in
(SELECT id
FROM company
WHERE status='closed'
  AND id IN 

(SELECT company_id
FROM funding_round
WHERE is_first_round=1 AND is_last_round=1))
GROUP BY p.id) as ce;

-- 18. Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Socialnet.
SELECT AVG(ei)
FROM
(SELECT  p.id,
COUNT(e.instituition) as ei
FROM people as p
JOIN education as e on p.id=e.person_id
WHERE company_id in 
 (SELECT id
  FROM company
  WHERE name='Facebook')
GROUP BY p.id) as ce
;

-- 19. Составьте таблицу из полей:
-- name_of_fund — название фонда;
-- name_of_company — название компании;
-- amount — сумма инвестиций, которую привлекла компания в раунде.
-- В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно.
SELECT f.name as name_of_fund,
c.name as name_of_company ,
fr.raised_amount as amount
FROM investment as i
LEFT JOIN company as c ON i.company_id=c.id
LEFT JOIN fund as f ON i.fund_id=f.id
LEFT JOIN funding_round as fr ON i.funding_round_id = fr.id
WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2012 AND 2013
AND c.milestones > 6;

-- 20. Выгрузите таблицу, в которой будут такие поля:
-- название компании-покупателя;
-- сумма сделки;
-- название компании, которую купили;
-- сумма инвестиций, вложенных в купленную компанию;
-- доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
-- Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
-- Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничьте таблицу первыми десятью записями.
SELECT c.name as acquiring_company,
a.price_amount,
ca.name as acquired_company,
ca.funding_total,
ROUND((a.price_amount)/ca.funding_total)
FROM acquisition as a
LEFT JOIN company as c ON a.acquiring_company_id=c.id
LEFT JOIN company as ca ON a.acquired_company_id=ca.id
WHERE a.price_amount != 0
AND ca.funding_total !=0
ORDER BY 2 DESC, 3
LIMIT 10
;

-- 21. Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.
SELECT c.name as name,
EXTRACT(MONTH FROM CAST(fr.funded_at as DATE))
FROM company as c
LEFT JOIN funding_round as fr ON c.id=fr.company_id
WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date))BETWEEN 2010 and 2013
AND fr.raised_amount !=0
AND c.category_code = 'social';

-- 22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
-- номер месяца, в котором проходили раунды;
-- количество уникальных названий фондов из США, которые инвестировали в этом месяце;
-- количество компаний, купленных за этот месяц;
-- общая сумма сделок по покупкам в этом месяце.
WITH
fund_count AS (
               SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS month_number,
                      COUNT(DISTINCT f.name) AS fund_count_USA       
               FROM funding_round AS fr
               LEFT OUTER JOIN investment AS i 
               ON fr.id=i.funding_round_id
               LEFT OUTER JOIN fund AS f 
               ON i.fund_id=f.id
               WHERE f.country_code='USA'
               AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013
               GROUP BY  EXTRACT(MONTH FROM CAST(fr.funded_at AS date))
               ),
comp_count AS (
               SELECT EXTRACT(MONTH FROM CAST(acquired_at AS date)) AS month_number,
                      COUNT(id) AS company_count,
                      SUM(price_amount) AS total_amount
               FROM  acquisition
               WHERE EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN 2010 AND 2013
               GROUP BY EXTRACT(MONTH FROM CAST(acquired_at AS date)) 
               )                             
SELECT fund_count.month_number,
       fund_count_USA,
       company_count, 
       total_amount
FROM fund_count 
LEFT JOIN comp_count 
ON fund_count.month_number=comp_count.month_number;

-- 23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.
WITH
y_2011 AS (
           SELECT country_code,
                  AVG(funding_total) AS year_2011
           FROM company
           WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2011
           GROUP BY country_code
           ),
y_2012 AS (
           SELECT country_code,
                  AVG(funding_total) AS  year_2012
           FROM company
           WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2012
           GROUP BY country_code
           ), 
y_2013 AS (
           SELECT country_code,
                 AVG(funding_total) AS year_2013
           FROM company
           WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2013
           GROUP BY country_code
           )

SELECT y_2011.country_code,
       year_2011,
       year_2012,
       year_2013
FROM  y_2011 JOIN y_2012  
ON y_2011.country_code=y_2012.country_code
INNER JOIN y_2013 
ON y_2011.country_code=y_2013.country_code
ORDER BY year_2011 DESC;
