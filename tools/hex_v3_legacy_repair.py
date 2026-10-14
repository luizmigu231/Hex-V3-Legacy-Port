#!/usr/bin/env python3
"""Repair a converted Hex V3 -> VS Impostor: Legacy Mobile port, including Ram (2026) audio and labels.

Safe default: analyse only. Pass --apply to write changes.

Termux example:
  python "$HOME/storage/downloads/hex_v3_legacy_repair.py" \
    --source "$HOME/Hex-V3" \
    --output "/storage/emulated/0/.FNFTools/HEX-PORT" \
    --dry-run

After checking the report, repeat with --apply to make changes.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Any, Iterable

VERSION = "2026-10-13-r12"
CHART_NAME = re.compile(r"^(normal|easy|hard)\.json$", re.IGNORECASE)
ADD_CALL = re.compile(r"(?:(?:[A-Za-z_]\w*\s*\.\s*)*)add\(\s*([A-Za-z_]\w*)\s*\)")
NUMERIC_Z_ASSIGN = re.compile(r"^(\s*)([A-Za-z_]\w*)\s*\.\s*zIndex\s*=\s*(-?\d+(?:\.\d+)?)\s*;?(\s*(?://.*)?)$")
IDENTIFIER = re.compile(r"^[A-Za-z_]\w*$")

FRONT_HINTS = (
    "foreground", "frontoverlay", "frontlayer", "frontwall", "frontlight", "front", "overlay", "curtain",
    "stagecurtains", "vignette", "coverlayer", "screenflash", "fullscreen",
    "overcharacter", "abovepers", "frontmask", "blackoverlay", "whiteoverlay",
)
BACK_HINTS = (
    "background", "backdrop", "stageback", "backwall", "bg", "sky", "cloud",
    "starfield", "stars", "moon", "planet", "farbg", "horizon", "distant",
    "mountain", "mountains", "backdrop", "oceanbg", "citybg",
)
CHARACTER_NAMES = {
    "dad", "gf", "boyfriend", "bf", "opponent", "girlfriend", "pet",
    "dadgroup", "g fgroup", "boyfriendgroup", "player", "character",
    "secondopp", "secondopponent",
}


def slug(value: Any) -> str:
    return re.sub(r"[^a-z0-9]", "", str(value or "").lower())


def base_song_slug(value: Any) -> str:
    """Normalize common Hex chart variants such as (new), (erect), and (2026)."""
    value_slug = slug(value)
    # Strip one or more known suffixes, but do not strip "remix" if it is part of
    # a real source folder unless another exact match has already been preferred.
    changed = True
    while changed:
        changed = False
        for suffix in ("erect", "new", "2026", "normal", "easy", "hard"):
            if value_slug.endswith(suffix) and len(value_slug) > len(suffix):
                value_slug = value_slug[:-len(suffix)]
                changed = True
                break
    return value_slug


def load_json(path: Path) -> Any | None:
    try:
        if path.stat().st_size > 40 * 1024 * 1024:
            return None
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None


def write_json(path: Path, data: Any, dry_run: bool, backups: bool = True) -> None:
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if backups and path.exists():
        backup = path.with_suffix(path.suffix + ".before-hex-repair.bak")
        if not backup.exists():
            shutil.copy2(path, backup)
    path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


def chart_song_obj(data: Any) -> dict[str, Any] | None:
    """Return chart metadata for both wrapped and older root-level FNF charts.

    Some Hex/source charts use {"song": {...}}, while others use
    {"song": "Song Name", "notes": [...], ...}. In the latter format,
    treating the string-valued `song` field as the whole chart made every
    source chart invisible to the matcher.
    """
    if not isinstance(data, dict):
        return None
    song = data.get("song")
    if isinstance(song, dict):
        return song
    if any(k in data for k in ("notes", "sections", "chartNotes", "chart", "chartData", "songNotes", "events", "bpm", "songName")):
        return data
    return None


def is_chart_json(path: Path, data: Any) -> bool:
    """Exclude event-only files; source matching must be based on actual charts."""
    if path.name.lower() == "events.json" or not isinstance(data, dict):
        return False
    song = chart_song_obj(data)
    if not isinstance(song, dict):
        return False
    notes = song.get("notes", song.get("sections", song.get("chartNotes", song.get("songNotes"))))
    if isinstance(notes, list):
        return True
    if isinstance(song.get("chart"), (dict, list)) or isinstance(song.get("chartData"), (dict, list)):
        return True
    # Some Hex source files use names such as <song>-chart.json and store
    # chart data in a custom root shape. Only admit those explicitly named
    # chart files; arbitrary JSON assets must not become chart candidates.
    if "chart" in path.stem.lower() and any(k in song for k in ("events", "eventData", "chart", "chartData", "notes", "sections", "songNotes")):
        return True
    return isinstance(song.get("events"), (list, dict)) and any(k in song for k in ("bpm", "speed", "song", "songName"))


def val_string(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return str(value)


def _dict_first(source: dict[str, Any], keys: tuple[str, ...], default: Any = "") -> Any:
    for key in keys:
        if key in source and source[key] is not None:
            return source[key]
    return default


def event_triplet(item: Any) -> list[str] | None:
    """Convert common legacy/Psych/FNF-style event records into [name, v1, v2]."""
    if isinstance(item, dict):
        nested_event = item.get("event")
        if isinstance(nested_event, dict):
            nested_triplet = event_triplet(nested_event)
            if nested_triplet:
                return nested_triplet
        # Hex V3 event format: {"t": time, "e": "EventName", "v": {...}}.
        # Only known compatibility events may cross into Legacy: unknown Hex events
        # must not be dispatched with a JSON blob in value1 as that can trigger invalid
        # Legacy event parameter handling. This mapping mirrors the runtime handlers.
        if isinstance(item.get("e"), str) and item.get("e").strip():
            name = item["e"].strip()
            params = item.get("v", {})
            if not isinstance(params, dict):
                params = {}
            if name == "FocusCamera":
                packed = "|".join(str(params.get(k, default)) for k, default in (("duration", 0), ("ease", "linear"), ("easeDir", ""), ("x", 0), ("y", 0)))
                return ["HEX FocusCamera", str(params.get("char", 0)), packed]
            if name == "CharacterLook":
                return ["HEX CharacterLook", str(params.get("look", "")), str(params.get("fade", 0.5))]
            if name == "PlayAnimation":
                packed = "|".join([str(params.get("anim", "hey")), str(params.get("force", False)).lower()])
                return ["HEX PlayAnimation", str(params.get("target", "bf")), packed]
            if name in ("SwitchCharacters", "SwitchCharacter"):
                try: target = int(params.get("target", 0) or 0)
                except (TypeError, ValueError): target = 0
                packed = "|".join([str(params.get("id", "")), str(params.get("offsetX", 0)), str(params.get("offsetY", 0)), str(params.get("stageMark", False)).lower(), str(params.get("fade", 0))])
                return ["HEX SwitchCharacter", str(target), packed]
            if name == "SetCameraBop":
                return ["HEX SetCameraBop", str(params.get("intensity", 0)), f"{params.get('offset', 0)}|{params.get('rate', 1)}"]
            if name == "ZoomCamera":
                packed = "|".join(str(params.get(k, default)) for k, default in (("duration", 0), ("ease", "linear"), ("easeDir", ""), ("mode", "stage"), ("widescreenScaleX", 0), ("widescreenScaleY", 0)))
                return ["HEX ZoomCamera", str(params.get("zoom", 1)), packed]
            return None
        name = _dict_first(item, ("name", "n", "eventName", "eventKind", "eventType", "event", "kind"), "")
        if not name and isinstance(item.get("type"), str):
            name = item["type"]
        values = _dict_first(item, ("values", "v", "params", "arguments", "data", "parameters"), [])
        value1 = _dict_first(item, ("value1", "v1", "value", "param1"), "")
        value2 = _dict_first(item, ("value2", "v2", "param2"), "")
        if isinstance(values, (list, tuple)):
            if len(values) > 0:
                value1 = values[0]
            if len(values) > 1:
                value2 = values[1]
        elif isinstance(values, dict):
            value1 = _dict_first(values, ("value1", "v1", "char", "character", "target", "zoom", "anim", "animation", "amount"), value1)
            value2 = _dict_first(values, ("value2", "v2", "duration", "ease", "target", "speed"), value2)
            if value1 == "" and values:
                # Retain otherwise-unmapped parameters instead of silently discarding them.
                value1 = values
        if not str(name).strip():
            return None
        return [val_string(name), val_string(value1), val_string(value2)]
    if isinstance(item, (list, tuple)):
        if not item:
            return None
        if len(item) >= 3:
            return [val_string(item[0]), val_string(item[1]), val_string(item[2])]
        if len(item) == 2:
            return [val_string(item[0]), val_string(item[1]), ""]
        if len(item) == 1:
            return [val_string(item[0]), "", ""]
    return None


def is_time(value: Any) -> bool:
    if isinstance(value, bool) or value is None:
        return False
    if isinstance(value, (int, float)):
        return True
    if isinstance(value, str):
        try:
            float(value.strip())
            return bool(value.strip())
        except ValueError:
            return False
    return False


def payload_to_triplets(payload: Any) -> list[list[str]]:
    if isinstance(payload, dict):
        trip = event_triplet(payload)
        return [trip] if trip else []
    if not isinstance(payload, (list, tuple)) or not payload:
        return []
    # A single event triplet looks like ["Event name", "value1", "value2"].
    if not isinstance(payload[0], (dict, list, tuple)):
        trip = event_triplet(payload)
        return [trip] if trip else []
    result: list[list[str]] = []
    for item in payload:
        if isinstance(item, dict):
            trip = event_triplet(item)
            if trip:
                result.append(trip)
        elif isinstance(item, (list, tuple)):
            trip = event_triplet(item)
            if trip:
                result.append(trip)
    return result


def parse_event_collection(raw: Any) -> list[list[Any]]:
    """Normalize common event JSON shapes to Legacy's [[time, [[name,v1,v2], ...]], ...]."""
    result: list[list[Any]] = []

    def append(time: Any, payload: Any) -> None:
        if not is_time(time):
            return
        trips = payload_to_triplets(payload)
        if trips:
            try:
                t: Any = float(time)
                if t.is_integer():
                    t = int(t)
            except (TypeError, ValueError, AttributeError):
                t = time
            result.append([t, trips])

    def visit(node: Any, inherited_time: Any = None) -> None:
        if isinstance(node, dict):
            # Newer chart formats can wrap song/events or put timestamp on each event.
            if "song" in node and isinstance(node["song"], dict):
                visit(node["song"], inherited_time)
                return
            time = _dict_first(node, ("t", "time", "strumTime", "timestamp", "timeMs", "time_ms"), inherited_time)
            # Hex V3 stores each event as {t, e, v}; handle it as one complete record.
            if isinstance(node.get("e"), str) and is_time(time):
                append(time, node)
                return
            payload_key = next((k for k in ("events", "eventData", "event", "data", "entries") if k in node), None)
            has_event_name = any(k in node for k in ("name", "n", "eventName", "eventKind", "eventType", "kind", "type"))
            if isinstance(node.get("event"), str):
                has_event_name = True
            if has_event_name and is_time(time):
                append(time, node)
                return
            if payload_key is not None and is_time(time):
                append(time, node[payload_key])
                return
            # Root container such as {"events": [...]} or {"notes": [...]}.
            if payload_key is not None:
                visit(node[payload_key], inherited_time)
                return
            for key in ("chart", "data", "entries", "timeline"):
                if key in node:
                    visit(node[key], inherited_time)
            return

        if not isinstance(node, (list, tuple)) or not node:
            return
        # Legacy nested event row: [time, [[name, value1, value2], ...]].
        if len(node) >= 2 and is_time(node[0]):
            if len(node) == 2:
                append(node[0], node[1])
            else:
                # Flat event rows [time, name, value1, value2] and variants.
                if isinstance(node[1], str) or isinstance(node[1], dict):
                    trip = event_triplet(node[1:]) if not isinstance(node[1], dict) else event_triplet(node[1])
                    if trip:
                        append(node[0], [trip])
                    else:
                        append(node[0], node[1:])
                else:
                    append(node[0], node[1])
            return
        # A wrapper list may contain rows rather than one row.
        for child in node:
            visit(child, inherited_time)

    visit(raw)
    return merge_events_no_recursion(result)


