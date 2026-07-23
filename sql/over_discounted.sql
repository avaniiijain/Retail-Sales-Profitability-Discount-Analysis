-- Q2: WHICH PRODUCT CATEGORIES ARE OVER-DISCOUNTED?

-- Business Context:
-- Not all products respond to discounting in the same way.
-- This analysis drills deeper into each
-- category to determine which sub-categories are responsible for
-- profit erosion, how profitability changes across discount depths,
-- which products meet predefined pricing-risk criteria, and finally
-- summarizes promotional performance back at the category level.

-- Key Finding:
-- Tables, Machines, Bookcases, Binders, and Appliances
-- generated the largest discounted losses, while profitability
-- consistently deteriorated as discount depth increased.
-- Technology remained the only category that was profitable
-- overall under discounted sales.

-- Decision this enables:
-- Replace uniform promotional pricing with category- and
-- sub-category-specific discount strategies, prioritizing
-- pricing reviews for the highest-risk product groups while
-- preserving promotional flexibility for products that remain
-- consistently profitable.


-- PART A: Discounted Sub-Category Profitability Scorecard
-- Identifies discounted sub-categories with the weakest
-- financial performance based on profit, margin, and loss rate.

SELECT
    category,
    sub_category,
    COUNT(*)                                                          AS sales_records,
    ROUND(AVG(percentage_discount), 1)                                AS avg_discount_pct,
    ROUND(SUM(sales), 2)                                              AS total_revenue,
    ROUND(SUM(profit), 2)                                             AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 1)               AS profit_margin_pct,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                 AS loss_rate_pct
FROM SuperstoreDB.dbo.vw_superstore
WHERE is_promoted = 1
GROUP BY category, sub_category
ORDER BY total_profit ASC;


-- PART B: Profitability by Discount Depth
-- Compares profitability across discount levels,
-- using full-price sales as the performance baseline.

SELECT
    category,
    sub_category,
    discount_bucket,
    COUNT(*)                                                           AS sales_records,
    ROUND(SUM(sales), 2)                                               AS total_revenue,
    ROUND(SUM(profit), 2)                                              AS total_profit,
    ROUND(
        SUM(profit)
        / NULLIF(SUM(sales),0) *100, 2)                                AS profit_margin_pct,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100,2)                                            AS loss_rate_pct

FROM SuperstoreDB.dbo.vw_superstore
GROUP BY category, sub_category, discount_bucket, discount_bucket_rank
ORDER BY category, sub_category, discount_bucket_rank;


-- PART C: Which sub-categories meet defined risk criteria and should be prioritized for review?
-- Identifies discounted sub-categories that combine deep average
-- discounts with frequent loss-making sales.
--
-- Screening criteria:
--   Average discount > 20%
--   Loss rate > 30%
--   At least 30 discounted sales records

WITH sub_summary AS (
  SELECT
        category,
        sub_category,
        COUNT(*)                                                        AS sales_records,
        ROUND(AVG(percentage_discount), 1)                              AS avg_discount_pct,
        SUM(sales)                                                      AS total_revenue,
        ROUND(SUM(profit), 2)                                           AS total_profit,
        ROUND(SUM(profit)
            / NULLIF(SUM(sales), 0) * 100,2)                            AS profit_margin_pct,
        ROUND(
            SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
            / COUNT(*) * 100, 1
        )                                                               AS loss_rate_pct
    FROM SuperstoreDB.dbo.vw_superstore
    WHERE is_promoted = 1
    GROUP BY category, sub_category
)
SELECT
    category,
    sub_category,
    sales_records,
    avg_discount_pct,
    total_profit,
    profit_margin_pct,
    loss_rate_pct,
    'HIGH DISCOUNT RISK'                                                   AS pricing_review_flag
FROM sub_summary
WHERE avg_discount_pct > 20
  AND loss_rate_pct > 30
  AND sales_records >= 30
ORDER BY total_profit ASC;


-- PART D: Category-Level Discount Efficiency
-- Summarizes the financial return associated with the estimated
-- value of discounts provided within each product category.

WITH category_summary AS(
    SELECT
    category,
    ROUND(SUM(sales),2)                                                AS discounted_revenue,
    ROUND(SUM(profit), 2)                                              AS discounted_sales_profit,
    ROUND(SUM(revenue_impact), 2)                                      AS estimated_discount_value
FROM SuperstoreDB.dbo.vw_superstore
WHERE is_promoted = 1
GROUP BY category
)

SELECT
    category,
    estimated_discount_value,
    discounted_sales_profit,
    ROUND(discounted_sales_profit
        / NULLIF(discounted_revenue, 0) * 100, 2)                      AS discounted_profit_margin_pct,
    ROUND(discounted_sales_profit
        / NULLIF(estimated_discount_value, 0), 2)                      AS profit_per_estimated_discount_dollar

FROM category_summary
ORDER BY profit_per_estimated_discount_dollar ASC;