WITH
  dex_users AS (
    SELECT
      DATE_TRUNC('month', block_time) AS time,
      COUNT(DISTINCT tx_from) AS dex_users
    FROM
      dex.trades
    WHERE
      category = 'DEX'
      AND block_time BETWEEN CAST('2019-06-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    GROUP BY
      1
    ORDER BY
      1 DESC
  ),
  aggregator_users AS (
    SELECT
      DATE_TRUNC('month', block_time) AS time,
      COUNT(DISTINCT tx_from) AS aggregator_users
    FROM
      dex.trades
    WHERE
      category = 'Aggregator'
      AND project NOT IN ('Matcha', 'Tokenlon')
      AND block_time BETWEEN CAST('2019-06-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    GROUP BY
      1
    ORDER BY
      1 DESC
  )

SELECT
  d.time,
  (d.dex_users - a.aggregator_users) AS standard_dex,
  a.aggregator_users AS aggregator
FROM
  dex_users d
  JOIN aggregator_users a ON d.time = a.time
ORDER BY
  1;