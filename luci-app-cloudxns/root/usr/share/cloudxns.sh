#!/bin/sh
#By Zy143L
#CloudXNS API

PROGRAM="CloudXNS"
On=`uci get cloudxns.shizuku.cloudxns`

API_KEY=`uci get cloudxns.shizuku.API_KEY`
#API_KEY获取

SECRET_KEY=`uci get cloudxns.shizuku.SECRET_KEY`
#SECRET_KEY获取

DOMAIN=`uci get cloudxns.shizuku.main_domain`
#主机Host

HOST=`uci get cloudxns.shizuku.sub_domain`
#Domian

IPv4_6=`uci get cloudxns.shizuku.ipv6`
#IPv4/6判断



printMsg() {
	local msg="$1"
		logger -t "${PROGRAM}" "${msg}"
		#echo $msg
} #//日志输出调用API


if [ "${On}" != "1" ];then
 exit
fi

cron=`cat /etc/crontabs/root | grep "5 * * * *" | grep cloudxns`
if [ -z "${cron}" ];then
  sed -i '/cloudxns/d' /etc/crontabs/root >/dev/null 2>&1
  echo "*/5 * * * * /usr/share/cloudxns.sh" >> /etc/crontabs/root 
fi


if [ "${IPv4_6}" == "0" ];then
	IP=`curl -s http://members.3322.org/dyndns/getip`
	if [ "$IP" == "" ];then
	printMsg "IP获取失败 请检查网络连接"
	exit
	fi
	elif [ "${IPv4_6}" == "1" ];then
		IP6=`ifconfig | awk '/Global/{print $3}' | awk -F/ '{print $1}' | sed -n '1p;1q'`
			elif [ "${IPv4_6}" == "2" ];then
				IP=`curl -s http://members.3322.org/dyndns/getip`
					if [ "$IP" == "" ];then
	printMsg "IP获取失败 请检查网络连接"
	exit
	fi
				IP6=`ifconfig | awk '/Global/{print $3}' | awk -F/ '{print $1}' | sed -n '1p;1q'`
