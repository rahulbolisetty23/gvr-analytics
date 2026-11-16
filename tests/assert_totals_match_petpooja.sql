-- Fails (returns a row) if loaded totals drift from PetPooja's own report totals
select 'items' as check_name, sum(line_total) as loaded_total, 15994618.44 as report_total
from {{ ref('fact_sales_lines') }}
having abs(sum(line_total) - 15994618.44) > 1

union all

select 'invoices', sum(total_amount), 18041999.98
from {{ ref('fact_invoices') }}
having abs(sum(total_amount) - 18041999.98) > 1