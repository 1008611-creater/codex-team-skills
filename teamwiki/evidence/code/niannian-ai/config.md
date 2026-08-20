---
title: niannian-ai config
domain: code-knowledge
source:
  - test_bootstrap_mac_bridge_release.js
  - test_canvas_h3_runtime.js
  - test_codex_worker_dispatcher.js
  - test_install_mac_bridge_release.js
  - test_mac_codex_app_fixed_thread_turn.js
  - test_mac_skill_bundle_install.js
  - test_media_preflight.js
  - test_niannian_mac_bridge_install_release_runner.js
  - test_niannian_mac_user_action_bridge.js
  - test_niannian_redraw_step01_hq_full_executor.js
  - test_niannian_redraw_step01_mac_app_dispatcher.js
  - test_niannian_redraw_step01_mac_app_phase.js
  - test_niannian_redraw_step02_vertical.js
  - test_niannian_redraw_step02_windows_mac_phase_carrier.js
  - test_niannian_step01_hq_readback_sync.js
  - test_niannian_step01_server_executor.js
  - test_nomi_h3_multiref_contract.js
  - test_promote_step01_hq_full_toolchain.js
  - test_redraw_project_isolation.js
  - test_redraw_step01_flow.js
  - test_execute_step01_hq_full.py
---

# Config

- `process.env.NIANNIAN_MAC_BRIDGE_INSTALL_TEST_MODE` ← test_bootstrap_mac_bridge_release.js:4 [EXTRACTED]
  ```
  async function main(){const root=await fsp.mkdtemp(path.join(os.tmpdir(),'niannian-bootstrap-'));process.env.NIANNIAN_MAC_BRIDGE_INSTALL_TEST_MODE='1';try{const bundle=await release.buildReleaseBundle({sourceRoot:__dirname,bundleRoot:path.join(root,'bundle')});const result=await bootstrap.runBootstrap({testMode:true,projectRoot:path.join(root,'target'),bundleRoot:bundle.bundle_root,bundleBridgeDirectory:path.join(bundle.bundle_root,'bridge'),receiptPath:path.join(root,'target','receipt.json')});assert.equal(result.status,'installed_verified');await assert.rejects(()=>bootstrap.runBootstrap({testMode:true,projectRoot:path.join(root,'target2'),bundleRoot:bundle.bundle_root,bundleBridgeDirectory:path.join(root,'wrong')}),/location_rejected/);assert.throws(()=>bootstrap.assertBootstrapLocation(path.join(root,'wrong')),/location_rejected/);}finally{delete process.env.NIANNIAN_MAC_BRIDGE_INSTALL_TEST_MODE;await fsp.rm(root,{recursive:true,force:true});}process.stdout.write(JSON.stringify({ok:true,verified:['bundle-root bootstrap installs into distinct canonical target','wrong bootstrap location rejected','no bootstrap arguments accepted in production entrypoint']})+'\n');}main().catch(e=>{process.stderr.write(String(e.stack||e)+'\n');process.exitCode=1;});
  ```
- `process.env.NOMI_RUNNINGHUB_H3_API_KEY` ← test_canvas_h3_runtime.js:28 [EXTRACTED]
  ```
  const previousConsumerKey = process.env.NOMI_RUNNINGHUB_H3_API_KEY;
  ```
- `process.env.RUNNINGHUB_API_KEY` ← test_canvas_h3_runtime.js:29 [EXTRACTED]
  ```
  const previousGenericKey = process.env.RUNNINGHUB_API_KEY;
  ```
- `process.env.NIANNIAN_WORKER_DISPATCH_PATH` ← test_codex_worker_dispatcher.js:97 [EXTRACTED]
  ```
  "const dispatch = JSON.parse(fs.readFileSync(process.env.NIANNIAN_WORKER_DISPATCH_PATH, 'utf8'));",
  ```
- `process.env.NIANNIAN_WORKER_JOB_ROOT` ← test_codex_worker_dispatcher.js:98 [EXTRACTED]
  ```
  "const statusPath = path.join(process.env.NIANNIAN_WORKER_JOB_ROOT, 'status.json');",
  ```
