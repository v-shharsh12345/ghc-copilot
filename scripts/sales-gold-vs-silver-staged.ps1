$ErrorActionPreference = "Stop"
$sqlTok = az account get-access-token --resource "https://database.windows.net/" --query accessToken -o tsv
if (-not $sqlTok) { throw "No SQL token. Run 'az login' first." }

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

$salesServer = "x6eps4xrq2xudenlfv6naeo3i4-wkxkhwrfvh7exepkpoy75r6w7a.msit-datawarehouse.fabric.microsoft.com"
$salesDb     = "POSOT_Sales"

# ---- Resolve latest SalesGold schema that has all required Gold + intermediate tables ----
$reqGold = @('FactSales','DimBusiness','FactECSPurchase_Base','FactReconcileECSPurchase','FactECSPurchase')
$schemaSql = @"
SELECT TABLE_SCHEMA, COUNT(DISTINCT TABLE_NAME) AS hit
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE 'SalesGold20%'
  AND TABLE_NAME IN ('FactSales','DimBusiness','FactECSPurchase_Base','FactReconcileECSPurchase','FactECSPurchase')
GROUP BY TABLE_SCHEMA
HAVING COUNT(DISTINCT TABLE_NAME) = 5
ORDER BY TABLE_SCHEMA DESC
"@
$schemaDt = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $schemaSql
if ($schemaDt.Rows.Count -eq 0) { throw "No SalesGold schema contains all required tables: $($reqGold -join ', ')" }
$goldSchema = [string]$schemaDt.Rows[0]["TABLE_SCHEMA"]
Write-Host "Resolved latest SalesGold schema: $goldSchema"

# ---- Resolve Silver schema containing ECSPURSL00 ----
$silverSql = @"
SELECT TOP 1 TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'ECSPURSL00' AND TABLE_SCHEMA LIKE 'Silver%'
ORDER BY CASE WHEN TABLE_SCHEMA = 'Silver' THEN 0 ELSE 1 END, TABLE_SCHEMA
"@
$silverDt = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $silverSql
if ($silverDt.Rows.Count -eq 0) { throw "No Silver schema contains ECSPURSL00." }
$silverSchema = [string]$silverDt.Rows[0]["TABLE_SCHEMA"]
Write-Host "Resolved Silver schema: $silverSchema"

# =====================================================================
# Stage source queries (FiscalMonthID grain). Measures mapped by lineage:
#   Revenue : Silver actualrevenueamt -> Intermediate ActualRevenueAmt -> Gold SoldSeatsRevenue
#   SoldSeat: Silver InitiatedUnitCnt -> Intermediate SoldSeats        -> Gold SoldSeatsEOP
#   Deployed: Silver AssignedUnitCnt  -> Intermediate DeployedSeats    -> Gold DeployedSeatsEOP
#   Licenses: Silver Licenses(ActualLicenseCnt) -> Intermediate ActualLicenseCnt -> Gold Licenses
# =====================================================================

$silverQ = @"
SELECT A.FiscalMonthID,
SUM(CASE WHEN TRIM(SP.SummaryProgramName) = 'New Commerce' AND TRIM(SD.SuperDivisionCode) = 'HH9'
    THEN CAST(A.ActualRevenueAmt AS FLOAT)
    ELSE (CAST(A.ActualRevenueAmt AS FLOAT) / CD.ConstantDollarExchangeRate) END) AS Revenue,
SUM(A.InitiatedUnitCnt) AS SoldSeats,
SUM(A.AssignedUnitCnt)  AS DeployedSeats,
SUM(A.ActualLicenseCnt) AS Licenses
FROM [$silverSchema].[ECSPURSL00] A
INNER JOIN [$silverSchema].[ConstantDollarExchangeRate] CD
  ON A.BillingCurrencyID = CD.CurrencyID AND A.BillingMonthSalesDateID = CD.SalesDateID
 AND A.BusinessSummaryID IN (1, 25) AND A.FiscalMonthID >= 409
INNER JOIN [$silverSchema].[LicenseMaster] LM ON LM.LicenseTransactionItemId = A.LicenseTransactionItemId
INNER JOIN [$silverSchema].[SummaryProgram] SP ON SP.SummaryProgramId = LM.SummaryProgramID
INNER JOIN [$silverSchema].[ProductMaster] PM ON A.ProductId = PM.ProductID
INNER JOIN [$silverSchema].[SuperDivision] SD ON SD.SuperDivisionID = PM.SuperDivisionID
GROUP BY A.FiscalMonthID
"@

function Get-IntermediateQuery($tbl) {
@"
SELECT FiscalMonthID,
SUM(ActualRevenueAmt) AS Revenue,
SUM(SoldSeats)        AS SoldSeats,
SUM(DeployedSeats)    AS DeployedSeats,
SUM(ActualLicenseCnt) AS Licenses
FROM [$goldSchema].[$tbl] F
INNER JOIN [$goldSchema].[DimBusiness] DB ON F.BusinessID = DB.BusinessID AND DB.BusinessSummaryID IN (1, 25)
WHERE F.FiscalMonthID >= 409
GROUP BY FiscalMonthID
"@
}

