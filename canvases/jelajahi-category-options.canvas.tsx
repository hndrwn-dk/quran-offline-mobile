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
  categoryPaletteDark,
  categoryPaletteLight,
  useCanvasState,
  useHostTheme,
} from "cursor/canvas";

type Hub = "science" | "theme";
type Variant = "grid" | "list" | "tinted" | "hero" | "illustrated";
type TintKey = keyof typeof categoryPaletteLight;

type CategoryItem = {
  icon: string;
  title: string;
  sub: string;
  tint: TintKey;
  illus: "cosmos" | "bio" | "earth" | "physics" | "prayer" | "heart" | "calm" | "shield" | "compass";
};

const SCIENCE: CategoryItem[] = [
  { icon: "G", title: "Alam semesta", sub: "5 topik", tint: "cyan", illus: "cosmos" },
  { icon: "B", title: "Biologi", sub: "5 topik", tint: "green", illus: "bio" },
  { icon: "E", title: "Bumi & lingkungan", sub: "5 topik", tint: "yellow", illus: "earth" },
  { icon: "F", title: "Fisika & materi", sub: "4 topik", tint: "blue", illus: "physics" },
];

const THEMES: CategoryItem[] = [
  { icon: "A", title: "Ampun & tobat", sub: "7 doa", tint: "purple", illus: "prayer" },
  { icon: "I", title: "Iman & hati", sub: "4 doa", tint: "pink", illus: "heart" },
  { icon: "S", title: "Sabar & ketenangan", sub: "2 topik", tint: "cyan", illus: "calm" },
  { icon: "U", title: "Ujian & cemas", sub: "3 doa · 2 renungan", tint: "orange", illus: "earth" },
  { icon: "P", title: "Perlindungan", sub: "4 doa", tint: "blue", illus: "shield" },
  { icon: "R", title: "Rezeki & petunjuk", sub: "4 doa · 1 renungan", tint: "green", illus: "compass" },
];

const VARIANTS: { id: Variant; label: string; short: string }[] = [
  { id: "grid", label: "Grid 2 kolom (lama)", short: "Grid" },
  { id: "list", label: "List hub (implementasi)", short: "List" },
  { id: "tinted", label: "A — Tinted rows", short: "A" },
  { id: "hero", label: "B — Hero + list", short: "B" },
  { id: "illustrated", label: "C — Illustrated rows", short: "C" },
];

const DRIBBBLE_REFS = [
  { label: "Lazarev Matta categories", url: "https://dribbble.com/shots/22133095" },
  { label: "Ngajii Quran", url: "https://dribbble.com/shots/21068681" },
  { label: "Quranly themes", url: "https://dribbble.com/shots/21568426" },
  { label: "Green Healer nature", url: "https://dribbble.com/shots/24557119" },
  { label: "Jazakallah modules", url: "https://dribbble.com/shots/23667729" },
];

