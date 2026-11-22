USE InventoryOrderDemo;
GO
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE Email='demo.customer@example.com')
 INSERT dbo.Customers(FullName,Email) VALUES(N'Demo Customer',N'demo.customer@example.com');
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Sku='DEMO-KEYBOARD')
 INSERT dbo.Products(Sku,ProductName,UnitPrice,QuantityOnHand,ReorderLevel) VALUES(N'DEMO-KEYBOARD',N'Demo Keyboard',1499.00,25,5);
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Sku='DEMO-MOUSE')
 INSERT dbo.Products(Sku,ProductName,UnitPrice,QuantityOnHand,ReorderLevel) VALUES(N'DEMO-MOUSE',N'Demo Mouse',699.00,40,8);
GO
