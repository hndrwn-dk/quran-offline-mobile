#!/usr/bin/env python3
"""
Build-time script: add tajweed-aware transliteration (tl_tj) to Quran JSON.

Reads s001.json ... s114.json from data/raw_qurancom_json/, runs each ayah's
Arabic (ar) through quran-phonemizer, romanizes to Latin, and writes the same
JSON with new fields tl_tj and optionally tl_ph to data/quran_with_tajweed_tl/.

Requirements:
  pip install quran-phonemizer

Usage:
  python scripts/build_tajweed_transliteration.py [--input DIR] [--output DIR] [--tl-ph] [--workers N]
"""

import argparse
import json
import logging
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# Default paths (relative to project root)
# -----------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT_DIR = PROJECT_ROOT / "data" / "raw_qurancom_json"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "data" / "quran_with_tajweed_tl"


def _ensure_phonemizer():
    """Import quran-phonemizer; raise clear error if not installed."""
    try:
        from quran_phonemizer import QuranPhonemizer
        return QuranPhonemizer
    except ImportError as e:
        logger.error(
            "quran-phonemizer not found. Install with: pip install quran-phonemizer"
        )
        raise SystemExit(1) from e


def _ensure_romanize():
    """Import romanize module from scripts dir."""
    scripts_dir = Path(__file__).resolve().parent
    if str(scripts_dir) not in sys.path:
        sys.path.insert(0, str(scripts_dir))
    from romanize import romanize_to_readable
    return romanize_to_readable


def process_ayah(
    ayah: Dict[str, Any],
    phonemizer: Any,
    romanize_fn: Any,
    include_tl_ph: bool,
) -> Tuple[Dict[str, Any], Optional[str], Optional[str]]:
    """
    Process one ayah: ar -> phonemes -> tl_tj. On failure return (original, err, None).

    Returns:
        (updated_ayah_dict, error_message, tl_ph_or_none)
    """
    ar = ayah.get("ar")
    tl_fallback = ayah.get("tl") or ""
    if not ar or not ar.strip():
        ayah_copy = dict(ayah)
        ayah_copy["tl_tj"] = tl_fallback
        if include_tl_ph:
            ayah_copy["tl_ph"] = ""
        return ayah_copy, None, "" if include_tl_ph else None
    try:
        # One ayah: use default stopping rules (waqf at end)
        phonemes = phonemizer.phonemize_text(ar.strip())
        if phonemes is None:
            phonemes = ""
        tl_tj = romanize_fn(phonemes.strip()) if phonemes else ""
        if not tl_tj.strip():
            tl_tj = tl_fallback
        ayah_copy = dict(ayah)
        ayah_copy["tl_tj"] = tl_tj
        if include_tl_ph:
            ayah_copy["tl_ph"] = phonemes if isinstance(phonemes, str) else str(phonemes)
        return ayah_copy, None, ayah_copy.get("tl_ph")
    except Exception as e:
        ayah_copy = dict(ayah)
        ayah_copy["tl_tj"] = tl_fallback
        if include_tl_ph:
            ayah_copy["tl_ph"] = ""
        return ayah_copy, str(e), None


def process_surah(
    surah_path: Path,
    phonemizer: Any,
    romanize_fn: Any,
    include_tl_ph: bool,
) -> Tuple[List[Dict[str, Any]], int, List[Tuple[int, int, str]]]:
    """
    Load one surah JSON, process all ayahs, return (verses, failure_count, errors).
    """
    try:
        raw = surah_path.read_text(encoding="utf-8")
    except Exception as e:
        logger.error("Failed to read %s: %s", surah_path, e)
        return [], 0, [(0, 0, str(e))]
    try:
        verses = json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON %s: %s", surah_path, e)
        return [], 0, [(0, 0, str(e))]
    if not isinstance(verses, list):
        logger.error("Expected list of verses in %s", surah_path)
        return [], 0, [(0, 0, "Expected list")]

    surah_id = verses[0].get("s", 0) if verses else 0
    out_verses = []
    failures = []
    for v in verses:
        ayah_no = v.get("a", 0)
        updated, err, _ = process_ayah(v, phonemizer, romanize_fn, include_tl_ph)
        out_verses.append(updated)
        if err:
            failures.append((surah_id, ayah_no, err))
    return out_verses, len(failures), failures


