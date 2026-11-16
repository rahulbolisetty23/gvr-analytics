with invoices as (
    select * from {{ ref('stg_sales_invoices') }}
),

customers as (
    select
        customer_id,
        boolor_agg(is_walk_in_customer)       as is_walk_in,
        boolor_agg(voucher_type = 'invoice')  as has_b2b_invoice,
        min(invoice_date)                     as first_purchase_date,
        max(invoice_date)                     as last_purchase_date,
        count(*)                              as lifetime_bills,
        sum(total_amount)                     as lifetime_revenue
    from invoices
    group by customer_id
)

select
    *,
    case
        when is_walk_in      then 'Walk-in'
        when has_b2b_invoice then 'B2B'
        else 'Named retail'
    end as customer_type
from customers