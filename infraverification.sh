#!/usr/bin/ksh
#
# SCRIPT: infraverification.sh
# USAGE : ./infraverification.sh
#
# AUTHOR: PRAKASH DAYALAN (prakashdayalan@dbs.com)
# MODIFIER : PRAKASH DAYALAN (prakashdayalan@dbs.com)
#
# APPROVER : Ashish Bhan (ashishbhan@dbs.com)
#
# DATE: 11/Apr/2017
# REV: 2.4
#
# PLATFORM: AIX
#
# Update : 6:25 PM 8/15/2014 : Updated tripwire logic issues
# Update : 12:26 PM 22/8/2014 : Updated startup script logic for ssh & tsm
# Update : 05/April/2015 : Updated Script for all auto check
# Update : 04/August/2015 : Updated Script based on latest AIX Cookbook v2.4
# Update : 30/October/2015 : Minor Bug Fix
# Update : 02/November/2016 : Minor Bug Fix, HDS Disks
# Update : 11/Apr/2017 : Minor Bug Fix, Add SDCS, Remove System Director
#
# PURPOSE: This shell script is to perform BAU Health check to make sure
#          everything configured according to recommanded values
#
# set -n # Uncomment to check the script syntax without any execution
# set -x # Uncomment to debug this shell script
##################################################################################


############## T R A P CLEAN IF ANY USER INTERRUPTED

trap 'echo; echo Interrupted by user... Please wait| tee -a $LOGGER;rm -rf $OUTDIR;cleanup;tput rmso;sleep 2;exit 1' 1 2 3 15

############## H T M L  HEADER

function DrawHtmlFileHead {

        echo "<html>"
        echo "<style type=text/css>"
        echo "td { border-bottom:1px solid #D8D8D8; } </style>"
        echo "<body>"
        echo "<pre><hr><b><font size=5>$(uname) Infraverification : $(uname -n) </font></b><br><hr></pre>"
        echo "<table border=1 cellspacing='0' cellpadding='3' style='table-layout:fixed; width=100%;"
        echo "     font-size:10.0pt; font-family:Verdana, border-collapse: collapse' align='left' valign='center' >"
        echo "<col width=5%><col width=25%><col width=25%><col width=3%><col width=3%><col width=29%><col width=15%>"

}

############## H T M L  PARAMETER TAB

function DrawSecHead {

        head_cap="$1"
        printf "%s%s%s\n" "<tr><td colspan=7><br><b>" "<font size=4><i>$head_cap</i></font>" "</b></td></tr>"

        echo "<tr BGCOLOR='D8D8D8'>"
        echo "<td width='5%'> S.NO </td>"
        echo "<td width='25%'> System Value/ Parameter </td>"
        echo "<td width='25%'> Standard Setting </td>"
        echo "<td width='3%'> Std Bld </td>"
        echo "<td width='3%'> Auto Chk </td>"
        echo "<td width='29%'> Actual Setting </td>">>$HTMLLogFile
        echo "<td width='10%'> Remark </td>"
        echo "</tr>"

}

############## H T M L  SUB TITLE

function DrawSubHead {

    head_cap="$1"
    printf "%s%s%s\n" "<tr><td colspan=7><br><b>" "$head_cap" "</b></td></tr>"  >>$HTMLLogFile
    echo "<tr BGCOLOR='ccffff''>" >>$HTMLLogFile
    echo "            </tr>" >>$HTMLLogFile
        return 0
}


############## H T M L VALUE TABLE

function DrawItem {

        itemno="$1"
        item="$2"
        p_set="$3"
        stdbld="$4"
        autochk="$5"
        c_set="$6"
        vio="$7"

        echo  "<tr><td valign='top' align='left' style='word-wrap: break-word;'> $itemno </td>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'> $item </td>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'> $p_set </td>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'> $stdbld </td>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'> $autochk </td>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'> $c_set </td>"

        if [[ "$vio" = "Compliant" ]] || [[ "$vio" = "compliant" ]]
        then
        #echo "<td valign='center' align='left' style='word-wrap: break-word;'><ul> $vio </ul></td></tr>"
        #echo "<td valign='top' align='left' style='word-wrap: break-word;'><ul> $vio </ul></td></tr>"
        #echo "<td valign='top' align='left' style='word-wrap: break-word;'><font color='#31B404'><ul>$vio </ul></td></tr>"
        #echo "<td valign='top' align='left' style='word-wrap: break-word;'><font color='#008000'><ul><b>$vio</b></ul></td></tr>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'><font color='#008000'><b>$vio</b></td></tr>"
        elif [[ "$vio" = "Non-Compliant" ]]
        then
        #echo  "<td valign='top' align='left' style='word-wrap: break-word;'><font color='ff0000'><ul> $vio </ul></td></tr>"
        #echo  "<td valign='center' align='left' style='word-wrap: break-word;'><font color='ff0000'><ul><b>$vio</b> </ul></td></tr>"
        echo  "<td valign='center' align='left' style='word-wrap: break-word;'><font color='ff0000'><b>$vio</b> </td></tr>"
        else
        #echo "<td valign='center' align='left' style='word-wrap: break-word;'><font color='0000A0'><ul> $vio </ul></td></tr>"
        #echo "<td valign='top' align='left' style='word-wrap: break-word;'><font color='0000A0'><ul> $vio </ul></td></tr>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'><font color='0000A0'> $vio </td></tr>"
        fi
                 return 0
}

############## PuTTy FORMAT
bold ()
{
tput bold
}
#
unbold ()
{
tput rmso
}
blank ()
{
echo "" | tee -a $LOGGER
}

############## R O O T AUTHORIZATION
checkroot ()
{
        OS=`uname`
        if [ $OS != "AIX" ]
        then
                        bold
                        echo "This script is meant for AIX only"
                        unbold
                        exit
        fi

        ROOT=`id | cut -b 5`
        if [ $ROOT -ne 0 ]
        then
                        bold
                        echo "U MUST BE A ROOT TO EXECUTE THIS SCRIPT"
                        unbold
                        exit
        fi
}

BAUScreen()
{
        clear
        echo "\n"
        echo "\t\t ***  Performing Infra Verification on \"$(hostname)\" **\n "
}

############## V A R I A B L E S
initialize()
{
        OUTDIR="/tmp/BAUCHK"
        HOSTNAME=`hostname|awk '{print tolower($1)}'`
        DATE=`date | awk '{ DAY=$3 } { MONTH=$2 } { YEAR=$6 } END { print DAY MONTH YEAR }'`
        LOGGER="$OUTDIR/aix_bau_os.$HOSTNAME.log"
        #HTMLLogFile="$OUTDIR/aix_bau_os.$HOSTNAME.htm"
        HTMLLogFile="$OUTDIR/$HOSTNAME.`uname`.infraverification.htm"
        DEVIATION="$OUTDIR/aix_bau_os.$HOSTNAME.devlog"
        export ODMDIR=/etc/objrepos
}


############## O U T P U T DIRECTORY
mk_outdir()
{

        [ -d $OUTDIR ] && (rm -rf $OUTDIR;mkdir -p $OUTDIR) || mkdir -p  $OUTDIR

}

TEST ()
{
        if test -f $1
        then
                rm $1
                touch $1
        else
                touch $1
        fi
}

############## S Y S T E M BASIC INFORMATION
sysinfo ()
{

        OS=$(uname -s)
        OSVER=$(oslevel -s)
        prtconf > temporary.txt
        SUBNETMASK=$(cat temporary.txt|grep -w "Sub Netmask"|awk '{print $3}')
        IPADD=$(cat temporary.txt |grep "IP Address"|awk '{print $3}')
        HostIs="$(uname -n)"
        HostSerial="$(lsattr -El sys0 -a systemid | cut -d ' ' -f 2)"
        HostModel="$(lsattr -El sys0 -a modelname | cut -d ' ' -f 2)"
        HostFware="$(lsattr -El sys0 -a fwversion | cut -d ' ' -f 2)"
        ProcType="$(lparstat -i | grep -w Type | tr -s ' ' | cut -d ':' -f 2)"
        ProcMode="$(lparstat -i | grep -w Mode | tr -s ' ' | grep -v "Power Saving Mode" | grep -v "Memory Mode" | cut -d ':' -f 2)"
        EC="$(lparstat -i | grep -w "Entitled Capacity" | tr -s ' ' | grep -v Pool | cut -d ':' -f 2)"
        VCPUS="$(lparstat -i | grep -w "Online Virtual CPUs" | tr -s ' ' | cut -d ':' -f 2)"
        MEM="$(lparstat -i | grep -w  "Online Memory" | tr -s ' '| cut -d ':' -f 2)"
        SUDOVER="$(sudo -V | grep ^"Sudo version" | awk '{print $3}')"
        ProcImpMode="$(prtconf | grep "Processor Implementation Mode" | awk -F ":" '{print $2}')"
        APPIS="$App"

# SSH Software and Its version.
for i in SSHTectia.Client WRQ.RSIT.Server openssh.base.server F-Secure.SSH.Server RSIT.ssh.Server dbsStd.SSHTectia.server
do
lslpp -L $i >/dev/null 2>&1 && SSHVER=$(lslpp -L $i|grep $i|grep -v grep|tr -s " "|cut -d" " -f3)
 if [ $? -eq 0 ]
  then
        case $i in
                SSHTectia.Client)
                                SSHSW="Tectia $SSHVER"
                                ;;
                WRQ.RSIT.Server|RSIT.ssh.Server|F-Secure.SSH.Server)
                                SSHSW="F-Secure $SSHVER"
                                ;;
                openssh.base.server)
                                SSHSW="OpenSSH $SSHVER"
                                ;;
                dbsStd.SSHTectia.server)
                                SSHSW="Tectia $SSHVER"
                                ;;
        esac
 fi
done

#######################################################################################################
#Software Version
for i in VRTSvcs cluster.es.server.rte gpfs.base mqm.base.runtime
do
lslpp -l $i >/dev/null 2>&1 && VER=$(lslpp -L $i|grep $i|grep -v grep|tr -s " "|cut -d" " -f3) || VER="NA"
  case $i in
        VRTSvcs)
                VCSVER="$VER"
                export VCSVER
                ;;
 cluster.es.server.rte)
                HACMP="$VER"
                export HACMP
                ;;
 gpfs.base)
                GPFS="$VER"
                export GPFS
                ;;
 mqm.base.runtime)
                MQ="$VER"
                export MQ
                ;;
 esac
done

#######################################################################################################
#CD Version
      test -f /usr/lpp/cdunix/etc/cdver && CDVER=$(/usr/lpp/cdunix/etc/cdver|cut -d":" -f2|tr -s " "|cut -d" " -f5) || CDVER="NA"
      CDVER=${CDVER%,}
#########################################################################################
#WAS Software Version
WASFS=$(/usr/bin/df -k|grep -i WebSphere|grep -v log|tr -s " "|cut -d" " -f7|head -1)
 if [ ! -z $WASFS ]
 then
        WASCMD=$(/usr/bin/find $WASFS -xdev -name versionInfo.sh -print|head -1)
  if [ ! -z $WASCMD  ]
  then
        WAS=$($WASCMD|grep ^Version|grep -v Directory|tr -s " "|cut -d" " -f2|tail -1)
  else
        WAS="NA"
   fi
 else
        WAS="NA"

 fi
#######################################################################################################
#IHS Software Version
IHSFS=$(/usr/bin/df -k|grep -i IBMIHS|grep -v log|tr -s " "|cut -d" " -f7|head -1)
 if [ ! -z $IHSFS ]
 then
        IHSCMD=$(/usr/bin/find $IHSFS -xdev -name versionInfo.sh -print|head -1)
   if [ ! -z $IHSCMD  ]
    then
        IHS=$($IHSCMD|grep ^Version|grep -v Directory|tr -s " "|cut -d" " -f2|tail -1)
    else
        IHS="NA"
   fi
 else
        IHS="NA"
 fi

########################################################################################################
#Operation system Edition
OSEDI=$(/usr/sbin/chedition -l)

#echo "<tr><td width='100%' BGCOLOR='FBEFEF'><b>Version - Release Levels/applicable to:</b></td><td colspan=>AIX Version 5.3, 6.x and 7.x</td></tr>
echo "<tr><td BGCOLOR='D8D8D8' colspan=2><b>Version - Release Levels/applicable to:</b></td><td colspan=5>AIX Version 5.3, 6.x and 7.x</td></tr>
<tr><td colspan=7><br></td></tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>SP Checklist V2.4(Script approved Month/Year: Apr 2017)</b></td></tr>
<tr><td colspan=7><br></td></tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>Servers General Information</b></td></tr>
<tr><td colspan=7>Application/Project Name: $App</td></tr>
<tr><td colspan=2>Host/Device Name: ${HostIs}</td>  <td colspan=2>IP Address(es): ${IPADD}</td>  <td colspan=3>Subnet mask(s): ${SUBNETMASK}</td>  </tr>
<tr><td colspan=2>Host/Device Serial: ${HostSerial}</td>  <td colspan=2> Server Model: ${HostModel}</td>  <td colspan=3> System Firmware: ${HostFware}</td>  </tr>
<tr><td colspan=2>Processor Type: ${ProcType}</td>  <td colspan=2> Processor Mode: ${ProcMode}</td>  <td colspan=3> Entitled Capacity: ${EC}</td>  </tr>
<tr><td colspan=2> Virtual CPUS: ${VCPUS}</td>  <td colspan=2> Real Memory: ${MEM}</td> <td colspan=3> Processor Implementation Mode: ${ProcImpMode}</td> </tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>Software Version Information</b></td></tr>
<tr><td colspan=2>Operating System: $OS</td> <td colspan=2>OS Version/Service Pack: ${OSVER}</td> <td colspan=3> OS Edition : ${OSEDI} </td> </tr>
<tr><td colspan=2> ConnectDirect : ${CDVER}</td>  <td colspan=2> IHS: ${IHS}</td>  <td colspan=3> WAS Version : ${WAS} </td>  </tr>
<tr><td colspan=2> HACMP Version: ${HACMP}</td>  <td colspan=2> Veritas Cluster services: ${VCSVER}</td>  <td colspan=3> GPFS Version : ${GPFS} </td>  </tr>
<tr><td colspan=2>SUDO Version : ${SUDOVER}</td> <td colspan=2> MQ Version : ${MQ}</td> <td colspan=3> SSH Version : ${SSHSW}</td></tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>Document Notations</b></td></tr>
<tr><td colspan=7> StandardBuild/AutoChck : M - Manual, C - Candidate for automation, A - Automated </td>  </tr>
<tr><td colspan=7><br></td></tr>
<tr><td colspan=7><b>SP Checklist V2.4(Script approved Month/Year: Apr 2017)<br></td></tr>
<tr><td colspan=7><b>Check started at: `date`</b></td></tr>
<tr><td colspan=7><br></td></tr>"

}


####################### M A I N  P R O G R A M ##################################

#####################
# Function : checkroot
# Description : Verifying authorization

checkroot

BAUScreen

initialize

mk_outdir

TEST $LOGGER
TEST $HTMLLogFile
TEST $DEVIATION

prtconf > $OUTDIR/prtconf.txt

DrawHtmlFileHead >> $HTMLLogFile

sysinfo >> $HTMLLogFile

################ Section A Starts #####################

DrawSecHead "Section A: AIX Operating System" >> $HTMLLogFile

echo "$(date) : AIX Operating System Settings Verification"

####
DrawSubHead "1. General"  >>$HTMLLogFile
####

#A1
DescNo="A1"
DescItem="Hostname"
policy_reco="Hostname must be set in accordance with Naming Standard for Servers"
STDBLD="A"
AUTOCHK="A"
how_to="uname -n"
OSIS=$(uname)
HNAME=$(uname -n)
HOSTS=$(hostname | cut -c1-3) > /dev/null 2>&1
if [ `echo $HOSTS | tr -s '[:upper:]' '[:lower:]'` = "a01" ]
        then
        hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]' |grep 'a01' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Singapore Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Singapore Standard"
        fi
elif [ `echo $HOSTS | tr -s '[:upper:]' '[:lower:]'` = "a03" ]
        then
        hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]' |grep 'a03' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Hong Kong Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Hong Kong standard"
        fi
elif [ `echo $HOSTS | tr -s '[:upper:]' '[:lower:]'` = "a07" ]
        then
        hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]' |grep 'a07' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Indonesia Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Indonesia standard"
        fi
elif [ `echo $HOSTS | tr -s '[:upper:]' '[:lower:]'` = "a05" ]
        then
        hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]' |grep 'a05' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>China Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not China standard"
        fi
elif [ `echo $HOSTS | tr -s '[:upper:]' '[:lower:]'` = "a11" ]
        then
        hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]' |grep 'a11' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Taiwan Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Taiwan standard"
        fi
elif [ `echo $HOSTS | tr -s '[:upper:]' '[:lower:]'` = "a06" ]
        then
        hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]' |grep 'a06' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>India Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not India standard"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A2
DescNo="A2"
DescItem="IP Address & subnetmask"
policy_reco="Ensure the subnetmask is entered correctly"
STDBLD="A"
AUTOCHK="A"
how_to="prtconf"
cat $OUTDIR/prtconf.txt | grep -E "IP|Sub" | awk '{print $1$2$3}' > $OUTDIR/ipsub.txt 2>&1
SN=`prtconf | grep Sub | awk '{print $3}'`
SN1="255.255.255.248"
SN2="255.255.255.240"
SN3="255.255.255.224"
SN4="255.255.255.192"
SN5="255.255.255.128"
SN6="255.255.255.0"
SN7="255.255.254.0"
SN8="255.255.252.0"
if ([ "$SN" -eq "$SN1" ] || [ "$SN" -eq "$SN2" ] || [ "$SN" -eq "$SN3" ] || [ "$SN" -eq "$SN4" ] || [ "$SN" -eq "$SN5" ] || [ "$SN" -eq "$SN6" ] || [ "$SN" -eq "$SN7" ] || [ "$SN" -eq "$SN8" ])
then
violations=Compliant
else
violations="Non-Compliant"
fi
printf "%-6s: %-6s: %-30s: %-15s: %-16s: %-16s: %s\n" "Adap" "Vlan" "Slot" "MAC" "IP" "SUBNET" "ALIAS"    >> $OUTDIR/ether.txt
for netint in `ifconfig -l`
        do
#        NETINT="$(ifconfig $netint | egrep "en[0-99]|lo[0-99]" | tr -d ':' | awk '{print $1}')" > /dev/null 2>&1
        NETINTP="$(echo $netint |sed 's/en/ent/')" > /dev/null 2>&1
        NETIP="$(lsattr -El $netint -a netaddr -F value)" > /dev/null 2>&1
	NETSUBN="$(lsattr -El $netint -a netmask -F value)" > /dev/null 2>&1
	NETALIAS="$(lsattr -El $netint -a alias4 -F value | tr '\012'  ':' | sed 's/.$//')" > /dev/null 2>&1
        VLAN="$(entstat -d $NETINTP | grep "Port VLAN ID" | tr -d 'Port VLAN ID:')" > /dev/null 2>&1
        ENSLOT="$(lscfg -l $NETINTP | awk '{print $2}')" > /dev/null 2>&1
	ENMAC=`lscfg -vpl $NETINTP | grep Network | awk '{print $2}' |sed 's/\Address.............//g'` > /dev/null 2>&1
        printf "%-6s: %-6s: %-30s: %-15s: %-16s: %-16s: %s\n" "$NETINTP" "$VLAN" "$ENSLOT" "$ENMAC" "$NETIP" "$NETSUBN" "$NETALIAS"  >> $OUTDIR/ether.txt
        done
VALUE1="$(cat $OUTDIR/ipsub.txt)"
VALUE2="$(cat $OUTDIR/ether.txt)"
VALUE="$VALUE1<br><br>$VALUE2"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A3
DescNo="A3"
DescItem="Name Resolution"
#policy_reco="<u>/etc/hosts</u><br><br>127.0.0.1   localhost<br><br><ipaddress> hostname<br><br><br><u>/etc/resolv.conf</u><br><br>search sgp.dbs.com dbs.com.sg<br><br>nameserver 10.80.114.8<br><br>nameserver 10.81.112.8<br><br><br><u>/etc/netsvc.conf</u><br><br>hosts=local4,bind4"
policy_reco="<u>/etc/hosts</u><br><br>127.0.0.1   localhost<br><br>${IPADD} ${HostIs}<br><br><br><u>SG /etc/resolv.conf</u><br>search dbs.com.sg sgp.dbs.com<br>nameserver 10.67.1.58<br>nameserver 10.67.1.64<BR><BR><u>HK /etc/resolv.conf</u><br>nameserver 10.190.2.23<br>nameserver 10.190.98.21<BR><BR><u>ID /etc/resolv.conf</u><br>search reg1.1bank.dbs.com<br>nameserver 10.192.40.6<br>nameserver 10.192.40.150<br><BR><u>CN /etc/resolv.conf</u><br>nameserver 10.67.1.58<br>nameserver 10.67.1.64<br><br><BR><u>TW /etc/resolv.conf</u><br>nameserver 10.231.114.225<br>nameserver 10.230.114.215<br><br><br><u>/etc/netsvc.conf</u><br><br>hosts=local4,bind4"
STDBLD="A"
AUTOCHK="A"
how_to=""
>$OUTDIR/nsresol.txt
if [ -f /etc/hosts -a -s /etc/hosts ]
then
        cat /etc/hosts | grep ^127.0.0.1 > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
                violations="Compliant"
                VALUE1=$(hostent -S)
                else
                violations="Non-Compliant"
                VALUE1=$(hostent -S)
                echo "$violations" >> $OUTDIR/nsresol.txt
                fi
else
    violations="Non-Compliant"
    VALUE1="File Not FOUND"
    echo "$violations" >> $OUTDIR/nsresol.txt
fi
if [ -f /etc/resolv.conf -a -s /etc/resolv.conf ]
then
        HOSTS=$(hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]')
        if [ "$HOSTS" = "a01" ]
                then
		D1=`egrep '^domain' /etc/resolv.conf | egrep 'dbs.com.sg' | wc -l`
		D2=`egrep '^domain' /etc/resolv.conf | egrep 'sgp.dbs.com'| wc -l`
		S1=`egrep '^search' /etc/resolv.conf | egrep 'dbs.com.sg'| wc -l`
		S2=`egrep '^search' /etc/resolv.conf | egrep 'sgp.dbs.com'| wc -l`
		N1=`egrep '^nameserver' /etc/resolv.conf |egrep '10.80.114.8|10.67.1.58'| wc -l`
		N2=`egrep '^nameserver' /etc/resolv.conf | egrep '10.81.112.8|10.67.1.64' |wc -l`
		D=`expr $D1 + $D2`
		S=`expr $S1 + $S2`
		N=`expr $N1 + $N2`
		RESOLV=`expr $D + $S + $N`
			if [ $RESOLV -ge 3 ] && [ $D -ge 0 ] && [ $S -ge 1 ] && [ $N -ge 2 ]; then
				egrep '^nameserver' /etc/resolv.conf | grep -v grep | grep -i "10.8" > /dev/null 2>&1
				if [ $? -eq 0 ];        then
					how_to="# cat /etc/resolv.conf. This is OLD DNS migration in progress"
				fi
				violations="Compliant"
				VALUE2=$(cat /etc/resolv.conf)
			else
				violations="Non-Compliant"
				VALUE2=$(cat /etc/resolv.conf)
			fi
        elif [ "$HOSTS" = "a03" ]
                then
		N3=`egrep '^nameserver' /etc/resolv.conf |egrep '10.190.2.23'| wc -l`
                N4=`egrep '^nameserver' /etc/resolv.conf | egrep '10.190.98.21' |wc -l`
		N=`expr $N3 + $N4`
                RESOLV=$N
                if [ "$RESOLV" -ge "2" ]
                then
                violations="Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                else
                violations="Non-Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                fi
        elif [ "$HOSTS" = "a07" ]
                then
                RESOLV=`egrep 'reg1.1bank.dbs.com|^nameserver 10.192.40.6|^nameserver 10.192.40.150' /etc/resolv.conf | wc -l`
                if [ "$RESOLV" -ge "3" ]
                then
                violations="Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                else
                violations="Non-Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                fi
        elif [ "$HOSTS" = "a05" ]
                then
                N3=`egrep '^nameserver' /etc/resolv.conf |egrep '10.67.1.58'| wc -l`
                N4=`egrep '^nameserver' /etc/resolv.conf | egrep '10.67.1.64' |wc -l`
                N=`expr $N3 + $N4`
                RESOLV=$N
                if [ "$RESOLV" -ge "2" ]
                then
                violations="Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                else
                violations="Non-Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                fi
        elif [ "$HOSTS" = "a11" ]
                then
                N3=`egrep '^nameserver' /etc/resolv.conf |egrep '10.231.114.225'| wc -l`
                N4=`egrep '^nameserver' /etc/resolv.conf | egrep '10.230.114.215' |wc -l`
                N=`expr $N3 + $N4`
                RESOLV=$N
                if [ "$RESOLV" -ge "2" ]
                then
                violations="Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                else:
                violations="Non-Compliant"
                VALUE2=$(cat /etc/resolv.conf)
                fi                
        fi
else
        violations="Non-Compliant"
        VALUE2="File Not FOUND or File is Empty"
        echo "$violations" >> $OUTDIR/nsresol.txt
fi
if [ -f /etc/netsvc.conf -a -s /etc/netsvc.conf ]
then
#       cat /etc/netsvc.conf | grep ^"hosts=local4,.bind4" > /dev/null 2>&1;RC=$?
cat /etc/netsvc.conf | grep -E ^"hosts=local4,bind4|hosts = local4, bind4|hosts = local4,bind4|hosts= local4 , bind4" > /dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
                violations="Compliant"
                VALUE3="$(cat /etc/netsvc.conf | grep ^hosts)"
                else
                violations="Non-Compliant"
                VALUE3="$(cat /etc/netsvc.conf | grep ^hosts)"
                echo "$violations" >> $OUTDIR/nsresol.txt
        fi
else
                violations="Non-Compliant"
                VALUE3="File Not FOUND"
                echo "$violations" >> $OUTDIR/nsresol.txt
fi
VALUE="<u>cat /etc/hosts</u><br>${VALUE1}<br><br>                           <u>cat /etc/resolv.conf</u><br>${VALUE2}<br><br>                            <u>cat /etc/netsvc.conf</u><br>${VALUE3}"
cat  $OUTDIR/nsresol.txt | grep ^Non > /dev/null 2>&1
if [ $? -eq 0 ]
then
    violations="Non-Compliant"
else
    violations="Compliant"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A4
DescNo="A4"
DescItem="System TimeZone"
policy_reco="Set TZ to "Asia/Singapore" or SGT-8 or HKT-8 or WIB-7 or BEIST-8 or TAIST-8"
how_to="# echo \$TZ"
STDBLD="A"
AUTOCHK="A"
VALUE=$(echo $TZ)
HOSTS=`hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]'` > /dev/null 2>&1
if [ "$HOSTS" = "a01" ]
        then
        if [ $VALUE  = "SGT-8" -o $VALUE = "Asia/Singapore" -o $VALUE = "SGT-8SGT" ]
        then
        violations="Compliant"
        else
        violations="Non-Compliant"
        fi
elif [ "$HOSTS" = "a03" ]
        then
        if [ $VALUE  = "HKT" -o $VALUE  = "HKT-8" -o $VALUE = "Asia/Hong_Kong" ]
        then
        violations="Compliant"
        else
        violations="Non-Compliant"
        fi
elif [ "$HOSTS" = "a07" ]
        then
        if [ $VALUE  = "WIB" -o  $VALUE  = "WIB-7" ]
        then
        violations="Compliant"
        else
        violations="Non-Compliant"
        fi
elif [ "$HOSTS" = "a05" ]
        then
        if [ $VALUE  = "BEIST-8" ]
        then
        violations="Compliant"
        else
        violations="Non-Compliant"
        fi
