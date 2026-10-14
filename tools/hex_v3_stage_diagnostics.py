#!/usr/bin/env python3
# Hex V3 -> VS Impostor: Legacy Mobile stage diagnostics
# Read-only inspection of source stages and the converted Legacy pack.

from __future__ import annotations
import argparse
import json
import math
import re
import sys
from pathlib import Path
from typing import Any

VERSION = "1.0"


def load_json(path: Path) -> Any | None:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None


def case_path(path: Path) -> Path | None:
    if path.exists():
        return path
    current = path.anchor and Path(path.anchor) or Path()
    parts = path.parts[1:] if path.is_absolute() else path.parts
    for part in parts:
        if not current.is_dir():
            return None
        found = next((p for p in current.iterdir() if p.name.casefold() == part.casefold()), None)
        if found is None:
            return None
        current = found
    return current if current.exists() else None


def num_pair(value: Any) -> list[float] | None:
    if not isinstance(value, (list, tuple)) or len(value) < 2:
        return None
    try:
        pair = [float(value[0]), float(value[1])]
    except (TypeError, ValueError):
        return None
    if not all(math.isfinite(x) for x in pair):
        return None
    return pair


def equal_num(a: Any, b: Any, eps: float = 0.001) -> bool:
    try:
        return math.isfinite(float(a)) and math.isfinite(float(b)) and abs(float(a) - float(b)) <= eps
    except (TypeError, ValueError):
        return False


def equal_pair(a: Any, b: Any) -> bool:
    aa, bb = num_pair(a), num_pair(b)
    return bool(aa and bb and equal_num(aa[0], bb[0]) and equal_num(aa[1], bb[1]))


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.casefold())


def source_stages_root(source: Path) -> Path | None:
    for rel in ("gameplay/stages", "assets/gameplay/stages"):
        p = case_path(source / rel)
        if p and p.is_dir():
            return p
    return None


def output_stage_root(output: Path) -> Path | None:
    p = case_path(output / "stages")
    return p if p and p.is_dir() else None


def output_json_path(stage_root: Path, name: str) -> Path | None:
    return case_path(stage_root / f"{name}.json")


def source_asset_path(stage_root: Path, asset_path: str) -> Path | None:
    s = str(asset_path or "").replace("\\", "/").strip()
    if not s:
        return None
    s = s.removeprefix("/")
    s = s.replace("gameplay/stages/", "", 1) if "gameplay/stages/" in s else s
    direct = case_path(stage_root / s)
    if direct is not None:
        return direct
    # Stage prop assetPath commonly omits the image extension.
    base = stage_root / s
    for suffix in (".png", ".xml", ".json"):
        found = case_path(base.with_suffix(suffix))
        if found:
            return found
    return None


def output_asset_exists(output: Path, ref: str) -> bool:
    rel = str(ref or "").replace("\\", "/").strip().lstrip("/")
    if not rel:
        return False
    if rel.startswith("images/"):
        p = output / rel
    else:
        p = output / "images" / rel
    found = case_path(p)
    if found and (found.is_file() or found.is_dir()):
        return True
    if not Path(rel).suffix:
        for suffix in (".png", ".xml", ".json"):
            found = case_path(p.with_suffix(suffix))
            if found and found.is_file():
                return True
        # FlxAnimate atlases usually live in a folder with this prefix.
        parent = p.parent
        if parent.is_dir():
            prefix = p.name.casefold()
            for child in parent.iterdir():
                if child.name.casefold() == prefix and child.is_dir():
                    return True
    return False


def read_source_stage_json(stage_dir: Path, stage_name: str) -> tuple[Path | None, Any | None]:
    candidates = [stage_dir / f"{stage_name}.json", stage_dir / "stage.json"]
    for cand in candidates:
        found = case_path(cand)
        if found and found.is_file():
            return found, load_json(found)
    # Case-insensitive filename fallback.
    if stage_dir.is_dir():
        for cand in stage_dir.iterdir():
            if cand.is_file() and cand.suffix.casefold() == ".json" and cand.stem.casefold() in {stage_name.casefold(), "stage"}:
                return cand, load_json(cand)
    return None, None


