# Security Policy

## Supported versions

`leak_sentinel` is pre-1.0. Security fixes are applied to the latest published
`0.x` release only.

## Reporting a vulnerability

`leak_sentinel` is a development-time static-analysis tool — it does not run in
production apps and has no network or runtime surface. The most likely
"security-relevant" issue is a **false-negative** (a real leak the tool fails to
flag) or a **broken auto-fix** that changes program behavior.

Please **do not** open a public issue for a suspected vulnerability. Instead:

1. Use GitHub's **private vulnerability reporting**:
   <https://github.com/FlutterForge-V1/leak_sentinel/security/advisories/new>
2. Include a minimal reproduction and the affected version.

You can expect an acknowledgement within 5 business days.