export default function JelajahiCategoryOptionsCanvas() {
  const [hub, setHub] = useCanvasState<Hub>("hub", "science");
  const [variant, setVariant] = useCanvasState<Variant>("variant", "tinted");

  const items = hub === "science" ? SCIENCE : THEMES;
  const hubTitle = hub === "science" ? "Sains" : "Tema hidup";
  const hubSub =
    hub === "science"
      ? "Al-Qur'an dan alam semesta"
      : "Doa, zikir, dan renungan ayat";

  const activeMeta = VARIANTS.find((v) => v.id === variant)!;

  return (
    <Stack gap={28} style={{ padding: 24, maxWidth: 1200, margin: "0 auto" }}>
      <Stack gap={8}>
        <H1 style={{ margin: 0 }}>Jelajahi child — semua opsi desain</H1>
        <Text tone="secondary">
          Perbandingan 5 pola untuk menu kategori Sains &amp; Tema hidup. Inspirasi Dribbble:
          tinted rows (Lazarev), hero discover (Quranly), ilustrasi alam (Green Healer).
        </Text>
      </Stack>

      <Row gap={8} style={{ flexWrap: "wrap", alignItems: "center" }}>
        <Text size="small" tone="secondary">
          Layar:
        </Text>
        <Pill active={hub === "science"} onClick={() => setHub("science")}>
          Sains
        </Pill>
        <Pill active={hub === "theme"} onClick={() => setHub("theme")}>
          Tema hidup
        </Pill>
      </Row>

      <Row gap={6} style={{ flexWrap: "wrap" }}>
        {VARIANTS.map((v) => (
          <span key={v.id}>
            <Pill active={variant === v.id} onClick={() => setVariant(v.id)}>
              {v.label}
            </Pill>
          </span>
        ))}
      </Row>

      <Grid columns={2} gap={24} style={{ alignItems: "start" }}>
        <PhoneFrame label={`${activeMeta.label} — ${hubTitle}`} tall={hub === "theme"}>
          <ScreenHeader title={hubTitle} subtitle={hubSub} />
          <CategoryBody variant={variant} items={items} />
        </PhoneFrame>
        <SpecPanel variant={variant} hub={hub} />
      </Grid>

      <Stack gap={12}>
        <H2 style={{ margin: 0 }}>Perbandingan cepat — {hubTitle}</H2>
        <Text tone="secondary" size="small">
          Lima varian sejajar; klik pill di atas untuk detail + spesifikasi.
        </Text>
        <Grid columns={5} gap={12}>
          {VARIANTS.map((v) => (
            <div key={v.id}>
              <MiniPhone
                label={v.short}
                active={variant === v.id}
                onClick={() => setVariant(v.id)}
              >
                <ScreenHeader title={hubTitle} subtitle={hubSub} compact />
                <CategoryBody variant={v.id} items={items} compact />
              </MiniPhone>
            </div>
          ))}
        </Grid>
      </Stack>

      <Card>
        <CardHeader>Referensi Dribbble</CardHeader>
        <CardBody>
          <Stack gap={6}>
            {DRIBBBLE_REFS.map((r) => (
              <div key={r.url}>
                <Row gap={8} style={{ alignItems: "center" }}>
                  <Text size="small" tone="secondary">
                    {r.label}
                  </Text>
                  <Text size="small" tone="tertiary" style={{ fontFamily: "monospace", fontSize: 10 }}>
                    {r.url}
                  </Text>
                </Row>
              </div>
            ))}
          </Stack>
        </CardBody>
      </Card>
    </Stack>
  );
}

function PhoneFrame({
  label,
  tall,
  children,
}: {
  label: string;
  tall?: boolean;
  children?: unknown;
}) {
  const theme = useHostTheme();
  return (
    <Stack gap={10}>
      <H2 style={{ margin: 0, textAlign: "center", fontSize: 14 }}>{label}</H2>
      <div
        style={{
          width: 320,
          height: tall ? 620 : 520,
          margin: "0 auto",
          borderRadius: 24,
          border: `1px solid ${theme.stroke.secondary}`,
          overflow: "hidden",
          background: theme.fill.quaternary,
          display: "flex",
          flexDirection: "column",
        }}
      >
        {children}
      </div>
    </Stack>
  );
}

function MiniPhone({
  label,
  active,
  onClick,
  children,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
  children?: unknown;
}) {
  const theme = useHostTheme();
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        border: `2px solid ${active ? theme.accent.primary : theme.stroke.tertiary}`,
        borderRadius: 12,
        padding: 0,
        background: theme.bg.elevated,
        cursor: "pointer",
        textAlign: "left",
        overflow: "hidden",
      }}
    >
      <Text
        size="small"
        weight="medium"
        style={{
          display: "block",
          textAlign: "center",
          padding: "6px 0",
          fontSize: 10,
          background: active ? theme.fill.secondary : theme.fill.tertiary,
        }}
      >
        {label}
      </Text>
      <div style={{ height: 200, overflow: "hidden", transform: "scale(0.55)", transformOrigin: "top left", width: 182 }}>
        <div style={{ width: 320 }}>{children}</div>
      </div>
    </button>
  );
}

