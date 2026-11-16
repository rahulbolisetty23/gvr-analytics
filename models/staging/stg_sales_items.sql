with source as (
    select * from {{ source('raw', 'sales_items') }}
),

renamed as (
    select
        -- keys: a bill is identified by voucher_type + voucher_number
        vouchertype                                   as voucher_type,
        vouchernumber::varchar                        as voucher_number,
        row_number() over (
            partition by vouchertype, vouchernumber
            order by itemname
        )                                             as line_number,   -- no line id in source
        partyid::varchar                              as customer_id,

        -- when
        try_to_date(date::varchar)                    as invoice_date,
        coalesce(
            try_to_time("TIMESTAMP"::varchar, 'HH12:MI:SS AM'),
            try_to_time("TIMESTAMP"::varchar)
        )                                             as invoice_time,

        -- product
        itemname                                      as item_name,
        nullif(itemcode::varchar, '')                 as item_code,
        nullif(barcode::varchar, '')                  as barcode,
        categoryname                                  as category_name,
        groupname                                     as group_name,
        itemtype                                      as item_type,
        itemunit                                      as item_unit,
        nullif(hsn::varchar, '')                      as hsn_code,      -- GST product code

        -- quantities and money (all tax-inclusive per POS settings)
        try_to_number(quantity::varchar, 12, 3)       as quantity,
        try_to_number(price::varchar, 12, 2)          as unit_price,
        try_to_number(purchaseprice::varchar, 12, 2)  as unit_cost,     -- mostly 0: not reliable
        try_to_number(amount::varchar, 12, 2)         as gross_amount,
        try_to_number(discount::varchar, 12, 2)       as discount_amount,
        try_to_number(subtotal::varchar, 12, 2)       as taxable_amount,
        try_to_number(totaltax::varchar, 12, 2)       as tax_amount,
        try_to_number(finaltotal::varchar, 12, 2)     as line_total,    -- main revenue column
        try_to_number(adjustment::varchar, 12, 2)     as adjustment_amount,
        try_to_number(totaltaxrate::varchar, 5, 2)    as tax_rate_pct,
        taxtreatment                                  as tax_treatment,

        -- payment and channel
        paymentmodename                               as payment_mode,  -- UPI / Cash / Card
        paymenttype                                   as payment_type,  -- Cash / Credit (B2B)
        status                                        as invoice_status,
        countername                                   as counter_name,
        salesby                                       as sales_person

        -- dropped on purpose:
        --   PII: name, phone, address, gst, partycode
        --   empty or unused: variation, cess*, loyaltydiscount, serialnumbers,
        --     pricelistname, placeofsupply, payment_remarks, itemdescription, paymentnotes,
        --     cgst/sgst/igst split (kept the total tax instead)
    from source
)

select * from renamed