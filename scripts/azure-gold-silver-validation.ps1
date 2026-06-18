$ErrorActionPreference = "Stop"

$csv = "scripts\source1-gold-vs-silver-notebook-query-normalized.csv"
$outPath = (Resolve-Path ".").Path + "\Azure_Gold_vs_Silver_Validation.xlsx"
$desktop = [Environment]::GetFolderPath("Desktop") + "\Azure_Gold_vs_Silver_Validation.xlsx"

$data = Import-Csv $csv

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "Validation"

# Title
$ws.Cells.Item(1,1).Value2 = "Azure Source - Gold vs Silver Data Validation"
$ws.Range("A1:H1").Merge() | Out-Null
$ws.Range("A1:H1").Font.Bold = $true
$ws.Range("A1:H1").Font.Size = 14
$ws.Range("A1:H1").Interior.Color = 0x1F4E78
$ws.Range("A1:H1").Font.Color = 0xFFFFFF
$ws.Range("A1:H1").HorizontalAlignment = -4108

# Metadata
$ws.Cells.Item(2,1).Value2 = "Gold Schema:"
$ws.Cells.Item(2,1).Font.Bold = $true
$ws.Cells.Item(2,2).Value2 = [string]$data[0].GoldSchema
$ws.Cells.Item(2,4).Value2 = "Silver Schema:"
$ws.Cells.Item(2,4).Font.Bold = $true
$ws.Cells.Item(2,5).Value2 = "Silver"
$ws.Cells.Item(2,7).Value2 = "BillingMonthID:"
$ws.Cells.Item(2,7).Font.Bold = $true
$ws.Cells.Item(2,8).Value2 = [double]$data[0].BillingMonthID

# Headers
$headers = @("BillingMonthID","Association Type","Gold Value","Silver Value","Difference (Gold-Silver)","Diff %","Match Status")
for ($i = 0; $i -lt $headers.Count; $i++) {
  $c = $ws.Cells.Item(4, $i+1)
  $c.Value2 = $headers[$i]
  $c.Font.Bold = $true
  $c.Interior.Color = 0x203864
  $c.Font.Color = 0xFFFFFF
  $c.Borders.LineStyle = 1
  $c.HorizontalAlignment = -4108
}

$matchCount = 0; $goldOnly = 0; $silverOnly = 0; $mismatch = 0
$row = 5
foreach ($d in $data) {
  $g  = if ($d.GoldValue   -ne "") { [double]$d.GoldValue }   else { $null }
  $s  = if ($d.SilverValue -ne "") { [double]$d.SilverValue } else { $null }
  $df = if ($g -ne $null -and $s -ne $null) { $g - $s } else { $null }
  $pct = if ($g -ne $null -and $s -ne $null -and $s -ne 0) { ($g - $s) / [Math]::Abs($s) * 100 } else { $null }

  $status = if ($g -eq $null) { $silverOnly++; "Silver Only" }
            elseif ($s -eq $null) { $goldOnly++; "Gold Only" }
            elseif ($null -ne $df -and [Math]::Abs($df) -lt 1) { $matchCount++; "Match" }
            else { $mismatch++; "Mismatch" }

  $ws.Cells.Item($row,1).Value2 = [double]$d.BillingMonthID
  $ws.Cells.Item($row,2).Value2 = [string]$d.AssociationType
  if ($null -ne $g) { $c3=$ws.Cells.Item($row,3); $c3.Value2=[double]$g; $c3.NumberFormat="#,##0.00" }
  if ($null -ne $s) { $c4=$ws.Cells.Item($row,4); $c4.Value2=[double]$s; $c4.NumberFormat="#,##0.00" }
  if ($null -ne $df) { $c5=$ws.Cells.Item($row,5); $c5.Value2=[double]$df; $c5.NumberFormat="#,##0.00" }
  if ($null -ne $pct) { $c6=$ws.Cells.Item($row,6); $c6.Value2=[double]$pct; $c6.NumberFormat="0.0000%" }

  $sc = $ws.Cells.Item($row,7)
  $sc.Value2 = $status
  $sc.Font.Bold = $true
  if     ($status -eq "Match")       { $sc.Interior.Color = 0xC6EFCE; $sc.Font.Color = 0x276221 }
  elseif ($status -eq "Mismatch")    { $sc.Interior.Color = 0xFFC7CE; $sc.Font.Color = 0x9C0006 }
  else                               { $sc.Interior.Color = 0xFFEB9C; $sc.Font.Color = 0x9C6500 }

  for ($j=1; $j -le 7; $j++) { $ws.Cells.Item($row,$j).Borders.LineStyle = 1 }
  $row++
}

# Summary
$row += 1
$ws.Cells.Item($row,1).Value2 = "Summary"
$ws.Cells.Item($row,1).Font.Bold = $true
$ws.Cells.Item($row,1).Font.Size = 12

$row++
$ws.Cells.Item($row,1).Value2 = "Total Rows"
$ws.Cells.Item($row,2).Value2 = [double]($data.Count)

$row++
$ws.Cells.Item($row,1).Value2 = "Matching"
$ws.Cells.Item($row,2).Value2 = [double]$matchCount
$ws.Cells.Item($row,2).Font.Color = 0x276221
$ws.Cells.Item($row,2).Font.Bold = $true

$row++
$ws.Cells.Item($row,1).Value2 = "Mismatch"
$ws.Cells.Item($row,2).Value2 = [double]$mismatch
$ws.Cells.Item($row,2).Font.Color = 0x9C0006
$ws.Cells.Item($row,2).Font.Bold = $true

$row++
$ws.Cells.Item($row,1).Value2 = "Gold Only"
$ws.Cells.Item($row,2).Value2 = [double]$goldOnly
$ws.Cells.Item($row,2).Font.Color = 0x9C6500

$row++
$ws.Cells.Item($row,1).Value2 = "Silver Only"
$ws.Cells.Item($row,2).Value2 = [double]$silverOnly
$ws.Cells.Item($row,2).Font.Color = 0x9C6500

$ws.Columns.Item("A:H").EntireColumn.AutoFit() | Out-Null

if (Test-Path $outPath) { Remove-Item $outPath -Force }
$wb.SaveAs($outPath, 51)
$wb.Close($false)
$excel.Quit()
foreach ($o in @($ws,$wb,$excel)) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($o) | Out-Null }
[GC]::Collect(); [GC]::WaitForPendingFinalizers()
Copy-Item $outPath $desktop -Force
Write-Host "Excel written: $outPath"
Write-Host "Copied to: $desktop"
