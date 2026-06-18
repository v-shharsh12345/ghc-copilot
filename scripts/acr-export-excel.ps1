$ErrorActionPreference = "Stop"

$src1 = Import-Csv "scripts\acr-src1.csv"
$src2 = Import-Csv "scripts\acr-src2.csv"
$outPath = (Resolve-Path ".").Path + "\ACR_By_FiscalMonth_TwoSources.xlsx"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()

function Set-Num { param($cell, $val, $fmt)
  if ($null -ne $val -and "$val" -ne "") { $cell.Value2 = [double]$val }
  $cell.NumberFormat = $fmt
}

function Write-Sheet {
  param($ws, $title, $data)
  $ws.Cells.Item(1,1).Value2 = $title
  $t = $ws.Range("A1:C1"); $t.Merge(); $t.Font.Bold = $true; $t.Font.Size = 12
  $t.Interior.Color = 0x7A3B00; $t.Font.Color = 0xFFFFFF; $t.HorizontalAlignment = -4108
  $headers = @("FiscalMonthID","FiscalMonthName","ACR")
  for ($c=0; $c -lt 3; $c++) {
    $cell = $ws.Cells.Item(3, $c+1); $cell.Value2 = $headers[$c]
    $cell.Font.Bold = $true; $cell.Interior.Color = 0xD9D9D9; $cell.Borders.LineStyle = 1
  }
  $r = 4
  foreach ($row in $data) {
    Set-Num $ws.Cells.Item($r,1) $row.FiscalMonthID "0"
    $ws.Cells.Item($r,2).Value2 = [string]$row.FiscalMonthName
    Set-Num $ws.Cells.Item($r,3) $row.ACR "#,##0.00"
    for ($c=1; $c -le 3; $c++) { $ws.Cells.Item($r,$c).Borders.LineStyle = 1 }
    $r++
  }
  $ws.Columns.Item("A:C").EntireColumn.AutoFit() | Out-Null
}

$ws1 = $wb.Worksheets.Item(1); $ws1.Name = "Source1 POSOT_Azure"
Write-Sheet -ws $ws1 -title "Source 1: POSOT_Azure (Fact=Reporting.FactAzureConsumption_Reporting; Map=AzureGold2026061501; Time=POSOT_Integration.IntegrationGold2026061501)" -data $src1

$ws2 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $ws1)
$ws2.Name = "Source2 PPR Warehouse"
Write-Sheet -ws $ws2 -title "Source 2: PPR Warehouse (Gold schema - original query)" -data $src2

$ws3 = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $ws2)
$ws3.Name = "Comparison"
$ws3.Cells.Item(1,1).Value2 = "ACR Comparison by Fiscal Month (Source1 vs Source2)"
$tc = $ws3.Range("A1:E1"); $tc.Merge(); $tc.Font.Bold = $true; $tc.Font.Size = 12
$tc.Interior.Color = 0x1F4E78; $tc.Font.Color = 0xFFFFFF; $tc.HorizontalAlignment = -4108
$ch = @("FiscalMonthID","FiscalMonthName","ACR (Src1 POSOT_Azure)","ACR (Src2 PPR Warehouse)","Difference (Src2-Src1)")
for ($c=0; $c -lt 5; $c++) {
  $cell = $ws3.Cells.Item(3,$c+1); $cell.Value2 = $ch[$c]
  $cell.Font.Bold = $true; $cell.Interior.Color = 0xD9D9D9; $cell.Borders.LineStyle = 1
}
$map2 = @{}
foreach ($row in $src2) { $map2[[string]$row.FiscalMonthID] = $row }
$r = 4
foreach ($row in $src1) {
  $fmKey = [string]$row.FiscalMonthID
  $a1 = if ("$($row.ACR)" -ne "") { [double]$row.ACR } else { $null }
  $a2 = if ($map2.ContainsKey($fmKey) -and "$($map2[$fmKey].ACR)" -ne "") { [double]$map2[$fmKey].ACR } else { $null }
  Set-Num $ws3.Cells.Item($r,1) $row.FiscalMonthID "0"
  $ws3.Cells.Item($r,2).Value2 = [string]$row.FiscalMonthName
  Set-Num $ws3.Cells.Item($r,3) $a1 "#,##0.00"
  Set-Num $ws3.Cells.Item($r,4) $a2 "#,##0.00"
  $diff = if ($null -ne $a1 -and $null -ne $a2) { $a2 - $a1 } else { $null }
  Set-Num $ws3.Cells.Item($r,5) $diff "#,##0.00"
  for ($c=1; $c -le 5; $c++) { $ws3.Cells.Item($r,$c).Borders.LineStyle = 1 }
  $r++
}
$ws3.Columns.Item("A:E").EntireColumn.AutoFit() | Out-Null

$ws1.Activate()
if (Test-Path $outPath) { Remove-Item $outPath -Force }
$wb.SaveAs($outPath, 51)
$wb.Close($false)
$excel.Quit()
foreach ($o in @($ws1,$ws2,$ws3,$wb,$excel)) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($o) | Out-Null }
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
Write-Host "Excel written: $outPath"
