-- Часть 1.
-- 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
SELECT COUNT(id)
FROM stackoverflow.posts
WHERE (score>300 OR favorites_count >=100)
AND post_type_id = 1
;

-- 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
WITH
cnt AS
(SELECT CAST(DATE_TRUNC('day', p.creation_date) AS date) AS date, COUNT(p.id)
FROM stackoverflow.posts p
WHERE post_type_id = 1
GROUP BY CAST(DATE_TRUNC('day', p.creation_date) AS date)
HAVING CAST(DATE_TRUNC('day', p.creation_date) AS date) BETWEEN '2008-11-01' AND '2008-11-18')
SELECT ROUND(AVG(count)) FROM cnt
;

-- 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
WITH
cnt AS
(SELECT CAST(DATE_TRUNC('day', p.creation_date) AS date) AS date, COUNT(p.id)
FROM stackoverflow.posts p
WHERE post_type_id = 1
GROUP BY CAST(DATE_TRUNC('day', p.creation_date) AS date)
HAVING CAST(DATE_TRUNC('day', p.creation_date) AS date) BETWEEN '2008-11-01' AND '2008-11-18')
SELECT ROUND(AVG(count)) FROM cnt
;

-- 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
SELECT COUNT(DISTINCT(p.id))
FROM stackoverflow.posts p
JOIN stackoverflow.users u
ON p.user_id = u.id
RIGHT JOIN stackoverflow.votes v
ON p.id = v.post_id
WHERE u.display_name LIKE 'Joel Coehoorn'
;

-- 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.
SELECT * ,
RANK() OVER (ORDER BY id DESC)
FROM stackoverflow.vote_types 
ORDER BY id
;

-- 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
SELECT u.id, COUNT(*)
FROM stackoverflow.users u 
RIGHT JOIN stackoverflow.votes v ON u.id=v.user_id
JOIN stackoverflow.vote_types vt ON v.vote_type_id=vt.id
WHERE vt.name LIKE ('Close')
GROUP BY 1
ORDER BY 2 DESC, 1 DESC
LIMIT 10
;

-- 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
-- Отобразите несколько полей:
-- идентификатор пользователя;
-- число значков;
-- место в рейтинге — чем больше значков, тем выше рейтинг.
-- Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
-- Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
SELECT user_id,
       COUNT (id),
       DENSE_RANK () OVER (ORDER BY COUNT (id) DESC)
FROM stackoverflow.badges       
WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
ORDER BY COUNT (id) DESC,
         user_id
LIMIT 10;

-- 8. Сколько в среднем очков получает пост каждого пользователя?
-- Сформируйте таблицу из следующих полей:
-- заголовок поста;
-- идентификатор пользователя;
-- число очков поста;
-- среднее число очков пользователя за пост, округлённое до целого числа.
-- Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
SELECT title,
user_id,
score,
ROUND(AVG(score) OVER (PARTITION BY user_id)) AS score_avg
FROM stackoverflow.posts
WHERE score !=0
AND title IS NOT NULL
GROUP BY 1, 2, 3
;

-- 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
SELECT title
FROM stackoverflow.posts p
WHERE user_id in 

(SELECT user_id FROM stackoverflow.badges GROUP BY user_id HAVING COUNT(id)>1000)
AND p.title IS NOT NULL
;

-- 10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
-- пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
-- пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
-- пользователям с числом просмотров меньше 100 — группу 3.
-- Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.
SELECT id,
views,
CASE
  WHEN views>=350 THEN 1
  WHEN views>=100 AND views<350 THEN 2
  ELSE 3
END AS gr
FROM stackoverflow.users
WHERE location LIKE '%Canada%'
AND views !=0
;

-- 11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
WITH tab AS
(SELECT t.id,
        t.views,
        t.group,
        MAX(t.views) OVER (PARTITION BY t.group) AS max	
 FROM (SELECT id,
              views,
              CASE
                 WHEN views>=350 THEN 1
                 WHEN views<100 THEN 3
                 ELSE 2
              END AS group
       FROM stackoverflow.users
       WHERE location LIKE '%Canada%'
          AND views != 0
          ) as t
  )
  
SELECT tab.id, 
       tab.views,  
       tab.group
FROM tab
WHERE tab.views = tab.max
ORDER BY tab.views DESC, tab.id;

