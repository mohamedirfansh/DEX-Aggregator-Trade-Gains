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
      block_time BETWEEN CAST('2021-01-01' AS DATE) AND CAST('2023-01-01' AS DATE)
      AND "token_a_symbol" IS NOT NULL
      AND "token_b_symbol" IS NOT NULL
    GROUP BY
      1
    ORDER BY
      volume DESC NULLS LAST
  )
SELECT
  pair,
  SUM(volume) AS volume,
  SUM(swaps) AS swaps,
  SUM(wallets) AS wallets
FROM
  full_volume
GROUP BY
  1
ORDER BY
  volume DESC;