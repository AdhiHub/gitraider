# GITRAIDER v1.0

**GitHub Dorking Tool**

GitRaider searches GitHub for exposed secrets, API keys, passwords, and sensitive data using code search queries. Useful for OSINT and security audits.

## One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/AdhiHub/gitraider/main/install.sh | bash
```

## Features

| Feature        | Description                                           |
|----------------|-------------------------------------------------------|
| Secrets Search | Finds exposed secrets, private keys, tokens           |
| API Key Search | Scans for API keys across multiple file types         |
| Password Hunt  | Searches for hardcoded passwords in configs           |
| Custom Dork    | Run your own GitHub code search query                 |
| Token Support  | Use a GitHub token for higher rate limits (5000/hr)   |
| Report Export  | Saves all results to a timestamped file               |
| CLI + Menu     | Supports both command-line flags and menu mode        |

## Usage

### Interactive Mode
```bash
./gitraider.sh
```

### CLI Mode
```bash
# Search for secrets
./gitraider.sh --secrets

# Search for API keys
./gitraider.sh --apikeys

# Search for passwords
./gitraider.sh --passwords

# Custom dork query
./gitraider.sh --custom "password filename:.env"

# Use with GitHub token (higher rate limit)
./gitraider.sh -t ghp_your_token_here --secrets

# Help
./gitraider.sh -h
```

## Requirements

- Bash 4+
- curl
- python3 (for JSON parsing and URL encoding)

## Disclaimer

Use at your own risk, developer(s) assume NO liability. This tool is for educational purposes and authorized testing only. Unauthorized scanning of systems you do not own is illegal. You have been warned.