- `process.env.NIANNIAN_WORKER_RECEIPT_PATH` ← test_codex_worker_dispatcher.js:111 [EXTRACTED]
  ```
  "fs.writeFileSync(process.env.NIANNIAN_WORKER_RECEIPT_PATH, JSON.stringify({schema_version:1,job_id:dispatch.job_id,dispatch_id:dispatch.dispatch_id,production_status:'running_step01',worker_status:'active',current_node:'Step01',next_skill:'mx-shortdrama-01-frame-extract',next_action:status.next_action,provider_submission_requested:false,package_send_requested:false,updated_at:updatedAt}, null, 2) + '\\n');",
  ```
- `process.env.NIANNIAN_WORKER_FINAL_MESSAGE_PATH` ← test_codex_worker_dispatcher.js:112 [EXTRACTED]
  ```
  "fs.writeFileSync(process.env.NIANNIAN_WORKER_FINAL_MESSAGE_PATH, 'Fake Codex worker completed safe Step01 intake.\\n');",
  ```
- `process.env.NIANNIAN_MAC_BRIDGE_INSTALL_TEST_MODE` ← test_install_mac_bridge_release.js:4 [EXTRACTED]
  ```
  async function main(){const root=await fsp.mkdtemp(path.join(os.tmpdir(),'niannian-bridge-install-'));process.env.NIANNIAN_MAC_BRIDGE_INSTALL_TEST_MODE='1';try{const bundle=await release.buildReleaseBundle({sourceRoot:__dirname,bundleRoot:path.join(root,'bundle')});for(const file of release.BRIDGE_FILE_ALLOWLIST){const target=path.join(root,...file.split('/'));await fsp.mkdir(path.dirname(target),{recursive:true});await fsp.writeFile(target,'old-'+file);}
  ```
- `process.env.KRILL_CODEX_API_KEY` ← test_mac_codex_app_fixed_thread_turn.js:47 [EXTRACTED]
  ```
  const previousKrill=process.env.KRILL_CODEX_API_KEY,previousOpenAi=process.env.OPENAI_API_KEY;delete process.env.KRILL_CODEX_API_KEY;delete process.env.OPENAI_API_KEY;const envResult=fixed.ensureEmployeeModelRuntime();assert.equal(envResult.source,'codex_home_account_session');assert.equal(envResult.launch_mode,'native_account');assert.deepEqual(envResult.env_key_names,[]);assert.equal(envResult.raw_auth_read,false);assert.equal(process.env.KRILL_CODEX_API_KEY,undefined);assert.equal(process.env.OPENAI_API_KEY,undefined);if(previousKrill===undefined)delete process.env.KRILL_CODEX_API_KEY;else process.env.KRILL_CODEX_API_KEY=previousKrill;if(previousOpenAi===undefined)delete process.env.OPENAI_API_KEY;else process.env.OPENAI_API_KEY=previousOpenAi;
  ```
- `process.env.NIANNIAN_SKILL_INSTALL_TEST_MODE` ← test_mac_skill_bundle_install.js:27 [EXTRACTED]
  ```
  process.env.NIANNIAN_SKILL_INSTALL_TEST_MODE='1';
  ```
- `process.env.FFMPEG_PATH` ← test_media_preflight.js:55 [EXTRACTED]
  ```
  const ffmpegPath = process.env.FFMPEG_PATH || 'ffmpeg';
  ```
- `process.env.NIANNIAN_FFPROBE_PATH` ← test_media_preflight.js:56 [EXTRACTED]
  ```
  const ffprobePath = process.env.NIANNIAN_FFPROBE_PATH || 'ffprobe';
  ```
