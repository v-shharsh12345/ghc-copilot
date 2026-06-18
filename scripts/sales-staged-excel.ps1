$ErrorActionPreference = "Stop"
Import-Module ImportExcel

$csvPath = "scripts\sales-gold-vs-silver-staged.csv"
$rows = Import-Csv $csvPath

$goldSchema   = "SalesGold2026061601"
$silverSchema = "Silver"
$salesDb      = "POSOT_Sales"
$runUtc       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")

$xlPath   = Join-Path (Get-Location) "Sales_Gold_vs_Silver_Staged_Validation.xlsx"
$deskPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "Sales_Gold_vs_Silver_Staged_Validation.xlsx"
if (Test-Path $xlPath)   { Remove-Item $xlPath -Force }
if (Test-Path $deskPath) { Remove-Item $deskPath -Force }

# Preserve stage order
$stageOrder = $rows | Select-Object -ExpandProperty Stage -Unique
$sheet = "Sales Gold vs Silver"

$pkg = New-Object OfficeOpenXml.ExcelPackage
$ws  = $pkg.Workbook.Worksheets.Add($sheet)

$dataCols = 'FiscalMonthID','Measure','Upstream','Downstream','UpstreamValue','DownstreamValue','Difference'
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

$ws.Cells[$row,1].Value = "Database: $salesDb   |   Gold schema: $goldSchema   |   Silver schema: $silverSchema   |   Filter: FiscalMonthID >= 409   |   Run UTC: $runUtc"
$ws.Cells[$row,1,$row,7].Merge = $true
$ws.Cells[$row,1].Style.Font.Italic = $true
$row += 2

foreach ($stage in $stageOrder) {
  $stageRows = $rows | Where-Object { $_.Stage -eq $stage }

  # Stage heading
  $ws.Cells[$row,1].Value = $stage
  $ws.Cells[$row,1,$row,7].Merge = $true
  $ws.Cells[$row,1].Style.Font.Bold = $true
  $ws.Cells[$row,1].Style.Font.Size = 12
  $ws.Cells[$row,1].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
  $ws.Cells[$row,1].Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(221,235,247))
  $row++

  # Column headers
  for ($c = 0; $c -lt $dataCols.Count; $c++) {
    $cell = $ws.Cells[$row, ($c+1)]
    $cell.Value = $dataCols[$c]
    $cell.Style.Font.Bold = $true
    $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
    $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(217,217,217))
    $cell.Style.Border.Bottom.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
  }
  $row++

  # Data rows
  foreach ($r in $stageRows) {
    $ws.Cells[$row,1].Value = [int]$r.FiscalMonthID
    $ws.Cells[$row,2].Value = [string]$r.Measure
    $ws.Cells[$row,3].Value = [string]$r.Upstream
    $ws.Cells[$row,4].Value = [string]$r.Downstream

    foreach ($pair in @(@(5,$r.UpstreamValue), @(6,$r.DownstreamValue), @(7,$r.Difference))) {
      $col = $pair[0]; $val = $pair[1]
      if ($val -ne $null -and $val -ne '') {
        $ws.Cells[$row,$col].Value = [double]$val
        $ws.Cells[$row,$col].Style.Numberformat.Format = "#,##0.00"
      }
    }
    # Highlight non-zero differences
    if ($r.Difference -ne $null -and $r.Difference -ne '' -and [math]::Abs([double]$r.Difference) -gt 0.01) {
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

# Summary of non-zero diffs per stage
Write-Host "`n=== Non-zero difference summary ==="
foreach ($stage in $stageOrder) {
  $nz = $rows | Where-Object { $_.Stage -eq $stage -and $_.Difference -ne '' -and [math]::Abs([double]$_.Difference) -gt 0.01 }
  $tot = ($rows | Where-Object { $_.Stage -eq $stage }).Count
  Write-Host ("{0}: {1}/{2} measure-rows differ" -f $stage, $nz.Count, $tot)
}
Write-Host "DONE"
