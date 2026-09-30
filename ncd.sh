#!/usr/bin/env bash
# ncd.sh - nawigator katalogow w terminalu
# Dziala w: Linux, macOS (bash), WSL, Git Bash. Wymaga bash 3.2+ (szybkie
# przesuwanie wymaga bash 4+).
#
# Uzycie:   source ~/ncd.sh      (najlepiej dodac do ~/.bashrc)
#           ncd                  (Enter/Esc/Q = przejdz do wybranego katalogu,
#                                 Ctrl+C = wyjdz bez zmiany katalogu)
#
# Kolory: pelny system motywow RGB (24-bit). W programie nacisnij [S] -> "Edytuj
# kolory", aby zmienic dowolny element (suwaki R/G/B albo klawisz [H] = wpisanie
# kodu hex wprost), albo wybierz jeden z gotowych presetow w "Motyw".

NCD_CFG="${HOME}/.dirnav.conf"
NCD_ACTIONS=(UP DOWN LEFT RIGHT ENTER BACK PGUP PGDN REFRESH SETTINGS QUIT)
NCD_LABELS=(Up Down Left Right Enter Back PageUp PageDown Refresh Settings Quit)
NCD_SLOTS=(BG TEXT DIM HDR STAT BOR ACC HL)
NCD_SLOT_LABELS=("Tlo" "Tekst" "Przyciemniony" "Naglowek" "Status" "Ramka" "Akcent" "Wskaznik")
NCD_THEME_LIST=("Domyslny" "Dracula" "Nord" "Solarized Dark" "Gruvbox Dark" "Ocean")
NCD_FORCE_ONE=12          # ponizej tylu katalogow zawsze 1 kolumna
NCD_ELL="…"

printf -v _NCD_SP '%*s' 1000 ''
_NCD_HR=${_NCD_SP//?/─}
_NCD_LOW=abcdefghijklmnopqrstuvwxyz
_NCD_UPP=ABCDEFGHIJKLMNOPQRSTUVWXYZ
NCD_INT=0

# ---------------------------------------------------------------- motywy (presety RGB)
# Zwraca "$T_R $T_G $T_B" dla danego motywu i slotu w zmiennych globalnych T_R/T_G/T_B.
_ncd_theme_rgb() {
    local t=$1 s=$2
    case "$t|$s" in
        "Domyslny|BG")   T_R=0;   T_G=0;   T_B=0   ;;
        "Domyslny|TEXT") T_R=192; T_G=192; T_B=192 ;;
        "Domyslny|DIM")  T_R=128; T_G=128; T_B=128 ;;
        "Domyslny|HDR")  T_R=0;   T_G=255; T_B=255 ;;
        "Domyslny|STAT") T_R=0;   T_G=200; T_B=0   ;;
        "Domyslny|BOR")  T_R=105; T_G=105; T_B=105 ;;
        "Domyslny|ACC")  T_R=255; T_G=215; T_B=0   ;;
        "Domyslny|HL")   T_R=0;   T_G=139; T_B=139 ;;

        "Dracula|BG")   T_R=40;  T_G=42;  T_B=54  ;;
        "Dracula|TEXT") T_R=248; T_G=248; T_B=242 ;;
        "Dracula|DIM")  T_R=98;  T_G=114; T_B=164 ;;
        "Dracula|HDR")  T_R=139; T_G=233; T_B=253 ;;
        "Dracula|STAT") T_R=80;  T_G=250; T_B=123 ;;
        "Dracula|BOR")  T_R=68;  T_G=71;  T_B=90  ;;
        "Dracula|ACC")  T_R=241; T_G=250; T_B=140 ;;
        "Dracula|HL")   T_R=189; T_G=147; T_B=249 ;;

        "Nord|BG")   T_R=46;  T_G=52;  T_B=64  ;;
        "Nord|TEXT") T_R=216; T_G=222; T_B=233 ;;
        "Nord|DIM")  T_R=76;  T_G=86;  T_B=106 ;;
        "Nord|HDR")  T_R=136; T_G=192; T_B=208 ;;
        "Nord|STAT") T_R=163; T_G=190; T_B=140 ;;
        "Nord|BOR")  T_R=67;  T_G=76;  T_B=94  ;;
        "Nord|ACC")  T_R=235; T_G=203; T_B=139 ;;
        "Nord|HL")   T_R=94;  T_G=129; T_B=172 ;;

        "Solarized Dark|BG")   T_R=0;   T_G=43;  T_B=54  ;;
        "Solarized Dark|TEXT") T_R=131; T_G=148; T_B=150 ;;
        "Solarized Dark|DIM")  T_R=88;  T_G=110; T_B=117 ;;
        "Solarized Dark|HDR")  T_R=42;  T_G=161; T_B=152 ;;
        "Solarized Dark|STAT") T_R=133; T_G=153; T_B=0   ;;
        "Solarized Dark|BOR")  T_R=7;   T_G=54;  T_B=66  ;;
        "Solarized Dark|ACC")  T_R=181; T_G=137; T_B=0   ;;
        "Solarized Dark|HL")   T_R=38;  T_G=139; T_B=210 ;;

        "Gruvbox Dark|BG")   T_R=40;  T_G=40;  T_B=40  ;;
        "Gruvbox Dark|TEXT") T_R=235; T_G=219; T_B=178 ;;
        "Gruvbox Dark|DIM")  T_R=146; T_G=131; T_B=116 ;;
        "Gruvbox Dark|HDR")  T_R=131; T_G=165; T_B=152 ;;
        "Gruvbox Dark|STAT") T_R=152; T_G=151; T_B=26  ;;
        "Gruvbox Dark|BOR")  T_R=60;  T_G=56;  T_B=54  ;;
        "Gruvbox Dark|ACC")  T_R=215; T_G=153; T_B=33  ;;
        "Gruvbox Dark|HL")   T_R=214; T_G=93;  T_B=14  ;;

        "Ocean|BG")   T_R=16;  T_G=24;  T_B=32  ;;
        "Ocean|TEXT") T_R=200; T_G=220; T_B=230 ;;
        "Ocean|DIM")  T_R=90;  T_G=110; T_B=130 ;;
        "Ocean|HDR")  T_R=60;  T_G=180; T_B=220 ;;
        "Ocean|STAT") T_R=60;  T_G=200; T_B=160 ;;
        "Ocean|BOR")  T_R=40;  T_G=55;  T_B=70  ;;
        "Ocean|ACC")  T_R=240; T_G=180; T_B=60  ;;
        "Ocean|HL")   T_R=30;  T_G=120; T_B=180 ;;

        *) T_R=128; T_G=128; T_B=128 ;;
    esac
}