- `process.env.NIANNIAN_MAC_BRIDGE_INSTALL_RELAY_TEST_MODE` ← test_niannian_mac_bridge_install_release_runner.js:11 [EXTRACTED]
  ```
  async function main(){const root=await fsp.mkdtemp(path.join(os.tmpdir(),'niannian-install-relay-'));process.env.NIANNIAN_MAC_BRIDGE_INSTALL_RELAY_TEST_MODE='1';try{const scriptPath=path.join(root,'bridge','pull_mac_bridge_bootstrap.sh'),statePath=path.join(root,'output','mac-employee-training','mac-bridge-release-state.json'),installReceiptPath=path.join(root,'output','mac-employee-training','mac-bridge-release-install-receipt.json'),receiptPath=path.join(root,'receipts','install-1.json'),releaseVersion='2026.07.18.8',manifest='a'.repeat(64),archive='b'.repeat(64);await fsp.mkdir(path.dirname(scriptPath),{recursive:true});await fsp.writeFile(scriptPath,'#!/bin/bash\nexit 0\n');await writeJson(statePath,{schema_version:'niannian_mac_bridge_install_state_v1',status:'installed_verified',release_version:releaseVersion,manifest_sha256:manifest,installed_at:'2026-07-18T00:00:00.000Z'});await writeJson(installReceiptPath,{schema_version:'niannian_mac_bridge_install_receipt_v1',status:'installed_verified',release_version:releaseVersion,manifest_sha256:manifest,secret_output:false,provider_network_requested:false,provider_submit_requested:false,project_media_processed:false,real_delivery:false});let capturedEnv;const spawn=(command,args,options)=>{capturedEnv=options.env;return spawnOk();};const options={requestId:'install-release-test-1',releaseVersion,manifestSha256:manifest,archiveSha256:archive,testMode:true,projectRoot:root,scriptPath,statePath,installReceiptPath,receiptPath,spawn};const result=await runner.runInstall(options);assert.equal(result.status,'installed_verified');assert.equal(result.receipt.arbitrary_command_allowed,false);assert.equal(result.receipt.shell_surface,'fixed_script_only');assert.equal(capturedEnv.NIANNIAN_EXPECTED_RELEASE_VERSION,releaseVersion);assert.equal(capturedEnv.NIANNIAN_EXPECTED_MANIFEST_SHA256,manifest);assert.equal(capturedEnv.NIANNIAN_EXPECTED_ARCHIVE_SHA256,archive);if(process.platform!=='win32')assert.equal((await fsp.stat(receiptPath)).mode&0o777,0o600);const replay=await runner.runInstall(options);assert.equal(replay.status,'replayed');await assert.rejects(()=>runner.runInstall({...options,archiveSha256:'c'.repeat(64)}),/replay_conflict/);await assert.rejects(()=>runner.runInstall({...options,requestId:'install-release-test-2',releaseVersion:'bad'}),/version_invalid/);await assert.rejects(()=>runner.runInstall({...options,requestId:'install-release-test-3',testMode:false}),/override_forbidden/);const badReceiptPath=path.join(root,'receipts','bad.json');await writeJson(installReceiptPath,{schema_version:'niannian_mac_bridge_install_receipt_v1',status:'installed_verified',release_version:releaseVersion,manifest_sha256:manifest,secret_output:false,provider_network_requested:false,provider_submit_requested:true,project_media_processed:false,real_delivery:false});await assert.rejects(()=>runner.runInstall({...options,requestId:'install-release-test-4',receiptPath:badReceiptPath}),/readback_invalid/);process.stdout.write(JSON.stringify({ok:true,verified:['fixed script only','exact release identity','expected identity passed to pull verifier','mode-600 receipt on Mac','replay and conflict','override rejection','provider side-effect rejection']})+'\n');}finally{delete process.env.NIANNIAN_MAC_BRIDGE_INSTALL_RELAY_TEST_MODE;await fsp.rm(root,{recursive:true,force:true});}}
  ```
- `process.env.TEST_MARKER` ← test_niannian_mac_user_action_bridge.js:22 [EXTRACTED]
  ```
  process.env.TEST_MARKER = markerPath;
  ```
- `process.env.NIANNIAN_MAC_ACTION_SHELL` ← test_niannian_mac_user_action_bridge.js:23 [EXTRACTED]
  ```
  process.env.NIANNIAN_MAC_ACTION_SHELL = 'C:\\Program Files\\Git\\bin\\bash.exe';
  ```
- `process.env.NIANNIAN_STEP01_CONTRACT_TEST_MODE` ← test_niannian_redraw_step01_hq_full_executor.js:56 [EXTRACTED]
  ```
  process.env.NIANNIAN_STEP01_CONTRACT_TEST_MODE='1';
  ```
