SELECT
  project,
  AVG(usd_amount) AS volume
FROM
  dex.trades
WHERE
  category = 'Aggregator'
  AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
  AND project = '1inch'
GROUP BY
  1;