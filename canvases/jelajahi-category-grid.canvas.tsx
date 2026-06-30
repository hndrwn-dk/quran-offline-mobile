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
type Hub = "science" | "theme";

const SCIENCE = [
  { icon: "G", title: "Alam semesta", sub: "5 topik" },
  { icon: "B", title: "Biologi", sub: "5 topik" },
  { icon: "E", title: "Bumi & lingkungan", sub: "5 topik" },
  { icon: "F", title: "Fisika & materi", sub: "4 topik" },
];

const THEMES = [
  { icon: "A", title: "Ampun & tobat", sub: "7 doa" },
  { icon: "I", title: "Iman & hati", sub: "4 doa" },
  { icon: "S", title: "Sabar & ketenangan", sub: "2 topik" },
  { icon: "U", title: "Ujian & cemas", sub: "3 doa · 2 renungan" },
  { icon: "P", title: "Perlindungan", sub: "4 doa" },
  { icon: "R", title: "Rezeki & petunjuk", sub: "4 doa · 1 renungan" },
];

const HUB_REF = { icon: "S", title: "Sains", sub: "19 topik · Al-Qur'an dan alam semesta" };

export default function JelajahiCategoryGridCanvas() {
  const [view, setView] = useCanvasState<View>("view", "proposed");
  const [hub, setHub] = useCanvasState<Hub>("hub", "science");

  const items = hub === "science" ? SCIENCE : THEMES;
  const hubTitle = hub === "science" ? "Sains" : "Tema hidup";
  const hubSub =
    hub === "science"
      ? "Al-Qur'an dan alam semesta"
      : "Doa, zikir, dan renungan ayat";

  return (
    <Stack gap={24} style={{ padding: 24, maxWidth: 1100, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Jelajahi child — list kategori (seperti parent)</H1>
        <Text tone="secondary">
          Ganti grid 2 kolom dengan baris penuh line-by-line — identik{" "}
          <Text weight="medium">ExploreHubSectionCard</Text> di hub Jelajahi. Judul panjang
          tidak memotong kotak.
        </Text>
        <Row gap={16} style={{ alignItems: "center", flexWrap: "wrap", marginTop: 4 }}>
          <Row gap={8} style={{ alignItems: "center" }}>
            <Toggle checked={view === "proposed"} onChange={(on) => setView(on ? "proposed" : "current")} />
            <Text tone="secondary" size="small">
              {view === "proposed" ? "Usulan (list)" : "Saat ini (grid)"}
            </Text>
          </Row>
          <HubPicker hub={hub} onHub={setHub} />
        </Row>
      </Stack>

      <Grid columns={2} gap={24} style={{ alignItems: "start" }}>
        <PhonePreview title={hubTitle} subtitle={hubSub} view={view} items={items} />
        <SpecPanel view={view} hub={hub} />
      </Grid>
    </Stack>
  );
}

function HubPicker({ hub, onHub }: { hub: Hub; onHub: (h: Hub) => void }) {
  const theme = useHostTheme();
  const opts: { id: Hub; label: string }[] = [
    { id: "science", label: "Sains" },
    { id: "theme", label: "Tema hidup" },
  ];
  return (
    <Row gap={6}>
      {opts.map((o) => (
        <button
          key={o.id}
          type="button"
          onClick={() => onHub(o.id)}
          style={{
            border: `1px solid ${hub === o.id ? theme.accent.primary : theme.stroke.tertiary}`,
            borderRadius: 8,
            padding: "4px 10px",
            fontSize: 11,
            cursor: "pointer",
            background: hub === o.id ? theme.fill.secondary : theme.bg.elevated,
            fontWeight: hub === o.id ? 600 : 400,
          }}
        >
          {o.label}
        </button>
      ))}
    </Row>
  );
}

function PhonePreview({
  title,
  subtitle,
  view,
  items,
}: {
  title: string;
  subtitle: string;
  view: View;
  items: { icon: string; title: string; sub: string }[];
}) {
  const theme = useHostTheme();
  const cream = theme.fill.quaternary;

  return (
    <Stack gap={10}>
      <H2 style={{ margin: 0, textAlign: "center" }}>
        {view === "proposed" ? "Usulan — list" : "Saat ini — grid 2 kolom"}
      </H2>
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
        <div style={{ padding: "12px 16px 8px", background: theme.fill.secondary }}>
          <Row gap={8} style={{ alignItems: "center" }}>
            <Text tone="tertiary" size="small">
              ←
            </Text>
            <Stack gap={2}>
              <Text weight="medium" style={{ fontSize: 16 }}>
                {title}
              </Text>
              <Text tone="secondary" size="small" style={{ fontSize: 11 }}>
                {subtitle}
              </Text>
            </Stack>
          </Row>
        </div>
        <div style={{ height: 1, background: theme.stroke.tertiary }} />
        <div style={{ padding: "8px 16px 16px" }}>
          {view === "proposed" && (
            <Stack gap={6} style={{ marginBottom: 10 }}>
              <Text tone="tertiary" size="small" style={{ fontSize: 9, textTransform: "uppercase" }}>
                Referensi parent hub
              </Text>
              <HubRowCard {...HUB_REF} />
            </Stack>
          )}
          {view === "proposed" ? (
            <Stack gap={10}>
              {items.map((item) => (
                <div key={item.title}>
                  <HubRowCard icon={item.icon} title={item.title} sub={item.sub} />
                </div>
              ))}
            </Stack>
          ) : (
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
              {items.map((item) => (
                <div key={item.title}>
                  <GridTile icon={item.icon} title={item.title} sub={item.sub} />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </Stack>
  );
}

function HubRowCard({ icon, title, sub }: { icon: string; title: string; sub: string }) {
  const theme = useHostTheme();
  return (
    <button
      type="button"
      style={{
        width: "100%",
        borderRadius: 16,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.bg.elevated,
        padding: "14px",
        textAlign: "left",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        gap: 12,
      }}
    >
      <IconBox icon={icon} size={40} />
      <Stack gap={4} style={{ flex: 1, minWidth: 0 }}>
        <Text size="small" weight="medium" style={{ fontSize: 13 }}>
          {title}
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: 11, lineHeight: 1.35 }}>
          {sub}
        </Text>
      </Stack>
      <Text tone="tertiary" style={{ fontSize: 18, flexShrink: 0 }}>
        ›
      </Text>
    </button>
  );
}

function GridTile({ icon, title, sub }: { icon: string; title: string; sub: string }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        borderRadius: 14,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.bg.elevated,
        padding: 10,
        display: "flex",
        alignItems: "center",
        gap: 8,
        minHeight: 72,
      }}
    >
      <IconBox icon={icon} size={36} />
      <Stack gap={2} style={{ minWidth: 0 }}>
        <Text size="small" weight="medium" style={{ fontSize: 11, lineHeight: 1.25 }}>
          {title}
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: 9 }}>
          {sub}
        </Text>
      </Stack>
    </div>
  );
}

