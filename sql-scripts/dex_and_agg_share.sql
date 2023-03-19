WITH
  dex_volume AS (
    SELECT
      DATE_TRUNC('month', block_time) AS time,
      SUM(usd_amount) AS dex_volume
    FROM
      dex.trades
    WHERE
      category = 'DEX'
      AND project NOT IN ('Matcha', 'Tokenlon')
      AND block_time BETWEEN CAST('2019-06-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    GROUP BY
      1
    ORDER BY
      1 DESC
  ),
  aggregator_volume AS (
    SELECT
      DATE_TRUNC('month', block_time) AS time,
      SUM(usd_amount) AS aggregator_volume
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
  (d.dex_volume - a.aggregator_volume) AS Standard_DEX,
  a.aggregator_volume AS Aggregator
FROM
  dex_volume d
  JOIN aggregator_volume a ON d.time = a.time;