def merge_events_no_recursion(events: list[list[Any]]) -> list[list[Any]]:
    result: list[list[Any]] = []
    seen: set[tuple[Any, ...]] = set()
    for event in events:
        if not isinstance(event, list) or len(event) < 2 or not isinstance(event[1], list):
            continue
        try:
            time_key: Any = round(float(event[0]), 3)
        except (TypeError, ValueError):
            time_key = val_string(event[0])
        payload = tuple(tuple(val_string(x) for x in trip[:3]) for trip in event[1] if isinstance(trip, list))
        signature = (time_key, payload)
        if signature not in seen:
            seen.add(signature)
            result.append(event)
    result.sort(key=lambda e: float(e[0]) if is_time(e[0]) else 0)
    return result


def extract_negative_lane_events(song: dict[str, Any]) -> list[list[Any]]:
    events: list[list[Any]] = []
    notes = song.get("notes", song.get("sections", []))
    if not isinstance(notes, list):
        return events
    for section in notes:
        if not isinstance(section, dict):
            continue
        section_notes = section.get("sectionNotes", section.get("notes", []))
        if not isinstance(section_notes, list):
            continue
        for note in section_notes:
            if not isinstance(note, (list, tuple)) or len(note) < 3:
                continue
            try:
                lane = float(note[1])
            except (TypeError, ValueError):
                continue
            if lane < 0 and val_string(note[2]).strip():
                name = val_string(note[2])
                v1 = val_string(note[3] if len(note) > 3 else "")
                v2 = val_string(note[4] if len(note) > 4 else "")
                events.append([note[0], [[name, v1, v2]]])
    return merge_events_no_recursion(events)


