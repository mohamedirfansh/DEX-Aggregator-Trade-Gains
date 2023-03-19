SELECT
  DATE_TRUNC('month', block_time) AS time,
  project,
  SUM(usd_amount) AS volume
FROM
  dex.trades
WHERE
  category = 'DEX'
  AND block_time BETWEEN CAST('2019-06-01' AS DATE) AND CAST('2023-01-01' AS DATE)
  AND project IN ('Uniswap', 'Sushiswap', 'Curve', 'Bancor', 'Balancer', 'DODO')
GROUP BY
  1,
  2;