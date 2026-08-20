---
title: niannian-ai error
domain: code-knowledge
source:
  - test_canvas_text_runtime.js
  - test_niannian_redraw_step01_artifact_broker_transport.js
  - test_niannian_redraw_step01_fixed_app_phase_executor.js
  - test_niannian_redraw_step01_hq_full_executor.js
  - test_niannian_redraw_step02_mac_app_dispatcher.js
  - test_niannian_step01_artifact_broker.js
  - test_niannian_step01_fixed_app_dispatch.js
  - test_execute_step01_hq_full.py
  - test_refresh_analysis_service_cost_authority.py
---

# Error

- `CANVAS_TEXT_PROVIDER_FAILED` ← test_canvas_text_runtime.js:38 [INFERRED]
  ```
  assert.equal(error.code, 'CANVAS_TEXT_PROVIDER_FAILED');
  ```
- `ARTIFACT_PACKAGE_GRANT_FAILED` ← test_niannian_redraw_step01_artifact_broker_transport.js:42 [INFERRED]
  ```
  await assert.rejects(()=>transport.downloadPackageToStaging({broker:memory,binding,staging_root:path.join(root,'bad'),manifest_grant:getManifest,file_grants:[]}),error=>error.code==='ARTIFACT_PACKAGE_GRANT_FAILED');
  ```
- `ARTIFACT_RETURN_UPLOAD_FAILED` ← test_niannian_redraw_step01_artifact_broker_transport.js:65 [INFERRED]
  ```
  await assert.rejects(()=>transport.uploadReturnToBroker({broker:memory,binding:returnBinding,expected_phase:phase,workspace_path:returnWorkspace,issue_return_grant:issueReturnGrant}),error=>error.code==='ARTIFACT_RETURN_UPLOAD_FAILED');
  ```
- `ARTIFACT_RETURN_UPLOAD_FAILED` ← test_niannian_redraw_step01_fixed_app_phase_executor.js:11 [INFERRED]
  ```
  await assert.rejects(()=>executor.pushReturnToBroker({requestId:'request-0001',phaseKey:'step01phase-'+'a'.repeat(64)}),error=>error.code==='ARTIFACT_RETURN_UPLOAD_FAILED');
  ```
- `STEP01_HQ_TOOL_FAILED` ← test_niannian_redraw_step01_hq_full_executor.js:61 [INFERRED]
  ```
  const processFailure=await executor.runProcess(process.execPath,['-e',"process.stdout.write('safe stdout marker');process.stderr.write('STEP01_HQ_TOOL_FAILED:audio_first_mimo_forced_aligner:7\\nAuthorization: Bearer fixture-bearer\\napi_key="+"sk-"+"fixturecredential123456789\\n');process.exit(7)"],{cwd:root,env:{PATH:process.env.PATH},timeoutMs:5000}).then(()=>null,error=>error);assert(processFailure);assert.equal(processFailure.diagnostic.exit_code,7);assert.match(processFailure.diagnostic.stderr.safe_tail,/audio_first_mimo_forced_aligner/);assert.match(processFailure.diagnostic.stderr.safe_tail,/\[REDACTED\]/);assert(!processFailure.diagnostic.stderr.safe_tail.includes('fixture-bearer'));assert(!processFailure.diagnostic.stderr.safe_tail.includes('fixturecredential'));
  ```
- `STEP02_APP_TARGET_TURN_COMPLETED_ERROR` ← test_niannian_redraw_step02_mac_app_dispatcher.js:63 [INFERRED]
  ```
  for(const [suffix,scenario,code] of [['terminalerror',{targetError:true},'STEP02_APP_TARGET_TURN_COMPLETED_ERROR'],['missingassistant',{missingAssistant:true},'STEP02_APP_TARGET_TURN_ASSISTANT_MISSING']]){const current=await seed(root,suffix),client=new FakeClient(current.dispatch,candidate(current.dispatch));await assert.rejects(()=>dispatcher.run({dispatchPath:path.join(current.workspace,'step02_employee_dispatch.json'),workspace:current.workspace,leaseRoot:path.join(root,'leases-'+suffix),client,testMode:true,skillRoot:current.skillRoot,afterTurnStarted:()=>{throw step02.codeError('SYNTHETIC_AFTER_JOURNAL_CRASH');}}),/SYNTHETIC_AFTER_JOURNAL_CRASH/);Object.assign(client.scenario,scenario);await expectCode(()=>dispatcher.run({dispatchPath:path.join(current.workspace,'step02_employee_dispatch.json'),workspace:current.workspace,leaseRoot:path.join(root,'leases-'+suffix),client,testMode:true,skillRoot:current.skillRoot}),code);assert.equal(client.starts,1);}
  ```
- `STEP02_APP_LEASE_RENEWAL_FAILED` ← test_niannian_redraw_step02_mac_app_dispatcher.js:65 [INFERRED]
  ```
  const heartbeatCase=await seed(root,'heartbeat'),heartbeatClient=new FakeClient(heartbeatCase.dispatch,candidate(heartbeatCase.dispatch),{waitDelay:100});let renewCalls=0;await expectCode(()=>dispatcher.run({dispatchPath:path.join(heartbeatCase.workspace,'step02_employee_dispatch.json'),workspace:heartbeatCase.workspace,leaseRoot:path.join(root,'leases-heartbeat'),client:heartbeatClient,testMode:true,skillRoot:heartbeatCase.skillRoot,leaseHeartbeatMs:20,renewLease:async()=>{renewCalls++;if(renewCalls>1)throw new Error('synthetic renew failure');}}),'STEP02_APP_LEASE_RENEWAL_FAILED');assert.equal(await fsp.stat(path.join(root,'leases-heartbeat',heartbeatCase.dispatch.employee.thread_id)).then(s=>s.isDirectory()),true);
  ```
- `ARTIFACT_RETURN_UPLOAD_FAILED` ← test_niannian_step01_artifact_broker.js:27 [INFERRED]
  ```
  const diagnostic=broker.sanitizeDiagnostic(Object.assign(new Error('ARTIFACT_RETURN_UPLOAD_FAILED'),{code:'ARTIFACT_RETURN_UPLOAD_FAILED',http_status:403,provider_code:'AccessDenied',provider_request_id_sha256:'a'.repeat(64),provider_body_sha256:'b'.repeat(64),provider_body_bytes:128}),'synthetic_probe');
  ```
- `ARTIFACT_PACKAGE_DOWNLOAD_FAILED` ← test_niannian_step01_fixed_app_dispatch.js:106 [INFERRED]
  ```
  assert.equal(transportResult.blocker.code,'ARTIFACT_PACKAGE_DOWNLOAD_FAILED');
  ```
- `AssertionError` ← test_execute_step01_hq_full.py:122 [INFERRED]
  ```
  raise AssertionError("expected explicit test environment gate")
  ```
- `AssertionError` ← test_refresh_analysis_service_cost_authority.py:34 [INFERRED]
  ```
  raise AssertionError("tampered authority was overwritten")
  ```