import {
  Callout,
  Card,
  CardBody,
  CardHeader,
  Grid,
  H1,
  H2,
  Row,
  Stack,
  Text,
  Toggle,
  useCanvasState,
  useHostTheme,
} from "cursor/canvas";

type View = "current" | "proposed";
type ReadMode = "surah" | "juz" | "pages";

const SURAHS = [
  { id: 1, name: "Al-Fatihah", meaning: "Pembukaan", ayah: 7 },
  { id: 2, name: "Al-Baqarah", meaning: "Sapi", ayah: 286 },
  { id: 3, name: "Ali 'Imran", meaning: "Keluarga Imran", ayah: 200 },
];

/** Juz 1 sample — grouped section + surahs inside one card (matches juz_list_view.dart) */
const JUZ1 = {
  juzNo: 1,
  surahs: [
    { id: 1, name: "Al-Fatihah", ayah: 7 },
    { id: 2, name: "Al-Baqarah", ayah: 141 },
  ],
};

/** Page 1 sample — grouped section + surahs on that mushaf page (matches page_list_view.dart) */
const PAGE1 = {
  pageNo: 1,
  surahs: [{ id: 1, name: "Al-Fatihah", ayah: 7 }],
};

const READ_SUBTITLE = "Surah, juz, atau mushaf — pilih cara baca Anda";

const MODES: { id: ReadMode; label: string; icon: string }[] = [
  { id: "surah", label: "Surah", icon: "S" },
  { id: "juz", label: "Juz", icon: "J" },
  { id: "pages", label: "Mushaf", icon: "M" },
];

export default function BacaPremiumCanvas() {
  const [view, setView] = useCanvasState<View>("view", "proposed");
  const [mode, setMode] = useCanvasState<ReadMode>("mode", "surah");

  return (
    <Stack gap={24} style={{ padding: 24, maxWidth: 1080, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Baca — premium mockup</H1>
        <Text tone="secondary">
          Tab Baca (Read): selaraskan dengan Beranda/Koleksi — HomeBackdrop cream, segment pill
          unified. Konten list per mode (Surah / Juz / Mushaf) tidak berubah — hanya chrome
          premium. Ganti chip untuk lihat struktur list yang berbeda.
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
          {view === "current" ? <CurrentScreen mode={mode} onMode={setMode} /> : <ProposedScreen mode={mode} onMode={setMode} />}
        </PhoneFrame>
        <SpecPanel view={view} mode={mode} />
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
        <BottomNav active="Baca" />
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

function CurrentScreen({ mode, onMode }: { mode: ReadMode; onMode: (m: ReadMode) => void }) {
  const theme = useHostTheme();
  return (
    <>
      <CurrentHeader />
      <div style={{ padding: "6px 16px 8px", borderBottom: `1px solid ${theme.stroke.tertiary}` }}>
        <CurrentModeChips mode={mode} onMode={onMode} />
      </div>
      <div style={{ flex: 1, overflow: "auto", background: theme.bg.elevated }}>
        <ReadModeContent mode={mode} variant="current" />
      </div>
    </>
  );
}

function ProposedScreen({ mode, onMode }: { mode: ReadMode; onMode: (m: ReadMode) => void }) {
  const theme = useHostTheme();
  return (
    <>
      <ProposedHeader />
      <div style={{ flex: 1, overflow: "auto", background: theme.fill.quaternary }}>
        <div style={{ padding: "8px 16px 0" }}>
          <SegmentModeTabs mode={mode} onMode={onMode} />
        </div>
        <ReadModeContent mode={mode} variant="proposed" />
      </div>
    </>
  );
}

function CurrentHeader() {
  const theme = useHostTheme();
  return (
    <div
      style={{
        padding: "4px 16px 8px",
        borderBottom: `1px solid ${theme.stroke.tertiary}`,
        background: theme.bg.elevated,
      }}
    >
      <Row style={{ justifyContent: "space-between", alignItems: "flex-start" }}>
        <Row gap={10} style={{ alignItems: "center" }}>
          <IconCircle />
          <Stack gap={2}>
            <Text weight="medium" style={{ fontSize: 17, letterSpacing: -0.3 }}>
              Al-Qur&apos;an
            </Text>
            <Text tone="secondary" size="small" style={{ fontSize: 11 }}>
              {READ_SUBTITLE}
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
        padding: "4px 16px 8px",
        borderBottom: `1px solid ${theme.stroke.tertiary}`,
        background: theme.fill.secondary,
      }}
    >
      <Row style={{ justifyContent: "space-between", alignItems: "flex-start" }}>
        <Row gap={10} style={{ alignItems: "center" }}>
          <IconCircle />
          <Stack gap={2}>
            <Text weight="medium" style={{ fontSize: 17, letterSpacing: -0.3 }}>
              Al-Qur&apos;an
            </Text>
            <Text tone="secondary" size="small" style={{ fontSize: 11 }}>
              {READ_SUBTITLE}
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

function IconCircle() {
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
      B
    </div>
  );
}

function CurrentModeChips({ mode, onMode }: { mode: ReadMode; onMode: (m: ReadMode) => void }) {
  const theme = useHostTheme();
  return (
    <Row gap={8}>
      {MODES.map((m) => {
        const selected = mode === m.id;
        return (
          <button
            key={m.id}
            type="button"
            onClick={() => onMode(m.id)}
            style={{
              flex: 1,
              border: selected ? "none" : `1px solid ${theme.stroke.tertiary}`,
              borderRadius: 9999,
              padding: "8px 6px",
              cursor: "pointer",
              background: selected ? theme.accent.primary : theme.bg.elevated,
              color: selected ? theme.text.onAccent : theme.text.tertiary,
              fontSize: 11,
              fontWeight: selected ? 600 : 500,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 4,
            }}
          >
            <span style={{ fontSize: 10 }}>{m.icon}</span>
            {m.label}
          </button>
        );
      })}
    </Row>
  );
}

function SegmentModeTabs({ mode, onMode }: { mode: ReadMode; onMode: (m: ReadMode) => void }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        display: "flex",
        padding: 3,
        borderRadius: 12,
        background: theme.fill.secondary,
        border: `1px solid ${theme.stroke.tertiary}`,
      }}
    >
      {MODES.map((m) => {
        const selected = mode === m.id;
        return (
          <button
            key={m.id}
            type="button"
            onClick={() => onMode(m.id)}
            style={{
              flex: 1,
              border: "none",
              borderRadius: 10,
              padding: "8px 4px",
              cursor: "pointer",
              fontSize: 11,
              fontWeight: selected ? 600 : 400,
              background: selected ? theme.bg.elevated : "transparent",
              color: selected ? theme.text.primary : theme.text.tertiary,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 4,
            }}
          >
            <span style={{ fontSize: 10, opacity: 0.85 }}>{m.icon}</span>
            {m.label}
          </button>
        );
      })}
    </div>
  );
}

