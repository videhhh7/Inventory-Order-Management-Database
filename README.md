# Inventory & Order Management

ASP.NET Core 8 API + SQL Server 2022 with transactional order creation and guarded stock decrement.

## Start SQL Server locally
Create an untracked `.env` file:
```env
MSSQL_SA_PASSWORD=Use-A-Strong-Local-Password-Here!
```
Then run:
```bash
docker compose up -d
```
Set the API connection string (PowerShell):
```powershell
$env:ConnectionStrings__Inventory="Server=localhost,1433;Database=InventoryOrderDemo;User Id=sa;Password=YOUR_PASSWORD;TrustServerCertificate=True"
```
Run `sql/schema.sql` and `sql/seed.sql` using SSMS or sqlcmd, then:
```bash
dotnet restore src/Inventory.Api/Inventory.Api.csproj
dotnet run --project src/Inventory.Api/Inventory.Api.csproj
```

## Endpoints
- GET `/health`
- GET `/api/products/low-stock`
- POST `/api/customers`
- POST `/api/products`
- POST `/api/orders`

Order creation uses a SQL transaction and fails atomically if stock is insufficient.

## Cloud deployment
Use Amazon RDS for SQL Server or Azure SQL Database and deploy the API to ECS/App Runner or Azure App Service. Keep the DB private, enable TLS, use a least-privilege application login, and store the connection string in the cloud secret manager. Run reviewed schema scripts as a controlled deployment step; do not use the SQL admin account in the app.

Never commit database passwords or production data.