import {
  Callout,
  Card,
  CardBody,
  CardHeader,
  Grid,
  H1,
  H2,
  Pill,
  Row,
  Stack,
  Text,
  Toggle,
  useCanvasState,
  useHostTheme,
} from "cursor/canvas";

type View = "current" | "proposed";

const SURAHS = [
  { n: 1, name: "Al-Fatihah", status: "Belum tersimpan" },
  { n: 2, name: "Al-Baqarah", status: "Belum tersimpan" },
  { n: 3, name: "Ali 'Imran", status: "Belum tersimpan" },
  { n: 4, name: "An-Nisa", status: "0/286 ayat" },
  { n: 5, name: "Al-Ma'idah", status: "Tersimpan" },
];

export default function AudioDownloadsPremiumCanvas() {
  const [view, setView] = useCanvasState<View>("view", "proposed");

  return (
    <Stack gap={24} style={{ padding: 24, maxWidth: 1080, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Unduhan Tilawah — premium mockup</H1>
        <Text tone="secondary">
          Child screen header mengikuti pola ExploreSectionScaffold (Jelajahi / Doa drill-down):
          judul layar lebih kecil di AppBar, konteks reciter di subtitle — bukan titleLarge ganda.
        </Text>
        <Row gap={12} style={{ alignItems: "center", marginTop: 4 }}>
          <Toggle checked={view === "proposed"} onChange={(on) => setView(on ? "proposed" : "current")} />
          <Text tone="secondary" size="small">
            {view === "proposed" ? "Usulan premium" : "Saat ini (dari screenshot)"}
          </Text>
        </Row>
      </Stack>

      <Grid columns={2} gap={24} style={{ alignItems: "start" }}>
        <PhoneFrame label={view === "current" ? "Saat ini" : "Usulan"}>
          {view === "current" ? <CurrentScreen /> : <ProposedScreen />}
        </PhoneFrame>
        <SpecPanel view={view} />
      </Grid>
    </Stack>
  );
}

function PhoneFrame({ label, children }: { label: string; children?: unknown }) {
  const theme = useHostTheme();
  return (
    <Stack gap={10}>
      <H2 style={{ margin: 0, textAlign: "center" }}>{label}</H2>
      <div
        style={{
          width: 320,
          height: 640,
          margin: "0 auto",
          borderRadius: 28,
          border: `1px solid ${theme.stroke.secondary}`,
          background: theme.bg.elevated,
          overflow: "hidden",
          display: "flex",
          flexDirection: "column",
        }}
      >
        <StatusBar />
        {children}
      </div>
    </Stack>
  );
}

function StatusBar() {
  return (
    <Row
      style={{
        padding: "10px 20px 4px",
        justifyContent: "space-between",
        alignItems: "center",
      }}
    >
      <Text size="small" weight="medium">
        9:41
      </Text>
      <div style={{ width: 14, height: 8, borderRadius: 2, border: "1px solid currentColor" }} />
    </Row>
  );
}

function CurrentScreen() {
  const theme = useHostTheme();
  return (
    <>
      <CurrentAppBar />
      <div style={{ flex: 1, overflow: "auto", background: theme.fill.quaternary }}>
        <Stack gap={0}>
          <div style={{ padding: "12px 16px 14px" }}>
            <Text weight="medium" style={{ fontSize: 22, letterSpacing: -0.3, lineHeight: "28px" }}>
              Mishary Rashid Alafasy
            </Text>
            <div style={{ marginTop: 10 }}>
              <Pill tone="neutral" size="sm">
                0/114 surah · 0 B
              </Pill>
            </div>
            <div
              style={{
                marginTop: 14,
                width: "100%",
                borderRadius: 12,
                background: theme.accent.primary,
                color: theme.text.onAccent,
                padding: "12px 16px",
                textAlign: "center",
                fontSize: 14,
                fontWeight: 600,
              }}
            >
              Unduh semua surah
            </div>
          </div>
          <SurahList variant="current" />
        </Stack>
      </div>
    </>
  );
}

function CurrentAppBar() {
  const theme = useHostTheme();
  return (
    <div
      style={{
        borderBottom: `1px solid ${theme.stroke.tertiary}`,
        minHeight: 56,
        display: "flex",
        alignItems: "center",
        paddingRight: 16,
        background: theme.bg.chrome,
      }}
    >
      <BackSlot />
      <Text weight="medium" style={{ fontSize: 20, letterSpacing: -0.2 }}>
        Unduhan Tilawah
      </Text>
    </div>
  );
}

function ProposedScreen() {
  const theme = useHostTheme();
  return (
    <>
      <ProposedAppBar />
      <div style={{ flex: 1, overflow: "auto", background: theme.fill.quaternary }}>
        <Stack gap={0}>
          <div style={{ padding: "12px 16px 8px" }}>
            <HeroCard />
          </div>
          <SectionLabel text="114 SURAH" />
          <SurahList variant="proposed" />
        </Stack>
      </div>
    </>
  );
}

function ProposedAppBar() {
  const theme = useHostTheme();
  return (
    <div
      style={{
        borderBottom: `1px solid ${theme.stroke.tertiary}`,
        minHeight: 56,
        display: "flex",
        alignItems: "center",
        paddingRight: 16,
        background: theme.bg.chrome,
      }}
    >
      <BackSlot />
      <Stack gap={2}>
        <Text weight="medium" style={{ fontSize: 16, letterSpacing: -0.2, lineHeight: "20px" }}>
          Unduhan Tilawah
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: 12, lineHeight: "16px" }}>
          Mishary Rashid Alafasy · Tilawah
        </Text>
      </Stack>
    </div>
  );
}

