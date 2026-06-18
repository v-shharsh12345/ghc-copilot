# Visual Builder Functions — Full Implementations

Copy these into your PowerShell script. Replace `<TABLE>` with your semantic model entity name.

## MakeHeader (Textbox with dark background)

```powershell
function MakeHeader($text, $x, $y, $w, $h) {
    $v = VID
    return @{ vid=$v; json=@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json"
        name=$v
        position=@{ x=$x; y=$y; z=9000; height=$h; width=$w; tabOrder=9000 }
        visual=@{
            visualType="textbox"
            objects=@{ general=@(@{ properties=@{ paragraphs=@(@{ textRuns=@(@{
                value=$text
                textStyle=@{ fontFamily="Segoe UI Semibold"; fontSize="16px"; color="#FFFFFF" }
            }) }) } }) }
            visualContainerObjects=@{
                background=@(@{ properties=@{
                    color       = @{ solid=@{ color=@{ expr=@{ Literal=@{ Value="'#1B3A5C'" } } } } }
                    transparency= @{ expr=@{ Literal=@{ Value="0D" } } }
                } })
                border =@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="false" } } } } })
                padding=@(@{ properties=@{ top=@{ expr=@{ Literal=@{ Value="6D" } } }; left=@{ expr=@{ Literal=@{ Value="14D" } } } } })
            }
        }
    }}
}
```

## MakeBarChart (Clustered Bar — horizontal)

```powershell
function MakeBarChart($catCol, $measure, $title, $x, $y, $w, $h, $z, $color) {
    if (-not $color) { $color = "'#2E75B6'" }
    $v = VID
    return @{ vid=$v; json=@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json"
        name=$v
        position=@{ x=$x; y=$y; z=$z; height=$h; width=$w; tabOrder=$z }
        visual=@{
            visualType="clusteredBarChart"
            query=@{
                queryState=@{
                    Category=@{ projections=@(@{ field=@{ Column=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$catCol } }; queryRef="<TABLE>.$catCol"; nativeQueryRef=$catCol; active=$true }) }
                    Y=@{ projections=@(@{ field=@{ Measure=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$measure } }; queryRef="<TABLE>.$measure"; nativeQueryRef=$measure }) }
                }
                sortDefinition=@{ sort=@(@{ field=@{ Measure=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$measure } }; direction="Descending" }); isDefaultSort=$true }
            }
            objects=@{
                dataPoint=@(@{ properties=@{ fill=@{ solid=@{ color=@{ expr=@{ Literal=@{ Value=$color } } } } } } })
                labels=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; fontSize=@{ expr=@{ Literal=@{ Value="9D" } } } } })
            }
            visualContainerObjects=@{
                border=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; color=@{ solid=@{ color=@{ expr=@{ Literal=@{ Value="'#E0E0E0'" } } } } }; radius=@{ expr=@{ Literal=@{ Value="8D" } } } } })
                title=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; text=@{ expr=@{ Literal=@{ Value="'$title'" } } }; fontSize=@{ expr=@{ Literal=@{ Value="12D" } } } } })
            }
        }
    }}
}
```

## MakeColumnChart (Clustered Column — vertical)

```powershell
function MakeColumnChart($catCol, $measure, $title, $x, $y, $w, $h, $z, $color) {
    if (-not $color) { $color = "'#118DFF'" }
    $v = VID
    return @{ vid=$v; json=@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json"
        name=$v
        position=@{ x=$x; y=$y; z=$z; height=$h; width=$w; tabOrder=$z }
        visual=@{
            visualType="clusteredColumnChart"
            query=@{ queryState=@{
                Category=@{ projections=@(@{ field=@{ Column=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$catCol } }; queryRef="<TABLE>.$catCol"; nativeQueryRef=$catCol; active=$true }) }
                Y=@{ projections=@(@{ field=@{ Measure=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$measure } }; queryRef="<TABLE>.$measure"; nativeQueryRef=$measure }) }
            } }
            objects=@{
                dataPoint=@(@{ properties=@{ fill=@{ solid=@{ color=@{ expr=@{ Literal=@{ Value=$color } } } } } } })
                labels=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; fontSize=@{ expr=@{ Literal=@{ Value="8D" } } } } })
            }
            visualContainerObjects=@{
                border=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; radius=@{ expr=@{ Literal=@{ Value="8D" } } } } })
                title=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; text=@{ expr=@{ Literal=@{ Value="'$title'" } } }; fontSize=@{ expr=@{ Literal=@{ Value="12D" } } } } })
            }
        }
    }}
}
```

## MakeLineChart (supports multiple measures)

