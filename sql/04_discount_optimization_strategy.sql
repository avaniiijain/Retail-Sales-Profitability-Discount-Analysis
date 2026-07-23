-- Q4: WHAT DISCOUNT STRATEGY MAXIMIZES PROFITABILTY WHILE PROTECTING MARGINS?

-- Business context:
-- Questions 1–3 established that promotional losses are concentrated within a 
-- small group of high-risk sub-categories rather than specific customer segments. 
-- The next step is to translate these findings into an actionable pricing strategy 
-- by defining discount limits for high-risk products, evaluating their portfolio-wide impact, 
-- and estimating the financial outcomes under different business scenarios.


-- Finding:
-- A single company-wide discount cap is not optimal for every category.
-- Furniture requires tailored sub-category caps, while Office Supplies and
-- Technology can be managed effectively under a uniform 30% cap.


-- Headline number:
-- For Furniture, tailored caps increase the simulated profit margin from
-- 2.49% to 15.81%, compared with only 5.81% under the uniform 30% policy,
-- while reducing the simulated loss rate to 10.99%.


-- Decision this enables:
-- Adopt a hybrid discount strategy: apply tailored caps to high-risk
-- Furniture sub-categories and use a uniform 30% maximum discount for
-- Office Supplies and Technology.


-- PART A: Establish discount caps for high-risk sub-categories (Already identified in Q2)

-- High-risk criteria:
--   1. Average promoted discount > 20%
--   2. Loss rate on promoted sales > 30%
--   3. At least 30 promoted sales records

-- Cap methodology:
--   1. Find the first promoted discount bucket with negative profit.
--   2. Find the last profitable bucket before that point.
--   3. If no promoted bucket before that point is profitable, fall back to No Discount.
--   4. Return all performance metrics for the selected cap bucket.


CREATE OR ALTER VIEW dbo.vw_high_risk_discount_caps
AS 

WITH high_risk_subcategories AS
(
    SELECT
        category,
        sub_category

    FROM dbo.vw_superstore

    WHERE is_promoted = 1

    GROUP BY category, sub_category

    HAVING
        AVG(percentage_discount) > 20
        AND
        SUM(
            CASE
                WHEN profit_flag = 'Loss' THEN 1.0
                ELSE 0.0
            END
        ) * 100.0
        / NULLIF(COUNT(*), 0) > 30
        AND 
        COUNT(*) >= 30
),

discount_bucket_summary AS
(
    SELECT
        s.category,
        s.sub_category,
        s.discount_bucket,
        s.discount_bucket_rank,
        s.is_promoted,

        COUNT(*)                                                AS sales_records,
        AVG(s.percentage_discount)                              AS avg_discount_pct,
        SUM(s.sales)                                            AS total_revenue,
        SUM(s.profit)                                           AS total_profit,
        SUM(s.profit) * 100.0
        / NULLIF(SUM(s.sales), 0)                               AS profit_margin_pct,

        SUM(
            CASE
                WHEN s.profit_flag = 'Loss' THEN 1.0
                ELSE 0.0 END) * 100.0
        / NULLIF(COUNT(*), 0)                                   AS loss_rate_pct

    FROM dbo.vw_superstore AS s

    INNER JOIN high_risk_subcategories AS h
        ON  s.category = h.category
        AND s.sub_category = h.sub_category

-- No is_promoted filter here because No Discount must remain available as the fallback cap.

    GROUP BY s.category, s.sub_category, s.discount_bucket, s.discount_bucket_rank, s.is_promoted
),

first_unprofitable_bucket AS
(
    SELECT
        category,
        sub_category,

        MIN(
            CASE
                WHEN is_promoted = 1
                 AND total_profit < 0
                THEN discount_bucket_rank
            END)                                                 AS first_unprofitable_rank

    FROM discount_bucket_summary
    GROUP BY category, sub_category
),

bucket_limits AS
(
    SELECT
        f.category,
        f.sub_category,
        f.first_unprofitable_rank,

        COALESCE(
            MAX(
                CASE
                    WHEN d.total_profit > 0
                     AND (
                            f.first_unprofitable_rank IS NULL
                            OR d.discount_bucket_rank < f.first_unprofitable_rank
                         )
                    THEN d.discount_bucket_rank END), 1)       AS capped_bucket_rank

    FROM first_unprofitable_bucket AS f

    LEFT JOIN discount_bucket_summary AS d
        ON  f.category = d.category
        AND f.sub_category = d.sub_category

    GROUP BY f.category, f.sub_category, f.first_unprofitable_rank
)

