# Retail analytics pipeline: dbt + Snowflake

An end-to-end analytics engineering project built on point-of-sale (POS) exports from a family-run dry fruits and festival gift box retailer. Sales run through a POS system whose only analysis option was exporting messy CSV reports. This project turns those exports into clean, tested tables that answer business questions such as monthly sales, the festival-season spike, category mix, gift boxes vs loose products, and payment mix.

**Stack:** Snowflake (warehouse) · dbt platform (Fusion engine) · GitHub (version control, pull requests)

> **Data privacy:** this repository contains code only. Source data, business figures and customer details are kept private. Customer names, phone numbers, addresses and tax IDs are dropped in the staging layer.

---

## Architecture

```
POS exports (CSV)
        │  loaded as-is
        ▼
Bronze ── RAW.SALES_INVOICES, RAW.SALES_ITEMS        (dbt sources)
        │  rename, cast types, drop PII
        ▼
Silver ── stg_sales_invoices, stg_sales_items         (views)
        │  join, deduplicate, standardize, model
        ▼
Gold ──── dim_products, dim_customers,
          fact_invoices, fact_sales_lines             (tables, star schema)
```

<!-- Add a lineage screenshot from dbt Catalog here (model names only, no data) -->
<!-- ![Lineage](docs/lineage.png) -->

| Layer | Model | Grain | What it does |
|---|---|---|---|
| Bronze | `raw.sales_invoices` | one row per bill | bill-level POS export, loaded as-is |
| Bronze | `raw.sales_items` | one row per product line | line-level POS export, loaded as-is |
| Silver | `stg_sales_invoices` | one row per bill | snake_case names, typed amounts, PII removed, walk-in flag |
| Silver | `stg_sales_items` | one row per product line | typed quantities and prices, 12-hour time parsed, line numbers added |
| Gold | `dim_products` | one row per product | standardized categories, latest price, gift box flag |
| Gold | `dim_customers` | one row per customer | Walk-in / B2B / Named retail, first and last purchase |
| Gold | `fact_invoices` | one row per bill | totals, tax, payment split, line counts |
| Gold | `fact_sales_lines` | one row per product line | quantity, price, discount, tax, line total |

---

## Data quality issues I found and how I handled them

| Issue in the source | Why it matters | Fix |
|---|---|---|
| Bill numbers repeat: retail bills and B2B invoices use separate numbering | Joining or counting on bill number alone silently mixes up different bills | Use the POS `invoice_id` as the key; join items to bills on `voucher_type + voucher_number`, tested unique |
| Line export has no line ID, and the same product can appear twice on one bill | No natural primary key for sales lines | `row_number()` per bill creates `line_number` |
| Blank values in numeric columns broke the warehouse load | A single blank fails a numeric cast | Cast in staging with `try_to_number`, so blanks become NULL instead of errors |
| Inconsistent product categories (`Snack` vs `Snacks`, nested category paths, nulls) | Category reports split the same products | Explicit mapping in `dim_products`; nulls become `Uncategorized` |
| Prices change over time for over half of products | Which price is "the" price? | `dim_products` keeps the latest; facts keep the price actually charged |
| B2B invoices leave net/subtotal/paid blank | Revenue undercounted if those columns are used | `total_amount` / `line_total` are the revenue measures |

## Tests

`dbt build` runs 15 tests on every build:
- **Keys:** `unique` + `not_null` on every primary key
- **Referential integrity:** every fact row points to an existing product, customer and bill (`relationships`)
- **Accepted values:** voucher types and customer types
- **Reconciliation:** `tests/assert_gold_totals_match_raw.sql` checks that gold-layer sales totals match the raw source totals within 1 unit, so no rows are lost or duplicated in transformation. Gold totals were also verified once against the POS system's own report.

## Known limitations

- **No margin analysis:** purchase cost is rarely recorded in the POS.
- **No employee dimension:** a single salesperson and counter, so a staff dimension would add nothing.
- **Customer analysis is limited:** almost all bills are walk-in customers sharing one POS ID. Repeat-customer metrics only cover named and B2B customers.
- **Different date ranges:** line-level detail covers a shorter period than bill-level data. `fact_invoices.has_line_detail` flags which bills have line items.

## What's next

- Dashboard on the gold tables (monthly trend, festival spike, category mix)
- Add the store's gift box web app order log as a second source
- Festival-season sales forecast