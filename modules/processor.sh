#!/bin/bash
# FILE: modules/processor.sh
# FILE: modules/processor V1.4 PROCESSOR=1.4

# --- [1] HEADER KHUSUS AUTOCUT ---
header_potong() {
    clear
    # Pastikan variabel warna tersedia (diambil dari config/viral_downloader)
    echo -e "${CYAN}"
    echo "  ___ _   _ _____ ___ ____   _    ____ ___ "
    echo " |_ _| \ | |_   _|_ _/ ___| / \  |  _ \_ _| "
    echo "  | ||  \| | | |  | |\___ \/ _ \ | |_) | |  "
    echo "  | || |\  | | |  | | ___) / ___ \|  _ <| |  "
    echo " |___|_| \_| |_| |___|____/_/   \_\_| \_\___| "
    echo "          AUTOCUT (Video)  v$MOD_PROC_VER"
    echo "      [✂️] Podcast | LiveStream | Film    "
    echo -e "${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- [2] FUNGSI UTAMA PROCESSOR ---
proses_potong() {
    local full_path="$1"
    
    # Cek ketersediaan engine ffmpeg
    if [ ! -f "$FFMPEG_CMD" ]; then 
        cp $(command -v ffmpeg) "$FFMPEG_CMD" 2>/dev/null
        chmod +x "$FFMPEG_CMD"
    fi

    while true; do
        # Panggil Header Branding setiap kali loop kembali ke pilihan TXT
        header_potong 
        
        echo -e "${WHITE}  MODE: AUTO-CUT VIDEO (BY TXT RECIPE)${NC}"
        echo -e "${GRAY}  Video: $(basename "$full_path")${NC}"
        echo -e "${GRAY}  Tekan 'x' untuk kembali ke menu utama${NC}\n"

        if [ ! -d "$TXT_SOURCE_DIR" ]; then mkdir -p "$TXT_SOURCE_DIR"; fi

        # Scanning file TXT
        local txt_files=(); local i=1
        while IFS= read -r -d $'\0' f; do
            txt_files+=("$f")
            echo -e " [$i] ${WHITE}$(basename "$f")${NC}"
            ((i++))
        done < <(find "$TXT_SOURCE_DIR" -maxdepth 1 -type f -name "*.txt" ! -name "user_agent.txt" -print0 2>/dev/null)

        if [ ${#txt_files[@]} -eq 0 ]; then 
            echo -e "${RED}[!] File TXT Kosong di $TXT_SOURCE_DIR!${NC}"
            read -p " Tekan Enter..." ; return
        fi

        # Input Pilihan dengan opsi 'x'
        read -p " Pilih nomor file TXT > " txt_num
        
        # Logika Keluar seperti Viral Downloader
        [[ "$txt_num" == "x" || "$txt_num" == "X" ]] && return
        
        # Validasi Pilihan
        if [[ ! "$txt_num" =~ ^[0-9]+$ ]] || [ -z "${txt_files[$((txt_num-1))]}" ]; then
             echo -e "${RED}[!] Pilihan salah!${NC}"; sleep 1; continue
        fi
        
        local list_file="${txt_files[$((txt_num-1))]}"

        # --- PILIHAN REFRAME ---
        echo -e "\n${CYAN}=== ✂️  PILIH GAYA REFRAME ===${NC}"
        echo -e "${YELLOW}[1]${WHITE} Film / Cinematic"
        echo -e "${YELLOW}[2]${WHITE} Podcast Solo"
        echo -e "${YELLOW}[3]${WHITE} Podcast Berdua"
        echo -e "${YELLOW}[4]${WHITE} Original (Landscape)"
        echo -e "${GRAY}---------------------------------------${NC}"
        read -p " Pilihan (1-4) > " reframe_mode

        local vf_params=""
        case $reframe_mode in
            1|2) vf_params="crop=ih*(9/16):ih,scale=1080:1920,setsar=1" ;;
            3) vf_params="[0:v]crop=iw/2:ih:0:0[left];[0:v]crop=iw/2:ih:iw/2:0[right];[left][right]vstack=inputs=2,scale=1080:1920" ;;
            *) vf_params="scale=1080:-1" ;;
        esac

        # FOLDER TARGET = SESUAI NAMA VIDEO
        local nama_video=$(basename "$full_path")
        local nama_folder="${nama_video%.*}"
        local folder_target="/sdcard/$nama_folder"
        mkdir -p "$folder_target"
        
        echo -e "\n${YELLOW}[*] Menyiapkan Output: $folder_target${NC}"

        local no=1
        while IFS='|' read -r start_t end_t out_n <&3 || [ -n "$start_t" ]; do
            [[ "$start_t" =~ ^#.* ]] || [[ -z "$start_t" ]] && continue
            
            # Sanitasi Timestamp
            start_t=$(echo "$start_t" | sed 's/[^[:print:]]//g' | tr -d '\r' | xargs)
            end_t=$(echo "$end_t" | sed 's/[^[:print:]]//g' | tr -d '\r' | xargs)
            out_n=$(echo "$out_n" | tr -d '\r' | xargs)
            
            [[ -z "$start_t" || -z "$out_n" ]] && continue
            
            echo -e "\n${CYAN}🎬 [$no] Rendering:${NC} $out_n"
            
            # Proses FFMPEG
            if [[ "$reframe_mode" == "3" ]]; then
                "$FFMPEG_CMD" -ss "$start_t" -to "$end_t" -i "$full_path" -filter_complex "$vf_params" -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k -pix_fmt yuv420p -movflags +faststart -y -loglevel error -stats "$folder_target/$out_n"
            else
                "$FFMPEG_CMD" -ss "$start_t" -to "$end_t" -i "$full_path" -vf "$vf_params" -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k -pix_fmt yuv420p -movflags +faststart -y -loglevel error -stats "$folder_target/$out_n"
            fi
            
            # Update Stats Global (Mengambil fungsi dari utils.sh)
            CURRENT_COUNT=$(get_total_stats)
            NEW_COUNT=$((CURRENT_COUNT + 1))
            NEW_HASH=$(echo -n "${NEW_COUNT}${SALT_KEY}" | md5sum | cut -d' ' -f1)
            echo "${NEW_COUNT}|${NEW_HASH}" > "$FILE_STATS"
            
            termux-media-scan "$folder_target/$out_n" &>/dev/null &
            ((no++))
        done 3< "$list_file"
        
        termux-media-scan -r "$folder_target" &>/dev/null &
        kirim_laporan_admin 
        
        echo -e "\n${GREEN}[V] SELESAI! Semua potongan tersimpan di: $folder_target${NC}"
        echo -e "${GRAY}---------------------------------------${NC}"
        echo -e "${YELLOW}[1]${WHITE} Potong Video Lain / TXT Lain"
        echo -e "${YELLOW}[2]${WHITE} Kembali ke Menu Utama"
        read -p " Pilihan (1/2) > " setelah_potong
        
        [[ "$setelah_potong" == "2" ]] && break
    done
}