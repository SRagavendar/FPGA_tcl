
# ----------------------------------------------------------------------------
# --
# -- Title    : TCL Script for updating Vivado IP Cores 
# --
# ---------------------------------------------------------------------------- 
# --
# -- Description :
# -- 
# -- 1. Used to regenerate IP cores when changing the FPGA type
# -- 2. The location of the script in the project is ./src/tcl/
# -- 3. Running from the working directory of the Vivado project
# -- 4. To synthesize IP cores, refer Stage 5 and 6
# -- 5. The directory with IP cores should be named: src / ipcores
# -- 6. The directory from the project must be named: vivado
# -- 7. If the names are different, change the values ​​in the ProgDir and CoreDir parameters (see source code)
# --
# --
# ----------------------------------------------------------------------------

# ----- Find files in subdirs and add it to a list ----- #
proc findFiles { basedir pattern } {
	set basedir [string trimright [file join [file normalize $basedir] { }]]
	set fileList {}
	array set myArray {}

	# Look in the directory for matching files
	foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
		lappend fileList $fileName
	}

	foreach dirName [glob -nocomplain -type {d r} -path $basedir *] {
		set subDirList [findFiles $dirName $pattern]
		if { [llength $subDirList] > 0 } {
			foreach subDirFile $subDirList {
				lappend fileList $subDirFile
			}
		}
	}
	return $fileList
}

# ----- Stage 1: Set IP Cores working directory ----- #
cd [get_property directory [current_project]]
set WorkDir [pwd]
set ProgDir [string trim $WorkDir "*vivado" ]

# ----- Stage 2: Find name of the actual project ----- #
cd ../../
set NewVal [pwd]

set SizeStr [string length $NewVal]
set ProgName [string range $ProgDir $SizeStr+1 end-1]
set ProgFile $WorkDir/$ProgName.ip_user_files
cd [get_property directory [current_project]]

# ----- Stage 3: Create variables for the project ----- #
set CoreDir $ProgDir/src/ipcores
set CoreXCI "*.xci"
set basedir $CoreDir
set basepat $CoreXCI

# ----- Stage 4: Report IP Status and Update IP Cores ----- #
report_ip_status -name ip_status
export_ip_user_files -of_objects [get_ips] -no_script -reset -quiet
set IpCores [get_ips]
for {set i 0} {$i < [llength $IpCores]} {incr i} {
	set IpSingle [lindex $IpCores $i]
	set locked [get_property IS_LOCKED $IpSingle]
	set upgrade [get_property UPGRADE_VERSIONS $IpSingle]
	if {$upgrade != "" && $locked} {
		upgrade_ip $IpSingle;
	}
}

# ----- Stage 5: Find full path for each IP Core ----- #
set IpNames [findFiles $basedir $basepat]
set IpLists {}

# ----- Stage 6: Regenerate all IP Cores ----- #
generate_target all [get_files $IpNames]
for {set i 0} {$i < [llength $IpNames]} {incr i} {
	set IpSingle [lindex $IpNames $i]
	export_ip_user_files -of_objects [get_files $IpSingle] -no_script -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] $IpSingle]
    
    set IpSingle [lindex $IpCores $i]
    set IpSynth $IpSingle
    append IpSynth "_synth_1"
    foreach AllSynth $IpSynth {
        lappend IpLists $AllSynth
    }
    launch_run  {clk_wiz_tst_synth_1 ctrl_dds60mhz_prog_synth_1 ctrl_mmcm_in60_out300_240_synth_1 ctrl_ramb1024x32_synth_1}
    export_simulation -of_objects [get_files $IpSingle] -directory $ProgFile/sim_scripts -ip_user_files_dir $ProgFile -ipstatic_source_dir $ProgFile/ipstatic -force -quiet
}

launch_run $IpLists
export_simulation -of_objects [get_files $IpNames] -directory $ProgFile/sim_scripts -ip_user_files_dir $ProgFile -ipstatic_source_dir $ProgFile/ipstatic -force -quiet

# ----- Stage 7: Report IP Status ----- #
report_ip_status -name ip_status 