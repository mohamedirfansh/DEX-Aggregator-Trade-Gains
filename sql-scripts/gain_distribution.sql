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
  --Raw Aggregator (1inch) data
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
  -- Final table with gain calculated after comparison
  final AS (
    SELECT
      u.time,
      d.time,
      u.token_a_symbol,
      d.token_a_symbol,
      u.token_b_symbol,
      d.token_b_symbol,
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
      COALESCE(d.usd_amount, u.usd_amount) AS value
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
  -- Intervals to plot distribution
  intervals AS (
    SELECT -100 AS lower_limit, -50 AS upper_limit UNION ALL
    SELECT -50, -40 UNION ALL
    SELECT -40, -30 UNION ALL
    SELECT -30, -20 UNION ALL
    SELECT -20, -10 UNION ALL
    SELECT -10, 0 UNION ALL
    SELECT 0, 10 UNION ALL
    SELECT 10, 20 UNION ALL
    SELECT 20, 30 UNION ALL
    SELECT 30, 40 UNION ALL
    SELECT 40, 50 UNION ALL
    SELECT 50, 100 UNION ALL
    SELECT 100, 60000000
  ),
  -- Histogram data using intervals
  histogram AS (
    SELECT
      intervals.lower_limit,
      intervals.upper_limit,
      COUNT(
        CASE
          WHEN gain >= intervals.lower_limit
          AND gain < intervals.upper_limit THEN gain
        END
      ) AS count_
    FROM
      intervals
      LEFT JOIN final ON gain >= intervals.lower_limit
      AND gain < intervals.upper_limit
    GROUP BY
      intervals.lower_limit,
      intervals.upper_limit
  )
SELECT
  *
FROM
  histogram
ORDER BY
  upper_limit;