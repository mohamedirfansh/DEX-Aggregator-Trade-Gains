WITH
  uniswap_volume AS (
    SELECT
      DATE_TRUNC('day', block_time) AS time,
      usd_amount AS uni_volume,
      tx_hash
    FROM
      dex.trades
    WHERE
      project = 'Uniswap'
      AND category = 'DEX'
      AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    ORDER BY
      1 DESC
  ),
  uni_trades_distinct AS (
    SELECT distinct
      ON (tx_hash) *
    FROM
      uniswap_volume
  ),
  uniswap_volume_distinct AS (
    SELECT
      tx_hash,
      SUM(uniswap_volume.uni_volume) AS uni_volume
    FROM
      uniswap_volume
    GROUP BY
      1
    ORDER BY
      1 DESC
  ),
  uni_volume_fl AS (
    SELECT
      time,
      u.uni_volume AS u_vol
    FROM
      uniswap_volume_distinct u
      JOIN uni_trades_distinct t ON u.tx_hash = t.tx_hash
  )
SELECT
  AVG(u_vol)
FROM
  uni_volume_fl;