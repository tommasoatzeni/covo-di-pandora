# Checklist selezione — HP ProLiant MicroServer Gen11

**Data:** 2026-06-08
**Scopo:** scegliere il ferro "serio" che sostituirà X230 + NUC (banco prova) come
**Pandora** a regime. Due ruoli sulla stessa scatola: **gateway documenti** (aggregatore
rclone/git-annex, vedi MTOC) + **concentratore rete** (fibra 2.5G + MPTCP/NAT).
Orizzonte: **fine 2026**.

> Stile "verifica prima di comprare": sul MicroServer il diavolo sta nei dettagli di
> espansione. Disegna l'I/O *prima* di ordinare.

---

## 1. CPU — taglia in base al routing, non al file-serving
- [ ] Il file-gateway si accontenta di poco; è il **2.5G line-rate + MPTCP/NAT software**
      a chiedere clock e core. Punta al taglio **Xeon E-23xx (4c/8t)**, non al Pentium Gold.
- [ ] Confermare **AES-NI** presente: overlay WireGuard/Headscale e dedup cifrato ringraziano.
- [ ] Margine CPU = assicurazione contro il gray-failure da saturazione (crypto + VPN +
      routing insieme).

## 2. RAM ECC — il punto su cui non transigere
- [ ] **ECC UDIMM DDR5** (è il motivo per cui scegli questo box e non un mini-PC consumer).
- [ ] Solo **2 slot** → niente upgrade incrementali: o parti **64 GB (2×32)** o ti penti a
      metà strada. 64 a regime (cache VFS + indici recoll + dedup); 32 solo in fase prove.
- [ ] Modulo in **QVL HPE** (i MicroServer fanno i preziosi sulla compatibilità).

## 3. Espansione PCIe — IL vincolo #1
- [ ] Conta slot reali e **lane** (il Gen11 ne ha pochi). Decidi chi occupa cosa:
  - **NIC 2.5G/10G dedicata** per la fibra (l'onboard 1GbE non basta) → **1 slot**.
  - **Modem 4G/LTE industriale** mini-PCIe/M.2 → adattatore→PCIe o porta interna → **2° slot**.
- [ ] ⚠️ **Collisione possibile:** NIC veloce + modem interno potrebbero non starci entrambi.
      Alternative:
  - modem **USB3 industriale** (libera lo slot — occhio al bus), oppure
  - modem **esterno/router-mode sul tetto** che entra via Ethernet (spesso la scelta più
    pulita con le antenne Poynting → vedi resilient-comms-stack).
- [ ] Verificare ingombro **half-height / low-profile**: il telaio è stretto.

## 4. Storage — il basket 3-2-1
- [ ] **4 bay** (verificare LFF/SFF e hot-plug): basket canonico + ridondanza.
- [ ] Slot **M.2 NVMe** per OS + cache/catalogo (metadati, indici, working set git-annex).
- [ ] Layout: NVMe = OS+cache+catalogo; bay = pool dati con ridondanza (mirror/RAIDZ).
      Il "2" del 3-2-1 lo chiude il **NAS TrueNAS** in rete + un offsite.

## 5. Rete e gestione
- [ ] Onboard **2×1GbE**: ok per LAN lab/management, **non** per la fibra (NIC dedicata, §3).
- [ ] Gestione remota: i Gen11 hanno management **ridotto** vs iLO pieno — verificare cosa
      offre. Un nodo "mai disconnesso" lo vuoi poter resettare/diagnosticare da fuori.

## 6. Alimentazione, rumore, collocazione
- [ ] PSU: wattaggio vs schede aggiunte (NIC + eventuale HBA).
- [ ] Silenzioso ma non muto: valutare se sta in zona vissuta. Bene per nodo h24 in casa.

## 7. Decisione architetturale PRIMA dell'acquisto
- [ ] **File-gateway e concentratore-rete sulla stessa scatola?** In prova sì. A regime:
      separa i domini di guasto (hypervisor + VM/CT distinte), così un reboot del file layer
      **non** butta giù la portante. Se condivisi, **sovradimensiona** CPU/RAM ora.

---

## Contesto progetto
- **Banco prova (zero rischio):** X230 (`pataccone`, Void) + NUC. Si impara il workflow
  (git-annex su un disco UNIPI, rocky-net, Fase 2 MPTCP) e poi si travasa su ferro serio.
- **WAN lato tetto:** antenne **Poynting + modem 4G/LTE**, casa in **LOS sul Monte Serra**
  (nodo TLC centro Italia). Distinguere antenna cellulare (WAN/MPTCP) da futura LoRa 868 (mesh).
- **Nord magnetico:** availability-first — *mai perdere la connessione*.