elif [ "$HOSTS" = "a11" ]
        then
        if [ $VALUE  = "TAIST-8" ]
        then
        violations="Compliant"
        else
        violations="Non-Compliant"
        fi        
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A5
DescNo="A5"
DescItem="NTP"
policy_reco="<u>/etc/ntp.conf</u><br><u>SG </u>server 10.67.1.58<br>server 10.67.1.64<br><br><u>TW </u>server 10.231.114.225<br>server 10.230.114.215<br><BR><u>CN </u> /etc/resolv.conf</u><br>nameserver 10.67.1.58<br>nameserver 10.67.1.64<br>server 10.67.1.64<br><BR><u>CN /etc/resolv.conf</u><br>server 10.67.1.58<br>server 10.67.1.64"
how_to="# cat /etc/ntp.conf"
STDBLD="A"
AUTOCHK="A"
if [ -f /etc/ntp.conf ];	then
	HOSTS=`hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]'` > /dev/null 2>&1
    if [ "$HOSTS" = "a01" ];	then
        cat /etc/ntp.conf | grep -v "^#" | grep -Ew "10.80.114.8|10.67.1.58" > /dev/null 2>&1;RC1=$?
        cat /etc/ntp.conf | grep -v "^#" | grep -Ew "10.81.112.8|10.67.1.64" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ];	then
			violations="Compliant"
			VALUE="$(cat /etc/ntp.conf | grep -v "^#" | grep -Ew "10.80.114.8|10.81.112.8|10.67.1.58|10.67.1.64")"
		else
			violations="Non-Compliant"
			VALUE="DNS Entried not found"
        fi
     elif [ "$HOSTS" = "a03" ];	then
		cat /etc/ntp.conf | grep -v "^#" | grep -w 10.190.2.23 > /dev/null 2>&1;RC1=$?
		cat /etc/ntp.conf | grep -v "^#" | grep -w 10.190.98.21 > /dev/null 2>&1;RC2=$?
		((RC=$RC1+$RC2))
		if [ $RC -eq 0 ];	then
            violations="Compliant"
            VALUE="$(cat /etc/ntp.conf | grep -v "^#" | grep -Ew "10.190.2.23|10.190.98.21")"
		else
             violations="Non-Compliant"
             VALUE="DNS Entried not found"
		fi
     elif [ "$HOSTS" = "a07" ];	then
         cat /etc/ntp.conf | grep -v "^#" | grep -w 10.192.40.150 > /dev/null 2>&1;RC1=$?
         cat /etc/ntp.conf | grep -v "^#" | grep -w 10.192.40.6 > /dev/null 2>&1;RC2=$?
         cat /etc/ntp.conf | grep -v "^#" | grep -w 10.234.70.16 > /dev/null 2>&1;RC3=$?
         ((RC=$RC1+$RC2+$RC3))
		if [ $RC -eq 0 ];	then
			violations="Compliant"
			VALUE="$(cat /etc/ntp.conf | grep -v "^#" | grep -Ew "10.192.40.150|10.192.40.6|10.234.70.16")"
		else
			violations="Non-Compliant"
			VALUE="NTP Entries not found"
		fi
     elif [ "$HOSTS" = "a05" ];	then
         cat /etc/ntp.conf | grep -v "^#" | grep -w 10.67.1.58 > /dev/null 2>&1;RC1=$?
         cat /etc/ntp.conf | grep -v "^#" | grep -w 10.67.1.64 > /dev/null 2>&1;RC2=$?
         ((RC=$RC1+$RC2))
		if [ $RC -eq 0 ];	then
			violations="Compliant"
			VALUE="$(cat /etc/ntp.conf | grep -v "^#" | grep -Ew "10.192.40.150|10.192.40.6|10.234.70.16")"
		else
			violations="Non-Compliant"
			VALUE="NTP Entries not found"
		fi
     elif [ "$HOSTS" = "a11" ];	then
         cat /etc/ntp.conf | grep -v "^#" | grep -w 10.231.114.225 > /dev/null 2>&1;RC1=$?
         cat /etc/ntp.conf | grep -v "^#" | grep -w 10.230.114.215 > /dev/null 2>&1;RC2=$?
         ((RC=$RC1+$RC2))
		if [ $RC -eq 0 ];	then
			violations="Compliant"
			VALUE="$(cat /etc/ntp.conf | grep -v "^#" | grep -Ew "10.231.114.225|10.230.114.215")"
		else
			violations="Non-Compliant"
			VALUE="NTP Entries not found"
		fi
	fi       
else
	violations="Non-Compliant"
	VALUE="File not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A6
DescNo="A6"
DescItem="Ensure that the following file permissions are set properly for all users to have proper name resolution. /etc/resolv.conf (644) /etc/netsvc.conf (644) /etc/ntp.conf (644)"
policy_reco="<u>/etc/resolv.conf</u><br><br>rw-r--r-- (644)<br><br><u>/etc/netsvc.conf</u><br>rw-r--r-- (644)<br><br><u>/etc/ntp.conf</u><br><br>rw-r--r-- (644)"
STDBLD="A"
AUTOCHK="A"
how_to=""
RESOLVCONF=`ls -l /etc/resolv.conf | awk '{print $1}'`
NETSVCCONF=`ls -l /etc/netsvc.conf | awk '{print $1}'`
NTPCONF=`ls -l /etc/ntp.conf | awk '{print $1}'`
if ([ "$RESOLVCONF" = "-rw-r--r--" ] && [ "$NETSVCCONF" = "-rw-r--r--" ] && [ "$NTPCONF" = "-rw-r--r--" ])
        then
        VALUE=`ls -l /etc/resolv.conf /etc/netsvc.conf /etc/ntp.conf `
        violations="Compliant"
        else
        VALUE=`ls -l /etc/resolv.conf /etc/netsvc.conf /etc/ntp.conf`
        violations="Non-Compliant"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations"       >>$HTMLLogFile

#A7
DescNo="A7"
DescItem="Kernel Parameters"
#policy_reco="<ul><li>autorestart=true</li><li>cpuguard=enable</li><li>fullcore=false</li><li>maxuproc=16384</li></ul>"
policy_reco="<ul><li>autorestart=true</li><li>cpuguard=enable</li><li>fullcore=true</li><li>iostat=true</li><li>maxuproc=16384</li><li>max_logname=16</li></ul>"
how_to="# lsattr -El sys0"
STDBLD="A"
AUTOCHK="A"
#lsattr -El sys0 -a autorestart -a cpuguard -a fullcore -a maxuproc | awk '{print $1"="$2}' > $OUTDIR/sys01.txt
lsattr -El sys0 -a autorestart -a cpuguard -a fullcore -a iostat -a maxuproc -a max_logname | awk '{print $1"="$2}' > $OUTDIR/sys01.txt
echo "autorestart=true\ncpuguard=enable\nfullcore=true\niostat=true\nmaxuproc=16384\nmax_logname=16" > $OUTDIR/sys0.txt
#echo "autorestart=true\ncpuguard=enable\nfullcore=false\nmaxuproc=16384" > $OUTDIR/sys0.txt
diff $OUTDIR/sys01.txt $OUTDIR/sys0.txt > /dev/null 2>&1
if [ $? -eq 0 ]
then
        violations="Compliant"
        VALUE="$(cat $OUTDIR/sys01.txt)"
        else
        violations="Non-Compliant"
        VALUE="$(cat $OUTDIR/sys01.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A8
DescNo="A8"
DescItem="ulimits"
#policy_reco="<ul><li>fsize = -1</li><li>core = -1</li><li>cpu = -1</li><li>data = -1</li><li>rss = 65536</li><li>stack = 65536</li><li>nofiles = -1</li><li>threads = -1</li><li>nproc = -1</li></ul>"
policy_reco="<ul><li>fsize = -1</li><li>core = -1</li><li>cpu = -1</li><li>data = -1</li><li>rss = 65536</li><li>stack = 65536</li><li>nofiles = -1</li><li>threads = -1</li><li>nproc = -1</li></ul>"
how_to="# cat /etc/security/limits"
STDBLD="A"
AUTOCHK="A"
sed -n '/^root:/,/^ $/p' /etc/security/limits | grep -v "^ $" >$OUTDIR/limits_root.txt
echo "root:\n\tfsize = -1\n\tcore = -1\n\tcpu = -1\n\tdata = -1\n\trss = 65536\n\tstack = 65536\n\tnofiles = -1\n\tthreads = -1\n\tnproc = -1" >$OUTDIR/limits_root1.txt
sed -n '/^default:/,/^ $/p' /etc/security/limits | grep -v "^ $" >$OUTDIR/limits_default.txt
echo "default:\n\tfsize = -1\n\tcore = -1\n\tcpu = -1\n\tdata = -1\n\trss = 65536\n\tstack = 65536\n\tnofiles = -1\n\tthreads = -1\n\tnproc = -1" >$OUTDIR/limits_default1.txt
sed -n '/^root:/,/^ $/p' /etc/security/limits | grep -v "^ $" >> $OUTDIR/limits.txt
sed -n '/^default:/,/^ $/p' /etc/security/limits | grep -v "^ $" >> $OUTDIR/limits.txt
#cat /etc/security/limits | grep -v ^* | grep -ip "root:" >> $OUTDIR/limits.txt
#cat /etc/security/limits | grep -v ^* | grep -ip "default:" >> $OUTDIR/limits.txt
sdiff $OUTDIR/limits_root.txt $OUTDIR/limits_root1.txt > /dev/null 2>&1;RC1=$?
sdiff $OUTDIR/limits_default.txt $OUTDIR/limits_default1.txt > /dev/null 2>&1;RC2=$?
((RC=$RC1+$RC2))
if [ $RC -eq 0 ]
then
        violations="Compliant"
        VALUE="$(cat $OUTDIR/limits.txt)"
        else
        violations="Non-Compliant"
        VALUE="$(cat $OUTDIR/limits.txt)"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A9
DescNo="A9"
DescItem="OS FileSystem Capacity"
policy_reco="Make sure that the following file systems have the following minimum size <br><ul><li>1GB   /</li><li>2GB  /home</li><li>2GB  /system logs</li>2GB  /tmp</li><li>2GB  /var</li><li>1GB /opt</li><li>5GB  /usr</li>"
how_to="# df -g"
STDBLD="A"
AUTOCHK="A"
cat << FSList >> $OUTDIR/FSList.txt
/ 1.00
/home 2.00
/systemlogs 2.00
/tmp 2.00
/var 2.00
/opt 1.00
/usr 5.00
FSList
> $OUTDIR/dfCurcap.txt
cat $OUTDIR/FSList.txt | while read FS SIZE
do
CurCap=$(df -g $FS |tail +2 |awk '{ print $2 }')
[ $CurCap -lt $SIZE ] && echo "$FS size is $CurCap" >> $OUTDIR/dfCurcap.txt
done
HowMany=$(cat $OUTDIR/dfCurcap.txt | wc -l)
if [ $HowMany -eq 0 ]
then
    violations="Compliant"
    VALUE="$(cat $OUTDIR/FSList.txt)"
    else
    violations="Non-Compliant"
    VALUE="$(cat $OUTDIR/dfCurcap.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A10
DescNo="A10"
DescItem="Paging Space"
policy_reco="Memory is less than 8GB, Paging should be 8GB. If Memory is greater than 8GB and less than 32GB, paging should be equal to the amount of physical memory.<br>If memory is greater than 32GB, Paging should be minimum of 32GB. Paging should be a maximum of 16GB in rootvg and additional paging to be created in sysvg. Applicable only for LPARs which has sysvg and rootvg is not equal to 100GB."
#how_to="# lsps -s"
STDBLD="A"
AUTOCHK="A"
MEM=$(prtconf -m | awk '{print $3}')
PGSZ=$(lsps -s |  sed -e 's/MB//g' | grep "%" | awk '{print $1}')
if [ $MEM -le 8192 ]
then
        if ([ $PGSZ -ge 7168 ])
        then
        violations="Compliant"
        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
        else
        violations="Non-Compliant"
        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
        fi
elif ([ $MEM -gt 8192 ] && [ $MEM -le 32768 ])
then
        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
        RDISKSIZE=$(bootinfo -s $RDISK)
        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
        if ([ $RC -eq 0 ] && [ `lspv| grep -cw rootvg` -lt 2 ] && [ $RDISKSIZE -eq 102400 ])
        then
                        if [ $PGSZ -eq $MEM ]
                        then
                        violations="Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        else
                        violations="Non-Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        fi
        elif ([ $RC -eq 0 ] && [ `lspv| grep -cw rootvg` -lt 2 ] && [ $RDISKSIZE -eq 51200 ])
        then
                        if ([ $MEM -gt 8192 ] && [ $MEM -le 16384 ])
                        then
                                if [ $PGSZ -ge $MEM ]
                                then
                                violations="Compliant"
                                VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                                else
                                violations="Non-Compliant"
                                VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                                fi
                        elif ([ $MEM -gt 16384 ] && [ $MEM -le 32768 ])
                        then
                                RDISKPGSZ=$(lsps -a | grep -w $RDISK | awk '{print $4}' | tr -d 'MB')
                                if ([ $RDISKPGSZ -eq 16384 ] && [ $PGSZ -eq $MEM ])
                                then
                                violations="Compliant"
                                VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                                else
                                violations="Non-Compliant"
                                VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                                fi
                        fi
        elif ([ $RC -eq 0 ] && [ `lspv| grep -cw rootvg` -ge 1 ])
        then
                        if [ $PGSZ -eq $MEM ]
                        then
                        violations="Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        else
                        violations="Non-Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        fi
        elif ([ $RC -ne 0 ] && [ `lspv| grep -cw rootvg` -ge 1 ])
        then
                        if [ $PGSZ -eq $MEM ]
                        then
                        violations="Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        else
                        violations="Non-Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        fi
        fi
elif ([ $MEM -gt 32768 ])
then
        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
        RDISKSIZE=$(bootinfo -s $RDISK)
        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
        if ([ $RC -eq 0 ] && [ `lspv| grep -cw rootvg` -lt 2 ] && [ $RDISKSIZE -eq 102400 ])
        then
                        if [ $PGSZ -ge 32768 ]
                        then
                        violations="Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        else
                        violations="Non-Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        fi
        elif ([ $RC -eq 0 ] && [ `lspv| grep -cw rootvg` -lt 2 ] && [ $RDISKSIZE -eq 51200 ])
        then
                                RDISKPGSZ=$(lsps -a | grep -w $RDISK | awk '{print $4}' | tr -d 'MB')
                                if ([ $RDISKPGSZ -eq 16384 ] && [ $PGSZ -ge 32768 ])
                                then
                                violations="Compliant"
                                VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                                else
                                violations="Non-Compliant"
                                VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                                fi
        elif ([ $RC -eq 0 ] && [ `lspv| grep -cw rootvg` -ge 1 ])
        then
                        if [ $PGSZ -ge 32768 ]
                        then
                        violations="Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        else
                        violations="Non-Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        fi
        elif ([ $RC -ne 0 ] && [ `lspv| grep -cw rootvg` -ge 1 ])
        then
                        if [ $PGSZ -ge 32768 ]
                        then
                        violations="Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        else
                        violations="Non-Compliant"
                        VALUE="PaginSpace<br>$(lsps -s |  grep "%" | awk '{print $1}')<br>$(lsps -s)"
                        fi

        fi
fi
how_to="# Memory Size : $MEM"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A11
DescNo="A11"
DescItem="Dump Device Configuration"
policy_reco="Start with one 4GB dump device in rootvg, and monitor with sysdumpdev -e to adjust the dump device size. Dump type should be FW-Assisted"
how_to="# sysdumpdev -e & sysdumpdev -l"
STDBLD="A"
AUTOCHK="A"
DUMPSZ="4096"
EST_TEMP=$(sysdumpdev -e|cut -d":" -f2|cut -d" " -f2)
EST_DUMPSZ=$( echo "( $EST_TEMP / 1024 ) / 1024 " |bc)
PRIDUMP=$(/usr/bin/sysdumpdev -l|grep primary|cut -d"/" -f3)
SECDUMP=$(/usr/bin/sysdumpdev -l|grep secondary|cut -d"/" -f3)
RVGDISK=$(lsvg -p rootvg|grep -Ev 'rootvg|PV'|wc -l)
if [[ $RVGDISK -lt 2 ]]
then
        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
          RVGMIR="SANBoot"
          else
          RVGMIR="NOSAN"
        fi
fi
#Check pdump size
if [ $PRIDUMP != "sysdumpnull" ]
then
LVSZ1=$(lslv $PRIDUMP|grep -E "PP SIZE:|PPs"|grep -v STALE|cut -d":" -f3|tr -s " "|cut -d" " -f2|awk 'ORS=NR%1?"\n":"\*"'|sed 's/\*$//g')
PRIDUMPSZ=$(echo "$LVSZ1"|bc)
        if [  $PRIDUMPSZ -ge $DUMPSZ ]
        then
        echo "\nPRIMARY_DUMPSIZE_AS_RECOMMANDED" >> $OUTDIR/dumpdevinfoOK.txt
        else
        echo "\nPRIMARY_DUMPSIZE_AS_NOT_RECOMMANDED" >> $OUTDIR/dumpdevinfoNOK.txt
        fi
        if [ $PRIDUMPSZ -lt $EST_DUMPSZ ]
        then
        PRIDUMP_ENOUGH="PRIMARY_DUMP_NOT_ENOUGH"
        echo "\nPrimayDump_LV : $PRIDUMP \n PrimaryDumpSize : $PRIDUMPSZ\n EstimatedDumpSize : $EST_DUMPSZ \n STATUS : $PRIDUMP_ENOUGH \n_______________" >> $OUTDIR/dumpdevinfoNOK.txt
        else
        PRIDUMP_ENOUGH="PRIMARY_DUMP_ENOUGH"
        echo "PrimayDump_LV : $PRIDUMP \n PrimaryDumpSize : $PRIDUMPSZ\n EstimatedDumpSize : $EST_DUMPSZ \n STATUS : $PRIDUMP_ENOUGH \n_______________" >> $OUTDIR/dumpdevinfoOK.txt
        fi
else
echo "\nPRIMARY_DUMP_DEVICE_SET_AS_"sysdumpdull" " >> $OUTDIR/dumpdevinfoNOK.txt
fi
if ([ "$RVGMIR" != "SANBoot" ] || [ "$RVGMIR" != "NOSAN" ])
then
        if [ $SECDUMP != "sysdumpnull" ]
        then
                LVSZ2=$(lslv $SECDUMP|grep -E "PP SIZE:|PPs"|grep -v STALE|cut -d":" -f3|tr -s " "|cut -d" " -f2|awk 'ORS=NR%1?"\n":"\*"'|sed 's/\*$//g')
                SECDUMPSZ=$(echo "$LVSZ2"|bc)
                if [  $SECDUMPSZ -ge $DUMPSZ ]
                then
                echo "SECONDARY_DUMPSIZE_AS_RECOMMANDED" >> $OUTDIR/dumpdevinfoOK.txt
                else
                echo "SECONDARY_DUMPSIZE_AS_NOT_RECOMMANDED" >> $OUTDIR/dumpdevinfoNOK.txt
                fi
                if [ $SECDUMPSZ -lt $EST_DUMPSZ ]
                then
                        SECDUMP_ENOUGH="SecDumpNotEnough"
                        echo "$SECDUMP - $SECDUMPSZ(Sec.DumpSize) - $EST_DUMPSZ(Est.DumpSize) " >> $OUTDIR/dumpdevinfoNOK.txt
                        echo "Secondary_LV : $SECDUMP \n SecondryDumpSize : $SECDUMPSZ\n EstimatedDumpSize : $EST_DUMPSZ \n STATUS : $SECDUMP_ENOUGH \n_______________" >> $OUTDIR/dumpdevinfoNOK.txt
                                else
                        SECDUMP_ENOUGH="SecDumpEnough"
                        echo "Secondary_LV : $SECDUMP \n SecondryDumpSize : $SECDUMPSZ\n EstimatedDumpSize : $EST_DUMPSZ \n STATUS : $SECDUMP_ENOUGH \n_______________" >> $OUTDIR/dumpdevinfoOK.txt
                fi
        else
             echo "\nSECONDARY_DUMPDEVICE_SET_AS_"sysdumpnull" " >> $OUTDIR/dumpdevinfoOK.txt
        fi
else
        echo "\nROOTVG_IS_SANBOOT_OR_SINGLEDISK_IN_ROOTVG" >> $OUTDIR/dumpdevinfoOK.txt
fi
#
echo "\nType of Dump : "$(sysdumpdev -l | grep "type of dump" | awk '{print $4}') >> $OUTDIR/dumpdevinfoOK.txt
DUMPTYPE=$(sysdumpdev -l | grep "type of dump" | awk '{print $4}')
if ([ -s $OUTDIR/dumpdevinfoNOK.txt ] || [ $DUMPTYPE != "fw-assisted" ])
then
     violations="Non-Compliant"
     echo "\nType of Dump : "$(sysdumpdev -l | grep "type of dump" | awk '{print $4}') >> $OUTDIR/dumpdevinfoNOK.txt
     VALUE="$(cat $OUTDIR/dumpdevinfoNOK.txt)"
     else
     violations="Compliant"
     VALUE="$(cat $OUTDIR/dumpdevinfoOK.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A12
DescNo="A12"
DescItem="Syslog Notification"
policy_reco="Ensure necessary alert notification configured for syslog."
STDBLD="A"
AUTOCHK="A"
DescItem="Syslog notification Configuration"
policy_reco="Ensure necessary alert notification configured for syslog"
how_to="# cat /etc/syslog.conf"
if [ -f /etc/syslog.conf -a -s /etc/syslog.conf ]
then
        cat /etc/syslog.conf | grep -v "^#" | grep -E  "\*.info;|\mail.err;|\mark.none|scsp" | grep -v null >/dev/null 2>&1;RC1=$?
        cat /etc/syslog.conf | grep -v "^#" | grep -E "\*.warn;|\*.notice" | grep -v null >/dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
                 if [ $RC -eq 0 ]
                 then
                                violations="Compliant"
                VALUE1="$(cat /etc/syslog.conf | grep -v "^#" | grep -E  "\*.info;|\mail.err;|\mark.none|scsp" | grep -v null)"
                VALUE2="$(cat /etc/syslog.conf | grep -v "^#" | grep -E "\*.warn;|\*.notice" | grep -v null)"
                VALUE="$VALUE1<br>$VALUE2"
                                else
                                violations="Non-Compliant"
                VALUE1="$(cat /etc/syslog.conf | grep -v "^#" | grep -E  "\*.info;|\mail.err;|\mark.none|scsp" | grep -v null)"
                VALUE2="$(cat /etc/syslog.conf | grep -v "^#" | grep -E "\*.warn;|\*.notice" | grep -v null)"
                VALUE="$VALUE1<br>$VALUE2"
            fi
else
         violations="Non-Compliant"
         VALUE="FILE_NOT_FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A13
DescNo="A13"
DescItem="Standard Services"
policy_reco="Services to be Active<br><br>syslogd<br>portmap<br>inetd<br>hostmibd<br>aixmibd<br>pconsole<br>ctrmc<br>pnsd<br>tlmagent<br><br>AIX LPAR<br><br>IBM.MgmtDomainRM<br>IBM.ServiceRM<br>IBM.DRM<br><br>PowerHA<br><br>cthags<br>clevmgrdES<br>emsvcs<br>clcomd<br>clstrmgrES<br>clinfoES<br>snmpd<br>gsclvmd<br><br>Tectia SSH Server<br><br>ssh-tectia-server<br><br>Tripwire<br><br>teagent<br>teeg<br>"
how_to="# Active Services"
STDBLD="A"
AUTOCHK="A"
>$OUTDIR/services1.txt
>$OUTDIR/services2.txt
>$OUTDIR/services3.txt
>$OUTDIR/services4.txt
for i in "syslogd" "portmap" "inetd" "hostmibd" "aixmibd" "pconsole" "ctrmc" "pnsd" "tlmagent" "IBM.MgmtDomainRM" "IBM.ServiceRM" "IBM.DRM" "teagent" "teeg"
do
lssrc -s $i | grep -v PID | grep active |  sed -e '/^$/d' | awk '{print $1}' >> $OUTDIR/services1.txt
done
echo "syslogd\nportmap\ninetd\nhostmibd\naixmibd\npconsole\nctrmc\npnsd\ntlmagent\nIBM.MgmtDomainRM\nIBM.ServiceRM\nIBM.DRM\nteagent\nteeg" >$OUTDIR/services2.txt
diff $OUTDIR/services1.txt $OUTDIR/services2.txt > /dev/null 2>&1;RC1=$?
if [ $RC1 -eq 0 ]
then
        VALUE1="$(cat $OUTDIR/services1.txt)"
        else
        VALUE1="$(cat $OUTDIR/services1.txt)"
fi
lssrc -s clstrmgrES > /dev/null 2>&1;RC2=$?
if [ $RC2 -eq 0 ]
        then
        for i in "cthags" "clevmgrdES" "emsvcs" "clcomd" "clstrmgrES" "clinfoES" "snmpd" "gsclvmd"
        do
        lssrc -s $i | grep -v PID | grep active |  sed -e '/^$/d' | awk '{print $1}' >> $OUTDIR/services3.txt
        done
        echo "cthags\nclevmgrdES\nemsvcs\nclcomd\nclstrmgrES\nclinfoES\nsnmpd\ngsclvmd" >$OUTDIR/services4.txt
        diff $OUTDIR/services3.txt $OUTDIR/services4.txt > /dev/null 2>&1;RC3=$?
        if [ $RC1 -eq 0 ]
                then
                VALUE2="$(cat $OUTDIR/services3.txt)"
                else
                VALUE2="$(cat $OUTDIR/services3.txt)"
        fi
        else
        RC3=0
        VALUE2="No HACMP Installed"
fi
lslpp -l | grep -E "SSHTectia.Client|WRQ.RSIT.Server|F-Secure.SSH.Server|RSIT.ssh.Server|dbsStd.SSHTectia.server"  > /dev/null 2>&1;RC4=$?
if [ $RC4 -eq 0 ]; then
ps -ef | grep ssh | grep -v grep  > /dev/null 2>&1;RC5=$?
VALUE3="$(lslpp -l | grep -E "SSHTectia.Client|WRQ.RSIT.Server|F-Secure.SSH.Server|RSIT.ssh.Server|dbsStd.SSHTectia.server" | awk '{print $1}')"
fi
((RC=$RC1+$RC3+$RC5))
if [ $RC -eq 0 ]
then
    violations="Compliant"
    else
    violations="Non-Compliant"
fi
VALUE="$VALUE1\n$VALUE2\n$VALUE3"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#A14
DescNo="A14"
DescItem="Startup/Shtudown Scripts"
policy_reco="Ensure startup and stop scripts enabled"
STDBLD="A"
AUTOCHK="A"
how_to="# ls -lrt /etc/rc.startup /etc/rc.shutdown"
if [ -f /etc/rc.startup -a -s /etc/rc.startup ]
then
   echo "\n/etc/rc.startup : FILE_FOUND_AND_NON_ZERO " >> $OUTDIR/startshut.txt
   STARTUP=OK
   else
   echo "\n/etc/rc.startup : FILE_NOT_FOUND " >> $OUTDIR/startshut.txt
   STARTUP=NOK
fi
if [ -f /etc/rc.shutdown -a -s /etc/rc.shutdown ]
then
   echo "\n/etc/rc.shutdown : FILE_FOUND_AND_NON_ZERO " >> $OUTDIR/startshut.txt
   STOPUP=OK
   else
   echo "\n/etc/rc.shutdown : FILE_NOT_FOUND " >> $OUTDIR/startshut.txt
   STOPUP=NOK
fi
cat $OUTDIR/startshut.txt | grep NOT > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        violations="Non-Compliant"
        VALUE="$(cat $OUTDIR/startshut.txt)"
        else
        violations="Compliant"
        VALUE="$(cat $OUTDIR/startshut.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# LOGIN PROMPT
#A15
DescNo="A15"
DescItem="User Primary Login Prompt"
policy_reco="Configure the prompt to show user id, @ symbol, server name, : symbol , current directory, space and # symbol (for root user) or $ symbol (for non-root user)."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/profile"
cat /etc/profile | egrep -v '^ *#|^#' | grep "\$LOGNAME" | grep "\hostname" | grep '${ds}@${_time}${PS1}' | grep '\$PWD' > /dev/null2>&1;RC=$?
if [ $RC -eq 0 ]
then
    violations="Compliant"
    VALUE="$(cat /etc/profile | egrep -v '^ *#|^#' | grep "\$LOGNAME" | grep "\hostname" | grep '${ds}@${_time}${PS1}' | grep '\$PWD')"
  else
    violations="Non-Compliant"
    VALUE="$(cat /etc/profile | grep LOGNAME)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#TIMEOUT
#A16
DescNo="A16"
DescItem="Ensure that shell sessoin timeout is set to 10 mins. # TMOUT=600 "
policy_reco="Set TMOUT to 600secs"
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/profile"
cat /etc/profile | grep -v "#" | grep "TMOUT=600" > /dev/null 2>&1;RC=$?
if [ $RC  -eq 0 ]
then
   violations="Compliant"
   VALUE="$(cat /etc/profile | grep -v "^#" | grep "TMOUT=600")"
   else
   violations="Non-Compliant"
   VALUE="$(cat /etc/profile | grep -v "^#" | grep "TMOUT=600")"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A17
DescNo="A17"
DescItem="SAN Boot Disk"
policy_reco="Ensure that SAN boot is configured.  If local SCSI boot is used, please ensure that the steps under SCSI boot are also performed."
STDBLD="M"
AUTOCHK="A"
how_to="# Rootvg Disk"
RVGDISK=$(lsvg -p rootvg|grep -Ev 'rootvg|PV'|wc -l)
if [ $RVGDISK -lt 2 ]
then
        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
        RDISKSIZE=$(bootinfo -s $RDISK)
        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
        violations="Compliant"
        VALUE1=`echo "\nROOTVG_IS_SANBOOT"`
        VALUE2="\nRootvg Disk = $RDISK : Disk Size = $RDISKSIZE"
        VALUE="$VALUE1<br>$VALUE2"
        else
        violations="Non-Compliant"
        VALUE=`echo "\nROOTVG is not SANBOOT and not Mirrored. Ref.A27"`
        fi
