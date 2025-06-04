#!/usr/bin/env pwsh
#
# Powershell script.
# Get-WinBoxSaves.ps1
# For those who "forget" logins. Reads the winbox save database.
# Outputs logins and passwords from an unencrypted database.
#
# Usage 
# .\Get-WinboxSaves.ps1  [-Help] [-Dialog] [-Path] [-Console] [-HTML] [-HTMLPath]
#    -Help     - Show help.
#    -Dialog   - Only for OS MS Windows. Open "File open dialog" window. 
#    -Path     - Full path to Winbox save file (usually "Addresses.cdb").
#    -Console  - Only for OS MS Windows. Output to console. Don't open result window.
#    -HTML     - Write output result to html file and open brouser.
#    -HTMLPath - Full path to .html file. If missing set to "ScriptName.html". Path same with script.

param (
    [string] $Path,
    [string] $HTMLPath,
    [switch] $Dialog,
    [switch] $Help,
    [switch] $HTML,
    [switch] $Console )

# function -----------------------------------------------------------------------------------------------------------------
function ConvertTo-HtmlFile {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [string]$Title = "Данные",
        [string]$CssStyle,
        [switch]$PreContent,
        [switch]$PostContent
    )
    
    begin { $allObjects = @() }
    
    process { $allObjects += $InputObject  }
    
    end {
        # Генерируем HTML заголовок
        $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>$Title</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th { background-color: #f2f2f2; text-align: left; padding: 8px; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f1f1; }
        $CssStyle
    </style>
</head>
<body>
"@

        # Генерируем HTML подвал
        $htmlFooter = @"
</body>
</html>
"@

        # Конвертируем объекты в HTML
        $htmlContent = $allObjects | ConvertTo-Html -Fragment
        
        # Собираем полный HTML
        $fullHtml = $htmlHeader
        
        if ($PreContent) {
            $fullHtml += "<h1>$Title</h1>"
            $fullHtml += "<p>Сгенерировано: $(Get-Date)</p>"
        }
        
        $fullHtml += $htmlContent
        
        if ($PostContent) {
            $fullHtml += "<p>Всего записей: $($allObjects.Count)</p>"
        }
        
        $fullHtml += $htmlFooter
        
        # Сохраняем в файл
        $fullHtml | Out-File -FilePath $FilePath -Encoding utf8
        
        Write-Host "HTML файл сохранен в: $FilePath"
    }
}

