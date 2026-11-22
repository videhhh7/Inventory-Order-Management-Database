using Inventory.Api.Data;
using Inventory.Api.Models;
using Microsoft.Data.SqlClient;
using Microsoft.AspNetCore.Http;
using System.Data;

var builder=WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<InventoryRepository>();
builder.Services.AddSingleton<OrderRepository>();
var app=builder.Build();

app.MapGet("/health",()=>Results.Ok(new {status="healthy"}));
app.MapGet("/api/products/low-stock",async (InventoryRepository repo,CancellationToken ct)=>
    Results.Ok(await repo.GetLowStockAsync(ct)));
app.MapPost("/api/customers",async (CreateCustomerRequest request,IConfiguration config,CancellationToken ct)=>
{
    if(string.IsNullOrWhiteSpace(request.FullName)||string.IsNullOrWhiteSpace(request.Email)) return Results.BadRequest();
    await using var con=new SqlConnection(config.GetConnectionString("Inventory"));
    await con.OpenAsync(ct);
    await using var cmd=new SqlCommand("INSERT dbo.Customers(FullName,Email) OUTPUT INSERTED.CustomerId VALUES(@Name,@Email)",con);
    cmd.Parameters.Add("@Name",SqlDbType.NVarChar,150).Value=request.FullName;
    cmd.Parameters.Add("@Email",SqlDbType.NVarChar,254).Value=request.Email;
    var id=(int)(await cmd.ExecuteScalarAsync(ct) ?? 0);
    return Results.Created($"/api/customers/{id}",new {customerId=id});
});
app.MapPost("/api/products",async (CreateProductRequest request,IConfiguration config,CancellationToken ct)=>
{
    if(string.IsNullOrWhiteSpace(request.Sku)||string.IsNullOrWhiteSpace(request.ProductName)||request.UnitPrice<0||request.QuantityOnHand<0||request.ReorderLevel<0) return Results.BadRequest();
    await using var con=new SqlConnection(config.GetConnectionString("Inventory"));
    await con.OpenAsync(ct);
    await using var cmd=new SqlCommand("""
      INSERT dbo.Products(Sku,ProductName,UnitPrice,QuantityOnHand,ReorderLevel)
      OUTPUT INSERTED.ProductId VALUES(@Sku,@Name,@Price,@Qty,@Reorder)
      """,con);
    cmd.Parameters.Add("@Sku",SqlDbType.NVarChar,40).Value=request.Sku;
    cmd.Parameters.Add("@Name",SqlDbType.NVarChar,160).Value=request.ProductName;
    cmd.Parameters.Add("@Price",SqlDbType.Decimal).Value=request.UnitPrice;
    cmd.Parameters["@Price"].Precision=12;cmd.Parameters["@Price"].Scale=2;
    cmd.Parameters.Add("@Qty",SqlDbType.Int).Value=request.QuantityOnHand;
    cmd.Parameters.Add("@Reorder",SqlDbType.Int).Value=request.ReorderLevel;
    var id=(int)(await cmd.ExecuteScalarAsync(ct) ?? 0);
    return Results.Created($"/api/products/{id}",new {productId=id});
});
app.MapPost("/api/orders",async (CreateOrderRequest request,OrderRepository repo,CancellationToken ct)=>
{
    try {
        var id=await repo.CreateOrderAsync(request.CustomerId,request.Items.Select(x=>(x.ProductId,x.Quantity)).ToArray(),ct);
        return Results.Created($"/api/orders/{id}",new {orderId=id});
    } catch(SqlException ex) when(ex.Number==50001) { return Results.Conflict(new {error="Insufficient stock or product unavailable."}); }
});
app.Run();
