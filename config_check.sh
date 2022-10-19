#!/bin/sh
#
# 	Initial version
#	---------------
#
# config_check.sh --help
#
# Script for collecting system configuration details on several kind of UNIX systems.
# Supported platforms: AIX, VIO (AIX), Linux (ppc64, x86_64, x86_32), Solaris
# Supported shells: Bash, KSH. On Solaris, run the script by 'bash ./config_check.sh'
#
#  -s, --silent          Creates a .txt file under /tmp in the background instead of messing up your screen
#  -h, --help            Displays this help and exists
#  'no OPTION'           Shows everything in stdout
#
#
#
#
#
#===================================================================================================
# Version 	-> v 1.0       
# Date 		-> 2020-05-26				
#===================================================================================================

main() {

SEP="echo =========================================================================================="
export PATH=$PATH:/sbin:/usr/sbin:/etc

# Get the platform
OS=$(uname)
case "$OS" in
    "Linux")
      OSL=${OS}-$(uname -i)
      ;;
    "AIX")
      if [ -f /usr/ios/cli/ioscli ] ;
        then OSL="VIO"
        else OSL=${OS}$(uname -v).$(uname -r)
      fi
      ;;
    *)
      OSL=$OS
      ;;
esac

# Hostname, platform, uptime, system release, basic HW details
$SEP
echo "The system $(hostname) is a(n) $OSL"
$SEP
echo "╔════════════════════════════╗"
echo "║    Basic System Details    ║"
echo "╚════════════════════════════╝"
echo 
echo "<< uptime >>"
uptime
$SEP
echo "<< who -b >>"
who -b
$SEP
if [ $OS = "Linux" ] ; then
  echo "<< uname -a >>"
  uname -a
  $SEP
  echo "<< lsb_release -a >>"
  lsb_release -a
  $SEP
  echo "<< cat /etc/issue >>"
  cat /etc/issue
  $SEP
  echo "<< cat /proc/cpuinfo >>"
  cat /proc/cpuinfo
  $SEP
  echo "<< free -m >>"
  free -m
  $SEP
fi
if [ $OS = "AIX" ] ; then
  echo "<< oslevel -s >>"
  oslevel -s
  $SEP
  echo "<< lppchk -v >>"
  lppchk -v
  $SEP
  echo "<< prtconf | head >>"
  prtconf | head
  $SEP
fi
if [ $OS = "SunOS" ] ; then
  echo "<< uname -a >>"
  uname -a
  $SEP
  echo "<< prtdiag >>"
  prtdiag
  $SEP
fi
if [ $OSL = "Linux-ppc64" ] || [ $OS = "AIX" ] ; then
  echo "<< lparstat -i >>"
  lparstat -i
  $SEP
fi

# Networking
echo "<< ifconfig -a >>"
ifconfig -a
$SEP
echo "<< netstat -rn >>"
netstat -rn
$SEP
if [ $OS = "Linux" ] ; then
  echo "<< ifcfg contents >>"
  echo
  for IFCFG in $(find /etc/sysconfig -name 'ifcfg*eth*') ;
    do echo "$IFCFG:"
       cat $IFCFG
       echo
    done
  for IFCFG in $(find /etc/sysconfig -name 'ifcfg*bond*') ;
    do echo "$IFCFG:"
       cat $IFCFG 
       echo
    done
  $SEP
fi
if [ $OS = "AIX" ] ; then
  echo "<< lsattr -El inet0 >>"
  lsattr -El inet0
  $SEP
fi

