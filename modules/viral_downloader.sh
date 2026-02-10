#!/bin/bash
# FILE: modules/viral_downloader.sh
# VERSION: 1.9 (Storage Limiter: Max 2 Masters) VIRAL=1.9
# AUTHOR: Intisari Code Auditor

# --- KONFIGURASI WARNA ---
CYAN='\e[1;36m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RED='\e[1;31m'
WHITE='\e[1;37m'
GRAY='\e[1;30m'
NC='\e[0m'

# --- FUNGSI PELAPOR ERROR (SILENT) ---
kirim_error_log() {
    local pesan_error="$1"
    local short_log=$(echo "$pesan_error" | tail -c 500 | xxd -p | tr -d '\n' | sed 's/../%&/g')
    if [ ! -z "$LINK_MONITOR" ]; then
        curl -s -L "${LINK_MONITOR}?action=laporan_error&user=${MEMBER_ID}&desc=${short_log}" > /dev/null 2>&1 &
    fi
}

# --- FUNGSI PROGRESS BAR ---
show_progress_bar() {
    local current=$1; local total=$2
    local percent=$(( (current * 100) / total ))
    local completed=$(( (percent * 20) / 100 ))
    local remaining=$(( 20 - completed ))
    
    printf "${YELLOW}[*] Overall Progress: ${WHITE}["
    for ((i=0; i<completed; i++)); do printf "#"; done
    for ((i=0; i<remaining; i++)); do printf "."; done
    printf "] ${percent}%%${NC}"
}

# --- FUNGSI UTAMA ---
run_viral_downloader() {
    # 0. AUTO-CLEANUP & LIMITER (PENTING!)
    if [ -d "$SAVE_DIR" ]; then
        # A. Hapus yang sudah expired (> 7 hari)
        find "$SAVE_DIR" -name ".Master_*.mp4" -type f -mtime +7 -delete 2>/dev/null
        
        # B. LOGIKA BARU: Batasi Maksimal 2 Master
        # Mengambil daftar file master, urutkan dari yang terbaru (-t).
        # tail -n +3 artinya ambil mulai dari baris ke-3 sampai akhir (file lama).
        # xargs rm akan menghapus file-file lama tersebut.
        
        JML_MASTER=$(ls -1 "$SAVE_DIR"/.Master_*.mp4 2>/dev/null | wc -l)
        
        if [ "$JML_MASTER" -gt 2 ]; then
            echo -e "${YELLOW}[INFO] Mendeteksi $JML_MASTER Video Master (Batas Max: 2)${NC}"
            echo -e "${GRAY}Membersihkan master video terlama...${NC}"
            ls -t "$SAVE_DIR"/.Master_*.mp4 2>/dev/null | tail -n +3 | xargs rm -f
        fi
    fi

    while true; do
        clear
        
        # --- CEK DEPENDENSI ---
        if ! command -v node &> /dev/null; then
            echo -e "${RED}[!] CRITICAL ERROR: Node.js belum terinstall!${NC}"
            echo -e "Silakan ketik: ${CYAN}pkg install nodejs-lts${NC}"
            read -p "Tekan Enter..."
            return
        fi

        # 1. HEADER
        echo -e "${CYAN}"
        echo "  ___ _   _ _____ ___ ____   _    ____ ___ "
        echo " |_ _| \ | |_   _|_ _/ ___| / \  |  _ \_ _| "
        echo "  | ||  \| | | |  | |\___ \/ _ \ | |_) | |  "
        echo "  | || |\  | | |  | | ___) / ___ \|  _ <| |  "
        echo " |___|_| \_| |_| |___|____/_/   \_\_| \_\___| "
        echo "      A U T O C U T   V E R S I O N   $MOD_VIRAL_VER"
        echo -e "${NC}"
        echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Setup Awal
        silent_security_check 2>/dev/null
        mkdir -p "$SAVE_DIR"
        mkdir -p "$HOOK_DIR"

        # --- SMART COOKIES ---
        COOKIE_ARGS=""
        if [ -f "$COOKIE_FILE" ]; then
            COOKIE_ARGS="--cookies \"$COOKIE_FILE\""
            echo -e "${GREEN}[INFO] PREMIUM MODE: Cookies Terdeteksi!${NC}"
        else
            echo -e "${GRAY}[INFO] STANDARD MODE: Tidak ada cookies.${NC}"
        fi

        # 2. INPUT LINK
        echo -e "${WHITE}  MODE: DOWNLOAD VIDEO VIRAL (AUTO-SPLIT)${NC}"
        echo -e "${GRAY}  Tekan 'x' untuk kembali ke menu${NC}\n"
        read -p "  Masukan Link YouTube: " link
        
        if [[ "$link" == "x" || "$link" == "X" ]]; then return; fi
        if [ -z "$link" ]; then echo "  Link kosong!"; sleep 2; continue; fi

        echo -e "${YELLOW}[*] Mengambil Info Judul Video...${NC}"
        RAW_TITLE=$("$YTDLP_CMD" --ignore-config $COOKIE_ARGS --get-title --skip-download "$link" 2>/dev/null)
        
        if [ -z "$RAW_TITLE" ]; then 
            echo -e "${RED}[!] Gagal mengambil judul. Cek koneksi/Link.${NC}"; sleep 2; continue
        fi

        # Logic Nama & Folder
        # Pastikan nama bersih agar aman di sistem file
        CLEAN_NAME=$(echo "$RAW_TITLE" | awk '{print $1"_"$2"_"$3}' | sed 's/[^a-zA-Z0-9_]//g')
        [ -z "$CLEAN_NAME" ] && CLEAN_NAME="Viral_Video_$(date +%s)"
        
        FOLDER_TARGET="/sdcard/$CLEAN_NAME"       # Folder Hasil (Muncul di Galeri)
        FOLDER_SAMPAH_TEMP="/sdcard/.$CLEAN_NAME" # Folder Temp (Hidden)
        
        # FILE MASTER: Disimpan dengan awalan titik agar hidden
        MASTER_FILE="$SAVE_DIR/.Master_${CLEAN_NAME}.mp4"

        echo -e "${GREEN}[+] Target Folder: $FOLDER_TARGET${NC}"

        # 3. PILIH POLA
        echo -e "\n${GREEN}=== PILIH POLA POTONGAN (.txt) ===${NC}"
        local txt_files=(); local i=1
        while IFS= read -r -d $'\0' f; do
            txt_files+=("$f"); echo -e " [$i] ${WHITE}$(basename "$f")${NC}"; ((i++))
        done < <(find "$TXT_SOURCE_DIR" -maxdepth 1 -type f -name "*.txt" ! -name "user_agent.txt" -print0 2>/dev/null)

        if [ ${#txt_files[@]} -eq 0 ]; then
            echo -e "${RED}[!] Tidak ada file pola .txt di $TXT_SOURCE_DIR${NC}"; sleep 3; return
        fi

        read -p " Pilih Nomor File TXT > " txt_num
        if [[ ! "$txt_num" =~ ^[0-9]+$ ]] || [ -z "${txt_files[$((txt_num-1))]}" ]; then
             echo " Pilihan salah!"; sleep 1; continue
        fi
        local list_file="${txt_files[$((txt_num-1))]}"

        # 4. PILIH FORMAT OUTPUT
        echo -e "\n${CYAN}=== ✂️  FORMAT OUTPUT ===${NC}"
        echo -e "${YELLOW}[1]${WHITE} Original (Landscape)"
        echo -e "${YELLOW}[2]${WHITE} Vertical (Crop Tengah)"
        read -p " Pilihan (1/2) > " reframe_mode
        
        local vf_params=""
        if [ "$reframe_mode" == "2" ]; then 
            vf_params="-vf crop=ih*(9/16):ih,scale=1080:1920,setsar=1"
        else 
            vf_params="-vf scale=1080:-1" 
        fi

        # 5. DOWNLOAD MASTER (Smart Cache)
        TEMP_LOG="$TMPDIR/yt_debug_$(date +%s).log"
        
        if [ -f "$MASTER_FILE" ]; then
            echo -e "${GREEN}[✓] Master Video Ditemukan! Menggunakan Cache.${NC}"
        else
            echo -e "${YELLOW}[*] Sedang mengunduh Master Video...${NC}"
            
            pid=$!
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null; do
                i=$(( (i+1) %4 ))
                printf "\r${YELLOW}[*] Downloading... [${spin:$i:1}]${NC}"
                sleep 0.1
            done &
            SPIN_PID=$!

            timeout 600s "$YTDLP_CMD" --ignore-config $COOKIE_ARGS \
                --external-downloader aria2c \
                --external-downloader-args "aria2c:-x 8 -s 8 --connect-timeout=15 --timeout=15 --max-tries=5" \
                -f "bestvideo[height<=1080]+bestaudio/best" \
                --merge-output-format mp4 -o "$MASTER_FILE" "$link" > "$TEMP_LOG" 2>&1
            
            EXIT_STATUS=$?
            kill $SPIN_PID 2>/dev/null
            echo -e "\r${GREEN}[*] Download Master Selesai.           ${NC}" 

            if [ $EXIT_STATUS -ne 0 ]; then
                if [ ! -f "$MASTER_FILE" ]; then
                    echo -e "${RED}[!] Gagal Download Master!${NC}"
                    kirim_error_log "$(cat $TEMP_LOG)"
                    rm -f "$TEMP_LOG"
                    sleep 2; continue
                fi
            fi
            rm -f "$TEMP_LOG"
        fi

        # 6. EKSEKUSI PEMOTONGAN
        mkdir -p "$FOLDER_TARGET"
        echo -e "${YELLOW}[*] Memproses ke: $FOLDER_TARGET${NC}"
        
        TOTAL_CLIPS=$(grep -v '^#' "$list_file" | grep -v '^$' | wc -l)
        local no=1

        while IFS='|' read -r start_t end_t out_n <&3 || [ -n "$start_t" ]; do
            [[ "$start_t" =~ ^#.* ]] || [[ -z "$start_t" ]] && continue
            
            echo ""
            show_progress_bar $no $TOTAL_CLIPS
            
            start_t=$(echo "$start_t" | tr -d '\r' | xargs)
            end_t=$(echo "$end_t" | tr -d '\r' | xargs)
            out_n=$(echo "$out_n" | tr -d '\r' | xargs)
            
            SAFE_OUT_NAME=$(echo "$out_n" | sed 's/[^a-zA-Z0-9 _-]//g')
            OUTPUT_FILE="$FOLDER_TARGET/${SAFE_OUT_NAME}.mp4"
            
            echo -e "\n   ${GREEN}-> Clip $no: $SAFE_OUT_NAME${NC}"
            
            "$FFMPEG_CMD" -ss "$start_t" -to "$end_t" -i "$MASTER_FILE" $vf_params \
                -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k \
                -y -loglevel error "$OUTPUT_FILE" < /dev/null

            # Update Stats Global (Optional)
            CURRENT_COUNT=$(cat "$FILE_STATS" 2>/dev/null | cut -d'|' -f1)
            [ -z "$CURRENT_COUNT" ] && CURRENT_COUNT=0
            echo "$((CURRENT_COUNT + 1))|HASH" > "$FILE_STATS" 2>/dev/null
            
            ((no++))
        done 3< "$list_file"

        # 7. FINISHING & CLEANUP
        echo -e "\n${GRAY}[*] Refresh Galeri Android...${NC}"
        termux-media-scan -r "$FOLDER_TARGET" &>/dev/null
        
        echo -e "\n${YELLOW}[*] Membersihkan Sampah System...${NC}"
        
        # Hapus File Pola TXT
        if [ -f "$list_file" ]; then
            rm -f "$list_file"
            echo -e "${GRAY}    -> Menghapus pola file sampah server.${NC}"
        fi

        # Hapus Folder Temp Hidden (Jika ada sampah folder titik)
        if [ -d "$FOLDER_SAMPAH_TEMP" ]; then
             rm -rf "$FOLDER_SAMPAH_TEMP"
        fi

        # Info Master
        if [ -f "$MASTER_FILE" ]; then
            # Cek ulang jumlah master untuk laporan ke user
            JML_NOW=$(ls -1 "$SAVE_DIR"/.Master_*.mp4 2>/dev/null | wc -l)
            echo -e "${GREEN}[✓] Master Video Disimpan di server intisari.apps(Slot Terpakai: $JML_NOW/2).${NC}"
            if [ "$JML_NOW" -ge 2 ]; then
                echo -e "${RED}    [!] Slot Penuh. Download berikutnya akan menghapus Master terlama dari Sever.${NC}"
            fi
        fi

        echo -e "\n${GREEN}[V] SELESAI! Cek Galeri Anda.${NC}"
        echo -e "${GRAY}---------------------------------------${NC}"
        echo -e "${YELLOW}[1]${WHITE} Download Video Viral Lain"
        echo -e "${YELLOW}[2]${WHITE} Kembali ke Menu Utama"
        read -p " Pilihan (1/2) > " next_act
        
        [[ "$next_act" == "2" ]] && break
    done
}