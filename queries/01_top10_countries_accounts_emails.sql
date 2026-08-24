WITH
  account_inf AS (
    SELECT
      se.date AS date,
      sp.country AS country,
      acc.send_interval AS send_interval,
      acc.is_verified AS is_verified,
      acc.is_unsubscribed AS is_unsubscribed,
      COUNT(DISTINCT acc.id) AS account_cnt,
      0 sent_msg,
      0 open_msg,
      0 visit_msg
    FROM `DA.account` acc
    JOIN `DA.account_session` acs
      ON acc.id = acs.account_id
    JOIN `DA.session` se
      ON se.ga_session_id = acs.ga_session_id
    JOIN `DA.session_params` sp
      ON se.ga_session_id = sp.ga_session_id
    GROUP BY
      se.date,
      sp.country,
      acc.send_interval,
      acc.is_verified,
      acc.is_unsubscribed
  ),

  email_date AS (
    SELECT
      date_add(se.date, INTERVAL sent_date day) AS date,
      country,
      send_interval,
      is_verified,
      is_unsubscribed,
      0 account_cnt,
      COUNT(DISTINCT es.id_message) AS sent_msg,
      COUNT(DISTINCT eo.id_message) AS open_msg,
      COUNT(DISTINCT ev.id_message) AS visit_msg
    FROM `DA.email_sent` es
    LEFT JOIN `DA.email_open` eo
      ON es.id_message = eo.id_message
    LEFT JOIN `DA.email_visit` ev
      ON es.id_message = ev.id_message
    JOIN `DA.account_session` acs
      ON acs.account_id = es.id_account
    JOIN `DA.session` se
      ON se.ga_session_id = acs.ga_session_id
    JOIN `DA.session_params` sp
      ON se.ga_session_id = sp.ga_session_id
    JOIN `DA.account` acc
      ON acc.id = es.id_account
    GROUP BY
      date,
      sp.country,
      acc.send_interval,
      acc.is_verified,
      acc.is_unsubscribed
  ),

  account_email AS (
    SELECT * FROM account_inf
    UNION ALL
    SELECT * FROM email_date
  ),

  group_ac_em AS (
    SELECT
      date,
      country,
      send_interval,
      is_verified,
      is_unsubscribed,
      sum(account_cnt) AS account_cnt,
      sum(sent_msg) AS sent_msg,
      sum(open_msg) AS open_msg,
      sum(visit_msg) AS visit_msg
    FROM account_email
    GROUP BY 1, 2, 3, 4, 5
  ),

  total AS (
    SELECT
      *,
      sum(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt,
      sum(sent_msg) OVER (PARTITION BY country) AS total_country_sent_cnt
    FROM group_ac_em
  ),

  rank_total AS (
    SELECT
      *,
      dense_rank() OVER (ORDER BY total_country_sent_cnt DESC) AS rank_total_country_sent_cnt,
      dense_rank() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt
    FROM total
  )

SELECT
  date,
  country,
  send_interval,
  is_verified,
  is_unsubscribed,
  account_cnt,
  sent_msg,
  open_msg,
  visit_msg,
  total_country_account_cnt,
  total_country_sent_cnt,
  rank_total_country_account_cnt,
  rank_total_country_sent_cnt
FROM rank_total
WHERE rank_total_country_sent_cnt <= 10 OR rank_total_country_account_cnt <= 10
ORDER BY rank_total_country_account_cnt, rank_total_country_sent_cnt, date DESC
