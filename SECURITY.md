# Security Notes

Before pushing updates, run a secret scan:

```powershell
rg -n --hidden -S "sk-|ghp_|gho_|JINA_API|RUNNINGHUB_API|API_KEY|SECRET|TOKEN|COOKIE|BEGIN (RSA|OPENSSH|PRIVATE) KEY" .
```

Expected result: only documentation examples or placeholder names should match.

Never commit:

- `.env`, `config.env`, local API keys
- browser profiles, cookies, QR login screenshots
- buyer materials or private chat screenshots
- generated marketplace publish screenshots containing sensitive account details
