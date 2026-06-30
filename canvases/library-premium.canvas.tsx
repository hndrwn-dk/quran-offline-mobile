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

type View = "current" | "proposed";
type SubTab = "bookmarks" | "notes" | "highlights";

const BOOKMARKS = [
  {
    surahId: 2,
    name: "Al-Baqarah",
    meaning: "The Cow",
    ayah: 255,
    arabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ",
    translation: "Allah — there is no deity except Him, the Ever-Living...",
  },
  {
    surahId: 36,
    name: "Ya-Sin",
    meaning: "Ya Sin",
    ayah: 1,
    arabic: "يس",
    translation: "Ya Sin.",
  },
];

const NOTES = [
  {
    surahId: 18,
    name: "Al-Kahf",
    ayah: 10,
    note: "Ingat kisah Ashabul Kahf — sabar dan tawakal.",
    arabic: "إِذْ أَوَى الْفِتْيَةُ إِلَى الْكَهْفِ",
    translation: "When the youths retreated to the cave...",
  },
];

const HIGHLIGHTS = [
  {
    surahId: 55,
    name: "Ar-Rahman",
    ayah: 13,
    color: "#F5C842",
    arabic: "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ",
    translation: "So which of the favors of your Lord would you deny?",
  },
];

const AUDIT = [
  { screen: "Beranda", status: "done" as const, note: "HomeBackdrop, hero card, section links — sudah premium." },
  { screen: "Baca", status: "partial" as const, note: "Header icon OK; belum HomeBackdrop; mode chips masih Material default." },
  { screen: "Cari", status: "planned" as const, note: "Mockup search-premium.canvas.tsx — belum diimplementasi." },
  { screen: "Jelajahi", status: "done" as const, note: "ExploreSectionScaffold + hub cards — selaras iOS drill-down." },
  { screen: "Koleksi", status: "active" as const, note: "Fokus mockup ini — TabBar Material, hardcode title, flat empty state." },
  { screen: "Unduhan tilawah", status: "planned" as const, note: "Mockup audio-downloads-premium — child screen header perlu polish." },
  { screen: "Pengaturan", status: "partial" as const, note: "Menu sections OK; beberapa child screen masih titleLarge ganda." },
  { screen: "Reader / Mushaf", status: "done" as const, note: "Konteks baca — desain berbeda, tidak perlu HomeBackdrop." },
];

export default function LibraryPremiumCanvas() {
  const [view, setView] = useCanvasState<View>("view", "proposed");
  const [subTab, setSubTab] = useCanvasState<SubTab>("subTab", "bookmarks");

  return (
    <Stack gap={28} style={{ padding: 24, maxWidth: 1120, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Koleksi — premium mockup</H1>
        <Text tone="secondary">
          Tab Koleksi (My Library): selaraskan dengan Beranda/Jelajahi — HomeBackdrop, segment pill tabs
          iOS-style, stat chips, kartu elevated tanpa shadow, empty state bermakna. Audit layar lain di bawah.
        </Text>
        <Row gap={12} style={{ alignItems: "center", marginTop: 4 }}>
          <Toggle checked={view === "proposed"} onChange={(on) => setView(on ? "proposed" : "current")} />
          <Text tone="secondary" size="small">
            {view === "proposed" ? "Usulan premium" : "Saat ini (dari kode)"}
          </Text>
        </Row>
      </Stack>

      <Grid columns={2} gap={24} style={{ alignItems: "start" }}>
        <PhoneFrame label={view === "current" ? "Saat ini" : "Usulan"}>
          {view === "current" ? (
            <CurrentScreen subTab={subTab} onSubTab={setSubTab} />
          ) : (
            <ProposedScreen subTab={subTab} onSubTab={setSubTab} />
          )}
        </PhoneFrame>
        <SpecPanel view={view} subTab={subTab} />
      </Grid>

      <Divider />

      <ScreenAudit />
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
          height: 680,
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
        <BottomNav />
      </div>
    </Stack>
  );
}

function StatusBar() {
  return (
    <Row style={{ padding: "10px 20px 4px", justifyContent: "space-between", alignItems: "center" }}>
      <Text size="small" weight="medium">
        9:41
      </Text>
      <div style={{ width: 14, height: 8, borderRadius: 2, border: "1px solid currentColor" }} />
    </Row>
  );
}

function CurrentScreen({ subTab, onSubTab }: { subTab: SubTab; onSubTab: (t: SubTab) => void }) {
  const theme = useHostTheme();
  return (
    <>
      <CurrentHeader />
      <MaterialTabBar subTab={subTab} onSubTab={onSubTab} />
      <div style={{ flex: 1, overflow: "auto", background: theme.bg.elevated }}>
        {subTab === "bookmarks" && <CurrentBookmarkList />}
        {subTab === "notes" && <CurrentNotesList />}
        {subTab === "highlights" && <CurrentHighlightsList />}
      </div>
    </>
  );
}

function ProposedScreen({ subTab, onSubTab }: { subTab: SubTab; onSubTab: (t: SubTab) => void }) {
  const theme = useHostTheme();
  return (
    <>
      <ProposedHeader />
      <div style={{ flex: 1, overflow: "auto", background: theme.fill.quaternary }}>
        <StatsRow />
        <SegmentTabs subTab={subTab} onSubTab={onSubTab} />
        {subTab === "bookmarks" && <ProposedBookmarkList />}
        {subTab === "notes" && <ProposedNotesList />}
        {subTab === "highlights" && <ProposedHighlightsList />}
      </div>
    </>
  );
}

function CurrentHeader() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "4px 16px 8px", borderBottom: `1px solid ${theme.stroke.tertiary}` }}>
      <Row style={{ justifyContent: "space-between", alignItems: "flex-start" }}>
        <Row gap={10} style={{ alignItems: "center" }}>
          <IconCircle glyph="K" />
          <Stack gap={2}>
            <Text weight="medium" style={{ fontSize: 17, letterSpacing: -0.3 }}>
              My Library
            </Text>
            <Text tone="secondary" size="small" style={{ fontSize: 11 }}>
              Koleksi pribadi Anda
            </Text>
          </Stack>
        </Row>
        <Text tone="tertiary" style={{ fontSize: 18, padding: 4 }}>
          Q
        </Text>
      </Row>
    </div>
  );
}