- `process.env.PATH` ← test_niannian_redraw_step01_hq_full_executor.js:61 [EXTRACTED]
  ```
  const processFailure=await executor.runProcess(process.execPath,['-e',"process.stdout.write('safe stdout marker');process.stderr.write('STEP01_HQ_TOOL_FAILED:audio_first_mimo_forced_aligner:7\\nAuthorization: Bearer fixture-bearer\\napi_key="+"sk-"+"fixturecredential123456789\\n');process.exit(7)"],{cwd:root,env:{PATH:process.env.PATH},timeoutMs:5000}).then(()=>null,error=>error);assert(processFailure);assert.equal(processFailure.diagnostic.exit_code,7);assert.match(processFailure.diagnostic.stderr.safe_tail,/audio_first_mimo_forced_aligner/);assert.match(processFailure.diagnostic.stderr.safe_tail,/\[REDACTED\]/);assert(!processFailure.diagnostic.stderr.safe_tail.includes('fixture-bearer'));assert(!processFailure.diagnostic.stderr.safe_tail.includes('fixturecredential'));
  ```
- `process.env.NIANNIAN_STEP01_PHASE_TEST_MODE` ← test_niannian_redraw_step01_mac_app_dispatcher.js:38 [EXTRACTED]
  ```
  async function main(){const root=await fsp.mkdtemp(path.join(os.tmpdir(),'niannian-step01-app-dispatch-'));process.env.NIANNIAN_STEP01_PHASE_TEST_MODE='1';process.env.NIANNIAN_STEP01_DISPATCH_TEST_MODE='1';try{const pre=null;const configPath=path.join(root,'config.toml');await fsp.writeFile(configPath,'model_provider = "codex_local_access"\n[model_providers.codex_local_access]\nwire_api = "responses"\nenv_key = "KRILL_CODEX_API_KEY"\nrequires_openai_auth = false\n','utf8');
  ```
- `process.env.NIANNIAN_STEP01_PHASE_TEST_MODE` ← test_niannian_redraw_step01_mac_app_phase.js:54 [EXTRACTED]
  ```
  process.env.NIANNIAN_STEP01_PHASE_TEST_MODE='1';
  ```
- `process.env.NIANNIAN_STEP02_FAKE_TRANSPORT` ← test_niannian_redraw_step02_vertical.js:130 [EXTRACTED]
  ```
  const previousFake = process.env.NIANNIAN_STEP02_FAKE_TRANSPORT;
  ```
- `process.env.NIANNIAN_STEP02_SIGNED_FIXTURE` ← test_niannian_redraw_step02_vertical.js:131 [EXTRACTED]
  ```
  const previousSigned = process.env.NIANNIAN_STEP02_SIGNED_FIXTURE;
  ```
- `process.env.NIANNIAN_FORBIDDEN_SENTINEL` ← test_niannian_redraw_step02_windows_mac_phase_carrier.js:16 [EXTRACTED]
  ```
  async function main(){const root=await fsp.mkdtemp(path.join(os.tmpdir(),'step02-carrier-'));const oldSentinel=process.env.NIANNIAN_FORBIDDEN_SENTINEL;try{
  ```
- `process.env.NIANNIAN_STEP02_CARRIER_ENABLED` ← test_niannian_redraw_step02_windows_mac_phase_carrier.js:23 [EXTRACTED]
  ```
  const oldEnabled=process.env.NIANNIAN_STEP02_CARRIER_ENABLED;delete process.env.NIANNIAN_STEP02_CARRIER_ENABLED;await assert.rejects(()=>carrier.runCarrier({project:{id:'NN-X',ownerId:'owner'},jobRoot:root,ownerId:'owner',ownerActionEventId:'action'}),error=>error.code==='STEP02_CARRIER_PRODUCTION_DISABLED');if(oldEnabled!==undefined)process.env.NIANNIAN_STEP02_CARRIER_ENABLED=oldEnabled;
  ```
- `process.env.NIANNIAN_CANONICAL_DATA_ROOT` ← test_niannian_step01_hq_readback_sync.js:27 [EXTRACTED]
  ```
  process.env.NIANNIAN_CANONICAL_DATA_ROOT = dataRoot;
  ```