# Filesystems, mounts, LVM details, disks
if [ $OS = "Linux" ] ; then
  echo "<< df -hP >>"
  df -hP
  $SEP
  echo "<< mount >>"
  mount
  $SEP
  echo "<< vgdisplay >>"
  vgdisplay
  $SEP
  echo "<< lvdisplay >>"
  lvdisplay
  $SEP
  echo "<< pvscan >>"
  pvscan
  $SEP
  echo "<< FS checks >>"
  for fs in $(df -P | awk '{ print $1 }' | grep "/dev" | grep -v "/dev/sr0") ; do df -hP $fs ; \
      tune2fs -l $fs | grep -E "ount count|Last checked|Check interval|Next check after" ; \
      echo ----- ; done
  $SEP
  echo "<< cat /etc/fstab >>"
  cat /etc/fstab
  $SEP
  echo "<< multipath -dl >>"
  multipath -dl
  $SEP
  if [ $OSL = "Linux-ppc64" ] ; then
    echo "<< vSCSI / NPIV hosts >>"
    for SH in $(ls -1 /sys/class/scsi_host)
      do echo "$(echo $SH) -> \
    $(if [ -f /sys/class/scsi_host/$SH/vhost_loc ]; \
  then cat /sys/class/scsi_host/$SH/vhost_loc ; else cat /sys/class/scsi_host/$SH/drc_name ; \
  fi) -> \
  $(cat /sys/class/scsi_host/$SH/partition_name) -> \
  $(if [ -f /sys/class/scsi_host/$SH/vhost_name ]; \
  then cat /sys/class/scsi_host/$SH/vhost_name ; else cat /sys/class/scsi_host/$SH/device_name ; \
    fi)"
      done
  $SEP
  fi
fi
if [ $OS = "AIX" ] ; then
  echo "<< df -m >>"
  df -m
  $SEP
  echo "<< mount >>"
  mount
  $SEP
  echo "<< lsvg >>"
  lsvg
  $SEP
  echo "<< lsvg -o >>"
  lsvg -o
  $SEP
  echo "<< lsvg -l >>"
  for i in $(lsvg -o) ; do echo ; lsvg -l $i ; done
  $SEP
  echo "<< lsvg -p >>"
  for i in $(lsvg -o) ; do echo ; lsvg -p $i ; done
  $SEP
  echo "<< lsfs >>"
  lsfs
  $SEP
  echo "<< lspv >>"
  lspv
  $SEP
  echo "<< lsdev -Cc adapter >>"
  lsdev -Cc adapter
  $SEP
  echo "<< lsdev -Cc disk >>"
  lsdev -Cc disk
  $SEP
  echo "<< Allocated disk capacity summary >>"
  echo "--> in rootvg: \
  $(for PV in $(lspv | awk '/rootvg/{print $1}')
      do getconf DISK_SIZE /dev/$PV ; done | paste -sd+ - | bc) MB"
  echo "--> in other VGs: \
  $(for PV in $(lspv | grep -v -E "rootvg|none|None|gpfs" | awk '{print $1}')
      do getconf DISK_SIZE /dev/$PV ; done | paste -sd+ - | bc) MB"
  echo "--> in any GPFS: \
  $(for PV in $(lspv | awk '/gpfs/{print $1}')
      do getconf DISK_SIZE /dev/$PV ; done | paste -sd+ - | bc) MB"
  echo "--> on any None PVs: \
  $(for PV in $(lspv | grep -E "none|None" | awk '{print $1}')
      do getconf DISK_SIZE /dev/$PV ; done | paste -sd+ - | bc) MB"
  $SEP
  echo "<< Used disk capacity summary >>"
  echo "--> in rootvg: \
  $(lsvg rootvg | awk '/USED PPs/{print $6}' | sed 's/(//') MB"
  echo "--> in other VGs: \
  $(for VG in $(lsvg -o | grep -v rootvg | sort -n)
      do lsvg $VG | awk '/USED PPs/{print $6}' | sed 's/(//' ; done | paste -sd+ - | bc) MB"
  $SEP
  PCMPATHPATH=`which pcmpath`
  LSMPIOPATH=`which lsmpio`
  if [ -n "${PCMPATHPATH}" ] ; then
    echo "<< pcmpath information >>"
    echo "<< pcmpath query adapter >>"
    ${PCMPATHPATH} query adapter
    $SEP
    echo "<< pcmpath query device >>"
    ${PCMPATHPATH} query device
    $SEP
    echo "<< pcmpath query wwpn >>"
    ${PCMPATHPATH} query wwpn
    $SEP
    else 
        echo ""
        echo "No PCMPATH on this device"
        $SEP
        echo ""
        echo "<< Information about the MultiPath I/O (MPIO) storage devices >>"
        echo "<< MPIO adapters >>"
        ${LSMPIOPATH} -are
        $SEP
        echo "<< MultiPath I/O (MPIO) WWPNs >>"
        ${LSMPIOPATH} -a |grep WWPN
        $SEP
        echo "<< MultiPath I/O (MPIO) devices, serials >>"
        for i in `${LSMPIOPATH} -q |grep hdisk |awk '{print $1}'`;do echo "$i`${LSMPIOPATH} -ql $i |grep Serial`";done
        $SEP
        echo "<< MultiPath I/O (MPIO) disk sizes >>"
        ${LSMPIOPATH} -q
        $SEP
  fi
  if [ -e /usr/bin/xiv_devlist ] ; then
    echo "<< xiv_devlist >>"
    xiv_devlist
    $SEP
  fi
  echo "<< bootlist -m normal -o >>"
  bootlist -m normal -o
  $SEP
  echo "<< vSCSI / NPIV hosts >>"
  if [ $(lsdev -Cc disk | grep "$PV " | awk -F'Available' '{print $2}' | grep MPIO | wc -l) -gt 0 ];
    then LUNTYPE="NPIV"
    else LUNTYPE="vSCSI"
  fi
  if [ $LUNTYPE = "NPIV" ];
    then VIO=$(echo vfcs | kdb | awk '/vfcho/{print $4}' | paste -sd\; -)
    else VIO=$(echo cvai | kdb | awk '/vhost/{print $5}' | paste -sd\; -)
  fi
  echo $VIO
  $SEP
  echo "<< ipldevice check >>"
  ls -l /dev/$(bootlist -m normal -o | head -1 | awk '{ print $1 }') /dev/ipldevice
  $SEP
