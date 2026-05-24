# 📚 Yoda Moments — Linux per aspiranti Jedi
## Covo di Pandora — Raccolta delle perle di saggezza

*Estratti dalle sessioni di studio e laboratorio*
*Autore: Tommy Atzeni (IW5DPW) con Maestro Yoda AI*
*Aggiornato: Maggio 2026*

---

## 1. Il Prompt del Terminale — La tua bussola

Il prompt è la tua **bussola** — deve dirti sempre dove sei.
Un prompt mal configurato su macchine diverse causa errori gravi (comandi eseguiti sulla macchina sbagliata).

Schema consigliato per il Covo di Pandora:
```
mucchina  → verde   (control node MTOC, "sicuro")
pandora   → giallo  (hypervisor, "attenzione")
proxmox   → rosso   (produzione, "massima attenzione")
VM guest  → ciano   (ambienti di test)
```

Configurazione in `~/.bashrc`:
```bash
# Prompt rosso per server produzione
PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '
```

> *"Su server critici molti sysadmin mettono il prompt rosso — promemoria visivo: sei su produzione"*

---

## 2. /etc/nsswitch.conf — Chi comanda la risoluzione dei nomi

NSS (Name Service Switch) — il meccanismo con cui il sistema decide **dove** cercare le informazioni quando risolve nomi, utenti, gruppi, servizi.

```bash
cat /etc/nsswitch.conf
# La riga chiave:
hosts: myhostname files mdns4_minimal dns
```

La catena per `hosts`:
1. `myhostname` — risolvi il nome locale del sistema
2. `files` — guarda `/etc/hosts`
3. `mdns4_minimal` — prova mDNS per `.local` ← perché .local è problematico!
4. `dns` — usa il resolver configurato

> *"Chi controlla nsswitch.conf controlla come il sistema trova qualsiasi risorsa"*

