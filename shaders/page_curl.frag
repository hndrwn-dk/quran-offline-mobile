#version 460 core
#include <flutter/runtime_effect.glsl>

// Cylindrical Mushaf leaf turn (iBooks-like).
//
// The painter draws the paper background, the pages underneath and the gutter
// shade first, then draws this shader as one quad over the two-page stage. The
// shader is transparent outside the lifted leaf, so the live pages below show
// through without gaps.
//
// All coordinates are logical pixels in the shader's local space (the painter
// translates the canvas so the stage rect starts at 0,0). Textures were captured
// at the device pixel ratio; UVs are normalized, so the shader is DPR agnostic.

uniform vec2 uSize;       // stage size, logical px
uniform vec4 uLeaf;       // lifted page rect: x, y, width, height
uniform vec4 uLanded;     // page the leaf lands on
uniform vec4 uFrontRect;  // current projected front (empty once edge-on)
uniform vec4 uBackRect;   // current projected back (empty before edge-on)
uniform float uProgress;  // 0 flat .. 1 landed
uniform float uForward;   // 1 forward, 0 backward
uniform float uSpread;    // 1 spread, 0 single page
uniform float uDiag;      // max fold slope offset from the finger's y, px
uniform float uRadius;    // cylinder radius, logical px
uniform float uDpr;       // device pixel ratio (antialias width)
uniform vec4 uPaper;      // opaque paper colour behind captured textures

uniform sampler2D uFrontTex; // page printed on the front of the leaf
uniform sampler2D uBackTex;  // page printed on the back (next page)

out vec4 fragColor;

const float PI = 3.14159265358979323846;

float bandLight(float t) {
  // Slightly darker where the paper rolls away, catching light at the crest.
  return 0.80 + 0.20 * smoothstep(0.0, 1.0, t) + 0.06 * sin(PI * t);
}

