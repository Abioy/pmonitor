#!/bin/bash

sms_file="log/sms_msg"
wan_ip_file="wan_ip"
pt_file="last_pt"
declare wan_ip=""
declare loop=2

insert()
{
    data="$1"
    fname=`echo "$data" | md5sum | awk '{print $1}'`
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
    curl -L -v -H "User-Agent:Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36" "$url" 2>/dev/null | tr -d "\r" | tr -d "\n" | ./xpath-go "$p" "$q" | awk 'BEGIN{IGNORECASE=1} '$pt | while read line;
    do
        echo "$line" | python3.3 -c "import json; import sys; import re; j=json.loads(sys.stdin.read()); print(re.sub('\s', '', j['url']) + ' ' + re.sub('\s','',j['price']) + ' ' +  ' '.join(j['title'].split()));" |
        while read target_url price title;
        do
            abs_target_url=`./url-resolve "$url" "${target_url}" 2>/dev/null`
            key="${abs_target_url}"
            if [ "X${key}" == "X" ]; then
                key="${line}"
            fi
            insert "${key}"
            [ $? -eq 0 ] || continue
            # for webchat
            echo "[INFO] $id match: $line" && echo "<a href=\"${abs_target_url}\">${title}</a>,${price} " >> $sms_file && echo -e "\n" >> $sms_file
        done
    done
}

main()
{
    pt="/美可卓|亮碟|简境/||/美赞臣/&&/2段|安婴宝/&&/港/"
    pt="/a2|艾尔/&&/3段/||/欧乐|oral/&&/eb|刷头/&&!/净主/||/纸尿裤/&&/好奇|大王|妙而舒|Merries|moony|尤妮佳/&&/中|M[^eo]/||/米兔&3c/||/ppsu&奶瓶&300/"

    if [ $# -ge 1 ]; then
        pt=$1
    fi
    echo "[INFO] restart monitoring $pt ...";

    touch ${wan_ip_file};
    read wan_ip < ${wan_ip_file};
    touch ${pt_file};
    read last_pt < ${pt_file};
    if [ "X${last_pt}" != "X${pt}" ]; then
        echo "[INFO] pattern change. ${last_pt} -> ${pt}"
        notify "monitor pt change: ${last_pt} -> ${pt}"
        echo "${pt}" > ${pt_file}
    fi

    while true;
    do
        loop=$(($loop+1))
        sms_file="log/sms_msg.`date +%s`"
        read p q < ./xpath_expressions/m_smzdm.xpath
        monitor "" "https://m.smzdm.com"  "$pt" "$p" "$q"
        read p q < ./xpath_expressions/m_fx_smzdm.xpath
        monitor "" "https://faxian.m.smzdm.com"  "$pt" "$p" "$q"
        if [ -s "$sms_file" ];
        then
            msg=`cat $sms_file | tr "\n" " "`
            echo "[INFO] send ! `echo $msg`"
            notify "got: $msg"
            rm -f "$sms_file"
            sleep 40
        fi
        sleep 20

        if [ $loop -eq 3 ]; then
            continue
            loop=0
            new_wan_ip=`timeout 10 wget -T 10 -q --user-agent='curl/7.29.0' http://members.3322.org/dyndns/getip 2>/dev/null -O -`
            old_wan_ip=${wan_ip}
            if [ "X${new_wan_ip}" != "X${wan_ip}" ] && [ "X${new_wan_ip}" != "X" ]; then
                echo -n "${new_wan_ip}" > ${wan_ip_file}
                wan_ip=${new_wan_ip}
                echo "WanIP change: ${old_wan_ip} -> ${new_wan_ip}"
            fi
        fi
    done
}

pull()
{
    fname=$1
    tmp_fname=$2
    timeout 10 wget -T 10 --header="cache-control: no-control" --no-cache "https://raw.githubusercontent.com/Abioy/pmonitor/master/$fname" -O  "$tmp_fname" 2>/dev/null
}

pull_tools()
{
    fname=$1
    tmp_fname=$2
    timeout 60 wget -T 60 --header="cache-control: no-control" --no-cache "https://raw.githubusercontent.com/Abioy/arm-tools/master/$fname" -O  "$tmp_fname" 2>/dev/null
    chmod +x "${tmp_fname}"
}

main $*
if [ ! -e "xpath_expressions/m_fx_smzdm.xpath" ]; then
pull "xpath_expressions/m_fx_smzdm.xpath" "xpath_expressions/m_fx_smzdm.xpath"
pull "xpath_expressions/m_smzdm.xpath" "xpath_expressions/m_smzdm.xpath"
fi
exit 1
