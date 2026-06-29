# powershell -ExecutionPolicy Bypass -File \\wsl$\Ubuntu\home\${env:USERNAME}\dotfiles\tools\symlinkwsl.ps1

function Link-Items {
    param([string]$Source, [string]$Destination)
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        $link = Join-Path $Destination $_.Name
        if ($_.PSIsContainer) {
            if (Test-Path $link) {
                Link-Items -Source $_.FullName -Destination $link
            } else {
                New-Item -ItemType SymbolicLink -Path $link -Target $_.FullName | Out-Null
                Write-Host "Linked: $link -> $($_.FullName)"
            }
        } else {
            if (Test-Path $link) {
                Write-Host "Skipping (already exists): $link"
            } else {
                New-Item -ItemType SymbolicLink -Path $link -Target $_.FullName | Out-Null
                Write-Host "Linked: $link -> $($_.FullName)"
            }
        }
    }
}

$src = "\\wsl$\Ubuntu\home\${env:USERNAME}\dotfiles\komorebi"
$dst = "C:\Users\${env:USERNAME}"
Link-Items -Source $src -Destination $dst

$src = "\\wsl$\Ubuntu\home\${env:USERNAME}\dotfiles\rio\windows"
$dst = "$env:USERPROFILE\AppData\Local\rio\"
Link-Items -Source $src -Destination $dst
