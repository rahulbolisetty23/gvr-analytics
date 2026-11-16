with invoices as (
    select * from {{ ref('stg_sales_invoices') }}
),

line_summary as (
    select
        invoice_id,
        count(*)           as line_count,
        sum(quantity)      as total_quantity,
        min(invoice_time)  as invoice_time,   -- all lines on a bill share the same time
        min(time_key)      as time_key
    from {{ ref('fact_sales_lines') }}
    group by invoice_id
)

select
    i.invoice_id,
    to_number(to_char(i.invoice_date, 'YYYYMMDD')) as date_key,
    ls.time_key,
    i.invoice_date,
    ls.invoice_time,
    i.voucher_type,
    i.voucher_number,
    i.customer_id,
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
    ls.line_count,
    ls.total_quantity,
    ls.invoice_id is not null as has_line_detail   -- line detail only Jan–Oct 2026
from invoices i
left join line_summary ls
    on i.invoice_id = ls.invoice_id