# function -----------------------------------------------------------------------------------------------------------------
# Функция для обновления DataGridView с новыми данными
function Update-DataGridView {
    param(
        [System.Windows.Forms.DataGridView]$GridView,
        [PSObject[]]$Data
    )
    
    $GridView.Rows.Clear()
    $GridView.Columns.Clear()
    
    if ($Data.Count -eq 0) { return }
    
    # Получаем свойства первого объекта как образец
    $properties = $Data[0].PSObject.Properties.Name
    
    # Создаем колонки
    foreach ($prop in $properties) {
        $col = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $col.Name = $prop
        $col.HeaderText = $prop
        $GridView.Columns.Add($col) | Out-Null
    }
    
    # Добавляем строки
    foreach ($item in $Data) {
        $rowValues = @()
        foreach ($prop in $properties) {
            $rowValues += $item.$prop
        }
        $GridView.Rows.Add($rowValues) | Out-Null
    }
    
    # Автоподбор ширины колонок
    $GridView.AutoResizeColumns([System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells)
}

# function -----------------------------------------------------------------------------------------------------------------
function Create-Form {
    param(  [PSObject[]]$Data  )

 # Создаем форму
 $form = New-Object System.Windows.Forms.Form
 $form.Text = "Read WINBOX saves. Use - $filename"
 $form.Size = New-Object System.Drawing.Size(800, 600)
 $form.StartPosition = "CenterScreen"

 # Создаем DataGridView
 $grid = New-Object System.Windows.Forms.DataGridView
 $grid.Dock = [System.Windows.Forms.DockStyle]::Fill
 $grid.AllowUserToAddRows = $false
 $grid.ReadOnly = $true
 $grid.AutoSizeColumnsMode = 'AllCells'
 $grid.SelectionMode = 'CellSelect'
 $grid.MultiSelect = $false

 # Панель для кнопок
 $panel = New-Object System.Windows.Forms.Panel
 $panel.Dock = [System.Windows.Forms.DockStyle]::Bottom
 $panel.Height = 40

 # Кнопка копирования
 $copyButton = New-Object System.Windows.Forms.Button
 $copyButton.Text = "Копировать выбранное значение"
 $copyButton.Dock = [System.Windows.Forms.DockStyle]::Fill
 $copyButton.Enabled = $false

 $panel.Controls.Add($copyButton)
 $form.Controls.Add($grid)
 #$form.Controls.Add($panel)

	# Контекстное меню для правой кнопки мыши
	$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
	$copyMenu = $contextMenu.Items.Add("Копировать значение")
	$copyMenu.Add_Click({
		if ($grid.SelectedCells.Count -gt 0) {
			$selectedCell = $grid.SelectedCells[0]
			$valueToCopy = $selectedCell.Value.ToString()
			[System.Windows.Forms.Clipboard]::SetText($valueToCopy)
			
			$toolTip = New-Object System.Windows.Forms.ToolTip
			$toolTip.Show("Значение скопировано: $valueToCopy", $grid, 
						 $grid.GetCellDisplayRectangle($selectedCell.ColumnIndex, $selectedCell.RowIndex, $false).Location, 
						 1500)
		}
	})
	$grid.ContextMenuStrip = $contextMenu

Update-DataGridView -GridView $grid -Data $data
$form.ShowDialog() | Out-Null
exit
}

# function -----------------------------------------------------------------------------------------------------------------
function Show-FileOpenDialog {
    param (
        [string]$Title = "Выберите файл",
        [string]$InitialDirectory = [Environment]::GetFolderPath('MyDocuments'),
        [string]$Filter = "Все файлы (*.*)|*.*",
        [switch]$MultiSelect
    )

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $Title
    $openFileDialog.InitialDirectory = $InitialDirectory
    $openFileDialog.Filter = $Filter
    $openFileDialog.Multiselect = $MultiSelect

    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($MultiSelect) {
            return $openFileDialog.FileNames
        } else {
            return $openFileDialog.FileName
        }
    }
    return $null
}
# function -----------------------------------------------------------------------------------------------------------------
$global:helpout = $false
function Write-Help
{
 if ( -not $global:helpout)
 {

   Write-Host '
  Usage 
 .\Get-WinboxSaves.ps1  [-Help] [-Dialog] [-Path] [-Console] [-HTML] [-HTMLPath]
    -Help     - Show help.
    -Dialog   - Only for OS MS Windows. Open "File open dialog" window. 
    -Path     - Full path to Winbox save file (usually "Addresses.cdb").
    -Console  - Only for OS MS Windows. Output to console. Don''t open result window.
    -HTML     - Write output result to html file and open brouser.
    -HTMLPath - Full path to .html file. If missing set to "ScriptName.html". Path same with script. '

   $global:helpout = $true
  }
}

# MAIN function -----------------------------------------------------------------------------------------------------------------
$WinOS = [System.Environment]::OSVersion.Platform -like "Win*"
if ($console)  { $WinOS=$false }

if ($WinOS) { Add-Type -AssemblyName System.Windows.Forms }

if ($help)  { Write-Help }

if ($dialog -and $WinOS)  {$filename = Show-FileOpenDialog -InitialDirectory "$env:APPDATA\mikrotik\winbox" }
                     else { $filename = "$env:APPDATA\mikrotik\winbox\Addresses.cdb" }

if ($path) { $filename=$path} 
   else {
     if (-not $winOS) {
         Write-Help
         exit 1
        }
   }

if (-not $filename) {
    Write-Help
    exit 1
}

if ( -not (Test-Path -Path $filename) )
  {  if ($WinOS) {
         $filename = Show-FileOpenDialog -InitialDirectory "$env:APPDATA\mikrotik\winbox"
         if ( $filename -eq $NULL) { exit 1 }
         }
     else { write-host "File not found $path"
            write-help
            exit 1 }      
  }

#write-host " USe file $filename"
# Addresses.cdb file signature
$signature = [byte[]](0x0d, 0xf0, 0x1d, 0xc0)

