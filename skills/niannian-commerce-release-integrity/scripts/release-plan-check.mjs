import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const planPath = process.argv[2];
if (!planPath) {
  console.error("Usage: node release-plan-check.mjs <release-plan.json>");
  process.exit(2);
}

let plan;
try {
  plan = JSON.parse(readFileSync(resolve(planPath), "utf8"));
} catch (error) {
  console.error(`Cannot read release plan: ${error.message}`);
  process.exit(2);
}

const errors = [];
const requireString = (value, label) => {
  if (typeof value !== "string" || value.trim().length === 0) errors.push(`${label} must be a non-empty string`);
};
const requireArray = (value, label) => {
  if (!Array.isArray(value) || value.length === 0) errors.push(`${label} must be a non-empty array`);
};

requireString(plan?.target?.domain, "target.domain");
requireString(plan?.target?.product, "target.product");
if (plan?.target?.domain !== "https://dh.cauai.fun") {
  errors.push("target.domain must be https://dh.cauai.fun for this skill");
}
if (plan?.target?.product !== "niannian-commerce") {
  errors.push("target.product must be niannian-commerce for this skill");
}

requireString(plan?.onlineBaseline?.releaseId, "onlineBaseline.releaseId");
requireString(plan?.onlineBaseline?.sourceRoot, "onlineBaseline.sourceRoot");
requireString(plan?.onlineBaseline?.publicUrl, "onlineBaseline.publicUrl");
requireString(plan?.onlineBaseline?.capturedAt, "onlineBaseline.capturedAt");
if (!plan?.onlineBaseline?.publicUrl?.startsWith(plan?.target?.domain ?? "")) {
  errors.push("onlineBaseline.publicUrl must belong to target.domain");
}
requireArray(plan?.onlineBaseline?.assets, "onlineBaseline.assets");
for (const [index, asset] of (plan?.onlineBaseline?.assets ?? []).entries()) {
  requireString(asset?.path, `onlineBaseline.assets[${index}].path`);
  requireString(asset?.url, `onlineBaseline.assets[${index}].url`);
  requireString(asset?.sha256, `onlineBaseline.assets[${index}].sha256`);
}

requireString(plan?.candidate?.id, "candidate.id");
requireString(plan?.candidate?.parentReleaseId, "candidate.parentReleaseId");
requireString(plan?.candidate?.sourceRoot, "candidate.sourceRoot");
requireString(plan?.candidate?.scope, "candidate.scope");
requireArray(plan?.candidate?.allowedPaths, "candidate.allowedPaths");
requireArray(plan?.candidate?.protectedSurfaces, "candidate.protectedSurfaces");
if (plan?.candidate?.parentReleaseId !== plan?.onlineBaseline?.releaseId) {
  errors.push("candidate.parentReleaseId must equal onlineBaseline.releaseId");
}

requireString(plan?.deployment?.composeProject, "deployment.composeProject");
requireString(plan?.deployment?.service, "deployment.service");
requireString(plan?.deployment?.image, "deployment.image");
if (plan?.deployment?.forbidBindMounts !== true) errors.push("deployment.forbidBindMounts must be true");

requireString(plan?.verification?.desktop, "verification.desktop");
requireString(plan?.verification?.mobile, "verification.mobile");
requireArray(plan?.verification?.userFlows, "verification.userFlows");

if (errors.length > 0) {
  console.error("Release plan rejected:");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Release plan accepted: ${plan.candidate.id} from ${plan.onlineBaseline.releaseId}`);
console.log(`Protected surfaces: ${plan.candidate.protectedSurfaces.join(", ")}`);