def read_stage_ref(chart: Any) -> str | None:
    if not isinstance(chart, dict):
        return None
    candidates = []
    song = chart.get("song")
    if isinstance(song, dict):
        candidates.append(song)
    candidates.append(chart)
    for obj in candidates:
        for key in ("stage", "stageId", "stage_id"):
            value = obj.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Audita stages do Hex V3 e a conversão para VS Impostor: Legacy Mobile; não altera arquivos do port.")
    parser.add_argument("--source", required=True, help="Pasta do mod original Hex V3, contendo gameplay/stages/")
    parser.add_argument("--output", required=True, help="Pasta raiz do port Legacy, contendo stages/, images/ e songs/")
    parser.add_argument("--report", default="", help="Caminho opcional do relatório JSON; padrão: <output>/STAGE-DIAGNOSTICS.json")
    args = parser.parse_args()

    source = Path(args.source).expanduser().resolve()
    output = Path(args.output).expanduser().resolve()
    source_root = source_stages_root(source)
    out_root = output_stage_root(output)
    if not source.is_dir():
        print(f"ERRO: pasta de origem não encontrada: {source}", file=sys.stderr)
        return 2
    if source_root is None:
        print("ERRO: não encontrei gameplay/stages/ na origem. Passe --source apontando para a raiz extraída do Hex V3.", file=sys.stderr)
        return 2
    if not output.is_dir() or out_root is None:
        print("ERRO: pasta do port/stages não encontrada. Passe --output para a raiz que contém stages/.", file=sys.stderr)
        return 2

    stage_dirs = sorted((p for p in source_root.iterdir() if p.is_dir()), key=lambda p: p.name.casefold())
    output_jsons = {p.stem.casefold(): p for p in out_root.glob("*.json") if p.is_file()}
    output_hxs = {p.stem.casefold(): p for p in out_root.glob("*.hx") if p.is_file()}
    report: dict[str, Any] = {
        "tool": "hex_v3_stage_diagnostics.py",
        "version": VERSION,
        "source": str(source),
        "sourceStagesRoot": str(source_root),
        "output": str(output),
        "stageSummary": {"sourceStageFolders": len(stage_dirs), "legacyStageJsons": len(output_jsons), "legacyStageScripts": len(output_hxs)},
        "stages": [],
        "missingOutputStages": [],
        "unmatchedOutputStages": [],
        "chartStageReferences": {},
        "warnings": [],
        "notes": ["Relatório somente leitura: não modifica posições, câmeras, charts nem assets.", "Uma posição que difere da origem pode ter sido editada manualmente; confira antes de assumir que está errada."],
    }

    source_names = {d.name.casefold() for d in stage_dirs}
    for stage_dir in stage_dirs:
        sid = stage_dir.name
        src_json_path, cfg = read_source_stage_json(stage_dir, sid)
        sid_key = sid.casefold()
        out_json_path = output_jsons.get(sid_key)
        out_hx_path = output_hxs.get(sid_key)
        if out_json_path is None or out_hx_path is None:
            report["missingOutputStages"].append({"stage": sid, "missingJson": out_json_path is None, "missingHScript": out_hx_path is None})
        stage_item: dict[str, Any] = {
            "stage": sid,
            "sourceJson": str(src_json_path) if src_json_path else None,
            "legacyJson": str(out_json_path) if out_json_path else None,
            "legacyHScript": str(out_hx_path) if out_hx_path else None,
            "sourceJsonValid": isinstance(cfg, dict),
            "warnings": [],
            "metrics": {},
            "comparisons": {},
            "missingSourceAssets": [],
            "missingLegacyAssets": [],
        }
        if not isinstance(cfg, dict):
            stage_item["warnings"].append("JSON de origem ausente ou inválido.")
        props = cfg.get("props", []) if isinstance(cfg, dict) else []
        props = props if isinstance(props, list) else []
        missing_src = []
        for i, prop in enumerate(props):
            if not isinstance(prop, dict):
                continue
            ap = str(prop.get("assetPath", "") or "")
            if ap and source_asset_path(source_root, ap) is None:
                missing_src.append({"index": i, "name": prop.get("name", f"prop{i}"), "assetPath": ap})
        stage_item["missingSourceAssets"] = missing_src
        stage_item["metrics"]["sourceProps"] = len([p for p in props if isinstance(p, dict) and str(p.get("assetPath", "") or "").strip()])
        stage_item["metrics"]["sourcePropsWithoutAssetPath"] = len([p for p in props if isinstance(p, dict) and not str(p.get("assetPath", "") or "").strip()])

        out_data = load_json(out_json_path) if out_json_path else None
        if out_json_path and not isinstance(out_data, dict):
            stage_item["warnings"].append("JSON de stage Legacy inválido.")
        hx_text = ""
        if out_hx_path:
            try:
                hx_text = out_hx_path.read_text(encoding="utf-8-sig")
            except (OSError, UnicodeError):
                stage_item["warnings"].append("Não consegui ler o HScript do stage.")
        sprites = re.findall(r"new\s+(?:FunkinSprite|FlxSprite)\s*\(", hx_text)
        stage_item["metrics"]["legacySpritesCreated"] = len(sprites)
        if stage_item["metrics"]["sourceProps"] and len(sprites) != stage_item["metrics"]["sourceProps"]:
            stage_item["warnings"].append(f"Quantidade de sprites difere: origem tem {stage_item['metrics']['sourceProps']} props com assetPath, HScript cria {len(sprites)} sprites. Pode haver props não convertidos ou estrutura especial.")

        refs = []
        for match in re.finditer(r"(?:Paths\.image|Paths\.getSparrowAtlas|\.loadAtlas)\(\s*['\"]([^'\"]+)['\"]", hx_text):
            refs.append(match.group(1))
        refs = list(dict.fromkeys(refs))
        missing_refs = [r for r in refs if not output_asset_exists(output, r)]
        stage_item["metrics"]["legacyAssetReferences"] = len(refs)
        stage_item["missingLegacyAssets"] = missing_refs
        if missing_refs:
            stage_item["warnings"].append(f"{len(missing_refs)} referências de assets no HScript não foram encontradas em images/.")

        z_values = re.findall(r"\.zIndex\s*=\s*(-?\d+)", hx_text)
        z_counts: dict[str, int] = {}
        for z in z_values:
            z_counts[z] = z_counts.get(z, 0) + 1
        duplicates = {k: v for k, v in z_counts.items() if v > 1}
        stage_item["metrics"]["zIndexAssignments"] = len(z_values)
        stage_item["metrics"]["duplicateZIndexValues"] = duplicates
        if duplicates:
            stage_item["warnings"].append("Há valores zIndex repetidos nos props. Isso pode ser intencional; confira a ordem visual no jogo.")

        if isinstance(cfg, dict) and isinstance(out_data, dict):
            comparisons = {}
            comparisons["cameraZoom"] = {"source": cfg.get("cameraZoom", 0.9), "legacy": out_data.get("defaultZoom"), "matches": equal_num(cfg.get("cameraZoom", 0.9), out_data.get("defaultZoom", 0.9))}
            source_chars = cfg.get("characters", {}) if isinstance(cfg.get("characters", {}), dict) else {}
            for src_key, out_key in (("bf", "boyfriend"), ("dad", "opponent"), ("gf", "girlfriend")):
                src_obj = source_chars.get(src_key, {}) if isinstance(source_chars.get(src_key, {}), dict) else {}
                src_pos = num_pair(src_obj.get("position", [770,100] if src_key == "bf" else [100,100] if src_key == "dad" else [400,130]))
                out_pos = num_pair(out_data.get(out_key))
                comparisons[f"{src_key}Position"] = {"source": src_pos, "legacy": out_pos, "matches": bool(src_pos and out_pos and equal_pair(src_pos, out_pos))}
                src_cam = num_pair(src_obj.get("cameraOffsets", [0, 0]))
                out_cam_key = {"bf": "camera_boyfriend", "dad": "camera_opponent", "gf": "camera_girlfriend"}[src_key]
                out_cam = num_pair(out_data.get(out_cam_key, [0, 0]))
                comparisons[f"{src_key}CameraOffsets"] = {"source": src_cam, "legacy": out_cam, "matches": bool(src_cam and out_cam and equal_pair(src_cam, out_cam))}
            stage_item["comparisons"] = comparisons
            differences = [k for k, v in comparisons.items() if not v["matches"]]
            if differences:
                stage_item["warnings"].append("Metadados de câmera/posição diferem da origem: " + ", ".join(differences) + ". Confira se a diferença foi intencional.")
        if not out_hx_path:
            stage_item["warnings"].append("Arquivo .hx do stage ausente.")
        if not out_json_path:
            stage_item["warnings"].append("Arquivo .json do stage ausente.")
        report["stages"].append(stage_item)

    for key, path in output_jsons.items():
        if key not in source_names:
            report["unmatchedOutputStages"].append(path.stem)

    # Scan every song chart JSON and verify that stage references have a matching Legacy stage JSON.
    songs_root = case_path(output / "songs")
    if songs_root and songs_root.is_dir():
        stage_refs: dict[str, list[str]] = {}
        for path in songs_root.rglob("*.json"):
            data = load_json(path)
            if not isinstance(data, dict) or path.name.casefold() == "events.json":
                continue
            stage_name = read_stage_ref(data)
            if not stage_name:
                continue
            stage_refs.setdefault(stage_name, []).append(str(path.relative_to(output)))
        present = {p.stem.casefold() for p in out_root.glob("*.json") if p.is_file()}
        for stage_name, charts in sorted(stage_refs.items(), key=lambda kv: kv[0].casefold()):
            same = stage_name.casefold() in present
            if not same:
                # Give a relaxed normalized match for diagnostic purposes only.
                normalized = slug(stage_name)
                alt = next((p.stem for p in out_root.glob("*.json") if slug(p.stem) == normalized), None)
                report["chartStageReferences"][stage_name] = {"existsExact": False, "similarStage": alt, "charts": charts}
            else:
                report["chartStageReferences"][stage_name] = {"existsExact": True, "similarStage": None, "charts": charts}
    else:
        report["warnings"].append("Não encontrei songs/ no port; não foi possível conferir os stages usados pelos charts.")

    # Summary used to quickly prioritize actual blockers.
    all_stage_warnings = []
    missing_asset_total = 0
    for item in report["stages"]:
        missing_asset_total += len(item["missingLegacyAssets"])
        for warning in item["warnings"]:
            all_stage_warnings.append({"stage": item["stage"], "warning": warning})
    report["summary"] = {
        "stagesWithWarnings": sum(1 for s in report["stages"] if s["warnings"]),
        "missingSourceAssets": sum(len(s["missingSourceAssets"]) for s in report["stages"]),
        "missingLegacyAssets": missing_asset_total,
        "missingOutputStages": len(report["missingOutputStages"]),
        "chartStageReferencesWithoutExactMatch": sum(1 for v in report["chartStageReferences"].values() if not v["existsExact"]),
        "totalWarnings": len(all_stage_warnings),
    }
    report["warnings"].extend(all_stage_warnings)

    report_path = Path(args.report).expanduser().resolve() if args.report else output / "STAGE-DIAGNOSTICS.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    txt_path = report_path.with_suffix(".txt")
    lines = [
        "HEX V3 -> LEGACY MOBILE | STAGE DIAGNOSTICS",
        f"Origem: {source}",
        f"Port: {output}",
        "",
        f"Pastas de stage na origem: {len(stage_dirs)}",
        f"JSONs de stage Legacy: {len(output_jsons)}",
        f"HScript de stage Legacy: {len(output_hxs)}",
        f"Stages com alertas: {report['summary']['stagesWithWarnings']}",
        f"Assets Legacy ausentes: {report['summary']['missingLegacyAssets']}",
        f"Referências de chart sem stage exato: {report['summary']['chartStageReferencesWithoutExactMatch']}",
        "",
        "ALERTAS POR STAGE",
    ]
    found_any = False
    for st in report["stages"]:
        if not st["warnings"] and not st["missingLegacyAssets"] and not st["missingSourceAssets"]:
            continue
        found_any = True
        lines.append(f"\n[{st['stage']}]")
        for w in st["warnings"]:
            lines.append(f"- {w}")
        for m in st["missingSourceAssets"]:
            lines.append(f"- Asset de origem não localizado: {m['assetPath']} (prop {m.get('name')})")
        for m in st["missingLegacyAssets"]:
            lines.append(f"- Asset convertido não localizado: {m}")
    if not found_any:
        lines.append("Nenhum problema estrutural óbvio foi detectado. Isso NÃO garante posições/câmeras visualmente corretas no jogo.")
    if report["missingOutputStages"]:
        lines.extend(["", "STAGES AUSENTES NO PORT"])
        for x in report["missingOutputStages"]:
            lines.append(f"- {x['stage']}: JSON ausente={x['missingJson']}, HScript ausente={x['missingHScript']}")
    unmatched_refs = [(name, val) for name, val in report["chartStageReferences"].items() if not val["existsExact"]]
    if unmatched_refs:
        lines.extend(["", "REFERÊNCIAS DE CHART SEM STAGE EXATO"])
        for name, val in unmatched_refs:
            similar = f" (similar: {val['similarStage']})" if val.get("similarStage") else ""
            lines.append(f"- {name}{similar}: {', '.join(val['charts'][:4])}")
    lines.extend(["", "IMPORTANTE: relatório somente leitura. Posições e câmeras precisam de validação visual no jogo para confirmar a correção."])
    txt_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("Diagnóstico finalizado (nenhum arquivo do stage foi alterado).")
    print(f"Stages na origem: {len(stage_dirs)} | JSONs Legacy: {len(output_jsons)} | HScripts Legacy: {len(output_hxs)}")
    print(f"Stages com alertas: {report['summary']['stagesWithWarnings']}")
    print(f"Assets ausentes na origem: {report['summary']['missingSourceAssets']}")
    print(f"Assets ausentes no port: {report['summary']['missingLegacyAssets']}")
    print(f"Charts que referenciam stage sem correspondência exata: {report['summary']['chartStageReferencesWithoutExactMatch']}")
    print(f"Relatório JSON: {report_path}")
    print(f"Relatório TXT:  {txt_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
