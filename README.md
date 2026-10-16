# eCommerce Funnel Analysis (SQL)

An end-to-end funnel analysis of user behavior on an online store, written entirely in SQL. The project cleans a messy event log, measures conversion at each stage (view → cart → purchase), and identifies where the store loses the most customers.

**Tools:** SQL (SQLite), Python (one-time data loading), VS Code

---

## Business Question

Where do customers drop out of the purchase funnel, and which product categories are the worst offenders?

## Dataset

The dataset is **synthetic**. I generated it with `generate_data.py` to mimic the structure of the public [eCommerce Behavior Data](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store) dataset on Kaggle, and I added realistic data-quality problems on purpose so the cleaning step is meaningful.

- ~151,000 events from ~12,000 users, October 2019
- Columns: `event_time`, `event_type`, `product_id`, `category_id`, `category_code`, `brand`, `price`, `user_id`, `user_session`
- Event types: `view`, `cart`, `remove_from_cart`, `purchase`

Because the data is synthetic, the specific numbers below illustrate the method and should not be read as real-world benchmarks.

## Data Cleaning

The raw table (`events`) has known problems. `sql/00_data_cleaning.sql` builds a cleaned view (`events_clean`) that every later query uses.

| Problem | How I handled it |
|---|---|
| ~3,000 exact duplicate rows | `SELECT DISTINCT` |
| Inconsistent casing and whitespace in `brand` and `event_type` | `LOWER(TRIM(...))` |
| Mixed timestamp formats (`...T...Z` vs `... UTC`) | `REPLACE` to standardize |
| Zero and negative prices | Excluded with `price > 0` |
| Missing `user_id` | Excluded, since unidentified users can't be counted |
| 4 bot accounts with 2,500 views each and no purchases | Excluded (`user_id >= 900000000`) so they don't inflate top-of-funnel counts |
| Missing `brand` and `category_code` | Kept in the funnel totals; excluded only from category/brand breakdowns |

## Key Findings


### Overall funnel

| Stage | Users | Conversion from previous stage |
|---|---|---|
| View | 12,000 | n/a |
| Add to cart | 7,475 | 62.3% |
| Purchase | 3,593 | 48.1% |

- **29.9%** of viewers go on to purchase.
- **51.9%** of users who add to cart never buy. This is the biggest leak in the funnel, and it affects users who already showed strong purchase intent.

![Funnel counts](images/01_funnel_counts.png)
<img width="899" height="62" alt="Numbers" src="https://github.com/user-attachments/assets/c5ed77ca-f464-44f8-808e-f1eab7bebbe8" />


### By product category


<img width="449" height="281" alt="image" src="https://github.com/user-attachments/assets/c0b32f75-5ddf-4821-8d27-ddc39f6e074c" />


- **Worst cart-to-purchase conversion:** [category], at [x]%
- **Best cart-to-purchase conversion:** [category], at [x]%

## Recommendations

<!-- TODO: finish after the category results. Draft ideas below. -->

1. **Reduce cart abandonment:** target the [lowest-converting categories] with cart reminder emails and clearer shipping/return information at checkout.
2. **Estimate the impact:** improving cart-to-purchase conversion by 5 percentage points (48.1% → 53.1%) would add about 374 buyers, roughly a 10% increase in purchases, without needing any additional traffic.
3. **Protect data quality:** add event validation at the source to prevent duplicates, missing user IDs, and bad prices.

## Project Structure

```
funnel-analysis/
├── README.md
├── generate_data.py        # creates the synthetic dataset
├── load_data.py            # loads the CSV into SQLite (run once)
├── data/
│   └── events.csv          # raw data (funnel.db is generated, not committed)
├── sql/
│   ├── 00_data_cleaning.sql
│   ├── 01_funnel_counts.sql
│   ├── 02_conversion_rates.sql
│   └── 03_by_category.sql
└── images/                 # screenshots used in this README
```

## How to Run

1. Clone the repo and open it in VS Code.
2. Install pandas: `pip install pandas`
3. Load the data into a database (creates `data/funnel.db`):
   ```bash
   python load_data.py
   ```
4. Install the **SQLite** extension (by alexcvzz) in VS Code, then press `Ctrl + Shift + P` → **SQLite: Open Database** → choose `data/funnel.db`.
5. Run the SQL files in order, starting with `00_data_cleaning.sql`. Each later file reads from the cleaned view.

To regenerate the dataset from scratch, run `python generate_data.py`.

## Skills Demonstrated

- Data cleaning and validation in SQL
- CTEs, conditional aggregation (`CASE WHEN` inside `COUNT(DISTINCT ...)`), and safe division with `NULLIF`
- Funnel and conversion-rate analysis
- Turning query results into business recommendations

## Next Steps

- Conversion by brand and price range
- Conversion by hour of day and day of week
- Time between first view and purchase
- A Tableau dashboard built from the query results
