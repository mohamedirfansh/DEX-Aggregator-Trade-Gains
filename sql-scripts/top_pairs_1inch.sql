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
        '\x11111254369792b2ca5d084ab5eea397ca8fa48b', -- 1inch Exchange 2
        '\x111111125434b319222CdBf8C261674aDB56F3ae', -- 1inch v2 Aggregation Router
        '\x11111112542d85b3ef69ae05771c2dccff4faa26', -- 1inch v3 Aggregation Router
        '\x1111111254fb6c44bac0bed2854e76f90643097d', -- 1inch v4 Aggregation Router
        '\x1111111254eeb25477b68fb85ed929f73a960582'  -- 1inch v5 Aggregation Router
      )
      AND project = '1inch'
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