#!/usr/bin/env bash

RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

REPO_URL="https://raw.githubusercontent.com/AdhiHub/gitraider/main/gitraider.sh"
TOOL_NAME="gitraider"

detect_prefix() {
    if [ -d "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then
        echo "$PREFIX"
    else
        echo "/usr/local"
    fi
}

install_deps() {
    echo -e "${CYAN}[*] Checking dependencies...${RESET}"
    if ! command -v curl &>/dev/null; then
        echo -e "${YELLOW}[!] curl not found. Installing...${RESET}"
        if command -v apt &>/dev/null; then
            apt update -y && apt install curl -y
        elif command -v pkg &>/dev/null; then
            pkg install curl -y
        elif command -v yum &>/dev/null; then
            yum install curl -y
        else
            echo -e "${RED}[!] Could not install curl. Install it manually.${RESET}"
            exit 1
        fi
    fi

    if ! command -v python3 &>/dev/null; then
        echo -e "${YELLOW}[!] python3 not found. Installing...${RESET}"
        if command -v apt &>/dev/null; then
            apt install python3 -y
        elif command -v pkg &>/dev/null; then
            pkg install python -y
        else
            echo -e "${YELLOW}[!] Could not install python3. JSON parsing may fail.${RESET}"
        fi
    fi

    echo -e "${GREEN}[+] Dependencies satisfied.${RESET}"
}

do_install() {
    local prefix
    prefix=$(detect_prefix)
    local bin_dir="${prefix}/bin"

    echo -e "${CYAN}[*] Installing ${TOOL_NAME} to ${bin_dir}/${TOOL_NAME}...${RESET}"

    if command -v curl &>/dev/null; then
        curl -fsSL "$REPO_URL" -o "${bin_dir}/${TOOL_NAME}"
    elif command -v wget &>/dev/null; then
        wget -q "$REPO_URL" -O "${bin_dir}/${TOOL_NAME}"
    else
        echo -e "${RED}[!] Neither curl nor wget found. Cannot download.${RESET}"
        exit 1
    fi

    chmod +x "${bin_dir}/${TOOL_NAME}"

    if [ -f "${bin_dir}/${TOOL_NAME}" ]; then
        echo -e "${GREEN}[+] ${TOOL_NAME} installed successfully!${RESET}"
        echo -e "${GREEN}[+] Run: ${TOOL_NAME}${RESET}"
    else
        echo -e "${RED}[!] Installation failed.${RESET}"
        exit 1
    fi
}

main() {
    echo -e "${RED}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║     GITRAIDER INSTALLER v1.0         ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "${YELLOW}Use at your own risk, developer(s) assume NO liability${RESET}"
    echo ""

    install_deps
    do_install
}

main
