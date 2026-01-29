# CiscoTCL
A small repo for tclsh script ideas to help engineers keep their networks running

## DCPortProtector.tcl
The idea behind this script is to protect a data centre environment from a foregin device being added to the switchports. This could be an unknown device from a bad actor. 

### Function and Structure
The script uses EEM to trigger a TCL script in the event of a device being connected that the switch does **NOT** know about. Structure below:
1. EEM that triggers the script, caused by a log entry containing `"LINK-3-UPDOWN.*up"`
2. TCL script that creates the automation to check the MAC address of the connected device
3. Checks the connected device against known MACs in a .db file stored in flash under `flash:/trusted_macs.db`
   - If the MAC address is known, no action is taken by the script and the port remains in the same assigned VLAN, add an entry to the log
   - If the MAC address is not known, move the port to VLAN 999 (state suspend) and set the switchport to mode access, shut down the interface and add an entry to the log