def clean_negative_lane_notes(song: dict[str, Any]) -> int:
    removed = 0
    notes = song.get("notes", song.get("sections", []))
    if not isinstance(notes, list):
        return removed
    for section in notes:
        if not isinstance(section, dict):
            continue
        key = "sectionNotes" if isinstance(section.get("sectionNotes"), list) else "notes"
        if not isinstance(section.get(key), list):
            continue
        kept = []
        for note in section[key]:
            is_event = False
            if isinstance(note, (list, tuple)) and len(note) >= 3 and val_string(note[2]).strip():
                try:
                    is_event = float(note[1]) < 0
                except (TypeError, ValueError):
                    pass
            if is_event:
                removed += 1
            else:
                kept.append(note)
        section[key] = kept
    return removed


def event_signature(row: list[Any]) -> tuple[Any, ...]:
    try:
        timestamp: Any = round(float(row[0]), 3)
    except (TypeError, ValueError, IndexError):
        timestamp = val_string(row[0] if row else "")
    payload = row[1] if len(row) > 1 and isinstance(row[1], list) else []
    return (timestamp, tuple(tuple(val_string(v) for v in trip[:3]) for trip in payload if isinstance(trip, list)))


def merge_events(*collections: Iterable[list[Any]]) -> list[list[Any]]:
    """Merge events by timestamp and individual event tuple, avoiding partial duplicates."""
    buckets: dict[Any, dict[str, Any]] = {}
    order: list[Any] = []
    for collection in collections:
        for row in collection:
            if not isinstance(row, list) or len(row) < 2:
                continue
            for item in parse_event_collection([row]):
                try:
                    numeric_time = round(float(item[0]), 3)
                    time_key: Any = numeric_time
                    time_value: Any = int(numeric_time) if numeric_time.is_integer() else numeric_time
                except (TypeError, ValueError):
                    time_key = val_string(item[0])
                    time_value = item[0]
                if time_key not in buckets:
                    buckets[time_key] = {"time": time_value, "payload": [], "seen": set()}
                    order.append(time_key)
                bucket = buckets[time_key]
                for trip in item[1]:
                    if not isinstance(trip, list):
                        continue
                    normalized = [val_string(trip[i] if i < len(trip) else "") for i in range(3)]
                    signature = tuple(normalized)
                    if signature not in bucket["seen"]:
                        bucket["seen"].add(signature)
                        bucket["payload"].append(normalized)
    result = [[buckets[key]["time"], buckets[key]["payload"]] for key in order if buckets[key]["payload"]]
    result.sort(key=lambda e: float(e[0]) if is_time(e[0]) else 0)
    return result


def read_events_file(path: Path) -> list[list[Any]]:
    data = load_json(path)
    return parse_event_collection(data) if data is not None else []


def discover_source_charts(source_root: Path) -> list[tuple[Path, dict[str, Any]]]:
    found: list[tuple[Path, dict[str, Any]]] = []
    for path in source_root.rglob("*.json"):
        data = load_json(path)
        if data is None or not isinstance(data, dict):
            continue
        # Hex V3 source charts may be named *-chart.json rather than
        # normal.json/easy.json/hard.json. Keep the path-based candidate,
        # but still require chart-like data to avoid importing random JSON.
        if is_chart_json(path, data):
            found.append((path, data))
        elif "chart" in path.stem.lower() and any(
            key in data for key in ("events", "eventData", "notes", "sections", "chart", "chartData", "songNotes")
        ):
            found.append((path, data))
    return found


def source_chart_identity(path: Path) -> str:
    """Get the song/variant identity from names such as bit-chart-erect.json.

    Hex V3 commonly puts the variant AFTER the word "chart". Removing only a
    trailing "chart" (the old behavior) failed on names like cooling-chart-new
    and bit-chart-erect, which is why variants in the same folder were tied.
    """
    stem = re.sub(r"chart(?:[-_ ]?data)?", "", path.stem, flags=re.IGNORECASE)
    return slug(stem)


def split_song_variant(value: Any) -> tuple[str, str]:
    """Return (base song id, trailing variant), without treating remix as base."""
    normalized = slug(value)
    for suffix in ("erect", "new", "2026", "remix", "normal", "easy", "hard"):
        if normalized.endswith(suffix) and len(normalized) > len(suffix):
            return normalized[:-len(suffix)], suffix
    return normalized, ""


def variants_equivalent(left: str, right: str) -> bool:
    """Recognize source '-new' charts as the 2026 destination revisions when needed."""
    left_base, left_variant = split_song_variant(left)
    right_base, right_variant = split_song_variant(right)
    if not left_base or left_base != right_base or not left_variant or not right_variant:
        return False
    if left_variant == right_variant:
        return True
    return {left_variant, right_variant} == {"new", "2026"}


def match_source_chart(
    destination_song_slug: str,
    destination_song_title: str,
    candidates: list[tuple[Path, dict[str, Any]]],
    source_root: Path,
) -> tuple[Path, dict[str, Any]] | None:
    """Prefer matching filename+variant identity; use folders only as fallback."""
    ds = slug(destination_song_slug)
    dt = slug(destination_song_title)
    ds_base = base_song_slug(destination_song_slug)
    dt_base = base_song_slug(destination_song_title)
    scored: list[tuple[int, Path, dict[str, Any]]] = []

    for path, data in candidates:
        song = chart_song_obj(data) or {}
        source_title_raw = song.get("song", song.get("songName", song.get("title", "")))
        title = slug(source_title_raw)
        title_base = base_song_slug(source_title_raw)
        identity = source_chart_identity(path)
        identity_base, identity_variant = split_song_variant(identity)
        parent = slug(path.parent.name)
        parent_base = base_song_slug(path.parent.name)
        try:
            path_parts = [slug(part) for part in path.relative_to(source_root).parts[:-1]]
        except ValueError:
            path_parts = [slug(part) for part in path.parts[:-1]]
        path_bases = [base_song_slug(part) for part in path_parts]

        score = 0
        # Exact filename identity is the strongest signal. It distinguishes
        # bit-chart.json from bit-chart-erect.json even though both share a folder.
        if ds and identity == ds:
            score = max(score, 700)
        if dt and dt != ds and identity == dt:
            score = max(score, 540)

        # Hex's newer revision files end in "-new"; some converted chart folders
        # call the same revision "(2026)". Accept that specific equivalence only.
        if ds and variants_equivalent(identity, ds):
            score = max(score, 660)
        if dt and dt != ds and variants_equivalent(identity, dt):
            score = max(score, 520)

        # Use a folder match only as a fallback. Variant-less folder names such as
        # gameplay/songs/cooling contain both cooling-chart.json and cooling-chart-new.json.
        if ds and parent == ds:
            score = max(score, 410)
        if dt and dt != ds and parent == dt:
            score = max(score, 390)
        if ds and ds in path_parts:
            score = max(score, 380)
        if dt and dt != ds and dt in path_parts:
            score = max(score, 360)

        # Base-song fallback allows a converted destination alias to match the source
        # directory, but it must never override an exact filename/variant match.
        if ds_base and parent_base == ds_base:
            score = max(score, 330)
        if dt_base and parent_base == dt_base:
            score = max(score, 315)
        if ds_base and identity_base == ds_base and not identity_variant:
            score = max(score, 305)
        if ds_base and ds_base in path_bases:
            score = max(score, 295)

        # Metadata titles are weaker than file identity because source variants often
        # share the same display title (e.g. "dunk" for both default and 2026 charts).
        if dt and title == dt:
            score = max(score, 280)
        if dt_base and title_base == dt_base:
            score = max(score, 260)

        if score:
            scored.append((score, path, data))

    if not scored:
        return None
    highest = max(item[0] for item in scored)
    best = [item for item in scored if item[0] == highest]
    if len(best) == 1:
        return best[0][1], best[0][2]
    return None


