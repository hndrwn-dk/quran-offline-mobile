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

const HINTS = [
  { icon: "📖", title: "Surah", example: "Al-Fatihah, Al-Baqarah, dll." },
  { icon: "≡", title: "Juz", example: "Juz 1, Juz 2, dll." },
  { icon: "▢", title: "Halaman", example: "Halaman 604, Halaman 1, dll." },
  { icon: "#", title: "Ayat", example: "2:255, 3:190, dll." },
  { icon: "A", title: "Terjemahan", example: "Kata apa pun dalam teks terjemahan" },
  { icon: "ع", title: "Teks Arab ayat", example: "Fragmen seperti الرحمن" },
];

export default function SearchPremiumCanvas() {
  const [view, setView] = useCanvasState<View>("view", "proposed");

  return (
    <Stack gap={24} style={{ padding: 24, maxWidth: 1080, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Cari — premium mockup</H1>
        <Text tone="secondary">
          Tab root tetap punya header icon + judul. Hilangkan duplikat: icon lens besar dan
          &quot;Cari Al-Qur&apos;an&quot; di body. Langsung ke label section + kartu petunjuk premium.
        </Text>
        <Row gap={12} style={{ alignItems: "center", marginTop: 4 }}>
          <Toggle checked={view === "proposed"} onChange={(on) => setView(on ? "proposed" : "current")} />
          <Text tone="secondary" size="small">
            {view === "proposed" ? "Usulan premium" : "Saat ini (screenshot)"}
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
        <TabHeader />
        <SearchBar />
        <div style={{ flex: 1, overflow: "auto" }}>{children}</div>
        <BottomNav />
      </div>
    </Stack>
  );
}

function StatusBar() {
  return (
    <Row style={{ padding: "10px 20px 4px", justifyContent: "space-between", alignItems: "center" }}>
      <Text size="small" weight="medium">9:41</Text>
      <div style={{ width: 14, height: 8, borderRadius: 2, border: "1px solid currentColor" }} />
    </Row>
  );
}

function TabHeader() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "4px 16px 8px", borderBottom: `1px solid ${theme.stroke.tertiary}` }}>
      <Row gap={10} style={{ alignItems: "center" }}>
        <div
          style={{
            width: 28,
            height: 28,
            borderRadius: 9999,
            border: `1px solid ${theme.stroke.secondary}`,
            background: theme.fill.quaternary,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 12,
          }}
        >
          ◎
        </div>
        <Stack gap={2}>
          <Text weight="medium" style={{ fontSize: 17, letterSpacing: -0.3 }}>Cari</Text>
          <Text tone="secondary" size="small" style={{ fontSize: 11 }}>Cari di seluruh Al-Qur&apos;an</Text>
        </Stack>
      </Row>
    </div>
  );
}

function SearchBar() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "10px 16px 8px" }}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          padding: "4px 4px 4px 16px",
          borderRadius: 9999,
          border: `1px solid ${theme.stroke.tertiary}`,
          background: theme.bg.elevated,
        }}
      >
        <Text tone="tertiary" size="small" style={{ flex: 1, fontSize: 12 }}>
          Surah, Juz, halaman, 2:255, teks Arab...
        </Text>
        <div
          style={{
            width: 36,
            height: 36,
            borderRadius: 9999,
            background: theme.text.primary,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: theme.bg.elevated,
            fontSize: 14,
          }}
        >
          ⌕
        </div>
      </div>
    </div>
  );
}

function CurrentScreen() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "8px 20px 24px", textAlign: "center" }}>
      <div style={{ fontSize: 48, opacity: 0.28, marginBottom: 12 }}>⌕</div>
      <Text weight="medium" style={{ fontSize: 20, marginBottom: 8 }}>Cari Al-Qur&apos;an</Text>
      <Text tone="secondary" size="small" style={{ marginBottom: 16 }}>
        Anda dapat mencari berdasarkan:
      </Text>
      <Stack gap={10}>
        {HINTS.slice(0, 4).map((h) => (
          <div key={h.title}>
            <HintRowCurrent hint={h} />
          </div>
        ))}
      </Stack>
      <Text tone="tertiary" size="small" style={{ marginTop: 12, fontSize: 10 }}>
        + 2 kartu lagi di bawah...
      </Text>
    </div>
  );
}

