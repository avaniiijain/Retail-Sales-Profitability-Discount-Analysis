-- Q3: WHAT IS THE PRICE ELASTICITY OF DIFFERENT SEGMENTS?

-- Business context:
--   Not every customer type responds to discounts the same way.
--   Elastic segments increase volume when discounted — making
--   some discount spend justifiable. Inelastic segments buy
--   regardless — meaning discounts on them are pure giveaway.
--
-- Finding:
--   All three segments show identical margin collapse at High
--   and Extreme discount tiers — suggesting no segment is
--   actually buying more at deep discounts, they are simply
--   being given money away. Corporate and Home Office at
--   Extreme discount lose over $1 per dollar of revenue.
--   No discount tier across any segment improves profit —
--   only Mid discounts (11-30%) remain marginally positive.
--
-- Decision this enables:
--   Segment-specific discount caps. Corporate and Home Office
--   have higher avg order values and should be protected from
--   deep discounts entirely. Consumer mid-tier discounts
--   can be retained selectively.


-- PART A: Segment x discount bucket — core elasticity matrix
-- The main analytical output for this question

SELECT
    segment,
    discount_bucket,
    discount_bucket_rank,
    COUNT(*)                                                            AS total_orders,
    ROUND(AVG(sales), 2)                                               AS avg_order_value,
    ROUND(AVG(quantity), 2)                                            AS avg_quantity,
    ROUND(AVG(profit), 2)                                              AS avg_profit,
    ROUND(AVG(contribution_margin) * 100, 2)                           AS avg_margin_pct,
    ROUND(SUM(profit), 2)                                              AS total_profit,
    SUM(CASE WHEN profit_flag = 'Loss' THEN 1 ELSE 0 END)              AS loss_orders,
    ROUND(
        SUM(CASE WHEN profit_flag = 'Loss' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                                   AS loss_rate_pct
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY segment, discount_bucket, discount_bucket_rank
ORDER BY segment, discount_bucket_rank;


-- PART B: Volume response to discounting per segment
-- If a segment is elastic, order count should rise at
-- higher discount tiers — flat or falling means inelastic

WITH segment_baseline AS (
    -- Baseline: average order count at No Discount per segment
    SELECT
        segment,
        COUNT(*) * 1.0                                                  AS baseline_orders
    FROM SuperstoreDB.dbo.vw_superstore
    WHERE discount_bucket = 'No Discount'
    GROUP BY segment
)
SELECT
    v.segment,
    v.discount_bucket,
    v.discount_bucket_rank,
    COUNT(*)                                                            AS orders_at_tier,
    ROUND(b.baseline_orders, 0)                                         AS baseline_no_discount_orders,
    ROUND(COUNT(*) * 100.0 / b.baseline_orders, 1)                     AS volume_index
    -- volume_index > 100 = more orders than baseline (elastic)
    -- volume_index < 100 = fewer orders than baseline (inelastic)
FROM SuperstoreDB.dbo.vw_superstore v
JOIN segment_baseline b ON v.segment = b.segment
GROUP BY v.segment, v.discount_bucket, v.discount_bucket_rank, b.baseline_orders
ORDER BY v.segment, v.discount_bucket_rank;


-- PART C: High value orders by segment — are we discounting
-- our best customers unnecessarily?

SELECT
    segment,
    CASE WHEN is_promoted = 1 THEN 'Discounted' ELSE 'Full Price' END  AS order_type,
    COUNT(*)                                                            AS total_orders,
    ROUND(AVG(unit_price), 2)                                          AS avg_unit_price,
    ROUND(AVG(sales), 2)                                               AS avg_order_value,
    ROUND(AVG(profit), 2)                                              AS avg_profit,
    ROUND(AVG(contribution_margin) * 100, 2)                           AS avg_margin_pct,
    ROUND(SUM(revenue_impact), 2)                                      AS total_revenue_given_away
FROM SuperstoreDB.dbo.vw_superstore
GROUP BY segment, is_promoted
ORDER BY segment, is_promoted DESC;


-- ------------------------------------------------------------
-- PART D: Segment profitability ranking at each discount tier
-- Window function — ranks segments by profit within each tier
-- ------------------------------------------------------------
WITH segment_tier AS (
    SELECT
        segment,
        discount_bucket,
        discount_bucket_rank,
        ROUND(SUM(profit), 2)                                           AS total_profit,
        ROUND(AVG(contribution_margin) * 100, 2)                        AS avg_margin_pct
    FROM SuperstoreDB.dbo.vw_superstore
    GROUP BY segment, discount_bucket, discount_bucket_rank
)
SELECT
    segment,
    discount_bucket,
    total_profit,
    avg_margin_pct,
    RANK() OVER (
        PARTITION BY discount_bucket
        ORDER BY total_profit DESC
    )                                                                   AS profit_rank_within_tier
FROM segment_tier
ORDER BY discount_bucket_rank, profit_rank_within_tier;