SELECT
    b.category,
    b.sub_category,
    bad.discount_bucket                                         AS first_unprofitable_discount_bucket,
    cap.discount_bucket                                         AS proposed_discount_cap_bucket,

    CASE cap.discount_bucket_rank
        WHEN 1 THEN 0
        WHEN 2 THEN 10
        WHEN 3 THEN 30
        WHEN 4 THEN 50
        ELSE NULL END                                           AS proposed_discount_cap_pct,

    cap.sales_records                                           AS cap_bucket_sales_records,

    ROUND(cap.avg_discount_pct, 1)                              AS cap_bucket_avg_discount_pct,
    ROUND(cap.total_revenue, 2)                                 AS cap_bucket_revenue,
    ROUND(cap.total_profit, 2)                                  AS cap_bucket_profit,
    ROUND(cap.profit_margin_pct, 2)                             AS cap_bucket_profit_margin_pct,
    ROUND(cap.loss_rate_pct, 1)                                 AS cap_bucket_loss_rate_pct

FROM bucket_limits AS b

LEFT JOIN discount_bucket_summary AS bad
    ON  b.category = bad.category
    AND b.sub_category = bad.sub_category
    AND b.first_unprofitable_rank = bad.discount_bucket_rank

LEFT JOIN discount_bucket_summary AS cap
    ON  b.category = cap.category
    AND b.sub_category = cap.sub_category
    AND b.capped_bucket_rank = cap.discount_bucket_rank

GO

SELECT *
FROM dbo.vw_high_risk_discount_caps;

GO

-- PART B: How would the overall promotional portfolio perform if the proposed discount caps were enforced for all high-risk sub-categories?

-- Assumptions:
-- 1. The same transactions and quantities sold are retained after repricing.
-- 2. Product cost remains unchanged.
-- 3. Discounts above each high-risk sub-category's proposed cap are reduced to that cap.
-- 4. Transactions already within their applicable cap remain unchanged.
-- 5. Non-high-risk sub-categories remain unchanged.

CREATE OR ALTER VIEW dbo.vw_tailored_discount_policy
AS

WITH simulated_sales AS
(
    SELECT
        s.category,
        s.sub_category,
        s.sales,
        s.profit,
        s.percentage_discount,
        p.proposed_discount_cap_pct,

        CASE
            WHEN p.proposed_discount_cap_pct IS NOT NULL
             AND s.percentage_discount > p.proposed_discount_cap_pct
            THEN p.proposed_discount_cap_pct
            ELSE s.percentage_discount END                              AS simulated_discount_pct,

        CASE
            WHEN p.proposed_discount_cap_pct IS NOT NULL
             AND s.percentage_discount > p.proposed_discount_cap_pct
            THEN 1
            ELSE 0 END                                                  AS repriced_record_flag,

        s.sales
        / NULLIF(
            1.0 - s.percentage_discount / 100.0, 0)                     AS estimated_full_price_revenue,

        s.sales - s.profit                                              AS estimated_cost

    FROM dbo.vw_superstore AS s

    LEFT JOIN dbo.vw_high_risk_discount_caps AS p
        ON  s.category = p.category
        AND s.sub_category = p.sub_category
),

recalculated_sales AS
(
    SELECT
        category,
        sub_category,
        sales                                                           AS current_revenue,
        profit                                                          AS current_profit,
        percentage_discount                                             AS current_discount_pct,
        proposed_discount_cap_pct,
        simulated_discount_pct,
        repriced_record_flag,
        estimated_cost,

        CASE
            WHEN repriced_record_flag = 1
            THEN
                estimated_full_price_revenue * ( 1.0 - simulated_discount_pct / 100.0)
            ELSE sales
        END                                                             AS simulated_revenue

    FROM simulated_sales
),

category_summary AS
(
    SELECT
        category,
        COUNT(*)                                                        AS total_sales_records,

        SUM(repriced_record_flag)                                       AS repriced_sales_records,
        SUM(current_revenue)                                            AS current_total_revenue,
        SUM(current_profit)                                             AS current_total_profit,
        AVG(current_discount_pct)                                       AS current_avg_discount_pct,

        SUM(
            CASE
                WHEN current_profit < 0 THEN 1.0
                ELSE 0.0 END) * 100.0
        / NULLIF(COUNT(*), 0)                                           AS current_loss_rate_pct,

        SUM(simulated_revenue)                                          AS proposed_total_revenue,

        SUM(simulated_revenue - estimated_cost)                         AS proposed_total_profit,

        AVG(simulated_discount_pct)                                     AS proposed_avg_discount_pct,

        SUM(
            CASE
                WHEN simulated_revenue - estimated_cost < 0
                THEN 1.0
                ELSE 0.0 END) * 100.0
        / NULLIF(COUNT(*), 0)                                           AS proposed_loss_rate_pct

    FROM recalculated_sales
    GROUP BY category
)