function ProposedHeader() {
  const theme = useHostTheme();
  return (
    <div
      style={{
        padding: "4px 16px 10px",
        borderBottom: `1px solid ${theme.stroke.tertiary}`,
        background: theme.fill.secondary,
      }}
    >
      <Row style={{ justifyContent: "space-between", alignItems: "flex-start" }}>
        <Row gap={10} style={{ alignItems: "center" }}>
          <IconCircle glyph="K" />
          <Stack gap={2}>
            <Text weight="medium" style={{ fontSize: 17, letterSpacing: -0.3 }}>
              Koleksi
            </Text>
            <Text tone="secondary" size="small" style={{ fontSize: 11 }}>
              Koleksi pribadi Anda
            </Text>
          </Stack>
        </Row>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            padding: "6px 12px 6px 14px",
            borderRadius: 9999,
            border: `1px solid ${theme.stroke.tertiary}`,
            background: theme.bg.elevated,
            maxWidth: 120,
          }}
        >
          <Text tone="tertiary" size="small" style={{ fontSize: 11, flex: 1 }}>
            Cari...
          </Text>
          <Text tone="tertiary" style={{ fontSize: 12 }}>
            Q
          </Text>
        </div>
      </Row>
    </div>
  );
}

function IconCircle({ glyph }: { glyph: string }) {
  const theme = useHostTheme();
  return (
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
        fontSize: 11,
        fontWeight: 600,
      }}
    >
      {glyph}
    </div>
  );
}

function MaterialTabBar({ subTab, onSubTab }: { subTab: SubTab; onSubTab: (t: SubTab) => void }) {
  const theme = useHostTheme();
  const tabs: { id: SubTab; label: string }[] = [
    { id: "bookmarks", label: "Penanda" },
    { id: "notes", label: "Catatan" },
    { id: "highlights", label: "Sorotan" },
  ];
  return (
    <div style={{ borderBottom: `1px solid ${theme.stroke.tertiary}` }}>
      <Row style={{ padding: "0 8px" }}>
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => onSubTab(t.id)}
            style={{
              flex: 1,
              border: "none",
              background: "transparent",
              padding: "10px 4px",
              cursor: "pointer",
              borderBottom: subTab === t.id ? `2px solid ${theme.text.primary}` : "2px solid transparent",
              color: subTab === t.id ? theme.text.primary : theme.text.tertiary,
              fontSize: 11,
              fontWeight: subTab === t.id ? 600 : 400,
            }}
          >
            {t.label}
          </button>
        ))}
      </Row>
    </div>
  );
}

