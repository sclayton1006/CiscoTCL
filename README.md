# CiscoTCL
A small repository of `tclsh` script ideas to help engineers automate and protect their networks.

---

## DCPortProtector
`DCPortProtector` is designed to protect a data‑centre environment from an unexpected or foreign device being connected to a switchport. This could be an unknown device introduced accidentally or by a bad‑faith actor.

The script provides a lightweight, on‑box “quarantine” mechanism using Cisco EEM and Tcl.

---

## Requirements
- **DCPortProtectorEEM** — EEM applet that triggers the script  
- **DCPortProtector.tcl** — Tcl script that performs MAC validation and quarantining  
- **flash:/trusted_macs.db** — Text file containing one trusted MAC address per line  

---

## Function and Structure
The system works by using EEM to trigger a Tcl script whenever a device connects to a switchport.

### Workflow
1. **EEM trigger** fires when a log entry containing  
   `LINK-3-UPDOWN.*up`  
   appears (indicating a port has come up).

2. **Tcl script** runs and checks the MAC address learned on that interface.

3. The script compares the MAC against the trusted list stored in  
   `flash:/trusted_macs.db`.

4. **If the MAC is known**  
   - No configuration changes are made  
   - The port remains in its existing VLAN  
   - A log entry is generated  

5. **If the MAC is unknown**  
   - The port is moved to **VLAN 999** (state `suspend`)  
   - The port is set to **access mode**  
   - The interface is shut down  
   - A log entry is generated  

This provides immediate isolation of untrusted devices without affecting known servers or infrastructure.  
---   
### Sample Output
**If MAC is known:** AUTO-QUARANTINE: Known MAC aaaa.bbbb.cccc detected on Gi1/0/1. No action taken.  
**If MAC is unknown:** AUTO-QUARANTINE: Unknown MAC aaaa.bbbb.cccc on Gi1/0/1. Moving to VLAN 999.
