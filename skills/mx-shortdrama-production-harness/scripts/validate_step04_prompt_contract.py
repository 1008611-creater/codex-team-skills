#!/usr/bin/env python3
"""Deterministic, provider-free validation for the Step04 prompt contract.

The validator is intentionally independent from Word rendering and RunningHub.
It checks the boundary where verified Step02 facts become a video prompt.  A
failure means the prompt must not be rendered, uploaded, or paid for.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


MIN_DIALOGUE_MS = 120
GENERIC_CHARACTER_PATTERNS = (
    r"一名(?:成熟|年轻|深色|黑色|条纹|格纹)?(?:男子|男性|男士|男青年)",
    r"一位(?:成熟|年轻|深色|黑色|条纹|格纹)?(?:男子|男性|男士|男青年)",
    r"(?:成熟|年轻|深色|黑色|条纹|格纹)?(?:男子|男性|男士|男青年)",
    r"(?:某|一个)(?:人物|男子|男性|男士)",
    r"人物[AB](?:\b|/)",
    r"speaker_unknown",
)
GENERIC_CHARACTER_RE = re.compile("|".join(GENERIC_CHARACTER_PATTERNS))
AT_NAME_RE = re.compile(r"@[\u3400-\u9fff]{2,}")
POSITIVE_SUBTITLE_RE = re.compile(r"(?:显示|出现|保留|添加).{0,12}字幕|英文字幕|字幕随")
NEGATIVE_SUBTITLE_RE = re.compile(r"(?:不新增|不添加|不生成|禁止新增|避免新增).{0,8}字幕|不新增人物、字幕")


def load_json(path: str | Path) -> dict[str, Any]:
    value = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"JSON 根节点必须是对象: {path}")
    return value


def values(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def shot_number(value: Any) -> int:
    raw = str(value or "").strip().upper()
    raw = raw[1:] if raw.startswith("S") else raw
    return int(raw)


def card_range(card: dict[str, Any]) -> tuple[int, int]:
    start = card.get("source_start_ms", card.get("start_ms"))
    end = card.get("source_end_ms", card.get("end_ms"))
    if start is None:
        start = round(float(card.get("source_start_sec", 0)) * 1000)
    if end is None:
        end = round(float(card.get("source_end_sec", 0)) * 1000)
    return int(start), int(end)


def error(code: str, message: str, **details: Any) -> dict[str, Any]:
    return {"code": code, "message": message, "details": details}


def normalize_text(value: Any) -> str:
    return re.sub(r"\s+", "", str(value or "")).strip().lower()


def event_rows(card: dict[str, Any]) -> list[dict[str, Any]]:
    return [row for row in values(card.get("event_blocks") or card.get("events")) if isinstance(row, dict)]


def dialogue_from_event(event: dict[str, Any]) -> dict[str, Any] | None:
    dialogue = event.get("dialogue")
    return dialogue if isinstance(dialogue, dict) else None


def visual_speaker(event: dict[str, Any], dialogue: dict[str, Any]) -> str:
    for source in (dialogue, event):
        for key in (
            "visual_speaker_instance_id",
            "speaker_visual_instance_id",
            "mouth_instance_id",
            "visible_speaker_instance_id",
        ):
            value = str(source.get(key) or "").strip()
            if value:
                return value
        for key in ("onscreen_speaker_instance_ids", "visible_speaker_instance_ids"):
            raw = [str(item).strip() for item in values(source.get(key)) if str(item).strip()]
            if len(raw) == 1:
                return raw[0]
    return ""


def validate_step02_manifest(
    manifest: dict[str, Any],
    *,
    shot_ids: set[int] | None = None,
) -> list[dict[str, Any]]:
    """Validate the evidence fields that Step04 is not allowed to infer."""
    failures: list[dict[str, Any]] = []
    cards = [card for card in values(manifest.get("cards")) if isinstance(card, dict)]
    seen_dialogue: dict[tuple[int, str, str], tuple[int, int]] = {}
    previous_shot: int | None = None
    for card in cards:
        sid = shot_number(card.get("shot_id"))
        if shot_ids is not None and sid not in shot_ids:
            continue
        start_ms, end_ms = card_range(card)
        entities = [row for row in values(card.get("entity_instances") or card.get("entities")) if isinstance(row, dict)]
        entity_ids = {str(row.get("instance_id") or "") for row in entities}
        for event_index, event in enumerate(event_rows(card), start=1):
            dialogue = dialogue_from_event(event)
            if not dialogue:
                continue
            speaker = str(dialogue.get("speaker_instance_id") or dialogue.get("speaker_id") or "").strip()
            if not speaker:
                failures.append(error("STEP02_SPEAKER_BINDING_MISSING", f"S{sid:03d} E{event_index:02d} 缺少 speaker_instance_id", shot_id=sid, event_index=event_index))
                continue
            if speaker not in entity_ids:
                failures.append(error("STEP02_SPEAKER_INSTANCE_NOT_VISIBLE", f"S{sid:03d} 对白说话人不在可见实例集合", speaker=speaker, entity_ids=sorted(entity_ids)))
            mode = str(dialogue.get("mode") or "onscreen_mouth").lower()
            is_offscreen = mode in {"narration", "offscreen", "voiceover", "voice_over", "phone"}
            visual = visual_speaker(event, dialogue)
            if not is_offscreen and not visual:
                failures.append(error("STEP02_SPEAKER_VISUAL_BINDING_MISSING", f"S{sid:03d} 的口型对白没有视觉发言人绑定", speaker=speaker, event_index=event_index))
            if visual and visual != speaker and not is_offscreen:
                failures.append(error("STEP02_SPEAKER_VISUAL_CONFLICT", f"S{sid:03d} 画面发言人与对白 speaker 冲突", visual_speaker=visual, dialogue_speaker=speaker, event_index=event_index))
            timecode = dialogue.get("timecode_ms") or dialogue.get("time_ms")
            if not isinstance(timecode, list) or len(timecode) != 2:
                failures.append(error("STEP04_DIALOGUE_TIMECODE_INVALID", f"S{sid:03d} 对白缺少独立时间范围", event_index=event_index))
                continue
            try:
                d_start, d_end = int(timecode[0]), int(timecode[1])
            except (TypeError, ValueError):
                failures.append(error("STEP04_DIALOGUE_TIMECODE_INVALID", f"S{sid:03d} 对白时间范围不是整数", timecode=timecode))
                continue
            if d_start < start_ms or d_end > end_ms or d_end <= d_start:
                failures.append(error("STEP04_DIALOGUE_TIME_OUT_OF_RANGE", f"S{sid:03d} 对白时间超出镜头范围", timecode=[d_start, d_end], shot_range=[start_ms, end_ms]))
            duration = d_end - d_start
            if duration < MIN_DIALOGUE_MS:
                failures.append(error("STEP04_DIALOGUE_DURATION_IMPOSSIBLE", f"S{sid:03d} 对白只有 {duration} ms，无法执行口型和声音", duration_ms=duration, text=str(dialogue.get("text") or "")))
            text = normalize_text(dialogue.get("target_text") or dialogue.get("text") or dialogue.get("content"))
            if text:
                key = (sid, speaker, text)
                seen_dialogue[key] = (d_start, d_end)
                if previous_shot is not None and sid == previous_shot + 1:
                    for (old_sid, old_speaker, old_text), old_range in list(seen_dialogue.items()):
                        if old_sid == sid or old_speaker != speaker or old_text != text:
                            continue
                        if d_start - old_range[1] <= 600:
                            failures.append(error("STEP04_DIALOGUE_DUPLICATE", f"相邻镜头重复生成同一角色同一句台词", shot_id=sid, previous_shot=old_sid, speaker=speaker, text=str(dialogue.get("text") or "")))
        previous_shot = sid
    return failures


def validate_prompt_text(prompt: str, reference_keys: set[str] | None = None) -> list[dict[str, Any]]:
    failures: list[dict[str, Any]] = []
    text = str(prompt or "")
    generic = sorted(set(GENERIC_CHARACTER_RE.findall(text)))
    if generic:
        failures.append(error("STEP04_GENERIC_CHARACTER_REFERENCE", "生视频提示词含未绑定人物泛称", tokens=generic))
    if POSITIVE_SUBTITLE_RE.search(text) and NEGATIVE_SUBTITLE_RE.search(text):
        failures.append(error("STEP04_SUBTITLE_POLICY_CONFLICT", "提示词同时要求显示字幕和禁止新增字幕", positive=True, negative=True))
    if reference_keys is not None:
        # Chinese prose continues immediately after an @ reference (for
        # example "@男主沈川开口").  Compare known references by prefix at
        # each @ position instead of treating the whole Chinese clause as a
        # different asset name.
        mentioned: set[str] = set()
        unknown: list[str] = []
        for match in AT_NAME_RE.finditer(text):
            token = match.group(0)
            starts = [ref for ref in reference_keys if text.startswith(ref, match.start())]
            if starts:
                mentioned.add(max(starts, key=len))
            else:
                unknown.append(token)
        unknown = sorted(set(unknown))
        missing = sorted(reference_keys - mentioned)
        if unknown:
            failures.append(error("STEP04_REFERENCE_NAME_UNDECLARED", "提示词引用了未在当前生产组声明的 @ 资产", unknown=unknown))
        if missing:
            failures.append(error("STEP04_REFERENCE_DUTY_NOT_CONSUMED", "当前组上传参考图没有进入提示词正文", missing=missing))
    if re.search(r"(?:_CHAR_|_ASSET_|CHAR_|ASSET_)", text):
        failures.append(error("STEP04_PROMPT_INTERNAL_ASSET_ID", "提示词泄漏英文资产 ID"))
    return failures


def validate_ir_group(
    manifest: dict[str, Any],
    ir: dict[str, Any],
    group_id: str,
    *,
    prompt: str | None = None,
    source_start_ms: int | None = None,
    source_end_ms: int | None = None,
) -> list[dict[str, Any]]:
    failures: list[dict[str, Any]] = []
    group = next((row for row in values(ir.get("groups")) if isinstance(row, dict) and str(row.get("group_id")) == group_id), None)
    if group is None:
        return [error("STEP04_GROUP_MISSING", f"找不到生产组 {group_id}")]
    segments = [row for row in values(group.get("segments")) if isinstance(row, dict)]
    if not segments:
        failures.append(error("STEP04_GROUP_SEGMENTS_MISSING", f"{group_id} 没有小镜头段"))
        return failures
    cards = {shot_number(card.get("shot_id")): card for card in values(manifest.get("cards")) if isinstance(card, dict)}
    expected_start = min(int(row.get("start_ms")) for row in segments)
    expected_end = max(int(row.get("end_ms")) for row in segments)
    actual_start, actual_end = int(group.get("source_start_ms")), int(group.get("source_end_ms"))
    if (actual_start, actual_end) != (expected_start, expected_end):
        failures.append(error("STEP04_GROUP_INTERVAL_INTERNAL_MISMATCH", f"{group_id} 组区间与小镜头区间不一致", group=[actual_start, actual_end], segments=[expected_start, expected_end]))
    if source_start_ms is not None and source_end_ms is not None and (actual_start, actual_end) != (int(source_start_ms), int(source_end_ms)):
        failures.append(error("STEP04_SOURCE_INTERVAL_MISMATCH", f"{group_id} 源区间与权威生产区间不一致", group=[actual_start, actual_end], expected=[source_start_ms, source_end_ms]))
    reference_keys = {str(row.get("reference_key")) for row in values(group.get("references")) if str(row.get("reference_key"))}
    group_prompt = prompt if prompt is not None else str(group.get("prompt_text") or "")
    failures.extend(validate_prompt_text(group_prompt, reference_keys))
    seen_dialogue: dict[tuple[str, str], tuple[int, int, int]] = {}
    for segment in segments:
        sid = shot_number(segment.get("shot_id"))
        if sid not in cards:
            failures.append(error("STEP04_GROUP_SHOT_NOT_IN_STEP02", f"{group_id} 的 S{sid:03d} 不在 Step02 manifest"))
            continue
        card_start, card_end = card_range(cards[sid])
        seg_start, seg_end = int(segment.get("start_ms")), int(segment.get("end_ms"))
        if (seg_start, seg_end) != (card_start, card_end):
            failures.append(error("STEP04_SEGMENT_INTERVAL_MISMATCH", f"{group_id} S{sid:03d} 区间与 Step02 不一致", segment=[seg_start, seg_end], step02=[card_start, card_end]))
        role_refs = {str(value) for value in values(segment.get("role_refs")) if str(value)}
        for dialogue in [row for row in values(segment.get("dialogue")) if isinstance(row, dict)]:
            speaker = str(dialogue.get("speaker_instance_id") or "").strip()
            if not speaker:
                failures.append(error("STEP02_SPEAKER_BINDING_MISSING", f"{group_id} S{sid:03d} 对白缺 speaker_instance_id"))
            speaker_role = ""
            for entity in values(cards[sid].get("entity_instances") or cards[sid].get("entities")):
                if isinstance(entity, dict) and str(entity.get("instance_id")) == speaker:
                    speaker_role = str(entity.get("role_ref") or "")
            if speaker_role and speaker_role not in role_refs:
                failures.append(error("STEP04_SPEAKER_ROLE_MISMATCH", f"{group_id} S{sid:03d} 台词说话人不在当前段角色引用中", speaker_role=speaker_role, role_refs=sorted(role_refs)))
            timecode = dialogue.get("timecode_ms") or dialogue.get("time_ms")
            if isinstance(timecode, list) and len(timecode) == 2:
                d_start, d_end = int(timecode[0]), int(timecode[1])
                if d_end - d_start < MIN_DIALOGUE_MS:
                    failures.append(error("STEP04_DIALOGUE_DURATION_IMPOSSIBLE", f"{group_id} S{sid:03d} 对白只有 {d_end-d_start} ms", duration_ms=d_end-d_start))
                text_key = normalize_text(dialogue.get("target_text") or dialogue.get("text"))
                key = (speaker_role or speaker, text_key)
                if text_key and key in seen_dialogue and d_start - seen_dialogue[key][1] <= 600:
                    failures.append(error("STEP04_DIALOGUE_DUPLICATE", f"{group_id} 相邻段重复同角色同一句台词", shot_id=sid, previous_shot=seen_dialogue[key][2], text=dialogue.get("target_text") or dialogue.get("text")))
                if text_key:
                    seen_dialogue[key] = (d_start, d_end, sid)
    return failures


def validate_paths(
    step02_manifest: str | Path,
    step04_ir: str | Path | None = None,
    group_id: str | None = None,
    *,
    prompt: str | None = None,
    source_start_ms: int | None = None,
    source_end_ms: int | None = None,
) -> list[dict[str, Any]]:
    manifest = load_json(step02_manifest)
    ir = load_json(step04_ir) if step04_ir else None
    shot_ids: set[int] | None = None
    if ir and group_id:
        group = next((row for row in values(ir.get("groups")) if isinstance(row, dict) and str(row.get("group_id")) == group_id), None)
        if group:
            shot_ids = {shot_number(row.get("shot_id")) for row in values(group.get("segments")) if isinstance(row, dict)}
    failures = validate_step02_manifest(manifest, shot_ids=shot_ids)
    if ir and group_id:
        failures.extend(validate_ir_group(manifest, ir, group_id, prompt=prompt, source_start_ms=source_start_ms, source_end_ms=source_end_ms))
    elif prompt is not None:
        failures.extend(validate_prompt_text(prompt))
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the Step04 semantic/prompt contract without calling a Provider")
    parser.add_argument("--step02-manifest", required=True)
    parser.add_argument("--step04-ir")
    parser.add_argument("--group-id")
    parser.add_argument("--prompt")
    parser.add_argument("--prompt-file")
    parser.add_argument("--source-start-ms", type=int)
    parser.add_argument("--source-end-ms", type=int)
    parser.add_argument("--json-out")
    args = parser.parse_args()
    prompt = args.prompt
    if args.prompt_file:
        prompt = Path(args.prompt_file).read_text(encoding="utf-8")
    failures = validate_paths(args.step02_manifest, args.step04_ir, args.group_id, prompt=prompt, source_start_ms=args.source_start_ms, source_end_ms=args.source_end_ms)
    result = {"schema_version": "mx_shortdrama_step04_prompt_contract_v1", "status": "blocked" if failures else "passed", "failure_count": len(failures), "failures": failures}
    if args.json_out:
        Path(args.json_out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.json_out).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 2 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
