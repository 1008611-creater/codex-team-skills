## Team Codex Skills

This repository is the shared team package for Codex skills, onboarding prompts, and reusable AI workflow playbooks.

Before doing non-trivial work in this repository:

- Read `README.md`, `SKILLS_INDEX.md`, and the relevant `skills/<skill-name>/SKILL.md`.
- If the task changes shared rules, onboarding, publishing workflows, or skill behavior, treat it as team-impacting work and verify the install path before claiming it is complete.
- Keep changes small and traceable. Do not casually rewrite unrelated skills.

## Skill Selection

Use the local team skills instead of generic reasoning when a task clearly matches one of them:

- Long-term memory, continuity, cross-thread work: `codex-agent-mem`
- Three-window / multi-role complex work: `agent-team-workflow`
- Web research and page reading: `jina-search`
- Xianyu / Goofish demand mining and listing packs: `xianyu-ai-demand-radar`, `xianyu-product-publisher`
- Douyin / Kuaishou content and publishing prep: `douyin-workflow-orchestrator`, `kuaishou-content-pipeline`
- Image2 / GPT Image 2 / RunningHub image generation: `image2-direct`, `runninghub-image2-text`, `runninghub-image2-image`, `beecode-image2`, `ikun-image2`
- Digital human, commerce video, Seedance2, RunningHub video: `seedance2-commerce-video`, `runninghub-fruit-commerce-video`, `pexoai-agent`
- Figma and frontend design: `figma-*`, `frontend-design`, `impeccable`
- Documents, PDFs, screenshots, security reviews: `doc`, `pdf`, `screenshot`, `security-best-practices`, `security-threat-model`

## Team Safety Rules

- Never commit or paste API keys, cookies, login state, account passwords, QR codes, private keys, `.env`, or `config.env`.
- Only commit safe examples such as `config.env.example`.
- Do not automate final publish, payment, deletion, account setting changes, or irreversible platform actions without explicit user confirmation.
- Do not use competitor product images directly in publishable assets; create original images or clearly authorized assets.
- Do not build workflows for platform abuse, spam, account trading, verification bypassing, unauthorized face use, or privacy invasion.

## Onboarding

New members should start with:

```text
skills/README.md
skills/TEAM_ONBOARDING_PROMPT.md
```

Then run the dry-run installer first:

```powershell
.\skills\install-team-skills.ps1 -DryRun
```

Install only after the dry-run list looks correct.

