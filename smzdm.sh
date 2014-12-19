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
    msg="$*"
    for i in {0..2};
    do
        echo "smsing $i ..."
        python ../sms/fetionsms.py -m "$msg" | grep "发送短信成功"
        [ $? -eq 0 ] && return 0
    done
    echo "发送短信失败"
    return 1
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
    curl -v "$url" 2>/dev/null | sed -n -r 's/'$match'/\1, \3/p' 2>/dev/null | while read line;
    do
        insert "$line"
        [ $? -eq 0 ] && echo "[INFO] $id match $pt : $line" && sms "$id got $pt: $line"
    done
}

main()
{
pt="(万家乐|能率|林内|XQB75-Q77201|热水器|奶瓶|尿裤)"
if [ $# -ge 1 ]; then
    pt=$1
fi
echo "[INFO] restart monitoring $pt ..."
while true;
do
    monitor "SMZDM首页" "http://www.smzdm.com" "$pt" "^.*target=\"_blank\">([^<]*$pt[^<]*)<span\sclass=\"red\">([^<]*)<\/span.*$"
    monitor "SMZDM发现" "http://fx.smzdm.com"  "$pt" "^.*span\sclass=\"black\">([^<]*$pt[^<]*)<\/span><span\sclass=\"red\">([^<]*)<.*$"
    monitor "HH首页"    "http://www.huihui.cn" "$pt" "^\s\s*([^<]*$pt[^<]*)<em>([^<]*)<\/em>$"
    sleep 5
done
}

main $*
exit 1