$goldQ = @"
SELECT F.FiscalMonthID,
SUM(F.SoldSeatsRevenue) AS Revenue,
SUM(F.SoldSeatsEOP)     AS SoldSeats,
SUM(F.DeployedSeatsEOP) AS DeployedSeats,
SUM(F.Licenses)         AS Licenses
FROM [$goldSchema].[FactSales] F
INNER JOIN [$goldSchema].[DimBusiness] DB ON F.BusinessID = DB.BusinessID AND DB.BusinessSummaryID IN (1, 25)
WHERE F.IsDisti = 'No' AND F.FiscalMonthID >= 409
GROUP BY F.FiscalMonthID
"@

Write-Host "=== Running Sales Silver ==="
$dSilver = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $silverQ
Write-Host "  rows: $($dSilver.Rows.Count)"
Write-Host "=== Running FactECSPurchase_Base ==="
$dBase = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql (Get-IntermediateQuery 'FactECSPurchase_Base')
Write-Host "  rows: $($dBase.Rows.Count)"
Write-Host "=== Running FactReconcileECSPurchase ==="
$dRecon = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql (Get-IntermediateQuery 'FactReconcileECSPurchase')
Write-Host "  rows: $($dRecon.Rows.Count)"
Write-Host "=== Running FactECSPurchase ==="
$dEcs = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql (Get-IntermediateQuery 'FactECSPurchase')
Write-Host "  rows: $($dEcs.Rows.Count)"
Write-Host "=== Running Sales Gold (FactSales) ==="
$dGold = Invoke-FabricQuery -server $salesServer -db $salesDb -token $sqlTok -sql $goldQ
Write-Host "  rows: $($dGold.Rows.Count)"

# ---- Index helpers ----
function To-Map($dt) {
  $m = @{}
  foreach ($r in $dt.Rows) {
    $fm = [int]$r["FiscalMonthID"]
    $m[$fm] = [PSCustomObject]@{
      Revenue       = if ($r["Revenue"] -is [DBNull]) { $null } else { [double]$r["Revenue"] }
      SoldSeats     = if ($r["SoldSeats"] -is [DBNull]) { $null } else { [double]$r["SoldSeats"] }
      DeployedSeats = if ($r["DeployedSeats"] -is [DBNull]) { $null } else { [double]$r["DeployedSeats"] }
      Licenses      = if ($r["Licenses"] -is [DBNull]) { $null } else { [double]$r["Licenses"] }
    }
  }
  return $m
}
$mSilver = To-Map $dSilver
$mBase   = To-Map $dBase
$mRecon  = To-Map $dRecon
$mEcs    = To-Map $dEcs
$mGold   = To-Map $dGold

function Build-Stage($upName, $downName, $upMap, $downMap) {
  $fms = ($upMap.Keys + $downMap.Keys) | Sort-Object -Unique
  foreach ($fm in $fms) {
    $u = $upMap[$fm]; $d = $downMap[$fm]
    foreach ($measure in 'Revenue','SoldSeats','DeployedSeats','Licenses') {
      $uv = if ($u) { $u.$measure } else { $null }
      $dv = if ($d) { $d.$measure } else { $null }
      $diff = if ($uv -ne $null -and $dv -ne $null) { $uv - $dv } else { $null }
      [PSCustomObject]@{
        FiscalMonthID = $fm
        Measure       = $measure
        Upstream      = $upName
        Downstream    = $downName
        UpstreamValue = $uv
        DownstreamValue = $dv
        Difference    = $diff
      }
    }
  }
}

$stage1 = Build-Stage "Sales Silver" "FactECSPurchase_Base" $mSilver $mBase
$stage2 = Build-Stage "FactECSPurchase_Base" "FactReconcileECSPurchase" $mBase $mRecon
$stage3 = Build-Stage "FactReconcileECSPurchase" "FactECSPurchase" $mRecon $mEcs
$stage4 = Build-Stage "FactECSPurchase" "FactSales (Sales Gold)" $mEcs $mGold

# ---- Stage definitions (preserve order) ----
$stages = @(
  @{ Title = "Stage 1: Sales Silver vs FactECSPurchase_Base"; Data = $stage1 },
  @{ Title = "Stage 2: FactECSPurchase_Base vs FactReconcileECSPurchase"; Data = $stage2 },
  @{ Title = "Stage 3: FactReconcileECSPurchase vs FactECSPurchase"; Data = $stage3 },
  @{ Title = "Stage 4: FactECSPurchase vs FactSales (Sales Gold)"; Data = $stage4 }
)