else
        violations="Not-Applicable"
        VALUE=`echo "\nROOTVG has more than 1 Non-SAN disk. Ref.A27"`
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A18
DescNo="A18"
DescItem="NMON"
policy_reco="/usr/bin/topas_nmon -f -t -d -A -O -L -N -P -V -T -^ -s 60 -c 1440"
how_to="# ps -ef | grep nmon"
STDBLD="C"
AUTOCHK="A"
crontab -l |  grep nmon | grep -E "\-O \-L \-N|1440|60" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        echo "\nNMON_ENABLED_IN_CRON" >> $OUTDIR/nmon.txt
    else
        echo "\nNMON_NOT_ENABLED_IN_CRON"  >> $OUTDIR/nmon.txt
fi
ps -ef | grep nmon | grep -E "\-O \-L \-N|1440|60"  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        echo "\nNMON_PEOCESS RUNNING"  >> $OUTDIR/nmon.txt
    else
        echo "\nNMON_PROCESS_NOT_RUNNING"  >> $OUTDIR/nmon.txt
fi
cat $OUTDIR/nmon.txt | grep NOT > /dev/null 2>&1
if [ $? -eq 0 ]
then
    violations="Non-Compliant"
    VALUE="$(cat $OUTDIR/nmon.txt)"
    else
    violations="Compliant"
    VALUE="$(cat $OUTDIR/nmon.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A19
DescNo="A19"
DescItem="Standard Cronjob"
policy_reco="Ensure All standard AIX scripts enabled through cron<br>"/home/dbsinvs/adhoc_invensysCron.sh"<br>"/usr/local/scripts/SysHC/housekeepwrapper.pl"<br>"/usr/local/scripts/SysHC/Config_Bkp.ksh"<br>"/home/dbsinvs/Invensys_HealthCheck_Cron.sh"<br>"/home/dbsinvs/Invensys_Collector_Cron.sh"<br>"/usr/local/scripts/SysHC/aix_syshc.ksh"<br>"/usr/local/scripts/update_ftp_cron.sh"<br>"/usr/local/scripts/dumpcheck.ksh"<br>"/usr/local/scripts/filetransfer.sh"<br>"/usr/local/scripts/itmflag.sh"<br>"/usr/local/scripts/Agentrestart.sh"<br>"
STDBLD="C"
AUTOCHK="A"
how_to="# crontab -l"
#VALUE="MANUAL"
#violations="MANUAL"
> $OUTDIR/stdcron.txt
crontab -l | grep -Ei "/home/dbsinvs/adhoc_invensysCron.sh|/home/dbsinvs/Invensys_Collector_Cron.sh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/home/dbsinvs/Invensys_HealthCheck_Cron.sh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/SysHC/housekeepwrapper.pl" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/SysHC/Config_Bkp.ksh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/SysHC/aix_syshc.ksh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/eossp/sspscript/sspunixexecuter_static.sh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/eossp/sspscript/aix_postreboot_dynamic.sh"  | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/update_ftp_cron.sh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/dumpcheck.ksh"  | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/filetransfer.sh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/itmflag.sh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -i "/usr/local/scripts/Agentrestart.sh" | grep -v ^# >> $OUTDIR/stdcron.txt
crontab -l | grep -Ei "/home/dbsinvs/adhoc_invensysCron.sh|/home/dbsinvs/Invensys_Collector_Cron.sh" | grep -v ^#  > /dev/null 2>&1;RC3=$?
crontab -l | grep -i "/home/dbsinvs/Invensys_HealthCheck_Cron.sh" | grep -v ^# > /dev/null 2>&1;RC2=$?
crontab -l | grep -i "/usr/local/scripts/SysHC/housekeepwrapper.pl" | grep -v ^# > /dev/null 2>&1;RC5=$?
crontab -l | grep -i "/usr/local/scripts/SysHC/Config_Bkp.ksh" | grep -v ^# > /dev/null 2>&1;RC7=$?
crontab -l | grep -i "/usr/local/scripts/SysHC/aix_syshc.ksh" | grep -v ^# > /dev/null 2>&1;RC9=$?
crontab -l | grep -i "/eossp/sspscript/sspunixexecuter_static.sh" | grep -v ^# > /dev/null 2>&1;RC13=$?
crontab -l | grep -i "/eossp/sspscript/aix_postreboot_dynamic.sh"  | grep -v ^# > /dev/null 2>&1;RC14=$?
crontab -l | grep -i "/usr/local/scripts/update_ftp_cron.sh" | grep -v ^# > /dev/null 2>&1;RC4=$?
crontab -l | grep -i "/usr/local/scripts/dumpcheck.ksh"  | grep -v ^# > /dev/null 2>&1;RC6=$?
crontab -l | grep -i "/usr/local/scripts/filetransfer.sh" | grep -v ^# > /dev/null 2>&1;RC8=$?
crontab -l | grep -i "/usr/local/scripts/itmflag.sh" | grep -v ^# > /dev/null 2>&1;RC1=$?
crontab -l | grep -i "/usr/local/scripts/Agentrestart.sh" | grep -v ^# > /dev/null 2>&1;RC10=$?
if ([ -f /home/dbsinvs/Invensys_HealthCheck_Cron.sh -a -f /usr/local/scripts/SysHC/housekeepwrapper.pl -a -f /usr/local/scripts/SysHC/Config_Bkp.ksh -a -f /usr/local/scripts/SysHC/aix_syshc.ksh -a -f /usr/local/scripts/update_ftp_cron.sh -a -f /usr/local/scripts/dumpcheck.ksh -a -f /usr/local/scripts/filetransfer.sh -a -f /usr/local/scripts/itmflag.sh -a -f /usr/local/scripts/Agentrestart.sh ])
then
        RC11=0
else
        RC11=1
fi
if ([ -s /home/dbsinvs/Invensys_HealthCheck_Cron.sh -a -s /usr/local/scripts/SysHC/housekeepwrapper.pl -a -s /usr/local/scripts/SysHC/Config_Bkp.ksh -a -s /usr/local/scripts/SysHC/aix_syshc.ksh -a -s /usr/local/scripts/update_ftp_cron.sh -a -s /usr/local/scripts/dumpcheck.ksh -a -s /usr/local/scripts/filetransfer.sh -a -s /usr/local/scripts/itmflag.sh -a -s /usr/local/scripts/Agentrestart.sh ])
then
        RC12=0
else
        RC12=1
fi
if ([ -f /eossp/sspscript/sspunixexecuter_static.sh -a -f /eossp/sspscript/aix_postreboot_dynamic.sh -a -s /eossp/sspscript/sspunixexecuter_static.sh -a -s /eossp/sspscript/aix_postreboot_dynamic.sh ])
then
	RC15=0
else
	RC15=1
fi
HOSTE=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]' )
if ([ "$HOSTE" = "a01t" ] || [ "$HOSTE" = "a01b" ] || [ "$HOSTE" = "a01s" ] || [ "$HOSTE" = "a03t" ] || [ "$HOSTE" = "a03b" ] || [ "$HOSTE" = "a03s" ])
then
	((RC=$RC1+$RC2+$RC3+$RC4+$RC5+$RC6+$RC7+$RC8+$RC9+$RC10+$RC11+$RC12+$RC13+$RC14+$RC15))
	if [ $RC -eq 0 ] ; then
		violations="Compliant"
		VALUE="$(cat $OUTDIR/stdcron.txt)"
	else
		violations="Non-Compliant"
		VALUE="$(cat $OUTDIR/stdcron.txt)"
	fi
else
((RC=$RC1+$RC2+$RC3+$RC4+$RC5+$RC6+$RC7+$RC8+$RC9+$RC10+$RC11+$RC12))
if [ $RC -eq 0 ]
then
        violations="Compliant"
        VALUE="$(cat $OUTDIR/stdcron.txt)"
    else
    violations="Non-Compliant"
        VALUE="$(cat $OUTDIR/stdcron.txt)"
fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A20
DescNo="A20"
STDBLD="A"
AUTOCHK="A"
DescItem="FLASH-PPRC Scripts"
policy_reco="Ensure PPRC-FLASH Scripts configured"
how_to="# ls -lrt /usr/local/sysmaint/script/ or /HORCM/scripts/"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
if ([ "$HostDR" = "r" ] || [[ "$HostDR" = "g" && "$HostHADR" = "b" ]])
then
  lsdev -Cc disk | grep Hitachi  > /dev/null 2>&1;RC=$?
#  [ $RC -eq 0 ] && SANTYPE="Hitachi"
  if [ $RC -eq 0 ]
  then
 	if [ -d /HORCM/scripts/ ]
	then
		[ -x /HORCM/scripts/`hostname`_flash.ksh ] && RC1=$?
		crontab -l | grep -v "^#" | grep "/HORCM/scripts/`hostname`_flash.ksh" > /dev/null 2>&1;RC2=$?
		((RC=$RC1+$RC2))
		if [ $RC -eq 0 ]
		then
			violations="Compliant"
			VALUE="DR Flash Script Configured"
			VALUE2=$(raidcom get snapshot -IH2 | grep -i `hostname` | awk '{print $1}' | head -1 |  tr -d ' ' )
			VALUE1="$(raidcom get snapshot -snapshotgroup $VALUE2 -fx -IH2)"
		else
			violations="Non-Compliant"
			VALUE="DR Flash Script NotConfigured"
			VALUE1=" "
		fi
	else
		violations="Not-Applicable"
		VALUE="/HORCM/scripts/ Does not Exist"
		VALUE1=" "
	fi
  else
   if [ -d /usr/local/sysmaint/script ]
   then
       [ -x /usr/local/sysmaint/script/ibmsplitdisk.sh ] && RC1=$?
           crontab -l | grep -v "^#" | grep "/usr/local/sysmaint/script/ibmsplitdisk.sh" > /dev/null 2>&1;RC2=$?
                   R1COUNT=`awk '/^#SOURCE/,/^$/ { print }' /usr/local/sysmaint/script/`uname -n`_pprc.cfg|wc -l`
                   R1COUNT=`expr $R1COUNT - 1`
                   R2COUNT=`sudo /sysmaint/script/dspprc `uname -n` query |awk '$0~/^=/,/^=$/ { print }'|grep -i "Full Duplex" | wc -l`
           ((RC=$RC1+$RC2))
           if [ $RC -eq 0 ]
           then
              violations="Compliant"
              VALUE="DR Flash Script Configured"
                          VALUE1="$R1COUNT=$R2COUNT"
              else
              violations="Non-Compliant"
              VALUE="DR Flash Script NotConfigured"
                VALUE1=" "
           fi
    else
              violations="Not-Applicable"
              VALUE="/usr/local/sysmaint/script Does not Exist"
                VALUE1=" "
    fi
  fi
else
              violations="Not-Applicable"
              VALUE="NOT A DR NODE"
                VALUE1=" "
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE<br>$VALUE1</pre>" "$violations" >>$HTMLLogFile

#A21
# HARDWARE Alert
DescNo="A21"
STDBLD="A"
AUTOCHK="A"
DescItem="ODM Updated with errnotify"
policy_reco="Ensure errnotify enabled for HWAlert though ODM"
how_to="# odmget errnotify"
HWALSCRIPT=$(odmget errnotify|grep -w errornotify.sh|tail -1|cut -d"=" -f2|cut -d" " -f2|tr -d "\"")
if [ -z "$HWALSCRIPT" ]
 then
    HWALT="HWAlertNotConfigured"
 else
    [ -x "$HWALSCRIPT" ] && /usr/bin/grep PERM "$HWALSCRIPT">/dev/null 2>&1 && HWALT="HWAlertConfigured"||HWALT="HWAlertNotConfigured"
fi
if [ $HWALT = "HWAlertConfigured" ]
then
    violations="Compliant"
    VALUE="HWAlertConfigured via ODM"
       else
   violations="Non-Compliant"
   VALUE="HWAlertNotConfigured"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# INSTFIX -I
#A22
DescNo="A22"
DescItem="OS Patch"
#policy_reco="Ensure OS Patch is at recommanded level"
policy_reco="Ensure no filesets are missed"
STDBLD="A"
AUTOCHK="A"
how_to="# OSLEVEL"
echo "OSLEVEL : $(oslevel -s )" >> $OUTDIR/lppinfo.txt 2>&1
instfix -i | grep ML >  $OUTDIR/InstfixOut.txt 2>&1
cat $OUTDIR/InstfixOut.txt | grep -i Not > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    violations="Non-Compliant"
        VALUE="MISSING_FILESETS_FOUND"
        MissFiles="# instfix -i | grep ML<br>$(cat $OUTDIR/InstfixOut.txt)"
        RC1=1
    else
        violations="Compliant"
        VALUE="# instfix -i | grep -i ML<br>$(cat $OUTDIR/InstfixOut.txt)"
        RC1=0
fi
echo "\n$VALUE" >> $OUTDIR/lppinfo.txt 2>&1
echo "\n$MissFiles" >> $OUTDIR/lppinfo.txt 2>&1
# LPPCHK -VM3
lppchk -vm3 > $OUTDIR/lppchkOut.txt 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    violations="Compliant"
    VALUE="# lppchk -vm3<br>$(cat $OUTDIR/lppchkOut.txt)"
    RC2=0
    else
    violations="Non-Compliant"
    VALUE="# lppchk -vm3<br>$(cat $OUTDIR/lppchkOut.txt)"
    RC2=1
fi
echo "\n$VALUE" >> $OUTDIR/lppinfo.txt 2>&1
((RC=$RC1+$RC2))
if [ $RC -eq 0 ]
then
    violations="Compliant"
    VALUE="$(cat $OUTDIR/lppinfo.txt)"
    else
    violations="Non-Compliant"
    VALUE="$(cat $OUTDIR/lppinfo.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#
#A23
DescNo="A23"
DescItem="Sudo Configuration"
policy_reco="Sudo Configuration"
how_to="# sudo -V"
STDBLD="C"
AUTOCHK="A"
>$OUTDIR/sudoinfo.txt
sudo -V | grep "Sudo version" >> $OUTDIR/sudoinfo.txt 2>&1;RC1=$?
visudo -c >> $OUTDIR/sudoinfo.txt 2>&1;RC2=$?
if [ -f /etc/sudoers ]
then
        echo "Current CheckSum :$(cksum /etc/sudoers)" >> $OUTDIR/sudoinfo.txt 2>&1
else
        echo "Sudoers NOT_FOUND" >> $OUTDIR/sudoinfo.txt 2>&1
fi
((RC=$RC1+$RC2))
if [ $RC -eq 0 ]
then
          violations="Compliant"
          VALUE="<ol>$(cat $OUTDIR/sudoinfo.txt | sed -e 's/^/<li>/g' -e 's/$/<\/li>/g')</ol>"
          else
          violations="Non-Compliant"
          VALUE="<ol>$(cat $OUTDIR/sudoinfo.txt | sed -e 's/^/<li>/g' -e 's/$/<\/li>/g')</ol>"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A24
DescNo="A24"
DescItem="Ensure that DBSINVS user is available"
policy_reco="DBSINVS: rlogin=false, login=false, account_locked=false, maxage=0, unsuccessful_login_count=0, Signature file (/home/dbsinvs/`hostname`.csv), Robosys keys for SG, CN, HK & TW "
STDBLD="M"
AUTOCHK="A"
how_to="DBSINVS: "
lsuser dbsinvs >/dev/null 2>&1;RC1=$?
lsuser -f dbsinvs | grep -w rlogin | grep false >> $OUTDIR/dbsinvs.txt 2>&1;RC2=$?
lsuser -f dbsinvs | grep -w login | grep false >> $OUTDIR/dbsinvs.txt 2>&1;RC3=$?
lsuser -f dbsinvs | grep -w account_locked | grep false >> $OUTDIR/dbsinvs.txt 2>&1;RC4=$?
if [ `lsuser -f dbsinvs | grep -w maxage | awk -F "=" '{print $NF}'` -eq 0 ] ; then
	lsuser -f dbsinvs | grep -w maxage >> $OUTDIR/dbsinvs.txt 2>&1
	RC5=0
	else
	RC5=1
fi
lsuser -f dbsinvs | grep -w unsuccessful_login_count 2>&1;RC11=$?
if [ $RC11 -eq 0 ] ; then
if [ `lsuser -f dbsinvs | grep -w unsuccessful_login_count | awk -F "=" '{print $NF}'` -eq 0 ] ; then
	lsuser -f dbsinvs | grep -w unsuccessful_login_count >> $OUTDIR/dbsinvs.txt 2>&1
	RC6=0
	else
	RC6=1
fi
fi
HOSTN=$(hostname | tr -s '[:upper:]' '[:lower:]')
echo "Signature File :" >> $OUTDIR/dbsinvs.txt 2>&1
cat /home/dbsinvs/${HOSTN}.csv | grep -i ${HOSTN} > /dev/null 2>&1;RC7=$?
cat /home/dbsinvs/${HOSTN}.csv | grep -i ${HOSTN} >> $OUTDIR/dbsinvs.txt 2>&1
ls -l /home/dbsinvs/${HOSTN}.csv >> $OUTDIR/dbsinvs.txt 2>&1
HOSTCN=$(hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]')
if ([ "$HOSTCN" = "a01" ])
then
HOSTE=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]' | sed 's/^.*\(.\)$/\1/')
if ([ "$HOSTE" = "g" ] || [ "$HOSTE" = "r" ] || [ "$HOSTE" = "c" ])
then
	RC8=0 ; RC9=0
else
	if [ -d /home/dbsinvs/.ssh2 ] 
	then
		if [ -f /home/dbsinvs/.ssh2/w01tinvapp3a_dbsinvs.pub -a -f /home/dbsinvs/.ssh2/pdcrtems01_dbsinvs.pub -a -f /home/dbsinvs/.ssh2/authorization ]
		then
			echo "Robosys Keys :" >> $OUTDIR/dbsinvs.txt 2>&1 
			cat /home/dbsinvs/.ssh2/authorization | grep -Ei "key w01tinvapp3a_dbsinvs.pub" >> $OUTDIR/dbsinvs.txt 2>&1;RC8=$?
			cat /home/dbsinvs/.ssh2/authorization | grep -Ei "key pdcrtems01_dbsinvs.pub" >> $OUTDIR/dbsinvs.txt 2>&1;RC9=$?
		fi
	fi
fi
else
	RC7=0 ; RC8=0
fi
((RC=$RC1+$RC2+$RC3+$RC4+$RC5+$RC6+$RC7+$RC8+$RC9))
if [ $RC -eq 0 ]
then
        violations="Compliant"
        VALUE=$(cat $OUTDIR/dbsinvs.txt)
else
        violations="Non-Compliant"
        VALUE=$(cat $OUTDIR/dbsinvs.txt)
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A25
# CYBERARK
DescNo="A25"
STDBLD="A"
AUTOCHK="A"
DescItem="VASCO And CyberArk Configuration"
policy_reco="Ensure VASCO and CyberArk configured properly"
how_to="# netstat -an"
HOSTS=$(hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]')
if ([ "$HOSTS" = "a01" ] || [ "$HOSTS" = "a07" ])
then
        netstat -an | grep -w 60022 | grep LISTEN > /dev/null 2>&1;RC1=$?
        netstat -an | grep -w 61022 | grep LISTEN > /dev/null 2>&1;RC2=$?
        netstat -an | grep -w 63022 | grep LISTEN > /dev/null 2>&1;RC3=$?
        ((RC=$RC1+$RC2+RC3))
        if [ $RC -eq 0 ]
                then
                violations="Compliant"
                VALUE="$(netstat -an | grep -Ew "60022|61022|63022")"
        else
                violations="Non-Compliant"
                VALUE="Required ports are not LISTENING "
        fi
elif [ "$HOSTS" = "a03" ]
        then
                violations="Not-Applicable"
                VALUE="NOT APPLICABLE FOR SERVERS in HK"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A26
DescNo="A26"
DescItem="Dual Power Supplies"
policy_reco="Ensure Dual PowerSupplies available"
how_to="# lscfg -vp"
STDBLD="M"
AUTOCHK="A"
DPSC=$(lscfg -vp | grep -Ei "IBM PS|IBM AC PS" | wc -l)
if [ $DPSC -ge 2 ]
then
      violations="Compliant"
      VALUE="$(lscfg -vp | grep -Eip "IBM PS|IBM AC PS")"
       else
       violations="Non-Compliant"
       VALUE="$(lscfg -vp | grep -Eip "IBM PS|IBM AC PS")"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

################################################### SECTION C START ########################

DrawSubHead "2. SCSI boot (This following steps are applicable only when local SCSI boot is used)"  >>$HTMLLogFile
####

# ROOTVG MIRRORING
#A27
DescNo="A27"
DescItem="Root VolumeGroup State"
policy_reco="Ensure rootvg is mirrored properly"
how_to="# lsvg -l rootvg"
STDBLD="M"
AUTOCHK="A"
RVGDISK=$(lsvg -p rootvg|grep -Ev 'rootvg|PV'|wc -l)
if [[ $RVGDISK -lt 2 ]]
then
        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
          MIR="SANBoot"
          echo "\nROOTVG_IS_SANBOOT" >> $OUTDIR/rootvgmirOK.txt
          else
          MIR="MirrorNotDone"
          echo "\nROOTVG_IS_NOT_MIRRORED" >> $OUTDIR/rootvgmirNOK.txt
        fi
         else
# CHECK ALL LVS HAVE MIRROR COPIES
lsvg -l rootvg | grep -v sysdump | grep -v page | grep -v rootvg: | grep -v LV | grep ^hd | awk '{if($5!=2)print $1"-"$NF;}' > $OUTDIR/mirr.txt 2>&1
         if [ ! -s $OUTDIR/mirr.txt ]
         then
            LVMIR="DONE"
            echo "\nALL_LVS_MIRRORED" >> $OUTDIR/rootvgmirOK.txt
            else
            LVMIR="NOMIR"
            echo "\nALL_LVS_NOT_MIRRORED\n$(cat $OUTDIR/mirr.txt)" >> $OUTDIR/rootvgmirNOK.txt
         fi
# CHECK ALL LVS MIRRORED COPIES ARE ON SEPERATE DISKS
lsvg -l rootvg | grep -v sysdump | grep -v page | grep -v rootvg: | grep -v LV | grep ^hd | awk '{LPS=$3*2;if($4 != LPS)print $1"-"$NF};' > $OUTDIR/mirr.txt 2>&1
         if [ ! -s $OUTDIR/mirr.txt ]
         then
              LVCSEP="DONE"
            echo "\nAll LVS each copy on Seperate Disks" >> $OUTDIR/rootvgmirOK.txt
              else
              LVCSEP="NOSEP"
            echo "\nAllLVSNotonSeperateDisks-OR-LV_NOT_MIRRORED\n$(cat $OUTDIR/mirr.txt)" >> $OUTDIR/rootvgmirNOK.txt
         fi
         if [ "$LVMIR" == "DONE" -a "$LVCSEP" == "DONE" ]
         then
              MIR="MirrorDone"
              echo "\nMirrorDone : OK " >> $OUTDIR/rootvgmirOK.txt
              else
              MIR="MirrorNotDone"
              echo "\nMirrorNotDone Preoperly" >> $OUTDIR/rootvgmirNOK.txt
         fi
fi
# QUORUM
if [ "$MIR" = "MirrorDone" ]
then
      lsvg rootvg | grep QUORUM | grep Enabled > /dev/null 2>&1;RC=$?
      if [ $RC -eq 0 ]
      then
          echo "\nQUORUM_ENABLED" >> $OUTDIR/rootvgmirNOK.txt
          else
          echo "\nQUORUM_DISABLED" >> $OUTDIR/rootvgmirOK.txt
      fi
elif [ "$MIR" == "SANBoot" ]
then
         echo "\nQUORUM Enable/Disable: N/A" >>  $OUTDIR/rootvgmirOK.txt
elif [ "$MIR" == "MirrorNotDone" ]
then
      lsvg rootvg | grep QUORUM | grep Enabled > /dev/null 2>&1;RC=$?
      if [ $RC -eq 0 ]
      then
          echo "\nQUORUM_ENABLED" >> $OUTDIR/rootvgmirNOK.txt
          else
          echo "\nQUORUM_DISABLED" >> $OUTDIR/rootvgmirOK.txt
      fi
else
:
fi
# DUMP DEVICE
if [ "$MIR" == "MirrorDone" ]
then
        sysdumpdev -l | grep ^primary | basename `awk '{print $NF}'` | read DLV;
        if [ $DLV != "sysdumpnull" ]
        then
        lsvg -l rootvg | grep $DLV | awk '{if($3 == $4 && $4 != 2)print  "\nPRIMARY_DUMP_NOT_MIRRORED";}' >> $OUTDIR/rootvgmirOK.txt 2>&1
                  else
        echo "\nPRIMARY_DUMP_NOT_CONFIGURED_PROPERLY" >> $OUTDIR/rootvgmirNOK.txt 2>&1
        fi
        sysdumpdev -l | grep ^secondary | basename `awk '{print $NF}'` | read DLV;
        if [ $DLV != "sysdumpnull" ]
        then
lsvg -l rootvg | grep $DLV | awk '{if($3 == $4 && $4 != 2)print  "\nSecondaryDumpNotMirrored";}' >> $OUTDIR/rootvgmirOK.txt 2>&1
        else
        echo "\nSECONDARY_DUMP_NOT_CONFIGURED_PROPERLY" >> $OUTDIR/rootvgmirNOK.txt 2>&1
        fi
elif [ "$MIR" == "SANBoot" ]
then
        sysdumpdev -l | grep ^primary | basename `awk '{print $NF}'` | read DLV;
        if [ "$DLV" != "sysdumpnull" ]
        then
lsvg -l rootvg | grep $DLV | awk '{if($3 == $4 && $4 != 2)print  "\nPRIMARY_DUMP_CONFIGURED";}' >> $OUTDIR/rootvgmirOK.txt 2>&1
                  else
        echo "\nPRIMARY_DUMP_NOT_CONFIGURED_PROPERLY" >> $OUTDIR/rootvgmirNOK.txt 2>&1
        fi
        sysdumpdev -l | grep ^secondary | basename `awk '{print $NF}'` | read DLV;
        if [ "$DLV" != "sysdumpnull" ]
         then
lsvg -l rootvg | grep $DLV | awk '{if($3 == $4 && $4 != 2)print  "\nSECONDARY_DUMP_CONFIGURED";}' >> $OUTDIR/rootvgmirOK.txt 2>&1
                  else
        echo "\nSECONDARY_DUMP_NOT_REQUIRED_FOR_SANBOOT" >> $OUTDIR/rootvgmirOK.txt 2>&1
        fi
else
        sysdumpdev -l | grep ^primary | basename `awk '{print $NF}'` | read DLV;
        if [ $DLV != "sysdumpnull" ]
        then
 lsvg -l rootvg | grep $DLV | awk '{if($3 == $4 && $4 != 2)print  "\nPrimaryDumpNotMirrored-OR-PrimaryDumpConfigured";}' >> $OUTDIR/rootvgmirOK.txt 2>&1
                  else
        echo "\nPrimaryDumpNotConfiguredProperly" >> $OUTDIR/rootvgmirNOK.txt 2>&1
          fi
        sysdumpdev -l | grep ^secondary | basename `awk '{print $NF}'` | read DLV;
        if [ $DLV != "sysdumpnull" ]
        then
lsvg -l rootvg | grep $DLV | awk '{if($3 == $4 && $4 != 2)print  "\nSecondaryDumpNotMirrored-OR-SecondaryDumpConfigured";}' >> $OUTDIR/rootvgmirOK.txt 2>&1
        else
        echo "\nSecondaryDumpNotRequired" >> $OUTDIR/rootvgmirOK.txt 2>&1
        fi
fi
if [ ! -s $OUTDIR/rootvgmirNOK.txt ]
then
          violations="Compliant"
          VALUE1="$(cat $OUTDIR/rootvgmirOK.txt)"
          VALUE2=" "
#         VALUE2="$(cat $OUTDIR/rootvgmirNOK.txt)"
          else
          violations="Non-Compliant"
          VALUE1="$(cat $OUTDIR/rootvgmirOK.txt)"
          VALUE2="$(cat $OUTDIR/rootvgmirNOK.txt)"
fi
VALUE="$VALUE1\n$VALUE2"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
#A28
DescNo="A28"
DescItem="OS Bootlist"
policy_reco="Ensure the bootlist is updated with rootvg disks"
how_to="# bootlist -m normal -o"
STDBLD="M"
AUTOCHK="A"
if [ "$MIR" = "SANBoot" ]
then
   bootlist -m normal -o |grep  $(lspv|grep -w rootvg|cut -d" " -f1 | head -n 1) > /dev/null 2>&1;RC=$?
   if [ $RC -eq 0 ]
   then
     violations="Compliant"
     VALUE="$(bootlist -m normal -o)<br><br>BOOTLIST_UPDATED_CORRECT"
     else
     violations="Non-Compliant"
     VALUE="$(bootlist -m normal -o)<br><br>BOOTLIST_NOT_UPDATED_CORRECT"
   fi
elif [  "$MIR" = "MirrorDone" ]
then
       bootlist -m normal -o | grep $(lspv|grep -w rootvg|cut -d" " -f1 | head -n 1) > /dev/null 2>&1;RC1=$?
       bootlist -m normal -o | grep $(lspv|grep -w rootvg|cut -d" " -f1 | tail -n 1) > /dev/null 2>&1;RC2=$?
       ((RC=$RC1+$RC2))
       if [ $RC -eq 0 ]
       then
          violations="Compliant"
          VALUE="$(bootlist -m normal -o)<br><br>BOOTLIST_UPDATED_CORRECT"
          else
          violations="Non-Compliant"
          VALUE="$(bootlist -m normal -o)<br><br>BOOTLIST_NOT_UPDATED_CORRECT"
       fi