function StatsRow() {
  return (
    <Row gap={8} style={{ padding: "12px 16px 0", flexWrap: "wrap" }}>
      <Pill tone="neutral" size="sm">
        12 penanda
      </Pill>
      <Pill tone="neutral" size="sm">
        5 catatan
      </Pill>
      <Pill tone="neutral" size="sm">
        8 sorotan
      </Pill>
    </Row>
  );
}

function SegmentTabs({ subTab, onSubTab }: { subTab: SubTab; onSubTab: (t: SubTab) => void }) {
  const theme = useHostTheme();
  const tabs: { id: SubTab; label: string }[] = [
    { id: "bookmarks", label: "Penanda" },
    { id: "notes", label: "Catatan" },
    { id: "highlights", label: "Sorotan" },
  ];
  return (
    <div style={{ padding: "12px 16px 8px" }}>
      <div
        style={{
          display: "flex",
          padding: 3,
          borderRadius: 12,
          background: theme.fill.secondary,
          border: `1px solid ${theme.stroke.tertiary}`,
        }}
      >
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => onSubTab(t.id)}
            style={{
              flex: 1,
              border: "none",
              borderRadius: 10,
              padding: "7px 4px",
              cursor: "pointer",
              fontSize: 11,
              fontWeight: subTab === t.id ? 600 : 400,
              background: subTab === t.id ? theme.bg.elevated : "transparent",
              color: subTab === t.id ? theme.text.primary : theme.text.tertiary,
            }}
          >
            {t.label}
          </button>
        ))}
      </div>
    </div>
  );
}

function CurrentBookmarkList() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "12px 16px 16px" }}>
      {BOOKMARKS.map((b, i) => (
        <div
          key={b.surahId}
          style={{
            marginBottom: i === BOOKMARKS.length - 1 ? 0 : 12,
            padding: 16,
            borderRadius: 12,
            background: theme.bg.elevated,
            border: `1px solid ${theme.stroke.tertiary}`,
          }}
        >
          <ItemHeaderCurrent item={b} />
          <ArabicPreview text={b.arabic} />
          <Text tone="secondary" size="small" style={{ fontSize: 11, marginTop: 6 }}>
            {b.translation}
          </Text>
        </div>
      ))}
      <div
        style={{
          position: "relative",
          marginTop: 8,
          width: 40,
          height: 40,
          marginLeft: "auto",
          borderRadius: 9999,
          background: theme.accent.primary,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: theme.text.onAccent,
          fontSize: 14,
        }}
      >
        ...
      </div>
    </div>
  );
}

function ProposedBookmarkList() {
  return (
    <div style={{ padding: "0 16px 16px" }}>
      <Text
        tone="tertiary"
        size="small"
        weight="medium"
        style={{ fontSize: 10, letterSpacing: 0.5, marginBottom: 8, display: "block" }}
      >
        URUTKAN: TERBARU
      </Text>
      {BOOKMARKS.map((b, i) => (
        <div key={b.surahId} style={{ marginBottom: i === BOOKMARKS.length - 1 ? 0 : 8 }}>
          <PremiumItemCard item={b} trailing="penanda" />
        </div>
      ))}
    </div>
  );
}

function CurrentNotesList() {
  const theme = useHostTheme();
  const n = NOTES[0];
  return (
    <div style={{ padding: "12px 16px" }}>
      <div style={{ padding: 16, borderRadius: 12, background: theme.bg.elevated, border: `1px solid ${theme.stroke.tertiary}` }}>
        <ItemHeaderCurrent item={n} />
        <NoteBox text={n.note} />
      </div>
    </div>
  );
}

function ProposedNotesList() {
  const n = NOTES[0];
  return (
    <div style={{ padding: "0 16px 16px" }}>
      <PremiumItemCard item={n} trailing="catatan" note={n.note} />
    </div>
  );
}

function CurrentHighlightsList() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "8px 16px 16px" }}>
      <Row gap={6} style={{ marginBottom: 10, flexWrap: "wrap" }}>
        <Pill tone="neutral" size="sm">
          Semua
        </Pill>
        {["#F5C842", "#7BC67E", "#6BA3F5"].map((c) => (
          <div
            key={c}
            style={{
              width: 24,
              height: 24,
              borderRadius: 9999,
              background: c,
              border: `1px solid ${theme.stroke.secondary}`,
            }}
          />
        ))}
      </Row>
      <div style={{ padding: 16, borderRadius: 12, background: theme.bg.elevated, border: `1px solid ${theme.stroke.tertiary}` }}>
        <ItemHeaderCurrent item={HIGHLIGHTS[0]} accent={HIGHLIGHTS[0].color} />
      </div>
    </div>
  );
}

