---
name: runninghub-image2-image
description: Generate or edit images from one or more reference image URLs with the RunningHub Image G 2.0 / GPT-Image-2 low-price image-to-image channel only. Use when Codex should submit, poll, and download RunningHub Image2 low-price image-to-image jobs using RUNNINGHUB_API_KEY for restyling, product image edits, IP character refinement, or reference-guided ad visuals.
---

# RunningHub Image2 Image

Use this skill to call RunningHub Image G 2.0 image-to-image low-price channel only.

## Credentials

Read `RUNNINGHUB_API_KEY` from the current environment or from a `.env` file in the current working directory or one of its parents.

The helper scripts prefer the nearest project `.env` value for `RUNNINGHUB_API_KEY` over a stale process/global environment value. This avoids accidentally submitting with an old key.

Never place the API key in prompts, generated docs, screenshots, or final answers.

## Endpoint Policy

Only use the low-price channel. Do not use official or standard model endpoints for Image2 generation unless the user explicitly changes this policy in a later request.

## Prompt Language Policy

For Chinese livestream, e-commerce, portrait, IP character, and product-ad image work, write prompts in Chinese by default unless the user explicitly requests another language. Prefer concise, guiding language that tells Image2 the intended role, composition, constraints, and visual direction. Do not over-describe every object or texture when reference images already provide strong visual information; let Image2 use the references for identity, design judgment, and realism.

## Resolution Policy

When using this skill to generate images, default to `4k` resolution unless the user explicitly asks for another resolution such as `1k` or `2k`. Dry-runs, submitted jobs, and helper-script commands should all use `4k` by default.

```text
POST /openapi/v2/rhart-image-g-2/image-to-image
```

The task result query endpoint is:

```text
POST /openapi/v2/query
```

The low-price AI app API detail previously used for reference is:

```text
https://www.runninghub.cn/call-api/api-detail/2046503667076751361
```

## Scripts

The v2 endpoint expects public image URLs in `imageUrls`. If the user provides a local file path, first ask for or create a public URL workflow; do not pass `file://` paths.

Dry-run first:

```powershell
python C:\Users\lsb\.codex\skills\runninghub-image2-image\scripts\runninghub_image2_image.py --prompt-file .\prompt.txt --image-url "https://example.com/reference.png" --aspect-ratio 9:16 --dry-run
```

Submit and wait:

```powershell
python C:\Users\lsb\.codex\skills\runninghub-image2-image\scripts\runninghub_image2_image.py --prompt-file .\prompt.txt --image-url "https://example.com/reference.png" --aspect-ratio 9:16 --wait --download-dir .\outputs
```

Recover existing tasks without creating new generations:

```powershell
python C:\Users\lsb\.codex\skills\runninghub-image2-image\scripts\runninghub_query_tasks.py --task-id "2050211533166088194" --download-dir .\outputs\recovered
```

Useful options:

- `--prompt "..."` or `--prompt-file path`.
- `--image-url URL`; repeat it for multiple references.
- `--image-urls-file path` with one URL per line.
- `--aspect-ratio 9:16`, `1:1`, `16:9`, etc.
- `--resolution 1k|2k|4k`; default is `4k`.
- `--base-url https://www.runninghub.cn` default; switch to `.ai` if needed.
- `--dry-run` prints request payload without charging.

## Failure Recovery Rules

Network errors can happen after RunningHub has already accepted a task. An SSL EOF, connection reset, timeout, or local download failure does not prove that the generation failed.

When a submit/wait call errors after a non-dry-run attempt:

1. Do not blindly submit the same prompt again.
2. Check RunningHub call records for any new task IDs created around that time.
3. Use `runninghub_query_tasks.py` to query and download those task IDs.
4. Retry generation only after confirming no task was created or after the user explicitly wants another variant.

If RunningHub returns error `1014`, check key source first. A stale global `RUNNINGHUB_API_KEY` can override the intended project key in ad hoc commands. The helper scripts now prefer the nearest `.env`, but manually written commands should still avoid setting a conflicting `$env:RUNNINGHUB_API_KEY`.

## Workflow

1. Decide whether the reference image is strong enough for image-to-image. Weak logo-only references usually belong in text-to-image prompt exploration.
2. Use public reference image URLs.
3. Run `--dry-run`.
4. Submit with `--wait --download-dir`.
5. If the submit or wait phase errors, recover existing task IDs before retrying.
6. Record `taskId`, reference URLs, result URLs, local output paths, channel, aspect ratio, and prompt source in the project notes.

## Verified Image-to-Image Rule

When the user is troubleshooting whether image-to-image was truly used, prove it before submitting: run `--dry-run` and verify the payload contains the intended `imageUrls`. Do not treat a text prompt that merely says "use the uploaded image" as verified image-to-image. For identity-sensitive edits, start with one strongest main reference image instead of mixing many references, because extra references can cause the model to redesign the face, clothing, logo, or scene.

## Identity-Critical Stop Rule

If a low-price image-to-image result changes the person's face, hairstyle, name badge, or brand logo after the reference URLs were verified, do not keep retrying the same low-price channel by default. Treat it as a channel-fidelity problem, not just a prompt problem. For exact identity/logo work, stop and propose one of two routes: (1) user explicitly authorizes the official-stable Image G 2 image-to-image endpoint, which RunningHub documents as the higher-fidelity channel, or (2) use a local compositing/post-processing workflow that preserves the original face and pastes the original logo asset exactly.

## Logo Fidelity Note

Image2 may redraw text and logos imperfectly. If the user needs a logo to remain exactly unchanged, use the logo as an image-to-image reference for composition, then prefer a post-processing step that pastes the original logo asset back onto the generated character's badge, tag, apron, or prop. Do not rely on prompt text alone to preserve exact Chinese/English logo lettering.
