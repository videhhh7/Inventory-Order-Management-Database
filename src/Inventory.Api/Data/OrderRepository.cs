using Microsoft.Data.SqlClient;
using System.Data;
namespace Inventory.Api.Data;

public sealed class OrderRepository(IConfiguration configuration)
{
    private string ConnectionString => configuration.GetConnectionString("Inventory")
        ?? throw new InvalidOperationException("Connection string 'Inventory' is not configured.");

    public async Task<long> CreateOrderAsync(int customerId, IReadOnlyList<(int ProductId,int Quantity)> items, CancellationToken ct)
    {
        if(items.Count==0) throw new ArgumentException("An order needs at least one item.");
        await using var connection=new SqlConnection(ConnectionString);
        await connection.OpenAsync(ct);
        await using var transaction=await connection.BeginTransactionAsync(IsolationLevel.Serializable,ct);
        try
        {
            await using var orderCommand=new SqlCommand(
                "INSERT dbo.Orders(CustomerId) OUTPUT INSERTED.OrderId VALUES(@CustomerId);",connection,(SqlTransaction)transaction);
            orderCommand.Parameters.Add("@CustomerId",SqlDbType.Int).Value=customerId;
            var orderId=(long)(await orderCommand.ExecuteScalarAsync(ct) ?? throw new InvalidOperationException("Order insert failed."));
            foreach(var item in items)
            {
                if(item.Quantity<=0) throw new ArgumentOutOfRangeException(nameof(items),"Quantity must be positive.");
                await using var itemCommand=new SqlCommand("""
                    UPDATE dbo.Products SET QuantityOnHand=QuantityOnHand-@Quantity
                    WHERE ProductId=@ProductId AND IsActive=1 AND QuantityOnHand>=@Quantity;
                    IF @@ROWCOUNT=0 THROW 50001,'Product missing or insufficient stock.',1;
                    INSERT dbo.OrderItems(OrderId,ProductId,Quantity,UnitPrice)
                    SELECT @OrderId,ProductId,@Quantity,UnitPrice FROM dbo.Products WHERE ProductId=@ProductId;
                    """,connection,(SqlTransaction)transaction);
                itemCommand.Parameters.Add("@Quantity",SqlDbType.Int).Value=item.Quantity;
                itemCommand.Parameters.Add("@ProductId",SqlDbType.Int).Value=item.ProductId;
                itemCommand.Parameters.Add("@OrderId",SqlDbType.BigInt).Value=orderId;
                await itemCommand.ExecuteNonQueryAsync(ct);
            }
            await transaction.CommitAsync(ct);
            return orderId;
        }
        catch { await transaction.RollbackAsync(ct); throw; }
    }
}
