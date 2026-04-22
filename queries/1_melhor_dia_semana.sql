WITH daily_avg AS (
    SELECT 
        account_name,
        TRIM(TO_CHAR(post_date, 'Day')) AS dia_semana,
        AVG(engagement_rate) as avg_eng,
        RANK() OVER(PARTITION BY account_name ORDER BY AVG(engagement_rate) DESC) as rank_dia
    FROM mart_posts_performance
    GROUP BY 1, 2
)
SELECT 
    account_name, 
    dia_semana, 
    ROUND(CAST(avg_eng AS NUMERIC), 4) AS engajamento_medio 
FROM daily_avg 
WHERE rank_dia = 1;