# ---- CSV (long form, all stages) ----
$flat = New-Object System.Collections.Generic.List[object]
foreach ($st in $stages) {
  foreach ($item in $st.Data) {
    $flat.Add([pscustomobject][ordered]@{
      Stage           = $st.Title
      FiscalMonthID   = $item.FiscalMonthID
      Measure         = $item.Measure
      Upstream        = $item.Upstream
      Downstream      = $item.Downstream
      UpstreamValue   = $item.UpstreamValue
      DownstreamValue = $item.DownstreamValue
      Difference      = $item.Difference
    })
  }
}
$csvPath = "scripts\sales-gold-vs-silver-staged.csv"
$flat | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "`nSaved CSV: $csvPath"

# ---- Excel with heading per stage (ImportExcel / EPPlus, no COM) ----
Import-Module ImportExcel
$xlPath   = Join-Path (Get-Location) "Sales_Gold_vs_Silver_Staged_Validation.xlsx"
$deskPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "Sales_Gold_vs_Silver_Staged_Validation.xlsx"
if (Test-Path $xlPath)   { Remove-Item $xlPath -Force }
if (Test-Path $deskPath) { Remove-Item $deskPath -Force }

$pkg = New-Object OfficeOpenXml.ExcelPackage
$ws  = $pkg.Workbook.Worksheets.Add("Sales Gold vs Silver")
$cols = @('FiscalMonthID','Measure','Upstream','Downstream','UpstreamValue','DownstreamValue','Difference')
$row = 1

# Workbook title
$ws.Cells[$row,1].Value = "Sales Gold vs Sales Silver - Staged Validation"
$ws.Cells[$row,1,$row,7].Merge = $true
$ws.Cells[$row,1].Style.Font.Bold = $true
$ws.Cells[$row,1].Style.Font.Size = 14
$ws.Cells[$row,1].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
$ws.Cells[$row,1].Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(31,78,121))
$ws.Cells[$row,1].Style.Font.Color.SetColor([System.Drawing.Color]::White)
$row++
$ws.Cells[$row,1].Value = "Database: $salesDb   |   Gold schema: $goldSchema   |   Silver schema: $silverSchema   |   Filter: FiscalMonthID >= 409   |   Run UTC: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))"
$ws.Cells[$row,1,$row,7].Merge = $true
$ws.Cells[$row,1].Style.Font.Italic = $true
$row += 2

foreach ($st in $stages) {
  $ws.Cells[$row,1].Value = $st.Title
  $ws.Cells[$row,1,$row,7].Merge = $true
  $ws.Cells[$row,1].Style.Font.Bold = $true
  $ws.Cells[$row,1].Style.Font.Size = 12
  $ws.Cells[$row,1].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
  $ws.Cells[$row,1].Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(221,235,247))
  $row++

  for ($c = 0; $c -lt $cols.Count; $c++) {
    $cell = $ws.Cells[$row, ($c+1)]
    $cell.Value = $cols[$c]
    $cell.Style.Font.Bold = $true
    $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
    $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(217,217,217))
    $cell.Style.Border.Bottom.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
  }
  $row++

  foreach ($item in $st.Data) {
    $ws.Cells[$row,1].Value = [int]$item.FiscalMonthID
    $ws.Cells[$row,2].Value = [string]$item.Measure
    $ws.Cells[$row,3].Value = [string]$item.Upstream
    $ws.Cells[$row,4].Value = [string]$item.Downstream
    foreach ($pair in @(@(5,$item.UpstreamValue), @(6,$item.DownstreamValue), @(7,$item.Difference))) {
      $col = $pair[0]; $val = $pair[1]
      if ($val -ne $null) {
        $ws.Cells[$row,$col].Value = [double]$val
        $ws.Cells[$row,$col].Style.Numberformat.Format = "#,##0.00"
      }
    }
    if ($item.Difference -ne $null -and [math]::Abs([double]$item.Difference) -gt 0.01) {
      $ws.Cells[$row,7].Style.Font.Color.SetColor([System.Drawing.Color]::Red)
      $ws.Cells[$row,7].Style.Font.Bold = $true
    }
    $row++
  }
  $row += 2
}

$ws.Cells[$ws.Dimension.Address].AutoFitColumns()
$pkg.SaveAs([System.IO.FileInfo]$xlPath)
Copy-Item $xlPath $deskPath -Force
$pkg.Dispose()

Write-Host "Saved Excel: $xlPath"
Write-Host "Saved Excel (Desktop): $deskPath"

# ---- Console summary of mismatches ----
Write-Host "`n=== Stage difference summary (non-zero diffs) ==="
foreach ($st in $stages) {
  $nz = $st.Data | Where-Object { $_.Difference -ne $null -and [math]::Abs([double]$_.Difference) -gt 0.0001 }
  Write-Host ("{0}: {1} measure-rows with non-zero diff out of {2}" -f $st.Title, $nz.Count, $st.Data.Count)
}
Write-Host "DONE"
