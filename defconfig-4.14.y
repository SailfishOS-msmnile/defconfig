#!/bin/bash

FILE=$1

[ -f "$FILE" ] || {
	echo "Provide a config file as argument"
	exit
}

write=false

if [ "$2" = "-w" ]; then
	write=true
fi

CONFIGS_ON="
CONFIG_ANDROID_LOW_MEMORY_KILLER
CONFIG_ANDROID_PARANOID_NETWORK
CONFIG_AUDIT
CONFIG_AUTOFS4_FS
CONFIG_BRIDGE
CONFIG_CPUSETS
CONFIG_IP_NF_TARGET_MASQUERADE
CONFIG_IP_NF_IPTABLES
CONFIG_IP_MULTIPLE_TABLES
CONFIG_NETFILTER_NETLINK_ACCT
CONFIG_NETFILTER_XT_MATCH_NFACCT
CONFIG_NETFILTER_XT_CONNMARK
CONFIG_NETFILTER_XT_TARGET_CONNMARK
CONFIG_NETFILTER_XT_MATCH_CONNMARK
CONFIG_NETFILTER_XT_MATCH_CONNTRACK
CONFIG_NETFILTER_XT_MATCH_DCCP
CONFIG_NETFILTER_XT_MATCH_HASHLIMIT
CONFIG_NETFILTER_XT_MATCH_IPRANGE
CONFIG_NETFILTER_XT_MATCH_MARK
CONFIG_NETFILTER_XT_MATCH_MULTIPORT
CONFIG_NETFILTER_XT_MATCH_OWNER
CONFIG_NETFILTER_XT_MATCH_RECENT
CONFIG_NETFILTER_XT_MATCH_SCTP
CONFIG_NETFILTER_XT_MATCH_STATE
CONFIG_NETFILTER_XT_MATCH_PKTTYPE
CONFIG_NETFILTER_XT_MATCH_LIMIT
CONFIG_NETFILTER_XT_MATCH_HELPER
CONFIG_NETFILTER_XT_MATCH_ESP
CONFIG_IP_NF_MATCH_AH
CONFIG_IP_NF_MATCH_ECN
CONFIG_IP_NF_MATCH_TTL
CONFIG_IP6_NF_MATCH_AH
CONFIG_IP6_NF_MATCH_FRAG
CONFIG_IP6_NF_MATCH_MH
CONFIG_CGROUPS
CONFIG_CGROUP_FREEZER
CONFIG_CGROUP_DEVICE
CONFIG_CGROUP_CPUACCT
CONFIG_MEMCG
CONFIG_MEMCG_SWAP
CONFIG_MEMCG_KMEM
CONFIG_CGROUP_PERF
CONFIG_CGROUP_SCHED
CONFIG_BLK_CGROUP
CONFIG_NET_CLS_CGROUP
CONFIG_CGROUP_NET_PRIO
CONFIG_DEVTMPFS
CONFIG_FHANDLE
CONFIG_SCHEDSTATS
CONFIG_SCHED_DEBUG
CONFIG_NLS_UTF8
CONFIG_BT
CONFIG_BT_RFCOMM
CONFIG_BT_HCIUART
CONFIG_BT_HCIUART_H4
CONFIG_HIDRAW
CONFIG_UNIX
CONFIG_SYSVIPC
CONFIG_EXT4_FS
CONFIG_CUSE
CONFIG_FANOTIFY
CONFIG_INOTIFY_USER
CONFIG_IPV6
CONFIG_MODULES
CONFIG_RTC_DRV_CMOS
CONFIG_SIGNALFD
CONFIG_TIMERFD
CONFIG_EPOLL
CONFIG_NET
CONFIG_SYSFS
CONFIG_PROC_FS
CONFIG_TMPFS_POSIX_ACL
CONFIG_TMPFS_XATTR
CONFIG_SECCOMP
CONFIG_TUN
CONFIG_VT
CONFIG_LBDAF
CONFIG_WATCHDOG_NOWAYOUT
CONFIG_CHECKPOINT_RESTORE
CONFIG_RD_GZIP
CONFIG_IKCONFIG_PROC
CONFIG_DEVTMPFS_MOUNT
CONFIG_SECURITY_SELINUX
CONFIG_SECURITY_SELINUX_BOOTPARAM
CONFIG_UTS_NS
CONFIG_IPC_NS
CONFIG_PID_NS
CONFIG_NET_NS
CONFIG_SECURITY_YAMA
CONFIG_NETWORK_FILESYSTEMS
CONFIG_NFS_FS
CONFIG_NFS_V3
CONFIG_NFS_V3_ACL
CONFIG_NFS_V4
CONFIG_NFS_V4_1
CONFIG_NFS_USE_KERNEL_DNS
CONFIG_NFS_ACL_SUPPORT
CONFIG_NFS_COMMON
CONFIG_LOCKD
CONFIG_LOCKD_V4
CONFIG_SUNRPC
CONFIG_SUNRPC_GSS
CONFIG_BLK_DEV_NBD
CONFIG_ISO9660_FS
CONFIG_UDF_FS
CONFIG_ECRYPT_FS
CONFIG_F2FS_FS
CONFIG_F2FS_FS_SECURITY
CONFIG_CIFS
CONFIG_BTRFS_FS
CONFIG_IP_NF_MATCH_RPFILTER
CONFIG_IP6_NF_MATCH_RPFILTER
CONFIG_NF_NAT_IPV6
CONFIG_QUOTA
CONFIG_QUOTACTL
CONFIG_QUOTA_NETLINK_INTERFACE
CONFIG_QFMT_V2
CONFIG_NAMESPACES
CONFIG_UTS_NS
CONFIG_IPC_NS
CONFIG_PID_NS
"