function ReadModeContent({ mode, variant }: { mode: ReadMode; variant: "current" | "proposed" }) {
  if (mode === "surah") return <SurahModeList variant={variant} />;
  if (mode === "juz") return <JuzModeList variant={variant} />;
  return <MushafModeList variant={variant} />;
}

/** Mode Surah: satu kartu per surah (114 item) */
function SurahModeList({ variant }: { variant: "current" | "proposed" }) {
  return (
    <div style={{ padding: "12px 16px 16px" }}>
      {SURAHS.map((s, i) => (
        <SurahRow key={s.id} id={s.id} name={s.name} sub={`${s.meaning} · ${s.ayah} ayat`} variant={variant} isLast={i === SURAHS.length - 1} standalone />
      ))}
      {variant === "current" && (
        <Text tone="tertiary" size="small" style={{ fontSize: 10, marginTop: 8, display: "block" }}>
          Kartu surah saat ini memakai boxShadow
        </Text>
      )}
    </div>
  );
}

/** Mode Juz: section per juz, header + kartu berisi beberapa surah */
function JuzModeList({ variant }: { variant: "current" | "proposed" }) {
  return (
    <div style={{ padding: "8px 8px 16px" }}>
      <GroupedSection
        title={`Juz ${JUZ1.juzNo}`}
        actionLabel="Baca Juz"
        variant={variant}
      >
        {JUZ1.surahs.map((s, i) => (
          <SurahRow
            key={s.id}
            id={s.id}
            name={s.name}
            sub={`${s.ayah} ayat di juz ini`}
            variant={variant}
            isLast={i === JUZ1.surahs.length - 1}
          />
        ))}
      </GroupedSection>
      <GroupedSection title="Juz 2" actionLabel="Baca Juz" variant={variant} faded>
        <Text tone="tertiary" size="small" style={{ fontSize: 10, padding: "8px 14px" }}>
          … sisa surah Al-Baqarah, Ali &apos;Imran, …
        </Text>
      </GroupedSection>
    </div>
  );
}