**Libri consigliati:**
- "DNS and BIND" — Cricket Liu, Paul Albitz (O'Reilly)

---

## 3. /etc/hosts — La rete di sicurezza definitiva

`/etc/hosts` ha **priorità assoluta** su qualsiasi DNS.
Funziona offline, funziona senza dnsmasq, funziona in qualsiasi condizione.

```
Ordine di risoluzione:
/etc/hosts        ← primo, sempre, nessuna eccezione
dnsmasq locale    ← secondo
DNS upstream      ← terzo (1.1.1.1, 8.8.8.8)
```

> *"Il ping a mucchina.lan con RTT 0.038ms — il sistema risolve il suo stesso nome senza uscire sulla LAN. Questo dimostra che /etc/hosts viene letto prima di qualsiasi DNS"*

---

## 4. .local vs .lan vs altri suffissi DNS locali

| Suffisso | Standard | Problema | Consiglio |
|----------|----------|----------|-----------|
| `.local` | RFC 6762 (mDNS) | Interferisce con Bonjour/avahi | ❌ Evitare |
| `.lan` | Non standard | Nessuno | ✅ Usare |
| `.home.arpa` | RFC 8375 | Poco usato | 🔶 Futuro |
| `.internal` | Enterprise | Nessuno | ✅ Enterprise |

> *".lan scelto deliberatamente per evitare conflitti con .local (riservato mDNS/Bonjour)"*

---

## 5. Conventional Commits — Storia leggibile

Formato standard per i commit Git: `tipo: descrizione breve`

Tipi comuni: `feat`, `fix`, `docs`, `refactor`, `init`, `scripts`

```bash
git commit -m "init: struttura repository covo-di-pandora"
git commit -m "laptop: configurazione dnsmasq split DNS con dominio .lan"
git commit -m "scripts: aggiunto net-client — mobile lab router script"
```

> *"Quando guardi la history capisci immediatamente cosa è cambiato senza aprire il diff"*

---

## 6. Bash scripting — Tre regole fondamentali

### Regola 1: `set -e`
```bash
set -e  # Esci immediatamente se un comando fallisce
```
Prima riga di ogni script serio. Senza, uno script continua dopo un errore e può combinare guai peggiori.

### Regola 2: Verifica esplicita
Dopo aver eseguito un comando, verifica che abbia funzionato:
```bash
if ! ip addr show "$LAN_IF" | grep -q "192.168.1.1"; then
    echo "[ERRORE] Failed to configure $LAN_IF"
    exit 1
fi
```
Non assumere che il comando sia andato bene.

### Regola 3: Gestione conflitti di porta
Esempio: conflitto porta 53 tra NetworkManager interno e dnsmasq esterno.
Chi non conosce questo conflitto perde ore. La soluzione: fermare NM prima di avviare dnsmasq.

---

## 7. LVM Thin Provisioning

`local-lvm` in Proxmox usa **LVM thin provisioning** — le VM dichiarano X GB di disco ma lo spazio viene allocato solo quando viene scritto.

Una VM da 20GB non occupa 20GB subito — occupa solo quello che usa davvero.

È lo stesso principio dei file `.qcow2` sparse su btrfs, implementato a livello LVM.

---

## 8. La guerra del DNS — systemd vs sistemi senza systemd

**Il problema fondamentale con systemd:**
```
Sistemi con systemd:
├── systemd-resolved    vuole il DNS
├── NetworkManager      vuole il DNS
├── Tailscale           vuole il DNS
├── dnsmasq             vuole il DNS
└── tutti scrivono /etc/resolv.conf → CHAOS
```

**Sistemi senza systemd (Void/runit, Alpine/OpenRC):**
```
├── /etc/resolv.conf    scritto UNA volta
├── dnsmasq             lo gestisce lui
└── tutto il resto      si fa i fatti propri → ORDINE
```

> *"Le distro minimali senza systemd gestiscono questa cosa in modo impeccabile. Le altre ti costringono a fare accrocchi patchati"*

**Principio fondamentale Unix:**
> *"Do one thing and do it well"*
> Tailscale deve gestire la VPN mesh, non il DNS del sistema.
> dnsmasq deve gestire il DNS locale.
> Ognuno nel suo dominio.

---

## 9. Scegli la distro in base al ruolo

> *"Scegli la distro in base al ruolo della macchina, non per ideologia"*

| Ruolo | Distro consigliata | Motivo |
|-------|-------------------|--------|
| Bare metal laptop/workstation | Void Linux | Minimalismo usabile, runit |
| VM server minimale | Alpine Linux | 32MB RAM, musl, OpenRC |
| Hypervisor enterprise | openSUSE Leap | wicked, AutoYaST, SLES-compatible |
| Provisioning automatico | AutoYaST + Leap | Standard enterprise SUSE |
| Router embedded | OpenWrt / Alpine | Footprint minimo |
| Container base | Alpine | FROM alpine — standard Docker |

---

## 10. Benchmark RAM — Init systems a confronto

Dati reali misurati sul campo — Covo di Pandora, Maggio 2026:

| Sistema | Init | libc | RAM idle | Hardware | Note |
|---------|------|------|----------|----------|------|
| Alpine 3.23 (default) | OpenRC | musl | 57MB | VM KVM | Prima installazione |
| Alpine 3.23 (ottimizzato) | OpenRC | musl | 32MB | VM Proxmox nested | Boot da disco |
| Void Linux (min. ottimiz.) | runit | musl | 42MB | X230 fisico | Solo TTY eliminate |

> *"runit batte OpenRC di default, senza ottimizzazioni aggressive — solo qualche TTY in meno"*
> *"Alpine VM batte Void su fisico — OpenRC è più leggero di quanto si pensi su hardware virtuale"*

---

## 11. Alpine Linux — il server invisibile che regge internet

Alpine usata in produzione da:
- **Docker Hub** — base per quasi tutte le immagini ufficiali
- **Cloudflare** — edge services
- **Signal** — infrastruttura backend
- **Hetzner, Vultr** — immagini VPS minimali

Perché Alpine per i server:
- musl libc — meno vulnerabilità di glibc
- busybox — superficie d'attacco minima
- OpenRC — nessun systemd, nessun socket D-Bus esposto
- apk — package manager con verifica firma obbligatoria
- No password root di default — solo chiavi SSH

---

## 12. Disaster Radio — Alpine per nodi mesh

Stack ideale per nodo Disaster Radio a basso consumo:
```
Raspberry Pi 4/5 ARM
├── Alpine Linux (32-64MB RAM idle)
├── Reticulum Network Stack
├── MeshCore / Meshtastic bridge
└── Alimentazione 5V/3A

Consumo: ~3-5W idle
Pannello solare: 10-20W sufficiente
Batteria LiFePO4: autonomia giorni
Costo nodo: ~50-80€
```

Resilienza a strati (graceful degradation):
```
Livello 1: Fibra 2.5Gbps          ← normale operatività
Livello 2: 4G MPTCP dual SIM      ← fibra down
Livello 3: MeshCore/Meshtastic     ← tutto down, LoRa mesh
Livello 4: Reticulum               ← qualsiasi mezzo fisico
```

> *"Graceful degradation — il sistema degrada gradualmente mantenendo sempre il massimo livello di servizio possibile con le risorse disponibili. Principio fondamentale dell'ingegneria dei sistemi critici."*

---

## 13. Proxmox VE — Perfect Setup Community Edition

Passi per Proxmox senza subscription:

1. Disabilita repository enterprise:
```bash
# pve-enterprise.list
echo "# disabled" > /etc/apt/sources.list.d/pve-enterprise.list
# ceph.sources e pve-enterprise.sources → aggiungi Enabled: no
```

2. Aggiungi repository community:
```bash
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
  > /etc/apt/sources.list.d/pve-no-subscription.list
```

3. Aggiorna:
```bash
apt-get update && apt-get dist-upgrade -y
```

4. Rimuovi warning subscription:
```bash
# Cerca riga "No valid subscription" in proxmoxlib.js
# La riga if(...) diventa void({//
systemctl restart pveproxy
# Poi Ctrl+Shift+R nel browser
```

*Testato su Proxmox VE 9.1 — Maggio 2026*

---

## 14. Libri e Risorse consigliate

### Libri fondamentali
- **"The Linux Command Line"** — William Shotts (gratuito su linuxcommand.org)
- **"Linux System Administration Handbook"** — Nemeth, Snyder, Hein
- **"DNS and BIND"** — Cricket Liu, Paul Albitz (O'Reilly)
- **"TCP/IP Illustrated Vol. 1"** — W. Richard Stevens ← *il libro sacro del networking*
- **"How Linux Works"** — Brian Ward ← *systemd, cgroups, journald*

### Blog e risorse online
- **Brendan Gregg** — brendangregg.com ← performance Linux, lavora in Netflix
- **Dan Luu** — danluu.com ← analisi tecniche profonde
- **LWN.net** — lwn.net ← il NYT del kernel Linux
- **SUSE Blog tecnico** — suse.com/c/blog
- **Arch Wiki** — wiki.archlinux.org ← documentazione di riferimento universale
  - [DNS resolution on Linux](https://wiki.archlinux.org/title/Domain_name_resolution)

### RFC fondamentali
- RFC 826 — ARP
- RFC 791 — IP
- RFC 793 — TCP
- RFC 6762 — mDNS (.local)
- RFC 8375 — .home.arpa

---

## 15. Gap da colmare — Aree di approfondimento

1. **SELinux** — modello MAC, tipi, contesti, `audit2allow`
2. **systemd in profondità** — dipendenze unit, socket activation, cgroups
3. **btrfs internals** — CoW, extent tree, checksum
4. **Networking L2/L3** — RFC base per formalizzare le intuizioni

---

*"Conosci il lato oscuro per combatterlo"*
*— prossimamente: sicurezza offensiva, exploit, privilege escalation*

