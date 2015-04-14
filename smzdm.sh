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
    rc=0
    cat watcher.lst | while read usr;
    do
        sms "$usr" "$msg"
        [ $? -eq 0 ] || rc=1
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
    curl -v -H "Cookie: smzdm_user_source=1C62A16F6A22F14B6279BE719E5F1644; __gads=ID=ae2f654128af76c2:T=1389962281:S=ALNI_MZRDJ2inYrbM_MlmmNLk2bO8GuqPQ; __utma=123313929.864298857.1389962282.1415079491.1418359976.97; __utmz=123313929.1418359976.97.9.utmcsr=fx.smzdm.com|utmccn=(referral)|utmcmd=referral|utmcct=/detail/380417; 3thread-20150216174551=57; _ga=GA1.3.864298857.1389962282; _ga=GA1.2.864298857.1389962282; PHPSESSID=gh6r1oo3f5qjh92oko7a0db352; smzdm_user_view=D3222F4B0E5013636A7A21C16439AFC7; __jsluid=4026935b5a41ef4d15496439bc0a6876; wt3_eid=%3B999768690672041%7C2142331883600723213%232142902225600275631; wt3_sid=%3B999768690672041; crtg_rta=; count_i=1; 1thread-20150403194411=5; 2thread-20150403194411=2; 3thread-20150403194411=10; niuxamss=5; niuxamss30=240; __jsl_clearance=1429028350.422|0|GUyAKM3s5p5ZwIh7GJlAx5tkRus%3d; Hm_lvt_9b7ac3d38f30fe89ff0b8a0546904e58=1427551750,1427815185,1427987874,1428681495; Hm_lpvt_9b7ac3d38f30fe89ff0b8a0546904e58=1429028956; AJSTAT_ok_pages=4; AJSTAT_ok_times=59; amvid=f7cd6d84c92e6b96c9dd6aacd10054a2" -H "User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36" "$url" 2>/dev/null | sed -n -r 's/'$match'/\1, \3/p' 2>/dev/null | while read line;
    do
        insert "$line"
        [ $? -eq 0 ] && echo "[INFO] $id match $pt : $line" && notify "$id got $pt: $line"
    done
}

main()
{
    pt="(米糊|湿巾|纸尿裤)" 
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
