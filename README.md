
WITH src AS (
  SELECT unnest(ARRAY[${source:sqlstring}]) AS source
),
app AS (
  SELECT id, created_at, status_id
  FROM t_credit_applications_v3
  WHERE $__timeFilter(created_at)
    AND created_at < now()::timestamp - interval '1 hour'
),
notif AS (
  SELECT credit_application_id, source, status_id,
         min(requested_at) AS sent_at,
         bool_or(status = 100) AS confirmed
  FROM t_cb_responses_v3
  WHERE status_id IN (2,4,5) AND requested_at IS NOT NULL
  GROUP BY 1,2,3
)
SELECT
  s.source AS "Бюро",
  count(*) AS "Заявок",
  count(*) FILTER (WHERE n.sent_at IS NOT NULL
        AND n.sent_at - a.created_at <= interval '1 hour') AS "В срок",
  count(*) FILTER (WHERE n.sent_at IS NOT NULL
        AND n.sent_at - a.created_at > interval '1 hour') AS "Опоздали",
  count(*) FILTER (WHERE n.sent_at IS NULL) AS "Не отправлено",
  round(100.0 * count(*) FILTER (WHERE n.sent_at IS NOT NULL
        AND n.sent_at - a.created_at <= interval '1 hour')
        / nullif(count(*), 0), 2) AS "% SLA"
FROM app a
CROSS JOIN src s
LEFT JOIN notif n
  ON n.credit_application_id = a.id
 AND n.source = s.source
 AND n.status_id = a.status_id
GROUP BY s.source
ORDER BY s.source;

WITH src AS (
  SELECT unnest(ARRAY[${source:sqlstring}]) AS source
),
app AS (
  SELECT id, created_at, status_id
  FROM t_credit_applications_v3
  WHERE created_at > now()::timestamp - interval '3 hours'
),
notif AS (
  SELECT credit_application_id, source, status_id, min(requested_at) AS sent_at
  FROM t_cb_responses_v3
  WHERE status_id IN (2,4,5) AND requested_at IS NOT NULL
  GROUP BY 1,2,3
)
SELECT
  a.id AS "Заявка",
  s.source AS "Бюро",
  a.status_id AS "Статус",
  a.created_at AS "Создана",
  round((extract(epoch FROM (a.created_at + interval '1 hour' - now()::timestamp))/60)::numeric, 0) AS "Осталось, мин"
FROM app a
CROSS JOIN src s
LEFT JOIN notif n
  ON n.credit_application_id = a.id AND n.source = s.source AND n.status_id = a.status_id
WHERE n.sent_at IS NULL
ORDER BY 5 ASC
LIMIT 200;
