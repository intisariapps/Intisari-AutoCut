#!/bin/bash
# FILE: modules/config.sh
# FILE: modules/config V1.4 (FIXED)

# --- [MANAJEMEN VERSI LOKAL] ---
# (Disinkronkan dengan header file asli)
SYS_VER="6.0"                # Core (main.sh)
MOD_DL_VER="1.3"             # Downloader
MOD_PROC_VER="1.4"           # Processor
MOD_AUTH_VER="4.6"           # Auth
MOD_INST_VER="1.4"           # Installer
MOD_UTILS_VER="1.1"          # Utils
MOD_VIRAL_VER="1.9"          # Viral Downloader

# --- KONFIGURASI SERVER ---
REPO_USER="intisariapps" 
REPO_NAME="Intisari-AutoCut"
BRANCH="main"

LINK_MANIFEST="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH/manifest.txt"
LINK_RAW_MODULES="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH/modules"

# --- PENGATURAN UMUM (UI/UX) ---
LOCAL_VERSION="$SYS_VER" 
ADMIN_WA="628567870040"
# ... (Sisa kode ke bawah biarkan tetap sama) ...
LINK_PASTEBIN="https://gist.githubusercontent.com/faldi-intisariClipper/fcd4a0899553d41981c839fdbe4b58ae/raw/"
LINK_MONITOR="https://script.google.com/macros/s/AKfycbz1snzcZOhlZHvF9piJJJ9tyiQOUsJIkV78yXU8KOdBOhknaz5QZdt6x-RMAVGu0uZA/exec"
LINK_AKSES="-----"
LINK_GRUP_PREMIUM="https://chat.whatsapp.com/C7W3yOK89uu6WV5YVez32W"
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
MEMBER_ID="???"

# --- PATH TOOLS ---
TOOLS_DIR="$HOME/intisari_tools"
FFMPEG_CMD="$TOOLS_DIR/ffmpeg"
YTDLP_CMD="$TOOLS_DIR/yt-dlp"

# --- PATH DATA & BACKUP ---
FILE_LISENSI="/sdcard/Ringtones/.intisari_key"
FILE_LISENSI_BACKUP="/sdcard/Ringtones/.intisari_key" 
FILE_JEJAK_TRIAL="/sdcard/Ringtones/.sys_android_config"
FILE_STATS="/sdcard/Ringtones/.intisari_stats"
SALT_KEY="INTISARI_SECRET_2026"

# --- STRUKTUR FOLDER PENYIMPANAN (SESUAI REQUEST) ---
TXT_SOURCE_DIR="/sdcard/INTISARI_DATA" 
VIDEO_SOURCE_DIR="/sdcard/Video To Clip"
SAVE_DIR="/sdcard/Video To Clip"       # Hasil Youtube
HOOK_DIR="/sdcard/Video Hook"          # Hasil Sosmed (IG/FB/TT)
FILE_UA="$TXT_SOURCE_DIR/user_agent.txt"

# Inisialisasi Folder
mkdir -p "$TXT_SOURCE_DIR" "$SAVE_DIR" "$HOOK_DIR" "$TOOLS_DIR" "/sdcard/Ringtones"