elif [ "$MIR" == "MirrorNotDone" ]
then
      bootlist -m normal -o | grep $(lspv|grep -w rootvg|cut -d" " -f1 | head -n 1) > /dev/null 2>&1;RC1=$?
      bootlist -m normal -o | grep $(lspv|grep -w rootvg|cut -d" " -f1 | tail -n 1) > /dev/null 2>&1;RC2=$?
       ((RC=$RC1+$RC2))
       if [ $RC -eq 0 ]
       then
          violations="Compliant"
          VALUE="$(bootlist -m normal -o)<br><br>BOOTLIST_UPDATED_CORRECT"
          else
          violations="Non-Compliant"
          VALUE="$(bootlist -m normal -o)<br><br>BOOTLIST_NOT_UPDATED_CORRECT"
       fi
else
    violations="Non-Compliant"
    VALUE="$(bootlist -m normal -o)"
    VALUE="$(bootlist -m normal -o)<br><br>BOOTLIST_NOT_UPDATED_CORRECT"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# CPU
DrawSubHead "3. CPU"  >>$HTMLLogFile
#A29
DescNo="A29"
DescItem="Simultaneous Multi Threading"
policy_reco="Ensure the SMT Enabled according to POWER Series"
how_to="# smtctl"
STDBLD="C"
AUTOCHK="A"
prtconf > $OUTDIR/prtconf.txt
PROCS=$(cat $OUTDIR/prtconf.txt  | grep "Number Of Processors:" | awk '{print $NF}')
PROCTYPE=$(cat $OUTDIR/prtconf.txt | grep "Processor Implementation Mode:"  | awk '{print $NF}')
LCPUS=$(bindprocessor -q | awk '{print $NF}')
((NLCPUS=$LCPUS+1))
if [ $PROCTYPE -eq 6 -o $PROCTYPE -eq 5 ]
then
      SMTTHRD=2
elif [ $PROCTYPE -eq 4 ]
then
      SMTTHRD=1
elif [ $PROCTYPE -eq 7 ]
then
      SMTTHRD=4
elif [ $PROCTYPE -eq 8 ]
then
      SMTTHRD=8
fi
((GET_LCPUS=$PROCS*$SMTTHRD))
if [ $GET_LCPUS -eq $NLCPUS ]
then
   echo "POWER${PROCTYPE}_SMT_ENABLED_Correct" >> $OUTDIR/smtctlinfoOK.txt 2>&1
   else
   echo "POWER${PROCTYPE}_SMT_ENABLED_NotCorrect" >> $OUTDIR/smtctlinfoNOK.txt 2>&1
fi
if [ ! -s $OUTDIR/smtctlinfoNOK.txt ]
then
          violations="Compliant"
          VALUE="$(cat $OUTDIR/smtctlinfoOK.txt)"
          else
          violations="Non-Compliant"
          VALUE="$(cat $OUTDIR/smtctlinfoNOK.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A30
DescNo="A30"
STDBLD="C"
AUTOCHK="A"
DescItem="Virtual Processor Folding Policy"
policy_reco="Ensure Virtual processor folding enabled with(vpm_fold_policy) 3"
how_to="# schedo -a | grep vpm_fold_policy"
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
VPMFOLDPOLICY=$(schedo -a | grep vpm_fold_policy | awk -F '=' '{print $2}')
if [ $VPMFOLDPOLICY -eq 3 ]
then
          violations="Compliant"
          VALUE="$(schedo -a | grep vpm_fold_policy | awk -F '=' '{print $2}')"
          else
          violations="Non-Compliant"
          VALUE="$(schedo -a | grep vpm_fold_policy | awk -F '=' '{print $2}')"
fi
else
        violations="Not-Applicable"
        VALUE="NOT APPLICABLE FOR PHYSICAL SERVERS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A31
DescNo="A31"
STDBLD="C"
AUTOCHK="A"
DescItem="Virtual CPU Addition Enablement"
policy_reco="Ensure Virtual processor folding enabled(vpm_xvcpus=1)"
how_to="# schedo -a | grep vpm_xvcpus"
#lsdev -Cc adapter | grep Available | grep Virtual >/dev/null 2>&1;RC=$?
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
VPMXVCPUS=$(schedo -a | grep vpm_xvcpus | awk -F '=' '{print $2}')
if [ $VPMXVCPUS -eq 1 ]
then
    Violations="Compliant"
        VALUE=$(schedo -a | grep vpm_xvcpus | awk -F '=' '{print $2}')
    else
    violations="Non-Compliant"
        VALUE=$(schedo -a | grep vpm_xvcpus | awk -F '=' '{print $2}')
fi
else
        violations="Not-Applicable"
        VALUE="NOT APPLICABLE FOR PHYSICAL SERVERS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A32
DescNo=A32
DescItem="Ensure that uncapped LPARs are configured to have virtual processors 1.5 times the size of their entitlement capacity."
policy_reco="Uncapped LPARs are configured to have VCPU 1.5 times of size of EC"
STDBLD="M"
AUTOCHK="A"
how_to=" "
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
MODE="$(lparstat -i | grep ^Mode | awk -F ':' '{print $2}' | tr -d ' ')"
if [ "$MODE" != "Capped" ]
then
        EC=$(lparstat -i | grep -v Pool | grep "Entitled Capacity" | awk -F ':' '{print $2}'| tr -d ' ')
        ONVCPUS=$(lparstat -i | grep "Online Virtual CPUs" | awk -F ':' '{print $2}'|tr -d ' ' )
        TOTMIN=`echo "$EC * 1.5" | bc | awk '{printf("%d\n",$0+=$0<0?-0.1:0.9)}'`
	TOTMAX=`echo "$EC * 2" | bc | awk '{printf("%d\n",$0+=$0<0?-0.1:0.9)}'`
    if ([ $ONVCPUS -ge $TOTMIN ] && [ $ONVCPUS -le $TOTMAX ])	
    then
                        VALUE="OnlineVCPUS = Roundup of 1.5*EC : $ONVCPUS = Roundup(1.5*$EC) "
                        violations="Compliant"
                        else
                        VALUE="OnlineVCPUS = Roundup of 1.5*EC : $ONVCPUS != Roundup(1.5*$EC) "
                        violations="Non-Compliant"
    fi
else
    VALUE=Patition_Mode_Is_Capped""
        violations="Not-Applicable"
fi
else
        violations="Not-Applicable"
        VALUE="NOT APPLICABLE FOR PHYSICAL SERVERS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A33
DescNo=A33
DescItem="Ensure the Minimum physical processor will be configured as desired value divided by 1.5 and Maximum physical processor will be configured as desired value times 1.5."
policy_reco="Minimum = EC/1.5 & Maximum = EC*1.5"
STDBLD="M"
AUTOCHK="A"
how_to="# lparstat -i"
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
lparstat -i | grep Type | grep -Ew "Dedicated|Dedicated-SMT" >/dev/null 2>&1;RC4=$?
if [ $RC4 -eq 0 ]
then
	violations="Not-Applicable"
	VALUE="NOT APPLICABLE FOR LPAR WITH DEDICATED PROCESSOR TYPE"
else
EC=$(lparstat -i | grep -v Pool |  grep -E "^Entitled Capacity|^Minimum Capacity|^Maximum Capacity" | sed -n '1p' | awk -F ':' '{print $2}')
MAXEC=$(lparstat -i | grep -v Pool |  grep -E "^Entitled Capacity|^Minimum Capacity|^Maximum Capacity" | sed -n '3p' | awk -F ':' '{print $2}')
MINMAX_ECCHK=$(echo "scale=1; $EC* 1.4" | bc)
MAXMAX_ECCHK=$(echo "scale=1; $EC* 2" | bc)
if ([ "$MAXEC" -ge "$MINMAX_ECCHK" ] && [ "$MAXEC" -le "$MAXMAX_ECCHK" ])
then
   echo "MAX EC is 1.5 * EC : $MAXEC = 1.5 * $EC : OK" >> $OUTDIR/ecmincmaxec.txt 2>&1
   else
   echo "MAX EC is 1.5 * EC : $MAXEC != 1.5 * $EC : NOK"  >> $OUTDIR/ecmincmaxec.txt 2>&1
fi
MINEC=$(lparstat -i | grep -v Pool |  grep -E "^Entitled Capacity|^Minimum Capacity|^Maximum Capacity" | sed -n '2p' | awk -F ':' '{print $2}')
MINMIN_ECCHK=$(echo "scale=1; $EC/ 2" | bc)
MAXMIN_ECCHK=$(echo "scale=1; $EC/ 1.4" | bc)
if ([ "$MINEC" -ge "$MINMIN_ECCHK" ] && [ "$MINEC" -le "$MAXMIN_ECCHK" ])
then
   echo "MIN EC is 1.5 / EC : $MINEC = 1.5 / $EC : OK"  >> $OUTDIR/ecmincmaxec.txt 2>&1
   else
   echo "MIN EC is 1.5 / EC : $MINEC != 1.5 / $EC : NOK"  >> $OUTDIR/ecmincmaxec.txt 2>&1
fi
cat  $OUTDIR/ecmincmaxec.txt | grep -w NOK > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
    VALUE="$(cat $OUTDIR/ecmincmaxec.txt)"
    violations="Compliant"
   else
    VALUE="$(cat $OUTDIR/ecmincmaxec.txt)"
    violations="Non-Compliant"
fi
fi
else
        violations="Not-Applicable"
        VALUE="NOT APPLICABLE FOR PHYSICAL SERVERS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A34
DescNo="A34"
DescItem="Ensure the weightage of the uncapped partitions is set as below to manage the workload across the LPARs.<br> 1. 255 for VIOS LPAR to allow for 44% of usage <br>2. 225 for application LPAR to allow for 39% of usage <br>3. 100 for NIM LPAR to allowed for 17% of usage"
policy_reco="Uncapped Weight : 255 - VIO Server, 128 - Application LPARs, 100 - NIM LPARs"
STDBLD="M"
AUTOCHK="A"
how_to=" "
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
MODE="$(lparstat -i | grep ^"Mode" | awk -F ':' '{print $2}'| tr -d ' ')"
if [ "$MODE" = "Uncapped" ]
then
HOSTE=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]' | sed 's/^.*\(.\)$/\1/')
LPARWEI=$(lparstat -i | grep ^"Variable Capacity Weight" | awk -F ':' '{print $2}' | tr -d ' ')
if ([ "$HOSTE" = "g" ] || [ "$HOSTE" = "r" ] || [ "$HOSTE" = "c" ])
	then
	if ([ $LPARWEI -eq 128 ] || [ $LPARWEI -eq 225 ])
	then
		VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
		violations="Compliant"
	else
		VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
		violations="Non-Compliant"
	fi
elif [ "$HOSTE" = "t" ]
	then
        if [ $LPARWEI -eq 25 ]
        then
                VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
                violations="Compliant"
        else
                VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
                violations="Non-Compliant"
        fi
elif [ "$HOSTE" = "b" ]
	then
        if [ $LPARWEI -eq 100 ]
        then
                VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
                violations="Compliant"
        else
                VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
                violations="Non-Compliant"
        fi
elif [ "$HOSTE" = "s" ]
        then
        if [ $LPARWEI -eq 200 ]
        then
                VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
                violations="Compliant"
        else
                VALUE="$(lparstat -i | grep ^"Variable Capacity Weight")"
                violations="Non-Compliant"
        fi
fi	
else
                   VALUE="Patition_Mode_Is_Capped"
                   violations="Not-Applicable"
fi
else
        violations="Not-Applicable"
        VALUE="NOT APPLICABLE FOR PHYSICAL SERVERS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A35
DescNo=A35
DescItem="Ensure that the number of virtual processors in each LPAR in the system do not exceed the number of cores available in the system (CEC/framework) or if the partition is defined to run in specific virtual shared processor pool, the number of virtual processors should not exceed the maximum defined for the specific virtual shared processor pool."
policy_reco="No. of Virtual Processor should not exceed the maximum no of EC in the Frame"
STDBLD="M"
AUTOCHK="A"
how_to=" "
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
ON_VCPUS=$(lparstat -i | grep "Online Virtual CPUs " | awk -F ':' '{print $2}')
MAX_PHY_CPU=$(lparstat -i | grep "Maximum Physical CPUs in system" | awk -F ':' '{print $2}')
if [ $ON_VCPUS -ge $MAX_PHY_CPU ]
then
                   VALUE="OnlineVCPUS >= MaXPhyCPUS : $ON_VCPUS >= $MAX_PHY_CPU"
                   violations="Non-Compliant"
                   else
                   VALUE="OnlineVCPUS <= MaXPhyCPUS : $ON_VCPUS <= $MAX_PHY_CPU"
                   violations="Compliant"
fi
else
        violations="Not-Applicable"
        VALUE="NOT APPLICABLE FOR PHYSICAL SERVERS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#
DrawSubHead "4. Memory"  >>$HTMLLogFile

# A36
DescNo=A36
DescItem="Minimum memory will be configured as desired value divided by 1.5 and Maximum memory will be configured as desired value times 1.5."
policy_reco="Minimum Memory = Desired Memory / 1.5 [(Rounddown((Desired Mem/1.5)/LMB,0))*LMB], Maximum Memory = Desired Memory * 1.5"
STDBLD="M"
AUTOCHK="A"
how_to="Memory"
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
MIN_MEM=$(lparstat -i | grep -E "Online Memory|Maximum Memory|Minimum Memory" | sed -n '3p' | awk -F ':' '{print $2}' | sed -e 's/MB//g')
ON_MEM=$(lparstat -i | grep -E "Online Memory|Maximum Memory|Minimum Memory" | sed -n '1p'  | awk -F ':' '{print $2}' | sed -e 's/MB//g')
MAX_MEM=$(lparstat -i | grep -E "Online Memory|Maximum Memory|Minimum Memory" | sed -n '2p' | awk -F ':' '{print $2}'| sed -e 's/MB//g')
MINCHK_MIN=$(echo "scale=2; $ON_MEM/ 1.4" | bc)
MINCHK_MAX=$(echo "scale=2; $ON_MEM/ 2" | bc)
#((MINIS=$ON_MEM/2))
if ([ "$MIN_MEM" -ge "$MINCHK_MAX" ] && [ "$MIN_MEM" -le "$MINCHK_MIN" ])
#if [ $MINIS -eq $MIN_MEM ]
then
   echo "Min.Memory = Online.memory / 1.5 : MINMEM = $ON_MEM / 1.5 = $MIN_MEM : OK"  >> $OUTDIR/minmaxmem.txt 2>&1
   else
   echo "Min.Memory = Online.memory / 1.5 : MINMEM = $ON_MEM / 1.5 != $MIN_MEM : NOK"  >> $OUTDIR/minmaxmem.txt 2>&1
fi
MAXCHK_MIN=$(echo "scale=2; $ON_MEM* 1.4" | bc)
MAXCHK_MAX=$(echo "scale=2; $ON_MEM* 2" | bc)
#((MAXIS=$ON_MEM*2))
#if [ $MAXIS -eq $MAX_MEM ]
if ([ "$MAX_MEM" -ge "$MAXCHK_MIN" ] && [ "$MAX_MEM" -le "$MAXCHK_MAX" ])
then
   echo "Max.Memory = Online.memory X 1.5 : MAXMEM = $ON_MEM X 1.5 = $MAX_MEM : OK"  >> $OUTDIR/minmaxmem.txt 2>&1
   else
   echo "Max.Memory = Online.memory X 1.5 : MAXMEM = $ON_MEM X 1.5 != $MAX_MEM : NOK"  >> $OUTDIR/minmaxmem.txt 2>&1
fi
cat  $OUTDIR/minmaxmem.txt | grep -w NOK > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
    VALUE="$(cat $OUTDIR/minmaxmem.txt)"
    violations="Compliant"
   else
    VALUE="$(cat $OUTDIR/minmaxmem.txt)"
    violations="Non-Compliant"
fi
else
        violations="Not-Applicable"
        VALUE="NOT APPLICABLE FOR PHYSICAL SERVERS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#A37
DescNo="A37"
STDBLD="C"
AUTOCHK="A"
DescItem="maxperm%"
policy_reco="maxperm%=90%"
how_to="# vmo -L maxperm%"
MAXPERM=$(vmo -L maxperm% | grep ^maxperm% | awk '{print $2}')
if [ $MAXPERM -eq 90 ]
then
          violations="Compliant"
          VALUE="$(vmo -L maxperm% | grep ^maxperm% | awk '{print $2}')"
          else
          violations="Non-Compliant"
          VALUE="$(vmo -L  maxperm% | grep ^maxperm% | awk '{print $2}')"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A38
DescNo="A38"
STDBLD="C"
AUTOCHK="A"
DescItem="maxclient%"
policy_reco="maxclient%=90%"
how_to="# vmo -L maxclient%"
MAXCLIENT=$(vmo -L  maxclient% | grep ^maxclient% | awk '{print $2}')
if [ $MAXCLIENT -eq 90 ]
then
          violations="Compliant"
          VALUE="$(vmo -L maxclient% | grep ^maxclient% | awk '{print $2}')"
          else
          violations="Non-Compliant"
          VALUE="$(vmo -L maxclient% | grep ^maxclient% | awk '{print $2}')"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A39
DescNo="A39"
STDBLD="C"
AUTOCHK="A"
DescItem="minperm%"
policy_reco="minperm%=3%"
how_to="# vmo -L minperm%"
MINPERM=$(vmo -L  minperm% | grep ^minperm% | awk '{print $2}')
if [ $MINPERM -eq 3 ]
then
          violations="Compliant"
          VALUE="$(vmo -L minperm% | grep ^minperm% | awk '{print $2}')"
          else
          violations="Non-Compliant"
          VALUE="$(vmo -L  minperm% | grep ^minperm% | awk '{print $2}')"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A40
DescNo="A40"
STDBLD="C"
AUTOCHK="A"
DescItem="PageIn/PageOut Classification"
policy_reco="When the number of permanent memory pages (numperm) falls between minperm and maxperm, or the number of client memory pages falls between minperm and maxclient, this setting indicates whether repaging rates are considered when deciding to evict permanent memory pages or computational memory pages. Setting this to 0 tells AIX to ignore repaging rates and favor evicting permament memory pages, and thus keeping more computational memory in RAM.(lru_file_repage=0)"
how_to="# vmo -L lru_file_repage"
OSIS=$(oslevel -r | cut -c 1-2)
if [ "$OSIS" != "71" ]
then
LRUFILEREPAGE=$(vmo -L lru_file_repage | grep lru_file_repage | awk '{print $2}')
if [ $LRUFILEREPAGE -eq 0 ]
then
          violations="Compliant"
          VALUE="$(vmo -L  | grep lru_file_repage | awk '{print $2}')"
          else
          violations="Non-Compliant"
          VALUE="$(vmo -L  | grep lru_file_repage | awk '{print $2}')"
fi
else
          violations="Not-Applicable"
          VALUE="Default [lru_file_repage=0 ] NOTE:lru_file_repage is hardcoded to 0 with AIX7.1"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A41
DescNo="A41"
STDBLD="C"
AUTOCHK="A"
DescItem="page steal method"
policy_reco="page steal method(page_steal_method)"
how_to="# vmo -L page_steal_method"
PAGESTEALMETHOD=$(vmo -L page_steal_method | grep ^page_steal_method | awk '{print $2}')
if [ $PAGESTEALMETHOD -eq 1 ]
then
          violations="Compliant"
          VALUE="$(vmo -L page_steal_method | grep page_steal_method | awk '{print $2}')"
          else
          violations="Non-Compliant"
          VALUE="$(vmo -L page_steal_method | grep page_steal_method | awk '{print $2}')"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

######
DrawSubHead "5. STORAGE"  >>$HTMLLogFile
######

#A42
DescNo="A42"
STDBLD="C"
AUTOCHK="A"
how_to="# lslpp -l "
DescItem="MultiPath Software"
policy_reco="Ensure Proper Multipath software Installed"
> $OUTDIR/lppOut.txt
#lsdev -Cc disk | grep "FC" > /dev/null 2>&1;RC=$?
lsdev -Cc disk|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
                lsdev -Cc disk | grep power > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="EMC"

		lsdev -Cc disk | grep Hitachi  > /dev/null 2>&1;RC=$?
		[ $RC -eq 0 ] && SANTYPE="Hitachi"

                lsdev -Cc disk | grep ^vpath > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="VPATH"

                lslpp -l | grep -wi sddpcm > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="SDDPCM"
else
          how_to=""
          violations="Not-Applicable"
          VALUE="No SAN Disks Found"
fi
if [ "$SANTYPE" = "VPATH" ]
then
                lslpp -l | grep -wi SDD > $OUTDIR/lppOut.txt 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
                how_to="# lslpp -l | grep -wi sdd"
                                violations="Non-Compliant"
                                VALUE="$(lslpp -l | grep -wi SDD | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1)"
                                else
                                how_to="# lslpp -l | grep -wi sdd"
                                violations="Non-Compliant"
                                VALUE="Fileset Not found"
                fi
elif [ "$SANTYPE" = "EMC"  ]
then
       lslpp -l | grep -wi powerpath  > $OUTDIR/lppOut.txt 2>&1;RC=$?
       if [ $RC -eq 0 ]
       then
           violations="Compliant"
           VALUE="$(lslpp -l | grep -wi powerpath  | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1)"
           how_to="# lslpp -l | grep -wi powerpath"
           else
           how_to="# lslpp -l | grep -wi powerpath"
           violations="Non-Compliant"
           VALUE="Fileset Not found"
       fi
elif [ "$SANTYPE" = "SDDPCM" ]
then
       lslpp -l | grep -wi sddpcm  > $OUTDIR/lppOut.txt 2>&1;RC=$?
       if [ $RC -eq 0 ]
       then
           violations="Compliant"
           VALUE="$(lslpp -l | grep -wi sddpcm | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1)"
           how_to="# lslpp -l | grep -wi sddpcm"
           else
           how_to="# lslpp -l | grep -wi sddpcm"
           violations="Non-Compliant"
           VALUE="Fileset Not found"
       fi
elif [ "$SANTYPE" = "Hitachi" ]
then
	HOSTE=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]' | sed 's/^.*\(.\)$/\1/')
	if ([ "$HOSTE" = "g" ] || [ "$HOSTE" = "r" ] || [ "$HOSTE" = "c" ])
	then
 	       lslpp -l | grep -wi hitachi  > $OUTDIR/lppOut.txt 2>&1;RC=$?
	       if [ $RC -eq 0 ]
	       then
           violations="Compliant"
           VALUE="$(lslpp -l | grep -wi hitachi | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1)"
           how_to="# lslpp -l | grep -wi hitachi"
           else
           how_to="# lslpp -l | grep -wi hitachi"
           violations="Non-Compliant"
           VALUE="Fileset Not found"
		fi
	else
               lslpp -l | grep -wi hitachi  > $OUTDIR/lppOut.txt 2>&1;RC=$?
               if [ $RC -eq 0 ]
               then
           violations="Compliant"
           VALUE="$(lslpp -l | grep -wi hitachi | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1)"
           how_to="# lslpp -l | grep -wi hitachi"
           else
           how_to="# lslpp -l | grep -wi hitachi"
           violations="Non-Compliant"
           VALUE="Fileset Not found"		
		fi
       fi
else
          how_to=""
          violations="Not-Applicable"
          VALUE="No SAN Disks Found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


########
#A43
DescNo="A43"
DescItem="PATH Algorithm for SDDPCM/Hitachi disks"
policy_reco="Ensusre that round robin algorithm, Reserve policy is configured when SDDPCM/Hitachi is used"
STDBLD="A"
AUTOCHK="A"
how_to="# lsattr -El hdiskX"
# Algorithm
lsdev -Cc disk|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
                lsdev -Cc disk | grep power > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="EMC"

                lsdev -Cc disk | grep Hitachi  > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="Hitachi"

                lsdev -Cc disk | grep ^vpath > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="VPATH"

                lslpp -l | grep -wi sddpcm > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="SDDPCM"
else
          how_to=""
          violations="Not-Applicable"
          VALUE="No SAN Disks Found"
fi
if [ "$SANTYPE" = "SDDPCM" ]
then
lsdev -Cc disk | grep Available | grep FC | awk '{print "lsattr -El "$1" -a algorithm"}' | ksh | grep -v round > /dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
            violations="Non-Compliant"
            VALUE="$(lsdev -Cc disk | grep Available | grep FC | awk '{print "lsattr -El "$1" -a algorithm"}' | ksh  | awk '{print $1" "$2}'| grep -v round)"
            else
            violations="Compliant"
            VALUE="All PATH ALOGORITHM Set to round_robin OK"
       fi
elif [ "$SANTYPE" = "Hitachi" ]
then
lsdev -Cc disk | grep Available | grep Hitachi | awk '{print "lsattr -El "$1" -a algorithm"}' | ksh | grep -v round > /dev/null 2>&1;RC1=$?
lsdev -Cc disk | grep Available | grep Hitachi | awk '{print "lsattr -El "$1" -a reserve_policy"}' | ksh | grep -v no_reserve > /dev/null 2>&1;RC2=$?
((RC=$RC1+$RC2))
	if [ $RC -eq 0 ]
        then
            violations="Non-Compliant"
            VALUE1="$(lsdev -Cc disk | grep Available | grep Hitachi | awk '{print "lsattr -El "$1" -a algorithm"}' | ksh | awk '{print $1" "$2}'| grep -v round)"
            VALUE2="$(lsdev -Cc disk | grep Available | grep Hitachi | awk '{print "lsattr -El "$1" -a reserve_policy"}' | ksh | awk '{print $1" "$2}'| grep -v no_reserve)"
	    VALUE="$VALUE1\n$VALUE2"		
            else
            violations="Compliant"
            VALUE1="All PATH ALOGORITHM Set to round_robin OK"
	    VALUE2="All RESERVE POLICY Set to no_reserve OK"
            VALUE="$VALUE1\n$VALUE2"	 
	fi
else
 violations="Not-Applicable"
 VALUE="NO SDDPCM Drivers / Hitachi Disks FOUND...."
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A44
DescNo="A44"
DescItem="Default ODM Value of algorithm for SDDPCM/Hitachi disks"
policy_reco="Ensure SDDPCM disks default algorith is set to round_robin"
STDBLD="A"
AUTOCHK="A"
how_to="# odmget -q \"uniquetype=PCM/friend/sddpcm(or)hitachi AND attribute=algorithm\" PdAt"
lsdev -Cc disk|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
                lsdev -Cc disk | grep power > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="EMC"

                lsdev -Cc disk | grep Hitachi  > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="Hitachi"

                lsdev -Cc disk | grep ^vpath > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="VPATH"

                lslpp -l | grep -wi sddpcm > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="SDDPCM"
else
          how_to=""
          violations="Not-Applicable"
          VALUE="No SAN Disks Found"
fi
if [ "$SANTYPE" = "SDDPCM" ]
then
odmget -q "uniquetype=PCM/friend/sddpcm AND attribute=algorithm" PdAt | grep deflt | grep -wv round_robin > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
     odmget -q "uniquetype=PCM/friend/sddpcm AND attribute=algorithm" PdAt >> $OUTDIR/algoodminfo.txt
     violations="Compliant"
     VALUE="ODM Updated to ROUND_ROBIN at ODM level<br><br>$(cat $OUTDIR/algoodminfo.txt)"
     else
     violations="Non-Compliant"
     VALUE="$(odmget -q "uniquetype=PCM/friend/sddpcm AND attribute=algorithm" PdAt)"
fi
elif [ "$SANTYPE" = "Hitachi" ]
then
odmget -q "uniquetype=PCM/friend/Hitachi AND attribute=algorithm" PdAt | grep deflt | grep -wv round_robin > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
     odmget -q "uniquetype=PCM/friend/Hitachi AND attribute=algorithm" PdAt >> $OUTDIR/algoodminfo.txt
     violations="Compliant"
     VALUE="ODM Updated to ROUND_ROBIN at ODM level<br><br>$(cat $OUTDIR/algoodminfo.txt)"
     else
     violations="Non-Compliant"
     VALUE="$(odmget -q "uniquetype=PCM/friend/Hitachi AND attribute=algorithm" PdAt)"
fi
else
 violations="Not-Applicable"
 VALUE="NO SDDPCM/Hitachi Disks FOUND...."
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


########
#A45
DescNo="A45"
STDBLD="C"
AUTOCHK="A"
DescItem="HBA Attributes"
policy_reco="Ensure HBA Attributes set as dyntrk-yes|fc_err_recov-fast_fail"
how_to="# lsattr -El fscsiX"
lsdev -Cc adapter  | grep -v Def | grep ^fcs  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
                >$OUTDIR/fcsattrs.txt
                lsdev -Cc adapter | grep -v Def | grep ^fcs | awk '{print $1}' | while read FCS
                do
                        FSCSI=$(echo "$FCS" |  sed -e 's/fcs/fscsi/g')
