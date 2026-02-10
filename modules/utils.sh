#!/bin/bash
# FILE: modules/utils.sh
# FILE: modules/utils V1.1 UTILS=1.1

# --- FUNGSI AUTO BACKUP & RESTORE LISENSI ---
amankan_lisensi() {
    # KASUS 1: Restore (Habis Install Ulang Termux)
    if [ ! -f "$FILE_LISENSI" ] && [ -f "$FILE_LISENSI_BACKUP" ]; then
        echo -e "\e[1;32m[!] Mendeteksi Cadangan Lisensi di Penyimpanan...\e[0m"
        cp "$FILE_LISENSI_BACKUP" "$FILE_LISENSI"
        echo -e "\e[1;32m[V] Lisensi berhasil dipulihkan otomatis!\e[0m"
        sleep 1
    fi
    # KASUS 2: Backup (Pengguna Baru/Lama)
    if [ -f "$FILE_LISENSI" ]; then
        # Cek apakah isi file berbeda atau file backup belum ada
        if [ ! -f "$FILE_LISENSI_BACKUP" ] || ! cmp -s "$FILE_LISENSI" "$FILE_LISENSI_BACKUP"; then
            cp "$FILE_LISENSI" "$FILE_LISENSI_BACKUP"
        fi
    fi
}

load_user_agent() {
    if [ ! -f "$FILE_UA" ]; then
        echo "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36" > "$FILE_UA"
        echo "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1" >> "$FILE_UA"
        echo "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" >> "$FILE_UA"
    fi
    CUSTOM_UA=$(shuf -n 1 "$FILE_UA" | tr -d '\r')
    if [ -z "$CUSTOM_UA" ]; then CUSTOM_UA="Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"; fi
}

get_total_stats() {
    if [ ! -f "$FILE_STATS" ]; then echo "0"; return; fi
    local data=$(cat "$FILE_STATS")
    local angka=$(echo "$data" | cut -d'|' -f1)
    local hash_lama=$(echo "$data" | cut -d'|' -f2)
    local hash_cek=$(echo -n "${angka}${SALT_KEY}" | md5sum | cut -d' ' -f1)
    if [ "$hash_lama" == "$hash_cek" ]; then echo "$angka"; else echo "0"; fi
}

kirim_laporan_admin() { kirim_data_sheet "Cut Selesai" "Laporan: Selesai memproses job"; }

kirim_data_sheet() {
    local aksi="$1"; local detail="$2"; local total_cut=$(get_total_stats)
    local tipe="Premium"; local cek_trial=$(cat "$FILE_LISENSI" 2>/dev/null)
    [[ "$cek_trial" == *"TRIAL"* ]] && tipe="Trial"
    local json_data="{\"member_id\":\"#$MEMBER_ID\", \"tipe_user\":\"$tipe\", \"android_ver\":\"Android $ANDROID_VER\", \"aksi\":\"$aksi\", \"total_cut\":\"$total_cut\", \"detail\":\"$detail\"}"
    curl -s -L -X POST -H "Content-Type: application/json" -d "$json_data" "$LINK_MONITOR" &>/dev/null &
}