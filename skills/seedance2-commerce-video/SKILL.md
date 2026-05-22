---
name: seedance2-commerce-video
description: Create Seedance2/即梦-ready commerce IP videos for short-form selling, including persona positioning, 15-second hard/soft ad scripts, first-frame planning, reference-image upload order, image-to-video prompts, camera/lighting constraints, and iteration guidance. Use when the user mentions Seedance2, 即梦, 首帧图, 中间帧, 尾帧, 参考图, 带货视频, 女装带货, 水果带货, 快手/抖音/小红书种草, AI主播IP, or asks to turn product/model images into commerce video prompts.
---

# Seedance2 Commerce Video

## Core Rule

Build the video from conversion intent backward:

1. Define the IP, product, platform, and one conversion action.
2. Pick the minimum reference set needed to lock identity, outfit/product, and motion.
3. Write a 15-second timeline prompt, not a vague paragraph.
4. Preserve identity and product details aggressively; add negative constraints.
5. Keep Seedance2 generation clean; add subtitles, stickers, price, and calls-to-action in editing unless the user explicitly asks for in-video text.

For Seedance2 video-generation prompts, wrap the generated middle prompt with the user's fixed front/back constraint text from `references/templates.md` under "Fixed Seedance2 Video Wrapper". Do not rewrite that wrapper unless the user explicitly changes the rule.

## Default Workflow

1. **Clarify or infer the commerce task.** Identify product category, IP identity, selling platform, content style, hard/soft ad type, and desired action such as comment, follow, enter live room, or ask for link.
2. **Audit references.** Prefer fewer, stronger references. Distinguish an identity/product lock image from a true first frame. A white-background cutout or character card is not a first frame until the correct scene/background is added.
3. **Assign reference roles explicitly.** Tell Seedance2 exactly what each upload controls: identity lock, first frame, outfit/logo, product, scene, camera rhythm, or audio mood.
4. **Write the script before the prompt.** Output title/cover text, spoken copy, and the 15-second visual timeline.
5. **Write the Seedance2 prompt.** Use: aspect + duration + reference assignments + identity lock + timeline + camera + lighting + audio/voice + constraints.
6. **Create or approve the true first frame before video prompting.** If the current image lacks the intended background, treat it as `identity reference` and generate a separate `first-frame image` with the final scene.
7. **Plan extra reference images only after the true first frame is approved.** Create mid-frame/tail-frame/product/scene references when they reduce drift or support a specific shot.
8. **Iterate one variable at a time.** If output fails, change only one of: camera, motion intensity, background, product handling, or identity lock.

## Reference Strategy

Use this hierarchy:

- `@图片1`: strongest identity/product lock image, often a clean white-background portrait or character card.
- `@图片2`: true first frame with the final scene/background, used as the video starting frame when available.
- `@图片3`: optional product close-up or texture reference.
- `@图片4`: optional realistic scene/background reference.
- `@视频1`: optional camera rhythm, hand action, or UGC pacing reference.
- `@音频1`: optional voice tone, ambient sound, or beat reference.

Do not upload decorative references. Extra images often make Seedance2 invent logos, busy backgrounds, or identity drift. When the user cares about the face, say "保持@图片1中的五官、脸型、发型、表情和气质一致" near the top and again in constraints. When `@图片2` is the first frame, say "以@图片2作为首帧构图和背景".

## 15-Second Structure

Use 4 beats by default:

- `0-3秒`: hook; show face/product tension immediately.
- `3-7秒`: reveal task or problem.
- `7-11秒`: product handling, outfit detail, or emotional turn.
- `11-15秒`: soft conversion action; ask for comment, opening line, outfit choice, live-room question, or link intent.

For commerce IP content, avoid "perfect ad performance." Prefer small believable actions: glance down, laugh once, adjust apron, hesitate, compare outfits, hold product closer, or lean toward the phone.

## Prompt Quality Rules

- Use one main camera instruction, usually `前置手机自拍，轻微自然手持，整体稳定，缓慢轻微推近`.
- Separate subject action from camera movement.
- Specify lighting. Natural window light, soft studio light, or warm shop light usually beats generic "cinematic".
- Keep motion physically simple for identity-sensitive videos.
- For selfie videos, enforce physical logic: one hand holds the phone outside the frame or at the selfie edge; the other visible hand may hold the product. Do not let both hands hold the product unless explicitly requested.
- Avoid dead facial performance. Specify micro-expressions, eye movement, blinking, glancing down/up, hesitant mouth movement, nervous smile appearing and fading, and brief laugh-through-breath moments. Add "不要全程直勾勾看镜头，不要固定微笑".
- For first-person phone selfies, add subtle natural handheld motion from the phone-holding hand: small breathing shake, tiny framing drift, and slight push-in/pull-back while keeping the shot usable. Avoid tripod-still footage.
- For casual dance daily videos, do not force dialogue or product copy. Use table-placed phone logic when requested: the phone is put on a table and leaned against something, the frame is fixed with tiny unstable contact vibration, then the character returns and picks up the phone at the end. Use the dance reference video only for rhythm/body movement, not for identity, outfit, or scene.
- Use constraints: `禁止改脸、身份漂移、手指畸形、产品变形、logo错误、文字乱码、过度美颜、画面抖动`.
- For platform-native text, recommend post-editing unless Seedance2 text is central to the shot.

## Output Contract

When using this skill, deliver:

1. `参考图上传顺序` with each file's role.
2. `首帧状态判断`: whether the provided image is a true first frame or only an identity/product reference.
3. `成片目标` in one sentence.
4. `封面字/标题` if useful.
5. `口播文案` or dialogue, timed for 15 seconds.
6. `Seedance2提示词` ready to copy, including the fixed front/back constraint wrapper by default for video generation.
7. `负面约束` embedded in the prompt or separately listed.
8. `迭代建议` only when it materially improves the next generation.

For reusable templates and examples, read `references/templates.md`.
