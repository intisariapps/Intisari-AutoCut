#!/bin/bash
# FILE: modules/auth.sh
# VERSION: V4.7 (Pure Random Persistent ID & Full Integration) AUTH=4.6

# --- 1. IMPORT CONFIGURASI ---
# Kita load variabel dari file config.sh
if [ -f "modules/config.sh" ]; then
    source modules/config.sh
elif [ -f "config.sh" ]; then
    source config.sh
else
    # Fallback jika config tidak terbaca
    LINK_PASTEBIN="https://gist.githubusercontent.com/faldi-intisariClipper/fcd4a0899553d41981c839fdbe4b58ae/raw/"
    FILE_FAKE_ID="/sdcard/Ringtones/.my_device_id" 
    FILE_LISENSI="/sdcard/Ringtones/.intisari_key"
    FILE_JEJAK_TRIAL="/sdcard/Ringtones/.sys_android_config"
    ADMIN_WA="628567870040"
fi

# Pastikan path fallback jika di config kosong
: "${FILE_FAKE_ID:=/sdcard/Ringtones/.my_device_id}"

# --- 2. FUNGSI ID ABADI (PURE RANDOM) ---
get_device_id() {
    # Tentukan target file penyimpanan (Hardcode agar pasti)
    local FILE_TARGET="/sdcard/Ringtones/.my_device_id"

    # --- LOGIKA 1: CEK FILE YANG SUDAH ADA ---
    if [ -f "$FILE_TARGET" ]; then
        # Jika file ditemukan, BACA isinya dan KIRIM keluar
        cat "$FILE_TARGET"
        return # STOP! Tugas selesai.
    fi

    # --- LOGIKA 2: JIKA FILE BELUM ADA (Baru Pertama Kali) ---
    # Buat ID Random (Huruf Besar + Angka, 13 Digit)
    # Contoh Hasil: 858A23BB3XC9A
    local id_baru=$(tr -dc A-Z0-9 < /dev/urandom | head -c 13)

    # Simpan ID baru ini ke folder Ringtones agar jadi ABADI
    echo "$id_baru" > "$FILE_TARGET"

    # Kirim ID baru ini keluar agar bisa dibaca menu
    echo "$id_baru"
}