function ProposedHighlightsList() {
  const theme = useHostTheme();
  return (
    <div style={{ padding: "0 16px 16px" }}>
      <Row gap={6} style={{ marginBottom: 10, flexWrap: "wrap" }}>
        <Pill tone="accent" size="sm">
          Semua
        </Pill>
        {["#F5C842", "#7BC67E", "#6BA3F5", "#E88B8B"].map((c) => (
          <div
            key={c}
            style={{
              width: 28,
              height: 28,
              borderRadius: 8,
              background: c,
              border: `1px solid ${theme.stroke.secondary}`,
            }}
          />
        ))}
      </Row>
      <PremiumItemCard item={HIGHLIGHTS[0]} trailing="sorotan" accent={HIGHLIGHTS[0].color} />
    </div>
  );
}

function ItemHeaderCurrent({
  item,
  accent,
}: {
  item: { surahId: number; name: string; ayah: number; meaning?: string };
  accent?: string;
}) {
  const theme = useHostTheme();
  return (
    <Row gap={12} style={{ alignItems: "flex-start" }}>
      <div
        style={{
          width: 40,
          height: 40,
          borderRadius: 9999,
          background: theme.fill.secondary,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 13,
          fontWeight: 600,
          border: accent ? `2px solid ${accent}` : undefined,
        }}
      >
        {item.surahId}
      </div>
      <Stack gap={2} style={{ flex: 1 }}>
        <Row style={{ justifyContent: "space-between" }}>
          <Text size="small" weight="medium">
            {item.name}
          </Text>
          <Text tone="secondary" size="small" style={{ fontSize: 11 }}>
            Ayah {item.ayah}
          </Text>
        </Row>
        {item.meaning && (
          <Text tone="secondary" size="small" style={{ fontSize: 10 }}>
            {item.meaning}
          </Text>
        )}
      </Stack>
    </Row>
  );
}

function PremiumItemCard({
  item,
  trailing,
  note,
  accent,
}: {
  item: { surahId: number; name: string; ayah: number; arabic?: string; translation?: string; meaning?: string };
  trailing: "penanda" | "catatan" | "sorotan";
  note?: string;
  accent?: string;
}) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        padding: "12px 14px",
        borderRadius: 16,
        background: theme.bg.elevated,
        border: `1px solid ${theme.stroke.tertiary}`,
        display: "flex",
        gap: 12,
        alignItems: "flex-start",
      }}
    >
      <div
        style={{
          width: 36,
          height: 36,
          borderRadius: 10,
          background: accent ? `${accent}33` : theme.fill.secondary,
          border: accent ? `1.5px solid ${accent}` : `1px solid ${theme.stroke.tertiary}`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 12,
          fontWeight: 600,
          flexShrink: 0,
        }}
      >
        {item.surahId}
      </div>
      <Stack gap={4} style={{ flex: 1, minWidth: 0 }}>
        <Row style={{ justifyContent: "space-between", alignItems: "baseline" }}>
          <Text size="small" weight="medium">
            {item.name}
          </Text>
          <Text tone="secondary" size="small" style={{ fontSize: 10 }}>
            {item.ayah}
          </Text>
        </Row>
        {item.arabic && <ArabicPreview text={item.arabic} />}
        {item.translation && (
          <Text tone="secondary" size="small" style={{ fontSize: 10, lineHeight: 1.35 }}>
            {item.translation}
          </Text>
        )}
        {note && <NoteBox text={note} compact />}
      </Stack>
      <Text tone="tertiary" style={{ fontSize: 16, flexShrink: 0 }}>
        ›
      </Text>
    </div>
  );
}

function ArabicPreview({ text }: { text: string }) {
  return (
    <Text size="small" style={{ fontSize: 13, lineHeight: 1.5, textAlign: "right", direction: "rtl" }}>
      {text}
    </Text>
  );
}

