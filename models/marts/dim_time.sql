-- One row per minute of the day (1,440 rows). time_key = HHMM, e.g. 2114 = 9:14 PM
with minutes as (
    select row_number() over (order by seq4()) - 1 as minute_of_day
    from table(generator(rowcount => 1440))
)

select
    floor(minute_of_day / 60) * 100 + mod(minute_of_day, 60)       as time_key,
    time_from_parts(floor(minute_of_day / 60), mod(minute_of_day, 60), 0) as time_of_day,
    floor(minute_of_day / 60)                                       as hour_24,
    to_char(time_from_parts(floor(minute_of_day / 60), 0, 0), 'HH12 AM') as hour_label,  -- '09 PM'
    case
        when floor(minute_of_day / 60) between 5  and 11 then 'Morning'
        when floor(minute_of_day / 60) between 12 and 16 then 'Afternoon'
        when floor(minute_of_day / 60) between 17 and 20 then 'Evening'
        else 'Night'
    end                                                             as day_part
from minutes