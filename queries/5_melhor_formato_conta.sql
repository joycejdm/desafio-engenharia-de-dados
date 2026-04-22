WITH format_perf AS (
    SELECT 
        account_name,
        content_format,
        AVG(engagement_rate) as avg_eng,
        RANK() OVER(PARTITION BY account_name ORDER BY AVG(engagement_rate) DESC) as rnk
    FROM mart_posts_performance
    GROUP BY 1, 2
)
SELECT 
    account_name, 
    content_format, 
    ROUND(CAST(avg_eng AS NUMERIC), 4) AS engajamento_medio 
FROM format_perf 
WHERE rnk = 1;