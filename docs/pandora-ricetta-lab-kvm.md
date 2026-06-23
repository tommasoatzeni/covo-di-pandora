# Ricetta lab KVM "Pandora" — fotografia + procedura di ricostruzione

> Scopo: catturare COM'E' FATTO il lab Pandora (openSUSE Tumbleweed + KVM/libvirt)
> PRIMA di piallare il ferro, così la RICETTA si replica su un'altra macchina.
> Decisione (2026-06-23): il ferro Pandora diventa un PBS bare-metal da mandare a
> MC; il lab (questa ricetta) rivive altrove (NUC Manjaro risorto / ferro nuovo).
> Fotografia presa via SSH read-only il 2026-06-23 (~22:34) da X230.
>
> NB: gran parte della config E' GIA' versionata in questo repo (vedi "File correlati"
> in fondo). Questo doc aggiunge il pezzo mancante: le definizioni libvirt e la
> procedura `virt-install` con cui le VM sono state create.

---

## 1. Hardware (snapshot 2026-06-23)

- **CPU:** Intel Core **i5-2300** (Sandy Bridge 2011), 4 core / 4 thread, **VT-x** presente.
  AES-NI presente (utile per cifratura backup quando il ferro diventerà PBS).
- **RAM:** 15 GiB + swap 2 GiB.
- **Dischi:** 2x **WD Red 3TB `WD30EFRX`** (CMR, 5400rpm — gli STESSI di pdc/QNAP).
  - `sda` = btrfs di sistema (sottovolumi `/`, `/home`, `/var`, `/srv`, `/.snapshots`, ...).
    2,8T totali, **usati solo ~4,2G** (sistema quasi vuoto).
  - `sdb` = btrfs label `pandora-vmdata`, montato su `/srv/vmdata`, **~40G di VM**.
  - **NESSUNA ridondanza oggi**: due btrfs singoli (rilevante: da PBS andrà fatto un mirror).
- DVD-RW (`sr0`) presente.

## 2. Sistema operativo e stack

- **openSUSE Tumbleweed** (snapshot 20260411), kernel 6.19.x.
- **Virtualizzazione:** libvirt MODULARE (daemon `virtqemud`, non il monolitico `libvirtd`).
  Socket abilitati: `virtqemud.socket`, `virtqemud-ro.socket`, `virtqemud-admin.socket`.
- **Networking host:** **wicked** (NON NetworkManager). Servizi: `wicked`, `wickedd-dhcp4`,
  `wickedd-nanny`. Disabilitati/mascherati a mano: `wickedd-auto4`, `wickedd-dhcp6`.
- **Sicurezza:** **SELinux** attivo (Tumbleweed recente; le VM hanno seclabel `svirt_t`).
- **SSH:** `PermitRootLogin no` (root inibito by design). Si entra come `tommy` con chiave.

## 3. Rete host

Due NIC fisiche:

| IF        | Ruolo                          | Config                                            |
|-----------|--------------------------------|---------------------------------------------------|
| `eno1`    | porta del bridge VM            | `BOOTPROTO=none`, `BRIDGE=br0` (schiava di br0)    |
| `enp14s0` | **NIC di RESCUE** IP statico   | `192.168.1.11/24` — accesso quando il DHCP lab e' giu |
| `br0`     | bridge delle VM                | static `192.168.1.10/24`, gw .1 — porta `eno1`     |

⚠️ **INSIDIA NOTA:** `ifcfg-br0` assegna **`192.168.1.10`** che **COLLIDE con l'X230**
(pataccone = 192.168.1.10). A runtime br0 NON aveva l'IPv4 (eno1 senza link/DHCP del lab giu).
Sul ferro nuovo: scegliere un IP br0 LIBERO, oppure tenere br0 senza IP e gestire l'host
sulla NIC di management. Da correggere in fase di ricostruzione.

Accesso attuale dall'X230 (alias in `~/.ssh/config`):
- `ssh pandora`  -> `tommy@192.168.1.11` (NIC rescue), chiave `~/.ssh/id_covo`.
- `ssh pandina`  -> `tommy@192.168.10.10` (NIC DHCP lab, valida a lab rimontato).