fi
if [ $OS = "SunOS" ] ; then
  echo "<< df -h >>"
  df -h
  $SEP
  echo "<< mount >>"
  mount
  $SEP
  echo "<< zpool list >>"
  zpool list
  $SEP
  echo "<< zfs list >>"
  zfs list
  $SEP
  echo "<< svcs -a >>"
  svcs -a
  $SEP
  echo "<< zoneadm list -cv >>"
  zoneadm list -cv
  $SEP
fi

# System services
if [ $OS = "Linux" ] ; then
  echo "<< chkconfig --list >>"
  chkconfig --list
  $SEP
fi
if [ $OS = "AIX" ] ; then
  echo "<< lssrc -a >>"
  lssrc -a | head -1 ; lssrc -a | grep -v Subsystem | sort -n
  $SEP
  echo "<< lssrc -g cluster >>"
  lssrc -g cluster
  $SEP
  echo "<< lssrc -g spooler >>"
  lssrc -g spooler
  $SEP
  echo "<< lssrc -g nfs >>"
  lssrc -g nfs
  $SEP
fi
if [ $OS = "SunOS" ] ; then
  echo "<< svcs >>"
  svcs
  $SEP
fi
echo "<< crontab -l >>"
crontab -l
$SEP
echo "<< cat /etc/inittab >>"
cat /etc/inittab
$SEP
if [ -f /usr/es/sbin/cluster/utilities/clRGinfo ] ; then
  echo "╔═════════════════════╗"
  echo "║    PowerHA Setup    ║"
  echo "╚═════════════════════╝"
  echo 
  echo "<< cltopinfo >>"
  /usr/es/sbin/cluster/utilities/cltopinfo
  $SEP
  echo "<< clRGinfo >>"
  /usr/es/sbin/cluster/utilities/clRGinfo
  $SEP
  echo "<< cllsserv >>"
  /usr/es/sbin/cluster/utilities/cllsserv
  $SEP
  echo "<< cllsif >>"
  /usr/es/sbin/cluster/utilities/cllsif
  $SEP
  echo "<< cllsfs >>"
  /usr/es/sbin/cluster/utilities/cllsfs
  $SEP