```powershell
function MakeLineChart($catCol, $measures, $title, $x, $y, $w, $h, $z) {
    $v = VID
    $yProj = @()
    foreach ($m in $measures) {
        $yProj += @{
            field=@{ Measure=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$m } }
            queryRef="<TABLE>.$m"; nativeQueryRef=$m
        }
    }
    return @{ vid=$v; json=@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json"
        name=$v
        position=@{ x=$x; y=$y; z=$z; height=$h; width=$w; tabOrder=$z }
        visual=@{
            visualType="lineChart"
            query=@{ queryState=@{
                Category=@{ projections=@(@{ field=@{ Column=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$catCol } }; queryRef="<TABLE>.$catCol"; nativeQueryRef=$catCol; active=$true }) }
                Y=@{ projections=$yProj }
            } }
            visualContainerObjects=@{
                border=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; radius=@{ expr=@{ Literal=@{ Value="8D" } } } } })
                title=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; text=@{ expr=@{ Literal=@{ Value="'$title'" } } }; fontSize=@{ expr=@{ Literal=@{ Value="12D" } } } } })
            }
        }
    }}
}
```

## MakeDonut

```powershell
function MakeDonut($catCol, $measure, $title, $x, $y, $w, $h, $z) {
    $v = VID
    return @{ vid=$v; json=@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json"
        name=$v
        position=@{ x=$x; y=$y; z=$z; height=$h; width=$w; tabOrder=$z }
        visual=@{
            visualType="donutChart"
            query=@{
                queryState=@{
                    Category=@{ projections=@(@{ field=@{ Column=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$catCol } }; queryRef="<TABLE>.$catCol"; nativeQueryRef=$catCol; active=$true }) }
                    Y=@{ projections=@(@{ field=@{ Measure=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$measure } }; queryRef="<TABLE>.$measure"; nativeQueryRef=$measure }) }
                }
                sortDefinition=@{ sort=@(@{ field=@{ Measure=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$measure } }; direction="Descending" }); isDefaultSort=$true }
            }
            objects=@{
                legend=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; position=@{ expr=@{ Literal=@{ Value="'Right'" } } }; fontSize=@{ expr=@{ Literal=@{ Value="9D" } } } } })
                labels=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; labelStyle=@{ expr=@{ Literal=@{ Value="'Data value, percent of total'" } } }; fontSize=@{ expr=@{ Literal=@{ Value="8D" } } } } })
            }
            visualContainerObjects=@{
                border=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; radius=@{ expr=@{ Literal=@{ Value="8D" } } } } })
                title=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; text=@{ expr=@{ Literal=@{ Value="'$title'" } } }; fontSize=@{ expr=@{ Literal=@{ Value="12D" } } } } })
                background=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; color=@{ solid=@{ color=@{ expr=@{ Literal=@{ Value="'#FFFFFF'" } } } } } } })
            }
        }
    }}
}
```

## MakeTable (Matrix / Table visual)

```powershell
function MakeTable($columns, $measures, $title, $x, $y, $w, $h, $z) {
    $v = VID
    $colProj = @(); $i = 0
    foreach ($c in $columns) {
        $colProj += @{ field=@{ Column=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$c } }; queryRef="<TABLE>.$c"; nativeQueryRef=$c; active=$true }
        $i++
    }
    $valProj = @()
    foreach ($m in $measures) {
        $valProj += @{ field=@{ Measure=@{ Expression=@{ SourceRef=@{ Entity="<TABLE>" } }; Property=$m } }; queryRef="<TABLE>.$m"; nativeQueryRef=$m }
    }
    return @{ vid=$v; json=@{
        '$schema' = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.7.0/schema.json"
        name=$v; position=@{ x=$x; y=$y; z=$z; height=$h; width=$w; tabOrder=$z }
        visual=@{
            visualType="tableEx"
            query=@{ queryState=@{ Values=@{ projections=($colProj + $valProj) } } }
            visualContainerObjects=@{
                title=@(@{ properties=@{ show=@{ expr=@{ Literal=@{ Value="true" } } }; text=@{ expr=@{ Literal=@{ Value="'$title'" } } } } })
            }
        }
    }}
}
```

## Color Palette Reference

| Purpose | Hex | PBIR Value |
|---------|-----|------------|
| Header bg | #1B3A5C | `"'#1B3A5C'"` |
| Primary blue | #118DFF | `"'#118DFF'"` |
| Bar chart | #2E75B6 | `"'#2E75B6'"` |
| Orange accent | #E66C37 | `"'#E66C37'"` |
| Success green bg | #E8F5E9 | `"'#E8F5E9'"` |
| Success green text | #1B5E20 | `"'#1B5E20'"` |
| Info blue bg | #E3F2FD | `"'#E3F2FD'"` |
| Info blue text | #0D47A1 | `"'#0D47A1'"` |
| Purple accent bg | #F3E5F5 | `"'#F3E5F5'"` |
| Warning orange bg | #FFF3E0 | `"'#FFF3E0'"` |
| Card border | #E0E0E0 | `"'#E0E0E0'"` |
| Secondary card bg | #F8F9FA | `"'#F8F9FA'"` |
| Dark text | #333333 | `"'#333333'"` |
| Muted text | #666666 | `"'#666666'"` |