## 4. Storage libvirt (pool) — vedi `hypervisor/libvirt/pools/*.xml`

| Pool          | Tipo | Path                       | Note                              |
|---------------|------|----------------------------|-----------------------------------|
| `default`     | dir  | `/srv/vmdata/images`       | dischi qcow2 delle VM (qemu-owned)|
| `vmdata`      | dir  | `/srv/vmdata`              | radice dati VM (gruppo 1000=tommy)|
| `iso`         | dir  | `/srv/vmdata/iso`          | ISO sorgenti (Leap 15.6, PVE 9.1) |
| `boot-scratch`| dir  | `/var/lib/libvirt/boot`    | scratch d'installazione           |

ISO presenti in `/srv/vmdata/iso/`:
- `openSUSE-Leap-15.6-DVD-x86_64-Media.iso` (~4,6G)
- `proxmox-ve_9.1-1.iso` (~1,8G)

⚠️ I qcow2 in `/srv/vmdata/images/` sono **owned `qemu:qemu`** (dir `drwxrwx--x`): per
COPIARLI serve `sudo` (l'utente `tommy` non li legge). Ma per la ricetta NON servono:
le VM si ricostruiscono da zero con i comandi `virt-install` qui sotto.

## 5. Le VM (la "palestra") — definizioni in `hypervisor/libvirt/qemu/*.xml`

| VM             | OS              | RAM   | vCPU | Disco                         | Rete | Ruolo                          |
|----------------|-----------------|-------|------|-------------------------------|------|--------------------------------|
| `proxmox`      | Debian12/PVE 9.1| 4 GiB | 2    | `proxmox-test.qcow2` (32G)    | br0  | Proxmox nested di studio        |
| `pandora-leap` | Leap 15.6       | 4 GiB | 2    | `pandora-leap.qcow2` (20G)    | br0  | base; snapshot `leap-base-template` |
| `autoyast`     | Leap 15.6       | 2 GiB | 2    | `autoyast-test.qcow2` (20G)   | br0  | banco di prova AutoYaST         |

Tutte: `cpu host-passthrough`, macchina `q35`, console seriale, bridge `br0`.
`proxmox` ha anche VNC su `0.0.0.0:5900` (per la GUI installer PVE) e UEFI.

### Comandi `virt-install` ESATTI (ricostruiti dal `.bash_history`)

```sh
# --- VM Leap base (pandora-leap) ---
virt-install \
  --name pandora-leap --vcpus 2 --memory 4096 \
  --disk path=/srv/vmdata/images/pandora-leap.qcow2,size=20,format=qcow2 \
  --location /srv/vmdata/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso \
  --network bridge=br0 --os-variant opensuse15.6 \
  --graphics none --console pty,target_type=serial \
  --extra-args 'console=ttyS0,115200n8'
# poi: snapshot template "leap-base-template" (Leap hardened: SSH + nftables)
#   virsh snapshot-create-as pandora-leap --name leap-base-template \
#     --description "Leap 15.6 - SSH hardened - nftables - template base pre-AutoYaST" --atomic

# --- VM AutoYaST (install non presidiata via profilo servito in HTTP) ---
virt-install \
  --name autoyast-test --vcpus 2 --memory 2048 \
  --disk path=/srv/vmdata/images/autoyast-test.qcow2,size=20,format=qcow2 \
  --location /srv/vmdata/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso \
  --network bridge=br0 --os-variant opensuse15.6 \
  --graphics none --console pty,target_type=serial \
  --extra-args 'console=ttyS0,115200n8 autoyast=http://192.168.1.1:8080/autoinst.xml'
# rinominata poi:  virsh domrename autoyast-test autoyast

# --- VM Proxmox nested (installer testuale via seriale) ---
virt-install \
  --name proxmox-test --vcpus 2 --memory 4096 \
  --disk path=/srv/vmdata/images/proxmox-test.qcow2,size=32,format=qcow2 \
  --location /srv/vmdata/iso/proxmox-ve_9.1-1.iso \
  --network bridge=br0 --os-variant debian12 --cpu host-passthrough \
  --graphics none --console pty,target_type=serial \
  --extra-args 'console=ttyS0,115200n8'
# variante GUI:  --graphics vnc,listen=0.0.0.0,port=5900 --noautoconsole --check all=off
# rinominata poi: virsh domrename proxmox-test proxmox ; virsh autostart proxmox
```

## 6. AutoYaST + DHCP/PXE — il pezzo che vive(va) sul NUC "mucchina"

- Il profilo AutoYaST e' servito via **`http://192.168.1.1:8080/autoinst.xml`** e il
  **DHCP del lab era `dnsmasq` sulla "mucchina"** (il NUC ThinkPad/Manjaro). Quel NUC e'
  **morto** ("scoppiata la Manjaro") -> ecco perche' oggi il `dnsmasq` del lab e' ORFANO
  e `eno1` non prende IP (nessuno serve DHCP sulla subnet lab).
- Il profilo e' GIA' versionato qui: `autoyast/autoinst.xml` (+ `autoinst-v1.0-FUNZIONANTE.xml`).
- Il `dnsmasq` del lab e' versionato sotto `laptop/etc/dnsmasq.*` (girava sul portatile/mucchina).
- **Per rimontare il lab** serve riportare in vita questo servente (DHCP + HTTP autoinst)
  su una macchina della subnet lab. Il backup del NUC e' in `nuc_backup` sul TrueNAS `.100`
  (vedi [[nas-backup-access]]): da li' si recupera l'eventuale `~/autoinst.xml` originale.

## 7. Procedura per RICOSTRUIRE il lab su ferro nuovo (NUC risorto / Z840 / altro)

1. Installa **openSUSE Tumbleweed**; stack: `qemu-kvm libvirt libvirt-client virt-install
   osinfo-db osinfo-db-tools` + i driver libvirt modulari (qemu/network/storage-core).
2. Applica le config host versionate in `hypervisor/etc/` (rete wicked, nftables, sshd
   hardening, moduli kvm, dracut). **Correggi l'IP di `br0`** (non 192.168.1.10: collide).
3. Ricrea i pool libvirt (`virsh pool-define hypervisor/libvirt/pools/<nome>.xml` +
   `pool-autostart` + `pool-start`). Adatta i `<path>` se cambiano i mountpoint.
4. Scarica le ISO in `iso/`; ricrea le VM con i `virt-install` del par. 5
   (oppure `virsh define hypervisor/libvirt/qemu/<vm>.xml` se riusi i qcow2 copiati).
5. Rimetti in piedi il servente AutoYaST (DHCP `dnsmasq` lab + HTTP `autoinst.xml`).
6. Verifica: `virsh list --all`, install AutoYaST non presidiata, Proxmox nested.

## 8. File correlati (gia' versionati in questo repo)

- `autoyast/autoinst.xml`, `autoyast/autoinst-v1.0-FUNZIONANTE.xml` — profilo AutoYaST.
- `hypervisor/etc/sysconfig/network/ifcfg-{br0,eno1,enp14s0}`, `routes` — rete host.
- `hypervisor/etc/nftables.conf`, `systemd/system/nftables.service` — firewall.
- `hypervisor/etc/ssh/sshd_config.d/99-hardening.conf` — hardening SSH (root off).
- `hypervisor/etc/modules-load.d/kvm.conf`, `dracut.conf.d/pandora-server.conf`.
- `hypervisor/libvirt/{qemu,networks,pools}/*.xml` — **definizioni libvirt (questo doc)**.
- `laptop/etc/dnsmasq.*`, `etc/hosts` — servente DHCP/DNS del lab (sul portatile/mucchina).
- `scripts/net-client`, `scripts/net-client.lab.conf` — router NAT da campo.
- `docs/hardware-gen11-checklist.md` — checklist ferro a regime.
