# GITRAIDER — GitHub Dorking Tool

**Search GitHub for leaked secrets, API keys, passwords, and sensitive data.**

Part of the **AdhiHub** security toolkit.

---

## What It Does

GitRaider uses GitHub's code search to find exposed secrets in public repositories. Think of it as Google dorking, but for GitHub.

| Search Mode | What It Looks For |
|-------------|-------------------|
| Secrets | Private keys, tokens, certificates, credentials |
| API Keys | AWS keys, Google API keys, Slack tokens, Stripe keys |
| Passwords | Hardcoded passwords in config files, env files, source code |
| Custom Dork | You write your own GitHub search query |

---

## One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/AdhiHub/gitraider/main/install.sh | bash
```

After install:

```bash
gitraider
```

---

## How to Use

### Method 1: Interactive Menu

```bash
gitraider
```

Pick what you want to search for. Enter your GitHub token (optional — gives higher rate limit).

### Method 2: Command Line

```bash
# Search for secrets
gitraider --secrets

# Search for API keys
gitraider --apikeys

# Search for passwords
gitraider --passwords

# Custom dork
gitraider --custom "password filename:.env"

# With GitHub token (5000 requests/hr instead of 10)
gitraider -t ghp_your_token_here --secrets

# Help
gitraider -h
```

---

## GitHub Rate Limits

| Without Token | With Token |
|--------------|------------|
| 10 requests/min | 5000 requests/hr |

Get a token: GitHub → Settings → Developer settings → Personal access tokens

---

## Requirements

- **Linux** or **Termux** (Android)
- Bash 4+
- curl

---

## Run Without Installing

```bash
git clone https://github.com/AdhiHub/gitraider.git
cd gitraider
chmod +x gitraider.sh
./gitraider.sh
```

---

> **⚠️ DISCLAIMER: FOR EDUCATIONAL PURPOSES ONLY**
>
> Use at your own risk. Developer(s) assume NO liability.
> Only search for data on repositories you own or have permission to audit.
> GitHub's Terms of Service apply.
