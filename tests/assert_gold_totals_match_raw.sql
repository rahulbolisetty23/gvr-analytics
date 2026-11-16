-- Fails if rows were lost or duplicated between the raw sources and the gold facts
with totals as (
    select 'items' as check_name,
        (select sum(try_to_number(finaltotal::varchar, 12, 2)) from {{ source('raw', 'sales_items') }}) as raw_total,
        (select sum(line_total) from {{ ref('fact_sales_lines') }})                                     as gold_total
    union all
    select 'invoices',
        (select sum(try_to_number(total::varchar, 12, 2)) from {{ source('raw', 'sales_invoices') }}),
        (select sum(total_amount) from {{ ref('fact_invoices') }})
)

select * from totals
where abs(raw_total - gold_total) > 1