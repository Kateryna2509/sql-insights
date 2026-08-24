WITH
  account_os AS (
    SELECT DISTINCT
      acs.account_id AS account_id,
      sp.operating_system
    FROM `DA.account_session` acs
    JOIN `DA.session_params` sp
      ON acs.ga_session_id = sp.ga_session_id
  ),
  accounts AS (
    SELECT id
    FROM `DA.account`
    WHERE is_unsubscribed = 0
  )
SELECT
  os.operating_system,
  COUNT(DISTINCT es.id_message) AS sent_msg,
  COUNT(DISTINCT eo.id_message) AS open_msg,
  COUNT(DISTINCT ev.id_message) AS visit_msg,
  COUNT(DISTINCT eo.id_message) / COUNT(DISTINCT es.id_message) * 100 AS open_rate,
  COUNT(DISTINCT ev.id_message) / COUNT(DISTINCT es.id_message) * 100 AS click_rate,
  COUNT(DISTINCT ev.id_message) / COUNT(DISTINCT eo.id_message) * 100 AS ctor
FROM `DA.email_sent` es
LEFT JOIN `DA.email_open` eo
  ON es.id_message = eo.id_message
LEFT JOIN `DA.email_visit` ev
  ON es.id_message = ev.id_message
JOIN account_os os
  ON es.id_account = os.account_id
JOIN accounts acc
  ON acc.id = es.id_account
GROUP BY operating_system
