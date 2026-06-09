#!/usr/bin/env bash
# Regression: Read scroll, Mushaf/Juz, Koleksi Juz Amma summary + program, nav smoke.
# Usage: ./scripts/regression_read_scroll.sh <device-serial>
set -euo pipefail

SERIAL="${1:?Usage: $0 <device-serial>}"
PKG="com.tursinalabs.quranoffline"
PYTHON="${PYTHON:-py -3}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${ROOT}/.regression_shots/${SERIAL}"
mkdir -p "$OUT_DIR"

log() { echo "[$SERIAL] $*"; }
fail() { echo "[$SERIAL] FAIL: $*" >&2; exit 1; }

dump_ui() {
  local tag="$1"
  local attempt=0
  while [[ $attempt -lt 3 ]]; do
    adb -s "$SERIAL" shell "uiautomator dump /sdcard/ui_reg.xml && cat /sdcard/ui_reg.xml" \
      > "${OUT_DIR}/${tag}.xml" 2>/dev/null || true
    sed -i '1{/^UI hierchary dumped/d;}' "${OUT_DIR}/${tag}.xml" 2>/dev/null || \
      sed -i '' '1{/^UI hierchary dumped/d;}' "${OUT_DIR}/${tag}.xml" 2>/dev/null || true
    if [[ -s "${OUT_DIR}/${tag}.xml" ]]; then
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 2
  done
  fail "UI dump empty for ${tag}"
}

grep_ui() {
  local pattern="$1"
  local file="$2"
  grep -qiE "$pattern" "$file"
}