def source_event_files(source_chart: Path, destination_song_slug: str, source_song: dict[str, Any]) -> list[Path]:
    result: list[Path] = []
    expected = {slug(destination_song_slug), slug(source_song.get("song", source_song.get("songName", "")))}
    parent = source_chart.parent
    # A sibling events.json belongs to this chart directory.
    sibling = parent / "events.json"
    if sibling.exists():
        result.append(sibling)
    # A parent-level events.json is allowed only if that directory itself is named for this song.
    grandparent = parent.parent
    if slug(parent.name) not in expected and slug(grandparent.name) in expected:
        shared = grandparent / "events.json"
        if shared.exists() and shared not in result:
            result.append(shared)
    return result


def repair_charts(source_root: Path, output_root: Path, dry_run: bool, backups: bool, report: list[str]) -> tuple[int, int, int]:
    source_charts = discover_source_charts(source_root)
    report.append(f"Source chart candidates discovered: {len(source_charts)}")
    # Print the exact candidate paths so a dry-run can reveal whether a missing
    # match is caused by naming differences or by source charts not being found.
    for candidate_path, _candidate_data in source_charts:
        try:
            candidate_label = candidate_path.relative_to(source_root).as_posix()
        except ValueError:
            candidate_label = str(candidate_path)
        report.append(f"SOURCE CANDIDATE: {candidate_label}")
    destination_charts = [p for p in output_root.rglob("normal.json") if p.parent.name.lower() == "data"]
    matched = repaired = total_events = 0

    for dest_path in sorted(destination_charts):
        dest_data = load_json(dest_path)
        dest_song = chart_song_obj(dest_data)
        if not isinstance(dest_song, dict):
            continue

        song_slug = dest_path.parent.parent.name
        song_title = val_string(dest_song.get("song", song_slug))
        match = match_source_chart(song_slug, song_title, source_charts, source_root)

        internal_raw = dest_song.get("events", [])
        dest_events = parse_event_collection(internal_raw)
        dest_events_path = dest_path.parent / "events.json"
        external_raw = load_json(dest_events_path) if dest_events_path.exists() else None
        existing_external = parse_event_collection(external_raw) if external_raw is not None else []
        negative_events = extract_negative_lane_events(dest_song)
        source_events: list[list[Any]] = []
        source_desc = "no source chart match"

        if match:
            matched += 1
            source_path, source_data = match
            source_desc = str(source_path.relative_to(source_root))
            source_song = chart_song_obj(source_data) or source_data
            # Read event containers from both the normalized song object and
            # the root. Some Hex chart files keep metadata/events at the root.
            for event_key in ("events", "eventData", "eventNotes"):
                if event_key in source_song:
                    source_events.extend(parse_event_collection(source_song.get(event_key)))
                if source_data is not source_song and event_key in source_data:
                    source_events.extend(parse_event_collection(source_data.get(event_key)))
            source_events.extend(extract_negative_lane_events(source_song))
            for ev_path in source_event_files(source_path, song_slug, source_song):
                source_events.extend(read_events_file(ev_path))
        else:
            # Report the closest names on a dry run. This is diagnostic only:
            # never use fuzzy similarity to import a chart from a different song.
            dest_aliases = {slug(song_slug), slug(song_title), base_song_slug(song_slug), base_song_slug(song_title)}
            ranked: list[tuple[int, str]] = []
            for candidate_path, candidate_data in source_charts:
                candidate_song = chart_song_obj(candidate_data) or candidate_data
                candidate_title = candidate_song.get("song", candidate_song.get("songName", candidate_song.get("title", "")))
                aliases = {
                    slug(candidate_path.parent.name),
                    slug(candidate_path.stem),
                    re.sub(r"(?:chartdata|chart|normal|easy|hard)$", "", slug(candidate_path.stem)),
                    slug(candidate_title),
                    base_song_slug(candidate_path.parent.name),
                    base_song_slug(candidate_title),
                }
                overlap = max((1 if a and a == b else 0 for a in dest_aliases for b in aliases), default=0)
                if overlap:
                    try:
                        label = candidate_path.relative_to(source_root).as_posix()
                    except ValueError:
                        label = str(candidate_path)
                    ranked.append((overlap, label))
            if ranked:
                source_desc = "no safe match; related candidate(s): " + "; ".join(label for _, label in ranked[:5])
            else:
                source_desc = "no source chart match; inspect SOURCE CANDIDATE paths above"
            # If a title is present in multiple variants, don't silently pull from one of them.
            same_name = [p for p, d in source_charts if slug((chart_song_obj(d) or {}).get("song", "")) in {slug(song_slug), slug(song_title)}]
            if same_name:
                source_desc = "ambiguous source chart match; skipped to avoid cross-version event mixing"

        internal_unparsed = "events" in dest_song and dest_song.get("events") not in (None, [], {}) and not dest_events
        external_has_payload = False
        if isinstance(external_raw, dict):
            raw_song = external_raw.get("song", external_raw)
            external_has_payload = isinstance(raw_song, dict) and raw_song.get("events") not in (None, [], {})
        elif isinstance(external_raw, list):
            external_has_payload = bool(external_raw)
        external_unparsed = external_has_payload and not existing_external

        # Avoid replacing an opaque event structure with an empty/partial conversion.
        if internal_unparsed or external_unparsed:
            why = "chart events" if internal_unparsed else "existing events.json"
            report.append(f"CHART {song_slug}: unsupported {why} format detected; original event data preserved. source={source_desc}")
            continue

        combined = merge_events(existing_external, dest_events, negative_events, source_events)
        can_migrate = bool(combined)
        removed_notes = 0
        changed_chart = False
        changed_external = False

        if can_migrate:
            before_chart = json.dumps(dest_data, ensure_ascii=False, sort_keys=True)
            # Only remove event lanes if their events were successfully parsed.
            if negative_events:
                removed_notes = clean_negative_lane_notes(dest_song)
            # Canonical storage is data/events.json; Legacy loads this alongside SONG.events.
            # Clearing internal events avoids double playback of the same event list.
            if dest_events or source_events or existing_external:
                dest_song["events"] = []
            after_chart = json.dumps(dest_data, ensure_ascii=False, sort_keys=True)
            changed_chart = before_chart != after_chart
            canonical = {"song": {"events": combined, "notes": []}}
            changed_external = json.dumps(external_raw, ensure_ascii=False, sort_keys=True) != json.dumps(canonical, ensure_ascii=False, sort_keys=True)
            if changed_chart:
                write_json(dest_path, dest_data, dry_run, backups)
            if changed_external:
                write_json(dest_events_path, canonical, dry_run, backups)
            if changed_chart or changed_external:
                repaired += 1
                total_events += len(combined)
                report.append(
                    f"CHART {song_slug}: {len(combined)} unique events; removed {removed_notes} negative-lane event notes; source={source_desc}"
                )
            else:
                report.append(f"CHART {song_slug}: already repaired ({len(combined)} events); source={source_desc}")
        else:
            if match and isinstance((chart_song_obj(match[1]) or {}).get("events"), list) and (chart_song_obj(match[1]) or {}).get("events"):
                report.append(f"CHART {song_slug}: source chart contains events, but no supported event records were parsed; destination left unchanged. source={source_desc}")
            else:
                report.append(f"CHART {song_slug}: no recognized events found; no files changed. source={source_desc}")

    return matched, repaired, total_events


