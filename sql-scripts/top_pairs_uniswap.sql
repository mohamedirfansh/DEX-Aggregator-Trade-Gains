WITH
  full_volume AS (
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
      ) || ' - ' || GREATEST(
        CASE
          WHEN "token_a_symbol" = 'WETH' THEN 'ETH'
          ELSE "token_a_symbol"
        END,
        CASE
          WHEN "token_b_symbol" = 'WETH' THEN 'ETH'
          ELSE "token_b_symbol"
        END
      ) AS pair,
      ROW_NUMBER () OVER (
        ORDER BY
          SUM(usd_amount) DESC NULLS LAST
      ) AS id,
      COUNT(distinct tx_from) AS wallets,
      COUNT(*) AS swaps,
      SUM(usd_amount) AS volume
    FROM
      dex.trades
    WHERE
      tx_to IN (
        '\x7a250d5630b4cf539739df2c5dacb4c659f2488d', -- Uniswap V2 Router
        '\xe592427a0aece92de3edee1f18e0157c05861564', -- Uniswap V3 Router
        '\x68b3465833fb72a70ecdf485e0e4c7bd8665fc45'  -- Uniswap V3 Router 2
      )
      AND project = 'Uniswap'
      AND block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
      AND "token_a_symbol" IS NOT NULL
      AND "token_b_symbol" IS NOT NULL
    GROUP BY
      1
    ORDER BY
      volume DESC NULLS LAST
  )
SELECT
  CASE
    WHEN id < 11 THEN pair
    ELSE 'Others'
  END AS pair,
  SUM(volume) AS volume,
  SUM(swaps) AS swaps,
  SUM(wallets) AS wallets
FROM
  full_volume
GROUP BY
  1
ORDER BY
  volume DESC;