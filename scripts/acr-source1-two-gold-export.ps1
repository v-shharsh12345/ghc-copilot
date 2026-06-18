$ErrorActionPreference = "Stop"

$data = Import-Csv "scripts\acr-source1-gold-latest-vs-prev.csv"
$outPath = (Resolve-Path ".").Path + "\ACR_Source1_Latest_vs_Previous_Gold.xlsx"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "Source1 Gold Compare"

$ws.Cells.Item(1,1).Value2 = "Source1 ACR Comparison - Latest vs Previous Gold Schema"
$ws.Range("A1:G1").Merge() | Out-Null
$ws.Range("A1:G1").Font.Bold = $true
$ws.Range("A1:G1").Font.Size = 13
$ws.Range("A1:G1").HorizontalAlignment = -4108

$headers = @(
  "FiscalMonthID",
  "FiscalMonthName",
  "ACR Latest Gold",
  "ACR Previous Gold",
  "Difference (Latest-Previous)",
  "Latest Gold Schema",
  "Previous Gold Schema"
)
for ($i=0; $i -lt $headers.Count; $i++) {
  $cell = $ws.Cells.Item(3, $i+1)
  $cell.Value2 = $headers[$i]
  $cell.Font.Bold = $true
  $cell.Interior.Color = 0xD9D9D9
  $cell.Borders.LineStyle = 1
}

$row = 4
foreach ($d in $data) {
  $ws.Cells.Item($row,1).Value2 = [double]$d.FiscalMonthID
  $ws.Cells.Item($row,2).Value2 = [string]$d.FiscalMonthName_LatestTime
  $ws.Cells.Item($row,3).Value2 = [double]$d.ACR_LatestGold
  $ws.Cells.Item($row,4).Value2 = [double]$d.ACR_PreviousGold
  $ws.Cells.Item($row,5).Value2 = [double]$d.Difference_LatestMinusPrevious
  $ws.Cells.Item($row,6).Value2 = [string]$d.AzureGold_Latest
  $ws.Cells.Item($row,7).Value2 = [string]$d.AzureGold_Previous

  $ws.Cells.Item($row,3).NumberFormat = "#,##0.00"
  $ws.Cells.Item($row,4).NumberFormat = "#,##0.00"
  $ws.Cells.Item($row,5).NumberFormat = "#,##0.00"

  for ($c=1; $c -le 7; $c++) { $ws.Cells.Item($row,$c).Borders.LineStyle = 1 }
  $row++
}

$ws.Columns.Item("A:G").EntireColumn.AutoFit() | Out-Null

if (Test-Path $outPath) { Remove-Item $outPath -Force }
$wb.SaveAs($outPath, 51)
$wb.Close($false)
$excel.Quit()

foreach ($o in @($ws,$wb,$excel)) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($o) | Out-Null }
[GC]::Collect(); [GC]::WaitForPendingFinalizers()

$desktop = [Environment]::GetFolderPath("Desktop") + "\ACR_Source1_Latest_vs_Previous_Gold.xlsx"
Copy-Item $outPath $desktop -Force

Write-Host "Excel written: $outPath"
Write-Host "Copied to: $desktop"
