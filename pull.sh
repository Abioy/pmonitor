#!/bin/bash

pull()
{
    ts=$1
    fname=$2

    tmp_fname="tmp/${fname}_${ts}"

    wget "https://raw.githubusercontent.com/Abioy/pmonitor/master/$fname" -O  "$tmp_fname" 2>/dev/null
    if [ $? -ne 0 ];
    then
        echo "[DEBUG] wget file $fname fail ..."
        rm -f $tmp_fname
        return 1
    fi

    if [ -e "./$fname" ];
    then
        diff "$tmp_fname" "$fname" >/dev/null
        if [ $? -eq 0 ]; then
            echo "[DEBUG] file $fname not changed ..."
            rm -f $tmp_fname
            return 1
        fi
    fi

    ln -sf "$tmp_fname" "$fname"
    echo "[INFO] file $fname update to $tmp_fname ..."

    return 0
}

shut_down()
{
    fname=$1

    echo "[INFO] shutdown process $fname ..."

    ps -ef | grep $fname | grep -v grep | grep -v pull.sh | awk '{print $2}' | while read pid;
    do
        echo "[INFO] kill $pid ..."
        kill -9 $pid
    done
    return 0
}

main()
{
    ts=`date +%s`
    fname="smzdm.sh"
    if [ $# -ge 1 ];
    then
        fname="$1"
    fi

    echo "[INFO] watching $fname at $ts ..."
    pull $ts $fname
    if [ $? -eq 0 ];
    then
        shut_down $fname
        exit 0
    fi
}

main $*
exit 1