function ScreenHeader({
  title,
  subtitle,
  compact,
}: {
  title: string;
  subtitle: string;
  compact?: boolean;
}) {
  const theme = useHostTheme();
  return (
    <>
      <div style={{ padding: compact ? "8px 12px 6px" : "12px 16px 8px", background: theme.fill.secondary }}>
        <Row gap={8} style={{ alignItems: "center" }}>
          <Text tone="tertiary" size="small" style={{ fontSize: compact ? 10 : 12 }}>
            ←
          </Text>
          <Stack gap={2}>
            <Text weight="medium" style={{ fontSize: compact ? 13 : 16 }}>
              {title}
            </Text>
            <Text tone="secondary" size="small" style={{ fontSize: compact ? 9 : 11 }}>
              {subtitle}
            </Text>
          </Stack>
        </Row>
      </div>
      <div style={{ height: 1, background: theme.stroke.tertiary }} />
    </>
  );
}

function CategoryBody({
  variant,
  items,
  compact,
}: {
  variant: Variant;
  items: CategoryItem[];
  compact?: boolean;
}) {
  const pad = compact ? 8 : 12;
  const gap = compact ? 6 : 10;

  return (
    <div style={{ flex: 1, overflow: "auto", padding: `${pad}px ${pad + 4}px ${pad + 8}px` }}>
      {variant === "grid" && (
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap }}>
          {items.map((item) => (
            <div key={item.title}>
              <GridTile item={item} compact={compact} />
            </div>
          ))}
        </div>
      )}
      {variant === "list" && (
        <Stack gap={gap}>
          {items.map((item) => (
            <div key={item.title}>
              <HubRow item={item} compact={compact} />
            </div>
          ))}
        </Stack>
      )}
      {variant === "tinted" && (
        <Stack gap={gap}>
          {items.map((item) => (
            <div key={item.title}>
              <TintedRow item={item} compact={compact} />
            </div>
          ))}
        </Stack>
      )}
      {variant === "hero" && (
        <Stack gap={gap}>
          <HeroCard item={items[0]} compact={compact} />
          {items.slice(1).map((item) => (
            <div key={item.title}>
              <HubRow item={item} compact={compact} />
            </div>
          ))}
        </Stack>
      )}
      {variant === "illustrated" && (
        <Stack gap={gap}>
          {items.map((item) => (
            <div key={item.title}>
              <IllustratedRow item={item} compact={compact} />
            </div>
          ))}
        </Stack>
      )}
    </div>
  );
}

function GridTile({ item, compact }: { item: CategoryItem; compact?: boolean }) {
  const theme = useHostTheme();
  return (
    <div
      style={{
        borderRadius: 14,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.bg.elevated,
        padding: compact ? 8 : 10,
        display: "flex",
        alignItems: "center",
        gap: 8,
        minHeight: compact ? 56 : 72,
      }}
    >
      <IconBox icon={item.icon} size={compact ? 28 : 36} />
      <Stack gap={2} style={{ minWidth: 0 }}>
        <Text size="small" weight="medium" style={{ fontSize: compact ? 9 : 11, lineHeight: 1.25 }}>
          {item.title}
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: compact ? 8 : 9 }}>
          {item.sub}
        </Text>
      </Stack>
    </div>
  );
}

function HubRow({ item, compact }: { item: CategoryItem; compact?: boolean }) {
  const theme = useHostTheme();
  return (
    <button
      type="button"
      style={{
        width: "100%",
        borderRadius: 16,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.bg.elevated,
        padding: compact ? "10px 10px" : "14px",
        textAlign: "left",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        gap: compact ? 8 : 12,
      }}
    >
      <IconBox icon={item.icon} size={compact ? 32 : 40} />
      <Stack gap={compact ? 2 : 4} style={{ flex: 1, minWidth: 0 }}>
        <Text size="small" weight="medium" style={{ fontSize: compact ? 10 : 13 }}>
          {item.title}
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: compact ? 8 : 11, lineHeight: 1.35 }}>
          {item.sub}
        </Text>
      </Stack>
      <Text tone="tertiary" style={{ fontSize: compact ? 14 : 18, flexShrink: 0 }}>
        ›
      </Text>
    </button>
  );
}

