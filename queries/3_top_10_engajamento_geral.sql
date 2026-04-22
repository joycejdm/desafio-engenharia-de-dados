SELECT 
    platform, 
    post_id, 
    account_name, 
    ROUND(CAST(engagement_rate AS NUMERIC), 4) AS engagement_rate
FROM mart_posts_performance
ORDER BY engagement_rate DESC
LIMIT 10;