_ncd_apply_theme() {
    local t=$1 slot
    for slot in "${NCD_SLOTS[@]}"; do
        _ncd_theme_rgb "$t" "$slot"
        printf -v "NCD_${slot}R" '%s' "$T_R"
        printf -v "NCD_${slot}G" '%s' "$T_G"
        printf -v "NCD_${slot}B" '%s' "$T_B"
    done
    NCD_THEME=$t
}

# ---------------------------------------------------------------- konfiguracja
_ncd_defaults() {
    NCD_MAXCOLS=3
    NCD_TRUNC=Middle
    NCD_DELAY=0
    _ncd_apply_theme "Domyslny"
    NCD_K_UP="UP";         NCD_K_DOWN="DOWN"
    NCD_K_LEFT="LEFT";     NCD_K_RIGHT="RIGHT"
    NCD_K_ENTER="ENTER";   NCD_K_BACK="BACK"
    NCD_K_PGUP="PGUP";     NCD_K_PGDN="PGDN"
    NCD_K_REFRESH="R";     NCD_K_SETTINGS="S"
    NCD_K_QUIT="ESC Q"
}

_ncd_load() {
    [[ -r $NCD_CFG ]] || return 0
    local k v a slot chan rest nv
    while IFS='=' read -r k v || [[ -n $k ]]; do
        v=${v%$'\r'}
        case $k in
            MaxColumns)      [[ $v =~ ^[1-6]$ ]] && NCD_MAXCOLS=$v ;;
            TruncateMode)    [[ $v == Middle || $v == End ]] && NCD_TRUNC=$v ;;
            MovementDelayMs) [[ $v =~ ^[0-9]{1,3}$ ]] && NCD_DELAY=$((10#$v)) ;;
            Theme)           [[ -n $v ]] && NCD_THEME=$v ;;
            Color.*)
                rest=${k#Color.}
                slot=${rest%%.*}
                chan=${rest#*.}
                case " ${NCD_SLOTS[*]} " in
                    *" $slot "*)
                        if [[ $chan =~ ^(R|G|B)$ && $v =~ ^[0-9]{1,3}$ ]]; then
                            nv=$((10#$v)); (( nv > 255 )) && nv=255
                            printf -v "NCD_${slot}${chan}" '%s' "$nv"
                        fi ;;
                esac ;;
            Key.*)
                a=${k#Key.}
                case " ${NCD_ACTIONS[*]} " in
                    *" $a "*) [[ -n $v ]] && printf -v "NCD_K_$a" '%s' "$v" ;;
                esac ;;
        esac
    done < "$NCD_CFG"
}

_ncd_save() {
    local a v slot rv gv bv
    {
        printf 'MaxColumns=%s\n' "$NCD_MAXCOLS"
        printf 'TruncateMode=%s\n' "$NCD_TRUNC"
        printf 'MovementDelayMs=%s\n' "$NCD_DELAY"
        printf 'Theme=%s\n' "$NCD_THEME"
        for slot in "${NCD_SLOTS[@]}"; do
            rv="NCD_${slot}R"; gv="NCD_${slot}G"; bv="NCD_${slot}B"
            printf 'Color.%s.R=%s\n' "$slot" "${!rv}"
            printf 'Color.%s.G=%s\n' "$slot" "${!gv}"
            printf 'Color.%s.B=%s\n' "$slot" "${!bv}"
        done
        for a in "${NCD_ACTIONS[@]}"; do
            v="NCD_K_$a"
            printf 'Key.%s=%s\n' "$a" "${!v}"
        done
    } > "$NCD_CFG" 2>/dev/null
}

# ---------------------------------------------------------------- kolory (24-bit / truecolor)
_ncd_styles() {
    RST=$'\e[0m'
    local lum hf
    S_TEXT=$'\e[38;2;'"${NCD_TEXTR};${NCD_TEXTG};${NCD_TEXTB};48;2;${NCD_BGR};${NCD_BGG};${NCD_BGB}m"
    S_BG=$S_TEXT
    S_HDR=$'\e[38;2;'"${NCD_HDRR};${NCD_HDRG};${NCD_HDRB};48;2;${NCD_BGR};${NCD_BGG};${NCD_BGB}m"
    S_DIM=$'\e[38;2;'"${NCD_DIMR};${NCD_DIMG};${NCD_DIMB};48;2;${NCD_BGR};${NCD_BGG};${NCD_BGB}m"
    S_BORDER=$'\e[38;2;'"${NCD_BORR};${NCD_BORG};${NCD_BORB};48;2;${NCD_BGR};${NCD_BGG};${NCD_BGB}m"
    S_ACC=$'\e[38;2;'"${NCD_ACCR};${NCD_ACCG};${NCD_ACCB};48;2;${NCD_BGR};${NCD_BGG};${NCD_BGB}m"
    S_STAT=$'\e[38;2;'"${NCD_STATR};${NCD_STATG};${NCD_STATB};48;2;${NCD_BGR};${NCD_BGG};${NCD_BGB}m"
    lum=$(( (299 * NCD_HLR + 587 * NCD_HLG + 114 * NCD_HLB) / 1000 ))
    hf=255; (( lum > 140 )) && hf=0
    S_HI=$'\e[38;2;'"${hf};${hf};${hf};48;2;${NCD_HLR};${NCD_HLG};${NCD_HLB}m"
}

# ---------------------------------------------------------------- rysowanie
_ncd_fit() {   # $1 tekst, $2 szerokosc -> FIT (przyciete lub dopelnione spacjami)
    local s=$1 w=$2
    if (( w <= 0 )); then FIT=""; return; fi
    if (( ${#s} > w )); then
        FIT=${s:0:w}
    else
        FIT=$s${_NCD_SP:0:$((w - ${#s}))}
    fi
}

_ncd_ln() {    # $1 styl, $2 tekst -> dopisuje linie do $out
    _ncd_fit "$2" "$W"
    # Zmiana: najpierw kolor linii, potem spacje, następnie sekwencja czyszcząca \e[K, a DOPIERO POTEM reset \e[0m ($RST)
    out+="$1$FIT"$'\e[K'"$RST"$'\n'
}

_ncd_size() {  # ustawia H, COLS, W
    local s
    s=$(stty size </dev/tty 2>/dev/null)
    H=${s%% *}; COLS=${s##* }
    [[ $H =~ ^[0-9]+$ && $COLS =~ ^[0-9]+$ ]] || { H=24; COLS=80; }
    (( COLS < 15 )) && COLS=15
    (( COLS > 900 )) && COLS=900
    (( H < 8 )) && H=8
    W=$((COLS - 1))
}

# ---------------------------------------------------------------- klawisze
# Ustawia KEY: UP DOWN LEFT RIGHT PGUP PGDN ENTER ESC BACK TAB SPACE OTHER
# lub wielka litera / cyfra / znak. $1 = opcjonalny timeout (sek.) dla pierwszego znaku.
_ncd_read_key() {
    local k rest="" c tmp rc
    if [[ -n $1 ]]; then
        IFS= read -rsn1 -t "$1" k 2>/dev/null; rc=$?
    else
        IFS= read -rsn1 k; rc=$?
    fi
    (( rc != 0 )) && { KEY=""; return 1; }
    case $k in
        "") KEY=ENTER ;;
        $'\e')
            IFS= read -rsn2 -t "$NCD_ESC_T" rest 2>/dev/null
            case $rest in
                '[A'|'OA') KEY=UP ;;
                '[B'|'OB') KEY=DOWN ;;
                '[C'|'OC') KEY=RIGHT ;;
                '[D'|'OD') KEY=LEFT ;;
                '[5') IFS= read -rsn1 -t "$NCD_ESC_T" c 2>/dev/null; KEY=PGUP ;;
                '[6') IFS= read -rsn1 -t "$NCD_ESC_T" c 2>/dev/null; KEY=PGDN ;;
                '') KEY=ESC ;;
                '['[0-9]|'O'?)
                    # inne sekwencje (Home, End, Ctrl+strzalki...) - wyczysc do konca
                    while IFS= read -rsn1 -t "$NCD_ESC_T" c 2>/dev/null; do
                        [[ $c == [A-Za-z~] ]] && break
                    done
                    KEY=OTHER ;;
                *) KEY=OTHER ;;
            esac ;;
        $'\x7f'|$'\b') KEY=BACK ;;
        $'\t') KEY=TAB ;;
        ' ') KEY=SPACE ;;
        [0-9]) KEY=$k ;;
        *)
            tmp=${_NCD_LOW%%"$k"*}
            if (( ${#tmp} < 26 )); then KEY=${_NCD_UPP:${#tmp}:1}; else KEY=$k; fi ;;
    esac
    return 0
}

_ncd_is() {    # czy KEY jest przypisany do akcji $1
    local v="NCD_K_$1"
    [[ " ${!v} " == *" $KEY "* ]]
}

# ---------------------------------------------------------------- katalogi
_ncd_load_dirs() {
    local d ng=0 dg=0
    dirs=(); maxlen=0
    [[ $cwd != / ]] && dirs+=("..")
    shopt -q nullglob && ng=1
    shopt -q dotglob && dg=1
    shopt -s nullglob dotglob
    for d in "${cwd%/}"/*/; do
        d=${d%/}; d=${d##*/}
        dirs+=("$d")
        (( ${#d} > maxlen )) && maxlen=${#d}
    done
    (( ng )) || shopt -u nullglob
    (( dg )) || shopt -u dotglob
    count=${#dirs[@]}
}

_ncd_parent() {
    local p=${cwd%/*}
    [[ -z $p ]] && p=/
    cwd=$p
}

# ruch wskaznika; zwraca 0 jesli KEY byl klawiszem ruchu
_ncd_move() {
    local p cc pc b nx
    if _ncd_is UP; then
        p=$((sel - columns))
        if (( p >= 0 )); then
            sel=$p
        else
            cc=$((sel % columns)); pc=$(( (cc - 1 + columns) % columns ))
            b=$((pc + (rows - 1) * columns))
            (( b >= count )) && b=$((b - columns))
            (( b >= 0 )) && sel=$b
        fi
    elif _ncd_is DOWN; then
        nx=$((sel + columns))
        if (( nx < count )); then
            sel=$nx
        else
            cc=$((sel % columns)); pc=$(( (cc + 1) % columns ))
            (( pc < count )) && sel=$pc
        fi
    elif _ncd_is LEFT; then
        (( sel > 0 )) && sel=$((sel - 1))
    elif _ncd_is RIGHT; then
        (( sel < count - 1 )) && sel=$((sel + 1))
    elif _ncd_is PGUP; then
        sel=$((sel - maxvis * columns))
        (( sel < 0 )) && sel=0
    elif _ncd_is PGDN; then
        sel=$((sel + maxvis * columns))
        (( sel >= count )) && sel=$((count - 1))
    else
        return 1
    fi
    (( sel < 0 )) && sel=0
    return 0
}

# jedna pelna klatka, wypisana jednym printf (bez Clear -> bez migania)
_ncd_render() {
    local r c idx name disp prefix style line cellw maxdisp keep half endlen
    local startrow endrow rendered=0 dp ps pcur ptot status
    cellw=$((W / columns)); (( cellw < 2 )) && cellw=2

    dp=$cwd; ps=$((W - 4))
    if (( ${#dp} > ps )); then
        if (( ps > 5 )); then
            dp="…${dp:$((${#dp} - ps + 1))}"
        else
            (( ps < 1 )) && ps=1
            dp=${dp:0:ps}
        fi
    fi

    out=$'\e[H'
    _ncd_ln "$S_BG" ""
    _ncd_ln "$S_HDR" " $dp"
    _ncd_ln "$S_DIM" " [Ruch]: Skroty | [Enter]: Wejdz | [S]: Ust. | [Esc]: Wyjdz"
    _ncd_ln "$S_BORDER" "${_NCD_HR:0:W}"

    if (( count == 0 )); then
        _ncd_ln "$S_DIM" "  (brak katalogow)"
        rendered=1
    else
        startrow=$scroll
        endrow=$((scroll + maxvis - 1))
        (( endrow > rows - 1 )) && endrow=$((rows - 1))
        for (( r = startrow; r <= endrow; r++ )); do
            line=""
            for (( c = 0; c < columns; c++ )); do
                idx=$((r * columns + c))
                if (( idx < count )); then
                    name=${dirs[idx]}
                    if [[ $name == .. ]]; then disp="↑ .."; else disp=$name; fi
                    maxdisp=$((cellw - 5)); (( maxdisp < 1 )) && maxdisp=1
                    if (( ${#disp} > maxdisp )); then
                        keep=$((maxdisp - ${#NCD_ELL}))
                        if (( keep > 0 )); then
                            if [[ $NCD_TRUNC == Middle ]]; then
                                half=$((keep / 2)); endlen=$((keep - half))
                                disp="${disp:0:half}${NCD_ELL}${disp: -endlen}"
                            else
                                disp="${disp:0:keep}${NCD_ELL}"
                            fi
                        else
                            disp=${disp:0:1}
                        fi
                    fi
                    if (( idx == sel )); then
                        prefix=" ► "; style=$S_HI
                    elif [[ $name == .. ]]; then
                        prefix="   "; style=$S_ACC
                    else
                        prefix="   "; style=$S_TEXT
                    fi
                    _ncd_fit "$prefix$disp" "$cellw"
                    line+="$style$FIT"
                else
                    line+="$S_BG${_NCD_SP:0:cellw}"
                fi
            done
            # Zmiana: wyczyszczenie reszty linii zachowując S_BG, potem RST
            out+="$line$S_BG"$'\e[K'"$RST"$'\n'
            rendered=$((rendered + 1))
        done
    fi
    while (( rendered < maxvis )); do
        _ncd_ln "$S_BG" ""
        rendered=$((rendered + 1))
    done
    _ncd_ln "$S_BORDER" "${_NCD_HR:0:W}"

    if (( count == 0 )); then idx=0; else idx=$((sel + 1)); fi
    pcur=$((scroll / maxvis + 1))
    ptot=$(( (rows + maxvis - 1) / maxvis )); (( ptot < 1 )) && ptot=1
    status="  Katalog: $idx / $count  |  Strona: $pcur / $ptot"
    _ncd_fit "$status" "$W"
    
    # Zmiana: czyszczenie ekranu (\e[J) do końca z nałożonym kolorem S_BG, aby reszta tła poprawnie się wypełniła 
    out+="$S_STAT$FIT"$'\e[K'"$S_BG"$'\e[J'"$RST"
    printf '%s' "$out"
}

# ---------------------------------------------------------------- menu
_ncd_menu_head() {   # $1 tytul, $2 podpowiedz
    _ncd_ln "$S_BG" ""
    _ncd_ln "$S_HDR" " ╭ $1"
    _ncd_ln "$S_DIM" " $2"
    _ncd_ln "$S_BORDER" "${_NCD_HR:0:W}"
}

_ncd_menu_items() {  # korzysta z: items, msel, out
    local i
    for i in "${!items[@]}"; do
        if (( i == msel )); then
            _ncd_ln "$S_HI" " ► ${items[i]}"
        else
            _ncd_ln "$S_TEXT" "   ${items[i]}"
        fi
    done
    # Zmiana: upewnij się, że reszta tła jest czyszczona na kolor zdefiniowany w S_BG
    out+="$S_BG"$'\e[J'"$RST"
}

_ncd_keybinds() {
    local msel=0 out W H COLS items i v val n=${#NCD_ACTIONS[@]}
    printf '%s\e[2J%s' "$S_BG" "$RST"
    while true; do
        _ncd_size
        items=()
        for (( i = 0; i < n; i++ )); do
            v="NCD_K_${NCD_ACTIONS[i]}"; val=${!v}; val=${val// /, }
            items+=("${NCD_LABELS[i]}: [$val]")
        done
        out=$'\e[H'
        _ncd_menu_head "USTAWIENIA SKROTOW" "[↑/↓]: Wybor | [Enter]: Zmien | [Esc]: Wroc"
        _ncd_menu_items
        printf '%s' "$out"
        _ncd_read_key || return
        case $KEY in
            UP)   (( msel > 0 )) && msel=$((msel - 1)) ;;
            DOWN) (( msel < n - 1 )) && msel=$((msel + 1)) ;;
            ENTER)
                _ncd_fit " Nacisnij nowy klawisz dla: ${NCD_LABELS[msel]}..." "$W"
                printf '\n%s%s%s' "$S_HI" "$FIT" "$RST"
                if _ncd_read_key && [[ $KEY != OTHER ]]; then
                    printf -v "NCD_K_${NCD_ACTIONS[msel]}" '%s' "$KEY"
                fi ;;
            ESC|Q) return ;;
        esac
    done
}

# Edytor pojedynczego koloru: suwaki R/G/B (0-255) LUB bezposrednie wpisanie
# kodu hex po nacisnieciu [H]. $1 = slot (np. HL), $2 = etykieta wyswietlana.
_ncd_rgb_editor() {
    local slot=$1 label=$2
    local csel=0 out W H COLS items chans=(R G B) hex hexmode=0 hexbuf="" i
    printf '%s\e[2J%s' "$S_BG" "$RST"
    while true; do
        _ncd_size
        local rv="NCD_${slot}R" gv="NCD_${slot}G" bv="NCD_${slot}B"
        items=("R: [${!rv}]" "G: [${!gv}]" "B: [${!bv}]")
        out=$'\e[H'
        if (( hexmode )); then
            _ncd_menu_head "$label - WPISZ HEX" "Wpisz do 6 znakow hex | [Enter]: Zatwierdz | [Esc]: Anuluj"
        else
            _ncd_menu_head "$label (RGB)" "[↑/↓]: Kanal | [←/→]: -5/+5 | [H]: Wpisz HEX | [Esc]: Zapisz i wroc"
        fi
        for (( i = 0; i < 3; i++ )); do
            if (( ! hexmode && i == csel )); then
                out+="$S_HI"
            else
                out+="$S_TEXT"
            fi
            _ncd_fit "   ${items[i]}" "$W"
            # Zmiana: bezpieczne resetowanie kolorów
            out+="$FIT"$'\e[K'"$RST"$'\n'
        done
        printf -v hex '#%02X%02X%02X' "${!rv}" "${!gv}" "${!bv}"
        _ncd_fit "" "$W"; out+="$S_BG$FIT"$'\e[K'"$RST"$'\n'
        if (( hexmode )); then
            _ncd_fit "   Hex: #${hexbuf}" "$W"
            out+="$S_HI$FIT"$'\e[K'"$RST"$'\n'
        else
            _ncd_fit "   Podglad ($hex):" "$W"
            out+="$S_DIM$FIT"$'\e[K'"$RST"$'\n'
        fi
        _ncd_fit "   ► Przyklad tekstu w tym kolorze" "$W"
        out+="$S_HI$FIT"$'\e[K'"$S_BG"$'\e[J'"$RST"
        printf '%s' "$out"

        _ncd_read_key || { _ncd_save; return; }

        if (( hexmode )); then
            case $KEY in
                ENTER)
                    if [[ ${#hexbuf} -eq 6 ]]; then
                        printf -v "$rv" '%d' "0x${hexbuf:0:2}"
                        printf -v "$gv" '%d' "0x${hexbuf:2:2}"
                        printf -v "$bv" '%d' "0x${hexbuf:4:2}"
                    fi
                    hexmode=0; hexbuf="" ;;
                BACK) hexbuf=${hexbuf%?} ;;
                ESC|Q) hexmode=0; hexbuf="" ;;
                [0-9A-Fa-f])
                    if (( ${#hexbuf} < 6 )); then hexbuf+=${KEY^^}; fi ;;
            esac
        else
            case $KEY in
                UP)   (( csel > 0 )) && csel=$((csel - 1)) ;;
                DOWN) (( csel < 2 )) && csel=$((csel + 1)) ;;
                LEFT|RIGHT)
                    local delta=5 var
                    [[ $KEY == LEFT ]] && delta=-5
                    case $csel in 0) var=$rv;; 1) var=$gv;; 2) var=$bv;; esac
                    local nv=$(( ${!var} + delta ))
                    (( nv < 0 )) && nv=0
                    (( nv > 255 )) && nv=255
                    printf -v "$var" '%s' "$nv" ;;
                H) hexmode=1; hexbuf="" ;;
                ESC|Q) _ncd_save; return ;;
            esac
        fi
        _ncd_styles
    done
}

# Lista wszystkich kolorowanych elementow - wybor ktory edytowac
_ncd_color_menu() {
    local msel=0 out W H COLS items i n=${#NCD_SLOTS[@]} slot rv gv bv hex
    printf '%s\e[2J%s' "$S_BG" "$RST"
    while true; do
        _ncd_size
        items=()
        for (( i = 0; i < n; i++ )); do
            slot=${NCD_SLOTS[i]}
            rv="NCD_${slot}R"; gv="NCD_${slot}G"; bv="NCD_${slot}B"
            printf -v hex '#%02X%02X%02X' "${!rv}" "${!gv}" "${!bv}"
            items+=("${NCD_SLOT_LABELS[i]}: [$hex]")
        done
        out=$'\e[H'
        _ncd_menu_head "EDYTUJ KOLORY  (Motyw: $NCD_THEME)" "[↑/↓]: Wybor | [Enter]: Edytuj | [Esc]: Wroc"
        _ncd_menu_items
        printf '%s' "$out"
        _ncd_read_key || { _ncd_save; return; }
        case $KEY in
            UP)   (( msel > 0 )) && msel=$((msel - 1)) ;;
            DOWN) (( msel < n - 1 )) && msel=$((msel + 1)) ;;
            ENTER)
                _ncd_rgb_editor "${NCD_SLOTS[msel]}" "${NCD_SLOT_LABELS[msel]}"
                NCD_THEME="Wlasny"
                printf '%s\e[2J%s' "$S_BG" "$RST" ;;
            ESC|Q) _ncd_save; return ;;
        esac
    done
}

_ncd_settings() {
    local msel=0 out W H COLS items i idx n themes
    local delays=(0 25 50 75 100 150 200)
    printf '%s\e[2J%s' "$S_BG" "$RST"
    while true; do
        _ncd_size
        items=("Maks. kolumn: [$NCD_MAXCOLS]"
               "Skracanie: [$NCD_TRUNC]"
               "Motyw: [$NCD_THEME]"
               "Edytuj kolory: [Wejdz (Enter)]"
               "Op. ruchu (ms): [$NCD_DELAY]"
               "Skroty: [Wejdz (Enter)]")
        out=$'\e[H'
        _ncd_menu_head "USTAWIENIA" "[↑/↓]: Wybor | [Enter/←/→]: Zmiana | [Esc]: Wroc"
        _ncd_menu_items
        printf '%s' "$out"
        _ncd_read_key || { _ncd_save; return; }
        case $KEY in
            UP)   (( msel > 0 )) && msel=$((msel - 1)) ;;
            DOWN) (( msel < 5 )) && msel=$((msel + 1)) ;;
            ENTER|LEFT|RIGHT|SPACE)
                case $msel in
                    0)
                        if [[ $KEY == LEFT ]]; then
                            (( NCD_MAXCOLS > 1 )) && NCD_MAXCOLS=$((NCD_MAXCOLS - 1))
                        else
                            if (( NCD_MAXCOLS < 6 )); then NCD_MAXCOLS=$((NCD_MAXCOLS + 1)); else NCD_MAXCOLS=1; fi
                        fi ;;
                    1)
                        if [[ $NCD_TRUNC == Middle ]]; then NCD_TRUNC=End; else NCD_TRUNC=Middle; fi ;;
                    2)
                        n=${#NCD_THEME_LIST[@]}; idx=0
                        for (( i = 0; i < n; i++ )); do
                            [[ ${NCD_THEME_LIST[i]} == "$NCD_THEME" ]] && idx=$i
                        done
                        if [[ $KEY == LEFT ]]; then idx=$(( (idx - 1 + n) % n )); else idx=$(( (idx + 1) % n )); fi
                        _ncd_apply_theme "${NCD_THEME_LIST[idx]}"
                        _ncd_styles ;;
                    3)
                        if [[ $KEY == ENTER ]]; then _ncd_color_menu; printf '%s\e[2J%s' "$S_BG" "$RST"; fi ;;
                    4)
                        n=${#delays[@]}; idx=0
                        for (( i = 0; i < n; i++ )); do
                            [[ ${delays[i]} == "$NCD_DELAY" ]] && idx=$i
                        done
                        if [[ $KEY == LEFT ]]; then idx=$(( (idx - 1 + n) % n )); else idx=$(( (idx + 1) % n )); fi
                        NCD_DELAY=${delays[idx]} ;;
                    5)
                        if [[ $KEY == ENTER ]]; then _ncd_keybinds; printf '%s\e[2J%s' "$S_BG" "$RST"; fi ;;
                esac ;;
            ESC|Q) _ncd_save; return ;;
        esac
    done
}

# ---------------------------------------------------------------- glowna funkcja
ncd() {
    if [[ ! -t 0 || ! -t 1 ]]; then
        echo "ncd: wymagany interaktywny terminal" >&2
        return 1
    fi

    local cwd=$PWD sel=0 scroll=0 count=0 maxlen=0 dirs=() need_load=1
    local pending="" KEY="" out W H COLS columns rows maxvis colw
    local selrow maxscroll target n ms oldint
    local running=1 go=0 junk
    _ncd_defaults; _ncd_load; _ncd_styles

    # ulamkowe timeouty (bash 4+) -> szybkie przesuwanie i krotkie ESC
    NCD_ESC_T=1; NCD_FAST=0
    if read -t 0.01 -r junk <<<"" 2>/dev/null; then
        NCD_ESC_T=0.05; NCD_FAST=1
    fi

    NCD_INT=0
    oldint=$(trap -p INT)
    trap 'NCD_INT=1' INT
    
    # Zmiana: po włączeniu alternatywnego ekranu od razu uzupełnij go ustawionym kolorem tła motywu.
    printf '\e[?1049h\e[?25l'
    printf '%s\e[2J%s' "$S_BG" "$RST"

    while (( running )); do
        if (( need_load )); then _ncd_load_dirs; need_load=0; fi
        _ncd_size

        # uklad
        if (( count <= NCD_FORCE_ONE || COLS < 50 )); then
            columns=1
        else
            colw=$((maxlen + 6)); (( colw < 20 )) && colw=20
            columns=$((COLS / colw))
            (( columns > NCD_MAXCOLS )) && columns=$NCD_MAXCOLS
            (( columns < 1 )) && columns=1
        fi
        rows=$(( (count + columns - 1) / columns )); (( rows < 1 )) && rows=1
        maxvis=$((H - 6)); (( maxvis < 1 )) && maxvis=1

        (( sel >= count )) && sel=$((count - 1))
        (( sel < 0 )) && sel=0
        selrow=$((sel / columns))
        (( selrow < scroll )) && scroll=$selrow
        (( selrow >= scroll + maxvis )) && scroll=$((selrow - maxvis + 1))
        maxscroll=$((rows - maxvis)); (( maxscroll < 0 )) && maxscroll=0
        (( scroll > maxscroll )) && scroll=$maxscroll

        _ncd_render

        if [[ -n $pending ]]; then
            KEY=$pending; pending=""
        elif ! _ncd_read_key; then
            running=0; continue
        fi

        if _ncd_move; then
            # zastosuj wszystkie oczekujace ruchy przed kolejnym rysowaniem
            if (( NCD_FAST )); then
                n=0
                while (( n < 300 )) && _ncd_read_key 0.001; do
                    if _ncd_move; then
                        n=$((n + 1))
                    else
                        pending=$KEY; break
                    fi
                done
            fi
            if (( NCD_DELAY > 0 )); then
                printf -v ms '0.%03d' "$NCD_DELAY"; sleep "$ms"
            fi
        elif _ncd_is ENTER; then
            if (( count > 0 )); then
                target=${dirs[sel]}
                if [[ $target == .. ]]; then _ncd_parent; else cwd="${cwd%/}/$target"; fi
                sel=0; scroll=0; need_load=1
            fi
        elif _ncd_is BACK; then
            if [[ $cwd != / ]]; then _ncd_parent; sel=0; scroll=0; need_load=1; fi
        elif _ncd_is SETTINGS; then
            _ncd_settings; _ncd_styles; need_load=1
            # Po wyjściu z ustawień wypełniamy ekran tłem aby ukryć ewentualne śmieci
            printf '%s\e[2J%s' "$S_BG" "$RST"
        elif _ncd_is REFRESH; then
            need_load=1
        elif _ncd_is QUIT; then
            go=1; running=0
        fi

        if (( NCD_INT )); then running=0; go=0; fi
    done

    printf '\e[?25h\e[?1049l'
    eval "${oldint:-trap - INT}"
    (( go )) && builtin cd -- "$cwd"
    return 0
}