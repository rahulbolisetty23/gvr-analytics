with lines as (
    select * from {{ ref('stg_sales_items') }}
),

latest as (   -- most recent sale of each item, for current price/unit
    select *
    from lines
    qualify row_number() over (
        partition by item_name order by invoice_date desc, invoice_time desc
    ) = 1
),

stats as (
    select
        item_name,
        max(category_name)  as category_raw,
        max(group_name)     as group_raw,
        min(invoice_date)   as first_sold_date,
        max(invoice_date)   as last_sold_date
    from lines
    group by item_name
),

cleaned as (
    select
        md5(s.item_name)    as product_id,
        s.item_name,
        case
            when s.category_raw is null                                   then 'Uncategorized'
            when s.category_raw = 'Snack'                                 then 'Snacks'
            when s.category_raw = 'Dried Fruits'                          then 'Dry Fruits'
            when s.category_raw = 'Dry Fruits,Dry Fruits>Cashews'         then 'Cashew'
            when s.category_raw = 'Dry Fruits,Dry Fruits>Almond'          then 'Almond'
            when s.category_raw = 'Dry Fruits,Dry Fruits>Kishmish (Raisins)' then 'Kishmish'
            when s.category_raw = 'Dry Fruits,Dry Fruits>Brazil Nuts'     then 'Premium Nuts'
            else s.category_raw
        end                 as category_name,
        coalesce(s.group_raw, 'Ungrouped') as group_name,
        l.barcode,
        l.hsn_code,
        l.item_unit         as current_unit,
        l.unit_price        as current_price,
        s.first_sold_date,
        s.last_sold_date
    from stats s
    join latest l on s.item_name = l.item_name
)

select
    *,
    category_name = 'Gift Box' as is_gift_box
from cleaned