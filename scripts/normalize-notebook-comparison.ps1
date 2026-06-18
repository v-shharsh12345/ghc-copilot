$ErrorActionPreference = "Stop"

$inCsv = "scripts\source1-gold-vs-silver-notebook-query.csv"
$outCsv = "scripts\source1-gold-vs-silver-notebook-query-normalized.csv"
$outXlsx = (Resolve-Path ".").Path + "\Source1_Gold_vs_Silver_NotebookQuery_Normalized.xlsx"
$desktopXlsx = [Environment]::GetFolderPath("Desktop") + "\Source1_Gold_vs_Silver_NotebookQuery_Normalized.xlsx"

$data = Import-Csv $inCsv

$exclude = @("TPOR-DIR","TPOR-IND","TPOR-SOA")

function Normalize-AssociationType {
  param([string]$v)
  if ($null -eq $v) { return "" }
  $x = $v.Trim()
  $x = $x -replace '^CSP\s+Tier\s+1$', 'CSP Tier1'
  $x = $x -replace '^CSP\s+Tier\s+2$', 'CSP Tier2'
  return $x
}

$prepped = foreach ($r in $data) {
  $atype = Normalize-AssociationType -v $r.AssociationType
  if ($exclude -contains $atype) { continue }

  [PSCustomObject]@{
    BillingMonthID = [int]$r.BillingMonthID
    AssociationType = $atype
    GoldValue = if ($r.GoldValue -ne "") { [double]$r.GoldValue } else { $null }
    SilverValue = if ($r.SilverValue -ne "") { [double]$r.SilverValue } else { $null }
    GoldSchema = [string]$r.GoldSchema
  }
}

$grouped = $prepped | Group-Object BillingMonthID, AssociationType, GoldSchema
$tmpOut = foreach ($g in $grouped) {
  $first = $g.Group | Select-Object -First 1
  $sumGold = ($g.Group | Measure-Object -Property GoldValue -Sum).Sum
  $sumSilver = ($g.Group | Measure-Object -Property SilverValue -Sum).Sum

  [PSCustomObject]@{
    BillingMonthID = $first.BillingMonthID
    AssociationType = $first.AssociationType
    GoldValue = if ($null -ne $sumGold) { [double]$sumGold } else { $null }
    SilverValue = if ($null -ne $sumSilver) { [double]$sumSilver } else { $null }
    Difference_GoldMinusSilver = if ($null -ne $sumGold -and $null -ne $sumSilver) { [double]$sumGold - [double]$sumSilver } else { $null }
    GoldSchema = $first.GoldSchema
  }
}

$out = $tmpOut | Sort-Object BillingMonthID, AssociationType

$out | Export-Csv $outCsv -NoTypeInformation -Encoding UTF8
Write-Host "Saved CSV: $outCsv"
$out | Format-Table -AutoSize

# Excel export
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "Normalized Compare"

$headers = @("BillingMonthID","AssociationType","GoldValue","SilverValue","Difference (Gold-Silver)","GoldSchema")
for ($i=0; $i -lt $headers.Count; $i++) {
  $c = $ws.Cells.Item(1,$i+1)
  $c.Value2 = $headers[$i]
  $c.Font.Bold = $true
  $c.Interior.Color = 0xD9D9D9
  $c.Borders.LineStyle = 1
}

$row = 2
foreach ($d in $out) {
  $ws.Cells.Item($row,1).Value2 = [double]$d.BillingMonthID
  $ws.Cells.Item($row,2).Value2 = [string]$d.AssociationType
  if ($null -ne $d.GoldValue) { $ws.Cells.Item($row,3).Value2 = [double]$d.GoldValue }
  if ($null -ne $d.SilverValue) { $ws.Cells.Item($row,4).Value2 = [double]$d.SilverValue }
  if ($null -ne $d.Difference_GoldMinusSilver) { $ws.Cells.Item($row,5).Value2 = [double]$d.Difference_GoldMinusSilver }
  $ws.Cells.Item($row,6).Value2 = [string]$d.GoldSchema

  $ws.Cells.Item($row,3).NumberFormat = "#,##0.00"
  $ws.Cells.Item($row,4).NumberFormat = "#,##0.00"
  $ws.Cells.Item($row,5).NumberFormat = "#,##0.00"
  for ($j=1; $j -le 6; $j++) { $ws.Cells.Item($row,$j).Borders.LineStyle = 1 }
  $row++
}

$ws.Columns.Item("A:F").EntireColumn.AutoFit() | Out-Null
if (Test-Path $outXlsx) { Remove-Item $outXlsx -Force }
$wb.SaveAs($outXlsx, 51)
$wb.Close($false)
$excel.Quit()
foreach ($o in @($ws,$wb,$excel)) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($o) | Out-Null }
[GC]::Collect(); [GC]::WaitForPendingFinalizers()

Copy-Item $outXlsx $desktopXlsx -Force
Write-Host "Excel written: $outXlsx"
Write-Host "Copied to: $desktopXlsx"