CONFIGS_OFF="
CONFIG_NETFILTER_XT_MATCH_QTAGUID
CONFIG_CGROUP_MEM_RES_CTLR
CONFIG_CGROUP_MEM_RES_CTLR_SWAP
CONFIG_CGROUP_MEM_RES_CTLR_KMEM
CONFIG_NETPRIO_CGROUP
CONFIG_DUMMY
CONFIG_BT_MSM_SLEEP
CONFIG_SYSFS_DEPRECATED
CONFIG_FW_LOADER_USER_HELPER
CONFIG_SECURITY_YAMA_STACKED
"

CONFIGS_EQ="
CONFIG_UEVENT_HELPER_PATH=\"\"
CONFIG_SECURITY_SELINUX_BOOTPARAM_VALUE=\"0\"
"

ered() {
	echo -e "\033[31m" $@
}

egreen() {
	echo -e "\033[32m" $@
}

ewhite() {
	echo -e "\033[37m" $@
}

echo -e "\n\nChecking config file for Halium specific config options.\n\n"

errors=0
fixes=0

for c in $CONFIGS_ON $CONFIGS_OFF;do
	cnt=`grep -w -c $c $FILE`
	if [ $cnt -gt 1 ];then
		ered "$c appears more than once in the config file, fix this"
		errors=$((errors+1))
	fi

	if [ $cnt -eq 0 ];then
		if $write ; then
			ewhite "Creating $c"
			echo "# $c is not set" >> "$FILE"
			fixes=$((fixes+1))
		else
			ered "$c is neither enabled nor disabled in the config file"
			errors=$((errors+1))
		fi
	fi
done

for c in $CONFIGS_ON;do
	if grep "$c=y\|$c=m" "$FILE" >/dev/null;then
		egreen "$c is already set"
	else
		if $write ; then
			ewhite "Setting $c"
			sed  -i "s,# $c is not set,$c=y," "$FILE"
			fixes=$((fixes+1))
		else
			ered "$c is not set, set it"
			errors=$((errors+1))
		fi
	fi
done

for c in $CONFIGS_EQ;do
	lhs=$(awk -F= '{ print $1 }' <(echo $c))
	rhs=$(awk -F= '{ print $2 }' <(echo $c))
	if grep "^$c" "$FILE" >/dev/null;then
		egreen "$c is already set correctly."
		continue
	elif grep "^$lhs" "$FILE" >/dev/null;then
		cur=$(awk -F= '{ print $2 }' <(grep "^$lhs=" "$FILE"))
		ered "$lhs is set, but to $cur not $rhs."
		if $write ; then
			egreen "Setting $c correctly"
			sed -i 's,^'"$lhs"'.*,# '"$lhs"' was '"$cur"'\n'"$c"',' "$FILE"
			fixes=$((fixes+1))
		fi
	else
		if $write ; then
			ewhite "Setting $c"
			echo  "$c" >> "$FILE"
			fixes=$((fixes+1))
		else
			ered "$c is not set"
			errors=$((errors+1))
		fi
	fi
done

for c in $CONFIGS_OFF;do
	if grep "$c=y\|$c=m" "$FILE" >/dev/null;then
		if $write ; then
			ewhite "Unsetting $c"
			sed  -i "s,$c=.*,# $c is not set," $FILE
			fixes=$((fixes+1))
		else
			ered "$c is set, unset it"
			errors=$((errors+1))
		fi
	else
		egreen "$c is already unset"
	fi
done

if [ $errors -eq 0 ];then
	egreen "\n\nConfig file checked, found no errors.\n\n"
else
	ered "\n\nConfig file checked, found $errors errors that I did not fix.\n\n"
fi

if [ $fixes -gt 0 ];then
	egreen "Made $fixes fixes.\n\n"
fi

ewhite " "