function IconBox({ icon, size }: { icon: string; size: number }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: 10,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.fill.secondary,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: size * 0.38,
        fontWeight: 700,
        color: theme.accent.primary,
        flexShrink: 0,
      }}
    >
      {icon}
    </div>
  );
}

function SpecPanel({ view, hub }: { view: View; hub: Hub }) {
  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>Spesifikasi — {hub === "science" ? "Sains" : "Tema hidup"}</H2>

      <Callout tone={view === "proposed" ? "success" : "warning"}>
        <Text size="small" tone="secondary">
          {view === "proposed"
            ? "SliverList.separated — satu baris penuh per kategori, layout sama ExploreHubSectionCard (icon 40 + title + count + chevron)."
            : "SliverGrid 2 kolom — judul panjang membuat tinggi kotak tidak seragam dan teks terpotong."}
        </Text>
      </Callout>

      <Card>
        <CardHeader>Layout</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ SliverList.separated, gap 10 px</Text>
            <Text size="small" tone="secondary">+ Padding horizontal 16, top 0 (scaffold sudah kAppBodyTopInset)</Text>
            <Text size="small" tone="secondary">- Hapus SliverGrid 2 kolom</Text>
            <Text size="small" tone="secondary">+ Terapkan juga: Doa para nabi (sudah list, kartu diseragamkan)</Text>
          </Stack>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>ExploreCategoryCard = hub row</CardHeader>
        <CardBody>
          <Stack gap={6}>
            <Text size="small" tone="secondary">+ Radius 16, border 0.55, padding 14</Text>
            <Text size="small" tone="secondary">+ Row: icon 40 | titleSmall w600 | bodySmall count | chevron</Text>
            <Text size="small" tone="secondary">+ Subtitle boleh 2 baris (ellipsis) — lebar penuh</Text>
          </Stack>
        </CardBody>
      </Card>
    </Stack>
  );
}