else
exit
fi

	URL_D="https://www.cloudxns.net/api2/domain"
	DATE=`date`
	HMAC_D=`printf "%s" "${API_KEY}${URL_D}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
	DOMAIN_ID=`curl -k -s ${URL_D} -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: ${DATE}" -H "API-HMAC: ${HMAC_D}"`
	DOMAIN_ID=`echo ${DOMAIN_ID}|grep -o "id\":\"[0-9]*\",\"domain\":\"${DOMAIN}"|grep -o "[0-9]*"|head -n1`
	#echo "DOMAIN ID: $DOMAIN_ID"
	# 获得记录ID
	URL_R="https://www.cloudxns.net/api2/record/$DOMAIN_ID?host_id=0&row_num=500"
	DATE=`date`
	HMAC_R=`printf "%s" "${API_KEY}${URL_R}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
	SRECORD_ID=`curl -k -s "${URL_R}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: ${DATE}" -H "API-HMAC: ${HMAC_R}"`
	rm -rf /tmp/RECORD_ID
	echo ${SRECORD_ID} | sed "s#},{#\n#g" >/tmp/RECORD_ID
	#A_RECORD_ID=`cat /tmp/RECORD_ID`
	if [ ${IPv4_6} == "0" ];then
	domain_type=A
	RECORD_ID=`cat /tmp/RECORD_ID |grep -o "record_id\":\"[0-9]*\",\"host_id\":\"[0-9]*\",\"host\":\"${HOST}*\",*.*\"type\":\"${domain_type}\""|grep -o "record_id\":\"[0-9]*"|grep -o "[0-9]*" |head -n1`
	elif [ ${IPv4_6} == "1" ];then
	domain_type=AAAA
	RECORD_ID_6=`cat /tmp/RECORD_ID |grep -o "record_id\":\"[0-9]*\",\"host_id\":\"[0-9]*\",\"host\":\"${HOST}*\",*.*\"type\":\"${domain_type}\""|grep -o "record_id\":\"[0-9]*"|grep -o "[0-9]*" |head -n1`
	elif [ ${IPv4_6} == "2" ];then
	domain_type=A
	RECORD_ID=`cat /tmp/RECORD_ID |grep -o "record_id\":\"[0-9]*\",\"host_id\":\"[0-9]*\",\"host\":\"${HOST}*\",*.*\"type\":\"${domain_type}\""|grep -o "record_id\":\"[0-9]*"|grep -o "[0-9]*" |head -n1`
	domain_type=AAAA
	RECORD_ID_6=`cat /tmp/RECORD_ID |grep -o "record_id\":\"[0-9]*\",\"host_id\":\"[0-9]*\",\"host\":\"${HOST}*\",*.*\"type\":\"${domain_type}\""|grep -o "record_id\":\"[0-9]*"|grep -o "[0-9]*" |head -n1`
	else
        printMsg "CloudXNS动态域名 异常退出"
	fi
	URL_A="https://www.cloudxns.net/api2/record"
	DATE=`date`
	if [ "$IPv4_6" == "0" ] && [ "$RECORD_ID" == "" ];then
	printMsg "CloudXNS动态域名 IPv4模式 添加域名 ${HOST}.${DOMAIN} 记录IP $IP"
	domain_type="A"
	PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"type\":\"${domain_type}\",\"value\":\"${IP}\",\"line_id\":\"1\"}"
	HMAC_A=`printf "%s" "${API_KEY}${URL_A}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
	RESULT=`curl -k -s "${URL_A}" -X POST -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: ${DATE}" -H "API-HMAC: ${HMAC_A}" -H 'Content-Type: application/json'`
	printMsg "$RESULT"
	elif [ "$IPv4_6" == "1" ] && [ "$RECORD_ID_6" == "" ];then
	printMsg "CloudXNS动态域名 IPv6模式 添加域名 ${HOST}.${DOMAIN} 记录IP $IP6"
	domain_type="AAAA"
	PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"type\":\"${domain_type}\",\"value\":\"${IP6}\",\"line_id\":\"1\"}"
	HMAC_A=`printf "%s" "${API_KEY}${URL_A}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
	RESULT=`curl -k -s "${URL_A}" -X POST -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_A" -H 'Content-Type: application/json'`
	printMsg "$RESULT"
	elif [ "$IPv4_6" == "2" ] && [ "$RECORD_ID" == "" ] && [ "$RECORD_ID_6" == "" ];then
	printMsg "CloudXNS动态域名 IPv4/6模式 添加域名 ${HOST}.${DOMAIN} 记录IP $IP $IP6"
	domain_type="A"
	PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"type\":\"${domain_type}\",\"value\":\"${IP}\",\"line_id\":\"1\"}"
	HMAC_A=`printf "%s" "${API_KEY}${URL_A}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
	RESULT=`curl -k -s "${URL_A}" -X POST -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_A" -H 'Content-Type: application/json'`
	printMsg "$RESULT"
	domain_type="AAAA"
	PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"type\":\"${domain_type}\",\"value\":\"${IP6}\",\"line_id\":\"1\"}"
	HMAC_A=`printf "%s" "${API_KEY}${URL_A}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
	RESULT=`curl -k -s "${URL_A}" -X POST -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: $DATE" -H "API-HMAC: $HMAC_A" -H 'Content-Type: application/json'`
	printMsg "$RESULT"
	else
		# 更新记录IP
		DATE=`date`
		#URL_U="https://www.cloudxns.net/api2/record/$RECORD_ID"
		if [ "$IPv4_6" == "0" ] ;then
		printMsg "CloudXNS动态域名 IPv4模式 更新域名 ${HOST}.${DOMAIN} 记录IP $IP"
		URL_U="https://www.cloudxns.net/api2/record/${RECORD_ID}"
		PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"value\":\"${IP}\"}"
		HMAC_U=`printf "%s" "${API_KEY}${URL_U}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
		RESULT=`curl -k -s "${URL_U}" -X PUT -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: ${DATE}" -H "API-HMAC: ${HMAC_U}" -H 'Content-Type: application/json'`
		printMsg "$RESULT"
		elif [ "$IPv4_6" == "1" ] ;then
		printMsg "CloudXNS动态域名 IPv6模式 更新域名 ${HOST}.${DOMAIN} 记录IP $IP6"
		URL_U="https://www.cloudxns.net/api2/record/${RECORD_ID_6}"
		PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"value\":\"${IP6}\"}"
		HMAC_U=`printf "%s" "${API_KEY}${URL_U}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
		RESULT=`curl -k -s "${URL_U}" -X PUT -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: ${DATE}" -H "API-HMAC: ${HMAC_U}" -H 'Content-Type: application/json'`
		printMsg "$RESULT"
		elif [ "$IPv4_6" == "2" ] ;then
		URL_U="https://www.cloudxns.net/api2/record/${RECORD_ID}"
		printMsg "CloudXNS动态域名 IPv4/6模式 更新域名 ${HOST}.${DOMAIN} 记录IP $IP $IP6"
		PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"value\":\"${IP}\"}"
		DATE=`date`
		HMAC_U=`printf "%s" "${API_KEY}${URL_U}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
		RESULT=`curl -k -s "${URL_U}" -X PUT -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: ${DATE}" -H "API-HMAC: ${HMAC_U}" -H 'Content-Type: application/json'`
		#echo $RESULT
		printMsg "$RESULT"
		URL_U="https://www.cloudxns.net/api2/record/${RECORD_ID_6}"
		PARAM_BODY="{\"domain_id\":\"${DOMAIN_ID}\",\"host\":\"${HOST}\",\"value\":\"${IP6}\"}"
		DATE=`date`
		HMAC_U=`printf "%s" "${API_KEY}${URL_U}${PARAM_BODY}${DATE}${SECRET_KEY}"|md5sum|cut -d" " -f1`
		RESULT=`curl -k -s "${URL_U}" -X PUT -d "${PARAM_BODY}" -H "API-KEY: ${API_KEY}" -H "API-REQUEST-DATE: ${DATE}" -H "API-HMAC: ${HMAC_U}" -H 'Content-Type: application/json'`
		#echo $RESULT
		printMsg "$RESULT"
	fi
	fi
exit