function NoteBox({ text, compact }: { text: string; compact?: boolean }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        marginTop: compact ? 4 : 8,
        padding: compact ? "6px 8px" : "8px 10px",
        borderRadius: 8,
        background: theme.fill.secondary,
        border: `1px solid ${theme.stroke.tertiary}`,
      }}
    >
      <Text size="small" style={{ fontSize: 10, lineHeight: 1.4 }}>
        {text}
      </Text>
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
          <Text
            key={t}
            size="small"
            tone={t === "Koleksi" ? "primary" : "tertiary"}
            weight={t === "Koleksi" ? "medium" : "normal"}
            style={{ fontSize: 9 }}
          >
            {t}
          </Text>
        ))}
      </Row>
    </div>
  );
}

function SpecPanel({ view, subTab }: { view: View; subTab: SubTab }) {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Spesifikasi Koleksi</H2>

      <Callout tone={view === "proposed" ? "success" : "warning"}>
        <Text size="small" weight="medium">
          {view === "proposed" ? "Usulan" : "Masalah saat ini"}
        </Text>
        <Text size="small" tone="secondary">
          {view === "proposed"
            ? "Selaras Beranda/Jelajahi: cream backdrop, segment pill tabs, stat chips, kartu flat 16px + chevron. Judul lokal getMenuText('library')."
            : "Hardcode 'My Library', TabBar underline Material, elevation Card, mini FAB seleksi, empty state teks polos, search mode sembunyikan tabs."}
        </Text>
      </Callout>

      <Card>
        <CardHeader>Header &amp; navigasi</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ HomeBackdrop.topTint pada AppBar (toolbarHeight 48)</Text>
            <Text size="small" tone="secondary">+ getMenuText(&apos;library&apos;) — bukan hardcode &quot;My Library&quot;</Text>
            <Text size="small" tone="secondary">+ Search pill compact di header (bukan mode terpisah)</Text>
            <Text size="small" tone="secondary">+ Segment control menggantikan TabBar Material</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Body — tab {subTab}</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ Stat row: Pill count penanda / catatan / sorotan</Text>
            <Text size="small" tone="secondary">+ Kartu: radius 16, border only (elevation 0)</Text>
            <Text size="small" tone="secondary">+ Surah badge: rounded square 36px (bukan lingkaran 40px)</Text>
            <Text size="small" tone="secondary">+ Chevron kanan; swipe/long-press untuk seleksi</Text>
            <Text size="small" tone="secondary">+ Empty state: icon box + judul + CTA ke Baca</Text>
            <Text size="small" tone="secondary">- Hapus mini FAB checklist (Android-ish)</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>File yang disentuh</CardHeader>
        <CardBody>
          <Stack gap={4}>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/library/my_library_screen.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/bookmarks/widgets/bookmarks_tab_content.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/notes/widgets/notes_tab_content.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/highlights/highlights_screen.dart
            </Text>
          </Stack>
        </CardBody>
      </Card>
    </Stack>
  );
}

function ScreenAudit() {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Audit layar — prioritas premium iOS-ready</H2>
      <Text tone="secondary" size="small">
        Ringkasan status seluruh tab root dan child screen. Mockup terpisah sudah ada untuk Cari dan Unduhan tilawah.
      </Text>
      <Grid columns={2} gap={12}>
        {AUDIT.map((row) => (
          <AuditCard key={row.screen} {...row} />
        ))}
      </Grid>
      <Callout tone="info">
        <Text size="small" weight="medium">Rekomendasi urutan implementasi</Text>
        <Text size="small" tone="secondary">
          1) Koleksi (mockup ini) — 2) Cari (search-premium) — 3) Baca backdrop + mode chips — 4) Unduhan tilawah child header
        </Text>
      </Callout>
    </Stack>
  );
}

function AuditCard({
  screen,
  status,
  note,
}: {
  screen: string;
  status: "done" | "partial" | "planned" | "active";
  note: string;
}) {
  const tone =
    status === "done" ? "success" : status === "active" ? "accent" : status === "planned" ? "warning" : "neutral";
  const label =
    status === "done"
      ? "Sudah premium"
      : status === "active"
        ? "Sedang dirancang"
        : status === "planned"
          ? "Mockup siap"
          : "Perlu polish";
  return (
    <Card>
      <CardHeader
        trailing={
          <Pill tone={tone} size="sm">
            {label}
          </Pill>
        }
      >
        {screen}
      </CardHeader>
      <CardBody>
        <Text size="small" tone="secondary">
          {note}
        </Text>
      </CardBody>
    </Card>
  );
}
