#The default working directory for hook scripts is e.g. vivado/stop_watch.runs/impl_1
#But relying on this makes it impossible to run the script explicitly (outside some hook).
#That's why we specify the working directory to be in the tcl folder and we do not rely on the
#project path, but on the source directory structure.
#The working directory of a hook script needs to be restored once it is finished,
#because the calling script uses source to call this. The path change affects the calling script.
#And the calling one creates a file .write_bitstream.end.rst in the stop_watch.runs/impl_1
#directory to signal the GUI, that the generate-bitstream script is done. If the path is wrong,
#this signaling file is created in the wrong directory and the GUI does not get the information.
set oldpwd [pwd]
cd [ file dirname [ file normalize [ info script ] ] ]
cd "../../reports"
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file "./exc_timing.txt"
report_utilization -hierarchical -file "./exc_utilization_hier.txt"
report_utilization -file "./exc_utilization.txt"
report_clock_networks -file "./exc_clock_networks.txt"
report_clock_interaction -delay_type min_max -significant_digits 3 -file "./exc_clock_interaction.txt"
cd $oldpwd