#                       echo "$FCS : $(lsattr -El $FSCSI | grep -E "dyntrk|fc_err_recov" | awk '{print $1" "$2}' | tr '\n' ' ')" >> $OUTDIR/fcsattrs.txt
                        echo "$FCS : $(lsattr -El $FSCSI | grep -E "dyntrk|fc_err_recov|scsi_id" | awk '{print $1" "$2}' | tr '\n' ' ' ; lscfg -l $FCS |  awk -F " " '{print $2}' | tr '\n' ' ' ; lscfg -vpl $FCS | grep "Network Address" | sed -e 's/Network Address.............//g' | tr -d ' ' )" >> $OUTDIR/fcsattrs.txt
                done
                cat $OUTDIR/fcsattrs.txt  | grep "fc_err_recov" | grep  "delayed_fail" > /dev/null 2>&1;RC1=$?
                cat $OUTDIR/fcsattrs.txt  | grep "dyntrk" |  grep  "no" > /dev/null 2>&1;RC2=$?
                ((RC=$RC1+$RC2))
                if [ $RC -ne 0 ]
                then
                                violations="Compliant"
                                VALUE="$(cat $OUTDIR/fcsattrs.txt)"

                                else

                                violations="Non-Compliant"
                                VALUE="$(cat $OUTDIR/fcsattrs.txt)"
                fi
else
         violations="Not-Applicable"
         VALUE="NO FCS FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

####

#A46
DescNo="A46"
DescItem="VSCSI Attributes"
policy_reco="Ensure that fast failure is enabled on VSCSI adapters"
STDBLD="A"
AUTOCHK="A"
how_to="# lsattr -El vscsiX"
lsdev -Cc adapter | grep ^vscsi > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        lsdev -Cc adapter | grep ^vscsi | grep -i available | awk '{print "lsattr -El "$1" -a vscsi_err_recov"}' | ksh | grep delayed_fail > /dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
                violations="Non-Compliant"
                VALUE="$(lsdev -Cc adapter | grep ^vscsi | grep -i available | awk '{print "lsattr -El "$1" -a vscsi_err_recov"}' | ksh  | awk '{print $1" "$2}'| grep  fail)"
                else
                violations="Compliant"
                VALUE="$(lsdev -Cc adapter | grep ^vscsi | grep -i available | awk '{print "lsattr -El "$1" -a vscsi_err_recov"}' | ksh  | awk '{print $1" "$2}'| grep  fail)"
        fi
else
        violations="Not-Applicable"
        VALUE="NO VSCSI ADAPTERS FOUND...."
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A47
DescNo="A47"
STDBLD="A"
AUTOCHK="A"
DescItem="HBA Attributes on ODM"
policy_reco="Ensure HBA Attributes updated in ODM to get default values"
how_to="# odmget  -q 'uniquetype=driver/iocb/efscsi and attribute=dyntrk' PdAt<br>odmget  -q 'uniquetype=driver/iocb/efscsi and attribute=fc_err_recov' PdAt"
lsdev -Cc adapter | grep ^fcs | grep Available  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=dyntrk" PdAt >> $OUTDIR/fcsodminfo.txt
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=fc_err_recov" PdAt >> $OUTDIR/fcsodminfo.txt
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=dyntrk" PdAt | grep "deflt" | grep -w no > /dev/null 2>&1;RC=$?
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=fc_err_recov" PdAt | grep -w deflt | grep delayed_fail > /dev/null 2>&1;RC=$?
        if [ $RC -ne 0 ]
        then
         violations="Compliant"
         VALUE="$(cat $OUTDIR/fcsodminfo.txt)"
         else
         violations="Non-Compliant"
         VALUE="$(cat $OUTDIR/fcsodminfo.txt)"
        fi
else
         violations="Not-Applicable"
         VALUE="NO FCS FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


######
#A48
DescNo="A48"
DescItem="Disk HealthCheck Capability"
policy_reco="Ensure the HealthCheck Capability is set to \"nonactive\" mode"
STDBLD="C"
AUTOCHK="A"
how_to="# lsattr -El hdsikX"
lsdev -Cc disk | grep FC > /dev/null 2>&1;RC1=$?
lsdev -Cc disk | grep ^vpath > /dev/null 2>&1;RC2=$?
lsdev -Cc disk | grep Hitachi > /dev/null 2>&1;RC3=$?	
((RC=$RC1+$RC2+RC3))
if [ $RC -ne 0 ]
then
lsdev -Cc disk | grep Available | grep -E "FC|Hitachi" | awk '{print "lsattr -El "$1" -a hcheck_mode"}' | ksh | awk '{print $1" "$2}' | grep -v "hcheck_mode nonactive" > /dev/null 2>&1;RC=$?
     if [ $RC -eq 0 ]
     then
                violations="Non-Compliant"
                VALUE="$(lsdev -Cc disk | grep Available | grep -E "FC|Hitachi" | awk '{print "lsattr -El "$1"  -a hcheck_mode"}' | ksh | awk '{print $1" "$2}' | grep -v "hcheck_mode nonactive")"
         else
         violations="Compliant"
         VALUE="ALL DISKS hcheck_mode SET TO nonactive"
     fi
else
        violations="Not-Applicable"
        VALUE="NO SAN DISKS FOUND...-OR- DISKS MAY BE VPATHS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

############
#A49
DescNo="A49"
DescItem="Disk HealthCheck Interval"
policy_reco="Ensure that Disk HealthCheck Interval set to 60secs"
STDBLD="A"
AUTOCHK="A"
how_to="# lsattr -El hdiskX"
lsdev -Cc disk | grep FC > /dev/null 2>&1;RC1=$?
lsdev -Cc disk | grep ^vpath > /dev/null 2>&1;RC2=$?
lsdev -Cc disk | grep Hitachi > /dev/null 2>&1;RC3=$?
((RC=$RC1+$RC2+RC3))
if [ $RC -ne 0 ]
then
                lsdev -Cc disk | grep Available | grep -E "FC|Hitachi" | awk '{print "lsattr -El "$1"  -a hcheck_interval"}' | ksh | awk '{print $1" "$2}'| grep -v "hcheck_interval 60" > /dev/null 2>&1;RC=$?
                if [ $RC -eq 0 ]
                then
                                violations="Non-Compliant"
                                VALUE="$(lsdev -Cc disk | grep Available | grep -E "FC|Hitachi" | awk '{print "lsattr -El "$1"  -a hcheck_interval"}'  | ksh | awk '{print $1" "$2}'| grep -v "hcheck_interval 60")"
                                else
                                violations="Compliant"
                                VALUE="ALL DISKS hcheck_interval SET TO 60"
                fi
else
        violations="Not-Applicable"
        VALUE="NO SAN DISKS FOUND..-OR- Disks Maybe VPATHS "
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

################
#A50
DescNo="A50"
DescItem="Disk QueueDepth"
policy_reco="Ensure that Disk Queue Depth is set (queue_depth=3 for VSCSI and queue_depth=8 for Hitachi Disks)"
STDBLD="C"
AUTOCHK="A"
how_to="# lsattr -El hdiskX"
lsdev -Cc disk|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
                lsdev -Cc disk | grep power > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="EMC"

                lsdev -Cc disk | grep Hitachi  > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="Hitachi"

                lsdev -Cc disk | grep ^vpath > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="VPATH"

                lslpp -l | grep -wi sddpcm > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="SDDPCM"

		lsdev -Cc disk | grep "Virtual SCSI Disk Drive" > /dev/null 2>&1;RC=$?
		[ $RC -eq 0 ] && SANTYPE="VSCSI"
else
          how_to=""
          violations="Not-Applicable"
          VALUE="No SAN Disks Found"
fi
if [ "$SANTYPE" = "Hitachi" ]
then
	lsdev -Cc disk | grep Hitachi |  awk '{print $1}' | while read DISKH
	do
	echo "$DISKH : $(lsattr -El $DISKH -a queue_depth | awk '{print $1" "$2}')" >> $OUTDIR/vdisksinfo.txt  2>&1
	done
	cat $OUTDIR/vdisksinfo.txt | grep -v "queue_depth 8"  > /dev/null 2>&1;RC=$?
	if [ $RC -eq 0 ]
        then
               VALUE=$(cat $OUTDIR/vdisksinfo.txt)
                violations="Non-Compliant"
	else
               VALUE=$(cat $OUTDIR/vdisksinfo.txt)
               violations="Compliant"
        fi
elif [ "$SANTYPE" = "VSCSI" ]
then
        lsdev -Cc disk | grep "Virtual SCSI Disk Drive" | awk '{print $1}' | while read VDISK
        do
        echo "$VDISK : $(lsattr -El $VDISK -a queue_depth | awk '{print $1" "$2}')" >> $OUTDIR/vdisksinfo.txt  2>&1
        done
        cat $OUTDIR/vdisksinfo.txt | grep -v "queue_depth 3"  > /dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
               VALUE=$(cat $OUTDIR/vdisksinfo.txt)
                violations="Non-Compliant"
	else
               VALUE=$(cat $OUTDIR/vdisksinfo.txt)
               violations="Compliant"
        fi
else
               VALUE="NO VSCSI/Hitachi DISK FOUND"
               violations="Not-Applicable"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###################
#A51
DescNo="A51"
STDBLD="C"
AUTOCHK="A"
DescItem="SAN PATHS"
policy_reco="For SAN attached servers, ensure that all LUNS are dual path and all SAN disks paths are available state."
lsdev -Cc disk | grep -wE "FC|PowerPath|Hitachi"  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
                lsdev -Cc disk | grep power > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="EMC"

                lsdev -Cc disk | grep ^vpath > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="VPATH"

                lslpp -l | grep -wi sddpcm > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="SDDPCM"

                lsdev -Cc disk | grep Hitachi  > /dev/null 2>&1;RC=$?
                [ $RC -eq 0 ] && SANTYPE="Hitachi"
else
          how_to=""
          violations="Not-Applicable"
          VALUE="No SAN Disks Found"
fi
# SDD
if [ "$SANTYPE" = "VPATH" ]
then
   datapath query adapter | grep fscsi | grep -v NORMAL > /dev/null 2>&1;RC=$?
   if [ $RC -ne 0 ]
   then
          violations="Compliant"
          VALUE1="$(datapath query adapter)"
          VALUE2="$(lsvpcfg)"
          VALUE="$VALUE1<br><br>$VALUE2"
          how_to="# datapath query adapter"
          else
          violations="Non-Compliant"
          VALUE1="$(datapath query adapter)"
          VALUE2="$(lsvpcfg)"
          VALUE="$VALUE1<br><br>$VALUE2"
          how_to="# datapath query adapter"
   fi
elif [ "$SANTYPE" = "SDDPCM" ]
then
   pcmpath query adapter | grep fscsi | grep -v NORMAL > /dev/null 2>&1;RC=$?
   if [ $RC -ne 0 ]
   then
                        violations="Compliant"
                        VALUE1="$(pcmpath query adapter)"
                        VALUE2="$(lspcmcfg)"
                        VALUE="$VALUE1<br><br>$VALUE2"
                        how_to="# pcmpath query adapter"
                        else
                        violations="Non-Compliant"
                        VALUE1="$(pcmpath query adapter)"
                        VALUE2="$(lspcmcfg)"
                        VALUE="$VALUE1<br><br>$VALUE2"
                        how_to="# pcmpath query adapter"
   fi
elif [ "$SANTYPE" = "EMC" ]
then
   powermt display | grep fscsi | grep -v optimal > /dev/null 2>&1;RC=$?
   if [ $RC -ne 0 ]
   then
          violations="Compliant"
          VALUE1="$(powermt display)"
          VALUE2="$(powermt display dev=all | grep -E "Pseudo|ID")"
          VALUE="$VALUE1<br><br>$VALUE2"
          how_to="# powermt display"
          else
          VALUE1="$(powermt display)"
          VALUE2="$(powermt display dev=all | grep -E "Pseudo|ID")"
          VALUE="$VALUE1<br><br>$VALUE2"
          violations="Non-Compliant"
          how_to="# powermt display"
   fi
elif [ "$SANTYPE" = "Hitachi" ]
then
	lsdev -Cc disk|grep "Hitachi" | grep Available | awk '{print $1}' | while read DISKPATH
	do
	PCNT=`lspath | grep -w $DISKPATH | grep Enabled | sort -u | wc -l`
        VPCNT=`expr $PCNT % 2`
        if [ $VPCNT -eq 0 ]
                then
                        echo "$(lspath | grep -w $DISKPATH | grep Enabled | sort -u) : OK" >> $OUTDIR/diskpath.txt
                        else
                        echo "$(lspath | grep -w $DISKPATH | grep Enabled | sort -u) : NOK" >> $OUTDIR/diskpath.txt
                fi
        done
                echo " OK " >> $OUTDIR/diskpath.txt
cat  $OUTDIR/diskpath.txt | grep NOK > /dev/null 2>&1;RC1=$?
if [ $RC1 -eq 0 ]
then
     VALUE1="$(lsmpio -ar)"
     VALUE2="$(lsdev -Cc disk | grep Hitachi | while read i k; do echo " $i : $(lspv $i | grep "VOLUME GROUP" | awk '{print $NF}') :  $(lsmpio -ql $i | grep -i "Volume Serial" | awk -F : '{print $2}' | awk -F "[()]" '{print $1}' | sed 's/ *$//' |  sed 's/^.*\(....\)$/\1/' ) " ; done)"
     VALUE="$VALUE1\n$VALUE2"	
     violations="Non-Compliant"
else
     VALUE1="$(lsmpio -ar)"
     VALUE2="$(lsdev -Cc disk | grep Hitachi | while read i k; do echo " $i : $(lspv $i | grep "VOLUME GROUP" | awk '{print $NF}') :  $(lsmpio -ql $i | grep -i "Volume Serial" | awk -F : '{print $2}' | awk -F "[()]" '{print $1}' | sed 's/ *$//' |  sed 's/^.*\(....\)$/\1/' ) " ; done)"
     VALUE="$VALUE1\n$VALUE2"
     violations="Compliant"
fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###################
########################### IP FORWARDING
######
DrawSubHead "6. NETWORK"  >>$HTMLLogFile
######

#A52
DescNo="A52"
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep ipforwarding"
DescItem="IP Forwarding: Deactivate IP forwarding"
policy_reco="Ensure that AIX is not acting as a router by turning off IP forwarding."
VALUE=$(no -a | grep ipforwarding | awk -F '=' '{print $2}')
if [ $VALUE -eq 0 ]; then
        violations="Compliant"
        VALUE=`grep ipforwarding /etc/rc.net|head -1`
  else
    violations="Non-Compliant"
    VALUE="IP forwarding turned on"
  fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

########################### ROUTE_EXPIRE

#A53
DescNo="A53"
DescItem="route_expire"
policy_reco="Ensure that AIX will learn new route when there is a network outage."
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep route_expire"
#how_to="# no -a"
VALUE=$(no -a | grep route_expire | awk -F '=' '{print $2}')
if [ $VALUE  -eq 1 ]
then
    violations="Compliant"
  else
    violations="Non-Compliant"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A54
DescNo="A54"
DescItem="EtherChannel"
policy_reco="Ensure that EtherChannel netif_backup mode (AIX 5.1) or EtherChannel backup adapter (AIX 5.2) is configured to provide network adapter redundancy on two network adapters, each connecting to a different switch.<br>1.Etherchannel can be configured in Network Interface Backup mode to improve redundancy between two Ethernet ports. Ensure the two Ethernet ports are two different physical Ethernet adapters connecting to two different switches.<br>2.While configuring NIB, enter a reliable IP address such as a routers IP address in the Address to Ping parameter. This is the way that the system can identify the primary adapter is no longer active and will move the traffic to the backup adapter.<br>3.Link aggregation is used to achieve increase in bandwidth using two Ethernet ports and creating a logical Ethernet port.While using link aggregation, ensure that the two ports used are from different physical Ethernet adapters but they are connecting to the same network switch. The switch also must support LACP protocol.<br>"
STDBLD="A"
AUTOCHK="A"
how_to="# EtherChannel Configuration"
>$OUTDIR/ethchan.txt
lsdev -Cc adapter | grep ^ent | grep "Virtual I/O Ethernet Adapter" | grep Available > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
lsdev -Cc adapter | grep EtherChannel > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        echo "1.EtherChannel configured in NIB Mode:" >> $OUTDIR/ethchan.txt
        lsdev -Cc adapter | grep EtherChannel | awk '{print $1}' | while read ETHCH
        do
                BKPADPT=$(lsattr -El $ETHCH | grep backup_adapter | awk '{print $2}')
                if [ "$BKPADPT" = "NONE" ]
                then
                      echo "$ETHCH : $(lsattr -El $ETHCH | grep adapter_names | awk '{print "Primary adapter:",$2}'): NOK" >> $OUTDIR/ethchan.txt
                      echo "$ETHCH : $(lsattr -El $ETHCH | grep backup_adapter | awk '{print $1" "$2}'): NOK" >> $OUTDIR/ethchan.txt
                      else
                      echo "$ETHCH : $(lsattr -El $ETHCH | grep adapter_names | awk '{print "Primary adapter:",$2}'): OK" >> $OUTDIR/ethchan.txt
                      echo "$ETHCH : $(lsattr -El $ETHCH | grep backup_adapter | awk '{print $1" "$2}'): OK" >> $OUTDIR/ethchan.txt
                fi
        done
else
        echo "1.NO ETHERCHANNEL ADAPTERS CONFIGURED" >> $OUTDIR/ethchan.txt
fi
lsdev -Cc adapter | grep EtherChannel > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        echo "2.EtherChannel Address to Ping for NIB Mode Adapters:" >> $OUTDIR/ethchan.txt
        lsdev -Cc adapter | grep EtherChannel | awk '{print $1}' | while read ETHCH
        do
                ADDRTOP=$(lsattr -El $ETHCH | grep netaddr | awk '{print $2}')
                if [ "$ADDRTOP" = "0" ]
                then
                      echo "$ETHCH : $(lsattr -El $ETHCH | grep netaddr | awk '{print $1" "$2}'): NOK" >> $OUTDIR/ethchan.txt
                      else
                      echo "$ETHCH : $(lsattr -El $ETHCH | grep netaddr | awk '{print $1" "$2}'): OK" >> $OUTDIR/ethchan.txt
                fi
        done
else
        echo "2.NO ETHERCHANNEL ADAPTERS CONFIGURED" >> $OUTDIR/ethchan.txt
fi
if [ "$BKPADPT" = "NONE" ]
then
lsdev -Cc adapter | grep EtherChannel > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        echo "3.EtherChannel Adapter using Link Aggregation:" >> $OUTDIR/ethchan.txt
        lsdev -Cc adapter | grep EtherChannel | awk '{print $1}' | while read ETHCH
        do
                PRIADPT=$(lsattr -El $ETHCH -a adapter_names -F value  | tr -s "," " "  | wc -w)
                if [ "$PRIADPT" -eq "1" ]
                then
                      echo "$ETHCH : $(lsattr -El $ETHCH -a adapter_names -F value  | tr -s "," " " ): NOK" >> $OUTDIR/ethchan.txt
                      else
                      echo "$ETHCH : $(lsattr -El $ETHCH -a adapter_names -F value  | tr -s "," " " ): OK" >> $OUTDIR/ethchan.txt
                fi
        done
else
        echo "3.NO ETHERCHANNEL ADAPTERS CONFIGURED" >> $OUTDIR/ethchan.txt
fi
else
        echo "3.Link Aggregation (LACP) : Etherchannel configured using NIB Mode : OK" >> $OUTDIR/ethchan.txt
fi
else
        echo "Applicable for NonVIO Clients " >> $OUTDIR/ethchan.txt
fi
cat  $OUTDIR/ethchan.txt | grep NOK > /dev/null 2>&1;RC1=$?
cat  $OUTDIR/ethchan.txt | grep -E "CONFIGURED|NonVIO" > /dev/null 2>&1;RC2=$?
if [ $RC1 -eq 0 ]
then
     VALUE="$(cat $OUTDIR/ethchan.txt)"
     violations="Non-Compliant"
     #violations="MANUAL"
elif [ $RC2 -eq 0 ]
then
     VALUE="$(cat $OUTDIR/ethchan.txt)"
     violations="Not-Applicable"
     #violations="MANUAL"
else
     VALUE="$(cat $OUTDIR/ethchan.txt)"
     violations="Compliant"
     #violations="MANUAL"
fi
#VALUE1="<br>2.MANUAL<br>3.MANUAL<br>4.MANUAL<br>5.MANUAL"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile



#A55
DescNo="A55"
DescItem="Adapter speed / duplex mode"
policy_reco="Auto-negotiable"
STDBLD="A"
AUTOCHK="A"
how_to="Adapter Speed:"
lsdev -Cc adapter | grep ^ent | grep "Virtual I/O Ethernet Adapter" | grep Available > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
        lscfg | grep -e "10/100/1000 Base-TX" -e "Ethernet" -e "Logical Host Ethernet Port" | grep -v lhea | awk '{print $2}' | grep ^ent | sort | while read ETHADP 
        do
                NWADPSPD=$(lsattr -El $ETHADP -a media_speed -F value)
                if [ "$NWADPSPD" = "Auto_Negotiation" ]
                then
                        echo "$ETHADP: $(lsattr -El $ETHADP -a media_speed -F value) : OK" >> $OUTDIR/ethspeed.txt
                        else
                        echo "$ETHADP: $(lsattr -El $ETHADP -a media_speed -F value) : NOK" >> $OUTDIR/ethspeed.txt
                fi
        done
else
        echo "No Physical Ethernet Adapter CONFIGURED" >> $OUTDIR/ethspeed.txt
fi
cat  $OUTDIR/ethspeed.txt | grep NOK > /dev/null 2>&1;RC1=$?
cat  $OUTDIR/ethspeed.txt | grep "CONFIGURED" > /dev/null 2>&1;RC2=$?
if [ $RC1 -eq 0 ]
then
     VALUE="$(cat $OUTDIR/ethspeed.txt)"
     violations="Non-Compliant"
elif [ $RC2 -eq 0 ]
then
     VALUE="$(cat $OUTDIR/ethspeed.txt)"
     violations="Not-Applicable"
else
     VALUE="$(cat $OUTDIR/ethspeed.txt)"
     violations="Compliant"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A56
DescNo="A56"
DescItem="maxmbuf"
policy_reco="Maximum kilobytes of real memory allowed for MBUFS.(maxmbuf=0)"
STDBLD="A"
AUTOCHK="A"
how_to="# lsattr -El sys0 -a maxmbuf"
VALUE=$(lsattr -El sys0 -a maxmbuf | cut -d ' ' -f 2)
if [ $VALUE -eq 0 ]
then
    violations="Compliant"
        VALUE=$(lsattr -El sys0 -a maxmbuf | cut -d ' ' -f 2)
    else
    violations="Non-Compliant"
        VALUE=$(lsattr -El sys0 -a maxmbuf | cut -d ' ' -f 2)
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A57
DescNo="A57"
DescItem="MTU"
policy_reco="Limits the size of packets that are transmitted on the network.For the Gigabit Ethernet adapter, use the device attribute jumbo_frames=yes to enable jumbo frames (just setting MTU to 9000 on the interface is not enough)."
STDBLD="A"
AUTOCHK="A"
how_to="# netstat -in"
MTU1400=$(netstat -in | grep ^en | grep -v "*" | awk '{print $1" "$2}' | grep -Ev "1400|9000" | sort -u | wc -l | awk '{print $1}')
if [ $MTU1400 -eq 0 ]
then
      violations="Compliant"
      VALUE="$(netstat -in | grep ^en | awk '{print $1" "$2}' | sort -u)"
       else
       violations="Non-Compliant"
       VALUE="$(netstat -in | grep ^en | awk '{print $1" "$2}' | sort -u)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


########################### ENT RFC VALUE
#A58
DescNo="A58"
DescItem="rfc1323"
policy_reco="Enables TCP enhancements as specified by RFC 1323 (TCP Extensions for High Performance)(rfc1323=1)."
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep rfc1323"
RFC1323=$(no -a | grep rfc1323 | awk -F '=' '{print $2}')
if [ $RFC1323 -eq 0 ]
then
     violations="Non-Compliant"
     VALUE=$(no -a | grep rfc1323 | awk -F '=' '{print $2}')
     else
     violations="Compliant"
     VALUE=$(no -a | grep rfc1323 | awk -F '=' '{print $2}')
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


###########################
#A59
DescNo="A59"
DescItem="tcp_mssdflt"
policy_reco="Default maximum segment size used in communicating with remote networks.(tcp_mssdflt=1360)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep tcp_mssdflt"
VALUE=$(no -a | grep tcp_mssdflt | awk -F '=' '{print $2}')
if [ $VALUE  -eq 1360 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_mssdflt)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_mssdflt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########################
#A60
DescNo="A60"
DescItem="tcp_nodelayack"
policy_reco="Specifies that sockets using TCP over this interface follow the Nagle algorithm when sending data. By default, TCP follows the Nagle algorithm.(tcp_nodelayack=0)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep tcp_nodelayack"
VALUE=$(no -a | grep tcp_nodelayack | awk -F '=' '{print $2}')
if [ $VALUE  -eq 0 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_nodelayack)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_nodelayack)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########################
#A61
DescNo="A61"
DescItem="tcp_recvspace"
policy_reco="Specifies the system default socket buffer size for receiving data. This affects the window size used by TCP.(tcp_recvspace=524288)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep tcp_recvspace"
VALUE=$(no -a | grep tcp_recvspace | awk -F '=' '{print $2}')
if [ $VALUE  -eq 524288 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_recvspace)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_recvspace)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A62
DescNo="A62"
DescItem="tcp_sendspace"
policy_reco="Specifies the system default socket buffer size for sending data.(tcp_sendspace=524288)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep tcp_sendspace"
VALUE=$(no -a | grep tcp_sendspace| awk -F '=' '{print $2}')
if [ $VALUE  -eq 524288 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_sendspace)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_sendspace)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A63
DescNo="A63"
DescItem="udp_recvspace"
policy_reco="Specifies the system default socket buffer size for receiving UDP data.(udp_recvspace=655360)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep udp_recvspace"
VALUE=$(no -a | grep udp_recvspace| awk -F '=' '{print $2}')
if [ $VALUE  -eq 655360 ]
then
    violations="Compliant"
VALUE="$(no -a | grep udp_recvspace)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep udp_recvspace)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A64
DescNo="A64"
DescItem="udp_sendspace"
policy_reco="Specifies the system default socket buffer size (in bytes) for sending UDP data.(udp_sendspace=655360)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep udp_sendspace"
VALUE=$(no -a | grep udp_sendspace| awk -F '=' '{print $2}')
if [ $VALUE  -eq 655360 ]
then
    violations="Compliant"
VALUE="$(no -a | grep udp_sendspace)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep udp_sendspace)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##A65
DescNo="A65"
DescItem="use_sndbufpool"
policy_reco="Enables caching of mbuf clusters to improve performance.(use_sndbufpool=1)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep use_sndbufpool"
VALUE=$(no -a | grep use_sndbufpool | awk -F '=' '{print $2}')
if [ $VALUE -eq 1 ]
then
    violations="Compliant"
VALUE="$(no -a | grep use_sndbufpool)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep use_sndbufpool)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##A66
DescNo="A66"
DescItem="xmt_que_sizei/tx_que_sz"
policy_reco="Specifies the maximum number of send buffers that can be queued up for the Physical interface.(tx_que_sz=[default])"
STDBLD="C"
AUTOCHK="A"
how_to="# lsattr -El entX"
ENTSS=$(lsdev -Cc adapter | grep ^ent | grep -v "Virtual I/O Ethernet Adapter"|wc -l)
if [ $ENTSS -gt 1 ]
then
lsdev -Cc adapter | grep ^ent | grep -v "Virtual I/O Ethernet Adapter" | awk '{print $1}' | while read ENTIS
do
echo "$ENTIS : $(lsattr -El $ENTIS -a tx_que_sz | awk '{print $1" "$2}')" >> $OUTDIR/xntquesz.txt 2>&1
done
VALUE="$(cat $OUTDIR/xntquesz.txt)"
violations="Compliant"
else
VALUE="NO PHYSICAL ETHERNET ADAPTERS FOUND"
violations="Not-Applicable"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##A67
DescNo="A67"
DescItem="thewall"
policy_reco="Specifies the maximum number of send buffers that can be queued up for the interface.(thewall=default)"
STDBLD="C"
AUTOCHK="A"
how_to="# no -a | grep thewall"
VALUE=$(no -a | grep thewall | awk -F '=' '{print $2}')
violations="Compliant"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A68
DescNo="A68"
DescItem="tcp_keepidle"
policy_reco="Specifies the length of time to keep the connection active, measured in half seconds.(tcp_keepidle=600)"
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep tcp_keepidle"
VALUE=$(no -a | grep tcp_keepidle | awk -F '=' '{print $2}')
if [ $VALUE  -eq 600 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_keepidle)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_keepidle)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########################
#A69
DescNo="A69"
DescItem="tcp_keepintvl"
policy_reco="Specifies the interval, which is measured in half seconds, between packets that are sent to validate the connection.(tcp_keepintvl=10)"
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep ipforwarding"
VALUE=$(no -a | grep tcp_keepintvl| awk -F '=' '{print $2}')
if [ $VALUE  -eq 10 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_keepintvl)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_keepintvl)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########################
#A70
DescNo="A70"
DescItem="tcp_keepcnt"
policy_reco="tcp_keepcnt represents the number of keepalive probes that could be sent before terminating the connection.(tcp_keepcnt=8)"
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep tcp_keepcnt"
VALUE=$(no -a | grep tcp_keepcnt |  awk -F '=' '{print $2}')
if [ $VALUE  -eq 8 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_keepcnt)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_keepcnt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


