#version 460 core
#include <flutter/runtime_effect.glsl>

// Cylindrical Mushaf leaf turn.
//
// Drawn as one quad over the whole stage, on top of LIVE pages: the page that
// stays and the page revealed underneath are widgets below this quad. The
// shader only paints the moving leaf (front + back, sampled from snapshots)
// and the shadows it casts; everything else is transparent.
//
// Leaf space (u, v): u is the distance from the spine (hinge) towards the
// leaf's free edge, v the distance from the leaf's top. The leaf occupies
// u in [u0, u0 + W], v in [0, H]. Paper past the fold line (dist > 0) wraps
// around a cylinder of radius r and comes back flat on top, mirrored, which is
// where the back of the leaf (the next page) shows. Geometry is computed in
// Dart (PageCurlFrame); all uniforms are set every frame.

uniform vec2 uSize;      // stage size, logical px
uniform vec4 uLeaf;      // leaf front sheet rect: x, y, w, h (stage px)
uniform float uHinge;    // spine x (stage px)
uniform float uSide;     // +1 leaf lies left of the spine, -1 right
uniform vec2 uOrigin;    // a point on the fold line (leaf space)
uniform vec2 uNormal;    // unit normal of the fold line, towards the free edge
uniform float uRadius;   // cylinder radius (px)
uniform float uStrength; // shadow strength 0..1
uniform float uDark;     // 1 for a dark colour scheme

uniform sampler2D uFront; // current page (front of the leaf)
uniform sampler2D uBack;  // next page (back of the leaf)

out vec4 fragColor;

const float PI = 3.14159265358979;
const float AA = 0.6;

// Distance of q outside the leaf rect (0 inside).
float outside(vec2 q, float u0, float w, float h) {
  vec2 lo = vec2(u0, 0.0);
  vec2 hi = vec2(u0 + w, h);
  vec2 d = max(max(lo - q, q - hi), vec2(0.0));
  return length(d);
}

vec4 over(vec4 src, vec4 dst) {
  return src + dst * (1.0 - src.a);
}

void main() {
  vec2 frag = clamp(FlutterFragCoord().xy, vec2(0.0), uSize);
  float s = uSide >= 0.0 ? 1.0 : -1.0;
  float w = max(uLeaf.z, 1.0);
  float h = max(uLeaf.w, 1.0);
  float u0 = s > 0.0 ? uHinge - (uLeaf.x + w) : uLeaf.x - uHinge;
  vec2 p = vec2(s * (uHinge - frag.x), frag.y - uLeaf.y);
  vec2 n = uNormal;
  float r = max(uRadius, 0.0);
  float d = dot(p - uOrigin, n);
  float strength = clamp(uStrength, 0.0, 1.0);
  float blur = 6.0 + r * 1.2;

  vec4 acc = vec4(0.0);

  // 1. Shadow the curl casts ahead of it on the page underneath.
  if (d >= r && p.y >= 0.0 && p.y <= h && abs(p.x) <= u0 + w) {
    float t = clamp((d - r) / (blur * 1.6), 0.0, 1.0);
    acc = vec4(0.0, 0.0, 0.0, 0.30 * strength * (1.0 - t) * (1.0 - t));
  }

  // 2. Front of the leaf: flat part, then the underside rolling up.
  if (d < r) {
    vec2 qf = p;
    // The sheet starts to lift just before the fold.
    float shade = 1.0 - 0.07 * strength * smoothstep(-max(r * 2.0, 1.0), 0.0, min(d, 0.0));
    if (d >= 0.0 && r > 0.0) {
      float th = asin(clamp(d / r, 0.0, 1.0));
      qf = p + n * (r * th - d);
      shade *= 0.72 + 0.28 * cos(th);
    }
    float cov = 1.0 - smoothstep(0.0, AA, outside(qf, u0, w, h));
    if (cov > 0.0) {
      vec2 uv = vec2(s > 0.0 ? (u0 + w - qf.x) / w : (qf.x - u0) / w, qf.y / h);
      uv = clamp(uv, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
      uv.y = 1.0 - uv.y;
#endif
      vec4 tex = texture(uFront, uv);
      acc = over(vec4(tex.rgb * shade, 1.0) * cov, acc);
    }
  }

  // 3. Back of the leaf: over the cylinder top, then flat and mirrored.
  vec2 qb = vec2(-1.0e4);
  // Lying flat (landed, or just lifting off) the back must match the live
  // page exactly; it dims only while the leaf is in the air.
  float backShade = 1.0 - 0.07 * strength;
  if (d < 0.0) {
    qb = p + n * (PI * r - 2.0 * d);
  } else if (d < r && r > 0.0) {
    float th = asin(clamp(d / r, 0.0, 1.0));
    qb = p + n * (r * (PI - th) - d);
    float c = cos(th);
    // Darker where the sheet turns edge-on, a thin highlight at the crest.
    backShade *= 0.75 + 0.25 * c;
    float k = (th - 1.25) / 0.18;
    backShade += (0.10 + 0.05 * uDark) * exp(-k * k);
  }
  float outB = outside(qb, u0, w, h);
  // Soft shadow of the lifted leaf on whatever lies below it.
  if (outB > 0.0 && outB < blur && d < r) {
    float t = outB / blur;
    acc = over(vec4(0.0, 0.0, 0.0, 0.22 * strength * (1.0 - t) * (1.0 - t)), acc);
  }
  float covB = 1.0 - smoothstep(0.0, AA, outB);
  if (covB > 0.0) {
    vec2 uv = vec2(s > 0.0 ? (qb.x - u0) / w : (u0 + w - qb.x) / w, qb.y / h);
    uv = clamp(uv, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
    uv.y = 1.0 - uv.y;
#endif
    vec4 tex = texture(uBack, uv);
    acc = over(vec4(tex.rgb * backShade, 1.0) * covB, acc);
  }

  fragColor = acc;
}
