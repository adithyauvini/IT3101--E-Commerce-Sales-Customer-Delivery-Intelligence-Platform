# Olist E-Commerce Data Source Inventory

This document records the structure and basic data-quality characteristics of the original Olist CSV source files. The raw files are preserved without modification.

## Source Files

| File | Rows | Columns | Missing Values | Columns With Missing Values | Complete Duplicate Rows |
|---|---:|---:|---:|---:|---:|
| `olist_customers_dataset.csv` | 99,441 | 5 | 0 | 0 | 0 |
| `olist_geolocation_dataset.csv` | 1,000,163 | 5 | 0 | 0 | 261,831 |
| `olist_order_items_dataset.csv` | 112,650 | 7 | 0 | 0 | 0 |
| `olist_order_payments_dataset.csv` | 103,886 | 5 | 0 | 0 | 0 |
| `olist_order_reviews_dataset.csv` | 99,224 | 7 | 145,903 | 2 | 0 |
| `olist_orders_dataset.csv` | 99,441 | 8 | 4,908 | 3 | 0 |
| `olist_products_dataset.csv` | 32,951 | 9 | 2,448 | 8 | 0 |
| `olist_sellers_dataset.csv` | 3,095 | 4 | 0 | 0 | 0 |
| `product_category_name_translation.csv` | 71 | 2 | 0 | 0 | 0 |

## Column Details


### `olist_customers_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `customer_id` | `str` | 0 |
| `customer_unique_id` | `str` | 0 |
| `customer_zip_code_prefix` | `int64` | 0 |
| `customer_city` | `str` | 0 |
| `customer_state` | `str` | 0 |

### `olist_geolocation_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `geolocation_zip_code_prefix` | `int64` | 0 |
| `geolocation_lat` | `float64` | 0 |
| `geolocation_lng` | `float64` | 0 |
| `geolocation_city` | `str` | 0 |
| `geolocation_state` | `str` | 0 |

### `olist_order_items_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `order_id` | `str` | 0 |
| `order_item_id` | `int64` | 0 |
| `product_id` | `str` | 0 |
| `seller_id` | `str` | 0 |
| `shipping_limit_date` | `str` | 0 |
| `price` | `float64` | 0 |
| `freight_value` | `float64` | 0 |

### `olist_order_payments_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `order_id` | `str` | 0 |
| `payment_sequential` | `int64` | 0 |
| `payment_type` | `str` | 0 |
| `payment_installments` | `int64` | 0 |
| `payment_value` | `float64` | 0 |

### `olist_order_reviews_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `review_id` | `str` | 0 |
| `order_id` | `str` | 0 |
| `review_score` | `int64` | 0 |
| `review_comment_title` | `str` | 87,656 |
| `review_comment_message` | `str` | 58,247 |
| `review_creation_date` | `str` | 0 |
| `review_answer_timestamp` | `str` | 0 |

### `olist_orders_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `order_id` | `str` | 0 |
| `customer_id` | `str` | 0 |
| `order_status` | `str` | 0 |
| `order_purchase_timestamp` | `str` | 0 |
| `order_approved_at` | `str` | 160 |
| `order_delivered_carrier_date` | `str` | 1,783 |
| `order_delivered_customer_date` | `str` | 2,965 |
| `order_estimated_delivery_date` | `str` | 0 |

### `olist_products_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `product_id` | `str` | 0 |
| `product_category_name` | `str` | 610 |
| `product_name_lenght` | `float64` | 610 |
| `product_description_lenght` | `float64` | 610 |
| `product_photos_qty` | `float64` | 610 |
| `product_weight_g` | `float64` | 2 |
| `product_length_cm` | `float64` | 2 |
| `product_height_cm` | `float64` | 2 |
| `product_width_cm` | `float64` | 2 |

### `olist_sellers_dataset.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `seller_id` | `str` | 0 |
| `seller_zip_code_prefix` | `int64` | 0 |
| `seller_city` | `str` | 0 |
| `seller_state` | `str` | 0 |

### `product_category_name_translation.csv`

| Column | Data Type | Missing Values |
|---|---|---:|
| `product_category_name` | `str` | 0 |
| `product_category_name_english` | `str` | 0 |