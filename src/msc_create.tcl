# ---------------------------------------------------------------- 
# --
# -- Title    : Create *.MSC from *.BIT
# --
# ----------------------------------------------------------------
# -- Description :
# --
# -- 1. This script allows you create *.msc file without setting parameters. You should only change MSC format.
# -- 2. For example: -format mcs -size 32 -interface SPIx4
# -- 
# ---------------------------------------------------------------- 

# ----- Go-to project directory ----- #
cd [get_property DIRECTORY [current_project]]
cd ..

# ----- GET IMPLEMENTATION SET ----- #
set ImpNum [current_run -implementation]

# ----- IMPLEMENTATION DIRECTORY ----- #
set VivTop [lindex [find_top] 0]
set VivDir [get_property DIRECTORY [current_project]]
set VivName [get_property NAME [current_project]]
set VivBit $VivDir/$VivName.runs/$ImpNum/$VivTop.bit

# ----- CHANGE 'date format' ----- #
set VivList [split "[clock format [clock seconds] -format %D]" {/}]
set NewDate "_[lindex $VivList 2]_[lindex $VivList 0]_[lindex $VivList 1]"

# ----- MCS FILE DIRECTORY ----- #
set VivMSC [pwd]/$VivTop$NewDate.msc

# ----- CREATE MSC FILE ----- #
write_cfgmem  -format mcs -size 32 -interface SPIx4 -loadbit "up 0x00000000 $VivBit" -checksum -force -file "$VivMSC"