function TintedRow({ item, compact }: { item: CategoryItem; compact?: boolean }) {
  const theme = useHostTheme();
  const palette = theme.kind === "light" ? categoryPaletteLight : categoryPaletteDark;
  const accent = palette[item.tint];

  return (
    <button
      type="button"
      style={{
        width: "100%",
        borderRadius: 16,
        border: `1px solid ${theme.stroke.tertiary}`,
        borderLeft: `4px solid ${accent}`,
        background: theme.bg.elevated,
        padding: compact ? "10px 10px 10px 8px" : "14px 14px 14px 10px",
        textAlign: "left",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        gap: compact ? 8 : 12,
      }}
    >
      <div
        style={{
          width: compact ? 32 : 40,
          height: compact ? 32 : 40,
          borderRadius: 10,
          background: theme.fill.secondary,
          border: `1px solid ${theme.stroke.tertiary}`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: accent,
          fontWeight: 700,
          fontSize: compact ? 12 : 15,
          flexShrink: 0,
        }}
      >
        {item.icon}
      </div>
      <Stack gap={compact ? 2 : 4} style={{ flex: 1, minWidth: 0 }}>
        <Text size="small" weight="medium" style={{ fontSize: compact ? 10 : 13 }}>
          {item.title}
        </Text>
        <Row gap={6} style={{ alignItems: "center", flexWrap: "wrap" }}>
          <span
            style={{
              fontSize: compact ? 7 : 9,
              fontWeight: 600,
              padding: "2px 6px",
              borderRadius: 6,
              background: theme.fill.tertiary,
              color: accent,
            }}
          >
            {item.sub}
          </span>
        </Row>
      </Stack>
      <Text tone="tertiary" style={{ fontSize: compact ? 14 : 18, flexShrink: 0 }}>
        ›
      </Text>
    </button>
  );
}

function HeroCard({ item, compact }: { item: CategoryItem; compact?: boolean }) {
  const theme = useHostTheme();
  const palette = theme.kind === "light" ? categoryPaletteLight : categoryPaletteDark;
  const accent = palette[item.tint];

  return (
    <button
      type="button"
      style={{
        width: "100%",
        borderRadius: 16,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.fill.secondary,
        padding: compact ? 12 : 16,
        textAlign: "left",
        cursor: "pointer",
        minHeight: compact ? 88 : 120,
        display: "flex",
        flexDirection: "column",
        justifyContent: "space-between",
      }}
    >
      <Row style={{ justifyContent: "space-between", alignItems: "flex-start" }}>
        <IconBox icon={item.icon} size={compact ? 36 : 48} accent={accent} />
        <Text
          size="small"
          style={{
            fontSize: compact ? 7 : 9,
            fontWeight: 600,
            padding: "3px 8px",
            borderRadius: 8,
            background: theme.bg.elevated,
            color: accent,
            border: `1px solid ${theme.stroke.tertiary}`,
          }}
        >
          Unggulan
        </Text>
      </Row>
      <Stack gap={4} style={{ marginTop: compact ? 8 : 12 }}>
        <Text weight="medium" style={{ fontSize: compact ? 12 : 15 }}>
          {item.title}
        </Text>
        <Text tone="secondary" size="small" style={{ fontSize: compact ? 9 : 11 }}>
          {item.sub} — ketuk untuk lihat semua topik
        </Text>
      </Stack>
    </button>
  );
}

