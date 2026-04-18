Configurazioni, profili AutoYaST e script per il lab enterprise portatile
basato su openSUSE Leap/Tumbleweed + KVM/libvirt.

# Struttura

covo-di-pandora/
├── laptop/          # Configurazioni Thinkpad X230 (mucchina)
├── hypervisor/      # Configurazioni Pandora (KVM host)
├── autoyast/        # Profili AutoYaST per provisioning automatico
├── scripts/         # Script di deploy e setup
└── docs/            # Documentazione tecnica

## Hardware

- **Mucchina**: Thinkpad X230 — control node, dnsmasq, gateway 4G
- **Pandora**: Desktop Sandy Bridge i5-2300 — KVM hypervisor
- **NUC**: Intel NUC — hypervisor portatile (target finale)
## Quick Start

```bash
# Deploy configurazioni laptop
bash scripts/deploy-laptop.sh
# Deploy configurazioni hypervisor (da eseguire su Pandora)
bash scripts/deploy-hypervisor.sh
```
## Documentazione

Vedi `docs/` per guide dettagliate su:
- Bridge L2 con wicked su openSUSE
- KVM/libvirt architettura modulare
- AutoYaST provisioning automatico
- dnsmasq split DNS con dominio .lan
