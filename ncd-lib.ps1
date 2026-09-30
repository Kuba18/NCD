function ncd {
    # Plik konfiguracyjny w katalogu domowym uzytkownika
    $ConfigFile = Join-Path $HOME ".dirnav.json"
    
    # ====================================================================
    # --- DOMYSLNA KONFIGURACJA SKRYPTU ---
    # Kolory: pelny system motywow RGB (24-bit). W programie [S] -> "Edytuj
    # kolory" zmienia kazdy element (suwaki R/G/B albo [H] = wpisanie kodu
    # hex wprost), albo wybierz gotowy motyw w "Motyw".
    # ====================================================================
    $Config = @{
        MaxColumns = 3
        ForceOneColumnThreshold = 12
        SeparatorChar = "─"
        
        TruncateMode = "Middle"
        Ellipsis = "…"
        
        MovementDelayMs = 0 # <--- Opoznienie ruchu przy trzymaniu klawisza (w milisekundach)
        
        Keys = @{
            Up = @("UpArrow")
            Down = @("DownArrow")
            Left = @("LeftArrow")
            Right = @("RightArrow")
            Enter = @("Enter")
            Back = @("Backspace")
            PageUp = @("PageUp")
            PageDown = @("PageDown")
            Refresh = @("R")
            Settings = @("S")
            Quit = @("Escape", "Q")
        }
        
        Theme = "Domyslny"
        Colors = @{
            Bg = @{ R = 0; G = 0; B = 0 }
            Text = @{ R = 192; G = 192; B = 192 }
            Dim = @{ R = 128; G = 128; B = 128 }
            Header = @{ R = 0; G = 255; B = 255 }
            Status = @{ R = 0; G = 200; B = 0 }
            Border = @{ R = 105; G = 105; B = 105 }
            Accent = @{ R = 255; G = 215; B = 0 }
            Indicator = @{ R = 0; G = 139; B = 139 }
        }
    }
    # ====================================================================
    
    function Get-ThemePresets {
        return @{
            "Domyslny" = @{
                Bg = @{ R=0; G=0; B=0 }; Text = @{ R=192; G=192; B=192 }; Dim = @{ R=128; G=128; B=128 }
                Header = @{ R=0; G=255; B=255 }; Status = @{ R=0; G=200; B=0 }; Border = @{ R=105; G=105; B=105 }
                Accent = @{ R=255; G=215; B=0 }; Indicator = @{ R=0; G=139; B=139 }
            }
            "Dracula" = @{
                Bg = @{ R=40; G=42; B=54 }; Text = @{ R=248; G=248; B=242 }; Dim = @{ R=98; G=114; B=164 }
                Header = @{ R=139; G=233; B=253 }; Status = @{ R=80; G=250; B=123 }; Border = @{ R=68; G=71; B=90 }
                Accent = @{ R=241; G=250; B=140 }; Indicator = @{ R=189; G=147; B=249 }
            }
            "Nord" = @{
                Bg = @{ R=46; G=52; B=64 }; Text = @{ R=216; G=222; B=233 }; Dim = @{ R=76; G=86; B=106 }
                Header = @{ R=136; G=192; B=208 }; Status = @{ R=163; G=190; B=140 }; Border = @{ R=67; G=76; B=94 }
                Accent = @{ R=235; G=203; B=139 }; Indicator = @{ R=94; G=129; B=172 }
            }
            "Solarized Dark" = @{
                Bg = @{ R=0; G=43; B=54 }; Text = @{ R=131; G=148; B=150 }; Dim = @{ R=88; G=110; B=117 }
                Header = @{ R=42; G=161; B=152 }; Status = @{ R=133; G=153; B=0 }; Border = @{ R=7; G=54; B=66 }
                Accent = @{ R=181; G=137; B=0 }; Indicator = @{ R=38; G=139; B=210 }
            }
            "Gruvbox Dark" = @{
                Bg = @{ R=40; G=40; B=40 }; Text = @{ R=235; G=219; B=178 }; Dim = @{ R=146; G=131; B=116 }
                Header = @{ R=131; G=165; B=152 }; Status = @{ R=152; G=151; B=26 }; Border = @{ R=60; G=56; B=54 }
                Accent = @{ R=215; G=153; B=33 }; Indicator = @{ R=214; G=93; B=14 }
            }
            "Ocean" = @{
                Bg = @{ R=16; G=24; B=32 }; Text = @{ R=200; G=220; B=230 }; Dim = @{ R=90; G=110; B=130 }
                Header = @{ R=60; G=180; B=220 }; Status = @{ R=60; G=200; B=160 }; Border = @{ R=40; G=55; B=70 }
                Accent = @{ R=240; G=180; B=60 }; Indicator = @{ R=30; G=120; B=180 }
            }
        }
    }
    
    function Set-Theme {
        param([string]$Name)
        $presets = Get-ThemePresets
        if ($presets.ContainsKey($Name)) {
            foreach ($role in $presets[$Name].Keys) {
                $Config.Colors[$role] = @{ R = $presets[$Name][$role].R; G = $presets[$Name][$role].G; B = $presets[$Name][$role].B }
            }
            $Config.Theme = $Name
        }
    }
    
    # Bezpieczne formatowanie linii
    function Fit-String {
        param([string]$Text, [int]$Width)
        if ($Width -le 0) { return "" }
        if ($Text.Length -gt $Width) { return $Text.Substring(0, $Width) }
        return $Text.PadRight($Width)
    }
    
    # Wlacza obsluge sekwencji ANSI/VT w konsoli Windows
    function Enable-VTMode {
        try {
            if (-not ([System.Management.Automation.PSTypeName]'NcdNative').Type) {
                Add-Type -Namespace NcdNative -Name Console -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern System.IntPtr GetStdHandle(int nStdHandle);
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out uint lpMode);
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, uint dwMode);
"@ -ErrorAction SilentlyContinue
            }
            $handle = [NcdNative.Console]::GetStdHandle(-11)
            $mode = 0
            [NcdNative.Console]::GetConsoleMode($handle, [ref]$mode) | Out-Null
            [NcdNative.Console]::SetConsoleMode($handle, ($mode -bor 0x0004)) | Out-Null
        } catch { }
    }
    
    # ====================================================================
    # FUNKCJE RYSOWANIA INTERFEJSU Z POPRAWKĄ TŁA
    # ====================================================================
    
    # Czyści cały ekran za pomocą sekwencji ANSI z uwzględnieniem koloru tła z motywu
    function Clear-TerminalSurface {
        $bg = $Config.Colors.Bg
        $esc = [char]27
        # Ustawienie tła na globalne -> wyczyszczenie ekranu (2J) -> powrót na górę (H)
        Write-Host -NoNewline "$esc[0m$esc[48;2;$($bg.R);$($bg.G);$($bg.B)m$esc[2J$esc[H"
    }
    
    function Get-RoleAnsi {
        param([string]$Role)
        $c = $Config.Colors[$Role]
        $bg = $Config.Colors.Bg
        $esc = [char]27
        return "$esc[38;2;$($c.R);$($c.G);$($c.B);48;2;$($bg.R);$($bg.G);$($bg.B)m"
    }
    
    function Write-Role {
        param([string]$Role, [string]$Text, [switch]$NoNewline)
        $esc = [char]27
        $bg = $Config.Colors.Bg
        # Po zresetowaniu [0m, ponownie aplikujemy tło z motywu aby krawędzie nie były czarne
        $seq = (Get-RoleAnsi $Role) + $Text + "$esc[0m$esc[48;2;$($bg.R);$($bg.G);$($bg.B)m"
        if ($NoNewline) { Write-Host $seq -NoNewline } else { Write-Host $seq }
    }
    
    function Write-AnsiHighlight {
        param([string]$Text, [switch]$NoNewline)
        $c = $Config.Colors.Indicator
        $bg = $Config.Colors.Bg
        $lum = (0.299 * $c.R) + (0.587 * $c.G) + (0.114 * $c.B)
        $fg = if ($lum -gt 140) { 0 } else { 255 }
        $esc = [char]27
        $seq = "$esc[38;2;${fg};${fg};${fg};48;2;$($c.R);$($c.G);$($c.B)m$Text$esc[0m$esc[48;2;$($bg.R);$($bg.G);$($bg.B)m"
        if ($NoNewline) { Write-Host $seq -NoNewline } else { Write-Host $seq }
    }
    
    # --- LADOWANIE ZAPISANYCH USTAWIEN ---
    if (Test-Path $ConfigFile) {
        try {
            $saved = Get-Content $ConfigFile -Raw | ConvertFrom-Json
            if ($null -ne $saved.MaxColumns) { $Config.MaxColumns = $saved.MaxColumns }
            if ($null -ne $saved.TruncateMode) { $Config.TruncateMode = $saved.TruncateMode }
            if ($null -ne $saved.MovementDelayMs) { $Config.MovementDelayMs = $saved.MovementDelayMs }
            if ($null -ne $saved.Theme) { $Config.Theme = $saved.Theme }
            if ($null -ne $saved.Colors) {
                foreach ($role in @("Bg", "Text", "Dim", "Header", "Status", "Border", "Accent", "Indicator")) {
                    if ($null -ne $saved.Colors.$role) {
                        if ($null -ne $saved.Colors.$role.R) { $Config.Colors[$role].R = [int]$saved.Colors.$role.R }
                        if ($null -ne $saved.Colors.$role.G) { $Config.Colors[$role].G = [int]$saved.Colors.$role.G }
                        if ($null -ne $saved.Colors.$role.B) { $Config.Colors[$role].B = [int]$saved.Colors.$role.B }
                    }
                }
            }
            if ($null -ne $saved.Keys) {
                foreach ($k in $saved.Keys.psobject.properties.name) {
                    if ($Config.Keys.Contains($k)) {
                        $Config.Keys[$k] = @($saved.Keys.$k)
                    }
                }
            }
        } catch {
            Write-Warning "Nie udalo sie zaladowac pliku konfiguracyjnego dirnav."
            Start-Sleep -Seconds 1
        }
    }
    
    # --- ZAPIS USTAWIEN ---
    function Save-Config {
        try {
            $Config | ConvertTo-Json -Depth 6 | Set-Content $ConfigFile -Force
        } catch { }
    }
    
    Enable-VTMode
    
    $currentPath = (Get-Location).Path
    $selected = 0
    $scrollOffset = 0
    $pendingKey = $null
    
    function Test-KeyMatch($actionKeys, $pressedKey) {
        $kName = $pressedKey.Key.ToString()
        $kChar = $pressedKey.KeyChar.ToString().ToUpper()
        foreach ($k in $actionKeys) {
            if ($k -eq $kName -or $k.ToUpper() -eq $kChar) { return $true }
        }
        return $false
    }
    
    $TryMove = {
        param($k)
        $moveHandled = $true
        if (Test-KeyMatch $Config.Keys.Up $k) {
            $prev = $selected - $columns
            if ($prev -ge 0) { $selected = $prev }
            else {
                $currentCol = $selected % $columns
                $prevCol = ($currentCol - 1 + $columns) % $columns
                $bottomOfPrevCol = $prevCol + ($rows - 1) * $columns
                if ($bottomOfPrevCol -ge $directories.Count) { $bottomOfPrevCol -= $columns }
                if ($bottomOfPrevCol -ge 0) { $selected = $bottomOfPrevCol }
            }
        }
        elseif (Test-KeyMatch $Config.Keys.Down $k) {
            $next = $selected + $columns
            if ($next -lt $directories.Count) { $selected = $next }
            else {
                $currentCol = $selected % $columns
                $nextCol = ($currentCol + 1) % $columns
                if ($nextCol -lt $directories.Count) { $selected = $nextCol }
            }
        }
        elseif (Test-KeyMatch $Config.Keys.Left $k) {
            if ($selected -gt 0) { $selected-- }
        }
        elseif (Test-KeyMatch $Config.Keys.Right $k) {
            if ($selected -lt ($directories.Count - 1)) { $selected++ }
        }
        elseif (Test-KeyMatch $Config.Keys.PageUp $k) {
            $selected -= ($maxVisibleRows * $columns)
            if ($selected -lt 0) { $selected = 0 }
        }
        elseif (Test-KeyMatch $Config.Keys.PageDown $k) {
            $selected += ($maxVisibleRows * $columns)
            if ($selected -ge $directories.Count) { $selected = $directories.Count - 1 }
            if ($selected -lt 0) { $selected = 0 }
        }
        else { $moveHandled = $false }
    }
    
    function Show-KeybindsMenu {
        $kbSelected = 0
        $actions = @("Up", "Down", "Left", "Right", "Enter", "Back", "PageUp", "PageDown", "Refresh", "Settings", "Quit")
        
        while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
        
        while ($true) {
            Clear-TerminalSurface
            $W = [Console]::WindowWidth - 1
            if ($W -lt 10) { $W = 10 }
            
            Write-Role "Text" (Fit-String "" $W)
            Write-Role "Header" (Fit-String " ╭ USTAWIENIA SKROTOW" $W)
            Write-Role "Dim" (Fit-String " [↑/↓]: Wybor | [Enter]: Zmien | [Esc]: Wroc" $W)
            Write-Role "Border" (Fit-String ($Config.SeparatorChar * $W) $W)
            
            for ($i = 0; $i -lt $actions.Count; $i++) {
                $prefix = if ($i -eq $kbSelected) { " ► " } else { "   " }
                $actName = $actions[$i]
                $currentKeys = $Config.Keys[$actName] -join ", "
                
                $lineFormatted = Fit-String "${prefix}${actName}: [${currentKeys}]" $W
                
                if ($i -eq $kbSelected) { Write-AnsiHighlight $lineFormatted } 
                else { Write-Role "Text" $lineFormatted }
            }
            
            while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
            $kbKey = [Console]::ReadKey($true)
            $kbKeyName = $kbKey.Key.ToString()
            
            if ($kbKeyName -eq "UpArrow") { if ($kbSelected -gt 0) { $kbSelected-- } }
            elseif ($kbKeyName -eq "DownArrow") { if ($kbSelected -lt ($actions.Count - 1)) { $kbSelected++ } }
            elseif ($kbKeyName -eq "Enter") {
                $targetAction = $actions[$kbSelected]
                Write-Host ""
                Write-AnsiHighlight (Fit-String " Nacisnij nowy klawisz dla: $targetAction..." $W)
                
                while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
                $newKey = [Console]::ReadKey($true)
                $Config.Keys[$targetAction] = @($newKey.Key.ToString())
            }
            elseif ($kbKeyName -in @("Escape", "Q")) {
                Save-Config
                break
            }
        }
    }
    
    function Show-RgbEditor {
        param([string]$Role, [string]$Label)
        $rSelected = 0
        $channels = @("R", "G", "B")
        $hexMode = $false
        $hexBuf = ""
        
        while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
        
        while ($true) {
            Clear-TerminalSurface
            $W = [Console]::WindowWidth - 1
            if ($W -lt 10) { $W = 10 }
            
            Write-Role "Text" (Fit-String "" $W)
            Write-Role "Header" (Fit-String " ╭ $Label (RGB)" $W)
            if ($hexMode) {
                Write-Role "Dim" (Fit-String " Wpisz do 6 znakow hex | [Enter]: Zatwierdz | [Esc]: Anuluj" $W)
            } else {
                Write-Role "Dim" (Fit-String " [↑/↓]: Kanal | [←/→]: -5/+5 | [H]: Wpisz HEX | [Esc]: Zapisz i wroc" $W)
            }
            Write-Role "Border" (Fit-String ($Config.SeparatorChar * $W) $W)
            
            for ($i = 0; $i -lt $channels.Count; $i++) {
                $val = $Config.Colors[$Role][$channels[$i]]
                $prefix = if ($i -eq $rSelected) { " ► " } else { "   " }
                $lineFormatted = Fit-String "${prefix}$($channels[$i]): [$val]" $W
                if ((-not $hexMode) -and $i -eq $rSelected) { Write-AnsiHighlight $lineFormatted } 
                else { Write-Role "Text" $lineFormatted }
            }
            
            $c = $Config.Colors[$Role]
            $hex = "#{0:X2}{1:X2}{2:X2}" -f [int]$c.R, [int]$c.G, [int]$c.B
            Write-Role "Text" (Fit-String "" $W)
            if ($hexMode) {
                Write-AnsiHighlight (Fit-String " Hex: #$hexBuf" $W)
            } else {
                Write-Role "Dim" (Fit-String " Podglad ($hex):" $W)
            }
            Write-AnsiHighlight (Fit-String " ► Przyklad tekstu w tym kolorze" $W)
            
            while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
            $rKey = [Console]::ReadKey($true)
            $rKeyName = $rKey.Key.ToString()
            $rKeyChar = $rKey.KeyChar.ToString().ToUpper()
            
            if ($hexMode) {
                if ($rKeyName -eq "Enter") {
                    if ($hexBuf.Length -eq 6) {
                        $Config.Colors[$Role].R = [Convert]::ToInt32($hexBuf.Substring(0, 2), 16)
                        $Config.Colors[$Role].G = [Convert]::ToInt32($hexBuf.Substring(2, 2), 16)
                        $Config.Colors[$Role].B = [Convert]::ToInt32($hexBuf.Substring(4, 2), 16)
                    }
                    $hexMode = $false; $hexBuf = ""
                }
                elseif ($rKeyName -eq "Backspace") {
                    if ($hexBuf.Length -gt 0) { $hexBuf = $hexBuf.Substring(0, $hexBuf.Length - 1) }
                }
                elseif ($rKeyName -eq "Escape") {
                    $hexMode = $false; $hexBuf = ""
                }
                elseif ($rKeyChar -match '^[0-9A-F]$' -and $hexBuf.Length -lt 6) {
                    $hexBuf += $rKeyChar
                }
            }
            else {
                if ($rKeyName -eq "UpArrow") { if ($rSelected -gt 0) { $rSelected-- } }
                elseif ($rKeyName -eq "DownArrow") { if ($rSelected -lt 2) { $rSelected++ } }
                elseif ($rKeyName -in @("LeftArrow", "RightArrow")) {
                    $delta = if ($rKeyName -eq "LeftArrow") { -1 } else { 1 }
                    $ch = $channels[$rSelected]
                    $newVal = [int]$Config.Colors[$Role][$ch] + $delta
                    if ($newVal -lt 0) { $newVal = 0 }
                    if ($newVal -gt 255) { $newVal = 255 }
                    $Config.Colors[$Role][$ch] = $newVal
                }
                elseif ($rKeyName -eq "H") { $hexMode = $true; $hexBuf = "" }
                elseif ($rKeyName -in @("Escape", "Q")) { Save-Config; break }
            }
        }
    }
    
    function Show-ColorMenu {
        $roles = @("Bg", "Text", "Dim", "Header", "Status", "Border", "Accent", "Indicator")
        $labels = @{ Bg="Tlo"; Text="Tekst"; Dim="Przyciemniony"; Header="Naglowek"; Status="Status"; Border="Ramka"; Accent="Akcent"; Indicator="Wskaznik" }
        $cSelected = 0
        
        while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
        
        while ($true) {
            Clear-TerminalSurface
            $W = [Console]::WindowWidth - 1
            if ($W -lt 10) { $W = 10 }
            
            Write-Role "Text" (Fit-String "" $W)
            Write-Role "Header" (Fit-String " ╭ EDYTUJ KOLORY (Motyw: $($Config.Theme))" $W)
            Write-Role "Dim" (Fit-String " [↑/↓]: Wybor | [Enter]: Edytuj | [Esc]: Wroc" $W)
            Write-Role "Border" (Fit-String ($Config.SeparatorChar * $W) $W)
            
            for ($i = 0; $i -lt $roles.Count; $i++) {
                $role = $roles[$i]
                $c = $Config.Colors[$role]
                $hex = "#{0:X2}{1:X2}{2:X2}" -f [int]$c.R, [int]$c.G, [int]$c.B
                $lineFormatted = Fit-String " $($labels[$role]): [$hex]" $W
                if ($i -eq $cSelected) { Write-AnsiHighlight $lineFormatted } 
                else { Write-Role "Text" $lineFormatted }
            }
            
            while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
            $cKey = [Console]::ReadKey($true)
            $cKeyName = $cKey.Key.ToString()
            
            if ($cKeyName -eq "UpArrow") { if ($cSelected -gt 0) { $cSelected-- } }
            elseif ($cKeyName -eq "DownArrow") { if ($cSelected -lt ($roles.Count - 1)) { $cSelected++ } }
            elseif ($cKeyName -eq "Enter") {
                Show-RgbEditor -Role $roles[$cSelected] -Label $labels[$roles[$cSelected]]
                $Config.Theme = "Wlasny"
            }
            elseif ($cKeyName -in @("Escape", "Q")) { Save-Config; break }
        }
    }

    function Show-ThemeMenu {
        $presets = Get-ThemePresets
        $themes = @($presets.Keys | Sort-Object)
        $tSelected = $themes.IndexOf($Config.Theme)
        if ($tSelected -lt 0) { $tSelected = 0 }

        while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }

        while ($true) {
            Clear-TerminalSurface
            $W = [Console]::WindowWidth - 1
            if ($W -lt 10) { $W = 10 }

            Write-Role "Text" (Fit-String "" $W)
            Write-Role "Header" (Fit-String " ╭ WYBIERZ MOTYW" $W)
            Write-Role "Dim" (Fit-String " [↑/↓]: Wybor | [Enter]: Zastosuj | [Esc]: Wroc" $W)
            Write-Role "Border" (Fit-String ($Config.SeparatorChar * $W) $W)

            for ($i = 0; $i -lt $themes.Count; $i++) {
                $tName = $themes[$i]
                $prefix = if ($i -eq $tSelected) { " ► " } else { "   " }
                $currentMark = if ($tName -eq $Config.Theme) { " (Aktywny)" } else { "" }
                $lineFormatted = Fit-String "${prefix}${tName}${currentMark}" $W

                if ($i -eq $tSelected) {
                    Write-AnsiHighlight $lineFormatted
                } else {
                    Write-Role "Text" $lineFormatted
                }
            }

            while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
            $tKey = [Console]::ReadKey($true)
            $tKeyName = $tKey.Key.ToString()

            if ($tKeyName -eq "UpArrow") {
                if ($tSelected -gt 0) { $tSelected-- }
            } elseif ($tKeyName -eq "DownArrow") {
                if ($tSelected -lt ($themes.Count - 1)) { $tSelected++ }
            } elseif ($tKeyName -eq "Enter") {
                Set-Theme $themes[$tSelected]
                Save-Config
                break
            } elseif ($tKeyName -in @("Escape", "Q")) {
                break
            }
        }
    }
    
    function Show-SettingsMenu {
        $sSelected = 0
        # Dynamiczne pobieranie predefiniowanych motywow
        $themeList = @((Get-ThemePresets).Keys | Sort-Object)
        
        while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
        
        while ($true) {
            Clear-TerminalSurface
            $W = [Console]::WindowWidth - 1
            if ($W -lt 10) { $W = 10 }
            
            Write-Role "Text" (Fit-String "" $W)
            Write-Role "Header" (Fit-String " ╭ USTAWIENIA" $W)
            Write-Role "Dim" (Fit-String " [↑/↓]: Wybor | [Enter/←/→]: Zmiana | [Esc]: Wroc" $W)
            Write-Role "Border" (Fit-String ($Config.SeparatorChar * $W) $W)
            
            $options = @(
                @{ Label = "Maks. kolumn"; Value = $Config.MaxColumns },
                @{ Label = "Skracanie"; Value = $Config.TruncateMode },
                @{ Label = "Motyw"; Value = "$($Config.Theme) [Enter/←/→]" },
                @{ Label = "Edytuj kolory"; Value = "Wejdz (Enter)" },
                @{ Label = "Op. ruchu (ms)"; Value = $Config.MovementDelayMs },
                @{ Label = "Skroty"; Value = "Wejdz (Enter)" }
            )
            
            for ($i = 0; $i -lt $options.Count; $i++) {
                $prefix = if ($i -eq $sSelected) { " ► " } else { "   " }
                $lineFormatted = Fit-String "${prefix}$($options[$i].Label): [$($options[$i].Value)]" $W
                if ($i -eq $sSelected) { Write-AnsiHighlight $lineFormatted } 
                else { Write-Role "Text" $lineFormatted }
            }
            
            while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
            $sKey = [Console]::ReadKey($true)
            $sKeyName = $sKey.Key.ToString()
            
            if ($sKeyName -eq "UpArrow") { if ($sSelected -gt 0) { $sSelected-- } }
            elseif ($sKeyName -eq "DownArrow") { if ($sSelected -lt ($options.Count - 1)) { $sSelected++ } }
            elseif ($sKeyName -in @("Enter", "RightArrow", "LeftArrow", "Spacebar")) {
                switch ($sSelected) {
                    0 {
                        if ($sKeyName -eq "LeftArrow") { if ($Config.MaxColumns -gt 1) { $Config.MaxColumns-- } } 
                        else { if ($Config.MaxColumns -lt 6) { $Config.MaxColumns++ } else { $Config.MaxColumns = 1 } }
                    }
                    1 {
                        if ($Config.TruncateMode -eq "Middle") { $Config.TruncateMode = "End" }
                        else { $Config.TruncateMode = "Middle" }
                    }
                    2 {
                        $tIdx = $themeList.IndexOf($Config.Theme)
                        if ($tIdx -lt 0) { $tIdx = 0 }

                        if ($sKeyName -eq "Enter") {
                            Show-ThemeMenu
                            $themeList = @((Get-ThemePresets).Keys | Sort-Object)
                        } elseif ($sKeyName -eq "LeftArrow") {
                            $tIdx--
                            if ($tIdx -lt 0) { $tIdx = $themeList.Count - 1 }
                            Set-Theme $themeList[$tIdx]
                        } elseif ($sKeyName -in @("RightArrow", "Spacebar")) {
                            $tIdx = ($tIdx + 1) % $themeList.Count
                            Set-Theme $themeList[$tIdx]
                        }
                    }
                    3 { if ($sKeyName -eq "Enter") { Show-ColorMenu } }
                    4 {
                        $delays = @(0, 25, 50, 75, 100, 150, 200)
                        $dIdx = $delays.IndexOf($Config.MovementDelayMs)
                        if ($dIdx -lt 0) { $dIdx = 0 }
                        if ($sKeyName -eq "LeftArrow") {
                            $dIdx--
                            if ($dIdx -lt 0) { $dIdx = $delays.Count - 1 }
                        } else { $dIdx = ($dIdx + 1) % $delays.Count }
                        $Config.MovementDelayMs = $delays[$dIdx]
                    }
                    5 { if ($sKeyName -eq "Enter") { Show-KeybindsMenu } }
                }
            }
            elseif ($sKeyName -in @("Escape", "Q")) { Save-Config; break }
        }
    }
    
    [Console]::CursorVisible = $false
    Clear-TerminalSurface
    
    try {
        while ($true) {
            $directories = @()
            
            $parent = Split-Path -Parent $currentPath -ErrorAction SilentlyContinue
            if ($parent -and $parent -ne $currentPath) { $directories += ".." }
            
            try {
                $dirs = [System.IO.Directory]::EnumerateDirectories($currentPath) | ForEach-Object { [System.IO.Path]::GetFileName($_) } | Sort-Object
                $directories += $dirs
            } catch { }
            
            if ($selected -ge $directories.Count) { $selected = [math]::Max(0, $directories.Count - 1) }
            
            $needsRefresh = $false
            
            while ($true) {
                $consoleWidth = [Console]::WindowWidth
                $consoleHeight = [Console]::WindowHeight
                
                if ($consoleWidth -lt 15) { $consoleWidth = 15 }
                if ($consoleHeight -lt 8) { $consoleHeight = 8 }
                $W = $consoleWidth - 1
                
                if ($directories.Count -le $Config.ForceOneColumnThreshold -or $consoleWidth -lt 50) { $columns = 1 }
                else {
                    $maxLength = 0
                    foreach ($d in $directories) { if ($d.Length -gt $maxLength) { $maxLength = $d.Length } }
                    $colWidth = $maxLength + 6
                    if ($colWidth -lt 20) { $colWidth = 20 }
                    
                    $columns = [math]::Floor($consoleWidth / $colWidth)
                    if ($columns -gt $Config.MaxColumns) { $columns = $Config.MaxColumns }
                    if ($columns -lt 1) { $columns = 1 }
                }
                
                $rows = [math]::Ceiling($directories.Count / [double]$columns)
                if ($rows -eq 0) { $rows = 1 }
                
                $selectedRow = [math]::Floor($selected / $columns)
                
                $maxVisibleRows = $consoleHeight - 6
                if ($maxVisibleRows -lt 1) { $maxVisibleRows = 1 }
                
                if ($selectedRow -lt $scrollOffset) { $scrollOffset = $selectedRow }
                if ($selectedRow -ge ($scrollOffset + $maxVisibleRows)) { $scrollOffset = $selectedRow - $maxVisibleRows + 1 }
                if ($scrollOffset -gt [math]::Max(0, $rows - $maxVisibleRows)) { $scrollOffset = [math]::Max(0, $rows - $maxVisibleRows) }
                
                try { [Console]::SetCursorPosition(0, 0) } catch { Clear-TerminalSurface }
                
                $separator = Fit-String ($Config.SeparatorChar * $W) $W
                
                $dispPath = $currentPath
                $pathSpace = $W - 4
                if ($pathSpace -gt 5 -and $dispPath.Length -gt $pathSpace) {
                    $dispPath = "…" + $dispPath.Substring($dispPath.Length - ($pathSpace - 1))
                } elseif ($dispPath.Length -gt $pathSpace) {
                    $dispPath = $dispPath.Substring(0, [math]::Max(1, $pathSpace))
                }
                
                Write-Role "Text" (Fit-String "" $W)
                Write-Role "Header" (Fit-String " $dispPath" $W)
                
                $navLine = " [Ruch]: Skroty | [Enter]: Wejdz | [S]: Ust. | [Esc]: Wyjdz"
                Write-Role "Dim" (Fit-String $navLine $W)
                Write-Role "Border" $separator
                
                $renderedRows = 0
                if ($directories.Count -eq 0) {
                    Write-Role "Dim" (Fit-String " (brak katalogow)" $W)
                    $renderedRows = 1
                }
                else {
                    $startRow = $scrollOffset
                    $endRow = [math]::Min($rows - 1, $scrollOffset + $maxVisibleRows - 1)
                    
                    for ($r = $startRow; $r -le $endRow; $r++) {
                        for ($c = 0; $c -lt $columns; $c++) {
                            
                            $idx = $r * $columns + $c
                            $cellW = [math]::Floor($W / $columns)
                            if ($cellW -lt 2) { $cellW = 2 }
                            
                            if ($idx -lt $directories.Count) {
                                $name = $directories[$idx]
                                $isSel = ($idx -eq $selected)
                                $prefix = if ($isSel) { " ► " } else { "   " }
                                
                                if ($name -eq "..") { $display = "↑ .." } else { $display = $name }
                                
                                $maxDisp = $cellW - 5
                                if ($maxDisp -lt 1) { $maxDisp = 1 }
                                
                                if ($display.Length -gt $maxDisp) {
                                    $ell = $Config.Ellipsis
                                    $keepLen = $maxDisp - $ell.Length
                                    
                                    if ($keepLen -gt 0) {
                                        if ($Config.TruncateMode -eq "Middle") {
                                            $half = [math]::Floor($keepLen / 2)
                                            $endLen = $keepLen - $half
                                            $display = $display.Substring(0, $half) + $ell + $display.Substring($display.Length - $endLen)
                                        }
                                        else {
                                            $display = $display.Substring(0, $keepLen) + $ell
                                        }
                                    } else {
                                        $display = $display.Substring(0, 1)
                                    }
                                }
                                
                                $displayStr = Fit-String "$prefix$display" $cellW
                                
                                if ($isSel) { Write-AnsiHighlight $displayStr -NoNewline }
                                else {
                                    if ($name -eq "..") { Write-Role "Accent" $displayStr -NoNewline } 
                                    else { Write-Role "Text" $displayStr -NoNewline }
                                }
                            }
                            else {
                                Write-Role "Text" (Fit-String "" $cellW) -NoNewline
                            }
                        }
                        Write-Host ""
                        $renderedRows++
                    }
                }
                
                while ($renderedRows -lt $maxVisibleRows) {
                    Write-Role "Text" (Fit-String "" $W)
                    $renderedRows++
                }
                
                Write-Role "Border" $separator
                
                $totalCount = $directories.Count
                $currentNum = if ($totalCount -eq 0) { 0 } else { $selected + 1 }
                
                $pageCurrent = [math]::Floor($scrollOffset/$maxVisibleRows) + 1
                $pageTotal = [math]::Ceiling($rows/$maxVisibleRows)
                if ($pageTotal -eq 0) { $pageTotal = 1 }
                
                $statusLine = " Katalog: $currentNum / $totalCount | Strona: $pageCurrent / $pageTotal"
                Write-Role "Status" (Fit-String $statusLine $W) -NoNewline
                
                # --- ODCZYT KLAWISZA ---
                if ($null -ne $pendingKey) {
                    $key = $pendingKey
                    $pendingKey = $null
                } else {
                    $key = [Console]::ReadKey($true)
                }
                
                . $TryMove $key
                $isMovementKey = $moveHandled
                
                if ($isMovementKey) {
                    $burst = 0
                    while ([Console]::KeyAvailable -and $burst -lt 200) {
                        $k2 = [Console]::ReadKey($true)
                        . $TryMove $k2
                        if (-not $moveHandled) { $pendingKey = $k2; break }
                        $burst++
                    }
                }
                elseif (Test-KeyMatch $Config.Keys.Enter $key) {
                    if ($directories.Count -gt 0) {
                        $target = $directories[$selected]
                        if ($target -eq "..") {
                            $parent = Split-Path -Parent $currentPath -ErrorAction SilentlyContinue
                            if ($parent) { $currentPath = $parent }
                        }
                        else {
                            $currentPath = Join-Path $currentPath $target
                        }
                        $selected = 0
                        $scrollOffset = 0
                        $needsRefresh = $true
                    }
                }
                elseif (Test-KeyMatch $Config.Keys.Back $key) {
                    $parent = Split-Path -Parent $currentPath -ErrorAction SilentlyContinue
                    if ($parent -and $parent -ne $currentPath) {
                        $currentPath = $parent
                        $selected = 0
                        $scrollOffset = 0
                        $needsRefresh = $true
                    }
                }
                elseif (Test-KeyMatch $Config.Keys.Settings $key) {
                    Show-SettingsMenu
                    $needsRefresh = $true
                }
                elseif (Test-KeyMatch $Config.Keys.Refresh $key) {
                    $needsRefresh = $true
                }
                elseif (Test-KeyMatch $Config.Keys.Quit $key) {
                    Set-Location $currentPath
                    if ($env:NCD_OUT) { Set-Content -Path $env:NCD_OUT -Value $currentPath -Encoding OEM }
                    # Przy wyjściu wymuszamy przejście do finally (break wyjdzie z pierwszej, return z funkcji)
                    return
                }
                
                if ($isMovementKey -and $Config.MovementDelayMs -gt 0) {
                    Start-Sleep -Milliseconds $Config.MovementDelayMs
                }
                
                if (-not $isMovementKey) {
                    while ([Console]::KeyAvailable) {
                        $null = [Console]::ReadKey($true)
                    }
                }
                
                if ($needsRefresh) {
                    Clear-TerminalSurface
                    break
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $true
        $esc = [char]27
        # Wychodząc ze skryptu resetujemy formatowanie do bazowego i czyścimy ekran, 
        # aby niestandardowe tło nie 'rozlało się' na główną konsole PS.
        Write-Host -NoNewline "$esc[0m$esc[2J$esc[H"
    }
}