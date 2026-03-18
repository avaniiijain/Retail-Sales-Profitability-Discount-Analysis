-- Q4: HOW TO OPTIMISE DISCOUNT DEPTH TO MAXIMISE MARGIN

-- Business context:
--   Given that discounting is causing losses, what is the
--   maximum safe discount level — and what is the financial
--   impact of enforcing a cap?
--
-- Finding:
--   No Discount orders produce a 29.5% margin.
--   Mid discount (11-30%) drops margin to 9.1% but stays positive.
--   High discount (31-50%) produces -24.8% margin — 91.6% loss rate.
--   Extreme discount (>50%) produces -119.2% margin — 100% loss rate.
--   Every single Extreme discount order in 4 years was a loss.
--
-- Headline number:
--   Capping all discounts at 30% would have recovered $124,006
--   in profit over the 4-year period — turning a loss-making
--   discount strategy into a net-positive one.
--
-- Decision this enables:
--   A concrete discount policy: cap at 30% company-wide,
--   with stricter caps of 20% on Furniture sub-categories.


-- PART A: Profitability by discount tier — the core table

SELECT
    discount_bucket,
    discount_bucket_rank,
    COUNT(*)                                                          AS total_orders,
    ROUND(SUM(sales), 2)                                              AS total_revenue,
    ROUND(SUM(profit), 2)                                             AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 1)               AS margin_pct,
    ROUND(AVG(contribution_margin) * 100, 2)                          AS avg_margin_pct,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)             AS loss_orders,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                 AS loss_rate_pct,
    ROUND(SUM(revenue_impact), 2)                                     AS revenue_given_away
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY discount_bucket, discount_bucket_rank
ORDER BY discount_bucket_rank;



-- PART B: Category x discount tier profitability
-- Finds which category breaks first at each discount level

SELECT
    category,
    discount_bucket,
    discount_bucket_rank,
    COUNT(*)                                                          AS total_orders,
    ROUND(SUM(profit), 2)                                             AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 1)               AS margin_pct,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)             AS loss_orders,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                 AS loss_rate_pct
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY category, discount_bucket, discount_bucket_rank
ORDER BY category, discount_bucket_rank;



-- PART C: THE HEADLINE NUMBER
-- Simulates capping all discounts at 30%
-- Orders above 30% discount are the ones to eliminate
-- This calculates the profit impact of that policy

WITH policy_simulation AS (
    SELECT
        -- Current state
        SUM(profit)                                                     AS actual_total_profit,

        -- Profit from orders that would survive a 30% cap
        SUM(CASE WHEN percentage_discount <= 30 THEN profit ELSE 0 END) AS profit_under_cap,

        -- Profit currently destroyed by orders above 30%
        SUM(CASE WHEN percentage_discount > 30 THEN profit ELSE 0 END)  AS profit_from_over_30,

        -- Orders that would be eliminated
        SUM(CASE WHEN percentage_discount > 30 THEN 1 ELSE 0 END)       AS orders_eliminated,

        -- Revenue that would be given up
        SUM(CASE WHEN percentage_discount > 30 THEN sales ELSE 0 END)   AS revenue_lost_from_cap
    FROM SuperstoreDB.dbo.vw_superstore
)
SELECT
    ROUND(actual_total_profit, 2)                                       AS current_total_profit,
    ROUND(profit_under_cap, 2)                                          AS profit_after_30pct_cap,
    ROUND(profit_under_cap - actual_total_profit, 2)                    AS profit_recovered,
    orders_eliminated                                                   AS orders_that_would_stop,
    ROUND(revenue_lost_from_cap, 2)                                     AS revenue_sacrificed,
    ROUND(
        (profit_under_cap - actual_total_profit)
        / NULLIF(revenue_lost_from_cap, 0) * 100, 1
    )                                                                   AS profit_recovery_per_100_revenue_lost
FROM policy_simulation;



-- PART D: Recommended discount caps by category
-- Different categories have different break-even points

WITH category_tier AS (
    SELECT
        category,
        discount_bucket,
        discount_bucket_rank,
        ROUND(AVG(contribution_margin) * 100, 2)                        AS avg_margin_pct,
        ROUND(
            SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
            / COUNT(*) * 100, 1
        )                                                               AS loss_rate_pct
    FROM SuperstoreDB.dbo.vw_superstore
    GROUP BY category, discount_bucket, discount_bucket_rank
),
first_loss_tier AS (
    -- Find the first discount bucket where margin goes negative per category
    SELECT
        category,
        MIN(discount_bucket_rank)                                       AS first_loss_bucket_rank
    FROM category_tier
    WHERE avg_margin_pct < 0
    GROUP BY category
)
SELECT
    ct.category,
    ct.discount_bucket                                                  AS recommended_max_bucket,
    ct.avg_margin_pct,
    ct.loss_rate_pct,
    CASE ct.discount_bucket
        WHEN 'No Discount'     THEN 'Cap at 0% — discounting destroys all margin'
        WHEN 'Low (1-10%)'     THEN 'Cap at 10%'
        WHEN 'Mid (11-30%)'    THEN 'Cap at 30%'
        WHEN 'High (31-50%)'   THEN 'Cap at 50%'
        ELSE                        'No safe discount level found'
    END                                                                 AS recommendation
FROM category_tier ct
JOIN first_loss_tier fl
    ON ct.category = fl.category
    AND ct.discount_bucket_rank = fl.first_loss_bucket_rank - 1
ORDER BY ct.category;