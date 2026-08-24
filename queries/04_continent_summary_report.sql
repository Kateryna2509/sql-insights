WITH
  revenue AS (
    SELECT
      continent,
      SUM(pr.price) AS revenue,
      SUM(CASE WHEN sp.device = 'desktop' THEN pr.price END) AS revenue_from_desktop,
      SUM(CASE WHEN sp.device = 'mobile' THEN pr.price END) AS revenue_from_mobile
    FROM `DA.order` ord
    JOIN `DA.product` pr
      ON ord.item_id = pr.item_id
    JOIN `DA.session_params` sp
      ON sp.ga_session_id = ord.ga_session_id
    GROUP BY continent
  ),
  account_info AS (
    SELECT
      sp.continent,
      COUNT(DISTINCT acs.account_id) AS account_count,
      COUNT(DISTINCT CASE WHEN acc.is_verified = 1 THEN acc.id END) AS verified_account
    FROM `DA.account` acc
    LEFT JOIN `DA.account_session` acs
      ON acc.id = acs.account_id
    JOIN `DA.session_params` sp
      ON sp.ga_session_id = acs.ga_session_id
    GROUP BY sp.continent
  ),
  session_cnt AS (
    SELECT
      continent,
      COUNT(*) AS session_count
    FROM `DA.session_params`
    GROUP BY continent
  )
SELECT
  sc.continent,
  r.revenue,
  r.revenue_from_mobile,
  r.revenue_from_desktop,
  ROUND(r.revenue / SUM(r.revenue) OVER () * 100, 2) AS revenue_from_total_pct,
  ai.account_count,
  ai.verified_account,
  sc.session_count
FROM session_cnt sc
LEFT JOIN account_info ai
  ON sc.continent = ai.continent
LEFT JOIN revenue r
  ON r.continent = sc.continent
ORDER BY r.revenue DESC
