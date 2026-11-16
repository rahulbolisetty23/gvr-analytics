with invoices as (
    select * from {{ ref('stg_sales_invoices') }}
),

line_counts as (
    select
        invoice_id,
        count(*)      as line_count,
        sum(quantity) as total_quantity
    from {{ ref('fact_sales_lines') }}
    group by invoice_id
)

select
    i.invoice_id,
    i.voucher_type,
    i.voucher_number,
    i.customer_id,
    i.invoice_date,
    i.payment_mode,
    i.payment_status,
    i.taxable_amount,
    i.tax_amount,
    i.discount_amount,
    i.total_amount,
    i.paid_cash,
    i.paid_upi,
    i.paid_card,
    i.amount_due,
    lc.line_count,
    lc.total_quantity,
    lc.invoice_id is not null as has_line_detail  -- item file only covers Jan–Oct 23, 2026
from invoices i
left join line_counts lc
    on i.invoice_id = lc.invoice_id