/** Mode Mushaf: section per halaman, header + kartu surah di halaman itu */
function MushafModeList({ variant }: { variant: "current" | "proposed" }) {
  return (
    <div style={{ padding: "8px 8px 16px" }}>
      <GroupedSection title={`Halaman ${PAGE1.pageNo}`} actionLabel="Baca Halaman" variant={variant}>
        {PAGE1.surahs.map((s, i) => (
          <SurahRow
            key={s.id}
            id={s.id}
            name={s.name}
            sub={`${s.ayah} ayat di halaman ini`}
            variant={variant}
            isLast={i === PAGE1.surahs.length - 1}
          />
        ))}
      </GroupedSection>
      <GroupedSection title="Halaman 2" actionLabel="Baca Halaman" variant={variant} faded>
        <SurahRow id={2} name="Al-Baqarah" sub="Ayat 1–5 di halaman ini" variant={variant} isLast />
      </GroupedSection>
    </div>
  );
}

function GroupedSection({
  title,
  actionLabel,
  variant,
  faded,
  children,
}: {
  title: string;
  actionLabel: string;
  variant: "current" | "proposed";
  faded?: boolean;
  children?: unknown;
}) {
  const theme = useHostTheme();
  return (
    <div style={{ marginBottom: 12, opacity: faded ? 0.55 : 1 }}>
      <Row style={{ padding: "12px 16px 6px", justifyContent: "space-between", alignItems: "center" }}>
        <Text weight="medium" style={{ fontSize: 15 }}>
          {title}
        </Text>
        <Text tone="primary" size="small" style={{ fontSize: 11, textDecoration: "underline" }}>
          {actionLabel}
        </Text>
      </Row>
      <div
        style={{
          margin: "0 8px",
          borderRadius: 16,
          background: theme.bg.elevated,
          border: variant === "proposed" ? `1px solid ${theme.stroke.tertiary}` : undefined,
          overflow: "hidden",
        }}
      >
        {children}
      </div>
    </div>
  );
}

function SurahRow({
  id,
  name,
  sub,
  variant,
  isLast,
  standalone,
}: {
  id: number;
  name: string;
  sub: string;
  variant: "current" | "proposed";
  isLast?: boolean;
  standalone?: boolean;
}) {
  const theme = useHostTheme();
  const inner = (
    <>
      <div
        style={{
          width: 36,
          height: 36,
          borderRadius: variant === "proposed" ? 10 : 9999,
          background: theme.fill.secondary,
          border: variant === "proposed" ? `1px solid ${theme.stroke.tertiary}` : undefined,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 12,
          fontWeight: 600,
          flexShrink: 0,
        }}
      >
        {id}
      </div>
      <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
        <Text size="small" weight="medium">
          {name}
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: 10 }}>
          {sub}
        </Text>
      </Stack>
      <Text tone="tertiary" style={{ fontSize: 16 }}>
        ›
      </Text>
    </>
  );

  if (standalone) {
    return (
      <div
        style={{
          marginBottom: isLast ? 0 : 8,
          padding: "12px 14px",
          borderRadius: 16,
          background: theme.bg.elevated,
          border: variant === "proposed" ? `1px solid ${theme.stroke.tertiary}` : undefined,
          display: "flex",
          alignItems: "center",
          gap: 12,
        }}
      >
        {inner}
      </div>
    );
  }

  return (
    <div
      style={{
        padding: "12px 14px",
        display: "flex",
        alignItems: "center",
        gap: 12,
        borderBottom: isLast ? undefined : `1px solid ${theme.stroke.tertiary}`,
      }}
    >
      {inner}
    </div>
  );
}

