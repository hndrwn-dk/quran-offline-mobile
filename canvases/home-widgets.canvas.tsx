import {
  Callout,
  Card,
  CardBody,
  CardHeader,
  Divider,
  Grid,
  H1,
  H2,
  H3,
  Pill,
  Row,
  Stack,
  Text,
  Toggle,
  useCanvasState,
  useHostTheme,
} from "cursor/canvas";

type WidgetSize = "medium" | "large";
type ThemeMode = "light" | "dark";
type Platform = "android" | "ios";
type ProgressMode = "single" | "dual";

const SAGE = {
  primary: "#5A7358",
  primaryLight: "#6F8870",
  cream: "#F3F6F0",
  tint: "#E8EDE3",
  border: "#B5C7B1",
  darkBg: "#2A322C",
  darkText: "#E8EDE3",
  muted: "#5C6B58",
  mutedDark: "#9AAB96",
};

const REFLECTION = {
  badge: "Kesabaran",
  title: "Ketika ujian datang",
  ref: "Al-Baqarah 2:155–157",
  context: "Ujian datang untuk menguji iman — sabar dan shalat adalah jalan keluar.",
};

const LAST_READ = {
  surah: "Al-Kahf",
  ayah: 45,
  surahProgress: 0.41,
  surahCurrent: 45,
  surahTotal: 110,
  juzLabel: "Juz 15",
  juzProgress: 0.58,
  juzCurrent: 142,
  juzTotal: 246,
};

