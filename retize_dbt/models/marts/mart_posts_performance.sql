{{ config(materialized='table') }}

with instagram as (
    select * from {{ ref('stg_instagram_posts') }}
),

tiktok as (
    select * from {{ ref('stg_tiktok_posts') }}
),

unificado as (
    select * from instagram
    union all
    select * from tiktok
),

-- Remove as linhas duplicadas baseadas no post_id que vieram sujas da fonte
deduplicado as (
    select 
        *,
        row_number() over(partition by post_id order by post_date desc) as rn
    from unificado
)

select 
    account_name,
    platform,
    post_id,
    post_date,
    content_format,
    likes,
    comments,
    shares,
    reach,
    case 
        when reach = 0 then 0 
        else cast((likes + comments + shares) as float) / reach 
    end as engagement_rate
from deduplicado
where rn = 1 
  and post_date between '2025-03-01' and '2026-03-31'