WITH sentiment_stats AS (
    SELECT 
        p.account_name,
        s.platform,
        COUNT(*) FILTER (WHERE s.sentiment = 'negativo') * 1.0 / NULLIF(COUNT(*), 0) AS proporcao_negativo
    FROM mart_comments_sentiment s
    JOIN mart_posts_performance p ON s.post_id = p.post_id
    GROUP BY 1, 2
),
ranked_sentiment AS (
    SELECT 
        *, 
        RANK() OVER(PARTITION BY account_name ORDER BY proporcao_negativo DESC) as rnk
    FROM sentiment_stats
)
SELECT 
    account_name, 
    platform, 
    ROUND(CAST(proporcao_negativo AS NUMERIC), 4) AS proporcao_negativo 
FROM ranked_sentiment 
WHERE rnk = 1;