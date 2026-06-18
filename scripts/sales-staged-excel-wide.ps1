$ErrorActionPreference = "Stop"
Import-Module ImportExcel

$csvPath = "scripts\sales-gold-vs-silver-staged.csv"
$rows = Import-Csv $csvPath

$goldSchema   = "SalesGold2026061601"
$silverSchema = "Silver"
$salesDb      = "POSOT_Sales"
$runUtc       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")

# Measure order used in the long CSV
$measures = 'Revenue','SoldSeats','DeployedSeats','Licenses'

# Per-stage native column names (upstream table | downstream table) matching each notebook query
$stageDefs = @(
  @{ Title="Stage 1: Sales Silver vs FactECSPurchase_Base"
     UpLabel="ECSPURSL00 (Sales Silver)"; UpCols=@('actualrevenueamt','InitiatedUnitCnt','AssignedUnitCnt','Licenses')
     DownLabel="FactECSPurchase_Base";     DownCols=@('ActualRevenueAmt','SoldSeats','DeployedSeats','ActualLicenseCnt')
     Stage="Stage 1: Sales Silver vs FactECSPurchase_Base" },
  @{ Title="Stage 2: FactECSPurchase_Base vs FactReconcileECSPurchase"
     UpLabel="FactECSPurchase_Base";        UpCols=@('ActualRevenueAmt','SoldSeats','DeployedSeats','ActualLicenseCnt')
     DownLabel="FactReconcileECSPurchase";  DownCols=@('ActualRevenueAmt','SoldSeats','DeployedSeats','ActualLicenseCnt')
     Stage="Stage 2: FactECSPurchase_Base vs FactReconcileECSPurchase" },
  @{ Title="Stage 3: FactReconcileECSPurchase vs FactECSPurchase"
     UpLabel="FactReconcileECSPurchase";    UpCols=@('ActualRevenueAmt','SoldSeats','DeployedSeats','ActualLicenseCnt')
     DownLabel="FactECSPurchase";           DownCols=@('ActualRevenueAmt','SoldSeats','DeployedSeats','ActualLicenseCnt')
     Stage="Stage 3: FactReconcileECSPurchase vs FactECSPurchase" },
  @{ Title="Stage 4: FactECSPurchase vs FactSales (Sales Gold)"
     UpLabel="FactECSPurchase";             UpCols=@('ActualRevenueAmt','SoldSeats','DeployedSeats','ActualLicenseCnt')
     DownLabel="FactSales (Sales Gold)";    DownCols=@('BilledRevenue','SoldSeatsEOP','DeployedSeatsEOP','Licenses')
     Stage="Stage 4: FactECSPurchase vs FactSales (Sales Gold)" }
)

$xlPath   = Join-Path (Get-Location) "Sales_Gold_vs_Silver_Staged_Validation.xlsx"
$deskPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "Sales_Gold_vs_Silver_Staged_Validation.xlsx"
if (Test-Path $xlPath) { try { Remove-Item $xlPath -Force } catch { } }

$pkg = New-Object OfficeOpenXml.ExcelPackage
$ws  = $pkg.Workbook.Worksheets.Add("Sales Gold vs Silver")

$navy   = [System.Drawing.Color]::FromArgb(31,78,121)
$blue   = [System.Drawing.Color]::FromArgb(189,215,238)
$grey   = [System.Drawing.Color]::FromArgb(217,217,217)
$amber  = [System.Drawing.Color]::FromArgb(255,242,204)
$white  = [System.Drawing.Color]::White

$row = 1
# Workbook title
$ws.Cells[$row,1].Value = "Sales Gold vs Sales Silver - Staged Validation (side-by-side)"
$ws.Cells[$row,1,$row,14].Merge = $true
$ws.Cells[$row,1].Style.Font.Bold = $true
$ws.Cells[$row,1].Style.Font.Size = 14
$ws.Cells[$row,1].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
$ws.Cells[$row,1].Style.Fill.BackgroundColor.SetColor($navy)
$ws.Cells[$row,1].Style.Font.Color.SetColor($white)
$row++
$ws.Cells[$row,1].Value = "Database: $salesDb   |   Gold schema: $goldSchema   |   Silver schema: $silverSchema   |   Filter: FiscalMonthID >= 409   |   Run UTC: $runUtc   |   %Diff = (Upstream - Downstream) / Downstream"
$ws.Cells[$row,1,$row,14].Merge = $true
$ws.Cells[$row,1].Style.Font.Italic = $true
$row += 2