def object_label(obj: dict[str, Any]) -> str:
    return " ".join(val_string(obj.get(k, "")) for k in ("id", "asset", "customInstance", "name", "layer", "animation"))


def classify_layer(label: str) -> str:
    normalized = slug(label)
    # In Legacy stage.json, the common "stagefront" floor is normally behind characters.
    if "stagefront" in normalized:
        return "middle"
    if any(h in normalized for h in FRONT_HINTS):
        return "front"
    if any(h in normalized for h in BACK_HINTS):
        return "back"
    return "middle"


def z_for_layer(layer: str, ordinal: int) -> int:
    if layer == "back":
        return -300 + ordinal * 5
    if layer == "front":
        return 1000 + ordinal * 5
    return 10 + min(ordinal, 15) * 5


def repair_stage_jsons(output_root: Path, dry_run: bool, backups: bool, preserve_character_zindex: bool, preserve_stage_object_zindex: bool, report: list[str]) -> tuple[int, int]:
    stage_files = 0
    object_count = 0
    for path in sorted(output_root.rglob("*.json")):
        data = load_json(path)
        if not isinstance(data, dict):
            continue
        if not ("boyfriend" in data and "opponent" in data and "defaultZoom" in data):
            continue
        changed = False
        if not preserve_character_zindex:
            # Use one shared character plane. Legacy defaults to 0; a consistent explicit value
            # keeps old converted stage-object z-indices from swallowing every character.
            # Keep the opponent behind the player, with GF between them.
            # Using 100 for all three creates ties and can leave order dependent
            # on insertion order in Legacy's z-sorting.
            character_layers = {"dadZIndex": 100, "gfZIndex": 110, "bfZIndex": 120}
            for key, target_z in character_layers.items():
                if data.get(key) != target_z:
                    data[key] = target_z
                    changed = True
        objects = data.get("stageObjects")
        changed_objects = 0
        if isinstance(objects, list) and not preserve_stage_object_zindex:
            layer_counts = {"back": 0, "middle": 0, "front": 0}
            for obj in objects:
                if not isinstance(obj, dict):
                    continue
                layer = classify_layer(object_label(obj))
                ordinal = layer_counts[layer]
                layer_counts[layer] += 1
                z = z_for_layer(layer, ordinal)
                if obj.get("zIndex") != z:
                    obj["zIndex"] = z
                    changed = True
                    changed_objects += 1
        if changed:
            write_json(path, data, dry_run, backups)
            stage_files += 1
            object_count += changed_objects
            report.append(
                f"STAGE JSON {path.relative_to(output_root)}: character z-index={'preserved' if preserve_character_zindex else '100/110/120 (dad/gf/bf)'}; rebalanced {changed_objects} stageObjects"
            )
    return stage_files, object_count


def _stage_script_layer(var_name: str, source_lines: list[str], add_line_index: int) -> str:
    label = var_name
    for previous in reversed(source_lines[max(0, add_line_index - 40):add_line_index]):
        if re.search(rf"\b{re.escape(var_name)}\b", previous):
            label += " " + previous
            if any(token in previous for token in ("Paths.image", "Paths.getSparrowAtlas", "new FlxSprite", "loadGraphic", "makeGraphic")):
                # Keep checking a few more lines for the asset path, but stop at declarations.
                if re.search(rf"\bvar\s+{re.escape(var_name)}\b", previous):
                    break
    return classify_layer(label)


def patch_stage_hscript(path: Path, output_root: Path, dry_run: bool, backups: bool, report: list[str]) -> int:
    try:
        original = path.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError):
        return 0
    lines = original.splitlines(keepends=True)
    content_lines = [line.rstrip("\r\n") for line in lines]

    # Builder-generated Hex stages already copy source zIndex values directly. Do not
    # replace those intentional per-prop depths with generic foreground/background ranks.
    if "var hexProps:Array<Dynamic>" in original and "hexProps.push(" in original:
        report.append(f"STAGE HScript {path.relative_to(output_root)}: source Hex zIndex values preserved")
        return 0

    # Discover static stage.add(sprite)/add(sprite) calls and assign stable layer values.
    occurrences: list[tuple[int, str, str, int]] = []
    layer_counts = {"back": 0, "middle": 0, "front": 0}
    seen_var: set[str] = set()
    for index, line in enumerate(content_lines):
        for match in ADD_CALL.finditer(line):
            var_name = match.group(1)
            if slug(var_name) in {slug(x) for x in CHARACTER_NAMES}:
                continue
            layer = _stage_script_layer(var_name, content_lines, index)
            if var_name in seen_var:
                continue
            seen_var.add(var_name)
            ordinal = layer_counts[layer]
            layer_counts[layer] += 1
            occurrences.append((index, var_name, layer, z_for_layer(layer, ordinal)))

    if not occurrences:
        return 0

    by_var = {var: (layer, z, index) for index, var, layer, z in occurrences}
    explicit_z_vars = set(re.findall(r"\b([A-Za-z_]\w*)\s*\.\s*zIndex\s*(?:=|\+=|-=)", original))
    numeric_z_vars = {m.group(2) for text_line in content_lines if (m := NUMERIC_Z_ASSIGN.match(text_line))}
    assigned = 0
    new_lines: list[str] = []
    inserted_vars: set[str] = set()
    replaced_vars: set[str] = set()

    for index, line in enumerate(lines):
        clean = line.rstrip("\r\n")
        zmatch = NUMERIC_Z_ASSIGN.match(clean)
        if zmatch and zmatch.group(2) in by_var:
            var = zmatch.group(2)
            _, z, _ = by_var[var]
            indent, _, _, comment = zmatch.groups()
            newline = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else ""
            new_lines.append(f"{indent}{var}.zIndex = {z};{comment}{newline}")
            replaced_vars.add(var)
            assigned += 1
            continue

        # If no numeric assignment exists, insert immediately before the first add call for it.
        vars_on_line = [var for call_index, var, _, _ in occurrences if call_index == index]
        for var in vars_on_line:
            if var in replaced_vars or var in inserted_vars or var in explicit_z_vars:
                continue
            _, z, _ = by_var[var]
            indent = re.match(r"^\s*", clean).group(0)
            newline = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else "\n"
            new_lines.append(f"{indent}{var}.zIndex = {z};{newline}")
            inserted_vars.add(var)
            assigned += 1
        new_lines.append(line)

    updated = "".join(new_lines)
    dynamic_vars = sorted(var for var in by_var if var in explicit_z_vars and var not in numeric_z_vars)
    if dynamic_vars:
        report.append(f"STAGE HScript {path.relative_to(output_root)}: dynamic zIndex expression kept for {', '.join(dynamic_vars)}")
    if assigned and updated != original:
        if not dry_run:
            if backups:
                backup = path.with_suffix(path.suffix + ".before-hex-repair.bak")
                if not backup.exists():
                    shutil.copy2(path, backup)
            path.write_text(updated, encoding="utf-8")
        report.append(f"STAGE HScript {path.relative_to(output_root)}: normalized/inserted {assigned} static zIndex assignments")
    return assigned