function BackSlot() {
  return (
    <div
      style={{
        width: 48,
        height: 48,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 20,
        flexShrink: 0,
      }}
    >
      ←
    </div>
  );
}

function HeroCard() {
  const theme = useHostTheme();
  return (
    <div
      style={{
        borderRadius: 16,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.bg.elevated,
        padding: "14px 16px 16px",
      }}
    >
      <Row style={{ justifyContent: "space-between", alignItems: "start" }}>
        <Stack gap={6}>
          <Text tone="tertiary" size="small" weight="medium" style={{ fontSize: 10, letterSpacing: 0.6 }}>
            QARI TERPILIH
          </Text>
          <Text weight="medium" style={{ fontSize: 17, letterSpacing: -0.2, lineHeight: "22px" }}>
            Mishary Rashid Alafasy
          </Text>
        </Stack>
        <Pill tone="neutral" size="sm">
          0/114
        </Pill>
      </Row>
      <Text tone="secondary" size="small" style={{ marginTop: 8, fontSize: 12 }}>
        0 B di perangkat · belum ada surah tersimpan
      </Text>
      <div
        style={{
          marginTop: 14,
          width: "100%",
          borderRadius: 12,
          background: theme.accent.primary,
          color: theme.text.onAccent,
          padding: "11px 16px",
          textAlign: "center",
          fontSize: 14,
          fontWeight: 600,
        }}
      >
        Unduh semua surah
      </div>
    </div>
  );
}

function SectionLabel({ text }: { text: string }) {
  return (
    <div style={{ padding: "14px 16px 6px" }}>
      <Text tone="tertiary" size="small" weight="medium" style={{ fontSize: 11, letterSpacing: 0.5 }}>
        {text}
      </Text>
    </div>
  );
}

function SurahList({ variant }: { variant: "current" | "proposed" }) {
  const theme = useHostTheme();
  return (
    <Stack gap={0}>
      {SURAHS.map((s, i) => (
        <div
          key={s.n}
          style={{
            display: "flex",
            flexDirection: "row",
            alignItems: "center",
            gap: 12,
            padding: variant === "proposed" ? "12px 16px" : "10px 16px",
            borderBottom: i < SURAHS.length - 1 ? `1px solid ${theme.stroke.tertiary}` : undefined,
            background: variant === "proposed" ? theme.bg.elevated : undefined,
          }}
        >
          <div
            style={{
              width: variant === "proposed" ? 32 : 36,
              height: variant === "proposed" ? 32 : 36,
              borderRadius: 9999,
              background: theme.fill.secondary,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            <Text size="small" weight="medium" style={{ fontSize: 12, color: theme.accent.primary }}>
              {s.n}
            </Text>
          </div>
          <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
            <Text size="small" weight="medium">
              {s.name}
            </Text>
            <Text
              tone={s.status === "Tersimpan" ? "primary" : "secondary"}
              size="small"
              style={{ fontSize: 11 }}
            >
              {s.status}
            </Text>
          </Stack>
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 9999,
              border: `1px solid ${theme.stroke.tertiary}`,
              background: variant === "proposed" ? theme.fill.quaternary : "transparent",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
              fontSize: 16,
            }}
          >
            ↓
          </div>
        </div>
      ))}
    </Stack>
  );
}

