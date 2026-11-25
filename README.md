# Small Business Order Management Database

A compact PostgreSQL schema for a small business that sells products to customers.
It records product categories, customer orders, order line items, and payments.

## Repository contents

- `schema.sql` — creates all tables, keys, constraints, and useful indexes.
- `diagrams/erd.md` — Entity Relationship Diagram in Mermaid syntax.

## Requirements

- PostgreSQL 14 or newer
- A database created for this project

## Run the schema

From a terminal, connect to your PostgreSQL database and run:

```bash
psql -d your_database_name -f schema.sql
```

Or, from the PostgreSQL prompt:

```sql
\i schema.sql
```

The script creates the tables in dependency order. Run it in a new/empty project
database. It is not intended as a migration script and does not drop existing tables.

## Entities and relationships

- One customer can place many orders.
- One category can contain many products.
- Each order contains one or more order items.
- A product can appear in many order items.
- An order can have multiple payment records (for example, split payments).

`order_items` resolves the many-to-many relationship between orders and products.
Its composite primary key (`order_id`, `product_id`) prevents the same product
from being entered twice on one order.

## Keys and constraints

- Every main entity has a primary key.
- `customers.email`, `categories.category_name`, and `products.sku` are unique.
- Foreign keys enforce the relationships shown in the ER diagram.
- `CHECK` constraints validate non-empty names, non-negative prices, positive
  quantities and payment amounts, and allowed order/payment states.
- `NOT NULL` constraints protect required data.
- `ON DELETE CASCADE` is used for order-owned line items and payments. Customer,
  category, and product records cannot be deleted while referenced.

## Normalisation (3NF)

The design follows Third Normal Form:

1. **1NF:** Each column stores a single value; repeating order products are stored
   as separate rows in `order_items`.
2. **2NF:** In `order_items`, `quantity` and the recorded `unit_price` depend on
   the complete composite key (`order_id`, `product_id`). Other tables use
   single-column primary keys.
3. **3NF:** Non-key attributes describe only the key, the whole key, and nothing
   but the key. Customer details are stored only in `customers`; category names
   are stored only in `categories`; product details are stored only in `products`.
   Orders reference customers, and line items reference products rather than
   copying their descriptive details.

`order_items.unit_price` intentionally stores the price agreed at the time of
sale. It is a transaction fact, not a duplicate of the current product price;
this preserves historical order values if a product's price changes later.

## Design assumptions

- A customer is identified by a unique email address in addition to the generated ID.
- Each product belongs to exactly one category.
- An order may have multiple payments.
- An order may contain a product only once; its quantity is stored on that line.
- Taxes, shipping, inventory, returns, and multiple delivery addresses are outside
  this small project's scope.