SELECT
    category,
    -- total_sales_records, 
    -- repriced_sales_records,

    CAST(ROUND(
        repriced_sales_records * 100.0
        / NULLIF(total_sales_records, 0), 2) AS DECIMAL(10,2))             AS repriced_records_pct,

    -- ROUND(current_total_revenue, 2)                                     AS current_total_revenue,
    -- ROUND(proposed_total_revenue, 2)                                    AS proposed_total_revenue,
    -- ROUND(proposed_total_revenue - current_total_revenue, 2)            AS revenue_change,

    CAST(ROUND(
        (proposed_total_revenue - current_total_revenue) * 100.0
        / NULLIF(current_total_revenue, 0),2) AS DECIMAL(10,2))            AS revenue_change_pct,

    -- ROUND(current_total_profit, 2)                                      AS current_total_profit,
    -- ROUND(proposed_total_profit, 2)                                     AS proposed_total_profit,
    -- ROUND(proposed_total_profit - current_total_profit, 2)              AS profit_change,

    CAST(ROUND(
        (proposed_total_profit - current_total_profit) * 100.0
        / NULLIF(ABS(current_total_profit), 0), 2) AS DECIMAL(10,2))       AS profit_change_pct,

    CAST(ROUND(current_total_profit * 100.0
        / NULLIF(current_total_revenue, 0), 2) AS DECIMAL(10,2))           AS current_profit_margin_pct,

    CAST(ROUND(proposed_total_profit * 100.0
        / NULLIF(proposed_total_revenue, 0), 2)AS DECIMAL(10,2))           AS proposed_profit_margin_pct,

    CAST(ROUND(current_avg_discount_pct, 2) AS DECIMAL(10,2))              AS current_avg_discount_pct,

    CAST(ROUND(proposed_avg_discount_pct, 2) AS DECIMAL(10,2))             AS proposed_avg_discount_pct,

    CAST(ROUND(current_loss_rate_pct, 2) AS DECIMAL(10,2))                 AS current_loss_rate_pct,

    CAST(ROUND(proposed_loss_rate_pct, 2) AS DECIMAL(10,2))                AS proposed_loss_rate_pct

FROM category_summary;

GO

SELECT *
FROM dbo.vw_tailored_discount_policy
ORDER BY category;

GO 
-- PART C: Evaluate category-level performance under a uniform company-wide 30% discount policy.

-- Assumptions:
-- 1. The number of orders and quantity sold remain unchanged.
-- 2. Estimated product cost per transaction remains unchanged.
-- 3. Every transaction with a historical discount above 30% is repriced to a maximum discount of 30%.
-- 4. Transactions already discounted at 30% or less remain unchanged.
-- 5. Historical full-price revenue is estimated from the observed sales value and discount percentage.

CREATE OR ALTER VIEW dbo.vw_uniform_discount_policy
AS

WITH simulated_sales AS
(
    SELECT
        s.category,
        s.sub_category,
        s.sales,
        s.profit,
        s.percentage_discount,

        CASE
            WHEN s.percentage_discount > 30
            THEN 30
            ELSE s.percentage_discount END                                  AS simulated_discount_pct,

        CASE
            WHEN s.percentage_discount > 30
            THEN 1
            ELSE 0 END                                                      AS repriced_record_flag,

        s.sales
            / NULLIF(
                1.0 - s.percentage_discount / 100.0, 0)                     AS estimated_full_price_revenue,

        s.sales - s.profit                                                  AS estimated_cost

    FROM dbo.vw_superstore AS s
),

recalculated_sales AS
(
    SELECT
        category,
        sub_category,

        sales                                                               AS current_revenue,
        profit                                                              AS current_profit,
        percentage_discount                                                 AS current_discount_pct,
        simulated_discount_pct,
        repriced_record_flag,
        estimated_cost,

        CASE
            WHEN repriced_record_flag = 1
            THEN
                estimated_full_price_revenue
                * (1.0 - simulated_discount_pct / 100.0)
            ELSE sales END                                                  AS simulated_revenue

    FROM simulated_sales
),

