{{ config(materialized='table') }}

select 
    social_media as platform,
    post_id,
    predicted_sentiment as sentiment
from {{ source('raw', 'raw_instagram_comments') }}

union all

select 
    social_media as platform,
    post_id,
    predicted_sentiment as sentiment
from {{ source('raw', 'raw_tiktok_comments') }}