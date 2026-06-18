$ErrorActionPreference = "Stop"
$sqlTok = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv

function Invoke-FabricQuery {
  param($server, $db, $token, $sql)
  $conn = New-Object System.Data.SqlClient.SqlConnection
  $conn.ConnectionString = "Server=tcp:$server,1433;Database=$db;Encrypt=True;TrustServerCertificate=False;Connection Timeout=120;"
  $conn.AccessToken = $token
  $conn.Open()
  $cmd = $conn.CreateCommand()
  $cmd.CommandText = $sql
  $cmd.CommandTimeout = 600
  $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
  $dt = New-Object System.Data.DataTable
  [void]$da.Fill($dt)
  $conn.Close()
  return ,$dt
}

# Endpoints
$salesServer = "x6eps4xrq2xudenlfv6naeo3i4-wkxkhwrfvh7exepkpoy75r6w7a.msit-datawarehouse.fabric.microsoft.com"
$salesDb     = "POSOT_Sales"
$salesSchema = "SalesGold2026061601"   # latest dated SalesGold schema (contains FactSales + DimBusiness)

$pprServer   = "x6eps4xrq2xudenlfv6naeo3i4-gs7rn6r7m2oetco33xb7dwa6o4.msit-datawarehouse.fabric.microsoft.com"
$pprDb       = "PPR Warehouse"

# ---- PPR Warehouse query #3: "PPR Warehouse based on Fiscalmonth(Sales)" ----
$pprSql = @"
with cte as (
    SELECT Distinct A.AssociationID
    FROM  [PPR Warehouse].[Gold].[Map_Partner_Association_Sales] A
    inner join [PPR Warehouse].[Gold].[DimPartnerAssociation] M
    on M.AssociationID = A.AssociationID
)
SELECT
    F.FiscalMonthID,
    T.FiscalMonthName,
    SUM(F.SoldSeatsRevenue) AS TotalSoldSeatsRevenue
FROM [PPR Warehouse].[Gold].[FactSalesPPR] F
inner JOIN [PPR Warehouse].[Gold].[DimIntegrationTime] T
    ON T.FiscalMonthID = F.FiscalMonthID
inner join cte c on c.AssociationID = F.AssociationID
GROUP BY F.FiscalMonthID, T.FiscalMonthName
ORDER BY F.FiscalMonthID
"@

# ---- Sales Gold query (Source D), schema-qualified for T-SQL ----
$salesSql = @"
SELECT F.FiscalMonthID,
       SUM(F.SoldSeatsRevenue) AS BilledRevenue
FROM [$salesSchema].[FactSales] F
INNER JOIN [$salesSchema].[DimBusiness] DB
    ON F.BusinessID = DB.BusinessID
   AND DB.BusinessSummaryID IN (1, 25)
   AND F.IsDisti = 'No'
WHERE F.FiscalMonthID >= 409
GROUP BY F.FiscalMonthID
ORDER BY F.FiscalMonthID
"@

Write-Host "=== Running PPR Warehouse (FactSalesPPR by FiscalMonth) ==="
$pprDt = Invoke-FabricQuery -server $pprServer -db $pprDb -token $sqlTok -sql $pprSql
Write-Host "PPR rows: $($pprDt.Rows.Count)"

Write-Host "=== Running Sales Gold (FactSales by FiscalMonth) ==="
$salesDt = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $salesSql
Write-Host "Sales rows: $($salesDt.Rows.Count)"

# ---- Merge by FiscalMonthID ----
$ppr = @{}
$names = @{}
foreach ($r in $pprDt.Rows) {
  $fm = [int]$r["FiscalMonthID"]
  $ppr[$fm] = [decimal]$r["TotalSoldSeatsRevenue"]
  $names[$fm] = [string]$r["FiscalMonthName"]
}
$sales = @{}
foreach ($r in $salesDt.Rows) {
  $fm = [int]$r["FiscalMonthID"]
  $sales[$fm] = [decimal]$r["BilledRevenue"]
}

$allFm = ($ppr.Keys + $sales.Keys) | Sort-Object -Unique
$results = foreach ($fm in $allFm) {
  $p = if ($ppr.ContainsKey($fm)) { $ppr[$fm] } else { $null }
  $s = if ($sales.ContainsKey($fm)) { $sales[$fm] } else { $null }
  $diff = if ($p -ne $null -and $s -ne $null) { $p - $s } else { $null }
  [PSCustomObject]@{
    FiscalMonthID            = $fm
    FiscalMonthName          = $names[$fm]
    PPR_SoldSeatsRevenue     = $p
    Sales_SoldSeatsRevenue   = $s
    Difference_PPR_minus_Sales = $diff
    PPR_Source               = "PPR Warehouse.Gold.FactSalesPPR"
    Sales_Source             = "POSOT_Sales.$salesSchema.FactSales"
    QueryRunUTC              = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
  }
}

$csvPath = "scripts\ppr-warehouse-vs-sales-fiscalmonth.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "`nSaved CSV: $csvPath"
$results | Format-Table -AutoSize | Out-String -Width 220 | Write-Host