###########################
#A71
DescNo="A71"
DescItem="tcp_keepinit"
policy_reco="
Sets the initial timeout value for a TCP connection, which is measured in half seconds.(tcp_keepinit=40)"
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep tcp_keepinit"
VALUE=$(no -a | grep tcp_keepinit |  awk -F '=' '{print $2}')
if [ $VALUE  -eq 40 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_keepinit)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_keepinit)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########################
#A72
DescNo="A72"
DescItem="sb_max"
policy_reco="Specifies the maximum buffer size that is allowed for a TCP and UDP socket. Limits setsockopt, udp_sendspace, udp_recvspace, tcp_sendspace, and tcp_recvspace.(sb_max=5242880)"
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep  sb_max"
VALUE=$(no -a | grep sb_max |  awk -F '=' '{print $2}')
if [ $VALUE  -eq 5242880 ]
then
    violations="Compliant"
VALUE="$(no -a | grep sb_max)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep sb_max)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########################
#A73
DescNo="A73"
DescItem="tcp_timewait"
policy_reco="The tcp_timewait option is used to configure how long connections are kept in the timewait state."
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep ipforwarding"
VALUE=$(no -a | grep tcp_timewait |  awk -F '=' '{print $2}')
if [ $VALUE  -eq 1 ]
then
    violations="Compliant"
VALUE="$(no -a | grep tcp_timewait)"
  else
    violations="Non-Compliant"
VALUE="$(no -a | grep tcp_timewait)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#################################
#A74
DescNo="A74"
DescItem="MTU Default ODM Value"
policy_reco="Limits the size of packets that are transmitted on the network.For the Gigabit Ethernet adapter, use the device attribute jumbo_frames=yes to enable jumbo frames (just setting MTU to 9000 on the interface is not enough)."
STDBLD="A"
AUTOCHK="A"
how_to="# odmget -q \"uniquetype=if/EN/en AND attribute=mtu\" PdAt"
odmget -q "uniquetype=if/EN/en AND attribute=mtu" PdAt | grep deflt | grep -wv 1400 > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
     violations="Compliant"
     VALUE="ODM Updated to 1400 at ODM level"
     else
     violations="Non-Compliant"
     VALUE="$(odmget -q "uniquetype=if/EN/en AND attribute=mtu" PdAt | grep deflt | grep -wv 1400)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##############

#A75
DescNo="A75"
DescItem="ipqmaxlen"
policy_reco="Specifies the number of received packets that can be queued on the IP protocol input queue.(ipqmaxlen=512)"
STDBLD="A"
AUTOCHK="A"
how_to="# no -a | grep ipqmaxlen"
VALUE=$(no -a | grep ipqmaxlen |  awk -F '=' '{print $2}')
if [ $VALUE  -eq 512 ]
then
     violations="Compliant"
     VALUE="$(no -a | grep ipqmaxlen)"
     else
     violations="Non-Compliant"
     VALUE="$(no -a | grep ipqmaxlen)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################

DrawSecHead "Section B: Standard system software" >> $HTMLLogFile

echo "$(date) : Standard system software Verification "
#B1
DescNo="B1"
DescItem="Infra Softwares"
policy_reco="Ensure that the standard system software are installed."
STDBLD="A"
AUTOCHK="A"
how_to="# lslpp -l <LPP>"
> $OUTDIR/lppinfo.txt
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
lslpp -l | grep -iE "tivoli.tsm|dbsStd.tsm.lanclient" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    echo "<b>TSM</b>:" >> $OUTDIR/lppinfo.out 2>&1
    lslpp -l | grep -iE "dbsStd.tsm.lanclient|tivoli.tsm" | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1 >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
else
    if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
    then
    echo "TSM is not required for DEV and SIT servers"  >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
    then
    echo "TSM is not mandatory for UAT servers" >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
    then
    echo "<b>TSM</b>: NOT INSTALLED " >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    fi
fi
#lslpp -l | grep -wi tripwire > /dev/null 2>&1;RC=$?
ls -ld /opt/tripwire/te/agent > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    #echo "<b>TRIPWIRE</b>:" >> $OUTDIR/lppinfo.out 2>&1
    #lslpp -l | grep -wi tripwire | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1 >> $OUTDIR/lppinfo.out 2>&1
    echo "<b>TRIPWIRE</b>: INSTALLED " >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    else
    if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
    then
    echo "Tripwire is not required for DEV and SIT servers"  >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    else
    echo "<b>TRIPWIRE</b>: NOT INSTALLED " >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    fi
fi
lslpp -l | grep -Ei "dbsStd.tad4d.agent|tad4d" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    echo "<b>TAD4D</b>:" >> $OUTDIR/lppinfo.out 2>&1
    lslpp -l | grep -iE "dbsStd.tad4d.agent|tad4d" | tr -s ' ' | awk '{print $1" "$2" "$3}' | head -n 1 >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    else
    echo "<b>TAD4D</b>: NOT INSTALLED " >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
fi
lslpp -l | grep -E "SSHTectia.Client|WRQ.RSIT.Server|F-Secure.SSH.Server|RSIT.ssh.Server|dbsStd.SSHTectia.server"  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    echo "<b>SSH-TECTIA</b>:" >> $OUTDIR/lppinfo.out 2>&1
    lslpp -l | grep -Ei "SSHTectia.Client|WRQ.RSIT.Server|F-Secure.SSH.Server|RSIT.ssh.Server|dbsStd.SSHTectia.server" | head -n 1 >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    else
    echo "<b>SSH-TECTIA</b>: NOT INSTALLED" >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
fi
#
if ([ -d /IBM/itm/bin ] || [ -d /opt/IBM/ITM ])
then
    echo "<b>ITM</b>: INSTALLED  " >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
else
    if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
    then
    echo "ITM is not required for DEV and SIT servers"  >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
    then
    echo "ITM is not mandatory for UAT servers"  >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
    then
    echo "<b>ITM</b>: NOT INSTALLED" >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    fi
fi
if [ -d /UnixPatchAgent/patchagent ]
then
    echo "<b>LUMENSION</b>: INSTALLED " >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    else
    echo "<b>LUMENSION</b>: NOT INSTALLED" >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
fi
if ([ -d /opt/Symantec/scspagent/IDS/bin/ -a -d /opt/Symantec/scspagent/IPS/bin/ ] || [ -d /opt/Symantec/sdcssagent/IDS/bin -a -d /opt/Symantec/sdcssagent/IPS/bin ])
then
    echo "<b>SCSP/SDCS</b>: INSTALLED " >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
else
    HOSTS=`hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]'` > /dev/null 2>&1	
    if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
    then
    echo "SCSP/SDCS is not required for DEV and SIT servers"  >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    elif [ "$HOSTS" = "a03s" ]
    then
    echo "SCSP/SDCS is not mandatory for UAT servers in HK"  >> $OUTDIR/lppinfo.out 2>&1
    else
    echo "<b>SCSP/SDCS</b>: NOT INSTALLED" >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    fi
fi
lslpp -l | grep -i "lsof.base"  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    echo "<b>LSOF</b>:" >> $OUTDIR/lppinfo.out 2>&1
    lslpp -l | grep -i "lsof.base" | head -n 1 >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    else
    echo "<b>LSOF</b>: NOT INSTALLED" >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
fi
lslpp -l | grep -i "bos.adt.debug"  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    echo "<b>DEBUG Tools</b>:" >> $OUTDIR/lppinfo.out 2>&1
    lslpp -l | grep -i "bos.adt.debug" | head -n 1 >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
    else
    echo "<b>DEBUG Tools</b>: NOT INSTALLED" >> $OUTDIR/lppinfo.out 2>&1
    echo >> $OUTDIR/lppinfo.out 2>&1
fi
cat $OUTDIR/lppinfo.out | grep "NOT INSTALLED" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        violations="Non-Compliant"
        VALUE="$(cat $OUTDIR/lppinfo.out)"
        else
        violations="Compliant"
        VALUE="$(cat $OUTDIR/lppinfo.out)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#B2
DescNo="B2"
DescItem="Startup/Shutdown Scripts"
policy_reco="Ensure startup and stop scripts enabled"
STDBLD="A"
AUTOCHK="A"
how_to="# ls -lrt /etc/rc.startup /etc/rc.shutdown"
>$OUTDIR/startshut.txt
if [ -f /etc/rc.startup -a -s /etc/rc.startup ]
then
   echo "/etc/rc.startup : EXIST_AND_NON_ZERO " >> $OUTDIR/startshut.txt
   STARTUP=OK
   else
   echo "/etc/rc.startup : DOES_NOT_EXIST_OR_ZERO " >> $OUTDIR/startshut.txt
   STARTUP=NOK
fi
if [ -f /etc/rc.shutdown -a -s /etc/rc.startup ]
then
   echo "/etc/rc.shutdown : EXIST_AND_NON_ZERO " >> $OUTDIR/startshut.txt
   STOPUP=OK
   else
   echo "/etc/rc.shutdown : DOES_NOT_EXIST_OR_ZERO " >> $OUTDIR/startshut.txt
   STOPUP=NOK
fi
cat $OUTDIR/startshut.txt | grep NOT > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        violations="Non-Compliant"
        VALUE="$(cat $OUTDIR/startshut.txt)"
        else
        violations="Compliant"
        VALUE="$(cat $OUTDIR/startshut.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

export STARTUP STOPUP

#####
DrawSubHead "1. ISCD - Hardware monitoring"  >>$HTMLLogFile

#B3
DescNo="B3"
DescItem="AIX ISCD"
policy_reco="Harden the server according to T&O-TS-ISS AIX Hardening Checklist published on http://dbsnet.dbs.com.sg/to/grouptechnologyservices/html/ref.html"
STDBLD="A"
AUTOCHK="A"
how_to="# aix_im_iscd.sh"
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
then
        VALUE="ISCD is not required for Development and SIT servers"
        violations="Not-Applicable"
else
        violations="Not-Applicable"
        VALUE="Automated Using Tripwire"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


##################

DrawSubHead "2. Tectia SSH - Shell access / file transfer"  >>$HTMLLogFile

#B4
DescNo="B4"
DescItem="SSH Service Startup/Shutdown"
policy_reco="Ensure that Tectia SSH has a rc startup/shutdown script"
STDBLD="A"
AUTOCHK="A"
#how_to="# cat /etc/rc.startup & cat /etc/rc.shutdown"
how_to="# cat /etc/inittab"
cat /etc/inittab | grep -i ^ssh  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
                        violations="Compliant"
                        VALUE="$(cat /etc/inittab | grep -i ^ssh)"
                        else
                        violations="Non-Compliant"
                        VALUE="SSH AutoStart_DOES_NOT_EXIST"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

########
#B5
DescNo="B5"
DescItem="SSH Binary Location"
policy_reco="Ensure that Tectia SSH files are placed in rootvg volume group"
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l rootvg"
for i in SSHTectia.Client WRQ.RSIT.Server openssh.base.server F-Secure.SSH.Server RSIT.ssh.Server dbsStd.SSHTectia.server
do
lslpp -L $i >/dev/null 2>&1 && SSHVER=$(lslpp -L $i|grep $i|grep -v grep|tr -s " "|cut -d" " -f3)
 if [ $? -eq 0 ]
  then
        case $i in
                SSHTectia.Client)
                                SSHSW="Tectia"
                                ;;
                WRQ.RSIT.Server|RSIT.ssh.Server|F-Secure.SSH.Server)
                                SSHSW="F-Secure"
                                ;;
                openssh.base.server)
                                SSHSW="OpenSSH"
                                ;;
                dbsStd.SSHTectia.server)
                                SSHSW="Tectia"
                                ;;
        esac
 fi
done
if [ $SSHSW = "Tectia" ] ; then
df -g /opt/tectia/libexec/ssh-servant-g3 | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS="$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}')" >/dev/null 2>&1
if [ "$VGIS" = "rootvg" ]
then
 violations="Compliant"
 VALUE="SSH_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /opt/tectia/libexec/ssh-servant-g3 | grep -v Filesystem | awk '{print $7}')"
 else
 violations="Non-Compliant"
 VALUE="SSH_BINARY_LOCATION_IS_NONROOTVG<br><br><br>$(df -g /opt/tectia/libexec/ssh-servant-g3 | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="SSH Tectia is not installed in the server"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##################
DrawSubHead "3. ITM - Server monitoring" >>$HTMLLogFile

#B6
DescNo="B6"
DescItem="ITM Service Startup/Shutdown"
policy_reco="Ensure that ITM has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup & cat /etc/rc.shutdown"
if ([ -d /IBM/itm/bin ] || [ -d /opt/IBM/ITM ])
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.itm" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.itm" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.itm -a -s /etc/rc.itm ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.itm)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.itm DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.itm NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="ITM not Installed. Development or SIT Server"
elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
        then
        violations="Not-Applicable"
        VALUE="ITM not Installed. Not mandatory for UAT Servers"
elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
        then
        violations="Non-Compliant"
        VALUE="ITM not Installed"
fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########
#B7
DescNo="B7"
DescItem="ITM Binary Location"
policy_reco="Ensure that ITM files are placed in sysvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l sysvg"
#if [ -d /IBM/itm/bin ]
if [ -d /IBM/itm/bin -o -d /opt/IBM/ITM/bin ]
then
#       df -g | grep /IBM/itm | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
        df -g | grep -E "\/IBM\/itm|\/opt\/IBM\/ITM" | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
        if [ ! -z "$LVIS" ]
        then
        VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
                if [ "$VGIS" = "rootvg" ]
                then
                        if [ `lspv| grep -cw rootvg` -lt 2 ]
                        then
                        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
                        RDISKSIZE=$(bootinfo -s $RDISK)
                        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
                                if [ $RC -eq 0 ]
                                then
                                        if [ $RDISKSIZE -eq 102400 ]
                                        then
                                        violations="Compliant"
                                        VALUE="ITM_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and 100GB size. No Sysvg<br><br><br>$(df -g | grep -E "\/IBM\/itm|\/opt\/IBM\/ITM" | grep -v Filesystem | awk '{print $7}')"
                                        else
                                        violations="Non-Compliant"
                                        VALUE="ITM_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and less than 100GB size.<br><br><br>$(df -g | grep -E "\/IBM\/itm|\/opt\/IBM\/ITM" | grep -v Filesystem | awk '{print $7}')"
                                        fi
                                else
                                        violations="Non-Compliant"
                                        VALUE="ITM_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is Not SAN Disk.<br><br><br>$(df -g | grep -E "\/IBM\/itm|\/opt\/IBM\/ITM"  | grep -v Filesystem | awk '{print $7}')"
                                fi
                        else
				lspv | grep sysvg > /dev/null 2>&1;RC1=$?
				if [ $RC1 -eq 0 ] ; then
                                violations="Non-Compliant"
                                VALUE="ITM_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g | grep -E "\/IBM\/itm|\/opt\/IBM\/ITM"  | grep -v Filesystem |  awk '{print $7}')"
				else
				violations="Compliant"
				VALUE="ITM_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g | grep -E "\/IBM\/itm|\/opt\/IBM\/ITM"  | grep -v Filesystem |  awk '{print $7}')"
				fi
                        fi
                else
                violations="Compliant"
                VALUE="ITM_BINARY_LOCATION_IS_IN_NONROOTVG<br><br><br>$(df -g | grep -E "\/IBM\/itm|\/opt\/IBM\/ITM" | grep -v Filesystem | awk '{print $7}')"
                fi
        else
                violations="Non-Compliant"
                VALUE="ITM_BINARY_LOCATION_FileSystem_NOTFOUND...."
        fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="ITM not Installed. Development or SIT Server"
        elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
        then
        violations="Not-Applicable"
        VALUE="ITM not Installed. Not mandatory for UAT Servers"
        elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
        then
        violations="Non-Compliant"
        VALUE="ITM not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#####
DrawSubHead "4. TSM - Backup " >>$HTMLLogFile

#B8
DescNo="B8"
DescItem="TSM Service Startup/Shutdown"
policy_reco="Ensure that TSM has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup && cat /etc/rc.shutdown "
lslpp -l | grep -iE "tivoli.tsm|dbsStd.tsm.lanclient" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.tsm" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.tsm" > /dev/null 2>&1;RC2=$?
        ((RC3=$RC1+$RC2))
        if [ $RC3 -eq 0 ]
        then
                        if [ -f /etc/rc.tsm -a -s /etc/rc.tsm ]
                        then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.tsm)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.tsm DOES_NOT_EXIST"
                        fi
        else
        violations="Non-Compliant"
        VALUE="/etc/rc.tsm NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="TSM not Installed. Development or SIT Server"
        elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
        then
        violations="Not-Applicable"
        VALUE="TSM not Installed. Not mandatory for UAT Servers"
        elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
        then
        violations="Non-Compliant"
        VALUE="TSM not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#B9
DescNo="B9"
DescItem="TSM Binary Location"
policy_reco="Ensure that TSM files are placed in rootvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l rootvg"
lslpp -l | grep -iE "tivoli.tsm|dbsStd.tsm.lanclient" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
if [ -d /usr/tivoli/tsm ]
then
        df -g /usr/tivoli/tsm | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
        VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
        if [ "$VGIS" = "rootvg" ]
        then
                violations="Compliant"
                VALUE="TSM_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /usr/tivoli/tsm | grep -v Filesystem | awk '{print $7}')"
                else
                violations="Non-Compliant"
                VALUE="TSM_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /usr/tivoli/tsm | grep -v Filesystem | awk '{print $7}')"
        fi
else
                violations="Non-Compliant"
                VALUE="TSM_BINARY_LOCATION_NOT_FOUND<br><br><br>"
fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="TSM not Installed. Development or SIT Server"
        elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
        then
        violations="Not-Applicable"
        VALUE="TSM not Installed. Not mandatory for UAT Servers"
        elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
        then
        violations="Non-Compliant"
        VALUE="TSM not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

####B10
DescNo="B10"
DescItem="TSM Backup VLAN"
policy_reco="Ensure that TSM uses dedicated backup VLAN instead of public VLAN. Not Applicable to DMZ and Extranet Servers."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /usr/tivoli/tsm/client/ba/bin64/dsm.sys"
lslpp -l | grep -iE "tivoli.tsm|dbsStd.tsm.lanclient" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
if [ -d /usr/tivoli/tsm/client/ba/ ]
then
        find /usr/tivoli/tsm/client/ba/bin64/ -name dsm.sys > $OUTDIR/tsmdsmsys.txt 2>&1
        if [ -s $OUTDIR/tsmdsmsys.txt ]
        then
		cat `cat $OUTDIR/tsmdsmsys.txt` | grep -iw  "TCPclientaddress" | awk '{print $2}' | grep -E "10|192" | head -1 > /dev/null 2>&1;RC3=$?
		if [ $RC3 -eq 0 ] ; then
		cat `cat  $OUTDIR/tsmdsmsys.txt` | grep -iw  "TCPclientaddress" | awk '{print $2}' | head -1 > $OUTDIR/tsmclientip.txt 2>&1
		else
		TSMHN=`cat $OUTDIR/tsmdsmsys.txt` | grep -iw  "TCPclientaddress" | awk '{print $2}' | head -1
		nslookup $TSMHN | tail -2 | grep Address | cut -f2 -d":" -d " " > $OUTDIR/tsmclientip.txt 2>&1
		fi
                SERVERIP=$(prtconf  |grep "IP Address"|awk '{print $3}'| cut -f1-3 -d ".")
                cat $OUTDIR/tsmclientip.txt | grep "$SERVERIP" > /dev/null 2>&1;RC1=$?
                        if [ $RC1 -eq 0 ]
                        then
                        violations="Compliant"
                        VALUE="TSM Configured using Public IP<br><br>$(cat $OUTDIR/tsmclientip.txt)"
                        else
                        violations="Compliant"
                        VALUE="TSM Configured using Backup IP<br><br>$(cat $OUTDIR/tsmclientip.txt)"
                        fi
        else
                VALUE="dsm.sys FILE_NOT_FOUND"
                violations="Non-Compliant"
        fi
else
        VALUE="TSM Installation PATH_NOT_FOUND"
        violations="Non-Compliant"
fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="TSM not Installed. Development or SIT Server"
        elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
        then
        violations="Not-Applicable"
        VALUE="TSM not Installed. Not mandatory for UAT Servers"
        elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
        then
        violations="Non-Compliant"
        VALUE="TSM not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########
DrawSubHead "5. NIM - OS Backup"  >>$HTMLLogFile

#B11
DescNo="B11"
DescItem="NIM Server/Client Configuration"
policy_reco="Ensure that NIM client is configured to its respective NIM server in the particular security zone."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/niminfo"
if [ -f /etc/niminfo -a -s /etc/niminfo ]
then
    VALUE="$(cat /etc/niminfo)"
    violations="Compliant"
    else
    VALUE="/etc/niminfo NOT FOUND or ZERO"
    violations="Non-Compliant"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


##################
DrawSubHead "6. TAD4d - Asset discovery"  >>$HTMLLogFile
#B12
DescNo="B12"
DescItem="TAD4d Startup/Shutdown"
policy_reco="Ensure that TAD4d has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup && cat /etc/rc.shutdown"
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.Tad4D" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.Tad4D" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                ls -l /etc/ | grep -i rc.tad4d >/dev/null 2>&1;RC3=$?
                RC4="$(ls -lrt /etc/ | grep -i rc.tad4d | awk '{ print $5}' | tail -1)"
                if ([ $RC3 -eq 0 ] && [ $RC4 -ne 0 ])
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/ | grep -i rc.tad4d | tail -1)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.Tad4D DOES_NOT_EXIST"
                fi
          else
                violations="Non-Compliant"
                VALUE="/etc/rc.Tad4D NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# B13
DescNo="B13"
DescItem="T4Dd Binary Location"
policy_reco="Ensure that TAD4d files are placed in sysvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l sysvg"
if [ -d /opt/itlm ]
then
df -g /opt/itlm | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
                        if [ `lspv| grep -cw rootvg` -lt 2 ]
                        then
                        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
                        RDISKSIZE=$(bootinfo -s $RDISK)
                        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
                                if [ $RC -eq 0 ]
                                then
                                        if [ $RDISKSIZE -eq 102400 ]
                                        then
                                        violations="Compliant"
                                        VALUE="TAD4D_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and 100GB size. No Sysvg<br><br><br>$(df -g /opt/itlm | grep -v Filesystem | awk '{print $7}')"
                                        else
                                        violations="Non-Compliant"
                                        VALUE="TAD4D_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and less than 100GB size.<br><br><br>$(df -g /opt/itlm  | grep -v Filesystem | awk '{print $7}')"
                                        fi
                                else
                                        violations="Non-Compliant"
                                        VALUE="TAD4D_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is Not SAN Disk.<br><br><br>$(df -g /opt/itlm  | grep -v Filesystem | awk '{print $7}')"
                                fi
                        else
				lspv | grep sysvg > /dev/null 2>&1;RC1=$?
				if [ $RC1 -eq 0 ] ; then
                                violations="Non-Compliant"
                                VALUE="TAD4D_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /opt/itlm  | grep -v Filesystem |  awk '{print $7}')"
				else
				violations="Compliant"
				VALUE="TAD4D_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /opt/itlm  | grep -v Filesystem |  awk '{print $7}')"
				fi
                        fi
                else
                violations="Compliant"
                VALUE="TAD4D_BINARY_LOCATION_IS_IN_NONROOTVG<br><br><br>$(df -g /opt/itlm | grep -v Filesystem | awk '{print $7}')"
                fi
        else
                violations="Non-Compliant"
                VALUE="TAD4D_BINARY_LOCATION_FileSystem_NOTFOUND...."
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##################

DrawSubHead "7. Lumension Patchlink - Patch management"  >>$HTMLLogFile
#B14
DescNo="B14"
DescItem="LUMENSION Startup/Shutdown"
policy_reco="Ensure that LUMENSION has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup & cat /etc/rc.shutdown"
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.UPA" > /dev/null 2>&1;RC1=$?
       cat /etc/rc.shutdown  | grep -i "/etc/rc.UPA" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.UPA -a -s /etc/rc.UPA ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.UPA)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.UPA DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.UPA NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

############
#B15
DescNo="B15"
DescItem="LUMENSION Binary Location"
policy_reco="Ensure that Lumension Patchlink files are placed in sysvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l sysvg"
df -g /UnixPatchAgent/patchagent | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ "$VGIS" = "rootvg" ]
then
                        if [ `lspv| grep -cw rootvg` -lt 2 ]
                        then
                        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
                        RDISKSIZE=$(bootinfo -s $RDISK)
                        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
                                if [ $RC -eq 0 ]
                                then
                                        if [ $RDISKSIZE -eq 102400 ]
                                        then
                                        violations="Compliant"
                                        VALUE="Lumension_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and 100GB size. No Sysvg<br><br><br>$(df -g /UnixPatchAgent/patchagent  | grep -v Filesystem | awk '{print $7}')"
                                        else
                                        violations="Non-Compliant"
                                        VALUE="Lumension_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and less than 100GB size.<br><br><br>$(df -g /UnixPatchAgent/patchagent  | grep -v Filesystem | awk '{print $7}')"
                                        fi
                                else
                                        violations="Non-Compliant"
                                        VALUE="Lumension_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is Not SAN Disk.<br><br><br>$(df -g /UnixPatchAgent/patchagent  | grep -v Filesystem | awk '{print $7}')"
                                fi
                        else
				lspv | grep sysvg > /dev/null 2>&1;RC1=$?
				if [ $RC1 -eq 0 ] ; then
                                violations="Non-Compliant"
                                VALUE="Lumension_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /UnixPatchAgent/patchagent  | grep -v Filesystem |  awk '{print $7}')"
				else
				violations="Compliant"
				VALUE="Lumension_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /UnixPatchAgent/patchagent  | grep -v Filesystem |  awk '{print $7}')"
				fi
                        fi
else
                violations="Compliant"
                VALUE="Lumension_BINARY_LOCATION_IS_IN_NONROOTVG<br><br><br>$(df -g /UnixPatchAgent/patchagent | grep -v Filesystem | awk '{print $7}')"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

######################

DrawSubHead "8. SCSP/SDCS - Intrusion detection"  >>$HTMLLogFile
#B16
DescNo="B16"
DescItem="SCSP/SDCS Service Startup"
policy_reco="Ensure that SCSP/SDCS has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup && cat /etc/rc.shutdown"
if ([ -d /opt/Symantec/scspagent/ ] || [ -d /opt/Symantec/sdcssagent/ ])
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.scsp" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.scsp" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.scsp -a -s /etc/rc.scsp ]
                then

                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.scsp)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.scsp DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.scsp NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
HOSTS=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="SCSP not Installed. Development or SIT Server"
	elif [ "$HOSTS" = "a03s" ] ; then
	violations="Not-Applicable"
	VALUE="SCSP not Installed.Not Mandatory for HK UAT servers "
        else
        violations="Non-Compliant"
        VALUE="SCSP not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########
