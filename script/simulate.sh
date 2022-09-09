#    #!/bin/bash
# Requires sv2v to be installed in /usr/bin/ if using WSL due to path issues
if [ -z "$1" ]
then
    echo "simulate.sh needs the name of a toplevel testbench from the rtl directory!"
else
    toplevel=$(basename -- "${1%.*}")
    getmypath () {
        echo ${0%/*}/
    }
    mypath=$(getmypath)
    tmp="$mypath/../tmp"
    rtl="$mypath/../rtl"
    mkdir -p $tmp
    rm $tmp/*
    incdirlist=$(find $rtl/ -not -path */testbench -and -type d -exec bash -c 'echo "-I $1"' bash "{}" \; )
    toplevelfile="$(find $rtl/ -name $1)"
    echo ==sv2v==
    echo "script: generating verilog..."
    sv2v -E always -E logic -E unbasedunsized -w $tmp/$toplevel.v $incdirlist $toplevelfile
    find $rtl/ -not -path */testbench/* -and \( -iname *.v -o -iname *.vh -o -iname *.sv \)  -exec bash -c 'sv2v -E always -E logic -E unbasedunsized -w $2/$(basename ${1%.*}).v $3 $1' bash "{}" "$tmp" "$incdirlist" \;
    echo "script: copying rom files..."
    cp $mypath/../rom/* $tmp/
    cd $tmp/
    echo ==iverilog==
    iverilog -o $tmp/out.tmp -g2012 -Wall -Wno-sensitivity-entire-vector -Wno-sensitivity-entire-array -grelative-include -Y .sv -y $tmp $tmp/$toplevel.v
    echo ==simulation==
    vvp $tmp/out.tmp
fi

