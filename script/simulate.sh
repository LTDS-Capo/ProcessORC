#!/bin/bash
# Requires sv2v to be installed in /usr/bin/ if using WSL due to path issues
if [ -z "$1" ]
then
    echo "simulate.sh needs the name of a toplevel testbench from the rtl directory!"
else
    toplevel=${1%.*}
    toplevel=${toplevel##*/}
    toplevel=${toplevel##*\\} # just in case a windows path was passed...
    tmp="../tmp"
    rtl="../rtl"
    mkdir -p $tmp
    rm $tmp/*
    incdirlist=$(find $rtl/ -not -path */testbench -and -type d -exec echo "-I {}" \; )
    filelist="$(find $rtl/ -name $1) $(find $rtl/ -not -path */testbench/* -and \( -iname *.v -o -iname *.vh -o -iname *.sv \) -and -not -iname *_TopLevel.sv )"
    sv2v -E always -E logic -E unbasedunsized $incdirlist $filelist > "$tmp/$toplevel.sv"
    cp $mypath/../rom/* $tmp/
    cd $tmp/
    iverilog -o $tmp/out.tmp -g2012 -grelative-include -Y .sv -y $tmp $tmp/$toplevel.sv
    vvp $tmp/out.tmp
fi