#B17
DescNo="B17"
DescItem="SCSP Binary Location"
policy_reco="Ensure that SCSP files are placed in sysvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l sysvg"
if ([ -d /opt/Symantec/scspagent/ ] || [ -d /opt/Symantec/sdcssagent/ ])
then
df -g /opt/Symantec/scspagent/ | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS1 >/dev/null 2>&1
VGIS1=$(lslv $LVIS1 | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
df -g /opt/Symantec/sdcssagent/ | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS2 >/dev/null 2>&1
VGIS2=$(lslv $LVIS2 | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if ([ $VGIS1 = "rootvg" ] || [ $VGIS2 = "rootvg" ])
then
                        if [ `lspv| grep -cw rootvg` -lt 2 ]
                        then
                        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
                        RDISKSIZE=$(bootinfo -s $RDISK)
                        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
                                if [ $RC -eq 0 ]
                                then
                                        if [ $RDISKSIZE -eq 102400 ]
                                        then
                                        violations="Compliant"
                                        VALUE="SCSP_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and 100GB size. No Sysvg<br><br><br>$(df -g /opt/Symantec/scspagent/ | grep -v Filesystem | awk '{print $7}')"
                                        else
                                        violations="Non-Compliant"
                                        VALUE="SCSP_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and less than 100GB size.<br><br><br>$(df -g /opt/Symantec/scspagent/  | grep -v Filesystem | awk '{print $7}')"
                                        fi
                                else
                                        violations="Non-Compliant"
                                        VALUE="SCSP_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is Not SAN Disk.<br><br><br>$(df -g /opt/Symantec/scspagent/  | grep -v Filesystem | awk '{print $7}')"
                                fi
                        else
				lspv | grep sysvg > /dev/null 2>&1;RC1=$?
				if [ $RC1 -eq 0 ] ; then
                                violations="Non-Compliant"
                                VALUE="SCSP_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /opt/Symantec/scspagent/  | grep -v Filesystem |  awk '{print $7}')"
				else
				violations="Compliant"
				VALUE="SCSP_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /opt/Symantec/scspagent/  | grep -v Filesystem |  awk '{print $7}')"
				fi
                        fi
                else
                violations="Compliant"
                VALUE="SCSP_BINARY_LOCATION_IS_IN_NONROOTVG<br><br><br>$(df -g /opt/Symantec/scspagent/ | grep -v Filesystem | awk '{print $7}')"
                fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
HOSTS=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="SCSP not Installed. Development or SIT Server"
        elif [ "$HOSTS" = "a03s" ] ; then
        violations="Not-Applicable"
        VALUE="SCSP not Installed.Not Mandatory for HK UAT servers "
        else
        violations="Non-Compliant"
        VALUE="SCSP not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


##############################
DrawSubHead "9. Tripwire Enterprise - Compliance check"  >>$HTMLLogFile
#B18
DescNo="B18"
DescItem="TRIPWIRE Service Startup"
policy_reco="Ensure that Tripwire Enterprise has a rc startup/shutdown script. Tripwire will not be installed in DMZ and Extranet Servers."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup && cat /etc/rc.shutdown"
ls -ld /opt/tripwire/ > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.tripwire" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.tripwire" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.tripwire -a -s /etc/rc.tripwire ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.tripwire)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.tripwire DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.tripwire NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="Tripwire not Installed. Development or SIT Server"
        else
        violations="Non-Compliant"
        VALUE="Tripwire not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#####################
#B19
DescNo="B19"
DescItem="TRIPWIRE Binary Location"
policy_reco="Ensure that Tripwire Enterprise files are placed in sysvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l sysvg"
if [ -d /opt/tripwire/ ]
then
df -g /opt/tripwire/ | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
                        if [ `lspv| grep -cw rootvg` -lt 2 ]
                        then
                        RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
                        RDISKSIZE=$(bootinfo -s $RDISK)
                        lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
                                if [ $RC -eq 0 ]
                                then
                                        if [ $RDISKSIZE -eq 102400 ]
                                        then
                                        violations="Compliant"
                                        VALUE="Tripwire_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and 100GB size. No Sysvg<br><br><br>$(df -g /opt/tripwire/ | grep -v Filesystem | awk '{print $7}')"
                                        else
                                        violations="Non-Compliant"
                                        VALUE="Tripwire_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and less than 100GB size.<br><br><br>$(df -g /opt/tripwire/ | grep -v Filesystem | awk '{print $7}')"
                                        fi
                                else
                                        violations="Non-Compliant"
                                        VALUE="Tripwire_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is Not SAN Disk.<br><br><br>$(df -g /opt/tripwire/  | grep -v Filesystem | awk '{print $7}')"
                                fi
                        else
				lspv | grep sysvg > /dev/null 2>&1;RC1=$?
				if [ $RC1 -eq 0 ] ; then
                                violations="Non-Compliant"
                                VALUE="Tripwire_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /opt/tripwire/  | grep -v Filesystem |  awk '{print $7}')"
				else
				violations="Compliant"
				VALUE="Tripwire_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g /opt/tripwire/  | grep -v Filesystem |  awk '{print $7}')"
				fi
                        fi
                else
                violations="Compliant"
                VALUE="Tripwire_BINARY_LOCATION_IS_IN_NONROOTVG<br><br><br>$(df -g /opt/tripwire/ | grep -v Filesystem | awk '{print $7}')"
                fi
else
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="Tripwire not Installed. Development or SIT Server"
        else
        violations="Non-Compliant"
        VALUE="Tripwire not Installed"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

################
DrawSecHead "Section C: Optional system software" >> $HTMLLogFile

echo "$(date) : Optional system software Verification "

DrawSubHead "1. TWS (This following steps are applicable only when TWS is installed)"  >>$HTMLLogFile
#C1
DescNo="C1"
DescItem="TWS Service Startup"
policy_reco="Ensure that TWS has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup & cat /etc/rc.shutdown"
ps -u maestro  > /dev/null 2>&1;RC1=$?
ps -u twsadmin > /dev/null 2>&1;RC2=$?
ps -u twsadm2 > /dev/null 2>&1;RC3=$?
if ([ $RC1 -eq 0 ] || [ $RC2 -eq 0 ]  || [ $RC3 -eq 0 ])
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.tws" > /dev/null 2>&1;RC3=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.tws" > /dev/null 2>&1;RC4=$?
        ((RC=$RC3+$RC4))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.tws* -a -s /etc/rc.tws* ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.tws*)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.tws DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.tws NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
  violations="Not-Applicable"
  VALUE="TWS NOT INSTALLED"
  VALIS="NOTWS"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#C2
DescNo="C2"
DescItem="TWS Binary Location"
policy_reco="Ensure that TWS files are placed in sysvg volume group"
STDBLD="A"
AUTOCHK="A"
if [ "$VALIS" != "NOTWS" ]
then
df -g | grep "/opt/maestro" | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS1 >/dev/null 2>&1
VGIS1=$(lslv $LVIS1 | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
df -g | grep "/opt/IBM/TWA" | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS2 >/dev/null 2>&1
VGIS2=$(lslv $LVIS2 | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
        if ([ $VGIS1 = "rootvg" ] || [ $VGIS2 = "rootvg" ])
        then
                if [ `lspv| grep -cw rootvg` -lt 2 ]
                then
                RDISK=$(lspv|grep -w rootvg|cut -d" " -f1)
                RDISKSIZE=$(bootinfo -s $RDISK)
                lsdev -Cc disk|grep -w $RDISK|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
                        if [ $RC -eq 0 ]
                        then
                                if [ $RDISKSIZE -eq 102400 ]
                                then
                                violations="Compliant"
                                VALUE="TWS_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and 100GB size. No Sysvg<br><br><br>$(df -g | grep -E "/opt/maestro|/opt/IBM/TWA" | grep -v Filesystem | awk '{print $7}')"
                                else
                                VALUE="TWS_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is SAN Disk and less than 100GB size.<br><br><br>$( df -g | grep -E "/opt/maestro|/opt/IBM/TWA" | grep -v Filesystem | awk '{print $7}')"
                                fi
                        else
                                violations="Non-Compliant"
                                VALUE="TWS_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg is Not SAN Disk.<br><br><br>$(df -g | grep -E "/opt/maestro|/opt/IBM/TWA"  | grep -v Filesystem | awk '{print $7}')"
                        fi
                else
                        violations="Non-Compliant"
                        VALUE="TWS_BINARY_LOCATION_IS_IN_ROOTVG and Rootvg has more than 1 Disk.<br><br><br>$(df -g | grep -E "/opt/maestro|/opt/IBM/TWA" | grep -v Filesystem |  awk '{print $7}')"
                fi
        else
        violations="Compliant"
        VALUE="TWS_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g | grep -E "/opt/maestro|/opt/IBM/TWA" | grep -v Filesystem | awk '{print $7}')"
        fi
else
  violations="Not-Applicable"
  VALUE="TWS NOT INSTALLED"
fi
how_to="# lsvg -l $VGIS"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


##################
DrawSubHead "2. GPFS (This following steps are applicable only when GPFS is installed)"  >>$HTMLLogFile
#C3
DescNo="C3"
DescItem="GPFS Startup/Stop Scripts"
policy_reco="Ensure that GPFS has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# GPFS Cluster Startup/Stop"
lslpp -l gpfs.base > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.gpfs" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.gpfs" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.gpfs -a -s /etc/rc.gpfs ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.gpfs)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.gpfs DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.gpfs NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
VALUE="NO GPFS FOUND"
violations="Not-Applicable"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

######
#C4
DescNo="C4"
DescItem="GPFS Binary Location"
policy_reco="Ensure that GPFS files are placed in rootvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l rootvg"
lslpp -l gpfs.base > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
df -g /usr/lpp/mmfs | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
 violations="Compliant"
 VALUE="GPFS_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /usr/lpp/mmfs  | grep -v Filesystem | awk '{print $7}')"
 else
 violations="Non-Compliant"
 VALUE="GPFS_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /usr/lpp/mmfs | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="NO_GPFS_FILESET_FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##################
DrawSubHead "3. PowerHA (This following steps are applicable only when PowerHA is installed)"  >>$HTMLLogFile
#C5
DescNo="C5"
DescItem="PowerHA Start/Stop Scripts"
policy_reco="Ensure that PowerHA has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# lssrc -g cluster"
lslpp -l cluster.es.server.rte > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
violations="Not-Applicable"
VALUE="HACMP Installed, No Auto Start for HACMP Cluster"
violations="Not-Applicable"
else
VALUE="No HACMP Installed"
violations="Not-Applicable"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#C6
DescNo="C6"
DescItem="PowerHA Binary Location"
policy_reco="Ensure that PowerHA files are placed in rootvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l rootvg"
lslpp -l cluster.es.server.rte > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
df -g /usr/es/sbin/cluster/utilities | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
violations="Compliant"
 VALUE="HACMP_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /usr/es/sbin/cluster/utilities  | grep -v Filesystem | awk '{print $7}')"
 else
 violations="Non-Compliant"
 VALUE="HACMP_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /usr/es/sbin/cluster/utilities | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="NO_HACMP_FILESET_FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


DrawSubHead "4. VCS (This following steps are applicable only when VCS is installed)"  >>$HTMLLogFile
#C7
DescNo="C7"
DescItem="VCS Start/Stop Scripts"
policy_reco="Ensure that VCS has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="Veritas Start/Stop "
lslpp -l VRTSvcs > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        Violations="Not-Applicable"
        VALUE="Veritas Installed, No Auto Start for Veritas Cluster"
else
        violations="Not-Applicable"
        VALUE="No Veritas Cluster Installed"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#C8
DescNo="C8"
DescItem="VCS Binary Location"
policy_reco="Ensure that VCS files are placed in rootvg volume group."
STDBLD="A"
AUTOCHK="A"
how_to="# lsvg -l rootvg"
lslpp -l VRTSvcs > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
df -g /opt/VRTSvcs/bin | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
violations="Compliant"
 VALUE="VCS_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /opt/VRTSvcs/bin  | grep -v Filesystem | awk '{print $7}')"
 else
violations="Non-Compliant"
 VALUE="VCS_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /opt/VRTSvcs/bin | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="NO_VCS_FILESET_FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#C9
DescNo="C9"
DescItem="VCS HA FAILOVER"
policy_reco="Ensure that VCS HA test is carried out to validate the HA setup."
STDBLD="A"
AUTOCHK="A"
how_to="HA Failover test"
lslpp -l VRTSvcs > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        Violations="Not-Applicable"
        VALUE="Veritas Installed,HA Failover test was carried out during the initial setup. See 'VCS HA Test' sheet."
else
        violations="Not-Applicable"
        VALUE="No Veritas Cluster Installed"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#####################################
DrawSecHead "Section D: Optional middleware" >> $HTMLLogFile

echo "$(date) : Optional middleware Verification "

DrawSubHead "1. MQ (This following steps are applicable only when MQ is installed)"  >>$HTMLLogFile

#D1
DescNo="D1"
DescItem="MQ Start/Stop Scritps"
policy_reco="Ensure that MQ has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup & /etc/rc.shutdown"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [ "$HostHADR" != "b" ])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
lslpp -l | grep mqm.base.runtime > /dev/null 2>&1;RC3=$?
dspmq > /dev/null 2>&1;RC4=$?
if ([ $RC3 -eq 0 ] && [ $RC4 -eq 0 ])
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.mq" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.mq" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.mq.all -a -s /etc/rc.mq.all ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.mq)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.mq.all DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.mq.all NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="NO_MQ_SERVER_FILESET_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#D2
DescNo="D2"
DescItem="MQ Binary location"
policy_reco="Ensure that MQ files are placed in appvg volume group."
AUTOCHK="A"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [ "$HostHADR" != "b" ])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
lslpp -l | grep mqm.base.runtime > /dev/null 2>&1;RC=$?
dspmq > /dev/null 2>&1;RC4=$?
if ([ $RC -eq 0 ] && [ $RC4 -eq 0 ])
then
df -g /var/mqm | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
 violations="Non-Compliant"
 VALUE="MQ_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /var/mqm  | grep -v Filesystem | awk '{print $7}')"
 else
 violations="Compliant"
 VALUE="MQ_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /var/mqm | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="NO_MQ_SERVER_FILESET_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
how_to="#lsvg -l $VGIS"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###############################
DrawSubHead "2. WAS (This following steps are applicable only when WAS is installed)"  >>$HTMLLogFile
#D3
DescNo="D3"
DescItem="WAS Start/Stop Scripts"
policy_reco="Ensure WAS has rc StartupShutdown scripts"
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup & cat /etc/rc.shutdown"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [ "$HostHADR" != "b" ])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
/usr/bin/df -k|grep -i WebSphere > /dev/null 2>&1;RC3=$?
if [ $RC3 -eq 0 ]
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.was" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.was" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.was.all -a -s /etc/rc.was.all ]
                then
                        violations="Compliant"
                        VALUE="$(cksum /etc/rc.was.all)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.was.all DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.was NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="NO_WAS_FILESET_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#D4
DescNo="D4"
DescItem="WAS Binary location"
policy_reco="Ensure that WAS files are placed in appvg volume group."
STDBLD="A"
AUTOCHK="A"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [ "$HostHADR" != "b" ])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
/usr/bin/df -k|grep -i WebSphere  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
#if [ -d /usr/IBM/WebSphere ]
then
df -g /usr/IBM/WebSphere | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
 violations="Non-Compliant"
 VALUE="WAS_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /usr/IBM/WebSphere  | grep -v Filesystem | awk '{print $7}')"
 else
 violations="Compliant"
 VALUE="WAS_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /usr/IBM/WebSphere | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="NO_WAS_FILESET_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
how_to="# lsvg -l $VGIS"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#####################################################
DrawSubHead "3. Oracle/DB2 (This following steps are applicable only when Oracle is installed)"  >>$HTMLLogFile
#D5
DescNo="D5"
DescItem="ORACLE/DB2 Start/Stop Scripts"
policy_reco="Ensure that Oracle has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup & cat /etc/rc.shutdown"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [ "$HostHADR" != "b" ])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
id oracle > /dev/null 2>&1;RC3=$?
cat /etc/passwd | grep ^db2 > /dev/null 2>&1;RC4=$?
if ([ $RC3 -eq 0 ] && [ -d /oracle ]) || ([ $RC4 -eq 0 ])
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.db" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.db" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.db -a -s /etc/rc.db ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.db)"
                        else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.db DOES_NOT_EXIST"
                fi
           else
                violations="Non-Compliant"
                VALUE="/etc/rc.db NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
VALUE="NO DB FOUND"
violations="Not-Applicable"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#D6
DescNo="D6"
DescItem="ORACLE Binary location"
policy_reco="Ensure that Oracle files are placed in datavg & logvg volume groups."
STDBLD="A"
AUTOCHK="A"
#lslpp -l | grep -i WebSphere > /dev/null 2>&1;RC=$?
#if [ $RC -eq 0 ]
#if [ -d /oracle ]
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [ "$HostHADR" != "b" ])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
id oracle > /dev/null 2>&1;RC3=$?
if ([ $RC3 -eq 0 ] && [ -d /oracle ])
then
df -g /oracle | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS >/dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') >/dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
 violations="Non-Compliant"
 VALUE="ORACLE_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /usr/IBM/WebSphere  | grep -v Filesystem | awk '{print $7}')"
 else
 violations="Compliant"
 VALUE="ORACLE_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /usr/IBM/WebSphere | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="NO_ORACLE_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
how_to="# lsvg -l $VGIS"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#####################################################
DrawSubHead "4. ConnectDirect (This following steps are applicable only when ConnectDirect is installed)"  >>$HTMLLogFile
#D7
DescNo="D7"
DescItem="ConnectDirect Start/Stop Scripts"
policy_reco="Ensure that ConnectDirect has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/rc.startup & cat /etc/rc.shutdown"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [ "$HostHADR" != "b" ])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
if [ -d /usr/lpp/cdunix ]
then
if [  "$STARTUP" = "OK" -a "$STOPUP" = "OK"  ]
then
        cat /etc/rc.startup | grep -i "/etc/rc.cd" > /dev/null 2>&1;RC1=$?
        cat /etc/rc.shutdown  | grep -i "/etc/rc.cd" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                if [ -f /etc/rc.cd -a -s /etc/rc.cd ]
                then
                        violations="Compliant"
                        VALUE="$(ls -lrt /etc/rc.cd)"
                else
                        violations="Non-Compliant"
                        VALUE="/etc/rc.cd DOES_NOT_EXIST"
                fi
         else
                violations="Non-Compliant"
                VALUE="/etc/rc.cd NOT_ENABLED -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
   else
  violations="Non-Compliant"
  VALUE="/etc/rc.startup -OR- /etc/rc.shutdown NOT_FOUND"
fi
else
VALUE="NO CD FOUND"
violations="Not-Applicable"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#D8
DescNo="D8"
DescItem="ConnectDirect Binary location"
policy_reco="Ensure that ConnectDirect files are placed in datavg volume groups."
STDBLD="A"
AUTOCHK="A"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
#if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
if ([ "$HostDR" != "r" ] || [[  "$HostDR" = "g" && "$HostHADR" != "b" ]])
then
if [ -d /usr/lpp/cdunix ]
then
df -g /usr/lpp/cdunix | grep -v Filesystem | awk '{print $1}' | awk -F '/' '{print $NF}' | read LVIS > /dev/null 2>&1
VGIS=$(lslv $LVIS | grep "VOLUME GROUP" | awk '{print $NF}') > /dev/null 2>&1
if [ $VGIS = "rootvg" ]
then
 violations="Non-Compliant"
 VALUE="CD_BINARY_LOCATION_IS_IN_ROOTVG<br><br><br>$(df -g /usr/lpp/cdunix  | grep -v Filesystem | awk '{print $7}')"
 else
 violations="Compliant"
 VALUE="CD_BINARY_LOCATION_IS_NOROOTVG<br><br><br>$(df -g /usr/lpp/cdunix | grep -v Filesystem | awk '{print $7}')"
fi
else
 violations="Not-Applicable"
 VALUE="NO_CD_FOUND"
fi
else
 violations="Not-Applicable"
 VALUE="Not Applicable for DR or HADR server"
fi
how_to="# lsvg -l $VGIS"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


####################################
DrawSecHead "Section E: Additional Operating SystemSettings " >> $HTMLLogFile

echo "$(date) : Additional Operating SystemSettings Verification "

# TIMEOUT
#E1
DescNo="E1"
DescItem="Putty Session Timeout"
policy_reco="Set TMOUT to 600secs"
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/profile"
cat /etc/profile | grep -v "^#" | grep "TMOUT=600" > /dev/null 2>&1;RC=$?
if [ $RC  -eq 0 ]
then
   violations="Compliant"
   VALUE="$(cat /etc/profile | grep -v "^#" | grep "TMOUT=600")"
   else
   violations="Non-Compliant"
   VALUE="$(cat /etc/profile | grep -v "^#" | grep "TMOUT=600")"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#E2
DescNo="E2"
STDBLD="A"
AUTOCHK="A"
DescItem="PATH Variable"
policy_reco="Ensure PATH variable updated in /etc/environment"
how_to="# cat /etc/environment"
lslpp -L | grep VRTSvcs > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
cat /etc/environment |grep -v "^#" | grep -w PATH | grep VRTSvcs > /dev/null 2>&1;RC=$?
if [ $RC  -eq 0 ]
then
   violations="Compliant"
   VALUE="$(cat /etc/environment |grep -v "^#" | grep -w PATH)"
   else
   violations="Non-Compliant"
   VALUE="$(cat /etc/environment |grep -v "^#" | grep -w PATH)"
fi
else
cat /etc/environment |grep -v "^#" | grep -w PATH > /dev/null 2>&1;RC=$?
if [ $RC  -eq 0 ]
then
   violations="Compliant"
   VALUE="$(cat /etc/environment |grep -v "^#" | grep -w PATH)"
   else
   violations="Non-Compliant"
   VALUE="$(cat /etc/environment |grep -v "^#" | grep -w PATH)"
fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#E3, E4 & E5
i=3
for FILEIS in /etc/resolv.conf /etc/netsvc.conf /etc/ntp.conf
do
DescItem="$FILEIS Permissions"
policy_reco="Set $FILEIS permissions to 644"
how_to="# ls -lrt $FILEIS"
DescNo="E${i}"
STDBLD="A"
AUTOCHK="A"
if [ -f $FILEIS -a -s $FILEIS ]
then
  FPERMS=$(ls -lrt $FILEIS | awk '{print $1}')
  if [ "$FPERMS" = "-rw-r--r--" ]
  then
   violations="Compliant"
   VALUE="$(ls -lrt $FILEIS | awk '{print $1"  "$9}')"
  else
    violations="Non-Compliant"
    VALUE="$(ls -lrt $FILEIS | awk '{print $1"  "$9}')"
  fi
 else
    violations="Non-Compliant"
    VALUE="File Doesn't Exist or Empty File"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile
((i=$i+1))
done
###

# PERM HW Errors
#E6
DescNo="E6"
STDBLD="A"
AUTOCHK="A"
DescItem="PERM Hardware Errors to be captured"
policy_reco="Ensure /systemlogs/errpt.log exist"
how_to="# ls -lrt /systemlogs/errpt.log"
if [ -f /systemlogs/errpt.log ]
then
   violations="Compliant"
   VALUE="$(ls -lrt /systemlogs/errpt.log | awk '{print $1"  "$9}')"
  else
    violations="Non-Compliant"
    VALUE="File not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# errnotify.sh
#E7
DescNo="E7"
STDBLD="A"
AUTOCHK="A"
DescItem="errnotify Script"
policy_reco="Ensure /usr/local/scripts/errornotify.sh exist"
how_to="# ls -lrt /usr/local/scripts/errornotify.sh"
ls -lrt /usr/local/scripts/errornotify.sh > /dev/null 2>&1;RC1=$?
ls -lrt /usr/local/script/errornotify.sh > /dev/null 2>&1;RC2=$?
[ $RC1 -eq 0 ] && ERRNOTIFY="/usr/local/scripts/errornotify.sh"
[ $RC2 -eq 0 ] && ERRNOTIFY="/usr/local/script/errornotify.sh"
if [  $RC1 -eq 0 -o $RC2 -eq 0  ]
then
   violations="Compliant"
   VALUE="$(ls -lrt $ERRNOTIFY | awk '{print $1"  "$9}')"
  else
    violations="Non-Compliant"
    VALUE="File not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#####
#E8
DescNo="E8"
STDBLD="A"
AUTOCHK="A"
DescItem="NTP Service"
policy_reco="NTP client will synch with the NTP/DNS server via the NTP process<br><br>Ensure that NTP process is running on the client."
how_to="# lssrc -a|grep xntpd"
lssrc -a|grep xntpd | grep active > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
 then
    violations1="Compliant"
    VALUE1="`lssrc -a|grep xntpd`"
  else
    violations1="Non-Compliant"
   VALUE1="`lssrc -a |grep xntpd`"
fi
cat /etc/rc.tcpip | grep ^"start /usr/sbin/xntpd" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
 then
    violations2="Compliant"
    VALUE2="$(cat /etc/rc.tcpip | grep "start /usr/sbin/xntpd")"
  else
    violations2="Non-Compliant"
    VALUE2="$(cat /etc/rc.tcpip | grep "start /usr/sbin/xntpd")"
fi
if [ $violations1 = "Non-Compliant" -o $violations2 = "Non-Compliant" ]
then
    violations="Non-Compliant"
    else
    violations="Compliant"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE1<br>$VALUE2</pre>" "$violations" >>$HTMLLogFile

#E9
DescNo="E9"
STDBLD="A"
AUTOCHK="A"
DescItem="NTP Port"
policy_reco="Ensure NTP Port opened in /etc/services"
how_to="# cat /etc/services | grep ^ntp"
cat /etc/services | grep ^ntp > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    violations="Compliant"
    VALUE="$(cat /etc/services | grep -w ntp | grep Time)"
  else
    violations="Non-Compliant"
    VALUE="$(cat /etc/services | grep -w ntp | grep Time)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile
#

# TSCM
#E10
DescNo="E10"
STDBLD="A"
AUTOCHK="A"
DescItem="TSCM Client"
policy_reco="Ensure that Tivoli Security Compliance Manager (TSCM) is not installed."
how_to="#ls -ld /opt/IBM/SCM/client/"
if [ -f /opt/IBM/SCM/client/jacclient ]; then
  violations="Non-Compliant"
  VALUE="TSCM client installed"
else
  violations="Compliant"
  VALUE="TSCM not installed"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# SCSP
#E11
DescNo="E11"
STDBLD="A"
AUTOCHK="A"
DescItem="Intrusion Detection Tool"
policy_reco="Ensure SCSP/SDCS Agent is installed and running</n>See DBS ITA implementation / config standard and policy which is maintained by ITA administrator."
how_to="# ps -ef|grep scsp|grep -v grep ; sisipsconfig.sh -v ; sisipsconfig.sh -t"
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
        if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="SCSP not Installed. Development or SIT Server"
        HOSTS=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]')
        elif [ "$HOSTS" = "a03s" ] ; then
        violations="Not-Applicable"
        VALUE="SCSP not Installed.Not Mandatory for HK UAT servers "
        else
ps -ef|grep -E "scsp|sdcs" |grep -v grep >/dev/null 2>&1;RC1=$?
if [ -d "/opt/Symantec/scspagent" ];	then
	su - sisips -c "/opt/Symantec/scspagent/IPS/sisipsconfig.sh -v" > $OUTDIR/scsptmp.txt
	su - sisips -c "/opt/Symantec/scspagent/IPS/sisipsconfig.sh -t" > $OUTDIR/scsptestcomm.txt
else
	su - sisips -c "/opt/Symantec/sdcssagent/IPS/sisipsconfig.sh -v" > $OUTDIR/scsptmp.txt
	su - sisips -c "/opt/Symantec/sdcssagent/IPS/sisipsconfig.sh -t" > $OUTDIR/scsptestcomm.txt
fi
SCSPPF=$(cat $OUTDIR/scsptmp.txt | grep "Prevention Feature" | cut -d"-" -f2 | tr -d ' ')
cat $OUTDIR/scsptmp.txt | grep "Current Management Server" |  awk -F '-' '{print $2}' | tr -d ' ' | grep -E '10.80.128.121|10.89.52.28|10.197.150.64|10.196.150.129|10.196.150.130|10.190.15.231' > /dev/null 2>&1;RC2=$?
cat $OUTDIR/scsptestcomm.txt | grep -i "Connection to server successful" > /dev/null 2>&1;RC3=$?
if ([ $RC1 -eq 0 ] && [ $RC2 -eq 0 ] && [ $RC3 -eq 0 ] && [ $SCSPPF == "disabled" ])
then
  violations="Compliant"
  VALUE1="SCSP/SDCS agent is running"
  VALUE2="$(cat $OUTDIR/scsptmp.txt)"
  VALUE3="$(cat $OUTDIR/scsptestcomm.txt)"
  VALUE="$VALUE1\n$VALUE2\n$VALUE3"
else
  violations="Non-Compliant"
  VALUE1="SCSP/SDCS agent is not running, please check"
  VALUE2="$(cat $OUTDIR/scsptmp.txt)"
  VALUE3="$(cat $OUTDIR/scsptestcomm.txt)"
  VALUE="$VALUE1\n$VALUE2\n$VALUE3"
fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# SENDMAIL
#E12
DescNo="E12"
STDBLD="A"
AUTOCHK="A"
DescItem="Sendmail Service"
policy_reco="Ensure sendmail outbound disabled"
how_to="# lssrc -s sendmail"
lssrc -s sendmail | grep active > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
  violations1="Non-Compliant"
  VALUE1="$(lssrc -a | grep sendmail)"
else
  violations1="Compliant"
  VALUE1="$(lssrc -a | grep sendmail)"
fi
cat /etc/rc.tcpip | grep ^"#start /usr/lib/sendmail" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
  violations2="Compliant"
  VALUE2="$(cat  /etc/rc.tcpip | grep "start /usr/lib/sendmail")"
else
  violations2="Non-Compliant"
  VALUE2="$(cat  /etc/rc.tcpip | grep "start /usr/lib/sendmail")"
fi
if [ $violations1 = "Non-Compliant" -o $violations2 = "Non-Compliant" ]
then
  violations="Non-Compliant"
  else
  violations="Compliant"
fi
VALUE="$VALUE1<br>$VALUE2"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# SYSLOGD
#E13
DescNo="E13"
STDBLD="A"
AUTOCHK="A"
DescItem="syslogd Service"
policy_reco="Ensure Syslogd running"
how_to="# lssrc -s syslogd"
lssrc -s syslogd | grep active > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
 violations="Compliant"
  VALUE="$(lssrc -a | grep syslogd)"
else
  violations="Non-Compliant"
  VALUE="$(lssrc -a | grep syslogd)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# TRIP
