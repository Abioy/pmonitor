#!/bin/bash

insert()
{
    data="$1"
    fname=`echo $data | md5sum | awk '{print $1}'`
    fpath=db/$fname
    if [ -e $fpath ];
    then
        return 1
    fi
    echo $data > $fpath
    return 0
}

sms()
{
    usr="$1"
    shift
    msg="$*"
    for i in {0..2};
    do
        echo "smsing $i ..."
        python ../sms/fetionsms.py -m "$msg" -u "$usr" | grep "发送短信成功"  
        [ $? -eq 0 ] && return 0
    done
    echo "给$usr发送短信失败"
    return 1
}

notify()
{
    msg="$*"
    rc = 0
    cat watcher.lst | while read usr;
    do
        sms "$usr" "$msg"
        [ $? -eq 0 ] || rc = 1
    done
    return $rc
}

monitor()
{
    id=$1
    url=$2
    pt="$3"
    shift
    shift
    shift
    match="$*"
#    curl -v "$url" 2>/dev/null | sed -n -r 's/^.*span class="black">([^<]*'$pt'[^<]*)<\/span><span class="red">([^<]*)<.*$/\1, \3/p' 2>/dev/null | while read line;
    curl -v -H "User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36" "$url" 2>/dev/null | sed -n -r 's/'$match'/\1, \3/p' 2>/dev/null | while read line;
    do
        insert "$line"
        [ $? -eq 0 ] && echo "[INFO] $id match $pt : $line" && notify "$id got $pt: $line"
    done
}

main()
{
    pt="(米糊|湿巾|纸尿裤|手表)" 
    if [ $# -ge 1 ]; then
        pt=$1
    fi
    echo "[INFO] restart monitoring $pt ..."
    while true;
    do
        monitor "SMZDM首页" "http://www.smzdm.com" "$pt" "^.*target=\"_blank\">([^<]*$pt[^<]*)<span\sclass=\"red\">([^<]*)<\/span.*$"
        monitor "SMZDM发现" "http://faxian.smzdm.com"  "$pt" "^.*span\sclass=\"black\">([^<]*$pt[^<]*)<\/span><span\sclass=\"red\">([^<]*)<.*$"
        monitor "HH首页"    "http://www.huihui.cn" "$pt" "^\s\s*([^<]*$pt[^<]*)<em>([^<]*)<\/em>$"
        sleep 5
    done
}

main $*
exit 1
