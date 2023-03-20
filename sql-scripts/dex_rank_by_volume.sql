WITH
  dex_volume AS (
    SELECT
      project,
      SUM(usd_amount) AS volume
    FROM
      dex.trades
    WHERE
      category = 'DEX'
      AND block_time BETWEEN CAST('2019-06-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    GROUP BY
      1
  )

SELECT
  ROW_NUMBER() OVER (
    ORDER BY
      volume DESC
  ) AS rank_,
  project,
  volume
FROM
  dex_volume
WHERE
  dex_volume.volume > 0
ORDER by
  1;