# --- 3. FUNGSI CEK LISENSI (REQ USER) ---
cek_lisensi_online() {
    local input_key="$1"; local input_id="$2"; local silent_mode="$3"; local gabungan="${input_key}-${input_id}"
    
    # === JALUR TRIAL ===
    if [[ "$input_key" == *"TRIAL"* ]]; then
        [[ "$silent_mode" != "silent" ]] && echo -e "\e[1;34m[*] Memverifikasi Mode Trial...\e[0m"
        
        if [ -f "$FILE_JEJAK_TRIAL" ]; then
            [[ "$silent_mode" != "silent" ]] && echo -e "\n\e[1;41m[X] DEVICE INI SUDAH PERNAH MENGGUNAKAN TRIAL!\e[0m"
            return 1 
        fi

        local bulan_exp="${input_id:0:2}"; local hari_exp="${input_id:2:2}"; local tahun_exp="2026"
        local tgl_hari_ini=$(date +%Y%m%d)
        # Timeout dipercepat jadi 3 detik agar tidak lama
        local tgl_internet=$(curl -s --max-time 3 http://worldtimeapi.org/api/timezone/Asia/Jakarta | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | tr -d '-' 2>/dev/null)
        [[ -n "$tgl_internet" ]] && tgl_hari_ini=$tgl_internet
        local tgl_expired_full="${tahun_exp}${bulan_exp}${hari_exp}"
        
        if [ "$tgl_hari_ini" -gt "$tgl_expired_full" ]; then
            [[ "$silent_mode" != "silent" ]] && echo -e "\n\e[1;31m[!] TANGGAL DI ID EXPIRED ($bulan_exp/$hari_exp)!\e[0m"
            return 1
        fi

        [[ "$silent_mode" != "silent" ]] && echo -e "\e[1;36m[i] Kode Trial Diterima (First Time Device).\e[0m"
        echo "DEVICE_LOCKED_BY_TRIAL_$(date)" > "$FILE_JEJAK_TRIAL"
        MEMBER_ID="TRIAL-OFFLINE"
        return 0
    fi

    # === JALUR PREMIUM ===
    [[ "$silent_mode" != "silent" ]] && echo -e "\e[1;34m[*] Menghubungi Server Intisari...\e[0m"
    DATABASE_KODE=$(curl -s -L "$LINK_PASTEBIN")
    
    if echo "$DATABASE_KODE" | grep -qw "$gabungan"; then
        local baris_data=$(echo "$DATABASE_KODE" | grep -nw "$gabungan" | head -n 1 | cut -d: -f1)
        [[ -n "$baris_data" ]] && MEMBER_ID=$((baris_data + 99))
        [[ "$silent_mode" != "silent" ]] && echo -e "\n\e[1;32m[V] Lisensi Premium Valid! ID: #$MEMBER_ID\e[0m"
        return 0 
    else
        [[ "$silent_mode" != "silent" ]] && echo -e "\n\e[1;31m[X] LISENSI TIDAK TERDAFTAR!\e[0m"
        return 1 
    fi
}

# --- 4. FUNGSI KEAMANAN DIAM-DIAM (REQ USER) ---
# Fungsi ini dipanggil oleh downloader.sh
silent_security_check() {
    # Pastikan variabel FILE_LISENSI terbaca (jika belum didefinisikan global)
    local FILE_LISENSI="/sdcard/Ringtones/.intisari_key"

    # 1. Cek File Lisensi Ada/Tidak
    if [ -f "$FILE_LISENSI" ]; then
        local G_LOKAL=$(cat "$FILE_LISENSI" | tr -d '\r' | xargs)
        
        # Pecah String: AUTOCUT-KEY (Depan) dan ID (Belakang)
        local K_LOKAL=$(echo "$G_LOKAL" | rev | cut -d'-' -f2- | rev)
        local I_LOKAL=$(echo "$G_LOKAL" | rev | cut -d'-' -f1 | rev)
        
        # 2. Cek Hardware Lock (Jika bukan Trial)
        if [[ "$K_LOKAL" != *"TRIAL"* ]]; then
             local MY_CURRENT_ID=$(get_device_id)
             if [ "$I_LOKAL" != "$MY_CURRENT_ID" ]; then
						clear
				# Pastikan variabel warna didefinisikan (jika belum ada di script utama)
				CYAN='\033[0;36m'
				GRAY='\033[1;30m'
				RED='\033[1;31m'  # Merah untuk Alert
				NC='\033[0m'

				echo -e "${CYAN}"
				echo "  ___ _   _ _____ ___ ____   _    ____ ___ "
				echo " |_ _| \ | |_   _|_ _/ ___| / \  |  _ \_ _| "
				echo "  | ||  \| | | |  | |\___ \/ _ \ | |_) | |  "
				echo "  | || |\  | | |  | | ___) / ___ \|  _ <| |  "
				echo " |___|_| \_| |_| |___|____/_/   \_\_| \_\___| " 
				echo -e "${NC}"
				
				echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
				# PERBAIKAN DI SINI: Hapus tanda $ di luar kurung siku dan ganti warnanya jadi merah
				echo -e "${RED}[!]SECURITY ALERT: ID BERUBAH FILE PINDAH HP[!]${NC}"
				echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
				
				# --- BAGIAN TAMBAHAN: OPSI KE MENU AKTIVASI ---
				echo -e "\n\e[1;33mID Terdaftar di File : $I_LOKAL\e[0m"
				echo -e "\e[1;32mID Perangkat Saat Ini: $MY_CURRENT_ID\e[0m"
				
				echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
				echo -e " LISENSI ANDA TIDAK COCOK DENGAN PERANGKAT INI"
				echo -e "         DAFTARKAN ULANG PERANGKAT ANDA         "
				echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                
                # --- PERBAIKAN DI SINI (Gunakan read -p) ---
                read -p "Buka Menu Aktivasi? (y/n) : " PIL_RECOVERY
                
                if [[ "$PIL_RECOVERY" == "y" || "$PIL_RECOVERY" == "Y" ]]; then
                    echo -e "\n\e[1;32m[*] Membuka Menu Aktivasi...\e[0m"
                    sleep 1
                    
                    # Panggil fungsi menu_aktivasi
                    menu_aktivasi
                    
                    # Exit 0 agar script tidak lanjut ke proses di bawahnya (double run)
                    exit 0 
                else
                    echo -e "\e[1;31m[!] Akses Ditolak. Menutup Script...\e[0m"
                    exit 1
                fi
                # ----------------------------------------------
             fi
        fi
    fi
}


    # --- 5. MENU UTAMA (UPDATE FITUR PINDAH PERANGKAT) ---
menu_aktivasi() {
    # --- KONFIGURASI ---
    local ADMIN_WA="628567870040"  # Nomor Admin (Format 62...)
    local FILE_LISENSI="/sdcard/Ringtones/.intisari_key"
    local FILE_FAKE_ID="/sdcard/Ringtones/.my_device_id"
    local LINK_GRUP_PREMIUM="https://chat.whatsapp.com/GANTI_DENGAN_LINK_GRUP_ANDA"

    # --- FUNGSI BANTUAN ---
    get_actual_id() {
        # Cek apakah ada ID Custom?
        if [ -f "$FILE_FAKE_ID" ]; then
            cat "$FILE_FAKE_ID" | tr -d '\r' | xargs
        else
            # Jika tidak ada custom, ambil ID asli (pastikan fungsi get_device_id ada di script utama)
            get_device_id 
        fi
    }

    # --- LOGIKA AUTO-LOGIN (Cek Sekali di Awal) ---
    local CURRENT_ID=$(get_actual_id)
    
    if [ -f "$FILE_LISENSI" ]; then
        local CEK_ISI=$(cat "$FILE_LISENSI" | tr -d '\r' | xargs)
        local ID_DI_FILE=$(echo "$CEK_ISI" | rev | cut -d'-' -f1 | rev)
        
        # Jika ID di file COCOK dengan ID Perangkat (baik asli/custom)
        if [ "$ID_DI_FILE" == "$CURRENT_ID" ]; then
             # silent_security_check  <-- Hapus pagar jika fungsi ini ada
             echo -e "\e[1;32m[V] Auto-Login Berhasil! (ID: $CURRENT_ID)\e[0m"
             sleep 1
             return 0
        fi
    fi

    # --- MENU LOOPING UTAMA (ANTI-LOLOS) ---
    while true; do
        # [PENTING] Ambil ID di DALAM LOOP agar tampilan selalu update setelah Custom ID
        CURRENT_ID=$(get_actual_id)
        
        clear
        echo -e "\e[1;36m"
        echo "  ___ _    _ _____ ___ ____    _    ____ ___ "
        echo " |_ _| \ | |_   _|_ _/ ___| / \  |  _ \_ _| "
        echo "  | ||  \| | | |  | |\___ \/ _ \ | |_) | |  "
        echo "  | || |\  | | |  | | ___) / ___ \|  _ <| |  "
        echo " |___|_| \_| |_| |___|____/_/   \_\_| \_\___| "
        echo -e "\e[1;36m    AKTIVASI INTISARI AUTO-CUT SYSTEM    \e[0m"
        echo -e "\e[0m"
        echo -e "\e[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo -e "\e[1;36m========================================\e[0m"
        echo -e "\e[1;37mID PERANGKAT :\e[1;32m $CURRENT_ID\e[0m"
        echo -e "----------------------------------------"
        echo -e "\e[1;33m[1] \e[1;37mMasukan Lisensi (Login)\e[0m"
        echo -e "\e[1;33m[2] \e[1;37mDaftarkan Perangkat Baru (WA)\e[0m"
        echo -e "\e[1;33m[3] \e[1;37mPindah Perangkat (Reset ID)\e[0m"
        echo -e "\e[1;35m[4] \e[1;37mCek Lisensi Sebelumnya\e[0m"
        echo -e "\e[1;35m[5] \e[1;37mCustom ID Perangkat (Manual)\e[0m"
        echo -e "\e[1;31m[6] \e[1;37mKeluar / Exit\e[0m"
        echo -e "----------------------------------------"
        read -p "Pilihan > " opsi
        
        case $opsi in
            1)
                echo -e "\e[1;30mPaste Kode Lengkap (Cth: KEY-BLABLA-$CURRENT_ID)\e[0m"
                read -p "INPUT LISENSI : " USER_INPUT
                if [ -z "$USER_INPUT" ]; then continue; fi
                
                local IN_ID=$(echo "$USER_INPUT" | rev | cut -d'-' -f1 | rev)
                local IN_KEY=$(echo "$USER_INPUT" | rev | cut -d'-' -f2- | rev)
                
                # Validasi ID
                if [[ "$IN_KEY" != *"TRIAL"* ]]; then
                    if [ "$IN_ID" != "$CURRENT_ID" ]; then
                        echo -e "\n\e[1;41m[X] ID PERANGKAT SALAH!\e[0m"
                        echo -e "Lisensi ini untuk ID: $IN_ID"
                        echo -e "ID Perangkat Anda   : $CURRENT_ID"
                        sleep 3; continue
                    fi
                fi

                echo -e "\n\e[1;34m[*] Memverifikasi...\e[0m"
                
                # Pastikan fungsi 'cek_lisensi_online' ada di script utama
                if cek_lisensi_online "$IN_KEY" "$IN_ID"; then
                    echo "$USER_INPUT" > "$FILE_LISENSI"
                    
                    if [ ! -f "/sdcard/Ringtones/.sudah_join_grup" ] && [ -n "$LINK_GRUP_PREMIUM" ]; then
                        termux-open-url "$LINK_GRUP_PREMIUM"
                        touch "/sdcard/Ringtones/.sudah_join_grup"
                    fi
                    
                    echo -e "\e[1;32m[V] Login Sukses!\e[0m"
                    sleep 1
                    # BREAK untuk keluar dari while loop dan lanjut ke script utama
                    break 
                else
                    sleep 2
                fi
                ;;

            2)
                # DAFTAR BARU (WA ADMIN 08567870040)
                echo -e "\n\e[1;32m[*] Membuka WhatsApp Admin...\e[0m"
                PESAN="Halo Admin, saya mau beli lisensi untuk Device Baru.\nID Saya: *$CURRENT_ID*"
                PESAN_URL=$(echo -e "$PESAN" | sed 's/ /%20/g' | sed 's/\n/%0A/g')
                termux-open-url "https://wa.me/$ADMIN_WA?text=$PESAN_URL"
                sleep 2 ;;

            3)
                # RESET ID
                echo -e "\n\e[1;34m[*] Mengumpulkan data pemindahan...\e[0m"
                if [ -f "$FILE_LISENSI" ]; then
                    DATA_LAMA=$(cat "$FILE_LISENSI")
                    STATUS_FILE="(File Lisensi Ditemukan)"
                else
                    DATA_LAMA="TIDAK_ADA_FILE"
                    STATUS_FILE="(File Hilang/Terhapus)"
                fi

                echo -e "\e[1;32m[*] Mengirim Request Reset ke WA...\e[0m"
                PESAN="Halo Admin, saya mau PINDAH PERANGKAT (Reset ID).\n\n"
                PESAN+=">> ID BARU: *$CURRENT_ID*\n"
                PESAN+=">> LISENSI LAMA: $DATA_LAMA\n"
                PESAN+=">> STATUS: $STATUS_FILE\n\n"
                PESAN+="Mohon bantuannya untuk update ID."

                PESAN_URL=$(echo -e "$PESAN" | sed 's/ /%20/g' | sed 's/\n/%0A/g')
                termux-open-url "https://wa.me/$ADMIN_WA?text=$PESAN_URL"
                sleep 2 ;;
            
            4)
                # CEK HISTORY
                echo -e "\n\e[1;34m[*] Mengecek riwayat lisensi...\e[0m"
                if [ -f "$FILE_LISENSI" ]; then
                    ISI_LAMA=$(cat "$FILE_LISENSI")
                    echo -e "\e[1;32m[+] Ditemukan Data Lama:\e[0m"
                    echo -e "\e[1;37m----------------------------------------\e[0m"
                    echo -e "$ISI_LAMA"
                    echo -e "\e[1;37m----------------------------------------\e[0m"
                    echo -e "Silakan copy data di atas dan pilih menu [1]"
                else
                    echo -e "\e[1;31m[!] Tidak ada riwayat lisensi ditemukan.\e[0m"
                fi
                echo ""
                read -p "Tekan Enter untuk kembali..."
                ;;

            5)
                # --- PERBAIKAN CUSTOM ID (LANGSUNG TAMPIL) ---
                clear
                echo -e "\e[1;36m========================================\e[0m"
                echo -e "\e[1;33m       CUSTOM DEVICE ID (MANUAL)        \e[0m"
                echo -e "\e[1;36m========================================\e[0m"
                echo -e "\e[1;31m[!] PERHATIAN:\e[0m"
                echo -e "Mengubah ID akan \e[1;31mMENGHAPUS LISENSI AKTIF\e[0m."
                echo -e "Gunakan hanya huruf & angka tanpa spasi."
                echo -e "----------------------------------------"
                
                echo -e "ID Saat Ini: \e[1;32m$CURRENT_ID\e[0m"
                echo ""
                
                read -p "Yakin ubah ID? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    echo ""
                    read -p "Masukkan ID Baru : " NEW_CUSTOM_ID
                    
                    # Validasi: Hanya Alphanumeric & tidak kosong
                    if [[ "$NEW_CUSTOM_ID" =~ ^[a-zA-Z0-9]+$ ]] && [ ! -z "$NEW_CUSTOM_ID" ]; then
                        
                        # 1. Simpan ID Baru
                        echo "$NEW_CUSTOM_ID" > "$FILE_FAKE_ID"
                        
                        # 2. Hapus Lisensi Lama (Wajib reset)
                        if [ -f "$FILE_LISENSI" ]; then
                            rm "$FILE_LISENSI"
                        fi
                        
                        echo -e "\n\e[1;32m[V] ID BERHASIL DIUBAH!\e[0m"
                        echo -e "ID Baru: $NEW_CUSTOM_ID"
                        sleep 1.5
                        
                        # 3. FORCE REFRESH: Gunakan 'continue' agar loop mulai dari atas
                        #    dan mengambil ID baru di baris 'CURRENT_ID=$(get_actual_id)'
                        continue 
                    else
                        echo -e "\n\e[1;31m[X] ID Gagal! Jangan pakai spasi/simbol.\e[0m"
                        sleep 2
                    fi
                else
                    echo -e "\e[1;33mBatal.\e[0m"
                    sleep 1
                fi
                ;;
                
            6) 
                # Exit script sepenuhnya. Tidak akan lanjut ke main menu.
                echo "Keluar..."
                exit 0 
                ;;
            
            *) echo "Pilihan tidak valid."; sleep 1 ;;
        esac
    done

    # Jika loop break (karena login sukses), script lanjut ke bawah sini
    return 0
}

# --- BAGIAN EKSEKUSI ---
# Panggil fungsi