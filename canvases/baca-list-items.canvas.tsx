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
type ListMode = "surah" | "juz" | "pages";

const SURAH_FLAT = [
  { id: 1, name: "Al-Fatihah", meaning: "Pembukaan", ayah: 7 },
  { id: 2, name: "Al-Baqarah", meaning: "Sapi", ayah: 286 },
];

const JUZ1_ROWS = [
  { id: 1, name: "Al-Fatihah", detail: "7 ayat di juz ini" },
  { id: 2, name: "Al-Baqarah", detail: "141 ayat di juz ini" },
];

const PAGE1_ROWS = [{ id: 1, name: "Al-Fatihah", detail: "7 ayat di halaman ini" }];

export default function BacaListItemsCanvas() {
  const [view, setView] = useCanvasState<View>("view", "proposed");
  const [mode, setMode] = useCanvasState<ListMode>("mode", "juz");

  return (
    <Stack gap={24} style={{ padding: 24, maxWidth: 1100, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Baca — list items mockup</H1>
        <Text tone="secondary">
          Detail polish untuk baris surah: grouped elevated list di cream backdrop + badge surah
          persegi 32px. Struktur data tidak berubah (Surah flat / Juz grouped / Mushaf grouped).
        </Text>
        <Row gap={16} style={{ alignItems: "center", flexWrap: "wrap", marginTop: 4 }}>
          <Row gap={8} style={{ alignItems: "center" }}>
            <Toggle checked={view === "proposed"} onChange={(on) => setView(on ? "proposed" : "current")} />
            <Text tone="secondary" size="small">
              {view === "proposed" ? "Usulan" : "Saat ini (kode)"}
            </Text>
          </Row>
          <ModePicker mode={mode} onMode={setMode} />
        </Row>
      </Stack>

      <Grid columns={2} gap={24} style={{ alignItems: "start" }}>
        <Stack gap={12}>
          <H2 style={{ margin: 0, textAlign: "center" }}>
            {view === "proposed" ? "Usulan" : "Saat ini"} — {modeLabel(mode)}
          </H2>
          <ListPreview view={view} mode={mode} />
        </Stack>
        <SpecPanel view={view} mode={mode} />
      </Grid>
    </Stack>
  );
}

function modeLabel(mode: ListMode) {
  if (mode === "surah") return "Mode Surah";
  if (mode === "juz") return "Mode Juz";
  return "Mode Mushaf";
}

function ModePicker({ mode, onMode }: { mode: ListMode; onMode: (m: ListMode) => void }) {
  const theme = useHostTheme();
  const items: ListMode[] = ["surah", "juz", "pages"];
  const labels = { surah: "Surah", juz: "Juz", pages: "Mushaf" };
  return (
    <Row gap={6}>
      {items.map((m) => (
        <button
          key={m}
          type="button"
          onClick={() => onMode(m)}
          style={{
            border: `1px solid ${mode === m ? theme.accent.primary : theme.stroke.tertiary}`,
            borderRadius: 8,
            padding: "4px 10px",
            fontSize: 11,
            cursor: "pointer",
            background: mode === m ? theme.fill.secondary : theme.bg.elevated,
            fontWeight: mode === m ? 600 : 400,
          }}
        >
          {labels[m]}
        </button>
      ))}
    </Row>
  );
}

function ListPreview({ view, mode }: { view: View; mode: ListMode }) {
  const theme = useHostTheme();
  const cream = theme.fill.quaternary;

  return (
    <div
      style={{
        width: 320,
        margin: "0 auto",
        borderRadius: 24,
        border: `1px solid ${theme.stroke.secondary}`,
        overflow: "hidden",
        background: cream,
      }}
    >
      <div
        style={{
          padding: "8px 12px",
          fontSize: 10,
          color: theme.text.tertiary,
          borderBottom: `1px dashed ${theme.stroke.tertiary}`,
          background: theme.fill.secondary,
        }}
      >
        HomeBackdrop cream — konten scroll di sini
      </div>
      <div style={{ padding: "10px 0 16px", minHeight: 420 }}>
        {mode === "surah" && (
          <FlatSurahList view={view} items={SURAH_FLAT} />
        )}
        {mode === "juz" && (
          <GroupedList
            view={view}
            sectionTitle="Juz 1"
            actionLabel="Baca Juz"
            rows={JUZ1_ROWS}
          />
        )}
        {mode === "pages" && (
          <GroupedList
            view={view}
            sectionTitle="Halaman 1"
            actionLabel="Baca Halaman"
            rows={PAGE1_ROWS}
          />
        )}
      </div>
    </div>
  );
}

function FlatSurahList({
  view,
  items,
}: {
  view: View;
  items: { id: number; name: string; meaning: string; ayah: number }[];
}) {
  return (
    <div style={{ padding: "0 16px" }}>
      {items.map((s, i) => (
        <SurahItemRow
          key={s.id}
          view={view}
          id={s.id}
          title={s.name}
          subtitle={`${s.meaning} · ${s.ayah} ayat`}
          standalone
          isLast={i === items.length - 1}
          showArabic
        />
      ))}
    </div>
  );
}

function GroupedList({
  view,
  sectionTitle,
  actionLabel,
  rows,
}: {
  view: View;
  sectionTitle: string;
  actionLabel: string;
  rows: { id: number; name: string; detail: string }[];
}) {
  const theme = useHostTheme();
  const elevated = view === "proposed";

  return (
    <div style={{ marginBottom: 8 }}>
      <Row
        style={{
          padding: "4px 16px 8px",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <Text weight="medium" style={{ fontSize: 15 }}>
          {sectionTitle}
        </Text>
        <Text tone="primary" size="small" style={{ fontSize: 11, textDecoration: "underline" }}>
          {actionLabel}
        </Text>
      </Row>
      <div style={{ padding: "0 16px" }}>
        <div
          style={{
            borderRadius: 16,
            overflow: "hidden",
            background: theme.bg.elevated,
            border: elevated
              ? `1px solid ${theme.stroke.tertiary}`
              : `1px solid ${theme.stroke.tertiary}`,
            boxShadow: elevated
              ? `0 1px 0 ${theme.stroke.tertiary}, 0 4px 12px rgba(0,0,0,0.04)`
              : undefined,
          }}
        >
          {rows.map((r, i) => (
            <SurahItemRow
              key={r.id}
              view={view}
              id={r.id}
              title={r.name}
              subtitle={r.detail}
              isLast={i === rows.length - 1}
              showArabic
            />
          ))}
        </div>
        {view === "proposed" && (
          <Text tone="tertiary" size="small" style={{ fontSize: 9, marginTop: 6, display: "block" }}>
            Satu kartu elevated per section — baris surah di dalam, divider antar baris
          </Text>
        )}
      </div>
    </div>
  );
}

function SurahItemRow({
  view,
  id,
  title,
  subtitle,
  standalone,
  isLast,
  showArabic,
}: {
  view: View;
  id: number;
  title: string;
  subtitle: string;
  standalone?: boolean;
  isLast?: boolean;
  showArabic?: boolean;
}) {
  const theme = useHostTheme();
  const badgeSize = view === "proposed" ? 32 : 36;
  const badgeRadius = view === "proposed" ? 8 : 9999;

  const badge = (
    <div style={{ position: "relative", flexShrink: 0 }}>
      <div
        style={{
          width: badgeSize,
          height: badgeSize,
          borderRadius: badgeRadius,
          background: theme.fill.secondary,
          border: `1px solid ${theme.stroke.tertiary}`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: view === "proposed" ? 11 : 12,
          fontWeight: 600,
        }}
      >
        {id}
      </div>
      {view === "proposed" && (
        <span
          style={{
            position: "absolute",
            top: -6,
            left: -4,
            fontSize: 8,
            color: theme.accent.primary,
            fontWeight: 600,
            whiteSpace: "nowrap",
          }}
        >
          32px
        </span>
      )}
    </div>
  );

  const content = (
    <>
      {badge}
      <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
        <Text size="small" weight="medium">
          {title}
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: 10 }}>
          {subtitle}
        </Text>
      </Stack>
      {showArabic && (
        <Stack gap={2} style={{ alignItems: "flex-end", flexShrink: 0 }}>
          <Text tone="tertiary" style={{ fontSize: 14 }}>
            ﷽
          </Text>
          <Text tone="secondary" size="small" style={{ fontSize: 9 }}>
            glyph
          </Text>
        </Stack>
      )}
    </>
  );

  if (standalone) {
    const elevated = view === "proposed";
    return (
      <div
        style={{
          marginBottom: isLast ? 0 : 8,
          padding: "11px 12px",
          borderRadius: 16,
          background: theme.bg.elevated,
          border: `1px solid ${theme.stroke.tertiary}`,
          boxShadow: elevated
            ? "0 1px 0 rgba(0,0,0,0.04), 0 3px 10px rgba(0,0,0,0.04)"
            : view === "current"
              ? "0 2px 8px rgba(0,0,0,0.08)"
              : undefined,
          display: "flex",
          alignItems: "flex-start",
          gap: 10,
        }}
      >
        {content}
      </div>
    );
  }

  return (
    <div
      style={{
        padding: "11px 12px",
        display: "flex",
        alignItems: "flex-start",
        gap: 10,
        borderBottom: isLast ? undefined : `1px solid ${theme.stroke.tertiary}`,
      }}
    >
      {content}
    </div>
  );
}

function SpecPanel({ view, mode }: { view: View; mode: ListMode }) {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Spesifikasi list items</H2>

      <Callout tone="info">
        <Text size="small" weight="medium">
          Scope polish — bukan ubah struktur
        </Text>
        <Text size="small" tone="secondary">
          Surah: 1 kartu = 1 surah. Juz/Mushaf: header section + 1 kartu berisi beberapa surah.
          Hanya visual row + container.
        </Text>
      </Callout>

      <Card>
        <CardHeader>Cream backdrop</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">
              + List scroll di atas HomeBackdrop (sudah di read_screen)
            </Text>
            <Text size="small" tone="secondary">
              + Jarak antar kartu/section — cream terlihat di celah 8px
            </Text>
            <Text size="small" tone="secondary">
              + Kartu: surface ~94% opacity, border outlineVariant 0.45–0.55
            </Text>
            <Text size="small" tone="secondary">
              + Elevated: shadow sangat halus (blur 8–12, alpha 0.04) — bukan Material lama
            </Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>32px square surah badge</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ Ukuran: 32 × 32 px (Baca index — lebih padat)</Text>
            <Text size="small" tone="secondary">+ Radius: 8 px (rounded square)</Text>
            <Text size="small" tone="secondary">+ Fill: surfaceContainerHighest ~55%</Text>
            <Text size="small" tone="secondary">+ Border: outlineVariant ~45%, 1 px</Text>
            <Text size="small" tone="secondary">+ Teks: labelMedium, w600, onSurfaceVariant</Text>
            <Text size="small" tone="secondary">
              - Saat ini: 36 px lingkaran (surah_list) / 36 px circle (juz, page)
            </Text>
            <Text size="small" tone="secondary">
              Ref Koleksi: LibraryItemCard pakai 36 px — Baca sengaja 32 px untuk index panjang
            </Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          Grouped elevated — {mode === "surah" ? "N/A (flat cards)" : mode === "juz" ? "Juz" : "Mushaf"}
        </CardHeader>
        <CardBody>
          {mode === "surah" ? (
            <Stack gap={6}>
              <Text size="small" tone="secondary">Mode Surah: kartu terpisah per surah (bukan grouped)</Text>
              <Text size="small" tone="secondary">+ spacing 8 px, radius 16 px, badge 32 px</Text>
              <Text size="small" tone="secondary">+ Tetap: nama Latin + makna + glyph Arab + jumlah ayat kanan</Text>
            </Stack>
          ) : (
            <Stack gap={6}>
              <Text size="small" tone="secondary">
                + Header di luar kartu: &quot;Juz N&quot; / &quot;Halaman N&quot; + link Baca
              </Text>
              <Text size="small" tone="secondary">
                + Satu Container elevated per section, radius 16 px
              </Text>
              <Text size="small" tone="secondary">
                + Row surah di dalam: padding 12 px, divider antar row (bukan gap)
              </Text>
              <Text size="small" tone="secondary">
                + Row layout: badge 32 | nama + makna | glyph + &quot;N ayat di juz/halaman&quot;
              </Text>
              <Text size="small" tone="secondary">- Hapus boxShadow ganda per row — shadow hanya di group card</Text>
            </Stack>
          )}
        </CardBody>
      </Card>

      <Card>
        <CardHeader>Widget bersama (usulan)</CardHeader>
        <CardBody>
          <Stack gap={4}>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/widgets/read_surah_badge.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/widgets/read_surah_list_row.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/widgets/read_grouped_surah_card.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              lib/features/read/surah_list_view.dart
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

      <Callout tone={view === "proposed" ? "success" : "warning"}>
        <Text size="small" tone="secondary">
          {view === "proposed"
            ? "Setujui mockup ini → implementasi extract widget + terapkan ke 3 list view."
            : "Saat ini: border flat sudah sebagian; badge masih 36 px circle; grouped belum elevated halus."}
        </Text>
      </Callout>
    </Stack>
  );
}
