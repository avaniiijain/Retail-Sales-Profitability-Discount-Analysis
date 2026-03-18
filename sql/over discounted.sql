-- Q2: WHICH PRODUCT CATEGORIES ARE OVER-DISCOUNTED?

-- Business context:
--   Not all discounting is equal. Some sub-categories absorb
--   discounts without destroying margin. Others collapse into
--   losses the moment a discount is applied.
--
-- Finding:
--   Tables (63.6% loss rate) and Bookcases (47.8% loss rate)
--   are being discounted into guaranteed losses.
--   Binders receive the highest average discount (37.2%) of any
--   sub-category and generate $128K in revenue given away.
--   Technology sub-categories discount less and stay profitable.
--
-- Decision this enables:
--   Immediate discount caps on Tables, Bookcases, and Binders.
--   These three sub-categories account for the majority of
--   profit destruction in the portfolio.


-- PART A: Sub-category discount and profitability scorecard
-- The core diagnostic — ranked by worst profit first

SELECT
    category,
    sub_category,
    COUNT(*)                                                          AS total_orders,
    ROUND(AVG(percentage_discount), 1)                                AS avg_discount_pct,
    ROUND(SUM(sales), 2)                                              AS total_revenue,
    ROUND(SUM(profit), 2)                                             AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 1)               AS margin_pct,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)             AS loss_orders,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                   AS loss_rate_pct,
    ROUND(SUM(revenue_impact), 2)                                      AS total_revenue_given_away
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY category, sub_category
ORDER BY total_profit ASC;


-- PART B: Discount depth distribution per sub-category
-- Shows HOW discounts are being applied, not just the average

SELECT
    category,
    sub_category,
    discount_bucket,
    COUNT(*)                                                           AS orders,
    ROUND(SUM(sales), 2)                                               AS revenue,
    ROUND(SUM(profit), 2)                                              AS profit,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)              AS loss_orders
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY category, sub_category, discount_bucket, discount_bucket_rank
ORDER BY category, sub_category, discount_bucket_rank;


-- PART C: Over-discounting threshold breach
-- Flags every sub-category where avg discount exceeds 20%
-- AND loss rate exceeds 30% — the danger zone

WITH sub_summary AS (
    SELECT
        category,
        sub_category,
        COUNT(*)                                                        AS total_orders,
        ROUND(AVG(percentage_discount), 1)                              AS avg_discount_pct,
        ROUND(SUM(profit), 2)                                           AS total_profit,
        ROUND(
            SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
            / COUNT(*) * 100, 1
        )                                                               AS loss_rate_pct,
        ROUND(SUM(revenue_impact), 2)                                   AS revenue_given_away
    FROM SuperstoreDB.dbo.vw_superstore
    GROUP BY category, sub_category
)
SELECT
    category,
    sub_category,
    total_orders,
    avg_discount_pct,
    total_profit,
    loss_rate_pct,
    revenue_given_away,
    'OVER-DISCOUNTED'                                                   AS flag
FROM sub_summary
WHERE avg_discount_pct > 20
  AND loss_rate_pct    > 30
ORDER BY total_profit ASC;


-- PART D: Revenue given away vs profit earned per category
-- The trade-off summary for executive presentation

SELECT
    category,
    ROUND(SUM(revenue_impact), 2)                                      AS total_revenue_given_away,
    ROUND(SUM(profit), 2)                                              AS total_profit_earned,
    ROUND(SUM(profit) / NULLIF(SUM(revenue_impact), 0), 2)             AS profit_per_dollar_discounted
FROM SuperstoreDB.dbo.vw_superstore
WHERE is_promoted = 1
GROUP BY category
ORDER BY profit_per_dollar_discounted ASC;