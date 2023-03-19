--Most used dexs by aggregators time series
WITH
  dex_volume AS (
    SELECT
      DATE_TRUNC('month', block_time) AS time,
      usd_amount AS dex_volume,
      tx_hash,
      project
    FROM
      dex.trades
    WHERE
      category = 'DEX'
      AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    ORDER BY
      1 DESC
  ),
  aggregator_volume AS (
    SELECT
      DATE_TRUNC('month', block_time) AS time,
      usd_amount AS aggregator_volume,
      tx_hash,
      project
    FROM
      dex.trades
    WHERE
      category = 'Aggregator'
      AND project != 'Matcha' --0x API accounts for Matcha trades
      AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    ORDER BY
      1 DESC
  ),
  monthly_usage_by_aggregators AS (
    SELECT
      a.time,
      d.project AS dex,
      SUM(d.dex_volume) AS volumes
    FROM
      aggregator_volume a
      LEFT JOIN dex_volume d ON a.tx_hash = d.tx_hash
    GROUP BY
      1,
      2
    ORDER BY
      1 DESC
  )

SELECT
  *
FROM
  monthly_usage_by_aggregators
WHERE
  volumes > 1000000;--minumum $1,000,000 usage to show clearly on the graphs