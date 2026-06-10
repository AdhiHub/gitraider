#!/usr/bin/env bash

RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

REPORT="gitraider_report_$(date +%Y%m%d_%H%M%S).txt"
GITHUB_TOKEN=""

show_disclaimer() {
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                     DISCLAIMER                          ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ Use at your own risk, developer assume NO liability  ║"
    echo "║ This tool is for educational & authorized testing ONLY  ║"
    echo "║ Unauthorized scanning of systems you don't own is       ║"
    echo "║ ILLEGAL. You have been warned.                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

show_banner() {
    echo -e "${RED}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║       GITRAIDER v1.0                 ║"
    echo "  ║     GitHub Dorking Tool              ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${RESET}"
}

show_help() {
    echo -e "${CYAN}Usage:${RESET}"
    echo "  $0 [option] [query]"
    echo ""
    echo -e "${YELLOW}Options:${RESET}"
    echo "  -s, --secrets     Search for secrets"
    echo "  -k, --apikeys     Search for API keys"
    echo "  -p, --passwords   Search for passwords"
    echo "  -c, --custom      Custom dork query"
    echo "  -t, --token       Set GitHub token (usage: -t YOUR_TOKEN)"
    echo "  -h, --help        Show this help"
    echo ""
    echo -e "${CYAN}Examples:${RESET}"
    echo "  $0 -s"
    echo "  $0 -c \"api_key filename:.env\""
    echo "  $0 -t ghp_xxxx -s"
    echo "  $0                              Interactive menu"
    echo -e "${RESET}"
}

PYTHON_AVAILABLE=0

check_deps() {
    for cmd in curl; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}[!] $cmd is required but not installed.${RESET}"
            exit 1
        fi
    done
    if command -v python3 &>/dev/null; then
        PYTHON_AVAILABLE=1
    else
        echo -e "${YELLOW}[!] python3 not found. Results parsing will be limited.${RESET}"
    fi
}

