# auto_quarantine.tcl
# Automatically quarantine unknown devices by moving their port to VLAN 999
# requires a "trusted_macs.db" file in flash. Run flash:/trusted_macs.db to create the file

# Get the syslog message passed from EEM in DCPortProtectorEEM
set msg [lindex $argv 0]

# Extract interface name from the syslog message using RegEx
set intf ""
if {[regexp {([A-Za-z]+[A-Za-z]+[A-Za-z]*Ethernet[0-9/]+)} $msg match]} {
    set intf $match
}

# If interface name couldn't be parsed, return and stop script
if {$intf eq ""} {
    puts "AUTO-QUARANTINE: Could not extract interface from syslog."
    return
}

# Read the MAC address table for this interface
set mac_output [exec "show mac address-table interface $intf"]
set mac "unknown"

# Extract the first MAC address seen on the port
foreach line [split $mac_output "\n"] {
    if {[regexp {([0-9a-fA-F]{4}\.[0-9a-fA-F]{4}\.[0-9a-fA-F]{4})} $line m]} {
        set mac $m
        break
    }
}

# If no MAC found, nothing to do
if {$mac eq "unknown"} {
    puts "AUTO-QUARANTINE: No MAC found on $intf yet."
    return
}

# Path to the trusted MAC database
set db "flash:/trusted_macs.db"

# If the DB doesn't exist, create an empty one
if {![file exists $db]} {
    set fh [open $db w]
    close $fh
}

# Read the trusted MAC list
set fh [open $db r]
set trusted_list [split [read $fh] "\n"]
close $fh

# Check if MAC is trusted
set trusted 0
foreach t $trusted_list {
    if {[string tolower $t] eq [string tolower $mac]} {
        set trusted 1
        break
    }
}

# If trusted, log it and do nothing
if {$trusted} {
    puts "AUTO-QUARANTINE: Known MAC $mac detected on $intf. No action taken."
    return
}

# If not trusted, quarantine the port
puts "AUTO-QUARANTINE: Unknown MAC $mac on $intf. Moving to VLAN 999."

# Ensure VLAN 999 exists, script will error without the VLAN
set vlan_output [exec "show vlan id 999"]

# If VLAN 999 is not found, create it and set state to suspend
if {[string match "*% VLAN id not found*" $vlan_output]} {
    puts "AUTO-QUARANTINE: VLAN 999 does not exist. Creating it now."

    exec "configure terminal" \
         "vlan 999" \
         "name QUARANTINE" \
         "state suspend" \
         "exit"
}

exec "configure terminal" \
     "interface $intf" \
     "switchport mode access" \
     "switchport access vlan 999" \
     "exit"

puts "AUTO-QUARANTINE: $intf quarantined successfully."