function BottomNav({ active }: { active: string }) {
  const theme = useHostTheme();
  const tabs = ["Beranda", "Baca", "Cari", "Jelajahi", "Koleksi"];
  return (
    <div style={{ borderTop: `1px solid ${theme.stroke.secondary}`, padding: "8px 12px 14px" }}>
      <Row style={{ justifyContent: "space-between" }}>
        {tabs.map((t) => (
          <Text
            key={t}
            size="small"
            tone={t === active ? "primary" : "tertiary"}
            weight={t === active ? "medium" : "normal"}
            style={{ fontSize: 9 }}
          >
            {t}
          </Text>
        ))}
      </Row>
    </div>
  );
}

function SpecPanel({ view, mode }: { view: View; mode: ReadMode }) {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Spesifikasi Baca</H2>

      <Callout tone="info">
        <Text size="small" weight="medium">
          Konten list tidak berubah
        </Text>
        <Text size="small" tone="secondary">
          Surah = flat 114 kartu. Juz = section per juz + kartu berisi beberapa surah + link
          &quot;Baca Juz&quot;. Mushaf = section per halaman + surah di halaman itu + link
          &quot;Baca Halaman&quot;. Premium hanya mengubah backdrop, header, dan gaya chip.
        </Text>
      </Callout>

      <Callout tone={view === "proposed" ? "success" : "warning"}>
        <Text size="small" weight="medium">
          {view === "proposed" ? "Usulan" : "Masalah saat ini"}
        </Text>
        <Text size="small" tone="secondary">
          {view === "proposed"
            ? "HomeBackdrop cream + segment pill unified (sama Koleksi). Hilangkan gradient chip terpisah di AppBar bottom. Mode chips pindah ke body di bawah header."
            : "AppBar putih polos, 3 chip terpisah dengan gradient saat selected, segment di AppBar bottom — tidak selaras tab premium lain."}
        </Text>
      </Callout>

      <Card>
        <CardHeader>Header &amp; backdrop</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ HomeBackdrop.topTint pada AppBar</Text>
            <Text size="small" tone="secondary">+ HomeBackdrop wrap body (cream wash)</Text>
            <Text size="small" tone="secondary">+ Judul tetap Al-Qur&apos;an (bukan &quot;Baca&quot;)</Text>
            <Text size="small" tone="secondary">+ Subtitle (4 locale):</Text>
            <Text size="small" tone="secondary">id — Surah, juz, atau mushaf — pilih cara baca Anda</Text>
            <Text size="small" tone="secondary">en — Surah, juz, or mushaf — choose how you read</Text>
            <Text size="small" tone="secondary">zh — Surah、Juz 或 Mushaf — 选择您的阅读方式</Text>
            <Text size="small" tone="secondary">ja — Surah、Juz、Mushaf — 読み方を選びましょう</Text>
            <Text size="small" tone="secondary">Surah / Juz / Mushaf — istilah sama di semua locale</Text>
            <Text size="small" tone="secondary">- Hapus hardcode subtitle lama di read_screen.dart</Text>
            <Text size="small" tone="secondary">+ Search icon di AppBar (toggle QuickSearchBar) — tetap</Text>
            <Text size="small" tone="secondary">- Hapus PreferredSize bottom di AppBar untuk mode chips</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Mode chips — tab {mode}</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ Segment pill unified (reuse pola LibrarySegmentTabs)</Text>
            <Text size="small" tone="secondary">+ Posisi: body, padding 16px horizontal, di atas list</Text>
            <Text size="small" tone="secondary">+ Selected: elevated surface flat, bukan gradient</Text>
            <Text size="small" tone="secondary">+ Icon + label Surah / Juz / Mushaf tetap</Text>
            <Text size="small" tone="secondary">- Hapus LinearGradient AppColors.warmPrimary pada chip</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Opsional — polish kartu (semua mode)</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">Surah: kartu terpisah flat border</Text>
            <Text size="small" tone="secondary">Juz/Mushaf: grouped card + divider antar surah (struktur tetap)</Text>
            <Text size="small" tone="secondary">+ Badge surah: rounded square 36px</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>File implementasi</CardHeader>
        <CardBody>
          <Stack gap={4}>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/read_screen.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/library/widgets/library_segment_tabs.dart (extract shared)
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/surah_list_view.dart (opsional polish)
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/juz_list_view.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/page_list_view.dart
            </Text>
          </Stack>
        </CardBody>
      </Card>
    </Stack>
  );
}
