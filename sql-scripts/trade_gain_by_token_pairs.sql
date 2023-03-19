WITH
  --Raw Uniswap Trade data, includes aggregators
  dex_trades_uni AS (
    SELECT
      DATE_TRUNC('hour', block_time) AS time,
      token_a_symbol,
      token_b_symbol,
      token_a_amount,
      token_b_amount,
      token_b_address,
      tx_hash,
      usd_amount,
      category,
      project
    FROM
      dex.trades
    WHERE
      project = 'Uniswap'
      AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    ORDER BY
      1 DESC
  ),
  --Raw Aggregator data, includes Uniswaps and other DEXs
  dex_trades_agg AS (
    SELECT
      DATE_TRUNC('hour', block_time) AS time,
      token_a_symbol,
      token_b_symbol,
      token_a_amount,
      token_b_amount,
      tx_hash,
      usd_amount,
      category,
      project
    FROM
      dex.trades
    WHERE
      project = '1inch'
      --category = 'Aggregator'
      AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
    ORDER BY
      1 DESC
  ),
  -- All aggregator trades
  aggregator_trades AS (
    SELECT
      DATE_TRUNC('hour', block_time) AS time,
      tx_hash
    FROM
      dex.trades
    WHERE
      category = 'Aggregator'
      AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
  ),
  -- Remove Aggregator Trades in Uniswap
  uni_distinct AS (
    SELECT
      *
    FROM
      dex_trades_uni AS u
    WHERE
      u.tx_hash NOT IN (
        SELECT
          tx_hash
        FROM
          aggregator_trades AS d
      )
  ),
  final AS (
    SELECT
      u.time,
      d.time,
      u.token_a_symbol AS token_a_symbol,
      d.token_a_symbol AS token_a_symbol_d,
      u.token_b_symbol AS token_b_symbol,
      d.token_b_symbol AS token_b_symbol_d,
      u.token_a_amount,
      d.token_a_amount,
      u.token_b_amount,
      d.token_b_amount,
      u.tx_hash,
      d.tx_hash,
      u.usd_amount,
      d.usd_amount,
      (
        (
          (d.token_a_amount - u.token_a_amount) / u.token_a_amount
        ) * 100
      ) AS gain,
      coalesce(d.usd_amount, u.usd_amount) AS value
    FROM
      uni_distinct AS u
      INNER JOIN dex_trades_agg AS d ON (
        u.time = d.time
        AND u.token_a_symbol = d.token_a_symbol
        AND u.token_b_symbol = d.token_b_symbol
        AND u.token_b_amount = d.token_b_amount
        AND u.tx_hash != d.tx_hash
      )
    WHERE
      u.token_a_amount != 0
      AND d.token_a_amount != 0
    ORDER BY
      15 DESC
  ),
  quartiles AS (
    SELECT
      PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY
          gain
      ) AS Q1,
      PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY
          gain
      ) AS Q3
    FROM
      final
  ),
  range AS (
    SELECT
      (Q3 - Q1) * 1.5 AS IQR
    FROM
      quartiles
  ),
  without_outliers AS (
    SELECT
      *
    FROM
      final
    WHERE
      gain BETWEEN (
        SELECT
          Q1 - IQR
        FROM
          quartiles,
          range
      ) AND (
        SELECT
          Q3 + IQR
        FROM
          quartiles,
          range
      )
  )
SELECT
  LEAST(
    CASE
      WHEN "token_a_symbol" = 'WETH' THEN 'ETH'
      ELSE "token_a_symbol"
    END,
    CASE
      WHEN "token_b_symbol" = 'WETH' THEN 'ETH'
      ELSE "token_b_symbol"
    END
  ) || ' - ' || greatest(
    CASE
      WHEN "token_a_symbol" = 'WETH' THEN 'ETH'
      ELSE "token_a_symbol"
    END,
    CASE
      WHEN "token_b_symbol" = 'WETH' THEN 'ETH'
      ELSE "token_b_symbol"
    END
  ) AS pair,
  AVG(gain) AS avg_gain
FROM
  without_outliers
GROUP BY
  1
ORDER BY
  avg_gain DESC;