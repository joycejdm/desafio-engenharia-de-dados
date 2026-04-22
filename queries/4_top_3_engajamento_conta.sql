WITH ranked_posts AS (
    SELECT 
        platform, 
        account_name, 
        post_id, 
        ROUND(CAST(engagement_rate AS NUMERIC), 4) AS engagement_rate,
        ROW_NUMBER() OVER(PARTITION BY account_name ORDER BY engagement_rate DESC) as rank_pos
    FROM mart_posts_performance
)
SELECT 
    account_name,
    platform, 
    post_id, 
    engagement_rate
FROM ranked_posts 
WHERE rank_pos <= 3;