-- 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
-- номер дня;
-- число пользователей, зарегистрированных в этот день;
-- сумму пользователей с накоплением.
WITH
t1 AS
(SELECT CAST(DATE_TRUNC('day', creation_date) AS date) AS dt, COUNT(id) AS val
FROM stackoverflow.users
GROUP BY CAST(DATE_TRUNC('day', creation_date) AS date)
ORDER BY CAST(DATE_TRUNC('day', creation_date) AS date))

SELECT RANK() OVER(ORDER BY dt) ,val,
SUM(val) OVER (ORDER BY dt) AS cum
FROM t1 
WHERE dt BETWEEN '2008-11-01' AND '2008-11-30'
;

-- 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
-- идентификатор пользователя;
-- разницу во времени между регистрацией и первым постом.
WITH p AS 
(SELECT user_id, creation_date,
RANK() OVER (PARTITION BY user_id ORDER BY creation_date)  AS first_pub
FROM stackoverflow.posts 

ORDER BY user_id)

SELECT user_id, p.creation_date - u.creation_date FROM p
JOIN stackoverflow.users u ON p.user_id = u.id
WHERE first_pub = 1
;

-- Часть 2.
-- 1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
SELECT CAST(DATE_TRUNC('month', creation_date) AS date) AS month, SUM(views_count) AS sum
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-01-01' AND '2008-12-31'
GROUP BY CAST(DATE_TRUNC('month', creation_date) AS date)
ORDER BY sum DESC
;

-- 2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT display_name,
       COUNT(DISTINCT(user_id))
FROM stackoverflow.users AS u JOIN stackoverflow.posts AS p ON u.id=p.user_id
JOIN stackoverflow.post_types AS t ON p.post_type_id=t.id
WHERE (DATE_TRUNC('day', p.creation_date) <= DATE_TRUNC('day', u.creation_date) + INTERVAL '1 month') AND (p.post_type_id=2)
GROUP BY display_name
HAVING COUNT(p.id) > 100;

-- 3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.
WITH
t1 AS 
(SELECT u.id
FROM stackoverflow.users AS u JOIN stackoverflow.posts AS p ON u.id=p.user_id
WHERE (u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30')
AND ((p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31'))
GROUP BY u.id)

SELECT CAST(DATE_TRUNC('month', p.creation_date) AS date) AS month, COUNT(p.id) AS cnt
FROM stackoverflow.users AS u JOIN stackoverflow.posts AS p ON u.id=p.user_id
WHERE (p.creation_date::date BETWEEN '2008-01-01' AND '2008-12-31')
AND p.user_id IN (SELECT * FROM t1)
GROUP BY CAST(DATE_TRUNC('month', p.creation_date) AS date)
ORDER BY CAST(DATE_TRUNC('month', p.creation_date) AS date) DESC
;

-- 4. Используя данные о постах, выведите несколько полей:
-- идентификатор пользователя, который написал пост;
-- дата создания поста;
-- количество просмотров у текущего поста;
-- сумма просмотров постов автора с накоплением.
-- Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
SELECT user_id,
creation_date,
views_count,
SUM(views_count) OVER(PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts
ORDER BY 1, 2
;

-- 5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.
WITH users AS (
SELECT user_id,
    COUNT(distinct creation_date::date)
FROM stackoverflow.posts
WHERE creation_date BETWEEN '2008-12-01' AND '2008-12-08'
GROUP BY 1
HAVING COUNT(id)>=1
)
SELECT ROUND(AVG(count))
FROM users
;

-- 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
-- Номер месяца.
-- Количество постов за месяц.
-- Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
-- Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
-- Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.
with a AS (SELECT EXTRACT(month from creation_date) AS num, COUNT(id) AS cnt
           FROM stackoverflow.posts
           WHERE  creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
          GROUP BY 1)

          SELECT num, cnt, ROUND(((cnt::numeric/LAG(cnt) OVER (ORDER BY num))-1)*100,2)
          FROM a
;

-- 7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
-- номер недели;
-- дата и время последнего поста, опубликованного на этой неделе.
SELECT
DISTINCT(EXTRACT(week FROM creation_date::date)),
MAX(creation_date) OVER (ORDER BY EXTRACT(week FROM creation_date::date))
FROM stackoverflow.posts
WHERE user_id = 22656
AND creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'
;
