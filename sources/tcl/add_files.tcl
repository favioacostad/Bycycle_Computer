#add all project files to the project

set oldpwd [pwd]
set script_path [ file dirname [ file normalize [ info script ] ] ]
cd $script_path/..
set dir "."

#design sources
foreach file [glob -dir "$dir/student" *.v] {
    add_files -norecurse $file
}
foreach file [glob -dir "$dir/submodules" *.v] {
    add_files -norecurse $file
}
foreach file [glob -dir "$dir/synthesis" *.v] {
    add_files -norecurse $file
}

#testbenches
foreach file [glob -dir "$dir/testbench" *.v] {
    set_property SOURCE_SET sources_1 [get_filesets sim_1]
    add_files -fileset sim_1 -norecurse $file
}


#constraint files
foreach file [glob -dir "$dir/constraints" *.xdc] {
    add_files -fileset constrs_1 -norecurse $file
}

#Restore working directory
cd $oldpwd
