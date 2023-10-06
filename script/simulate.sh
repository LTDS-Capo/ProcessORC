#!/bin/bash
# Requires verilator
if [ -z "$1" ]
then
    echo "simulate.sh needs the name of a toplevel testbench from the rtl directory!"
else
    toplevel=$(basename -- "${1%.*}")
    mypath=$(pwd)
    tmp="$mypath/../tmp"
    mkdir -p $tmp
    rm -rf $tmp/*
    verilator_version=$(verilator --version)
    echo ==$verilator_version==
    { echo -e "#include \"obj_dir/V$toplevel.h\""; cat simulate.cpp; } > $tmp/simulate.cpp
    cd $tmp/
    rtl="../rtl"
    toplevelfile="$(find $rtl/ -name $1)"
    incdirlist=$(find $rtl/ -not -path */testbench -and -type d -exec bash -c 'echo "-I $1"' bash "{}" \; )
    libdirlist=$(find $rtl/ -not -path */testbench -and -type d -exec bash -c 'echo "-y $1"' bash "{}" \; )
    no_warn_list="-Wno-fatal"
    sv_std="--default-language 1800-2005"
    verilator --exe --build --timing -j 0 -CFLAGS "-DTARGET_TB=V$toplevel" -DSIM_DEBUG --trace --trace-structs --report-unoptflat -cc $sv_std $no_warn_list $libdirlist $toplevelfile simulate.cpp
    echo ==simulation==
    ./obj_dir/V$toplevel
    gtkwave -A --rcvar 'fontname_signals Monospace 13' --rcvar 'fontname_waves Monospace 12' sim.vcd
fi


# /main/
#   > /Projects/
#       > /Quartus/
#       > /Vivado/
#       > /Libero/
#   > /rtl/
#       > /*somefolder*/   - All your .v or .sv files go here
#           > /testbench/  - Any folder named testbench will be ignored, place your active testbench file in one of these when testing... it will choose the currently selected file as the toplevel, which you want to be your testbench
#   > /script/
#       > simulate.sh
#       > simulate.cpp
#   > /tmp/
#       > This folder is used by the simulation system, if you have some bizzare errors, sometimes clearing this helps.
