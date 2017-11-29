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
#    python ../wechat_notify/wechat_notify.py "$msg"
    python3.3 ../wechat_notify/wechat_notify_3.py "$msg"
    echo "发送微信消息提醒"
    return 0
}

notify()
{
    msg="$*"
    rc=0

    wx_txt_msg "$msg"
    [ $? -eq 0 ] || rc=1
    
    return $rc
}

monitor()
{
    id=$1
    url=$2
    pt="$3"
    p="$4"
    q="$5"
    curl -L -v -H "User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36" "$url" 2>/dev/null | tr -d "\r" | ./xpath-go "$p" "$q" | grep -E "$pt" | while read line;
    do
        insert "$line"
        [ $? -eq 0 ] || continue
        echo "$line" | python3.3 -c "import json; import sys; import re; j=json.loads(sys.stdin.read()); print(re.sub('\s', '', j['url']) + ' ' + re.sub('\s','',j['price']) + ' ' +  ' '.join(j['title'].split()));" |
        while read target_url price title;
        do
            # for webchat
            echo "[INFO] $id match $pt : $line" && echo "<a href=\"${target_url}\">${title}</a>,${price} " >> $sms_file && echo -e "\n" >> $sms_file
        done
    done
}

main()
{
    pt="(Les|亮碟)"

    if [ $# -ge 1 ]; then
        pt=$1
    fi
    echo "[INFO] restart monitoring $pt ..."
    while true;
    do
        sms_file="log/sms_msg.`date +%s`"
        read p q < ./xpath_expressions/m_smzdm.xpath
        monitor "" "http://m.smzdm.com"  "$pt" "$p" "$q"
        monitor "" "http://m.faxian.smzdm.com"  "$pt" "$p" "$q"
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