foreach ($sd in $stageDefs) {
  # Pivot this stage's long rows -> per FiscalMonthID map of measure values
  $stageRows = $rows | Where-Object { $_.Stage -eq $sd.Stage }
  $byMonth = @{}
  foreach ($r in $stageRows) {
    $fm = [int]$r.FiscalMonthID
    if (-not $byMonth.ContainsKey($fm)) { $byMonth[$fm] = @{} }
    $byMonth[$fm][$r.Measure] = [pscustomobject]@{
      Up   = if ($r.UpstreamValue   -ne '') { [double]$r.UpstreamValue }   else { $null }
      Down = if ($r.DownstreamValue -ne '') { [double]$r.DownstreamValue } else { $null }
    }
  }
  $months = $byMonth.Keys | Sort-Object

  # --- Stage title bar ---
  $ws.Cells[$row,1].Value = $sd.Title
  $ws.Cells[$row,1,$row,14].Merge = $true
  $ws.Cells[$row,1].Style.Font.Bold = $true
  $ws.Cells[$row,1].Style.Font.Size = 12
  $ws.Cells[$row,1].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
  $ws.Cells[$row,1].Style.Fill.BackgroundColor.SetColor($navy)
  $ws.Cells[$row,1].Style.Font.Color.SetColor($white)
  $row++

  # --- Group label band: upstream (1-5), %diff (6-9), downstream (10-14) ---
  $ws.Cells[$row,1].Value = $sd.UpLabel
  $ws.Cells[$row,1,$row,5].Merge = $true
  $ws.Cells[$row,1].Style.Font.Bold = $true
  $ws.Cells[$row,1].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
  $ws.Cells[$row,1].Style.Fill.BackgroundColor.SetColor($blue)
  $ws.Cells[$row,1].Style.HorizontalAlignment = [OfficeOpenXml.Style.ExcelHorizontalAlignment]::Center

  $ws.Cells[$row,6].Value = "% Difference (Up vs Down)"
  $ws.Cells[$row,6,$row,9].Merge = $true
  $ws.Cells[$row,6].Style.Font.Bold = $true
  $ws.Cells[$row,6].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
  $ws.Cells[$row,6].Style.Fill.BackgroundColor.SetColor($amber)
  $ws.Cells[$row,6].Style.HorizontalAlignment = [OfficeOpenXml.Style.ExcelHorizontalAlignment]::Center

  $ws.Cells[$row,10].Value = $sd.DownLabel
  $ws.Cells[$row,10,$row,14].Merge = $true
  $ws.Cells[$row,10].Style.Font.Bold = $true
  $ws.Cells[$row,10].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
  $ws.Cells[$row,10].Style.Fill.BackgroundColor.SetColor($blue)
  $ws.Cells[$row,10].Style.HorizontalAlignment = [OfficeOpenXml.Style.ExcelHorizontalAlignment]::Center
  $row++

  # --- Column headers ---
  $headers = @('FiscalMonthID') + $sd.UpCols `
           + @('%Diff_Revenue','%Diff_SoldSeats','%Diff_DeployedSeats','%Diff_Licenses') `
           + @('FiscalMonthID') + $sd.DownCols
  for ($c = 0; $c -lt $headers.Count; $c++) {
    $cell = $ws.Cells[$row, ($c+1)]
    $cell.Value = $headers[$c]
    $cell.Style.Font.Bold = $true
    $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
    $cell.Style.Fill.BackgroundColor.SetColor($grey)
    $cell.Style.Border.Bottom.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
  }
  $row++

  # --- Data rows (one per FiscalMonthID) ---
  foreach ($fm in $months) {
    $col = 1
    $ws.Cells[$row,$col].Value = $fm; $col++
    # upstream measure values
    foreach ($m in $measures) {
      $v = $byMonth[$fm][$m].Up
      if ($v -ne $null) { $ws.Cells[$row,$col].Value = $v; $ws.Cells[$row,$col].Style.Numberformat.Format = "#,##0.00" }
      $col++
    }
    # % diff per measure
    foreach ($m in $measures) {
      $u = $byMonth[$fm][$m].Up; $d = $byMonth[$fm][$m].Down
      if ($u -ne $null -and $d -ne $null -and $d -ne 0) {
        $pct = ($u - $d) / $d
        $ws.Cells[$row,$col].Value = $pct
        $ws.Cells[$row,$col].Style.Numberformat.Format = "0.00%"
        if ([math]::Abs($pct) -gt 0.0001) {
          $ws.Cells[$row,$col].Style.Font.Color.SetColor([System.Drawing.Color]::Red)
          $ws.Cells[$row,$col].Style.Font.Bold = $true
        }
      } elseif ($u -ne $null -and $d -ne $null -and $d -eq 0 -and $u -ne 0) {
        $ws.Cells[$row,$col].Value = "n/a"
      }
      $col++
    }
    # downstream FiscalMonthID + values
    $ws.Cells[$row,$col].Value = $fm; $col++
    foreach ($m in $measures) {
      $v = $byMonth[$fm][$m].Down
      if ($v -ne $null) { $ws.Cells[$row,$col].Value = $v; $ws.Cells[$row,$col].Style.Numberformat.Format = "#,##0.00" }
      $col++
    }
    $row++
  }
  $row += 2
}

$ws.Cells[$ws.Dimension.Address].AutoFitColumns()
$ws.View.FreezePanes(4,1)
$pkg.SaveAs([System.IO.FileInfo]$xlPath)
try {
  Copy-Item $xlPath $deskPath -Force
  Write-Host "Saved Excel (Desktop): $deskPath"
} catch {
  $dt = Get-Date -Format "yyyyMMdd_HHmmss"
  $deskPath = Join-Path ([Environment]::GetFolderPath('Desktop')) ("Sales_Gold_vs_Silver_Staged_Validation_" + $dt + ".xlsx")
  Copy-Item $xlPath $deskPath -Force
  Write-Host "Desktop file was locked; saved timestamped copy: $deskPath"
}
$pkg.Dispose()

Write-Host "Saved Excel: $xlPath"
Write-Host "DONE"