export default function HomeWidgetsCanvas() {
  const [size, setSize] = useCanvasState<WidgetSize>("size", "large");
  const [themeMode, setThemeMode] = useCanvasState<ThemeMode>("theme", "light");
  const [platform, setPlatform] = useCanvasState<Platform>("platform", "android");
  const [progressMode, setProgressMode] = useCanvasState<ProgressMode>("progressMode", "dual");

  return (
    <Stack gap={28} style={{ padding: 24, maxWidth: 1100, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Home Screen Widget — Beranda</H1>
        <Text tone="secondary">
          Satu widget terpadu: header → renungan → lanjutkan baca. Toggle progress bar tunggal vs
          dua layer (surah + juz) untuk bandingkan kepadatan di medium/large.
        </Text>
      </Stack>

      <Card>
        <CardHeader>Kontrol mockup</CardHeader>
        <CardBody>
          <Row gap={16} style={{ alignItems: "center", flexWrap: "wrap" }}>
            <Row gap={8} style={{ alignItems: "center" }}>
              <Text size="small" tone="secondary">
                Ukuran:
              </Text>
              <Pill active={size === "medium"} onClick={() => setSize("medium")}>
                Medium 4×2
              </Pill>
              <Pill active={size === "large"} onClick={() => setSize("large")}>
                Large 4×4
              </Pill>
            </Row>
            <Row gap={8} style={{ alignItems: "center" }}>
              <Toggle checked={themeMode === "dark"} onChange={(on) => setThemeMode(on ? "dark" : "light")} />
              <Text size="small" tone="secondary">
                {themeMode === "dark" ? "Dark" : "Light"}
              </Text>
            </Row>
            <Row gap={8}>
              <Pill active={platform === "android"} onClick={() => setPlatform("android")}>
                Android
              </Pill>
              <Pill active={platform === "ios"} onClick={() => setPlatform("ios")}>
                iOS
              </Pill>
            </Row>
            <Row gap={8} style={{ alignItems: "center" }}>
              <Text size="small" tone="secondary">
                Progress:
              </Text>
              <Pill active={progressMode === "single"} onClick={() => setProgressMode("single")}>
                Satu bar
              </Pill>
              <Pill active={progressMode === "dual"} onClick={() => setProgressMode("dual")}>
                Dua layer
              </Pill>
            </Row>
          </Row>
        </CardBody>
      </Card>

      <Grid columns={2} gap={24} style={{ alignItems: "start" }}>
        <Stack gap={20}>
          <HomeScreenPreview
            size={size}
            themeMode={themeMode}
            platform={platform}
            progressMode={progressMode}
          />
          <ProgressCompare themeMode={themeMode} platform={platform} size={size} />
          <SizeGallery themeMode={themeMode} platform={platform} progressMode={progressMode} />
        </Stack>
        <SpecPanel size={size} themeMode={themeMode} platform={platform} progressMode={progressMode} />
      </Grid>
    </Stack>
  );
}

function HomeScreenPreview({
  size,
  themeMode,
  platform,
  progressMode,
}: {
  size: WidgetSize;
  themeMode: ThemeMode;
  platform: Platform;
  progressMode: ProgressMode;
}) {
  const isDark = themeMode === "dark";
  const wallpaper = isDark ? SAGE.darkBg : SAGE.tint;

  return (
    <Stack gap={10}>
      <H2 style={{ margin: 0, textAlign: "center" }}>
        {platform === "android" ? "Android" : "iOS"} — layar utama
      </H2>
      <div
        style={{
          width: 320,
          height: 640,
          margin: "0 auto",
          borderRadius: platform === "ios" ? 36 : 28,
          border: `1px solid ${isDark ? "#3A4438" : SAGE.border}`,
          overflow: "hidden",
          position: "relative",
          background: wallpaper,
        }}
      >
        <StatusBar platform={platform} isDark={isDark} />
        <div style={{ padding: "12px 16px 0" }}>
          <Text
            size="small"
            weight="medium"
            style={{ color: isDark ? SAGE.darkText : "#2D3F30", fontSize: 22 }}
          >
            Minggu, 5 Juli
          </Text>
        </div>
        <div style={{ padding: "10px 14px 80px" }}>
          <BerandaWidget
            size={size}
            isDark={isDark}
            platform={platform}
            progressMode={progressMode}
          />
        </div>
        <AppIconDock platform={platform} isDark={isDark} />
      </div>
    </Stack>
  );
}

function ProgressCompare({
  themeMode,
  platform,
  size,
}: {
  themeMode: ThemeMode;
  platform: Platform;
  size: WidgetSize;
}) {
  const theme = useHostTheme();
  const isDark = themeMode === "dark";

  return (
    <Stack gap={10}>
      <H3 style={{ margin: 0, textAlign: "center" }}>Perbandingan progress bar</H3>
      <div
        style={{
          padding: 16,
          borderRadius: 16,
          border: `1px solid ${theme.stroke.secondary}`,
          background: theme.bg.elevated,
        }}
      >
        <Grid columns={2} gap={12}>
          {(["single", "dual"] as ProgressMode[]).map((mode) => (
            <div key={mode} style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              <Text size="small" tone="secondary" style={{ textAlign: "center" }}>
                {mode === "single" ? "Satu bar (scope aktif)" : "Dua layer (surah + juz)"}
              </Text>
              <ContinueBlockOnly
                isDark={isDark}
                compact={size === "medium"}
                progressMode={mode}
              />
            </div>
          ))}
        </Grid>
      </div>
    </Stack>
  );
}

/** Isolated continue section for side-by-side progress comparison */
function ContinueBlockOnly({
  isDark,
  compact,
  progressMode,
}: {
  isDark: boolean;
  compact: boolean;
  progressMode: ProgressMode;
}) {
  const text = isDark ? SAGE.darkText : "#2D3F30";
  const muted = isDark ? SAGE.mutedDark : SAGE.muted;
  const accent = isDark ? SAGE.primaryLight : SAGE.primary;
  const border = isDark ? "rgba(111,136,112,0.22)" : "rgba(90,115,88,0.14)";

  return (
    <div
      style={{
        padding: 12,
        borderRadius: 14,
        background: isDark ? SAGE.darkBg : "rgba(255,255,255,0.94)",
        border: `1px solid ${border}`,
      }}
    >
      <ContinueBlock
        isDark={isDark}
        compact={compact}
        text={text}
        muted={muted}
        accent={accent}
        border={border}
        progressMode={progressMode}
      />
    </div>
  );
}

function SizeGallery({
  themeMode,
  platform,
  progressMode,
}: {
  themeMode: ThemeMode;
  platform: Platform;
  progressMode: ProgressMode;
}) {
  const theme = useHostTheme();
  const isDark = themeMode === "dark";

  return (
    <Stack gap={10}>
      <H3 style={{ margin: 0, textAlign: "center" }}>Kedua ukuran</H3>
      <div
        style={{
          padding: 16,
          borderRadius: 16,
          border: `1px solid ${theme.stroke.secondary}`,
          background: theme.bg.elevated,
        }}
      >
        <Stack gap={16} style={{ alignItems: "center" }}>
          {(["medium", "large"] as WidgetSize[]).map((s) => (
            <div key={s} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
              <Text size="small" tone="secondary">
                {s === "medium" ? "Medium — 4×2" : "Large — 4×4"}
              </Text>
              <BerandaWidgetFrame
                size={s}
                isDark={isDark}
                platform={platform}
                progressMode={progressMode}
                scale={0.9}
              />
            </div>
          ))}
        </Stack>
      </div>
    </Stack>
  );
}

function BerandaWidgetFrame({
  size,
  isDark,
  platform,
  progressMode,
  scale = 1,
}: {
  size: WidgetSize;
  isDark: boolean;
  platform: Platform;
  progressMode: ProgressMode;
  scale?: number;
}) {
  const dims =
    size === "medium"
      ? { width: 292 * scale, height: 148 * scale }
      : { width: 292 * scale, height: platform === "ios" ? 292 * scale : 304 * scale };

  return (
    <div
      style={{
        width: dims.width,
        height: dims.height,
        borderRadius: platform === "ios" ? 22 : 18,
        overflow: "hidden",
        flexShrink: 0,
      }}
    >
      <BerandaWidget
        size={size}
        isDark={isDark}
        platform={platform}
        progressMode={progressMode}
      />
    </div>
  );
}

/** Unified Beranda widget: header + renungan + lanjutkan baca + progress bar */
function BerandaWidget({
  size,
  isDark,
  platform,
  progressMode,
}: {
  size: WidgetSize;
  isDark: boolean;
  platform: Platform;
  progressMode: ProgressMode;
}) {
  const bg = isDark ? SAGE.darkBg : "rgba(255,255,255,0.94)";
  const text = isDark ? SAGE.darkText : "#2D3F30";
  const muted = isDark ? SAGE.mutedDark : SAGE.muted;
  const accent = isDark ? SAGE.primaryLight : SAGE.primary;
  const border = isDark ? "rgba(111,136,112,0.22)" : "rgba(90,115,88,0.14)";
  const compact = size === "medium";

  return (
    <div
      style={{
        height: "100%",
        padding: compact ? 12 : 14,
        background: bg,
        border: `1px solid ${border}`,
        display: "flex",
        flexDirection: "column",
        gap: compact ? 8 : 10,
        boxSizing: "border-box",
      }}
    >
      <WidgetHeader isDark={isDark} platform={platform} compact={compact} />

      {/* Renungan */}
      <ReflectionBlock
        isDark={isDark}
        compact={compact}
        text={text}
        muted={muted}
        accent={accent}
        border={border}
      />

      {/* Lanjutkan baca + progress bar */}
      <ContinueBlock
        isDark={isDark}
        compact={compact}
        text={text}
        muted={muted}
        accent={accent}
        border={border}
        progressMode={progressMode}
      />
    </div>
  );
}

function WidgetHeader({
  isDark,
  platform,
  compact,
}: {
  isDark: boolean;
  platform: Platform;
  compact: boolean;
}) {
  const muted = isDark ? SAGE.mutedDark : SAGE.muted;
  const tagline = "Baca, renungkan, lanjutkan tilawah";

  return (
    <Row style={{ justifyContent: "space-between", alignItems: "center", gap: 6 }}>
      <Row gap={5} style={{ alignItems: "center", flex: 1, minWidth: 0 }}>
        <div
          style={{
            width: 14,
            height: 14,
            borderRadius: 4,
            background: SAGE.primary,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 8,
            color: "#fff",
            fontWeight: 700,
            flexShrink: 0,
          }}
        >
          Q
        </div>
        <Text size="small" style={{ fontSize: 8, color: muted, fontWeight: 600, flexShrink: 0 }}>
          Quran Offline
        </Text>
        <Text size="small" style={{ fontSize: 7, color: muted, flexShrink: 0 }}>
          —
        </Text>
        <Text
          size="small"
          style={{
            fontSize: compact ? 7 : 8,
            color: muted,
            fontWeight: 400,
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
            minWidth: 0,
          }}
        >
          {tagline}
        </Text>
      </Row>
      {platform === "ios" && (
        <Text size="small" style={{ fontSize: 7, color: muted, flexShrink: 0 }}>
          09:41
        </Text>
      )}
    </Row>
  );
}

function ReflectionBlock({
  isDark,
  compact,
  text,
  muted,
  accent,
  border,
}: {
  isDark: boolean;
  compact: boolean;
  text: string;
  muted: string;
  accent: string;
  border: string;
}) {
  return (
    <div style={{ flex: compact ? 1 : undefined }}>
      <Row style={{ justifyContent: "space-between", alignItems: "center", marginBottom: compact ? 3 : 5 }}>
        <Text size="small" style={{ fontSize: 8, color: muted, fontWeight: 600, letterSpacing: 0.4 }}>
          RENUNGAN
        </Text>
        <span
          style={{
            fontSize: 7,
            fontWeight: 600,
            padding: "2px 6px",
            borderRadius: 5,
            background: isDark ? "rgba(90,115,88,0.3)" : "rgba(255,255,255,0.7)",
            color: accent,
            border: `1px solid ${border}`,
          }}
        >
          {REFLECTION.badge}
        </span>
      </Row>
      <Text
        weight="medium"
        style={{ fontSize: compact ? 11 : 13, color: text, lineHeight: 1.25, margin: 0 }}
      >
        {REFLECTION.title}
      </Text>
      <Text size="small" style={{ fontSize: 8, color: accent, fontWeight: 600, marginTop: 2 }}>
        {REFLECTION.ref}
      </Text>
      {!compact && (
        <Text
          size="small"
          style={{
            fontSize: 9,
            color: muted,
            lineHeight: 1.4,
            marginTop: 4,
            overflow: "hidden",
            display: "-webkit-box",
            WebkitLineClamp: 2,
            WebkitBoxOrient: "vertical",
          }}
        >
          {REFLECTION.context}
        </Text>
      )}
    </div>
  );
}

function ContinueBlock({
  isDark,
  compact,
  text,
  muted,
  accent,
  border,
  progressMode,
}: {
  isDark: boolean;
  compact: boolean;
  text: string;
  muted: string;
  accent: string;
  border: string;
  progressMode: ProgressMode;
}) {
  const surahPct = Math.round(LAST_READ.surahProgress * 100);
  const juzPct = Math.round(LAST_READ.juzProgress * 100);
  const headerPct = progressMode === "dual" ? surahPct : surahPct;

  return (
    <div
      style={{
        marginTop: compact ? "auto" : 0,
        paddingTop: compact ? 6 : 8,
        borderTop: `1px solid ${border}`,
      }}
    >
      <Row style={{ justifyContent: "space-between", alignItems: "baseline", marginBottom: compact ? 4 : 6 }}>
        <Text size="small" style={{ fontSize: 8, color: muted, fontWeight: 600, letterSpacing: 0.4 }}>
          LANJUTKAN BACA
        </Text>
        {progressMode === "single" && (
          <Text size="small" style={{ fontSize: 8, color: accent, fontWeight: 600 }}>
            {headerPct}%
          </Text>
        )}
      </Row>
      <Row style={{ alignItems: "center", gap: 8, marginBottom: compact ? 5 : 7 }}>
        <Text weight="medium" style={{ fontSize: compact ? 12 : 14, color: text, flex: 1 }}>
          {LAST_READ.surah}
        </Text>
        <Text size="small" style={{ fontSize: 9, color: accent, fontWeight: 600 }}>
          Ayat {LAST_READ.ayah}
        </Text>
      </Row>

      {progressMode === "single" ? (
        <>
          <ProgressBarRow
            label="Surah"
            value={LAST_READ.surahProgress}
            percent={surahPct}
            isDark={isDark}
            accent={accent}
            muted={muted}
            height={compact ? 4 : 5}
            compact={compact}
            showLabel={!compact}
          />
          {!compact && (
            <Text size="small" style={{ fontSize: 8, color: muted, marginTop: 4 }}>
              {surahPct}% surah — ayat {LAST_READ.surahCurrent}/{LAST_READ.surahTotal}
            </Text>
          )}
        </>
      ) : (
        <Stack gap={compact ? 4 : 6}>
          <ProgressBarRow
            label="Surah"
            value={LAST_READ.surahProgress}
            percent={surahPct}
            isDark={isDark}
            accent={accent}
            muted={muted}
            height={compact ? 3 : 4}
            compact={compact}
            showLabel
          />
          <ProgressBarRow
            label={LAST_READ.juzLabel}
            value={LAST_READ.juzProgress}
            percent={juzPct}
            isDark={isDark}
            accent={isDark ? "#7A9A78" : "#4A6B48"}
            muted={muted}
            height={compact ? 3 : 4}
            compact={compact}
            showLabel
            secondary
          />
          {!compact && (
            <Text size="small" style={{ fontSize: 8, color: muted, marginTop: 2 }}>
              Surah {LAST_READ.surahCurrent}/{LAST_READ.surahTotal} · {LAST_READ.juzLabel}{" "}
              {LAST_READ.juzCurrent}/{LAST_READ.juzTotal} ayat
            </Text>
          )}
        </Stack>
      )}
    </div>
  );
}

function ProgressBarRow({
  label,
  value,
  percent,
  isDark,
  accent,
  muted,
  height,
  compact,
  showLabel,
  secondary,
}: {
  label: string;
  value: number;
  percent: number;
  isDark: boolean;
  accent: string;
  muted: string;
  height: number;
  compact: boolean;
  showLabel: boolean;
  secondary?: boolean;
}) {
  return (
    <div>
      {showLabel && (
        <Row style={{ justifyContent: "space-between", alignItems: "baseline", marginBottom: 3 }}>
          <Text
            size="small"
            style={{
              fontSize: compact ? 7 : 8,
              color: secondary ? muted : muted,
              fontWeight: 600,
              letterSpacing: 0.2,
            }}
          >
            {label.toUpperCase()}
          </Text>
          <Text
            size="small"
            style={{
              fontSize: compact ? 7 : 8,
              color: accent,
              fontWeight: 600,
              fontVariantNumeric: "tabular-nums",
            }}
          >
            {percent}%
          </Text>
        </Row>
      )}
      <ProgressBar value={value} isDark={isDark} accent={accent} height={height} />
    </div>
  );
}

function ProgressBar({
  value,
  isDark,
  accent,
  height,
}: {
  value: number;
  isDark: boolean;
  accent: string;
  height: number;
}) {
  return (
    <div
      style={{
        height,
        borderRadius: height,
        background: isDark ? "rgba(111,136,112,0.2)" : "rgba(90,115,88,0.12)",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          width: `${value * 100}%`,
          height: "100%",
          borderRadius: height,
          background: accent,
        }}
      />
    </div>
  );
}

function StatusBar({ platform, isDark }: { platform: Platform; isDark: boolean }) {
  const color = isDark ? SAGE.darkText : "#2D3F30";
  return (
    <Row
      style={{
        padding: platform === "ios" ? "14px 24px 4px" : "10px 20px 4px",
        justifyContent: "space-between",
        alignItems: "center",
      }}
    >
      <Text size="small" weight="medium" style={{ color, fontSize: 12 }}>
        9:41
      </Text>
      <div style={{ width: 14, height: 8, borderRadius: 2, border: `1px solid ${color}` }} />
    </Row>
  );
}

function AppIconDock({ platform, isDark }: { platform: Platform; isDark: boolean }) {
  return (
    <div
      style={{
        position: "absolute",
        bottom: platform === "ios" ? 24 : 16,
        left: 16,
        right: 16,
        padding: "10px 12px",
        borderRadius: platform === "ios" ? 24 : 16,
        background: isDark ? "rgba(30,36,32,0.8)" : "rgba(255,255,255,0.6)",
      }}
    >
      <Row style={{ justifyContent: "space-around" }}>
        {["Q", "·", "·", "·"].map((label, i) => (
          <div
            key={i}
            style={{
              width: 44,
              height: 44,
              borderRadius: 12,
              background: i === 0 ? SAGE.primary : isDark ? "#3A4438" : SAGE.tint,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: i === 0 ? 16 : 18,
              color: i === 0 ? "#fff" : isDark ? SAGE.mutedDark : SAGE.muted,
              fontWeight: i === 0 ? 700 : 400,
            }}
          >
            {label}
          </div>
        ))}
      </Row>
    </div>
  );
}

function SpecPanel({
  size,
  themeMode,
  platform,
  progressMode,
}: {
  size: WidgetSize;
  themeMode: ThemeMode;
  platform: Platform;
  progressMode: ProgressMode;
}) {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Spesifikasi</H2>

      <Callout tone="success">
        <Text size="small" weight="medium">
          Widget Beranda — {size} · progress {progressMode === "dual" ? "dua layer" : "satu bar"}
        </Text>
        <Text size="small" tone="secondary">
          {progressMode === "dual"
            ? "Dua bar bertumpuk: Surah (sage utama) + Juz (sage lebih gelap). Masing-masing punya label + % sendiri."
            : "Satu bar sesuai scope last read aktif (mirror LastReadCard saat ini — scope surah/juz/page)."}
        </Text>
      </Callout>

      <Card>
        <CardHeader>Struktur (atas → bawah)</CardHeader>
        <CardBody>
          <Stack gap={8}>
            <Stack gap={2}>
              <Text size="small" weight="medium">
                1. Header
              </Text>
              <Text size="small" tone="secondary">
                Q + Quran Offline — Baca, renungkan, lanjutkan tilawah (satu baris, ellipsis di
                medium). Tanpa chip salam terpisah.
              </Text>
            </Stack>
            <Divider />
            <Stack gap={2}>
              <Text size="small" weight="medium">
                2. Renungan
              </Text>
              <Text size="small" tone="secondary">
                Label RENUNGAN + badge tema + judul + referensi ayat. Konteks 2 baris hanya di large.
                Data: reflectionPickProvider.
              </Text>
            </Stack>
            <Divider />
            <Stack gap={2}>
              <Text size="small" weight="medium">
                3. Lanjutkan baca
              </Text>
              <Text size="small" tone="secondary">
                Divider, surah + ayat. Progress: satu bar (scope aktif) atau dua layer (surah + juz
                dari posisi ayat). Data: lastReadProvider + hitung ayat per surah/juz di DB.
              </Text>
            </Stack>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Progress bar — {progressMode === "dual" ? "dua layer" : "satu bar"}</CardHeader>
        <CardBody>
          <Stack gap={6}>
            {progressMode === "single" ? (
              <>
                <Text size="small" tone="secondary">
                  Satu bar + % kanan header. Scope mengikuti lastRead.type (surah / juz / page).
                </Text>
                <Text size="small" tone="secondary">
                  Mirror lastReadProgressProvider — sama seperti LastReadCard Beranda sekarang.
                </Text>
              </>
            ) : (
              <>
                <Text size="small" tone="secondary">
                  Bar 1 — SURAH: ayat {LAST_READ.surahCurrent}/{LAST_READ.surahTotal} ({Math.round(LAST_READ.surahProgress * 100)}%)
                </Text>
                <Text size="small" tone="secondary">
                  Bar 2 — {LAST_READ.juzLabel}: ayat {LAST_READ.juzCurrent}/{LAST_READ.juzTotal} ({Math.round(LAST_READ.juzProgress * 100)}%) warna sage lebih gelap
                </Text>
                <Text size="small" tone="secondary">
                  Medium: bar 3px + label 7px. Large: bar 4px + caption ayat di bawah.
                </Text>
                <Text size="small" tone="secondary">
                  Widget selalu hitung keduanya dari posisi ayat — tidak tergantung lastRead.type.
                </Text>
              </>
            )}
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Ukuran &amp; crop</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">
              Medium (4×2): dua layer masih muat — bar 3px, tanpa caption ayat
            </Text>
            <Text size="small" tone="secondary">
              Large (4×4): dua layer + caption Surah x/y · Juz x/y ayat
            </Text>
            <Text size="small" tone="secondary">
              Radius {platform === "ios" ? "22px" : "18px"} — {themeMode} theme ikut sistem
            </Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Deep link per zona</CardHeader>
        <CardBody>
          <Stack gap={4}>
            <Text size="small" style={{ fontFamily: "monospace" }}>
              quranoffline://home
            </Text>
            <Text size="small" style={{ fontFamily: "monospace" }}>
              quranoffline://reflection
            </Text>
            <Text size="small" style={{ fontFamily: "monospace" }}>
              quranoffline://read?surah=18&amp;ayah=45
            </Text>
          </Stack>
        </CardBody>
      </Card>
    </Stack>
  );
}
