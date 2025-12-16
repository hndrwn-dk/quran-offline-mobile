# Mushaf Mode – Reading Comfort Specification

> Goal: Make Mushaf mode **comfortable to read for long sessions** in Flutter,  
> without chasing 1:1 printed Mushaf typography (which is not feasible in Flutter).

This document defines **three core decisions** that MUST be followed.

---

## 1. Ayah-Based Layout

### Decision
Use **ayah-based layout**, not word-based or line-based layout.

### Definition
- **One ayah = one visual block**
- Each ayah is rendered independently
- No manual word tokenization
- No greedy line breaking
- No post-processing line rebalance

### Why
- Eliminates orphan/dangling words completely
- Eliminates unstable line breaking when font size changes
- Eliminates ayah badge duplication bugs
- Matches how people mentally scan verses

### Implementation Concept
```dart
Column(
  children: [
    AyahRow(ayah: 1, text: "..."),
    AyahRow(ayah: 2, text: "..."),
    AyahRow(ayah: 3, text: "..."),
  ],
);
````

Each page:

* Is still page-based (using `index_pages.json`)
* Contains a **list of ayahs**, not a single large text block

### Rules

* Do NOT split ayah text manually
* Do NOT perform word-level measurement
* Do NOT attempt Arabic justification or kashida logic

---

## 2. Prefix Ayah Number

### Decision

Ayah number must be rendered as a **prefix**, not inline at the end of text.

### Why Inline Suffix Is Rejected

* Inline ayah markers cause:

  * layout instability
  * badge duplication
  * orphaned markers
  * baseline inconsistencies
* WidgetSpan/TextSpan mixing is fragile in Flutter

### Approved Pattern

Ayah number appears **before** ayah text.

### Implementation Concept

```dart
Row(
  textDirection: TextDirection.rtl,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    AyahBadge(ayahNumber),
    SizedBox(width: 8),
    Expanded(
      child: Text(ayahText),
    ),
  ],
);
```

### Ayah Badge Guidelines

* Stable size (e.g. 20–22 px)
* Not scaled dynamically with font size
* Simple ornament or outlined circle
* Ayah number taken directly from verse metadata (never calculated)

### Rules

* Ayah badge rendered **once per ayah**
* No WidgetSpan inside Arabic text
* No ayah numbering based on index or page counter

---

## 3. TextAlign.right + Comfortable Line Height

### Decision

Use **TextAlign.right**, not justify or center.

### Why Justify Is Rejected

* Flutter does NOT support Arabic justification with kashida
* Justified Arabic causes:

  * uneven spacing
  * orphan words
  * visual instability across devices

### Approved Text Settings

```dart
Text(
  ayahText,
  textAlign: TextAlign.right,
  style: TextStyle(
    fontFamily: 'UthmanicHafsV22',
    fontSize: 30, // default
    height: 1.7,
  ),
);
```

### Font Size Guidelines

| Size      | Usage                 |
| --------- | --------------------- |
| 26–28     | Small screens         |
| **30–32** | Default (recommended) |
| 34–36     | Large text            |
| >36       | Not recommended       |

### Line Height

* Recommended range: **1.7 – 1.9**
* Priority: eye comfort > line density

---

## Final Principles

* Reading comfort is more important than printed Mushaf fidelity
* Stability across font sizes is mandatory
* Avoid complex heuristics that fight Flutter’s text engine
* Mushaf mode should feel calm, predictable, and distraction-free

---

## Explicitly Out of Scope

The following are intentionally NOT supported:

* Exact printed Mushaf line breaks
* Arabic justification with kashida
* Pre-shaped glyph rendering like Quran.com
* Word-level line balancing

These require a custom text engine and are not feasible in Flutter.

---

## Acceptance Criteria

Mushaf mode is considered successful if:

* Ayahs are clearly separated
* Ayah numbers are always readable and consistent
* No orphan or dangling words appear
* Layout remains stable when font size changes
* Users can read for 10–15 minutes without eye fatigue

---

**This document is the final reference for Mushaf mode behavior.
Do not reintroduce word-based layout or inline ayah markers.**

```