function SpecPanel({ view }: { view: View }) {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Spesifikasi</H2>

      <Callout tone={view === "proposed" ? "success" : "warning"}>
        <Text size="small" weight="medium">
          {view === "proposed" ? "Usulan — child header seperti Doa" : "Masalah saat ini"}
        </Text>
        <Text size="small" tone="secondary">
          {view === "proposed"
            ? "AppBar pakai titleMedium (16px) + subtitle reciter. Nama qari tidak lagi titleLarge di body — hanya di hero card."
            : "AppBar title ~20px + titleLarge qari (22px) = hierarki ganda & terasa generic ListTile."}
        </Text>
      </Callout>

      <Card>
        <CardHeader>AppBar (ikuti ExploreSectionScaffold)</CardHeader>
        <CardBody>
          <Text size="small" tone="secondary" style={{ fontFamily: "monospace", whiteSpace: "pre-wrap" }}>
            {`ExploreSectionScaffold(
  title: 'Unduhan Tilawah',      // titleMedium, w700
  subtitle: '${"${reciter.name}"} · Tilawah',
  body: ...,
)

// atau AudioDownloadsScreen refactor:
AppBar(
  titleSpacing: 0,
  title: Column(
    crossAxisAlignment: start,
    children: [
      Text(..., style: titleMedium + w700),
      Text(reciter.name, style: bodySmall + onSurfaceVariant),
    ],
  ),
)`}
          </Text>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Body premium</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ HomeBackdrop.topTint background (sama Doa)</Text>
            <Text size="small" tone="secondary">+ Hero card: stat chip, storage line, CTA full-width</Text>
            <Text size="small" tone="secondary">+ Section label &quot;114 SURAH&quot; di atas list</Text>
            <Text size="small" tone="secondary">+ Row: badge 32px, status warna primary jika tersimpan</Text>
            <Text size="small" tone="secondary">+ Trailing: IconButton tonal bulat, bukan icon telanjang</Text>
            <Text size="small" tone="secondary">+ List surface putih/elevated di atas cream backdrop</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Typography scale</CardHeader>
        <CardBody>
          <Stack gap={4}>
            <Row style={{ justifyContent: "space-between" }}>
              <Text size="small" tone="secondary">Child AppBar title</Text>
              <Text size="small" weight="medium">titleMedium · 16px</Text>
            </Row>
            <Row style={{ justifyContent: "space-between" }}>
              <Text size="small" tone="secondary">AppBar subtitle (qari)</Text>
              <Text size="small" weight="medium">bodySmall · 12px</Text>
            </Row>
            <Row style={{ justifyContent: "space-between" }}>
              <Text size="small" tone="secondary">Hero qari name</Text>
              <Text size="small" weight="medium">17px · bukan titleLarge</Text>
            </Row>
            <Row style={{ justifyContent: "space-between" }}>
              <Text size="small" tone="secondary">Tab root (Doa) — referensi</Text>
              <Text size="small" weight="medium">titleLarge · 22px + icon</Text>
            </Row>
          </Stack>
        </CardBody>
      </Card>

      <Callout tone="info">
        <Text size="small">
          File implementasi: lib/features/settings/audio_downloads_screen.dart — ganti AppBar + _buildHeader
          agar match ExploreSectionScaffold di lib/features/dua/widgets/explore_section_scaffold.dart
        </Text>
      </Callout>
    </Stack>
  );
}
