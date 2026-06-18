$ErrorActionPreference = "Stop"

$csv = Import-Csv "scripts\factmarketdb-nceflag-results.csv"
$outPath = (Resolve-Path ".").Path + "\FactMarketDB_NCEFlag_Counts.xlsx"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "FactMarketDB NCEFlag"

# Title
$ws.Cells.Item(1,1) = "FactMarketDB - Count where NCEFlag = 'Yes'"
$title = $ws.Range("A1:H1")
$title.Merge()
$title.Font.Bold = $true
$title.Font.Size = 14
$title.Interior.Color = 0x7A3B00
$title.Font.Color = 0xFFFFFF
$title.HorizontalAlignment = -4108

# Headers
$headers = @("Source","Database","Schema","Table","Fully Qualified","Filter","Record Count","Query Run (UTC)")
$hrow = 3
for ($c = 0; $c -lt $headers.Count; $c++) {
  $cell = $ws.Cells.Item($hrow, $c+1)
  $cell.Value2 = $headers[$c]
  $cell.Font.Bold = $true
  $cell.Interior.Color = 0xD9D9D9
  $cell.Borders.LineStyle = 1
}

# Data rows
$r = $hrow + 1
foreach ($row in $csv) {
  $ws.Cells.Item($r,1).Value2 = $row.Source
  $ws.Cells.Item($r,2).Value2 = $row.Database
  $ws.Cells.Item($r,3).Value2 = $row.Schema
  $ws.Cells.Item($r,4).Value2 = $row.Table
  $ws.Cells.Item($r,5).Value2 = $row.FullyQualified
  $ws.Cells.Item($r,6).Value2 = $row.Filter
  $cntCell = $ws.Cells.Item($r,7)
  $cntCell.Value2 = [double]$row.RecordCount
  $cntCell.NumberFormat = "#,##0"
  $ws.Cells.Item($r,8).Value2 = $row.QueryRunUTC
  for ($c=1; $c -le 8; $c++) { $ws.Cells.Item($r,$c).Borders.LineStyle = 1 }
  $r++
}

$ws.Columns.Item("A:H").EntireColumn.AutoFit() | Out-Null

if (Test-Path $outPath) { Remove-Item $outPath -Force }
$wb.SaveAs($outPath, 51)  # 51 = xlOpenXMLWorkbook (.xlsx)
$wb.Close($false)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
[GC]::Collect(); [GC]::WaitForPendingFinalizers()

Write-Host "Excel written: $outPath"