# Block signature
$M2 = [byte[]](0x4d, 0x32)

# Data types
$MT_DWORD = 0x08
$MT_BOOL_FALSE = 0x00
$MT_BOOL_TRUE = 0x01
$MT_ARRAY = 0x88
$MT_STRING = 0x21
$MT_BYTE = 0x09
$MT_BOOL = @{
    $MT_BOOL_FALSE = $false
    $MT_BOOL_TRUE = $true
}

# Addressbook field names
$ADDR_BOOK_FIELD = @{
    1 = 'host'
    2 = 'login'
    3 = 'password'
    4 = 'note'
    6 = 'session'
    8 = 'group'
    11 = 'romonagent'
}

$allr = @()

try {
    $content = [System.IO.File]::ReadAllBytes($filename)
}
catch {
    Write-Host "Error reading file: $_"
    exit 1
}

$ptr = 0
$fSig = $content[$ptr..($ptr+3)]

if ( ($fsig[0] -ne $signature[0]) -or ($fsig[1] -ne $signature[1]) -or ($fsig[2] -ne $signature[2]) -or ($fsig[3] -ne $signature[3])  )
{
    Write-Host "Bad signature in $filename"
    exit 1
}

$ptr += 4
$block_no = 0
while ($ptr -lt $content.Length) {
    $block_size = [System.BitConverter]::ToUInt32($content, $ptr)
    #Write-Host "Record #$block_no"
    $ptr += 4
    
    $blockSignature = $content[$ptr..($ptr+1)]
    if ( ($blockSignature[0] -ne $M2[0]) -or ($blockSignature[1] -ne $M2[1])  ) {
        Write-Host "Bad block #$block_no"
        exit 1
    }
    
    $block_start = $ptr
    $ptr += 2
    $CredRC = [PSCustomObject]@{
              Host       = ""
              Login      = ""
              Password   = ""
              Note       = ""
              Group      = ""
              Session    = ""
              romonagent = ""
             }

    while ($ptr -lt ($block_size + $block_start)) {
        # Read 3 bytes and add a zero byte to make it 4 bytes for UInt32
        $record_code_bytes = $content[$ptr..($ptr+2)] + [byte]0
        $record_code = [System.BitConverter]::ToUInt32($record_code_bytes, 0)
        $ptr += 3
        
        $record_type = $content[$ptr]
        $ptr += 1
        
        # Skip records with the following types: DWORD, BYTE, ARRAY
        switch ($record_type) {
            $MT_DWORD { $ptr += 4 }
            $MT_BYTE { $ptr += 1 }
            $MT_BOOL_FALSE { }
            $MT_BOOL_TRUE { }
            $MT_ARRAY {
                $length = [System.BitConverter]::ToUInt16($content, $ptr)
                $ptr += 2
                $element = 0
                while ($element -lt $length) {
                    $element += 1
                    $ptr += 4
                }
            }
            $MT_STRING {
                $length = $content[$ptr]
                $ptr += 1
                $value = $content[$ptr..($ptr+$length-1)]
                $ptr += $length
                try {
                    $decoded_value = [System.Text.Encoding]::UTF8.GetString($value)
                }
                catch {
                    $decoded_value = $value -join ','
                }
                [int]$rc = $record_code 
                if ($ADDR_BOOK_FIELD.ContainsKey($rc) ) {
                    #Write-Host "$($ADDR_BOOK_FIELD[$rc]) = $decoded_value"
                    [string]$rname=$ADDR_BOOK_FIELD[$rc]
                    $CredRC.$rname =   $decoded_value
                }
            }
        }
    }
    $allr = $allr + $CredRC
    $block_no += 1
}

if ($WinOS) { Create-form -data $allr }
       else { $allr | ft }

if ($html)  { 
   if ($HTMLPath) { $htmlfilename = $HTMLPath }
      else {
         $htmlfilename = $PSCommandPath + ".html"
      }
   $winOS = [System.Environment]::OSVersion.Platform -like "Win*"
   $allr | ConvertTo-HtmlFile -FilePath $htmlfilename
   if ($winos) { Start-Process $htmlfilename }
          else { if (Test-Path /usr/bin/xdg-open) { xdg-open $htmlfilename > /dev/null 2>&1 } }
   }