// Snapshots are opaque in the app (the page boundary wraps a ColoredBox), but
// composite over the paper anyway: a transparent capture must never turn the
// leaf black. Kept inline: SkSL cannot translate a sampler parameter.

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float p = clamp(uProgress, 0.0, 1.0);
  float strength = sin(PI * p);
  bool forward = uForward > 0.5;
  bool frontPhase = p <= 0.5;

  float pageW = max(uLeaf.z, 1.0);
  float pageH = max(uLeaf.w, 1.0);
  float leafLeft = uLeaf.x;
  float leafRight = uLeaf.x + pageW;
  float leafTop = uLeaf.y;
  float leafBottom = uLeaf.y + pageH;
  float radius = max(uRadius, 1.0);
  // No curl at rest or when the leaf lies flat on the target page.
  float curlW = radius * strength * (0.55 + 0.45 * strength);
  float shadowW = radius * 2.8;
  float aa = max(1.0 / max(uDpr, 1.0), 0.75);

  // Diagonal fold: the finger's y lifts one corner first.
  float dy = (frag.y - (leafTop + pageH * 0.5)) / max(pageH * 0.5, 1.0);
  float diagSign = (forward == frontPhase) ? 1.0 : -1.0;
  float diag = uDiag * clamp(dy, -1.0, 1.0) * diagSign;

  float baseEdge;
  float minEdge;
  float maxEdge;
  if (frontPhase) {
    minEdge = leafLeft;
    maxEdge = leafRight;
    if (forward) {
      baseEdge = uFrontRect.z <= 0.5 ? leafRight : uFrontRect.x;
    } else {
      baseEdge = uFrontRect.z <= 0.5 ? leafLeft : (uFrontRect.x + uFrontRect.z);
    }
  } else {
    minEdge = uLanded.x;
    maxEdge = uLanded.x + uLanded.z;
    if (forward) {
      baseEdge =
          uBackRect.z <= 0.5 ? uLanded.x : (uBackRect.x + uBackRect.z);
    } else {
      baseEdge = uBackRect.z <= 0.5 ? (uLanded.x + uLanded.z) : uBackRect.x;
    }
  }
  float edge = clamp(baseEdge + diag, minEdge, maxEdge);

  // Which outer side of the leaf band faces the page underneath.
  float belowSign = (frontPhase == forward) ? -1.0 : 1.0;
  float outerEdge = edge + belowSign * curlW;

  bool inLeafRows = frag.y >= leafTop - aa && frag.y <= leafBottom + aa;
  bool inFront = false;
  bool inBack = false;
  if (inLeafRows) {
    if (frontPhase) {
      inFront = forward
          ? (frag.x >= edge - aa && frag.x <= leafRight + aa)
          : (frag.x <= edge + aa && frag.x >= leafLeft - aa);
    } else {
      inBack = forward
          ? (frag.x >= uLanded.x - aa && frag.x <= edge + aa)
          : (frag.x <= uLanded.x + uLanded.z + aa && frag.x >= edge - aa);
    }
  }

  bool inCurl = false;
  if (inLeafRows && curlW > 0.5) {
    if (frontPhase) {
      inCurl = forward
          ? (frag.x >= edge - curlW - aa && frag.x < edge + aa)
          : (frag.x > edge - aa && frag.x <= edge + curlW + aa);
    } else {
      inCurl = forward
          ? (frag.x > edge - aa && frag.x <= edge + curlW + aa)
          : (frag.x >= edge - curlW - aa && frag.x < edge + aa);
    }
  }

  // Soft shadow the lifted paper casts on the page underneath, following the
  // fold line. Output premultiplied black so srcOver darkens the live page.
  float shadow = 0.0;
  if (inLeafRows && !inFront && !inBack && !inCurl) {
    float sd = belowSign * (frag.x - outerEdge);
    if (sd > 0.0 && sd < shadowW) {
      float t = 1.0 - sd / shadowW;
      shadow = 0.34 * strength * t * t;
      // Single pages have no facing page to catch the shadow; keep it soft.
      shadow *= mix(1.0, 0.8, uSpread > 0.5 ? 0.0 : 1.0);
    }
  }

  if (inFront) {
    float denom = forward
        ? max(leafRight - edge, 1.0)
        : max(edge - leafLeft, 1.0);
    float u = forward
        ? (frag.x - edge) / denom
        : (frag.x - leafLeft) / denom;
    float v = clamp((frag.y - leafTop) / pageH, 0.0, 1.0);
    vec4 texel =
        texture(uFrontTex, clamp(vec2(clamp(u, 0.0, 1.0), v), vec2(0.001), vec2(0.999)));
    vec3 color = texel.rgb + uPaper.rgb * (1.0 - texel.a);

    // The sheet bends away from the viewer at the free edge: a crease shade
    // plus a thin caught highlight.
    float d = forward ? (frag.x - edge) : (edge - frag.x);
    float crease = 1.0 - smoothstep(0.0, radius * 1.7, max(d, 0.0));
    color *= 1.0 - 0.34 * strength * crease;
    color += vec3(0.06) * strength * (1.0 - smoothstep(0.0, aa * 2.0, max(d, 0.0)));
    fragColor = vec4(color, 1.0);
    return;
  }

  if (inBack) {
    float denom = forward
        ? max(edge - uLanded.x, 1.0)
        : max(uLanded.x + uLanded.z - edge, 1.0);
    float u = forward
        ? (frag.x - uLanded.x) / denom
        : (frag.x - edge) / denom;
    float v = clamp((frag.y - leafTop) / pageH, 0.0, 1.0);
    vec4 texel = texture(
        uBackTex, clamp(vec2(clamp(u, 0.0, 1.0), v), vec2(0.001), vec2(0.999)));
    vec3 color = texel.rgb + uPaper.rgb * (1.0 - texel.a);
    // The landing leaf catches less light as it flattens out on the page.
    color *= 0.94 + 0.06 * (1.0 - strength);
    fragColor = vec4(color, 1.0);
    return;
  }

  if (inCurl) {
    // The curled strip shows the other side of the sheet. Work out how much of
    // the page surface the strip spans (in UV units).
    float bandPaper = clamp(curlW / pageW, 0.0, 0.45);
    float t;
    float u;
    bool showBack = frontPhase;
    if (frontPhase) {
      if (forward) {
        t = (frag.x - (edge - curlW)) / curlW;
        u = 1.0 - clamp(t, 0.0, 1.0) * bandPaper;
      } else {
        t = (frag.x - edge) / curlW;
        u = (1.0 - clamp(t, 0.0, 1.0)) * bandPaper;
      }
    } else {
      if (forward) {
        t = (frag.x - edge) / curlW;
        u = clamp(t, 0.0, 1.0) * bandPaper;
      } else {
        t = (edge - frag.x) / curlW;
        u = 1.0 - clamp(t, 0.0, 1.0) * bandPaper;
      }
    }
    float v = clamp((frag.y - leafTop) / pageH, 0.0, 1.0);
    vec2 bandUv =
        clamp(vec2(clamp(u, 0.0, 1.0), v), vec2(0.001), vec2(0.999));
    vec4 texel = showBack
        ? texture(uBackTex, bandUv)
        : texture(uFrontTex, bandUv);
    vec3 color = texel.rgb + uPaper.rgb * (1.0 - texel.a);
    // Lighting falloff across the curve.
    color *= bandLight(clamp(t, 0.0, 1.0));
    fragColor = vec4(color, 1.0);
    return;
  }

  if (shadow > 0.001) {
    fragColor = vec4(0.0, 0.0, 0.0, shadow);
    return;
  }
  fragColor = vec4(0.0);
}
