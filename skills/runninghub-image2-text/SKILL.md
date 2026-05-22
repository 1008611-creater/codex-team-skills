---
name: runninghub-image2-text
description: Generate images from text prompts with the RunningHub Image G 2.0 / GPT-Image-2 low-price text-to-image channel only. Use when Codex should submit, poll, and download RunningHub Image2 low-price text-to-image jobs using RUNNINGHUB_API_KEY for ad stills, IP character concepts, e-commerce visuals, posters, or prompt iteration.
---

# RunningHub Image2 Text

Use this skill to call RunningHub Image G 2.0 text-to-image low-price channel only.

## Credentials

Read `RUNNINGHUB_API_KEY` from the current environment or from a `.env` file in the current working directory or one of its parents.

Never place the API key in prompts, generated docs, screenshots, or final answers.

## Endpoint Policy

Only use the low-price channel. Do not use official or standard model endpoints for Image2 generation unless the user explicitly changes this policy in a later request.

```text
POST /openapi/v2/rhart-image-g-2/text-to-image
```

The task result query endpoint is:

```text
POST /openapi/v2/query
```

## Script

Dry-run first to inspect the payload:

```powershell
python C:\Users\lsb\.codex\skills\runninghub-image2-text\scripts\runninghub_image2_text.py --prompt-file .\prompt.txt --aspect-ratio 9:16 --dry-run
```

Submit and wait for results:

```powershell
python C:\Users\lsb\.codex\skills\runninghub-image2-text\scripts\runninghub_image2_text.py --prompt-file .\prompt.txt --aspect-ratio 9:16 --resolution 4k --wait --download-dir .\outputs
```

Useful options:

- `--prompt "..."` or `--prompt-file path`.
- `--aspect-ratio 9:16`, `1:1`, `16:9`, etc.
- `--resolution 1k|2k|4k`.
- `--base-url https://www.runninghub.cn` default; switch to `.ai` if needed.
- `--dry-run` prints request payload without charging.

## Workflow

1. Prepare a single, complete prompt. Keep ad text as post-production text unless the exact text rendering is the goal.
2. Run `--dry-run`.
3. Submit with `--wait --download-dir`.
4. Record `taskId`, result URLs, local output paths, channel, aspect ratio, and prompt source in the project notes.
