WITH aggregators AS (
  SELECT
    project,
    SUM(usd_amount) AS volume
  FROM
    dex.trades
  WHERE
    category = 'Aggregator'
    AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    AND project NOT IN ('Matcha', 'Tokenlon')
  GROUP BY
    1
)
SELECT
  ROW_NUMBER() OVER (ORDER BY volume DESC) AS rank_,
  project,
  volume
FROM
  aggregators
ORDER BY
  1;