github_search() {
    local query="$1" label="$2"
    local encoded_query
    if [ "$PYTHON_AVAILABLE" -eq 1 ]; then
        encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$query'''))" 2>/dev/null)
    fi
    if [ -z "$encoded_query" ]; then
        encoded_query=$(echo "$query" | sed 's/ /%20/g;s/:/%3A/g;s/\//%2F/g')
    fi

    echo -e "${YELLOW}[*] Searching GitHub for: $query${RESET}"
    echo "[GitRaider] $label query: $query" >> "$REPORT"
    echo "----------------------------------------" >> "$REPORT"

    local auth_header=""
    [ -n "$GITHUB_TOKEN" ] && auth_header="Authorization: token $GITHUB_TOKEN"

    local api_url="https://api.github.com/search/code?q=${encoded_query}&per_page=10"

    local response headers_file
    headers_file=$(mktemp)

    if [ -n "$auth_header" ]; then
        response=$(curl -s -H "$auth_header" -D "$headers_file" "$api_url")
    else
        response=$(curl -s -D "$headers_file" "$api_url")
    fi

    local remaining rate_limit
    remaining=$(grep -i "x-ratelimit-remaining" "$headers_file" | awk '{print $2}' | tr -d '\r')
    rate_limit=$(grep -i "x-ratelimit-limit" "$headers_file" | awk '{print $2}' | tr -d '\r')
    rm -f "$headers_file"

    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${YELLOW}[!] No token provided. Rate limit: ~10 req/min.${RESET}"
        echo -e "${YELLOW}[!] Use -t YOUR_TOKEN to increase limit to 5000/hr.${RESET}"
    else
        echo -e "${GREEN}[+] Rate limit remaining: $remaining / $rate_limit${RESET}"
    fi

    if [ "$PYTHON_AVAILABLE" -eq 1 ]; then
        echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    if not items:
        print('No results found.')
        sys.exit(0)
    for item in items[:10]:
        repo = item.get('repository', {}).get('full_name', 'unknown')
        path = item.get('path', 'unknown')
        html_url = item.get('html_url', '')
        print(f'  Repo: {repo}')
        print(f'  File: {path}')
        print(f'  URL:  {html_url}')
        print('  ---')
except json.JSONDecodeError:
        print('Failed to parse API response.')
" 2>/dev/null >> "$REPORT" || echo -e "${RED}[!] API error. Check your token or network.${RESET}"
    else
        echo "$response" | grep -o '"html_url":"[^"]*"' | head -10 >> "$REPORT"
    fi

    local result_count
    if [ "$PYTHON_AVAILABLE" -eq 1 ]; then
        result_count=$(echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(len(data.get('items', [])))
except:
    print('0')
" 2>/dev/null)
    else
        result_count=$(echo "$response" | grep -c '"html_url"')
    fi

    if [ "$result_count" -gt 0 ] 2>/dev/null; then
        echo -e "${GREEN}[+] Found $result_count results for: $query${RESET}"
    else
        echo -e "${YELLOW}[-] No results found for: $query${RESET}"
    fi

    echo "" >> "$REPORT"
}

dork_secrets() {
    local queries=(
        "secret filename:.env"
        "secret_key filename:.env"
        "SECRET_KEY"
        "secret_token"
        "client_secret"
        "api_secret"
        "aws_secret_access_key"
        "private_key"
        "-----BEGIN RSA PRIVATE KEY-----"
        "ssh-privatekey"
    )
    for q in "${queries[@]}"; do
        github_search "$q" "Secrets"
    done
}

dork_apikeys() {
    local queries=(
        "apikey"
        "api_key"
        "api-key"
        "API_KEY"
        "apiKey"
        "x-api-key"
        "api_key filename:.py"
        "api_key filename:.js"
        "api_key filename:.env"
        "api_key filename:.json"
    )
    for q in "${queries[@]}"; do
        github_search "$q" "API Keys"
    done
}

dork_passwords() {
    local queries=(
        "password filename:.env"
        "password filename:.ini"
        "DB_PASSWORD"
        "db_password"
        "dbpasswd"
        "db_pass"
        "MYSQL_PASSWORD"
        "POSTGRES_PASSWORD"
        "password filename:.cfg"
        "password filename:.conf"
    )
    for q in "${queries[@]}"; do
        github_search "$q" "Passwords"
    done
}

dork_custom() {
    echo -ne "${YELLOW}[?] Enter your GitHub dork query: ${RESET}"
    read -r query
    [ -z "$query" ] && { echo -e "${RED}[!] Query cannot be empty.${RESET}"; return; }
    github_search "$query" "Custom"
}

interactive_menu() {
    while true; do
        echo ""
        echo -e "${CYAN}╔══════════════════════════════════════╗${RESET}"
        echo -e "${CYAN}║          GITRAIDER MENU              ║${RESET}"
        echo -e "${CYAN}╠══════════════════════════════════════╣${RESET}"
        echo -e "${CYAN}║${RESET}  1) Search for secrets            ${CYAN}║${RESET}"
        echo -e "${CYAN}║${RESET}  2) Search for API keys           ${CYAN}║${RESET}"
        echo -e "${CYAN}║${RESET}  3) Search for passwords          ${CYAN}║${RESET}"
        echo -e "${CYAN}║${RESET}  4) Custom dork                   ${CYAN}║${RESET}"
        echo -e "${CYAN}║${RESET}  5) Set GitHub token              ${CYAN}║${RESET}"
        echo -e "${CYAN}║${RESET}  6) Help                          ${CYAN}║${RESET}"
        echo -e "${CYAN}║${RESET}  7) Exit                          ${CYAN}║${RESET}"
        echo -e "${CYAN}╚══════════════════════════════════════╝${RESET}"
        echo -ne "${GREEN}[?] Select option: ${RESET}"
        read -r choice

        case "$choice" in
            1) dork_secrets
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}" ;;
            2) dork_apikeys
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}" ;;
            3) dork_passwords
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}" ;;
            4) dork_custom
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}" ;;
            5)
               echo -ne "${YELLOW}[?] Enter GitHub token: ${RESET}"
               read -r token
               GITHUB_TOKEN="$token"
               echo -e "${GREEN}[+] Token set.${RESET}" ;;
            6) show_help ;;
            7) echo -e "${GREEN}[+] Exiting. Stay ethical.${RESET}"; exit 0 ;;
            *) echo -e "${RED}[!] Invalid option.${RESET}" ;;
        esac
    done
}

main() {
    show_disclaimer
    show_banner
    check_deps

    while [ $# -gt 0 ]; do
        case "$1" in
            -t|--token)
                shift; GITHUB_TOKEN="$1"; shift
                echo -e "${GREEN}[+] Token set.${RESET}" ;;
            -s|--secrets) shift; dork_secrets
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}"; exit 0 ;;
            -k|--apikeys) shift; dork_apikeys
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}"; exit 0 ;;
            -p|--passwords) shift; dork_passwords
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}"; exit 0 ;;
            -c|--custom) shift
               [ -z "$1" ] && { echo -e "${RED}[!] Missing query.${RESET}"; show_help; exit 1; }
               github_search "$1" "Custom"
               echo -e "${GREEN}[+] Report saved to: $REPORT${RESET}"; exit 0 ;;
            -h|--help) show_help; exit 0 ;;
            *) echo -e "${RED}[!] Unknown option: $1${RESET}"; show_help; exit 1 ;;
        esac
    done

    interactive_menu
}

main "$@"
