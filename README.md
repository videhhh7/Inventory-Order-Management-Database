# Inventory & Order Management Database

SQL Server portfolio project demonstrating relational database design and reporting for customers, products, inventory and orders.

## Features
- Normalized tables with primary and foreign keys.
- Constraints for data integrity.
- Order header and order-line modelling.
- Inventory tracking and low-stock reporting.
- Reusable views, stored procedures and analytical queries.

## Schema
```text
Customers 1 --- * Orders 1 --- * OrderItems * --- 1 Products
```

## Run
1. Open SQL Server Management Studio and connect to a local development SQL Server.
2. Run `sql/schema.sql`.
3. Run `sql/reports.sql`.

The scripts create a dedicated `InventoryOrderDemo` database. Review scripts before running on shared infrastructure.

## API starter
A minimal ASP.NET Core 8 API is included under `src/Inventory.Api`. Configure the connection string using user secrets or environment variables; do not commit real credentials.

## Possible extensions
Add inventory transaction history, optimistic concurrency, automated database tests and query-plan-driven indexing.
