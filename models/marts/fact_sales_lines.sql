with lines as (
    select * from {{ ref('stg_sales_items') }}
),

invoices as (
    select invoice_id, voucher_type, voucher_number
    from {{ ref('stg_sales_invoices') }}
)

select
    i.invoice_id || '-' || l.line_number  as sales_line_id,
    i.invoice_id,
    l.line_number,
    md5(l.item_name)                      as product_id,
    l.customer_id,
    l.invoice_date,
    l.invoice_time,
    to_number(to_char(l.invoice_date, 'YYYYMMDD'))       as date_key,
    hour(l.invoice_time) * 100 + minute(l.invoice_time)  as time_key,
    l.voucher_type,
    l.payment_mode,
    l.quantity,
    l.unit_price,
    l.gross_amount,
    l.discount_amount,
    l.taxable_amount,
    l.tax_amount,
    l.line_total
from lines l
left join invoices i
    on  l.voucher_type   = i.voucher_type
    and l.voucher_number = i.voucher_number