def repair_stage_scripts(output_root: Path, dry_run: bool, backups: bool, report: list[str]) -> int:
    assigned = 0
    for path in sorted(output_root.rglob("*.hx")):
        rel_parts = [slug(part) for part in path.relative_to(output_root).parts[:-1]]
        if not any("stage" in part for part in rel_parts):
            continue
        assigned += patch_stage_hscript(path, output_root, dry_run, backups, report)
    return assigned



RAM_NEW_PACKAGE_SLUGS = {"ramnew", "ram2026"}
RAM_NEW_SOURCE_INST_SLUGS = {"instnew", "instrumentalnew"}
RAM_TEXT_EXTENSIONS = {".json", ".hx", ".txt", ".lua", ".xml", ".hscript"}


def find_ram_new_source_instrument(source_root: Path) -> tuple[Path | None, list[Path]]:
    """Locate the source Ram New instrumental without confusing it with normal Ram."""
    found: list[tuple[int, Path]] = []
    for path in source_root.rglob("*"):
        if not path.is_file() or path.suffix.lower() != ".ogg":
            continue
        if slug(path.stem) not in RAM_NEW_SOURCE_INST_SLUGS:
            continue
        try:
            rel_parts = [slug(part) for part in path.relative_to(source_root).parts[:-1]]
        except ValueError:
            rel_parts = [slug(part) for part in path.parts[:-1]]
        # Require a Ram directory/identity somewhere in the path, so an unrelated
        # song that happens to have an Inst-new file cannot be selected.
        if not any(part in {"ram", "ramnew", "ram2026"} for part in rel_parts):
            continue
        score = 0
        if slug(path.stem) == "instnew":
            score += 50
        if slug(path.parent.name) == "ram":
            score += 40
        elif slug(path.parent.name) in {"ramnew", "ram2026"}:
            score += 30
        if "songs" in rel_parts:
            score += 15
        if "assets" in rel_parts or "gameplay" in rel_parts:
            score += 5
        if path.stat().st_size > 0:
            score += 1
        found.append((score, path))

    if not found:
        return None, []
    best_score = max(score for score, _ in found)
    best = sorted((path for score, path in found if score == best_score), key=lambda x: str(x).lower())
    if len(best) != 1:
        return None, best
    return best[0], [path for _, path in sorted(found, key=lambda item: (-item[0], str(item[1]).lower()))]


def find_ram_new_package(output_root: Path) -> tuple[Path | None, list[Path]]:
    """Find the converted song package which owns data/normal.json."""
    packages: set[Path] = set()
    for chart_path in output_root.rglob("normal.json"):
        if chart_path.parent.name.lower() != "data":
            continue
        package = chart_path.parent.parent
        if slug(package.name) in RAM_NEW_PACKAGE_SLUGS:
            packages.add(package)
    for package in output_root.rglob("*"):
        if not package.is_dir() or slug(package.name) not in RAM_NEW_PACKAGE_SLUGS:
            continue
        if (package / "data" / "normal.json").is_file():
            packages.add(package)
    ordered = sorted(packages, key=lambda p: (slug(p.name) != "ram2026", str(p).lower()))
    if len(ordered) == 1:
        return ordered[0], ordered
    if len(ordered) > 1:
        # Two packages with the old/new names can indicate a previous partial run;
        # do not guess which one should be playable.
        return None, ordered
    return None, []


def _ram_reference_replacements(text: str) -> str:
    # Display title is Ram (2026); package/path key must be ram-(2026).
    # Replace legacy folder identifiers in week definitions and other text metadata.
    text = re.sub(r"(?<![A-Za-z0-9])Ram\s+New(?![A-Za-z0-9])", "Ram (2026)", text, flags=re.IGNORECASE)
    text = re.sub(r"(?<![A-Za-z0-9])Ram\s+2026(?![A-Za-z0-9])", "Ram (2026)", text, flags=re.IGNORECASE)
    text = re.sub(r"(?<![A-Za-z0-9])R\.?A\.?M\.?\s*\(\s*2026(?:\s+Ver\.?)?\s*\)", "Ram (2026)", text, flags=re.IGNORECASE)
    text = re.sub(r"(?<![A-Za-z0-9])R\.?A\.?M\.?\s*\(\s*New\s*\)", "Ram (2026)", text, flags=re.IGNORECASE)
    text = re.sub(r"(?<![A-Za-z0-9])ram\s*-\s*\(\s*new\s*\)(?![A-Za-z0-9])", "ram-(2026)", text, flags=re.IGNORECASE)
    text = re.sub(r"(?<![A-Za-z0-9])ram\s*-\s*\(\s*2026\s*\)(?![A-Za-z0-9])", "ram-(2026)", text, flags=re.IGNORECASE)
    text = re.sub(r"(?<![A-Za-z0-9-])ram-new(?![A-Za-z0-9-])", "ram-(2026)", text, flags=re.IGNORECASE)
    text = re.sub(r"(?<![A-Za-z0-9-])ram-2026(?![A-Za-z0-9-])", "ram-(2026)", text, flags=re.IGNORECASE)
    return text


RAM_2026_TITLE = "Ram (2026)"
RAM_DISPLAY_FIELDS = {"song", "songname", "title", "displayname", "displaytitle", "label", "name"}


