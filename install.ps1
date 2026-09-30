# install.ps1 - konfiguruje komende ncd dla PowerShell (5.1 i 7) oraz cmd.
# Uruchom z folderu, w ktorym leza ncd-lib.ps1 i ncd.cmd:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1

$dir = $PSScriptRoot
$lib = Join-Path $dir "ncd-lib.ps1"
$cmd = Join-Path $dir "ncd.cmd"

if (-not (Test-Path -LiteralPath $lib)) { Write-Error "Brak pliku: $lib"; exit 1 }
if (-not (Test-Path -LiteralPath $cmd)) { Write-Error "Brak pliku: $cmd"; exit 1 }

# 1. Zdejmij blokade "pobrane z internetu"
Unblock-File -LiteralPath $lib -ErrorAction SilentlyContinue
Unblock-File -LiteralPath $cmd -ErrorAction SilentlyContinue
Unblock-File -LiteralPath (Join-Path $dir "install.ps1") -ErrorAction SilentlyContinue

# 2. Zezwol na profile lokalne skrypty
try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force }
catch { Write-Warning "Nie udalo sie zmienic ExecutionPolicy: $($_.Exception.Message)" }

# 3. Dodaj folder do PATH uzytkownika (dla cmd)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $userPath) { $userPath = "" }
$entries = $userPath -split ';' | Where-Object { $_ }
if ($entries -notcontains $dir) {
    $newPath = (($entries + $dir) -join ';')
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Dodano do PATH: $dir"
} else {
    Write-Host "Folder jest juz w PATH."
}

# 4. Dopisz wczytanie funkcji do profili Windows PowerShell i PowerShell 7
$docs = [Environment]::GetFolderPath('MyDocuments')
$profiles = @(
    (Join-Path $docs "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $docs "PowerShell\Microsoft.PowerShell_profile.ps1")
)
$line = ". '$lib'"
foreach ($p in $profiles) {
    $folder = Split-Path $p -Parent
    if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Force -Path $folder | Out-Null }
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Force -Path $p | Out-Null }
    $content = Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content -or $content -notlike "*$lib*") {
        Add-Content -LiteralPath $p -Value "`r`n$line"
        Write-Host "Zaktualizowano profil: $p"
    } else {
        Write-Host "Profil juz zawiera ncd: $p"
    }
}

# 5. Wlacz obsluge kolorow RGB (VT/ANSI) w konsoli Windows na stale
#    (ncd sam tez wlacza to w biezacej sesji, ale ten wpis dziala globalnie
#    dla kazdej nowej konsoli, np. cmd.exe uruchamianego przez ncd.cmd)
try {
    $consoleKey = 'HKCU:\Console'
    if (-not (Test-Path $consoleKey)) { New-Item -Path $consoleKey -Force | Out-Null }
    New-ItemProperty -Path $consoleKey -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null
    Write-Host "Wlaczono obsluge kolorow RGB (VT) dla konsoli Windows."
} catch {
    Write-Warning "Nie udalo sie ustawic VirtualTerminalLevel w rejestrze: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "Gotowe. Zamknij WSZYSTKIE okna cmd/PowerShell i otworz nowe, potem wpisz: ncd"
Write-Host 'W programie nacisnij [S] -> "Edytuj kolory", aby dostosowac kazdy element (RGB lub hex), albo wybierz gotowy motyw w "Motyw".'