fi
if [ $OSL = "VIO" ] ; then
  echo "╔═════════════════════════╗"
  echo "║    VIO Configuration    ║"
  echo "╚═════════════════════════╝"
  echo 
  echo "<< ioslevel >>"
  /usr/ios/cli/ioscli ioslevel
  $SEP
  echo "<< Shared Ethernet Adapters >>"
  for SEA in `lsdev | grep "Shared Ethernet" | awk '{ print $1 }'` ; do \
  echo "--- $SEA: --------------------" ; lsattr -El $SEA ; echo ; done
  $SEP
  echo "<< lsmap -all >>"
  /usr/ios/cli/ioscli lsmap -all
  $SEP
  echo "<< lsmap -all -net >>"
  /usr/ios/cli/ioscli lsmap -all -net
  $SEP
  echo "<< lsmap -all -npiv >>"
  /usr/ios/cli/ioscli lsmap -all -npiv
  $SEP
fi
echo "╔═════════════════╗"
echo "║    IBM Tools    ║"
echo "╚═════════════════╝"
echo 
echo "<< ITM agents >>"
ps -ef | grep [I]TM
echo -----
echo "<< Standard cinfo -r >>"
if [ -f /opt/IBM/ITM/bin/cinfo ] ;
  then /opt/IBM/ITM/bin/cinfo -r
fi
$SEP
echo "<< Tivoli endpoint >>"
ps -ef | grep [l]cfd
$SEP
echo "<< TSM Client >>"
ps -ef | grep [d]smc
$SEP
echo "<< TSCM Client >>"
ps -ef | grep [j]acclient
$SEP
echo "<< BlueWisdom >>"
ps -ef | grep [r]esamad
$SEP
echo "<< IEM (BigFix) >>"
ps -ef | grep -i [b]escli
$SEP
echo "<< SRM >>"
ps -ef | grep [p]erfmgr
$SEP
echo "<< NMON >>"
ps -ef | grep -i [n]mon
$SEP
echo "╔════════════════╗"
echo "║    Services    ║"
echo "╚════════════════╝"
echo 
if [ $(ps -ef | egrep -i "[W]ebSphere|[H]ttpServer|[h]ttpd" | wc -l) -gt 0 ] ; then
  echo "<< Running WAS / IHS / Apache instances >>"
  ps -ef | egrep -i "[W]ebSphere|[H]ttpServer|[h]ttpd" | awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9}' \
         | sort -n
  $SEP
fi
if [ $(ps -ef | grep [j]boss | wc -l) -gt 0 ] ; then
  echo "<< Running JBoss processes >>"
  ps -ef | grep [j]boss
  $SEP
fi
if [ $(ps -ef | grep [m]qm | wc -l) -gt 0 ] ; then
  echo "<< MQM check >>"
  ps -fu mqm
  echo -----
  echo "<< MQ Queue Manager's status >>"
  echo -----
  su - mqm -c "dspmq"
  echo -----
  $SEP
fi
if [ $(ps -ef | egrep -i "[t]ws|[m]aestro" | wc -l) -gt 0 ] ; then
  echo "<< TWS >>"
  ps -ef | egrep -i "[t]ws|[m]aestro"
  $SEP
fi
if [ $(ps -ef | grep [d]b2sysc | wc -l) -gt 0 ] ; then
  echo "<< Running DB2 SIDs >>"
  ps -ef | grep [d]b2sysc
  echo -----
  echo "<< Active DB2 connections >>"
  echo -----
  for INST in $(ps -ef | grep [d]b2sysc | awk '{ print $1 }') ;
    do
      echo $INST:
      su - $INST -c "sleep 1 ; db2 list applications"
      echo -----
    done
  $SEP
