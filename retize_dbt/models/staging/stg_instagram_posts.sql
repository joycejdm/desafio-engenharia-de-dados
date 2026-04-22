select 
    m.username as account_name,
    'Instagram' as platform,
    m.id as post_id,
    cast(m.timestamp as date) as post_date,
    m.media_type as content_format,
    coalesce(m.like_count, 0) as likes,
    coalesce(m.comments_count, 0) as comments,
    coalesce(i.shares, 0) as shares,
    coalesce(i.reach, 0) as reach
from {{ source('raw', 'raw_instagram_media') }} m
left join {{ source('raw', 'raw_instagram_media_insights') }} i on m.id = i.id