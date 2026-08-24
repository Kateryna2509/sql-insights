CREATE VIEW `Students.project_dataset_view` AS
WITH
  sent_month_account AS (
    SELECT
      es.id_account,
      DATE_ADD(se.date, INTERVAL es.sent_date DAY) AS date_sent,
      DATE_TRUNC(DATE_ADD(se.date, INTERVAL es.sent_date DAY), MONTH) AS sent_month,
      COUNT(es.id_message) AS message_id
    FROM `data-analytics-mate.DA.email_sent` es
    JOIN `DA.account_session` acs
      ON es.id_account = acs.account_id
    JOIN `DA.session` se
      ON acs.ga_session_id = se.ga_session_id
    GROUP BY date_sent, sent_month, es.id_account
  )
SELECT
  sent_month,
  id_account,
  ROUND(
    SUM(message_id) / SUM(SUM(message_id)) OVER (PARTITION BY sent_month) * 100,
    4
  ) AS sent_msg_percent_from_this_month,
  MIN(date_sent) AS first_sent_date,
  MAX(date_sent) AS last_sent_date
FROM sent_month_account
GROUP BY sent_month, id_account