def run_single_surah(args: Tuple[Path, Path, bool]) -> Tuple[Path, List[Dict], int, List[Tuple[int, int, str]]]:
    """Worker: (surah_path, output_dir, include_tl_ph) -> (path, verses, n_fail, errors)."""
    surah_path, output_dir, include_tl_ph = args
    QuranPhonemizer = _ensure_phonemizer()
    romanize_fn = _ensure_romanize()
    qp = QuranPhonemizer()
    verses, n_fail, errors = process_surah(surah_path, qp, romanize_fn, include_tl_ph)
    out_path = output_dir / surah_path.name
    return surah_path, verses, n_fail, errors


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Add tl_tj (tajweed-aware transliteration) to Quran JSON files.",
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help="Input folder containing s001.json ... s114.json",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Output folder (same filenames, with tl_tj added)",
    )
    parser.add_argument(
        "--tl-ph",
        action="store_true",
        help="Also write tl_ph (raw phoneme string) for debug",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=1,
        help="Parallel workers (1 = sequential; >1 uses multiprocessing per surah)",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=None,
        help="Write summary report to this file (default: stdout + optional file)",
    )
    args = parser.parse_args()

    input_dir = args.input.resolve()
    output_dir = args.output.resolve()
    if not input_dir.is_dir():
        logger.error("Input directory does not exist: %s", input_dir)
        raise SystemExit(1)
    output_dir.mkdir(parents=True, exist_ok=True)

    _ensure_phonemizer()
    romanize_fn = _ensure_romanize()

    # Collect s001.json ... s114.json
    surah_files = []
    for i in range(1, 115):
        name = f"s{i:03d}.json"
        path = input_dir / name
        if path.exists():
            surah_files.append(path)
        else:
            logger.warning("Missing %s in %s", name, input_dir)
    if not surah_files:
        logger.error("No sXXX.json files found in %s", input_dir)
        raise SystemExit(1)
    logger.info("Processing %d surah files from %s", len(surah_files), input_dir)

    total_ayahs = 0
    total_failures = 0
    all_errors: List[Tuple[int, int, str]] = []
    sample_diffs: List[Tuple[int, int, str, str]] = []  # (s, a, tl, tl_tj)

    if args.workers <= 1:
        QuranPhonemizer = _ensure_phonemizer()
        qp = QuranPhonemizer()
        for surah_path in sorted(surah_files):
            verses, n_fail, errors = process_surah(
                surah_path, qp, romanize_fn, args.tl_ph
            )
            all_errors.extend(errors)
            total_failures += n_fail
            for v in verses:
                total_ayahs += 1
                if v.get("s") == 1 and v.get("a") in (1, 7):
                    sample_diffs.append((
                        v["s"],
                        v["a"],
                        (v.get("tl") or ""),
                        (v.get("tl_tj") or ""),
                    ))
            out_path = output_dir / surah_path.name
            out_path.write_text(
                json.dumps(verses, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            logger.info("Wrote %s (%d verses, %d failures)", out_path, len(verses), n_fail)
    else:
        try:
            from multiprocessing import Pool
        except ImportError:
            logger.warning("multiprocessing not available; using 1 worker")
            args.workers = 1
        if args.workers > 1:
            task_args = [
                (p, output_dir, args.tl_ph) for p in sorted(surah_files)
            ]
            with Pool(processes=min(args.workers, len(surah_files))) as pool:
                results = pool.map(run_single_surah, task_args)
            for surah_path, verses, n_fail, errors in results:
                all_errors.extend(errors)
                total_failures += n_fail
                for v in verses:
                    total_ayahs += 1
                    if v.get("s") == 1 and v.get("a") in (1, 7):
                        sample_diffs.append((
                            v["s"],
                            v["a"],
                            (v.get("tl") or ""),
                            (v.get("tl_tj") or ""),
                        ))
                out_path = output_dir / surah_path.name
                out_path.write_text(
                    json.dumps(verses, ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )
                logger.info("Wrote %s (%d verses, %d failures)", out_path, len(verses), n_fail)
        else:
            # Fallback when workers was forced to 1 (e.g. no multiprocessing)
            QuranPhonemizer = _ensure_phonemizer()
            qp = QuranPhonemizer()
            for surah_path in sorted(surah_files):
                verses, n_fail, errors = process_surah(
                    surah_path, qp, romanize_fn, args.tl_ph
                )
                all_errors.extend(errors)
                total_failures += n_fail
                for v in verses:
                    total_ayahs += 1
                    if v.get("s") == 1 and v.get("a") in (1, 7):
                        sample_diffs.append((
                            v["s"], v["a"],
                            (v.get("tl") or ""),
                            (v.get("tl_tj") or ""),
                        ))
                out_path = output_dir / surah_path.name
                out_path.write_text(
                    json.dumps(verses, ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )
                logger.info("Wrote %s (%d verses, %d failures)", out_path, len(verses), n_fail)

    # Report
    report_lines = [
        "Tajweed transliteration build report",
        "====================================",
        f"Input dir:  {input_dir}",
        f"Output dir: {output_dir}",
        f"Total ayahs processed: {total_ayahs}",
        f"Total failures (fallback to tl): {total_failures}",
        "",
    ]
    if all_errors:
        report_lines.append("Errors (surah:ayah message):")
        for s, a, msg in all_errors[:50]:
            report_lines.append(f"  {s}:{a} {msg}")
        if len(all_errors) > 50:
            report_lines.append(f"  ... and {len(all_errors) - 50} more")
        report_lines.append("")
    if sample_diffs:
        report_lines.append("Sample diffs (tl vs tl_tj) for 1:1 and 1:7:")
        for s, a, tl, tl_tj in sample_diffs[:5]:
            report_lines.append(f"  {s}:{a}")
            report_lines.append(f"    tl:    {tl[:80]!r}")
            report_lines.append(f"    tl_tj: {tl_tj[:80]!r}")
    report_text = "\n".join(report_lines)
    logger.info("\n%s", report_text)
    if args.report:
        args.report = Path(args.report)
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report_text, encoding="utf-8")
        logger.info("Report written to %s", args.report)

    if total_failures > 0:
        logger.warning("Completed with %d fallbacks (tl_tj = tl)", total_failures)
    else:
        logger.info("All ayahs processed successfully.")


if __name__ == "__main__":
    main()
