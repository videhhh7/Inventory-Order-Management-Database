USE InventoryOrderDemo;
GO
-- Low-stock products
SELECT ProductId,Sku,ProductName,QuantityOnHand,ReorderLevel
FROM dbo.Products WHERE IsActive=1 AND QuantityOnHand<=ReorderLevel
ORDER BY QuantityOnHand,ProductName;
GO
-- Sales by product
SELECT p.ProductId,p.Sku,p.ProductName,SUM(oi.Quantity) AS UnitsSold,
       SUM(oi.Quantity*oi.UnitPrice) AS Revenue
FROM dbo.OrderItems oi
JOIN dbo.Orders o ON o.OrderId=oi.OrderId
JOIN dbo.Products p ON p.ProductId=oi.ProductId
WHERE o.Status IN (N'Paid',N'Shipped')
GROUP BY p.ProductId,p.Sku,p.ProductName ORDER BY Revenue DESC;
GO
-- Customer activity including customers with no orders
SELECT c.CustomerId,c.FullName,COUNT(o.OrderId) AS OrderCount
FROM dbo.Customers c LEFT JOIN dbo.Orders o ON o.CustomerId=c.CustomerId
GROUP BY c.CustomerId,c.FullName ORDER BY OrderCount DESC,c.FullName;
GO
CREATE OR ALTER PROCEDURE dbo.GetCustomerOrderHistory @CustomerId INT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT o.OrderId,o.OrderDateUtc,o.Status,
        COALESCE(SUM(oi.Quantity*oi.UnitPrice),0) AS OrderTotal
 FROM dbo.Orders o LEFT JOIN dbo.OrderItems oi ON oi.OrderId=o.OrderId
 WHERE o.CustomerId=@CustomerId
 GROUP BY o.OrderId,o.OrderDateUtc,o.Status
 ORDER BY o.OrderDateUtc DESC;
END;
GO
