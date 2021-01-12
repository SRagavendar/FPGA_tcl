# ---------------------------------------------------------------------------- 
# --
# -- Title    : Create IPs
# --
# ---------------------------------------------------------------------------- 
# --
# -- Description :
# --
# -- 1. Used to quickly create FFT IP Cores
# -- 2. The location of the script in the project is ./src/tcl/
# -- 3. Only the kernel name is required (composite ot regular)
# -- 4. The kernels are in the ./src/ip_cores directory (must be created)
# --
# ----------------------------------------------------------------------------

set ipForm .xci;
set TclPath [file dirname [file normalize [info script]]]
set NewLoc [string range $TclPath 0 [string last / $TclPath]-5]
set IpLoc $NewLoc/src/ip_cores

set prjName [current_project];

# ----- CHANGE IP CORE NAMES ----- #
set fftName xfft_nat_i16_n;
set fftLast k;

# ----- CREATE IP CORES ----- #
puts $NewLoc;
for {set i 0} {$i < 7} {incr 1} {
	set nFFT [expr int([expr pow(2, $i + 10)])];
	set j [expr int([expr pow(2, $i)])];
	set bRAMS [expr $i+3];
	set coreName $fftName$j$fftLast;
	puts $coreName;

	update_ip_catalog
	create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name $coreName -dir $IpLoc
	set_property -dict [list CONFIG.Component_Name $coreName CONFIG.transform_length $nFFT CONFIG.implementation_options {pipelined_streaming_io} CONFIG.scaling_options {unscaled} CONFIG.rounding_modes {convergent_rounding} CONFIG.aresetn {true} CONFIG.output_ordering {natural_order} CONFIG.complex_mult_type {use_mults_performance} CONFIG.butterfly_type {use_xtremedsp_slices} CONFIG.implementation_options {pipelined_streaming_io} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors $bRAMS] [get_ips $coreName]
}

# ----- SET CORE CONTAINER ENABLED ----- #
set ipFFT [get_ips];
for {set i 0} {$i < [llength $ipFFT]} {incr 1} {
	set IpSingle [lindex $ipFFT $i]
	set coreContainer [get_property IP_CORE_CONTAINER $IpSingle];
	set coreFile [get_property IP_FILE $IpSingle];

	if {$coreContainer > 0} {

		} else {
			convert_ips [get_files $coreFile];
			export_ip_user_files -of-objects [get_files $coreFile] -sync -lib__map_path [list {modelsim=$NewLocvivado/$prjName.cache/compile_simlib/modelsim} {questa=$NewLocvivado/$prjName.cache/compile_simlib/questa} {riviera=$NewLocvivado/$prjName.cache/compile_simlib/riviera} {activehdl=$NewLocvivado/$prjName.cache/compile_simlib/activehdl}] -force -quiet
		}
}

# ----- GENERATE OUTPUT PRODUCT ----- #
for {set i 0} {$i < [llength $ipFFT]} {incr 1} {
	set coreFile [get_property IP_FILE $IpSingle];
	set coreFile [get_property NAME $IpSingle];
	generate_target all [get_files $coreFile];
}

for {set i 0} {$i < [llength $ipFFT]} {incr 1} {
	set coreFile [get_property NAME $IpSingle];
	export_ip_user_files -of_objects  [get_files $coreFile] -no_script -sync -force -quiet;
    create_ip_run [get_files -of_objects [get_fileset sources_1] $coreFile];
}
launch_runs -jobs 4 $ipFFT;
}
}