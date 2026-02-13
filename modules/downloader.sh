#!/bin/bash
# FILE: modules/downloader.sh
# FILE: modules/downloader V1.4 DOWNLOADER=1.4

# --- [1] HEADER VISUAL KHUSUS YOUTUBE ---
header_youtube() {
    # 1. HEADER PREMIUM
	clear
    echo -e "${CYAN}"
    echo "  ___ _   _ _____ ___ ____   _    ____ ___ "
    echo " |_ _| \ | |_   _|_ _/ ___| / \  |  _ \_ _| "
    echo "  | ||  \| | | |  | |\___ \/ _ \ | |_) | |  "
    echo "  | || |\  | | |  | | ___) / ___ \|  _ <| |  "
    echo " |___|_| \_| |_| |___|____/_/   \_\_| \_\___| "
    echo "        YOUTUBE (DownLoder)  $MOD_DL_VER"
	echo "      [🌐] Fodcast | LiveStream | All Video	"
    echo -e "${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"


}

# --- [2] LOGIKA UTAMA DOWNLOADER ---
run_youtube_downloader() {
    # Loop agar user bisa download berkali-kali tanpa terlempar ke menu utama
    while true; do
        # 1. Panggil Header DULUAN sebelum minta input
        header_youtube 
        
        # Security & Logging berjalan di background (tidak mengganggu tampilan)
        silent_security_check
        load_user_agent
        
        echo -e "${WHITE}  YOUTUBE (DownLoder) ${NC}"
        echo -e "${GRAY}  Direktori: $(basename "$VIDEO_SOURCE_DIR")${NC}"
        echo -e "${GRAY}  Tekan 'x' untuk kembali ke menu utama${NC}\n"
        
        # 2. INPUT LINK (Di sini letak inputnya, DI DALAM MODUL)
        echo -e "\e[1;36m[?] Tempelkan Link YouTube di sini:\e[0m"
        read -p "Link > " link

        # Logika Keluar
        if [[ "$link" == "x" || "$link" == "X" ]]; then
            return # Kembali ke main.sh
        fi

        if [ -z "$link" ]; then
            echo -e "\e[1;31m[!] Link tidak boleh kosong!\e[0m"
            sleep 1
            continue
        fi

        # 3. PROSES DOWNLOAD
        kirim_data_sheet "Download YouTube" "Mulai: $link"
        echo -e "\n\e[1;34m[*] Mengambil info video... (Mohon tunggu)\e[0m"
        
        # Ambil Judul
        RAW_TITLE=$("$YTDLP_CMD" --get-title --skip-download "$link" 2>/dev/null)
        
        # Bersihkan Judul untuk Nama File
        CLEAN_TITLE=$(echo "$RAW_TITLE" | awk '{print $1"_"$2"_"$3}' | sed 's/[^a-zA-Z0-9_]//g' | sed 's/^_*//' | sed 's/_*$//')
        
        if [ -z "$CLEAN_TITLE" ]; then 
            BASE_NAME="Video_Intisari_$(date +%s)"
            TAMPILAN_JUDUL="Judul Tidak Terdeteksi"
        else 
            BASE_NAME="${CLEAN_TITLE}_$(date +%s)"
            TAMPILAN_JUDUL="$RAW_TITLE"
        fi
        
        FILE_OUTPUT="$BASE_NAME.mp4"

        # Tampilkan Info Video
        echo -e "\e[1;32m[+] Ditemukan: \e[1;37m$TAMPILAN_JUDUL\e[0m"
        
        # Pilihan Kualitas
        echo -e "\e[1;30m----------------------------------\e[0m"
        echo "Pilih Kualitas: [1] 1080p (FHD)"
		echo "Pilih Kualitas: [2] 720p (HD)"
        read -p "Pilihan (1/2): " qual

        echo -e "\e[1;33m[*] Memulai Download High-Speed...\e[0m"

        # Eksekusi YT-DLP
        if [ "$qual" == "1" ]; then
            "$YTDLP_CMD" --external-downloader aria2c --external-downloader-args "aria2c:-x 8 -s 8 -k 1M" --geo-bypass --user-agent "$CUSTOM_UA" -f "bestvideo[height<=1080]+bestaudio/best" --merge-output-format mp4 -o "$SAVE_DIR/$FILE_OUTPUT" "$link"
        else
            "$YTDLP_CMD" --external-downloader aria2c --external-downloader-args "aria2c:-x 8 -s 8 -k 1M" --geo-bypass --user-agent "$CUSTOM_UA" -f "bestvideo[height<=720]+bestaudio/best" --merge-output-format mp4 -o "$SAVE_DIR/$FILE_OUTPUT" "$link"
        fi

        # Cek Keberhasilan
        if [ -f "$SAVE_DIR/$FILE_OUTPUT" ]; then
            echo -e "\n\e[1;32m[V] DOWNLOAD SUKSES!\e[0m"
            echo -e "Lokasi: $SAVE_DIR/$FILE_OUTPUT"
            
            # --- FITUR INTEGRASI PROCESSOR (AUTO-CUT) ---
            # Menyiapkan file timestamps otomatis (Fitur lama Anda)
            FILE_TXT="$TXT_SOURCE_DIR/$BASE_NAME.txt"
            echo "# Timestamp for: $TAMPILAN_JUDUL" > "$FILE_TXT"
            echo "# Format: Start|End|Name" >> "$FILE_TXT"
            
            echo -e "\e[1;30m----------------------------------\e[0m"
            echo -e "\e[1;33mApa langkah selanjutnya?\e[0m"
            echo "[1] Potong Video Ini (Auto-Cut)"
            echo "[2] Download Video Lain"
            echo "[3] Kembali ke Menu Utama"
            read -p "Pilihan > " next_act
            
            case $next_act in
                1) proses_potong "$SAVE_DIR/$FILE_OUTPUT"; return ;; # Pindah ke modul Processor
                2) continue ;; # Ulangi loop (kembali ke input link)
                *) return ;; # Keluar ke main.sh
            esac
        else 
            echo -e "\n\e[1;31m[!] DOWNLOAD GAGAL. Cek koneksi atau link.\e[0m"
            sleep 2
        fi
    done
}