function HintRowCurrent({ hint }: { hint: (typeof HINTS)[0] }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        textAlign: "left",
        padding: 12,
        borderRadius: 12,
        background: theme.fill.quaternary,
        border: `1px solid ${theme.stroke.tertiary}`,
        display: "flex",
        gap: 12,
        alignItems: "flex-start",
      }}
    >
      <span style={{ fontSize: 16 }}>{hint.icon}</span>
      <Stack gap={2}>
        <Text size="small" weight="medium">{hint.title}</Text>
        <Text tone="secondary" size="small" style={{ fontSize: 11 }}>{hint.example}</Text>
      </Stack>
    </div>
  );
}

function ProposedScreen() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "4px 16px 20px", background: theme.fill.quaternary }}>
      <Text
        tone="tertiary"
        size="small"
        weight="medium"
        style={{ fontSize: 11, letterSpacing: 0.5, marginBottom: 10, display: "block" }}
      >
        ANDA DAPAT MENCARI BERDASARKAN
      </Text>
      <Stack gap={8}>
        {HINTS.map((h) => (
          <div key={h.title}>
            <HintCardPremium hint={h} />
          </div>
        ))}
      </Stack>
    </div>
  );
}

function HintCardPremium({ hint }: { hint: (typeof HINTS)[0] }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: "12px 14px",
        borderRadius: 16,
        background: theme.bg.elevated,
        border: `1px solid ${theme.stroke.tertiary}`,
      }}
    >
      <div
        style={{
          width: 36,
          height: 36,
          borderRadius: 10,
          background: theme.fill.secondary,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 14,
          flexShrink: 0,
        }}
      >
        {hint.icon}
      </div>
      <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
        <Text size="small" weight="medium">{hint.title}</Text>
        <Text tone="secondary" size="small" style={{ fontSize: 11, lineHeight: 1.35 }}>
          {hint.example}
        </Text>
      </Stack>
      <Text tone="tertiary" style={{ fontSize: 18 }}>›</Text>
    </div>
  );
}

function BottomNav() {
  const theme = useHostTheme();
  const tabs = ["Beranda", "Baca", "Cari", "Jelajahi", "Koleksi"];
  return (
    <div style={{ borderTop: `1px solid ${theme.stroke.secondary}`, padding: "8px 12px 14px" }}>
      <Row style={{ justifyContent: "space-between" }}>
        {tabs.map((t) => (
          <div key={t}>
            <Text
              size="small"
              tone={t === "Cari" ? "primary" : "tertiary"}
              weight={t === "Cari" ? "medium" : "normal"}
              style={{ fontSize: 9 }}
            >
              {t}
            </Text>
          </div>
        ))}
      </Row>
    </div>
  );
}

function SpecPanel({ view }: { view: View }) {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Spesifikasi</H2>

      <Callout tone={view === "proposed" ? "success" : "warning"}>
        <Text size="small" weight="medium">
          {view === "proposed" ? "Usulan" : "Masalah saat ini"}
        </Text>
        <Text size="small" tone="secondary">
          {view === "proposed"
            ? "Header tab sudah cukup — body langsung ke section label + kartu petunjuk. Tidak ada icon lens 56px atau judul Cari Al-Qur'an ganda."
            : "Icon search besar + judul Cari Al-Qur'an menduplikasi header tab dan search bar."}
        </Text>
      </Callout>

      <Card>
        <CardHeader>Dihapus dari body (empty state)</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">- Icon(Icons.search, size: 56)</Text>
            <Text size="small" tone="secondary">- Text search_title (&quot;Cari Al-Qur&apos;an&quot;)</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Body premium</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ HomeBackdrop cream (selaras tab Doa/Baca)</Text>
            <Text size="small" tone="secondary">+ Section label kecil: search_by_label</Text>
            <Text size="small" tone="secondary">+ Kartu elevated 16px radius + icon box 36px</Text>
            <Text size="small" tone="secondary">+ Chevron kanan — tap isi sample query</Text>
            <Text size="small" tone="secondary">+ Header tab: pakai getMenuText(&apos;cari&apos;) bukan hardcode &quot;Search&quot;</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>File</CardHeader>
        <CardBody>
          <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
            lib/features/search/search_screen.dart
          </Text>
        </CardBody>
      </Card>
    </Stack>
  );
}