tap_label_exact() {
  local label="$1"
  local xml="$2"
  $PYTHON - "$label" "$xml" <<'PY'
import html, re, sys
label, path = sys.argv[1], sys.argv[2]
xml = open(path, encoding="utf-8", errors="ignore").read()
needle = label.lower().strip()
pat = re.compile(
    r'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
)
for m in pat.finditer(xml):
    val = html.unescape(m.group(1)).replace("&#10;", "\n").strip()
    if val.lower() != needle:
        continue
    x1, y1, x2, y2 = map(int, m.group(2, 3, 4, 5))
    print((x1 + x2) // 2, (y1 + y2) // 2)
    sys.exit(0)
sys.exit(1)
PY
}

tap_label() {
  local label="$1"
  local xml="$2"
  $PYTHON - "$label" "$xml" <<'PY'
import html, re, sys
label, path = sys.argv[1], sys.argv[2]
xml = open(path, encoding="utf-8", errors="ignore").read()
needle = label.lower().strip()
pat = re.compile(
    r'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
)
rows = []
for m in pat.finditer(xml):
    val = html.unescape(m.group(1)).replace("&#10;", "\n").strip()
    if not val:
        continue
    x1, y1, x2, y2 = map(int, m.group(2, 3, 4, 5))
    rows.append((val, x1, y1, x2, y2))
for val, x1, y1, x2, y2 in rows:
    if val.lower() == needle:
        print((x1 + x2) // 2, (y1 + y2) // 2)
        sys.exit(0)
for val, x1, y1, x2, y2 in rows:
    if needle in val.lower():
        print((x1 + x2) // 2, (y1 + y2) // 2)
        sys.exit(0)
sys.exit(1)
PY
}

tap_text_or_label() {
  local label="$1"
  local xml="$2"
  if read -r tx ty < <(tap_label "$label" "$xml"); then
    echo "$tx $ty"
    return 0
  fi
  $PYTHON - "$label" "$xml" <<'PY'
import html, re, sys
label, path = sys.argv[1], sys.argv[2]
xml = open(path, encoding="utf-8", errors="ignore").read()
needle = label.lower().strip()
pat = re.compile(
    r'(?:text|content-desc)="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
)
rows = []
for m in pat.finditer(xml):
    val = html.unescape(m.group(1)).replace("&#10;", "\n").strip()
    if not val:
        continue
    x1, y1, x2, y2 = map(int, m.group(2, 3, 4, 5))
    rows.append((val, x1, y1, x2, y2))
for val, x1, y1, x2, y2 in rows:
    if val.lower() == needle:
        print((x1 + x2) // 2, (y1 + y2) // 2)
        sys.exit(0)
for val, x1, y1, x2, y2 in rows:
    if needle in val.lower():
        print((x1 + x2) // 2, (y1 + y2) // 2)
        sys.exit(0)
sys.exit(1)
PY
}

bounds_top_for_label() {
  local label="$1"
  local xml="$2"
  $PYTHON - "$label" "$xml" <<'PY'
import html, re, sys
label, path = sys.argv[1], sys.argv[2]
xml = open(path, encoding="utf-8", errors="ignore").read()
needle = label.lower().strip()
pat = re.compile(
    r'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
)
rows = []
for m in pat.finditer(xml):
    val = html.unescape(m.group(1)).replace("&#10;", "\n").strip()
    if not val:
        continue
    rows.append((val, int(m.group(3))))
for val, y1 in rows:
    if val.lower() == needle:
        print(y1)
        sys.exit(0)
for val, y1 in rows:
    if needle in val.lower():
        print(y1)
        sys.exit(0)
print(-1)
PY
}

launch_app() {
  # Force-stop resets the navigation stack; DB and prefs are kept.
  adb -s "$SERIAL" shell am force-stop "${PKG}" >/dev/null 2>&1 || true
  sleep 1
  adb -s "$SERIAL" shell am start -n "${PKG}/.MainActivity" >/dev/null 2>&1 \
    || adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null
  sleep 5
}

go_back() {
  adb -s "$SERIAL" shell input keyevent KEYCODE_BACK
  sleep 1
}

screenshot_hash() {
  local png="$1"
  md5sum "$png" 2>/dev/null | awk '{print $1}' \
    || md5 -q "$png" 2>/dev/null \
    || wc -c < "$png"
}

scroll_list() {
  local before_png="$1"
  local after_tag="$2"
  local before_hash
  before_hash="$(screenshot_hash "$before_png")"
  local xs=("$CX")
  if [[ "$W" -ge 1200 ]]; then
    xs=("160" "$CX")
  fi
  local y_mid=$((H / 2))
  local y_start=$((y_mid + H / 6))
  local y_end=$((y_mid - H / 6))
  for x in "${xs[@]}"; do
    local attempt=0
    while [[ $attempt -lt 3 ]]; do
      adb -s "$SERIAL" shell input swipe "$x" "$y_start" "$x" "$y_end" 700
      sleep 1
      adb -s "$SERIAL" exec-out screencap -p > "${OUT_DIR}/${after_tag}.png"
      local after_hash
      after_hash="$(screenshot_hash "${OUT_DIR}/${after_tag}.png")"
      if [[ "$after_hash" != "$before_hash" ]]; then
        log "Scroll OK at x=${x} (attempt $((attempt + 1)))"
        dump_ui "$after_tag"
        return 0
      fi
      attempt=$((attempt + 1))
    done
  done
  fail "List did not scroll (screenshot unchanged)"
}

tap_read_mode() {
  local mode="$1"
  local xml="$2"
  if read -r mx my < <(tap_label_exact "$mode" "$xml"); then
    adb -s "$SERIAL" shell input tap "$mx" "$my"
    return 0
  fi
  # Fallback: Surah | Juz | Mushaf segment row in app bar (~y 344 on 2400px phone).
  local x
  case "$mode" in
    Surah) x=$((W / 6)) ;;
    Juz) x=$((W / 2)) ;;
    Mushaf|Halaman) x=$((W * 5 / 6)) ;;
    *) fail "Unknown read mode: $mode" ;;
  esac
  local y=$((H / 7))
  adb -s "$SERIAL" shell input tap "$x" "$y"
}

tap_nav() {
  local label="$1"
  dump_ui "_nav_${label// /_}"
  read -r nx ny < <(tap_label "$label" "${OUT_DIR}/_nav_${label// /_}.xml") \
    || read -r nx ny < <(tap_text_or_label "$label" "${OUT_DIR}/_nav_${label// /_}.xml") \
    || fail "Could not find nav tab: ${label}"
  adb -s "$SERIAL" shell input tap "$nx" "$ny"
  sleep 2
}

complete_onboarding_if_needed() {
  local xml="$1"
  if ! grep_ui "Pilih bahasa|Choose language" "$xml"; then
    return 1
  fi
  log "Complete language onboarding (Bahasa Indonesia)"
  if read -r ox oy < <(tap_label "Bahasa Indonesia" "$xml"); then
    adb -s "$SERIAL" shell input tap "$ox" "$oy"
    sleep 10
    return 0
  fi
  fail "Could not find Bahasa Indonesia onboarding option"
}

wait_until_read_ready() {
  local tag="$1"
  local mode="${2:-read}"
  local attempt=0
  local max_attempts=30
  local ready_pat="Al-Fatihah|Surah|Baca"
  if [[ "$mode" == "juz" ]]; then
    ready_pat="Baca Juz|Read Juz|Juz 1|Juz Amma"
  elif [[ "$mode" == "mushaf" ]]; then
    ready_pat="Halaman|Page|Mushaf"
  elif [[ "$mode" == "library" ]]; then
    ready_pat="Juz Amma|Ayat dihafal|Ayahs memorized|Koleksi pribadi"
  elif [[ "$mode" == "juz_amma" ]]; then
    ready_pat="Metode terstruktur|Structured method|An-Nas|Program"
  fi
  while [[ $attempt -lt $max_attempts ]]; do
    dump_ui "$tag"
    grep -q "com.tursinalabs.quranoffline" "${OUT_DIR}/${tag}.xml" \
      || fail "Quran app not in foreground"
    if grep_ui "Quran Offline|Read the Quran offline|Importing" "${OUT_DIR}/${tag}.xml"; then
      log "Waiting for splash/import ($((attempt + 1))/${max_attempts})..."
      sleep 5
      attempt=$((attempt + 1))
      continue
    fi
    if complete_onboarding_if_needed "${OUT_DIR}/${tag}.xml"; then
      attempt=$((attempt + 1))
      continue
    fi
    if grep_ui "$ready_pat" "${OUT_DIR}/${tag}.xml"; then
      return 0
    fi
    log "Waiting for ${mode} ($((attempt + 1))/${max_attempts})..."
    sleep 5
    attempt=$((attempt + 1))
  done
  fail "${mode} did not load in time"
}

assert_no_crash() {
  local xml="$1"
  grep -q "com.tursinalabs.quranoffline" "$xml" \
    || fail "App left foreground (possible crash)"
  if grep_ui "RenderFlex overflowed|has overflowed|FlutterError" "$xml"; then
    fail "Visible error/overflow in UI"
  fi
}

is_device_friday() {
  adb -s "$SERIAL" shell date 2>/dev/null | grep -qiE 'Fri|Friday|Jumat|Jum'
}

regression_friday_setoran() {
  local xml="$1"
  log "Friday detected — verify setoran line inside Juz Amma card"
  grep_ui "\[Jumat\] Setoran:|\[Friday\] Setoran:" "$xml" \
    || fail "Friday setoran line missing in Juz Amma card"
  grep_ui "surat minggu ini|surahs this week" "$xml" \
    || fail "Friday setoran count line incomplete in card"

  log "Open Juz Amma full screen from card, then Setoran Jumat"
  if read -r jx jy < <(tap_text_or_label "Juz Amma" "$xml"); then
    adb -s "$SERIAL" shell input tap "$jx" "$jy"
  else
    adb -s "$SERIAL" shell input tap "$CX" 400
  fi
  sleep 2
  dump_ui "_juz_amma_friday"
  if read -r sx sy < <(tap_text_or_label "Mulai setoran Jumat" "${OUT_DIR}/_juz_amma_friday.xml"); then
    adb -s "$SERIAL" shell input tap "$sx" "$sy"
  elif read -r sx sy < <(tap_text_or_label "Start Friday setoran" "${OUT_DIR}/_juz_amma_friday.xml"); then
    adb -s "$SERIAL" shell input tap "$sx" "$sy"
  elif read -r sx sy < <(tap_text_or_label "Setoran Jumat" "${OUT_DIR}/_juz_amma_friday.xml"); then
    adb -s "$SERIAL" shell input tap "$sx" "$sy"
  else
    fail "Could not open Setoran Jumat from Juz Amma screen"
  fi
  sleep 2
  dump_ui "06b_friday_setoran"
  assert_no_crash "${OUT_DIR}/06b_friday_setoran.xml"
  grep_ui "Setoran Jumat|Friday setoran" "${OUT_DIR}/06b_friday_setoran.xml" \
    || fail "Friday setoran screen did not open"
  grep_ui "Ulang hafalan|Review Sat|Catatan mandiri|Self-practice" \
    "${OUT_DIR}/06b_friday_setoran.xml" \
    || fail "Friday setoran hint/note missing"

  if grep_ui "Belum ada hafalan baru|No new memorization this week" \
    "${OUT_DIR}/06b_friday_setoran.xml"; then
    log "Friday setoran queue empty (OK — no items this week)"
    go_back
    dump_ui "06c_back_library_friday"
    grep_ui "Juz Amma|Ayat dihafal" "${OUT_DIR}/06c_back_library_friday.xml" \
      || fail "Did not return to Koleksi after empty setoran"
    return 0
  fi

  log "Open first queue item (An-Nas or first surah)"
  if read -r qx qy < <(tap_text_or_label "An-Nas" "${OUT_DIR}/06b_friday_setoran.xml"); then
    adb -s "$SERIAL" shell input tap "$qx" "$qy"
  else
    # Tap first list row below the hint (center of screen).
    adb -s "$SERIAL" shell input tap "$CX" $((H / 3))
  fi
  sleep 2
  dump_ui "06d_setoran_session"
  assert_no_crash "${OUT_DIR}/06d_setoran_session.xml"
  grep_ui "Mode setoran|Setoran mode" "${OUT_DIR}/06d_setoran_session.xml" \
    || fail "Setoran session screen missing"
  grep_ui "Sudah benar|Correct" "${OUT_DIR}/06d_setoran_session.xml" \
    || fail "Fade setoran correct button missing"
  grep_ui "Perlu ulang|Try again" "${OUT_DIR}/06d_setoran_session.xml" \
    || fail "Fade setoran retry button missing"
  grep_ui "sketsa|sketch|samar|faint" "${OUT_DIR}/06d_setoran_session.xml" \
    || fail "Fade mode hint missing"
  grep_ui "Putar audio|Play ayah" "${OUT_DIR}/06d_setoran_session.xml" \
    || fail "Play audio control missing"
  grep_ui "Rekam bacaan|Record recitation" "${OUT_DIR}/06d_setoran_session.xml" \
    || fail "Record recitation button missing"
  if grep_ui "segera hadir|coming soon" "${OUT_DIR}/06d_setoran_session.xml"; then
    fail "Mic still shows coming-soon placeholder"
  fi
  grep_ui "Tandai sudah disetor|Mark setoran done" "${OUT_DIR}/06d_setoran_session.xml" \
    || fail "Mark setoran done button missing"

  log "Reveal all ayahs (fade Sudah benar)"
  local reveal_attempt=0
  while [[ $reveal_attempt -lt 8 ]]; do
    dump_ui "_fade_reveal_${reveal_attempt}"
    if read -r cx cy < <(tap_text_or_label "Sudah benar" "${OUT_DIR}/_fade_reveal_${reveal_attempt}.xml"); then
      adb -s "$SERIAL" shell input tap "$cx" "$cy"
      sleep 1
      reveal_attempt=$((reveal_attempt + 1))
      continue
    fi
    break
  done
  dump_ui "06e_setoran_revealed"
  grep_ui "Ayat jelas|Revealed:" "${OUT_DIR}/06e_setoran_revealed.xml" \
    || fail "Fade reveal progress not updated"

  log "Mark setoran item done (all ayahs revealed)"
  dump_ui "_mark_setoran"
  if read -r mx my < <(tap_text_or_label "Tandai sudah disetor" "${OUT_DIR}/_mark_setoran.xml"); then
    adb -s "$SERIAL" shell input tap "$mx" "$my"
  elif read -r mx my < <(tap_text_or_label "Mark setoran done" "${OUT_DIR}/_mark_setoran.xml"); then
    adb -s "$SERIAL" shell input tap "$mx" "$my"
  else
    fail "Could not tap Tandai sudah disetor"
  fi
  sleep 1
  dump_ui "06g_setoran_marked"
  grep_ui "Batalkan tanda setoran|Undo setoran mark" \
    "${OUT_DIR}/06g_setoran_marked.xml" \
    || fail "Setoran mark did not persist in session UI"

  log "Back to setoran queue"
  go_back
  sleep 1
  dump_ui "06h_setoran_queue_after"
  grep_ui "Setoran Jumat|Friday setoran" "${OUT_DIR}/06h_setoran_queue_after.xml" \
    || fail "Did not return to Friday setoran queue"
  if grep_ui "1 / [2-9]|1 / [1-9][0-9]|Sudah disetor" "${OUT_DIR}/06h_setoran_queue_after.xml"; then
    log "Queue progress updated after mark"
  fi

  log "Back to Koleksi"
  go_back
  dump_ui "06c_back_library_friday"
  grep_ui "Juz Amma|Ayat dihafal" "${OUT_DIR}/06c_back_library_friday.xml" \
    || fail "Did not return to Koleksi after Friday setoran flow"
}

SIZE="$(adb -s "$SERIAL" shell wm size | tr -d '\r' | awk '{print $3}')"
W="${SIZE%%x*}"
H="${SIZE##*x}"
# Split-view sidebar scroll anchor (~320dp); phones use center X.
if [[ "$W" -ge 1200 ]]; then
  CX=160
else
  CX=$((W / 2))
fi
SY=$((H * 2 / 3))
EY=$((H / 4))

log "Device ${W}x${H} — launch app"
launch_app
wait_until_read_ready "01_read_tab"
assert_no_crash "${OUT_DIR}/01_read_tab.xml"
grep_ui "Al-Fatihah|Surah" "${OUT_DIR}/01_read_tab.xml" \
  || fail "Surah list missing on Read tab"

log "Switch to Juz mode"
tap_read_mode "Juz" "${OUT_DIR}/01_read_tab.xml"
sleep 3
wait_until_read_ready "02_juz_top" "juz"
grep_ui "Baca Juz|Read Juz|Juz 1" "${OUT_DIR}/02_juz_top.xml" \
  || fail "Juz list missing on Juz tab"
adb -s "$SERIAL" exec-out screencap -p > "${OUT_DIR}/02_juz_top.png"

log "Scroll Juz list"
scroll_list "${OUT_DIR}/02_juz_top.png" "03_juz_scrolled"

log "Switch to Mushaf mode"
dump_ui "_tap_mushaf"
tap_read_mode "Mushaf" "${OUT_DIR}/_tap_mushaf.xml" \
  || tap_read_mode "Halaman" "${OUT_DIR}/_tap_mushaf.xml"
sleep 3
wait_until_read_ready "04_mushaf_top" "mushaf"
grep_ui "Halaman|Page|Mushaf|Baca Halaman" "${OUT_DIR}/04_mushaf_top.xml" \
  || fail "Mushaf tab missing expected content"
adb -s "$SERIAL" exec-out screencap -p > "${OUT_DIR}/04_mushaf_top.png"

log "Scroll Mushaf list (while on Mushaf tab)"
scroll_list "${OUT_DIR}/04_mushaf_top.png" "05_mushaf_scrolled"
grep_ui "Halaman|Page|Mushaf|Juz" "${OUT_DIR}/05_mushaf_scrolled.xml" \
  || fail "Mushaf list empty after scroll"

if [[ "$W" -ge 1200 ]]; then
  log "Large screen (${W}x${H}): verify split layout sidebar + reader"
  grep_ui "Qur.an|Juz|Surah|Mushaf" "${OUT_DIR}/04_mushaf_top.xml" \
    || fail "Large screen sidebar missing"
  log "Large screen layout OK"
fi

log "Open Koleksi tab for Juz Amma summary"
tap_nav "Koleksi" || tap_nav "Library"
wait_until_read_ready "06_library_hafalan" "library"
assert_no_crash "${OUT_DIR}/06_library_hafalan.xml"
grep_ui "Juz Amma|Ayat dihafal|Ayahs memorized" "${OUT_DIR}/06_library_hafalan.xml" \
  || fail "Juz Amma summary card missing in Koleksi"

if is_device_friday; then
  regression_friday_setoran "${OUT_DIR}/06_library_hafalan.xml"
else
  log "Not Friday on device — skip Setoran Jumat UI checks"
fi

log "Open Juz Amma program from summary card"
dump_ui "_lib_for_juz_amma"
if read -r ax ay < <(tap_text_or_label "Juz Amma" "${OUT_DIR}/_lib_for_juz_amma.xml"); then
  adb -s "$SERIAL" shell input tap "$ax" "$ay"
else
  adb -s "$SERIAL" shell input tap "$CX" 400
fi
sleep 2
wait_until_read_ready "07_juz_amma_screen" "juz_amma"
assert_no_crash "${OUT_DIR}/07_juz_amma_screen.xml"
grep_ui "Metode terstruktur|Structured method" "${OUT_DIR}/07_juz_amma_screen.xml" \
  || fail "Juz Amma method tip missing"
grep_ui "An-Nas|An Nas|114" "${OUT_DIR}/07_juz_amma_screen.xml" \
  || fail "Juz Amma surah list missing (An-Nas)"
grep_ui "Program|Bebas|Free" "${OUT_DIR}/07_juz_amma_screen.xml" \
  || fail "Juz Amma mode selector missing"

log "Scroll Juz Amma surah list"
adb -s "$SERIAL" exec-out screencap -p > "${OUT_DIR}/07_juz_amma_screen.png"
scroll_list "${OUT_DIR}/07_juz_amma_screen.png" "08_juz_amma_scrolled"
grep_ui "An-Nas|Al-Mulk|78|Metode terstruktur" "${OUT_DIR}/08_juz_amma_scrolled.xml" \
  || fail "Juz Amma list empty after scroll"

log "Back to Koleksi"
go_back
dump_ui "09_back_library"
grep_ui "Juz Amma|Ayat dihafal|Ayahs memorized" "${OUT_DIR}/09_back_library.xml" \
  || fail "Did not return to Koleksi after Juz Amma"

log "Smoke: Cari tab"
tap_nav "Cari" || tap_nav "Search"
dump_ui "10_search_tab"
assert_no_crash "${OUT_DIR}/10_search_tab.xml"
grep_ui "Cari|Search|Kata kunci|keyword" "${OUT_DIR}/10_search_tab.xml" \
  || fail "Search tab did not load"

log "Smoke: Atur (Settings) tab"
tap_nav "Atur" || tap_nav "Pengaturan" || tap_nav "Settings"
dump_ui "11_settings_tab"
assert_no_crash "${OUT_DIR}/11_settings_tab.xml"
grep_ui "Pengaturan|Settings|Atur|Bahasa|Language" "${OUT_DIR}/11_settings_tab.xml" \
  || fail "Settings tab did not load"

log "Return to Baca tab"
tap_nav "Baca" || tap_nav "Read"
wait_until_read_ready "12_read_final" "read"
assert_no_crash "${OUT_DIR}/12_read_final.xml"

adb -s "$SERIAL" exec-out screencap -p > "${OUT_DIR}/final.png"
log "PASS — artifacts in ${OUT_DIR}"
