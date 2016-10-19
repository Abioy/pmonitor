#!/bin/bash

sms_file="log/sms_msg"

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

async_wx_txt_msg()
{
    msg="$*"
    echo -n "$msg" > /tmp/smzdm_msg
    echo "发送微信消息提醒"
    return 0
}

wx_txt_msg()
{
    msg="$*"
    python ../wechat_notify/wechat_notify.py "$msg"
    echo "发送微信消息提醒"
    return 0
}

notify()
{
    msg="$*"
    rc=0
#    cat watcher.lst | while read usr;
#    do
#        sms "$usr" "$msg"
#        [ $? -eq 0 ] || rc=1
#    done

#    async_wx_txt_msg "$msg"

    wx_txt_msg "$msg"
    
    [ $? -eq 0 ] || rc=1
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
    curl -L -v -H "User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36" "$url" 2>/dev/null | tr -d "\r" | sed -r -n -e '/'$pt'/ {N;s/'$match'/\1, \3/p}' 2>/dev/null | while read line;
    do
        insert "$line"
        [ $? -eq 0 ] && echo "[INFO] $id match $pt : $line" && echo "${id}:${line}, " >> $sms_file
    done
}

main()
{
    pt="(洗碗机|美赞臣.*奶粉|奶粉.*美赞臣|纸尿裤)"

    if [ $# -ge 1 ]; then
        pt=$1
    fi
    echo "[INFO] restart monitoring $pt ..."
    while true;
    do
        sms_file="log/sms_msg.`date +%s`"
#        monitor "SMZDM首页" "http://www.smzdm.com" "$pt" "^.*target=\"_blank\">([^<]*$pt[^<]*)<span\sclass=\"red\">([^<]*)<\/span.*$"
#        monitor "SMZDM发现" "http://faxian.smzdm.com"  "$pt" "^.*span\sclass=\"black\">([^<]*$pt[^<]*)<\/span><span\sclass=\"red\">([^<]*)<.*$"
        monitor "HH首页"    "http://www.huihui.cn" "$pt" "^\s\s*([^<]*$pt[^<]*)<em>([^<]*)<\/em>.*$"
        monitor "SMZDM首页" "http://m.smzdm.com"  "$pt" "^\s\s*<h2>([^<]*$pt[^<]*)<\/h2>\n\s*<div\s\s*class=\"tips\"><em>([^<]*)<.*"
        monitor "SMZDM发现" "http://m.faxian.smzdm.com"  "$pt" "^\s\s*<h2>([^<]*$pt[^<]*)<\/h2>\n\s*<div\s\s*class=\"tips\"><em>([^<]*)<.*"
        if [ -s "$sms_file" ];
        then
            msg=`cat $sms_file | tr "\n" " "`
            echo "[INFO] send ! `echo $msg`"
            notify "got $pt: $msg"
            rm -f "$sms_file"
            sleep 40
        fi
        sleep 20
    done
}


main $*
exit 1
