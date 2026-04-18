#!/bin/bash
# =============================================================
# deploy-laptop.sh — Covo di Pandora
# Replica le configurazioni del control node (mucchina)
# su qualsiasi laptop/workstation Linux
#
# Uso: sudo bash scripts/deploy-laptop.sh
#
# Prerequisiti:
#   - dnsmasq installato
#   - NetworkManager installato
#   - interfaccia di rete collegata allo switch del lab
#
# Testato su: Arch Linux, openSUSE Tumbleweed
# Autore: tommy@mucchina-lab
# =============================================================

set -e  # esci immediatamente in caso di errore

# -------------------------------------------------------------
# Colori per output leggibile
# -------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

# -------------------------------------------------------------
# Verifica che lo script giri come root
# -------------------------------------------------------------
[ "$EUID" -ne 0 ] && fail "Eseguire come root: sudo bash $0"

# Directory base del repository
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ok "Repository: $REPO_DIR"

# -------------------------------------------------------------
# 1. dnsmasq
# -------------------------------------------------------------
echo ""
echo "==> Configurazione dnsmasq..."

if ! command -v dnsmasq &>/dev/null; then
    warn "dnsmasq non trovato — installarlo manualmente"
else
    cp "$REPO_DIR/laptop/etc/dnsmasq.conf" /etc/dnsmasq.conf
    ok "dnsmasq.conf installato"
    systemctl enable dnsmasq
    systemctl restart dnsmasq
    ok "dnsmasq avviato"
fi

# -------------------------------------------------------------
# 2. NetworkManager — split DNS
# -------------------------------------------------------------
echo ""
echo "==> Configurazione NetworkManager split DNS..."

if ! command -v nmcli &>/dev/null; then
    warn "NetworkManager non trovato — skip"
else
    mkdir -p /etc/NetworkManager/conf.d
    cp "$REPO_DIR/laptop/etc/NetworkManager/conf.d/dns-local.conf" \
       /etc/NetworkManager/conf.d/dns-local.conf
    ok "dns-local.conf installato"
    systemctl restart NetworkManager
    ok "NetworkManager riavviato"
fi

# -------------------------------------------------------------
# 3. /etc/hosts
# -------------------------------------------------------------
echo ""
echo "==> Aggiornamento /etc/hosts..."

# Aggiunge le voci .lan se non esistono già
if ! grep -q "pandora.lan" /etc/hosts; then
    echo "" >> /etc/hosts
    echo "# ===========================================" >> /etc/hosts
    echo "# Covo di Pandora — lab locale" >> /etc/hosts
    echo "# ===========================================" >> /etc/hosts
    echo "192.168.1.1    mucchina.lan mucchina" >> /etc/hosts
    echo "192.168.1.10   pandora.lan pandora" >> /etc/hosts
    echo "192.168.1.11   pandora-rescue.lan pandora-rescue" >> /etc/hosts
    ok "/etc/hosts aggiornato"
else
    warn "/etc/hosts già configurato — skip"
fi

# -------------------------------------------------------------
# 4. Verifica finale
# -------------------------------------------------------------
echo ""
echo "==> Verifica..."
ping -c1 -W2 pandora.lan &>/dev/null && ok "pandora.lan raggiungibile" || warn "pandora.lan non raggiungibile — lab connesso?"
ping -c1 -W2 1.1.1.1 &>/dev/null && ok "internet raggiungibile" || warn "internet non raggiungibile"

echo ""
ok "Deploy completato!"
echo ""
echo "Test SSH: ssh tommy@pandora.lan"
