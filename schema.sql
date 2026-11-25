-- Small Business Order Management Schema
-- Target database: PostgreSQL 14+
-- All tables are designed to satisfy Third Normal Form (3NF).

CREATE TABLE customers (
    customer_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name      VARCHAR(80) NOT NULL,
    last_name       VARCHAR(80) NOT NULL,
    email           VARCHAR(254) NOT NULL UNIQUE,
    phone           VARCHAR(30),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT customers_email_not_blank CHECK (length(trim(email)) > 0)
);

CREATE TABLE categories (
    category_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name   VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT categories_name_not_blank CHECK (length(trim(category_name)) > 0)
);

CREATE TABLE products (
    product_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id     BIGINT NOT NULL,
    sku             VARCHAR(40) NOT NULL UNIQUE,
    product_name    VARCHAR(150) NOT NULL,
    description     TEXT,
    unit_price      NUMERIC(10, 2) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT products_category_fk
        FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT products_price_nonnegative CHECK (unit_price >= 0),
    CONSTRAINT products_sku_not_blank CHECK (length(trim(sku)) > 0),
    CONSTRAINT products_name_not_blank CHECK (length(trim(product_name)) > 0)
);

CREATE TABLE orders (
    order_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     BIGINT NOT NULL,
    order_date      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status    VARCHAR(20) NOT NULL DEFAULT 'pending',
    notes           TEXT,
    CONSTRAINT orders_customer_fk
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT orders_status_valid
        CHECK (order_status IN ('pending', 'confirmed', 'shipped', 'completed', 'cancelled'))
);

CREATE TABLE order_items (
    order_id        BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantity        INTEGER NOT NULL,
    unit_price      NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT order_items_order_fk
        FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT order_items_product_fk
        FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT order_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT order_items_price_nonnegative CHECK (unit_price >= 0)
);

CREATE TABLE payments (
    payment_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        BIGINT NOT NULL,
    payment_date    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount          NUMERIC(10, 2) NOT NULL,
    payment_method  VARCHAR(20) NOT NULL,
    payment_status  VARCHAR(20) NOT NULL DEFAULT 'pending',
    CONSTRAINT payments_order_fk
        FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT payments_amount_positive CHECK (amount > 0),
    CONSTRAINT payments_method_valid
        CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'online')),
    CONSTRAINT payments_status_valid
        CHECK (payment_status IN ('pending', 'successful', 'failed', 'refunded'))
);

-- Indexes for common joins and lookups. Primary/unique keys are indexed automatically.
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
