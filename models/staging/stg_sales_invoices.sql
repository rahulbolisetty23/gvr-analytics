with source as (
    select * from {{ source('raw', 'sales_invoices') }}
),

renamed as (
    select
        -- keys
        id                                  as invoice_id,       -- unique per bill
        vouchernumber::varchar              as voucher_number,
        partyid::varchar                    as customer_id,
        partyname = 'Walk-in Customer'      as is_walk_in_customer,

        -- dates
        date                                as invoice_date,

        -- bill attributes
        vouchertype                         as voucher_type,     -- retailInvoice / invoice (B2B)
        status                              as invoice_status,
        paymentstatus                       as payment_status,
        paymentmode                         as payment_mode,
        salesby                             as sales_person,
        gsttreatment                        as gst_treatment,
        isinclusivetax                      as is_tax_inclusive,

        -- amounts already loaded as NUMBER
        taxableamount                       as taxable_amount,
        cgst                                as cgst_amount,
        sgst                                as sgst_amount,
        igst                                as igst_amount,
        taxtotal                            as tax_amount,
        total                               as total_amount,     -- main revenue column (filled on every bill)
        adjustment                          as adjustment_amount,
        discountamount                      as discount_amount,

        -- payment split (already NUMBER)
        cash                                as paid_cash,
        upi                                 as paid_upi,
        card                                as paid_card,
        due                                 as amount_due,

        -- amounts loaded as VARCHAR (blank on the 75 B2B invoices)
        try_to_number(netamount, 12, 2)     as net_amount,
        try_to_number(subtotal, 12, 2)      as subtotal_amount,
        try_to_number(paid, 12, 2)          as paid_amount,
        try_to_number(itemdiscount, 12, 2)  as item_discount_amount,
        try_to_number(orderdiscount, 12, 2) as order_discount_amount,
        try_to_number(extracharges, 12, 2)  as extra_charges_amount,
        try_to_number(creditamount, 12, 2)  as credit_amount

        -- dropped on purpose:
        --   PII: partyname, partycontact, partygstnumber, partycode
        --   low value: referencenumber, placeofsupply, payment_remarks,
        --              loyalty* (all zero), taxable/nontaxable/discount (duplicates of the amounts above)
    from source
)

select * from renamed