fi
if [ $(ps -ef | grep [s]mon | wc -l) -gt 0 ] ; then
  echo "<< Running Oracle SIDs >>"
  ps -ef | grep [s]mon
  $SEP
fi
if [ $(ps -ef | grep "[s]apstart pf=" | wc -l) -gt 0 ] ; then
  echo "<< Running SAP instances >>"
  ps -ef | grep "[s]apstart pf=" | sort -n
  $SEP
fi
echo "<< ps -ef >>"
ps -ef
$SEP

echo "<< Services listening on a port >>"
if [ $OS = "Linux" ] ; then
    netstat -natp|grep LISTEN
fi
if [ $OS = "AIX" ] ; then
    netstat -nat|grep LISTEN
fi

$SEP
echo "╔══════════════════════════════════╗"
echo "║    SSH, SSL, OS, Subscription    ║"
echo "╚══════════════════════════════════╝"
echo 
echo "<< SSH and OpenSSL status >>"
SSHCOMMAND=`which ssh`
if [ $OUTFILE = "NO" ]; then
	${SSHCOMMAND} -V 2>&1
	else
	${SSHCOMMAND} -V >> $OUTFILE 2>&1
fi
echo "-----"
OPENSSLCOMMAND=`which openssl`
${OPENSSLCOMMAND} version
$SEP

if [ $OS = "Linux" ]; then
	echo "<< Linux OS Release: >>"
	OSR=`cat /etc/*release|grep -E "Fedora|CentOS|Red|Ubuntu|SUSE"|tail -1`
	echo $OSR
fi

#REDHAT
grep Red /etc/*release >/dev/null 2>&1
ERR=`echo $?`
if [ $ERR -eq 0 ]; then
	$SEP
	echo "<< Red Hat Subscrition / License: >>"
	subscription-manager list --consumed
	$SEP
	echo "<< Red Hat Repositories: >>"
	yum repolist
fi

#SUSE
grep SUSE /etc/*release >/dev/null 2>&1
ERR=`echo $?`
if [ $ERR -eq 0 ]; then
	$SEP
	echo "<< SUSE Registration: >>"
	if [ ! -f /var/cache/SuseRegister/lastzmdconfig.cache ]; then
		echo "Not Activated or Expired!"
		else
		GUID=$(grep guid /var/cache/SuseRegister/lastzmdconfig.cache | grep zmdconfig | grep catalog | grep success |grep OK | head -n 1 | sed 's/^.*<guid>//g' | sed 's/<\/guid.*$//g')
		if [ -z "${GUID//[a-z0-9]}" ]; then
			echo "Activated!"
			else
			echo "Not Activated or Expired!"
		fi
	fi
$SEP
echo "<< SUSE Repositories: >>"
zypper repos
fi

if [ $OS = "Linux" ]; then
	$SEP
fi

}

silent() {
  OUTFILE=/tmp/$(hostname).config.$(date +%Y%m%d)-$(date +%H%M).txt
  echo "Collecting is in progress... you will find the results in file $OUTFILE when done."
  cat /dev/null > $OUTFILE
  exec 3>>$OUTFILE
  # exec 2>&3  # Sending stderr is not necessary
  exec 1>&3
}

help () {
  echo "Usage: $0 [OPTION]"
  echo "Script for collecting system configuration details on several kind of UNIX systems."
  echo "Supported platforms: AIX, VIO (AIX), Linux (ppc64, x86_64, x86_32), Solaris"
  echo "Supported shells: Bash, KSH. On Solaris, run the script by 'bash $0'"
  echo
  echo "  -s, --silent          Creates a .txt file under /tmp in the background instead of messing up your screen"
  echo "  -h, --help            Displays this help and exists"
  echo "  'no OPTION'           Shows everything in stdout"
}

case "$1" in
    -s|--silent)
      silent
      main
      ;;
    -h|--help)
      help
      ;;
    *)
      OUTFILE="NO"
      main
      ;;
esac


### test-01
