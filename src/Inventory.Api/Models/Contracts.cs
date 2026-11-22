namespace Inventory.Api.Models;
public sealed record CreateProductRequest(string Sku,string ProductName,decimal UnitPrice,int QuantityOnHand,int ReorderLevel);
public sealed record CreateOrderRequest(int CustomerId,IReadOnlyList<CreateOrderItemRequest> Items);
public sealed record CreateOrderItemRequest(int ProductId,int Quantity);
public sealed record CreateCustomerRequest(string FullName,string Email);
