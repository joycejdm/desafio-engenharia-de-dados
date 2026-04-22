select 
    business_username as account_name, 
    'TikTok' as platform,
    item_id as post_id,
    cast(to_timestamp(create_time) as date) as post_date,
    'VIDEO' as content_format,
    coalesce(likes, 0) as likes,
    coalesce(comments, 0) as comments,
    coalesce(shares, 0) as shares,
    coalesce(reach, 0) as reach
from {{ source('raw', 'raw_tiktok_posts') }}