def _is_ram_2026_marker(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    if slug(value) in {"ramnew", "ram2026"}:
        return True
    return bool(re.search(
        r"(?<![A-Za-z0-9])ram(?:\s*\(\s*2026\s*\)|[\s_-]+(?:new|2026))(?![A-Za-z0-9])",
        value,
        flags=re.IGNORECASE,
    ))


def _repair_ram_2026_week_tree(node: Any, inherited_target: bool = False) -> tuple[Any, int]:
    """Fix a week-entry display name when that entry identifies the ram-2026 variant."""
    changed = 0
    if isinstance(node, dict):
        explicit_target = inherited_target or any(
            _is_ram_2026_marker(key) or _is_ram_2026_marker(value)
            for key, value in node.items()
        )
        for key, value in list(node.items()):
            if explicit_target and str(key).lower() in RAM_DISPLAY_FIELDS and isinstance(value, str):
                if slug(value) == "ram":
                    node[key] = RAM_2026_TITLE
                    changed += 1
                    continue
            if isinstance(value, (dict, list)):
                updated, count = _repair_ram_2026_week_tree(value, explicit_target)
                node[key] = updated
                changed += count
        return node, changed
    if isinstance(node, list):
        # Some week formats encode a song entry as a small array. If the same
        # entry carries ram-new/ram-2026, disambiguate a plain "Ram" in that entry.
        explicit_target = inherited_target or any(_is_ram_2026_marker(item) for item in node)
        if explicit_target:
            for index, value in enumerate(node):
                if isinstance(value, str) and slug(value) in {"ram", "ramnew", "ram2026"}:
                    if value != RAM_2026_TITLE:
                        node[index] = RAM_2026_TITLE
                        changed += 1
        for index, value in enumerate(list(node)):
            if isinstance(value, (dict, list)):
                updated, count = _repair_ram_2026_week_tree(value, inherited_target)
                node[index] = updated
                changed += count
        return node, changed
    return node, 0


def update_ram_2026_display_metadata(output_root: Path, dry_run: bool, backups: bool, report: list[str]) -> tuple[int, int]:
    """Set the variant's chart title and matching week-entry title to `Ram (2026)`."""
    package, package_candidates = find_ram_new_package(output_root)
    chart_files_changed = 0
    week_files_changed = 0
    if package is None:
        report.append("RAM DISPLAY NAME: could not uniquely locate the ram-2026 chart package; skipped targeted chart/week metadata fix.")
        return 0, 0

    # A chart in the dedicated ram-2026 folder can safely have its bare "Ram"
    # metadata changed; normal Ram lives in a different folder and is untouched.
    for path in sorted((package / "data").glob("*.json")) if (package / "data").is_dir() else []:
        if path.name.lower() not in {"normal.json", "easy.json", "hard.json"}:
            continue
        data = load_json(path)
        song_obj = chart_song_obj(data)
        if not isinstance(song_obj, dict):
            continue
        changed = False
        for key in ("song", "songName", "title"):
            value = song_obj.get(key)
            if isinstance(value, str) and slug(value) in {"ram", "ramnew", "ram2026"} and value != RAM_2026_TITLE:
                song_obj[key] = RAM_2026_TITLE
                changed = True
        if changed:
            chart_files_changed += 1
            report.append(f"RAM CHART TITLE: {path.relative_to(output_root).as_posix()} -> {RAM_2026_TITLE}")
            write_json(path, data, dry_run, backups)

    # Week definitions usually store the title in a JSON entry. Only a bare "Ram"
    # in an entry already tied to ram-new/ram-2026 is changed, avoiding normal Ram.
    chart_root = package / "data"
    for path in sorted(output_root.rglob("*.json")):
        if chart_root in path.parents or path.name.lower() in {"normal.json", "easy.json", "hard.json", "events.json"} and path.parent.name.lower() == "data":
            continue
        if ".before-hex-repair.bak" in path.name or path.name == "hex_v3_legacy_repair_report.txt":
            continue
        data = load_json(path)
        if data is None:
            continue
        updated, count = _repair_ram_2026_week_tree(data)
        if count:
            week_files_changed += 1
            report.append(f"RAM WEEK TITLE: {path.relative_to(output_root).as_posix()} -> {RAM_2026_TITLE} ({count} field(s))")
            write_json(path, updated, dry_run, backups)

    if chart_files_changed == 0:
        report.append("RAM CHART TITLE: no bare Ram/New/2026 title field needed targeted correction (text replacements still applied where matching).")
    if week_files_changed == 0:
        report.append("RAM WEEK TITLE: no week JSON entry with a clear ram-new/ram-2026 identity and bare Ram title was found; explicit Ram New/Ram 2026 text references were still renamed.")
    return chart_files_changed, week_files_changed


def update_ram_new_references(output_root: Path, dry_run: bool, backups: bool, report: list[str]) -> int:
    changed_files = 0
    for path in sorted(output_root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in RAM_TEXT_EXTENSIONS:
            continue
        if ".before-hex-repair.bak" in path.name or path.name == "hex_v3_legacy_repair_report.txt":
            continue
        try:
            original = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        updated = _ram_reference_replacements(original)
        if updated == original:
            continue
        changed_files += 1
        try:
            rel = path.relative_to(output_root)
        except ValueError:
            rel = path
        report.append(f"RAM NAME REF {rel}: display title -> Ram (2026); week/path key -> ram-(2026)")
        if not dry_run:
            if backups and path.exists():
                backup = path.with_suffix(path.suffix + ".before-hex-repair.bak")
                if not backup.exists():
                    shutil.copy2(path, backup)
            path.write_text(updated, encoding="utf-8")
    return changed_files


def repair_ram_new_music(source_root: Path, output_root: Path, dry_run: bool, backups: bool, report: list[str]) -> tuple[int, int, int]:
    """Fix only Ram New: use its source Inst-new as this package's Inst.ogg and label it Ram (2026)."""
    source_inst, source_candidates = find_ram_new_source_instrument(source_root)
    if source_inst is None:
        if source_candidates:
            labels = []
            for candidate in source_candidates[:8]:
                try:
                    labels.append(candidate.relative_to(source_root).as_posix())
                except ValueError:
                    labels.append(str(candidate))
            report.append("MUSIC Ram New: ambiguous source Inst-new file; skipped. Candidates: " + "; ".join(labels))
        else:
            report.append("MUSIC Ram New: source Inst-new.ogg not found in a Ram-related folder; no music files changed.")
        return 0, 0, 0

    package, package_candidates = find_ram_new_package(output_root)
    if package is None:
        if package_candidates:
            report.append("MUSIC Ram New: multiple output packages named Ram New/Ram 2026; skipped to avoid changing the wrong package: " + "; ".join(str(x) for x in package_candidates))
        else:
            report.append("MUSIC Ram New: output package named ram-new/ram-2026 with data/normal.json not found; no music files changed.")
        return 0, 0, 0

    renamed = 0
    target_package = package
    canonical_package_name = "ram-(2026)"
    if package.name.lower() != canonical_package_name:
        proposed = package.with_name(canonical_package_name)
        if proposed.exists() and proposed.resolve() != package.resolve():
            report.append(f"MUSIC Ram (2026): cannot rename {package} because target already exists: {proposed}; no music files changed.")
            return 0, 0, 0
        report.append(f"MUSIC PACKAGE: rename {package.relative_to(output_root)} -> {proposed.relative_to(output_root)}")
        target_package = proposed
        renamed = 1

    # Legacy checks for songs/<key>/audio/Inst.ogg when the audio directory exists;
    # otherwise it loads songs/<key>/Inst.ogg.
    audio_rel = Path("audio") if (package / "audio").is_dir() else Path()
    source_rel = source_inst.relative_to(source_root).as_posix()
    dest_inst = target_package / audio_rel / "Inst.ogg"
    old_inst = package / audio_rel / "Inst.ogg"
    report.append(f"MUSIC SOURCE: {source_rel}")
    report.append(f"MUSIC INST: copy source Ram New instrumental -> {dest_inst.relative_to(output_root)} as Inst.ogg")

    if not dry_run:
        if renamed:
            package.rename(target_package)
        dest_inst.parent.mkdir(parents=True, exist_ok=True)
        # Back up the current (likely normal-Ram) instrumental before replacing it.
        current_inst = dest_inst if dest_inst.exists() else old_inst
        if current_inst.exists() and backups:
            backup = current_inst.with_suffix(current_inst.suffix + ".before-hex-repair.bak")
            if not backup.exists():
                shutil.copy2(current_inst, backup)
        shutil.copy2(source_inst, dest_inst)

    ref_count = update_ram_new_references(output_root, dry_run, backups, report)
    if dry_run:
        report.append("MUSIC NOTE: preview only; no folder, reference, or audio changes were written.")
    else:
        report.append("MUSIC NOTE: Ram (2026) instrumental repaired from source Inst-new; package folder is ram-(2026), week/path references use ram-(2026), and normal Ram audio remains separate.")
    return renamed, 1, ref_count

def main() -> int:
    parser = argparse.ArgumentParser(description="Repair Hex V3 chart events, Ram (2026) audio/names, and Legacy stage z-index values.")
    parser.add_argument("--source", required=True, help="Original Hex V3 directory")
    parser.add_argument("--output", required=True, help="Converted Legacy port directory")
    parser.add_argument("--apply", action="store_true", help="Write changes. Without this option, the script only previews changes.")
    parser.add_argument("--dry-run", action="store_true", help="Explicitly preview changes without writing (default behavior).")
    parser.add_argument("--no-backups", action="store_true", help="Do not create .before-hex-repair.bak backups")
    parser.add_argument("--preserve-character-zindex", action="store_true", help="Do not normalize dad/gf/bf z-index values to 100")
    parser.add_argument("--preserve-stage-object-zindex", action="store_true", help="Do not rebalance existing stageObjects zIndex values")
    parser.add_argument("--skip-events", action="store_true", help="Skip chart/event repairs")
    parser.add_argument("--skip-stages", action="store_true", help="Skip stage JSON/HScript z-index repairs")
    parser.add_argument("--skip-music", action="store_true", help="Skip the Ram (2026) instrumental/name repair")
    args = parser.parse_args()

    source_root = Path(args.source).expanduser().resolve()
    output_root = Path(args.output).expanduser().resolve()
    if not source_root.is_dir():
        print(f"ERROR: source directory does not exist: {source_root}", file=sys.stderr)
        return 2
    if not output_root.is_dir():
        print(f"ERROR: output directory does not exist: {output_root}", file=sys.stderr)
        print("Run the existing port builder first, then run this repair tool.", file=sys.stderr)
        return 2
    if source_root == output_root or source_root in output_root.parents:
        print("ERROR: source and output must be separate directories to avoid matching already-repaired files.", file=sys.stderr)
        return 2

    # Safe unless the user explicitly adds --apply.
    dry_run = not args.apply or args.dry_run
    backups = not args.no_backups
    report = [
        "Hex V3 -> VS Impostor: Legacy Mobile repair report",
        f"repair_script_version={VERSION}",
        f"source={source_root}",
        f"output={output_root}",
        f"dry_run={dry_run}",
        "",
    ]

    if args.skip_music:
        music_packages = music_inst = music_refs = 0
        report.append("MUSIC Ram (2026): skipped by --skip-music.")
    else:
        music_packages, music_inst, music_refs = repair_ram_new_music(source_root, output_root, dry_run, backups, report)

    if not args.skip_music:
        ram_chart_titles, ram_week_titles = update_ram_2026_display_metadata(output_root, dry_run, backups, report)
    else:
        ram_chart_titles = ram_week_titles = 0

    if args.skip_events:
        matched = chart_writes = event_count = 0
    else:
        matched, chart_writes, event_count = repair_charts(source_root, output_root, dry_run, backups, report)

    if args.skip_stages:
        stage_json_count = object_count = script_objects = 0
    else:
        stage_json_count, object_count = repair_stage_jsons(
            output_root, dry_run, backups, args.preserve_character_zindex,
            args.preserve_stage_object_zindex, report
        )
        script_objects = repair_stage_scripts(output_root, dry_run, backups, report)

    report.extend([
        "",
        f"Source chart matches: {matched}",
        f"Chart folders repaired: {chart_writes}",
        f"Unique events written/retained: {event_count}",
        f"Stage JSON files modified: {stage_json_count}",
        f"stageObjects zIndex values rebalanced: {object_count}",
        f"HScript zIndex assignments normalized/inserted: {script_objects}",
        f"Ram (2026) packages renamed: {music_packages}",
        f"Ram (2026) instrumentals repaired: {music_inst}",
        f"Files with Ram (2026) references updated: {music_refs}",
        f"Ram (2026) chart-title files updated: {ram_chart_titles}",
        f"Ram (2026) week-title files updated: {ram_week_titles}",
        "",
        "NOTE: source matching normalizes punctuation and matches chart filename variants (for example bit-chart-erect -> b.i.t.-(erect)); new/2026 aliases are equivalent only as a lower-priority variant match. Ambiguous ties are skipped.",
        "NOTE: SOURCE CANDIDATE lines list the actual files discovered under --source. For unmatched charts, related candidates are diagnostic only and are never imported by fuzzy name similarity.",
        "NOTE: Known Hex {t,e,v} events are converted to Legacy-compatible event triplets handled by HexModchartRuntime; unknown Hex event types are skipped and recorded in PORT-REPORT.json rather than dispatched with invalid parameters.",
        "NOTE: Ram (2026) audio repair copies source Inst-new.ogg into the separate ram-(2026) package as Inst.ogg; normal Ram audio is kept separate.",
        "NOTE: display text uses exactly 'Ram (2026)' and the internal package/week key is exactly 'ram-(2026)'. Week references ram-(new), ram-new, ram-2026, or ram-(2026) are normalized to ram-(2026).",
        "NOTE: foreground/background classification uses object names/assets. Review unusual names; no script can infer the intended layering of every custom sprite automatically.",
        "NOTE: preserving an event in events.json does not implement a Hex-only mechanic. Events unsupported by Legacy still need an HScript mechanic/event handler.",
        "NOTE: this run was only a preview; rerun with --apply to write files." if dry_run else "NOTE: changes were applied. Original files were backed up unless --no-backups was used.",
    ])

    report_text = "\n".join(report) + "\n"
    print(report_text)
    if not dry_run:
        report_path = output_root / "hex_v3_legacy_repair_report.txt"
        report_path.write_text(report_text, encoding="utf-8")
        print(f"Report saved to: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
