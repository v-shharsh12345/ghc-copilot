$ErrorActionPreference = "Stop"

$csv = Import-Csv "scripts\ppr-warehouse-vs-sales-fiscalmonth.csv"
$rootPath = (Resolve-Path ".").Path + "\PPRWarehouse_vs_Sales_FiscalMonth.xlsx"
$desktopPath = [Environment]::GetFolderPath("Desktop") + "\PPRWarehouse_vs_Sales_FiscalMonth.xlsx"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "PPR vs Sales"

# Title
$ws.Cells.Item(1,1) = "PPR Warehouse vs Sales - SoldSeatsRevenue by FiscalMonth"
$title = $ws.Range("A1:G1")
$title.Merge()
$title.Font.Bold = $true
$title.Font.Size = 14
$title.Interior.Color = 0x7A3B00
$title.Font.Color = 0xFFFFFF
$title.HorizontalAlignment = -4108

# Metadata line
$ws.Cells.Item(2,1) = "PPR: PPR Warehouse.Gold.FactSalesPPR  |  Sales: POSOT_Sales.SalesGold2026061601.FactSales  |  Key: FiscalMonthID"
$meta = $ws.Range("A2:G2"); $meta.Merge(); $meta.Font.Italic = $true

# Headers
$headers = @("FiscalMonthID","FiscalMonthName","PPR SoldSeatsRevenue","Sales SoldSeatsRevenue","Difference (PPR - Sales)","PPR Source","Sales Source")
$hrow = 4
for ($c = 0; $c -lt $headers.Count; $c++) {
  $cell = $ws.Cells.Item($hrow, $c+1)
  $cell.Value2 = $headers[$c]
  $cell.Font.Bold = $true
  $cell.Interior.Color = 0xD9D9D9
  $cell.Borders.LineStyle = 1
}

$r = $hrow + 1
foreach ($row in $csv) {
  $ws.Cells.Item($r,1).Value2 = [double]$row.FiscalMonthID
  $ws.Cells.Item($r,2).Value2 = $row.FiscalMonthName
  $c3 = $ws.Cells.Item($r,3); $c3.Value2 = [double]$row.PPR_SoldSeatsRevenue; $c3.NumberFormat = "#,##0.00"
  $c4 = $ws.Cells.Item($r,4); $c4.Value2 = [double]$row.Sales_SoldSeatsRevenue; $c4.NumberFormat = "#,##0.00"
  $c5 = $ws.Cells.Item($r,5); $c5.Value2 = [double]$row.Difference_PPR_minus_Sales; $c5.NumberFormat = "#,##0.00"
  if ([math]::Abs([double]$row.Difference_PPR_minus_Sales) -gt 1000000000) { $c5.Interior.Color = 0x9999FF }
  $ws.Cells.Item($r,6).Value2 = $row.PPR_Source
  $ws.Cells.Item($r,7).Value2 = $row.Sales_Source
  for ($c=1; $c -le 7; $c++) { $ws.Cells.Item($r,$c).Borders.LineStyle = 1 }
  $r++
}

$ws.Columns.Item("A:G").EntireColumn.AutoFit() | Out-Null

foreach ($p in @($rootPath, $desktopPath)) {
  if (Test-Path $p) { Remove-Item $p -Force }
  $wb.SaveAs($p, 51)
  Write-Host "Excel written: $p"
}
$wb.Close($false)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