# --- FUNGSI SOSMED LAINNYA (Biarkan Saja) ---
# --- [1] HEADER KHUSUS SOSIAL MEDIA ---
header_sosmed() {
# 1. HEADER PREMIUM
	clear
    echo -e "${CYAN}"
    echo "  ___ _   _ _____ ___ ____   _    ____ ___ "
    echo " |_ _| \ | |_   _|_ _/ ___| / \  |  _ \_ _| "
    echo "  | ||  \| | | |  | |\___ \/ _ \ | |_) | |  "
    echo "  | || |\  | | |  | | ___) / ___ \|  _ <| |  "
    echo " |___|_| \_| |_| |___|____/_/   \_\_| \_\___| "
    echo "      	SOSIAL MEDIA (DownLoder)  $MOD_DL_VER"
	echo "      [🌐] TikTok | Instagram | Facebook	"
    echo -e "${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- [2] FUNGSI UTAMA SOSMED ---
run_sosmed_downloader() {
    local choice="$1" # Mengambil pilihan dari menu main.sh
    local PLAT=""
    local PREFIX=""

    # Tentukan Platform berdasarkan pilihan dari main.sh
    if [ "$choice" == "2" ]; then PLAT="TikTok"; PREFIX="TT"; fi
    if [ "$choice" == "3" ]; then PLAT="Instagram"; PREFIX="IG"; fi
    if [ "$choice" == "4" ]; then PLAT="Facebook"; PREFIX="FB"; fi

    # Loop agar user tetap di dalam modul ini sampai menekan 'x'
    while true; do
        header_sosmed
        silent_security_check
        kirim_data_sheet "Download $PLAT" "User Masuk Menu $PLAT"

        echo -e "${WHITE}  SOSIAL MEDIA (DownLoder) ${NC}"
        echo -e "${GRAY}  Direktori : $(basename "$HOOK_DIR")${NC}"
        echo -e "${GRAY}  Tekan 'x' untuk kembali ke menu utama${NC}\n"
        
        # INPUT LINK DI DALAM MODUL
        read -p "Masukkan Link $PLAT: " link

        # Cek jika user ingin kembali
        if [[ "$link" == "x" || "$link" == "X" ]]; then
            return # Keluar dari fungsi, kembali ke main.sh
        fi

        # Cek jika link kosong
        if [ -z "$link" ]; then
            echo -e "\e[1;31m[!] Link tidak boleh kosong!\e[0m"
            sleep 1
            continue
        fi

        # PROSES DOWNLOAD
        FILE_HK="${PREFIX}_$(date +%s).mp4"
        echo -e "\n\e[1;34m[*] Sedang Mendownload $PLAT... \e[0m"
        echo -e "\e[1;30mTarget: $HOOK_DIR/$FILE_HK\e[0m"
        
        # Eksekusi Download
        "$YTDLP_CMD" -o "$HOOK_DIR/$FILE_HK" "$link"
        
        # Cek Keberhasilan
        if [ -f "$HOOK_DIR/$FILE_HK" ]; then
            termux-media-scan "$HOOK_DIR/$FILE_HK" &>/dev/null
            echo -e "\n\e[1;32m[V] DOWNLOAD BERHASIL!\e[0m"
            echo -e "\e[1;30m-----------------------------------------\e[0m"
            echo -e "\e[1;37mApa tindakan selanjutnya?\e[0m"
            echo " [1] Download Video $PLAT Lagi"
            echo " [2] Kembali ke Menu Utama"
            read -p "Pilihan > " nx

            if [[ "$nx" == "1" ]]; then
                proses_potong "$HOOK_DIR/$FILE_HK"
                return # Selesai potong kembali ke menu utama
            elif [[ "$nx" == "3" ]]; then
                return # Kembali ke menu utama
            else
                continue # Download lagi (loop)
            fi
        else 
            echo -e "\e[1;31m[!] Gagal mendownload video.\e[0m"
            echo "Mungkin link salah atau video di-private."
            read -p "Tekan Enter untuk mencoba lagi..." 
        fi
    done
}