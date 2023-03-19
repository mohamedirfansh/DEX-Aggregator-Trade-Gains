SELECT
  DATE_TRUNC('month', minute) AS time,
  AVG(price) AS price
FROM
  prices.usd
WHERE
  symbol = 'ETH'
  AND minute BETWEEN CAST('2019-06-01' AS DATE) AND CAST('2022-12-31' AS DATE)
GROUP BY
  1
ORDER BY
  1;