function IllustratedRow({ item, compact }: { item: CategoryItem; compact?: boolean }) {
  const theme = useHostTheme();
  const palette = theme.kind === "light" ? categoryPaletteLight : categoryPaletteDark;
  const accent = palette[item.tint];

  return (
    <button
      type="button"
      style={{
        width: "100%",
        borderRadius: 16,
        border: `1px solid ${theme.stroke.tertiary}`,
        background: theme.bg.elevated,
        padding: 0,
        textAlign: "left",
        cursor: "pointer",
        display: "flex",
        alignItems: "stretch",
        overflow: "hidden",
        minHeight: compact ? 64 : 80,
      }}
    >
      <div style={{ flex: 1, padding: compact ? "10px 8px 10px 10px" : "14px 12px 14px 14px" }}>
        <Row gap={compact ? 8 : 10} style={{ alignItems: "center" }}>
          <IconBox icon={item.icon} size={compact ? 28 : 36} accent={accent} />
          <Stack gap={2} style={{ flex: 1, minWidth: 0 }}>
            <Text size="small" weight="medium" style={{ fontSize: compact ? 10 : 12 }}>
              {item.title}
            </Text>
            <Text tone="secondary" size="small" style={{ fontSize: compact ? 8 : 10 }}>
              {item.sub}
            </Text>
          </Stack>
          <Text tone="tertiary" style={{ fontSize: compact ? 14 : 16, flexShrink: 0 }}>
            ›
          </Text>
        </Row>
      </div>
      <div
        style={{
          width: compact ? 52 : 72,
          background: theme.fill.tertiary,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
        }}
      >
        <MiniIllustration kind={item.illus} color={accent} size={compact ? 40 : 56} />
      </div>
    </button>
  );
}

function MiniIllustration({
  kind,
  color,
  size,
}: {
  kind: CategoryItem["illus"];
  color: string;
  size: number;
}) {
  const r = size * 0.12;
  const cx = size / 2;
  const cy = size / 2;

  if (kind === "cosmos") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={cx} cy={cy} r={size * 0.28} fill="none" stroke={color} strokeWidth={1.5} />
        <circle cx={cx + size * 0.14} cy={cy - size * 0.1} r={r} fill={color} />
        <circle cx={cx - size * 0.18} cy={cy + size * 0.12} r={r * 0.7} fill={color} opacity={0.6} />
      </svg>
    );
  }
  if (kind === "bio") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <ellipse cx={cx} cy={cy} rx={size * 0.22} ry={size * 0.14} fill="none" stroke={color} strokeWidth={1.5} />
        <circle cx={cx} cy={cy} r={r * 1.2} fill={color} opacity={0.5} />
      </svg>
    );
  }
  if (kind === "earth") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <path
          d={`M${size * 0.2} ${cy} Q${cx} ${size * 0.25} ${size * 0.8} ${cy} Q${cx} ${size * 0.75} ${size * 0.2} ${cy}`}
          fill="none"
          stroke={color}
          strokeWidth={1.5}
        />
        <circle cx={cx} cy={cy} r={size * 0.08} fill={color} />
      </svg>
    );
  }
  if (kind === "physics") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <rect x={cx - size * 0.12} y={size * 0.35} width={size * 0.24} height={size * 0.3} rx={4} fill="none" stroke={color} strokeWidth={1.5} />
        <line x1={cx} y1={size * 0.28} x2={cx} y2={size * 0.35} stroke={color} strokeWidth={1.5} />
      </svg>
    );
  }
  if (kind === "prayer") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={cx} cy={size * 0.32} r={r * 1.4} fill={color} opacity={0.7} />
        <path d={`M${cx} ${size * 0.42} L${cx} ${size * 0.72} M${cx - size * 0.12} ${size * 0.55} L${cx + size * 0.12} ${size * 0.55}`} stroke={color} strokeWidth={1.5} />
      </svg>
    );
  }
  if (kind === "heart") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <path
          d={`M${cx} ${size * 0.65} C${size * 0.15} ${size * 0.45} ${size * 0.15} ${size * 0.28} ${cx} ${size * 0.38} C${size * 0.85} ${size * 0.28} ${size * 0.85} ${size * 0.45} ${cx} ${size * 0.65}`}
          fill={color}
          opacity={0.65}
        />
      </svg>
    );
  }
  if (kind === "shield") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <path
          d={`M${cx} ${size * 0.22} L${size * 0.72} ${size * 0.32} L${size * 0.72} ${size * 0.52} C${size * 0.72} ${size * 0.68} ${cx} ${size * 0.78} ${cx} ${size * 0.78} C${cx} ${size * 0.78} ${size * 0.28} ${size * 0.68} ${size * 0.28} ${size * 0.52} L${size * 0.28} ${size * 0.32} Z`}
          fill="none"
          stroke={color}
          strokeWidth={1.5}
        />
      </svg>
    );
  }
  if (kind === "compass") {
    return (
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={cx} cy={cy} r={size * 0.26} fill="none" stroke={color} strokeWidth={1.5} />
        <polygon points={`${cx},${size * 0.28} ${size * 0.58},${cy} ${cx},${size * 0.72} ${size * 0.42},${cy}`} fill={color} opacity={0.55} />
      </svg>
    );
  }
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <circle cx={cx} cy={cy} r={size * 0.2} fill="none" stroke={color} strokeWidth={1.5} />
    </svg>
  );
}

