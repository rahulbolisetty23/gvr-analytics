-- One row per day, Apr 1, 2025 – Mar 31, 2027 (two Indian fiscal years)
with days as (
    select dateadd(day, row_number() over (order by seq4()) - 1, '2025-04-01'::date) as date_day
    from table(generator(rowcount => 730))
),

festivals as (
    select * from {{ ref('festival_dates') }}
)

select
    to_number(to_char(d.date_day, 'YYYYMMDD'))  as date_key,     -- 20261023
    d.date_day,

    -- calendar (for parents)
    year(d.date_day)                            as calendar_year,
    quarter(d.date_day)                         as calendar_quarter,
    month(d.date_day)                           as calendar_month,
    to_char(d.date_day, 'MMMM')                 as month_name,   -- 'October'
    date_trunc('month', d.date_day)             as month_start_date,
    weekofyear(d.date_day)                      as week_of_year,
    dayname(d.date_day)                         as weekday_name, -- 'Fri'
    dayofweekiso(d.date_day)                    as weekday_number, -- Mon=1 … Sun=7
    dayofweekiso(d.date_day) in (6, 7)          as is_weekend,

    -- Indian fiscal year Apr–Mar (for the accountant)
    case when month(d.date_day) >= 4 then year(d.date_day)
         else year(d.date_day) - 1 end          as fiscal_year_start,
    'FY' || fiscal_year_start || '-' || right(to_varchar(fiscal_year_start + 1), 2)
                                                as fiscal_year,  -- 'FY2026-27'
    mod(month(d.date_day) + 8, 12) + 1          as fiscal_month_number, -- Apr=1
    ceil(fiscal_month_number / 3)               as fiscal_quarter,

    -- festivals
    f.festival_name,
    f.festival_name is not null                 as is_festival_period
from days d
left join festivals f
    on d.date_day between f.period_start and f.period_end