category_summary AS
(
    SELECT
        category,
        COUNT(*)                                                            AS total_sales_records,
        SUM(repriced_record_flag)                                           AS repriced_sales_records,
        SUM(current_revenue)                                                AS current_total_revenue,
        SUM(current_profit)                                                 AS current_total_profit,
        AVG(current_discount_pct)                                           AS current_avg_discount_pct,
        
        SUM(
            CASE
                WHEN current_profit < 0 THEN 1.0
                ELSE 0.0 END ) * 100.0
        / NULLIF(COUNT(*),0)                                                AS current_loss_rate_pct,

        SUM(simulated_revenue)                                              AS proposed_total_revenue,
        SUM(simulated_revenue - estimated_cost)                             AS proposed_total_profit,
        AVG(simulated_discount_pct)                                         AS proposed_avg_discount_pct,

        SUM(
            CASE
                WHEN simulated_revenue - estimated_cost < 0
                THEN 1.0 ELSE 0.0 END) * 100.0
        / NULLIF(COUNT(*),0)                                                AS proposed_loss_rate_pct

    FROM recalculated_sales
    GROUP BY category
)

SELECT
    category,

    CAST(ROUND(
            repriced_sales_records * 100.0
            / NULLIF(total_sales_records,0), 2) AS DECIMAL(10,2))           AS repriced_records_pct,

    CAST(ROUND(
            (proposed_total_revenue - current_total_revenue) * 100.0
            / NULLIF(current_total_revenue,0), 2) AS DECIMAL(10,2))         AS revenue_change_pct,

    CAST(ROUND(
            (proposed_total_profit - current_total_profit) * 100.0
            / NULLIF(ABS(current_total_profit),0), 2) AS DECIMAL(10,2))     AS profit_change_pct,

    CAST(ROUND(current_total_profit * 100.0
            / NULLIF(current_total_revenue,0), 2) AS DECIMAL(10,2))         AS current_profit_margin_pct,

    CAST(ROUND(
            proposed_total_profit * 100.0
            / NULLIF(proposed_total_revenue,0),2) AS DECIMAL(10,2))         AS proposed_profit_margin_pct,

    CAST(ROUND(
            current_avg_discount_pct,2) AS DECIMAL(10,2))                   AS current_avg_discount_pct,

    CAST(ROUND(
            proposed_avg_discount_pct,2) AS DECIMAL(10,2))                  AS proposed_avg_discount_pct,

    CAST(ROUND(
            current_loss_rate_pct,2) AS DECIMAL(10,2))                      AS current_loss_rate_pct,

    CAST(ROUND(
            proposed_loss_rate_pct,2) AS DECIMAL(10,2))                     AS proposed_loss_rate_pct

FROM category_summary;
GO

SELECT *
FROM dbo.vw_uniform_discount_policy
ORDER BY category;


-- PART D: Which discount policy should be recommended for each category?

-- Decision rule:
-- 1. Prefer the policy with the higher profit margin and lower loss rate.
-- 2. If performance is identical or nearly identical, prefer the simpler uniform company-wide policy.


SELECT
    t.category,

    t.current_profit_margin_pct,

    t.proposed_profit_margin_pct                          AS tailored_profit_margin_pct,
    u.proposed_profit_margin_pct                          AS uniform_profit_margin_pct,

    t.proposed_loss_rate_pct                              AS tailored_loss_rate_pct,
    u.proposed_loss_rate_pct                              AS uniform_loss_rate_pct,

    t.profit_change_pct                                   AS tailored_profit_change_pct,
    u.profit_change_pct                                   AS uniform_profit_change_pct,

    t.revenue_change_pct                                  AS tailored_revenue_change_pct,
    u.revenue_change_pct                                  AS uniform_revenue_change_pct,

    t.repriced_records_pct                                AS tailored_repriced_records_pct,
    u.repriced_records_pct                                AS uniform_repriced_records_pct,

    CASE
        WHEN t.proposed_profit_margin_pct > u.proposed_profit_margin_pct
        THEN 'Tailored Sub-Category Policy'

        WHEN t.proposed_profit_margin_pct < u.proposed_profit_margin_pct
        THEN 'Uniform 30% Policy'

        ELSE 'Uniform 30% Policy'
    END                                                   AS recommended_policy,

    CASE
        WHEN t.proposed_profit_margin_pct > u.proposed_profit_margin_pct
        THEN 'Higher profit margin with lower promotional risk.'

        WHEN t.proposed_profit_margin_pct < u.proposed_profit_margin_pct
        THEN 'Higher profit margin while maintaining comparable risk.'

        ELSE 'Both policies deliver the same financial outcome; the uniform policy is simpler to implement.'
    END                                                   AS business_justification

FROM dbo.vw_tailored_discount_policy AS t

INNER JOIN dbo.vw_uniform_discount_policy AS u
    ON t.category = u.category

ORDER BY
    t.category;