function IconBox({
  icon,
  size,
  accent,
}: {
  icon: string;
  size: number;
  accent?: string;
}) {
  const theme = useHostTheme();
  const color = accent ?? theme.accent.primary;
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
        color,
        flexShrink: 0,
      }}
    >
      {icon}
    </div>
  );
}

function SpecPanel({ variant, hub }: { variant: Variant; hub: Hub }) {
  const meta = VARIANTS.find((v) => v.id === variant)!;

  const specs: Record<Variant, string[]> = {
    grid: [
      "SliverGrid 2 kolom — status: diganti",
      "Judul panjang memotong / tinggi kotak tidak seragam",
      "Tidak direkomendasikan untuk child menu",
    ],
    list: [
      "SliverList.separated, gap 10 px — sudah di Flutter",
      "ExploreCategoryCard = ExploreHubSectionCard row",
      "Aman untuk judul panjang; terasa datar tanpa aksen",
    ],
    tinted: [
      "Baris penuh + border kiri 4 px warna kategori",
      "Count sebagai pill kecil berwarna",
      "Icon box pakai accent kategori (bukan primary global)",
      "Inspirasi: Lazarev Matta, Ngajii",
      "Implementasi: tint map per categoryKey di explore_icons",
    ],
    hero: [
      "Kartu hero pertama (featured) + list kompak di bawah",
      "Hero: fill secondary, badge Unggulan, icon 48 px",
      "Cocok Sains (4 item); Tema hidup bisa skip hero",
      "Inspirasi: Quranly theme discovery, Volpis Discover",
    ],
    illustrated: [
      "Baris penuh + panel ilustrasi SVG kanan (72 px)",
      "Asset ringan per kategori — bisa PNG bundled nanti",
      "Kuat untuk Sains; effort asset untuk 11 tema",
      "Inspirasi: Green Healer nature concept",
    ],
  };

  const rec =
    hub === "science"
      ? "Rekomendasi Sains: A (tinted) atau B (hero Alam semesta)"
      : "Rekomendasi Tema hidup: A (tinted) — 9+ item, hero kurang ideal";

  return (
    <Stack gap={14}>
      <H2 style={{ margin: 0 }}>{meta.label}</H2>
      <Callout tone={variant === "grid" ? "warning" : variant === "list" ? "info" : "success"}>
        <Text size="small" tone="secondary">
          {rec}
        </Text>
      </Callout>
      <Card>
        <CardHeader>Spesifikasi</CardHeader>
        <CardBody>
          <Stack gap={6}>
            {specs[variant].map((line, i) => (
              <div key={i}>
                <Text size="small" tone="secondary">
                  {line}
                </Text>
              </div>
            ))}
          </Stack>
        </CardBody>
      </Card>
      <Card>
        <CardHeader>Flutter (jika dipilih)</CardHeader>
        <CardBody>
          <Stack gap={4}>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              explore_hub_section_card.dart
            </Text>
            <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
              dua_screen.dart — _ScienceCategoryGrid, _LifeSituationCategoryGrid
            </Text>
            {variant === "tinted" && (
              <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
                + explore_category_tints.dart (map key → Color)
              </Text>
            )}
            {variant === "hero" && (
              <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
                + ExploreFeaturedCategoryCard widget
              </Text>
            )}
            {variant === "illustrated" && (
              <Text size="small" tone="secondary" style={{ fontFamily: "monospace" }}>
                + assets/icon/explore/category_illus/*.png
              </Text>
            )}
          </Stack>
        </CardBody>
      </Card>
    </Stack>
  );
}