#E14
DescNo="E14"
STDBLD="A"
AUTOCHK="A"
DescItem="TripWire Service"
policy_reco="Ensure TripWire Service running"
how_to="# lssrc -g tripwire"
#lslpp -l | grep -wi tripwire > /dev/null 2>&1;RC=$?
ls -ld /opt/tripwire/te/agent > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ];	then
	violations="Non-Compliant"
	VALUE="TRIPWIRE_NOT_INSTALLED"
else
	lssrc -g tripwire |grep -v Subsystem | grep -v teges | grep -v active > /dev/null 2>&1;RC=$?
	if [ $RC -ne 0 ];	then
		violations="Compliant"
		VALUE="$(lssrc -a | grep trip)"
	else
		HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
		if ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ]);	then
			violations="Non-Applicable"
			VALUE="Tripwire is not required for DEV and SIT servers"
		else
			violations="Non-Compliant"
			VALUE="$(lssrc -a | grep trip)"
		fi
	fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# TLM
#E15
DescNo="E15"
STDBLD="A"
AUTOCHK="A"
DescItem="TLM Agent"
policy_reco="Ensure TLM Service running"
how_to="# lssrc -s tlmagent"
lssrc -s tlmagent | grep active > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
 violations="Compliant"
  VALUE="$(lssrc -a | grep tlmagent)"
else
  violations="Non-Compliant"
  VALUE="$(lssrc -a | grep tlmagent)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# CYBERARK
#E16
DescNo="E16"
STDBLD="A"
AUTOCHK="A"
DescItem="VASCO And CyberArk Configuration"
policy_reco="Ensure VASCO and CyberArk configured properly"
how_to="# netstat -an"
HOSTS=$(hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]')
if ([ "$HOSTS" = "a01" ] || [ "$HOSTS" = "a07" ])
then
        netstat -an | grep -w 60022 | grep LISTEN > /dev/null 2>&1;RC1=$?
        netstat -an | grep -w 61022 | grep LISTEN > /dev/null 2>&1;RC2=$?
        netstat -an | grep -w 63022 | grep LISTEN > /dev/null 2>&1;RC3=$?
        ((RC=$RC1+$RC2+RC3))
        if [ $RC -eq 0 ]
                then
                violations="Compliant"
                VALUE="$(netstat -an | grep -Ew "60022|61022|63022")"
        else
                violations="Non-Compliant"
                VALUE="Required ports are not LISTENING "
        fi
elif [ "$HOSTS" = "a03" ]
        then
                violations="Not-Applicable"
                VALUE="NOT APPLICABLE FOR SERVERS in HK"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# ITM
#E17
DescNo="E17"
STDBLD="A"
AUTOCHK="A"
DescItem="ITM Configuration"
policy_reco="Ensure ITM Agents running"
how_to="# cinfo -r"
HOSTE=$(hostname | cut -c1-4 | sed 's/^.*\(.\)$/\1/')
if [ -f /IBM/itm/bin/cinfo ]
then
     /IBM/itm/bin/cinfo -r > /tmp/itminfo.xt
     cat  /tmp/itminfo.xt | grep -w not > /dev/null 2>&1;RC=$?
     if [ $RC -eq 0 ]
     then
          violations="Non-Compliant"
          VALUE="$(cat /tmp/itminfo.xt)"
       else
          violations="Compliant"
          VALUE="$(cat /tmp/itminfo.xt)"
    fi
elif [ -f /opt/IBM/ITM/bin/cinfo ]
then
     /opt/IBM/ITM/bin/cinfo -r > /tmp/itminfo.xt
     cat  /tmp/itminfo.xt | grep -w not > /dev/null 2>&1;RC=$?
     if [ $RC -eq 0 ]
     then
          violations="Non-Compliant"
          VALUE="$(cat /tmp/itminfo.xt)"
       else
          violations="Compliant"
          VALUE="$(cat /tmp/itminfo.xt)"
    fi
elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "t" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "b" ])
        then
        violations="Not-Applicable"
        VALUE="ITM not Installed. Development or SIT Server"
elif [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "s" ]
        then
        violations="Not-Applicable"
        VALUE="ITM not Installed. Not mandatory for UAT Servers"
elif ([ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "g" ] || [ `echo $HOSTE | tr -s '[:upper:]' '[:lower:]'` = "r" ])
        then
        violations="Non-Compliant"
        VALUE="ITM not Installed"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# HARDWARE Alert
#E18
DescNo="E18"
STDBLD="A"
AUTOCHK="A"
DescItem="ODM Updated with errnotify"
policy_reco="Ensure errnotify enabled for HWAlert though ODM"
how_to="# odmget errnotify"
HWALSCRIPT=$(odmget errnotify|grep -w errornotify.sh|tail -1|cut -d"=" -f2|cut -d" " -f2|tr -d "\"")
if [ -z "$HWALSCRIPT" ]
 then
    HWALT="HWAlertNotConfigured"
 else
    [ -x "$HWALSCRIPT" ] && /usr/bin/grep PERM "$HWALSCRIPT">/dev/null 2>&1 && HWALT="HWAlertConfigured"||HWALT="HWAlertNotConfigured"
fi
if [ $HWALT = "HWAlertConfigured" ]
then
    violations="Compliant"
    VALUE="HWAlertConfigured via ODM"
       else
   violations="Non-Compliant"
   VALUE="HWAlertNotConfigured"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# SNMP
#E19
DescNo="E19"
STDBLD="A"
AUTOCHK="A"
DescItem="SNMP service"
policy_reco="To disable SNMP if not required. If needed, it has to be properly configured and controlled only for sending out SNMP traps and receiving SNMP messages from authorized hosts. <br><br>SNMP required for HACMP clustered servers."
how_to="$printing>lssrc -a |grep -i snmp"
lssrc -s clstrmgrES > /dev/null 2>&1;RC1=$?
if [ $RC1 -eq 0 ]
        then
        for i in "snmpd" 
        do
        lssrc -s $i | grep -v PID | grep active |  sed -e '/^$/d' | awk '{print $1}' >> $OUTDIR/snmp1.txt
        done
        echo "snmpd" >$OUTDIR/snmp2.txt
        diff $OUTDIR/snmp1.txt $OUTDIR/snmp2.txt > /dev/null 2>&1;RC2=$?
        if [ $RC2 -eq 0 ]
                then
                violations="Compliant"
                VALUE="$(cat $OUTDIR/snmp1.txt)"
                else
                violations="Non-Compliant"
                VALUE="$(cat $OUTDIR/snmp1.txt)"
        fi
        else
        violations="Not-Applicable"
        VALUE="No HACMP Installed"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#E20
DescNo="E20"
STDBLD="A"
AUTOCHK="A"
DescItem="URT Script"
#policy_reco="Ensure URT Script scheduled in crontab"
policy_reco="Ensure URT Script scheduled in crontab<br>"/usr/local/scripts/URT/iam_extract_global.ksh"<br>"
how_to="# crontab -l"
if [ -f /usr/local/scripts/URT/iam_extract_global.ksh -a -s /usr/local/scripts/URT/iam_extract_global.ksh ]
then
    crontab -l | grep -v "^#" | grep "/usr/local/scripts/URT/iam_extract_global.ksh -c DBS"   > /dev/null 2>&1;RC=$?
    if [ $RC -eq 0 ]
    then
         violations="Not-Applicable"
         VALUE="$(crontab -l | grep -v "^#" | grep "/usr/local/scripts/URT/iam_extract_global.ksh -c DBS")"
      else
          violations="Not-Applicable"
          VALUE="No Cron Schedule"
    fi
else
       violations="Not-Applicable"
       VALUE="Script not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


## E21
DescNo="E21"
STDBLD="A"
AUTOCHK="A"
DescItem="OS HealthCheck Script"
policy_reco="Ensure HealthCheck Script scheduled in crontab<br>"/usr/local/scripts/SysHC/aix_syshc.ksh"<br>"
how_to="# crontab -l"
if [ -f /usr/local/scripts/SysHC/aix_syshc.ksh ]
then
    crontab -l  | grep -v "^#" | grep  /usr/local/scripts/SysHC/aix_syshc.ksh   > /dev/null 2>&1;RC=$?
    if [ $RC -eq 0 ]
    then
           violations="Compliant"
          VALUE="$(crontab -l | grep -v "^#" | grep  "/usr/local/scripts/SysHC/aix_syshc.ksh" )"
       else
          violations="Non-Compliant"
          VALUE="No Cron Schedule"
    fi
else
       violations="Non-Compliant"
       VALUE="Script not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


####
#E22
DescNo="E22"
STDBLD="A"
AUTOCHK="A"
DescItem="OS HouseKeeping Script"
policy_reco="Ensure HouseKeeping Script scheduled in crontab<br>"/usr/local/scripts/SysHC/housekeepwrapper.pl"<br>"
how_to="# crontab -l"
if [ -f /usr/local/scripts/SysHC/housekeepwrapper.pl ]
then
    crontab -l  | grep -v "^#" | grep  "/usr/local/scripts/SysHC/housekeepwrapper.pl"   > /dev/null 2>&1;RC=$?
    if [ $RC -eq 0 ]
    then
           violations="Compliant"
          VALUE="$(crontab -l | grep -v "^#" | grep  "/usr/local/scripts/SysHC/housekeepwrapper.pl")"
       else
          violations="Non-Compliant"
          VALUE="No Cron Schedule"
    fi
else
       violations="Non-Compliant"
       VALUE="Script not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#E23
DescNo="E23"
STDBLD="A"
AUTOCHK="A"
DescItem="Sudoers Update Script"
policy_reco="Ensure Sudoers update Script scheduled in crontab<br>"update_sudoers"<br>"
how_to="# crontab -l"
crontab -l | grep -v "^#" | grep  update_sudoers   > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        CRONSCRIPT=$(crontab -l | grep -v "^#" | grep  update_sudoers | awk '{print $6}')
        if [ -x $CRONSCRIPT ]
        then
          violations="Not-Applicable"
          VALUE="$(crontab -l | grep -v "^#" | grep  update_sudoers)"
       else
          violations="Not-Applicable"
          VALUE="Script requirement not met"
        fi
else
       violations="Not-Applicable"
       VALUE="Cron Schedule not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# Checkpage
#E24
DescNo="E24"
STDBLD="A"
AUTOCHK="A"
DescItem="Paging Space Monitoring"
policy_reco="Ensure paging Space alert configured<br>"checkpage.ksh"<br>"
how_to="# crontab -l | grep checkpage"
crontab -l | grep -v "^#" | grep checkpage.ksh > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
      CRONSCRIPT=$(crontab -l | grep checkpage.ksh | awk '{print $6}')
      if  [ -x $CRONSCRIPT ]
      then
          violations="Compliant"
          VALUE="$(crontab -l | grep -v "^#" | grep checkpage.ksh)"
       else
          violations="Non-Compliant"
           VALUE="Script Requirements not met"
       fi
else
          violations="Non-Compliant"
          VALUE="Cron schedule not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile



# FTP
#E25
DescNo="E25"
STDBLD="A"
AUTOCHK="A"
DescItem="FTP Configuration"
policy_reco="Ensure FTP Users file backup configured through cron<br>"/usr/local/scripts/update_ftp_cron.sh"<br>"
how_to="# crontab -l | grep update_ftp_cron.sh"
if [ -f /usr/local/scripts/update_ftp_cron.sh  -a -x /usr/local/scripts/update_ftp_cron.sh  ]
then
        crontab -l | grep -v "^#" | grep "/usr/local/scripts/update_ftp_cron.sh" > /dev/null 2>&1;RC=$?
     if [ $RC -eq 0 ]
     then
          violations="Compliant"
          VALUE="$(crontab -l | grep -v "^#" | grep "/usr/local/scripts/update_ftp_cron.sh")"
       else
          violations="Non-Compliant"
           VALUE="No cron schedule"
fi
else
          violations="Non-Compliant"
          VALUE="Script not found"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile



# NMON
#E26
DescNo="E26"
STDBLD="A"
AUTOCHK="A"
DescItem="NMON Collection"
policy_reco="/usr/bin/topas_nmon -f -t -d -A -O -L -N -P -V -T -^ -s 60 -c 1440"
how_to="# crontab -l | grep nmon"
crontab -l |  grep nmon | grep -E "\-O \-L \-N|1440|60" > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        echo "\nNMON_ENABLED_IN_CRON" >> $OUTDIR/nmon.txt
    else
        echo "\nNMON_NOT_ENABLED_IN_CRON"  >> $OUTDIR/nmon.txt
fi
ps -ef | grep nmon | grep -E "\-O \-L \-N|1440|60"  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        echo "\nNMON_PROCESS RUNNING"  >> $OUTDIR/nmon.txt
    else
        echo "\nNMON_PROCESS_NOT_RUNNING"  >> $OUTDIR/nmon.txt
fi
cat $OUTDIR/nmon.txt | grep NOT > /dev/null 2>&1
if [ $? -eq 0 ]
then
    violations="Non-Compliant"
    VALUE="$(cat $OUTDIR/nmon.txt)"
    else
    violations="Compliant"
    VALUE="$(cat $OUTDIR/nmon.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# ID Management
#E27
DescNo="E27"
STDBLD="A"
AUTOCHK="A"
DescItem="ID Management Script"
policy_reco="Ensure ID Management script copied with execute permissions"
how_to="# ls -lrt /usr/bin/aixid.sh"
if [ -f /usr/bin/aixid.sh ]
then
AIXIDCHKSUM=$(cksum /usr/bin/aixid.sh | cut -d ' ' -f 1)
CKSUMIS="3553055510"
        if [ -x /usr/bin/aixid.sh -a "$CKSUMIS" = "$AIXIDCHKSUM"  ]
        then
          violations="Compliant"
          VALUE="$(ls -lrt /usr/bin/aixid.sh | awk '{print $1" "$9}')"
       else
          violations="Non-Compliant"
          VALUE="Script Requirement not met"
        fi
else
          violations="Non-Compliant"
          VALUE="Script_Does_Not_Exit"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# ID
#E28
DescNo="E28"
STDBLD="A"
AUTOCHK="A"
DescItem="Functional UserIds"
policy_reco="Ensure All functional IDs Created"
how_to="# cat /etc/passwd"
HOSTS=$(hostname | cut -c1-4 | tr -s '[:upper:]' '[:lower:]')
if ([ "$HOSTS" = "a03t" ] || [ "$HOSTS" = "a03b" ] || [ "$HOSTS" = "a03s" ])
        then
        cat /etc/passwd | grep ^eoadmin > /dev/null 2>&1;RC1=$?
        cat /etc/passwd | grep ^idmgt > /dev/null 2>&1;RC2=$?
        cat /etc/passwd | grep ^dbsinvs > /dev/null 2>&1;RC3=$?
        ((RC=$RC1+$RC2+RC3))
                if [ $RC -eq 0 ]
                then
                        violations="Compliant"
                        VALUE="$(cat /etc/passwd | egrep "eoadmin|ibmsa|idmgt|dbsinvs" | cut -d: -f1)"
                else
                        violations="Non-Compliant"
                        VALUE="Missing IDs"
                fi
elif ([ "$HOSTS" = "a01t" ] || [ "$HOSTS" = "a01b" ] || [ "$HOSTS" = "a01s" ]) ; then
cat /etc/passwd | grep ^aixadm > /dev/null 2>&1;RC1=$?
cat /etc/passwd | grep ^osadmin > /dev/null 2>&1;RC2=$?
cat /etc/passwd | grep ^paosim > /dev/null 2>&1;RC3=$?
cat /etc/passwd | grep ^stgadm > /dev/null 2>&1;RC4=$?
cat /etc/passwd | grep ^dbsinvs > /dev/null 2>&1;RC5=$?
cat /etc/passwd | grep ^eoadmin > /dev/null 2>&1;RC6=$?
((RC=$RC1+$RC2+$RC3+$RC4+$RC5+$RC6))
if [ $RC -eq 0 ]
then
          violations="Compliant"
          VALUE="$(cat /etc/passwd | egrep "eoadmin|aixadm|osadmin|paosim|stgadm|dbsinvs" | cut -d: -f1)"
       else
          violations="Non-Compliant"
           VALUE="Missing IDs"
fi
elif ([ "$HOSTS" = "a03g" ] || [ "$HOSTS" = "a03r" ])
then
cat /etc/passwd | grep ^eoadmin > /dev/null 2>&1;RC1=$?
cat /etc/passwd | grep ^idmgt > /dev/null 2>&1;RC2=$?
cat /etc/passwd | grep ^dbsinvs > /dev/null 2>&1;RC3=$?
cat /etc/passwd | grep ^ibmsa  > /dev/null 2>&1;RC4=$?
cat /etc/passwd | grep ^stgadm > /dev/null 2>&1;RC5=$?
((RC=$RC1+$RC2+$RC3+$RC4+$RC5))
if [ $RC -eq 0 ]
then
          violations="Compliant"
          VALUE="$(cat /etc/passwd | egrep "eoadmin|idmgt|dbsinvs|ibmsa|stgadm"  | cut -d: -f1)"
	else
	  violations="Non-Compliant"
           VALUE="Missing IDs"
fi
elif ([ "$HOSTS" = "a01g" ] || [ "$HOSTS" = "a01r" ] || [ "$HOSTS" = "a01c" ]) ; then
cat /etc/passwd | grep ^aixadm > /dev/null 2>&1;RC1=$?
cat /etc/passwd | grep ^osadmin > /dev/null 2>&1;RC2=$?
cat /etc/passwd | grep ^paosim > /dev/null 2>&1;RC3=$?
cat /etc/passwd | grep ^stgadm > /dev/null 2>&1;RC4=$?
cat /etc/passwd | grep ^dbsinvs > /dev/null 2>&1;RC5=$?
cat /etc/passwd | grep ^eoadmin > /dev/null 2>&1;RC6=$?
((RC=$RC1+$RC2+$RC3+$RC4+$RC5+$RC6))
if [ $RC -eq 0 ]
then
          violations="Compliant"
          VALUE="$(cat /etc/passwd | egrep "eoadmin|aixadm|osadmin|paosim|stgadm|dbsinvs" | cut -d: -f1)"
       else
          violations="Non-Compliant"
           VALUE="Missing IDs"
fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# SETUID & SETGID
#E29
DescNo="E29"
STDBLD="A"
AUTOCHK="A"
DescItem="SETUID & SETGID Files"
policy_reco="SCAN SETUID AND SETGID Files in /home directory"
how_to="List of SETUID and SETGID Files in /home "
find /home/ \( -perm -4000 -o -perm -2000 \) -type f -xdev -exec ls -l {} \; >> $OUTDIR/setuid.txt 2>&1
find /tmp/ \( -perm -4000 -o -perm -2000 \) -type f -xdev -exec ls -l {} \; >> $OUTDIR/setuid.txt 2>&1
if [ -f $OUTDIR/setuid.txt -a -s $OUTDIR/setuid.txt ]
then
        violations="Non-Compliant"
        VALUE="$(cat $OUTDIR/setuid.txt)"
else
        violations="Compliant"
        VALUE="$(cat $OUTDIR/setuid.txt)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#E30
DescNo="E30"
STDBLD="A"
AUTOCHK="A"
DescItem="HBA Attributes on ODM"
policy_reco="Ensure HBA Attributes updated in ODM to get default values"
how_to="# odmget  -q 'uniquetype=driver/iocb/efscsi and attribute=dyntrk' PdAt<br>odmget  -q 'uniquetype=driver/iocb/efscsi and attribute=fc_err_recov' PdAt"
lsdev -Cc adapter | grep ^fcs  > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=dyntrk" PdAt >> $OUTDIR/fcsodminfo.txt
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=fc_err_recov" PdAt >> $OUTDIR/fcsodminfo.txt
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=dyntrk" PdAt | grep "deflt" | grep -w no > /dev/null 2>&1;RC=$?
        odmget  -q "uniquetype=driver/iocb/efscsi and attribute=fc_err_recov" PdAt | grep -w deflt | grep delayed_fail > /dev/null 2>&1;RC=$?
        if [ $RC -ne 0 ]
        then
         violations="Compliant"
         VALUE="$(cat $OUTDIR/fcsodminfo.txt)"
         else
         violations="Non-Compliant"
         VALUE="$(cat $OUTDIR/fcsodminfo.txt)"
        fi
else
         violations="Not-Applicable"
         VALUE="NO FCS FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# FLASH-PPRC
#E31
DescNo="E31"
STDBLD="A"
AUTOCHK="A"
DescItem="FLASH-PPRC Scripts"
policy_reco="Ensure PPRC-FLASH Scripts configured"
how_to="# ls -lrt /usr/local/sysmaint/ or /HORCM/scripts/"
HostDR=$(echo `uname -n` | cut -b 4 | tr -s '[:upper:]' '[:lower:]')
HostHADR=$(echo `uname -n`  | sed 's/^.*\(.\)$/\1/' | tr -s '[:upper:]' '[:lower:]')
if ([ "$HostDR" = "r" ] || [[ "$HostDR" = "g" && "$HostHADR" = "b" ]])
then
  lsdev -Cc disk | grep Hitachi  > /dev/null 2>&1;RC=$?
  if [ $RC -eq 0 ]
  then
        if [ -d /HORCM/scripts/ ]
        then
                [ -x /HORCM/scripts/`hostname`_flash.ksh ] && RC1=$?
                crontab -l | grep -v "^#" | grep "/HORCM/scripts/`hostname`_flash.ksh" > /dev/null 2>&1;RC2=$?
                ((RC=$RC1+$RC2))
                if [ $RC -eq 0 ]
                then
                        violations="Compliant"
                        VALUE="DR Flash Script Configured"
                        VALUE2=$(raidcom get snapshot -IH2 | grep -i `hostname` | awk '{print $1}' | head -1 |  tr -d ' ' )
                        VALUE1="$(raidcom get snapshot -snapshotgroup $VALUE2 -fx -IH2)"
                else
                        violations="Non-Compliant"
                        VALUE="DR Flash Script NotConfigured"
                        VALUE1=" "
                fi
        else
                violations="Not-Applicable"
                VALUE="/HORCM/scripts/ Does not Exist"
                VALUE1=" "
        fi
  else
   if [ -d /usr/local/sysmaint/script ]
   then
       [ -x /usr/local/sysmaint/script/ibmsplitdisk.sh ] && RC1=$?
           crontab -l | grep -v "^#" | grep "/usr/local/sysmaint/script/ibmsplitdisk.sh" > /dev/null 2>&1;RC2=$?
                   R1COUNT=`awk '/^#SOURCE/,/^$/ { print }' /usr/local/sysmaint/script/`uname -n`_pprc.cfg|wc -l`
                   R1COUNT=`expr $R1COUNT - 1`
                   R2COUNT=`sudo /sysmaint/script/dspprc `uname -n` query |awk '$0~/^=/,/^=$/ { print }'|grep -i "Full Duplex" | wc -l`
           ((RC=$RC1+$RC2))
           if [ $RC -eq 0 ]
           then
              violations="Compliant"
              VALUE="DR Flash Script Configured"
                          VALUE1="$R1COUNT=$R2COUNT"
              else
              violations="Non-Compliant"
              VALUE="DR Flash Script NotConfigured"
                VALUE1=" "
           fi
    else
              violations="Not-Applicable"
              VALUE="/usr/local/sysmaint/script Does not Exist"
                VALUE1=" "
    fi
  fi
else
              violations="Not-Applicable"
              VALUE="NOT A DR NODE"
                VALUE1=" "
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE<br>$VALUE1</pre>" "$violations" >>$HTMLLogFile


# LSDEV
#E32
DescNo="E32"
STDBLD="A"
AUTOCHK="A"
DescItem="Device Status"
policy_reco="Ensure All devices are "Available""
how_to="# lsdev -Cc adapter"
lsdev -Cc adapter | grep Def > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
          violations="Compliant"
          VALUE="$(lsdev -Cc adapter)"
          else
          violations="Non-Compliant"
          VALUE="$(lsdev -Cc adapter)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# Adapters
#E33
DescNo="E33"
STDBLD="A"
AUTOCHK="A"
DescItem="Device Status"
policy_reco="Ensure All disks are "Available""
how_to="# lsdev -Cc disk"
lsdev -Cc disk | grep Def > /dev/null 2>&1;RC=$?
if [ $RC -ne 0 ]
then
          violations="Compliant"
          VALUE="$(lsdev -Cc disk)"
          else
          violations="Non-Compliant"
          VALUE="$(lsdev -Cc disk)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# Dual Path
#E34
DescNo="E34"
STDBLD="A"
AUTOCHK="A"
DescItem="Dual Path Status"
policy_reco="Ensure Dual path OK for all SAN disks  "
how_to="# lspath"
#lsdev -Cc disk | grep Available | awk '{print $1}' | while read DISKPATH
lsdev -Cc disk|grep Available|grep -wE "FC|PowerPath|Hitachi" >/dev/null 2>&1;RC=$?
        if [ $RC -eq 0 ]
        then
        lsdev -Cc disk|grep -wE "FC|PowerPath|Hitachi" | awk '{print $1}' | while read DISKPATH
        do
        PCNT=`lspath | grep -w $DISKPATH | grep Enabled | sort -u | wc -l`
        VPCNT=`expr $PCNT % 2`
        if [ $VPCNT -eq 0 ]
                then
                        echo "$(lspath | grep -w $DISKPATH | grep Enabled | sort -u) : OK" >> $OUTDIR/diskpath.txt
                        else
                        echo "$(lspath | grep -w $DISKPATH | grep Enabled | sort -u) : NOK" >> $OUTDIR/diskpath.txt
                fi
        done
        else
                echo "No SAN Disks : OK " >> $OUTDIR/diskpath.txt
        fi
cat  $OUTDIR/diskpath.txt | grep NOK > /dev/null 2>&1;RC1=$?
if [ $RC1 -eq 0 ]
then
     VALUE="$(cat $OUTDIR/diskpath.txt)"
     violations="Non-Compliant"
else
     VALUE="$(cat $OUTDIR/diskpath.txt)"
     violations="Compliant"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# Dual HMC
#E35
DescNo="E35"
STDBLD="A"
AUTOCHK="A"
DescItem="LPAR Managed by Dual HMC"
policy_reco="Virtual LPAR is managed by Dual HMC's"
how_to="# lsrsrc IBM.MCP"
#lsdev -Cc adapter | grep Virtual > /dev/null 2>&1;RC=$?
lsdev -Cc adapter | grep Available | grep Virtual | grep -E "Virtual Fibre|\(l-lan\)|Virtual SCSI"  >/dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
lsrsrc  "IBM.MCP" KeyToken  | grep KeyToken | awk '{print $3}' | sort -u >> $OUTDIR/hmc.txt
HMC=$(cat  $OUTDIR/hmc.txt | wc -l)
        if [ $HMC -eq 2 ]
        then
          violations="Compliant"
          VALUE="$(cat $OUTDIR/hmc.txt)"
          else
          violations="Non-Compliant"
	  VALUE1="$(cat $OUTDIR/hmc.txt)"
          VALUE2="Not able to connect to DUAL HMC. Check the RSCT deamon"
	  VALUE="$VALUE1\n$VALUE2"
        fi
else
lsrsrc  "IBM.MCP" KeyToken  | grep KeyToken | awk '{print $3}' | sort -u >> $OUTDIR/hmc.txt
HMC=$(cat  $OUTDIR/hmc.txt | wc -l)
        if [ $HMC -ge 1 ]
        then
        violations="Compliant"
        VALUE="$(cat $OUTDIR/hmc.txt)"
        else
        violations="Not-Applicable"
	VALUE1="$(cat $OUTDIR/hmc.txt)"
        VALUE2="Not a Virtual LPAR"
	VALUE="$VALUE1\n$VALUE2"
        fi
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

######################################################## CLOSING HERE ###############
echo "<tr><td colspan=7><b>Check Sum Value</b></td></tr>" >> $HTMLLogFile
echo "\n==============================================================================\nChecksum Value" >>$LOGGER
script_name=$0
if [ -f $script_name ]; then
  echo "<tr><td colspan=7>`cksum $script_name`</td></tr>" >>$HTMLLogFile
  echo "\t`cksum $script_name`" >> $LOGGER
fi
echo "\n==============================================================================\n">>$LOGGER

echo "<tr><td colspan=7><b>Check finished at: `date`</b></td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><b>Approver:</b> Ashish Bhan [ashishbhan@dbs.com]</td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><b>Author:</b> Prakash Dayalan [prakashdayalan@dbs.com]</td></tr>" >>$HTMLLogFile
#echo "<tr><td colspan=7><b>Modified By:</b> Prakash Dayalan [prakashdayalan@dbs.com]</td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><b>Reviewer:</b>[]</td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><b>Check finished at: `date`</b></td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><font color='red'>*DBS Confidential Document</font></p>" >>$HTMLLogFile
echo "$(date) : output generated as $HTMLLogFile "
chmod 755 $OUTDIR/;chmod 755 $OUTDIR/*;
chmod 644 $HTMLLogFile
chown dbsinvs $HTMLLogFile

echo "$(date) : Copying $HTMLLogFile to /home/dbsinvs"
cp -p $HTMLLogFile /home/dbsinvs/
/home/dbsinvs/Additional_data_collection.sh
echo "$(date) : InfraVerification | COMPLETED |  "