- `process.env.NIANNIAN_FFMPEG_PATH` ← test_niannian_step01_server_executor.js:81 [EXTRACTED]
  ```
  await command(process.env.NIANNIAN_FFMPEG_PATH || 'ffmpeg', ['-y','-f','lavfi','-i','color=c=blue:s=320x568:d=2','-f','lavfi','-i','anullsrc=r=16000:cl=mono','-shortest','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac',sourcePath]);
  ```
- `process.env.NOMI_RUNNINGHUB_H3_API_KEY` ← test_nomi_h3_multiref_contract.js:62 [EXTRACTED]
  ```
  const originalConsumerKey = process.env.NOMI_RUNNINGHUB_H3_API_KEY;
  ```
- `process.env.RUNNINGHUB_API_KEY` ← test_nomi_h3_multiref_contract.js:63 [EXTRACTED]
  ```
  const originalGenericKey = process.env.RUNNINGHUB_API_KEY;
  ```
- `process.env.NIANNIAN_STEP01_TOOLCHAIN_PROMOTION_TEST_MODE` ← test_promote_step01_hq_full_toolchain.js:23 [EXTRACTED]
  ```
  async function main(){const root=await fsp.mkdtemp(path.join(os.tmpdir(),'step01-hq-promote-'));process.env.NIANNIAN_STEP01_TOOLCHAIN_PROMOTION_TEST_MODE='1';try{assert.equal(promoter.DEFAULTS.adoption.replaceAll('\\','/'),'/Users/lsb/AI-Brain/niannian-ai-canonical-local/output/mac-employee-training/v2.0.3-adoption-r2/adoption-manifest.json');const good=await fixture(path.join(root,'good'));const result=await promoter.promote({...good.options,nowMs:good.now});assert.equal(result.status,'accepted');assert.notEqual(result.accepted_contract.exact_path,result.candidate_contract.exact_path);const accepted=JSON.parse(await fsp.readFile(result.accepted_contract.exact_path));assert.equal(accepted.settings_binding.version,2);const bad=await fixture(path.join(root,'bad'),{entrypointBinding:'0'.repeat(64)});await assert.rejects(()=>promoter.promote({...bad.options,nowMs:bad.now}),/promotion_binding_invalid/);const stale=await fixture(path.join(root,'stale'),{stale:true});assert.equal((await promoter.promote({...stale.options,nowMs:stale.now})).status,'accepted');delete process.env.NIANNIAN_STEP01_TOOLCHAIN_PROMOTION_TEST_MODE;await assert.rejects(()=>promoter.promote({testMode:true,projectRoot:root}),/promotion_override_forbidden/);process.env.NIANNIAN_STEP01_TOOLCHAIN_PROMOTION_TEST_MODE='1';process.stdout.write(JSON.stringify({ok:true,verified:['production default v2.0.3 adoption-r2 path','candidate remains immutable','accepted contract exact receipt bindings','valid v2 gate bindings required','expired health telemetry does not block promotion','production overrides rejected']})+'\n');}finally{delete process.env.NIANNIAN_STEP01_TOOLCHAIN_PROMOTION_TEST_MODE;await fsp.rm(root,{recursive:true,force:true});}}
  ```
- `process.env.FFMPEG_PATH` ← test_redraw_project_isolation.js:30 [EXTRACTED]
  ```
  await run(process.env.FFMPEG_PATH||'ffmpeg',['-y','-f','lavfi','-i','color=c=black:s=320x180:r=24','-f','lavfi','-i','sine=frequency=500:sample_rate=48000','-t','16','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac',video]);
  ```
- `process.env.NIANNIAN_FFMPEG_PATH` ← test_redraw_step01_flow.js:23 [EXTRACTED]
  ```
  await run(process.env.NIANNIAN_FFMPEG_PATH||'ffmpeg',['-y','-f','lavfi','-i','color=c=black:s=320x568:d=16','-f','lavfi','-i','anullsrc=r=16000:cl=mono','-shortest','-c:v','libx264','-pix_fmt','yuv420p','-c:a','aac',videoPath]);
  ```
- `MX_STEP01_TEST_MODE` ← test_execute_step01_hq_full.py:125 [EXTRACTED]
  ```
  os.environ["MX_STEP01_TEST_MODE"] = "1"
  ```