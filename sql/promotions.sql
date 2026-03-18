-- Q1: DO PROMOTIONS ACTUALLY INCREASE PROFIT OR JUST REVENUE?

-- Business context:
--   The sales team believes discounts drive growth.
--   Revenue is up — but is profit following?
--
-- Finding:
--   Promoted orders generate MORE revenue on average ($232 vs $226)
--   but produce NEGATIVE average profit (-$6.66 vs +$66.90).
--   Every single loss-making order in this dataset (1,871 orders)
--   came from a discounted transaction. Zero losses on full-price orders.
--
-- Decision this enables:
--   The discount strategy is buying revenue at the cost of profit.
--   Discounting is not growing the business — it is eroding it.


-- PART A: Overall promoted vs non-promoted comparison

SELECT
    CASE WHEN is_promoted = 1 THEN 'Discounted' ELSE 'Full Price' END  AS order_type,
    COUNT(*)                                                           AS total_orders,
    ROUND(SUM(sales), 2)                                               AS total_revenue,
    ROUND(SUM(profit), 2)                                              AS total_profit,
    ROUND(AVG(sales), 2)                                               AS avg_order_revenue,
    ROUND(AVG(profit), 2)                                              AS avg_order_profit,
    ROUND(AVG(contribution_margin) * 100, 2)                           AS avg_margin_pct,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)              AS loss_making_orders,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                   AS loss_rate_pct
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY is_promoted
ORDER BY is_promoted DESC;


-- PART B: Revenue vs profit by category — promoted vs not
-- Shows which categories are most damaged by discounting

SELECT
    category,
    CASE WHEN is_promoted = 1 THEN 'Discounted' ELSE 'Full Price' END  AS order_type,
    COUNT(*)                                                           AS total_orders,
    ROUND(SUM(sales), 2)                                               AS total_revenue,
    ROUND(SUM(profit), 2)                                              AS total_profit,
    ROUND(AVG(contribution_margin) * 100, 2)                           AS avg_margin_pct,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)              AS loss_orders
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY category, is_promoted
ORDER BY category, is_promoted DESC;


-- PART C: Revenue vs profit trend by year — promoted vs not
-- Shows whether the gap is widening or narrowing over time

SELECT
    order_year,
    CASE WHEN is_promoted = 1 THEN 'Discounted' ELSE 'Full Price' END  AS order_type,
    COUNT(*)                                                           AS total_orders,
    ROUND(SUM(sales), 2)                                               AS total_revenue,
    ROUND(SUM(profit), 2)                                              AS total_profit,
    ROUND(AVG(contribution_margin) * 100, 2)                           AS avg_margin_pct
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY order_year, is_promoted
ORDER BY order_year, is_promoted DESC;


-- PART D: The headline number
-- Total profit destroyed by discounting across all 4 years

SELECT
    ROUND(SUM(CASE WHEN is_promoted = 0 THEN profit ELSE 0 END), 2)    AS profit_full_price_orders,
    ROUND(SUM(CASE WHEN is_promoted = 1 THEN profit ELSE 0 END), 2)    AS profit_discounted_orders,
    ROUND(SUM(profit), 2)                                              AS total_profit,
    ROUND(
        SUM(CASE WHEN is_promoted = 1 THEN profit ELSE 0 END)
        / SUM(profit) * 100, 1
    )                                                                  AS discounted_share_of_profit_pct
FROM SuperstoreDB.dbo.vw_superstore;