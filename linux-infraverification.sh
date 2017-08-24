#!/bin/ksh
#
# SCRIPT: infraverification.sh
# USAGE : ./infraverification.sh
#
# AUTHOR: Sutharsanan.K (karuppaiah@dbs.com)
#
# REVIEWER: PRAKASH DAYALAN (prakashdayalan@dbs.com)
#
# APPROVER : Ashish BHAN (ashishbhan@dbs.com)
#
# DATE: 11/Apr/2017
# REV: 2.4
#
# PLATFORM: Linux
#
#
# PURPOSE: This shell script is to perform BAU Health check to make sure
#          everything configured according to recommanded values
#
# set -n # Uncomment to check the script syntax without any execution
# set -x # Uncomment to debug this shell script
##################################################################################

umask 022
export PATH=$PATH:/usr/sbin:/usr/ucb:/usr/local/bin:/sbin:/usr/bin:/opt/IBMsdd/bin:/usr/local/sbin/:/opt/VRTSvlic/bin:/opt/VRTSvlic/sbin:/opt/VRTS/bin:/opt/VRTSvcs/bin

############## T R A P CLEAN IF ANY USER INTERRUPTED

trap 'echo; echo Interrupted by user... Please wait| tee -a $LOGGER;rm -rf $OUTDIR;cleanup;tput rmso;sleep 2;exit 1' 1 2 3 15

############## H T M L  HEADER

function DrawHtmlFileHead {

        echo "<html>"
        echo "<style type=text/css>"
        echo "td { border-bottom:1px solid #D8D8D8; } </style>"
        echo "<body>"
        echo "<pre><hr><b><font size=5> Linux Infra Configuration Checklist for $(uname -n) </font></b><br><hr></pre>"
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
        echo "<td valign='top' align='left' style='word-wrap: break-word;'><font color='#008000'><ul><b>$vio</b></ul></td></tr>"
        elif [[ "$vio" = "Non-Compliant" ]]
        then
        #echo  "<td valign='top' align='left' style='word-wrap: break-word;'><font color='ff0000'><ul> $vio </ul></td></tr>"
        echo  "<td valign='center' align='left' style='word-wrap: break-word;'><font color='ff0000'><ul><b>$vio</b> </ul></td></tr>"
        else
        #echo "<td valign='center' align='left' style='word-wrap: break-word;'><font color='0000A0'><ul> $vio </ul></td></tr>"
        echo "<td valign='top' align='left' style='word-wrap: break-word;'><font color='0000A0'><ul> $vio </ul></td></tr>"
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
        echo -e "\n"
        echo -e "\t\t ***  Performing Infra Verification on \"$(hostname)\" **\n "
}

function Desctype
 {
OS=`uname`
if [ $OS = Linux ]
then
echo L
elif [ $OS = SunOS ]
then
echo S
elif [ $OS = AIX ]
then
echo A
fi
 }


############## V A R I A B L E S
initialize()
{
        OUTDIR="/tmp/INFRACHK"
        HOSTNAME=`hostname|awk '{print tolower($1)}'`
        DATE=`date | awk '{ DAY=$3 } { MONTH=$2 } { YEAR=$6 } END { print DAY MONTH YEAR }'`
        LOGGER="$OUTDIR/$HOSTNAME.`uname`.infraverification.log"
        HTMLLogFile="$OUTDIR/$HOSTNAME.`uname`.infraverification.htm"
        DEVIATION="$OUTDIR/$HOSTNAME.`uname`.infraverification.devlog"
#       export ODMDIR=/etc/objrepos
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
HOSTID=`hostid`
HOST=`hostname`
DEFROUTE=`netstat -nr | grep UG | awk '{ print $2 }'`

OS=`uname`
  if [ $OS = "Linux" ]; then
        OS=$(uname)
        OSVER=$(cat /etc/redhat-release)
        IPADD=$(ip route get 1.1.1.1 | grep src | awk '{ print $NF }')
        SUBNETMASK=$(ifconfig -a |grep $IPADD | awk '{ print $4 }' | cut -f2 -d:)
        HostIs="$(uname -n)"
        HostSerial="$(dmidecode -s system-serial-number | grep -v "^#")"
        HostModel="$( dmidecode -s system-product-name | grep -v "^#")"
        HostFware="$(dmidecode -s bios-version)"
        ProcType="$(dmidecode -s processor-family | grep -v Unknown | uniq | head -1)"
        ProcMode="NA"
        EC="NA"
        VCPUS="NA"
        TOTAL_MEM="$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')"
        MEM="$(expr $TOTAL_MEM / 1024)"
        SUDOVER="$(sudo -V 2> /dev/null | grep ^"Sudo version" | awk '{print $3}')"
        APPIS="$App"
        GPFS="NA"
        HACMP="NA"
        KERNEL="$(uname -r)"
  fi

# SSH Software and Its version.

OS=`uname`
        if [ $OS = "Linux" ]; then
        rpm -qa | grep -i ssh | grep -i server > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                        SSHPKG=`rpm -qa | grep -i ssh | grep -i server`
                        SSHSW=`rpm -qi $SSHPKG | egrep "Name|Version" | awk '{print $3}'`
                else
                        SSHSW="SSH Not Found"
                fi
        fi

#######################################################################################################
# VM Server
dmidecode -s system-product-name 2> /dev/null | grep -v "^#" | awk '{print $1}' | grep -v grep |grep VMware > /dev/null 2>&1
if [ $? -eq 0 ];	then
	VMServ="Yes"
	ls -ltr /usr/bin/vmware-toolbox-cmd > /dev/null 2>&1
	if [ $? -eq 0 ];	then
		VMVER=`/usr/bin/vmware-toolbox-cmd --version`
		VMVERSION="$VMVER"
	else
		VMVERSION="Not Installed"
	fi
	HostDR=`uname -n | cut -c4`
	if [ "$HostDR" = "r" ] || [ "$HostDR" = "R" ];	then
		if [ ! -d /etc/pprc ];	then
			mkdir -m 755 /etc/pprc/
			touch /etc/pprc/vmware
		else
			if [ ! -f /etc/pprc/vmware ];	then
					touch /etc/pprc/vmware
			fi
		fi
	fi
else
	VMServ="No"
	VMVERSION="N/A"
fi
#######################################################################################################
#Software Version
# VCS Version

rpm -qa | grep -i rpm -qa | grep VRTSvcs- > /dev/null 2>&1

if [ $? -eq 0 ]; then
        RPMVCS=`rpm -qa | grep -i rpm -qa | grep VRTSvcs-`
        VCSVER=`rpm -qi $RPMVCS | grep Version | awk '{print $3}'`
else
        VCSVER="NA"
fi

# MQM Version

rpm -qa | grep -i MQSeriesServer- > /dev/null 2>&1

if [ $? -eq 0 ]
        then
        RPMMQM=`rpm -qa | grep MQSeriesServer-`
        MQ=`rpm -qi $RPMMQM | grep Version | awk '{print $3}'`
        else
        MQ="NA"
fi


#######################################################################################################
#CD Version
      test -f /opt/cdunix/etc/cdver && CDVER=$(/opt/cdunix/etc/cdver|cut -d":" -f2|tr -s " "|cut -d" " -f5) || CDVER="NA"
      CDVER=${CDVER%,}
#########################################################################################
#WAS Software Version
WASFS=`df -T | grep WebSphere | awk '{print $6}' | sort -nr |head -1`
 if [ ! -z $WASFS ]
 then
        WASCMD=`find $WASFS -xdev -name versionInfo.sh | sort -rn | tail -1`
  if [ ! -z $WASCMD  ]
  then
        WAS=`$WASCMD|grep ^Version|grep -v Directory|tr -s " "|cut -d" " -f2|head -1`
  else
        WAS="NA"
   fi
 else
        WAS="NA"
 fi
#######################################################################################################
#IHS Software Version
IHSFS=$(df -k|grep -i IBMIHS|grep -v log|tr -s " "|cut -d" " -f6|head -1)
 if [ ! -z $IHSFS ]
 then
        IHSCMD=$(find $IHSFS -xdev -name versionInfo.sh -print|head -1)
   if [ ! -z $IHSCMD  ]
    then
        IHS=$($IHSCMD|grep ^Version|grep -v Directory|tr -s " "|cut -d" " -f2|tail -1)
    else
        IHS="NA"
   fi
 else
        IHS="NA"
 fi

echo "<tr><td BGCOLOR='D8D8D8' colspan=2><b>Version - Release Levels/applicable to:</b></td><td colspan=5> Linux 5.x, 6.x and 7.x version</td></tr>
<tr><td colspan=7><br></td></tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>SP Checklist V2.4(Script approved Month/Year: Apr 2017)</b></td></tr>
<tr><td colspan=7><br></td></tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>Servers General Information</b></td></tr>
<tr><td colspan=7>Application/Project Name: $App</td></tr>
<tr><td colspan=2>Host/Device Name: ${HostIs}</td>  <td colspan=2>IP Address(es): ${IPADD}</td>  <td colspan=4>Subnet mask(s): ${SUBNETMASK}</td>  </tr>
<tr><td colspan=2>Host/Device Serial: ${HostSerial}</td>  <td colspan=2> Server Model: ${HostModel}</td>  <td colspan=4> System Firmware: ${HostFware}</td>  </tr>
<tr><td colspan=2>Processor Type: ${ProcType}</td>  <td colspan=2> Processor Mode: ${ProcMode}</td>  <td colspan=4> Entitled Capacity: ${EC}</td>  </tr>
<tr><td colspan=2> Virtaul CPUS: ${VCPUS}</td>  <td colspan=2> Real Memory: ${MEM}</td> <td colspan=4> Kernel Level: ${KERNEL}</td> </tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>Software Version Information</b></td></tr>
<tr><td colspan=2>Operating System: $OS</td> <td colspan=2>OS Version/Service Pack: ${OSVER}</td> <td colspan=3> SSH Version : ${SSHSW} </td> </tr>
<tr><td colspan=2> VM Server (Yes/No) : ${VMServ} </td> <td colspan=2> VMTool Version : ${VMVERSION} </td> <td colspan=3>  </td> </tr>
<tr><td colspan=2> ConnectDirect : ${CDVER}</td>  <td colspan=2> IHS: ${IHS}</td>  <td colspan=3> WAS Version : ${WAS} </td>  </tr>
<tr><td colspan=2> HACMP Version: ${HACMP}</td>  <td colspan=2> Veritas Cluster services: ${VCSVER}</td>  <td colspan=3> GPFS Version : ${GPFS} </td>  </tr>
<tr><td colspan=2>SUDO Version : ${SUDOVER}</td> <td colspan=5> MQ Version : ${MQ}</td> </tr>
<tr BGCOLOR='D8D8D8'><td colspan=7><b>Document Notations</b></td></tr>
<tr><td colspan=7> StandardBuild/AutoChck : M - Manual, C - Candidate for automation, A - Automated </td>  </tr>
<tr><td colspan=7><br></td></tr>
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

#prtconf > $OUTDIR/prtconf.txt

DrawHtmlFileHead >> $HTMLLogFile

sysinfo >> $HTMLLogFile

######################### SECTION A START #######################

DrawSecHead " Section A. Linux Operating System Settings Verification" >> $HTMLLogFile

echo "$(date) : Linux Operating System Settings Verification"

####
DrawSubHead "1. General"  >>$HTMLLogFile
####

##########################################################################################################################
#A1
DescNo="A1"
DescItem="Hostname"
policy_reco="Hostname must be set in accordance with Naming Standard for Servers"
STDBLD="C"
AUTOCHK="A"
how_to="# uname -n"

HOSTS=`hostname | cut -c1-3` > /dev/null 2>&1
OSIS=$(uname)
HNAME=`uname -n`

if [ "$HOSTS" = "x01" ]
        then
        hostname | cut -c1-3 |grep 'x01' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Singapore Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Singapore Standard"
        fi
elif [ "$HOSTS" = "x03" ]
        then
        hostname | cut -c1-3 |grep 'x03' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Hong Kong Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Hong Kong standard"
        fi
elif [ "$HOSTS" = "x05" ]
        then
        hostname | cut -c1-3 |grep 'x05' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>China Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not China standard"
        fi
elif [ "$HOSTS" = "x06" ]
        then
        hostname | cut -c1-3 |grep 'x06' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>India Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not India standard"
        fi			
elif [ "$HOSTS" = "x07" ]
        then
        hostname | cut -c1-3 |grep 'x07' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Indonesia Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Indonesia standard"
        fi
elif [ "$HOSTS" = "x11" ]
        then
        hostname | cut -c1-3 |grep 'x11' > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
        violations="Compliant"
        VALUE="$HNAME<BR><BR>Taiwan Server"
        else
        violations="Non-Compliant"
        VALUE="$HNAME<BR><BR>Not Taiwan standard"
        fi		
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A2
DescNo="A2"
DescItem="IP Address & subnetmask"
policy_reco="Ensure the subnetmask is entered correctly"
STDBLD="C"
AUTOCHK="M"
how_to="# ifconfig"
SMASK=$(ifconfig -a |grep $IPADD | awk '{ print $4 }' | cut -f2 -d:)
SN1="255.255.255.248"
SN2="255.255.255.240"
SN3="255.255.255.224"
SN4="255.255.255.192"
SN5="255.255.255.128"
SN6="255.255.255.0"
SN7="255.255.254.0"
SN8="255.255.252.0"
if ([ "$SMASK" = "$SN1" ] || [ "$SMASK" = "$SN2" ] || [ "$SMASK" = "$SN3" ] || [ "$SMASK" = "$SN4" ] || [ "$SMASK" = "$SN5" ] || [ "$SMASK" = "$SN6" ] || [ "$SMASK" = "$SN7" ] || [ "$SMASK" = "$SN8" ])
   then
           violations="Compliant"
   else
           violations="Non-Compliant"
   fi

echo $IPADD >> $OUTDIR/ipsub.txt 2>&1
echo $SMASK >> $OUTDIR/ipsub.txt 2>&1
VALUE=`cat $OUTDIR/ipsub.txt`

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A3
DescNo="A3"
DescItem="hosts file configuration"
policy_reco="<u>/etc/hosts</u><br>127.0.0.1 localhost<br>hostname"
how_to="# cat /etc/hosts"
STDBLD="A"
AUTOCHK="A"

>$OUTDIR/nsresol.txt
if [ -f /etc/hosts ]
then
        cat /etc/hosts | grep ^127.0.0.1 > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
                violations="Compliant"
                        VALUE=$(cat /etc/hosts )
                        VALUE1=$(cat /etc/hosts | grep `hostname`)
                        else
                violations="Non-Compliant"
                        VALUE=$(cat /etc/hosts )
                        VALUE1=$(cat /etc/hosts | grep `hostname`)
                fi
else
    violations="Non-Compliant"
        VALUE="File Not FOUND"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE <br><br>$VALUE1</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# A4
DescNo="A4"
DescItem="DNS Resolve Configuration"
policy_reco="<u>SG /etc/resolv.conf</u><br>search dbs.com.sg sgp.dbs.com vsi.sgp.dbs.com<br>nameserver 10.80.114.8<br>nameserver 10.81.112.8<br><BR>or<BR>nameserver 10.67.1.58<br>nameserver 10.67.1.64<BR><BR>HK /etc/resolv.conf</u><br>nameserver 10.190.17.19<br>nameserver 10.190.17.20<br>nameserver 10.200.70.1<br>nameserver 10.190.96.3<br>nameserver 10.188.129.54<br>nameserver 10.190.129.7<BR><BR>TW /etc/resolv.conf</u><br>nameserver 10.231.114.225<br>nameserver 10.230.114.215<BR><BR>ID /etc/resolv.conf</u><br>search reg1.1bank.dbs.com<br>nameserver 10.232.74.10<br>nameserver 10.232.74.11<br>nameserver 10.232.70.52"
how_to="# cat /etc/resolv.conf"
STDBLD="A"
AUTOCHK="A"
HOSTS=`hostname | cut -c1-3` > /dev/null 2>&1

if [ "$HOSTS" = "x01" ];	then
    #RVER=`cat /etc/redhat-release  | awk '{print $(NF-1)}'| cut -d"." -f1`
    #if [ ${RVER} -eq 7 ];	then
	#	RESOLV=`egrep '^domain dbs.com.sg|^domain sgp.dbs.com|^search dbs.com.sg sgp.dbs.com|^nameserver 10.67.1.58|^nameserver 10.67.1.64' /etc/resolv.conf | wc -l`
	#else
	#	RESOLV=`egrep '^domain dbs.com.sg|^domain sgp.dbs.com|^search dbs.com.sg sgp.dbs.com|^nameserver 10.80.114.8|^nameserver 10.81.112.8' /etc/resolv.conf | wc -l`
	#fi
    #
    #if [ "$RESOLV" = "3" ]
    #then
    #        violations="Compliant"
    #        VALUE="`cat /etc/resolv.conf`"
    #        else
    #        violations="Non-Compliant"
    #        VALUE="`cat /etc/resolv.conf`"
    #fi
    D1=`egrep '^domain' /etc/resolv.conf | egrep 'dbs.com.sg' | wc -l`
    D2=`egrep '^domain' /etc/resolv.conf | egrep 'sgp.dbs.com'| wc -l`
    D3=`egrep '^domain' /etc/resolv.conf | egrep 'vsi.sgp.dbs.com'| wc -l`
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
	if [ $? -eq 0 ];	then
		how_to="# cat /etc/resolv.conf. This is OLD DNS migration in progress"
	fi
    violations="Compliant"
    VALUE="`cat /etc/resolv.conf`"
  else
    violations="Non-Compliant"
    VALUE="`cat /etc/resolv.conf`"
  fi
elif [ "$HOSTS" = "x03" ]
        then
        HOSTS1=`hostname | cut -c1-4 | tr [A-Z] [a-z]` > /dev/null 2>&1
        if [ "$HOSTS1" = "x03g" ];	then
        RESOLV=`egrep '^nameserver 10.190.17.19|^nameserver 10.190.17.20' /etc/resolv.conf | wc -l`
        if [ "$RESOLV" = "2" ];	then
                violations="Compliant"
                VALUE="`cat /etc/resolv.conf`"
                else
                violations="Non-Compliant"
                VALUE="`cat /etc/resolv.conf`"
        fi
		elif [ "$HOSTS1" = "x03r" ];	then
        RESOLV=`egrep '^nameserver 10.200.70.1|^nameserver 10.190.96.3' /etc/resolv.conf | wc -l`
        if [ "$RESOLV" = "2" ];	then
                violations="Compliant"
                VALUE="`cat /etc/resolv.conf`"
                else
                violations="Non-Compliant"
                VALUE="`cat /etc/resolv.conf`"
        fi
        else
        RESOLV=`egrep '^nameserver 10.188.129.54|^nameserver 10.190.17.20 |^nameserver 10.190.129.7' /etc/resolv.conf | wc -l`
        if [ "$RESOLV" = "2" ];	then
                violations="Compliant"
                VALUE="`cat /etc/resolv.conf`"
                else
                violations="Non-Compliant"
                VALUE="`cat /etc/resolv.conf`"
        fi        
        fi

elif [ "$HOSTS" = "x07" ]
        then
        RESOLV=`egrep 'reg1.1bank.dbs.com|^nameserver 10.232.74.10|^nameserver 10.232.74.11|^nameserver 10.232.70.52' /etc/resolv.conf | wc -l`
        #RESOLV=`egrep 'reg1.1bank.dbs.com|^nameserver 10.192.40.6|^nameserver 10.192.40.150' /etc/resolv.conf | wc -l`
        if [ "$RESOLV" = "4" ]
        then
                violations="Compliant"
                VALUE="`cat /etc/resolv.conf`"
                else
                violations="Non-Compliant"
               VALUE="`cat /etc/resolv.conf`"
        fi
elif [ "$HOSTS" = "x11" ]
        then
        RESOLV=`egrep '^nameserver 10.231.114.225|^nameserver 10.230.114.215' /etc/resolv.conf | wc -l`
        if [ "$RESOLV" = "2" ]
        then
                violations="Compliant"
                VALUE="`cat /etc/resolv.conf`"
                else
                violations="Non-Compliant"
               VALUE="`cat /etc/resolv.conf`"
        fi        

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A5
DescNo="A5"
DescItem="DNS switch Configuration"
policy_reco="<u>/etc/nsswitch.conf</u><br>hosts: files dns"
how_to="# cat /etc/nsswitch.conf"
STDBLD="A"
AUTOCHK="A"

if [ -f /etc/nsswitch.conf ]
then
NSW=`cat /etc/nsswitch.conf | grep -v ^# | grep hosts: | awk '{print $2 $3}'`
        if [ $NSW = filesdns ]
        then
                violations="Compliant"
                VALUE="$(cat /etc/nsswitch.conf | grep ^hosts)"
                else
                violations="Non-Compliant"
                VALUE="$(cat /etc/nsswitch.conf | grep ^hosts)"
        fi

else
                violations="Non-Compliant"
                VALUE="File Not FOUND"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# A6
DescNo="A6"
DescItem="System TimeZone"
policy_reco="Set TZ to SGT for Singapore Servers<BR><BR>Set TZ to HKT for Hong Kong Servers<BR><BR>Set TZ to WIB for Indonesia Servers"
how_to="# date"
STDBLD="A"
AUTOCHK="A"
HOSTS=hostname | cut -c1-3 > /dev/null 2>&1

if [ "$HOSTS" = "x01" ]
        then
        VALUE=$(date | awk '{print $5}')
        if [ $VALUE  = "SGT" ]
        then
        VALUE1="`date`"
        violations="Compliant"
        else
        VALUE1="`date`"
        violations="Non-Compliant"
        fi

elif [ "$HOSTS" = "x03" ]
        then
        VALUE=$(date | awk '{print $5}')
        if [ $VALUE  = "HKT" ]
        then
        VALUE1="`date`"
        violations="Compliant"
        else
        VALUE1="`date`"
        violations="Non-Compliant"
        fi

elif [ "$HOSTS" = "x07" ]
        then
        VALUE=$(date | awk '{print $5}')
        if [ $VALUE  = "WIB" ]
        then
        VALUE1="`date`"
        violations="Compliant"
        else
        VALUE1="`date`"
        violations="Non-Compliant"
        fi
elif [ "$HOSTS" = "x11" ]
        then
        VALUE=$(date | awk '{print $5}')
        if [ $VALUE  = "TAIST-8" ]
        then
        VALUE1="`date`"
        violations="Compliant"
        else
        VALUE1="`date`"
        violations="Non-Compliant"
        fi        
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE1</pre>" "$violations" >>$HTMLLogFile

# A7
DescNo="A7"
DescItem="NTP/CHRONY"
policy_reco="<u>/etc/ntp.conf or /etc/chrony.conf</u><br><u>SG </u>server 10.80.114.8<br>server 10.81.112.8<br>or<br>server 10.67.1.58<br>server 10.67.1.64<br><br><br><u>HK </u>server 10.190.2.23<br>server 10.190.98.21<br><br><u>TW </u>server 10.231.114.225<br>server 10.230.114.215<br><BR><u>CN </u> /etc/resolv.conf</u><br>nameserver 10.67.1.58<br>nameserver 10.67.1.64<br>server 10.67.1.64<br><BR><u>CN /etc/resolv.conf</u><br>server 10.67.1.58<br>server 10.67.1.64"
how_to="# cat /etc/ntp.conf"
STDBLD="A"
AUTOCHK="A"
OS=`uname`
if [ $OS = "Linux" ]; then
	if [ -f /etc/ntp.conf ] || [ -f /etc/chrony.conf ]; then
		ps -ef | grep -v grep | egrep "ntpd|chronyd"> /dev/null 2>&1
		if [ $? = 0 ]; then
			violations="Compliant"
			if [ -f "/etc/chrony.conf" ]; then
			VALUE=`cat /etc/chrony.conf | grep -v "#" | grep server`
			else
			VALUE=`cat /etc/ntp.conf | grep -v "#" | grep server`
			fi 
        else
			violations="Non-Compliant"
			if [ -f "/etc/chrony.conf" ]; then
			VALUE=`cat /etc/chrony.conf | grep -v "#" | grep server`
			else
			VALUE=`cat /etc/ntp.conf | grep -v "#" | grep server`
			fi 
        fi
	else
	VALUE="NTP Configuration file is Not Configured"
	violations="Non-Compliant"
	fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#A8
DescNo="A8"
DescItem="OS FileSystem Capacity"
#policy_reco="Make sure that the following file systems have the following minimum size <br><ul><li>14 GB   /</li><li>14GB  /var</li><li>4.5 GB  /home</li><li>2.5 GB  /tmp</li><li>9 GB  /opt</li><li>2GB  swap</li>"
how_to="# df -h"
STDBLD="A"
AUTOCHK="A"

cat << FSList >> $OUTDIR/FSList.txt
/ 14
/var 14
/home 4.5
/tmp 2.5
/opt 9
FSList
MCOUNT=`df -h /opt | wc -l`
if [ ${MCOUNT} -eq 2 ];	then
	OPTRC=`df -h /opt | awk '{print $2}' | grep -v Size | tr -d [A-Z] |awk '{ if ( $OPTSIZE == 6.8 ) print 0;else print 1}'`
elif [ ${MCOUNT} -eq 3 ];	then
	OPTRC=`df -h /opt | tail -1 | awk '{print $1}'| tr -d [A-Z] |awk '{ if ( $OPTSIZE == 6.8 ) print 0;else print 1}'`
fi
if [ ${OPTRC} -eq 0 ];	then
policy_reco="Make sure that the following file systems have the following minimum size <br><ul><li>14 GB   /</li><li>14GB  /var</li><li>4.5 GB  /home</li><li>2.5 GB  /tmp</li><li>6.8 GB  /opt</li><li>2 GB  swap</li>"
cat << LFSList >> $OUTDIR/LFSList.txt
/ 14
/var 14
/home 4.5
/tmp 2
/opt 6.8
LFSList
else
policy_reco="Make sure that the following file systems have the following minimum size <br><ul><li>14 GB   /</li><li>14GB  /var</li><li>4.5 GB  /home</li><li>2.5 GB  /tmp</li><li>9 GB  /opt</li><li>2.5 GB  swap</li>"
cat << LFSList >> $OUTDIR/LFSList.txt
/ 14
/var 14
/home 4.5
/tmp 2.5
/opt 9
LFSList
fi

> $OUTDIR/dfCurcap.txt

OS=`uname`
  if [ $OS = "Linux" ]; then
        cat $OUTDIR/LFSList.txt | while read FS SIZE
        do
        CurCap=$(df -Ph $FS |grep -v Filesystem |awk '{ print $2 }'| sed 's/G//')
        #[ "$CurCap" -lt $SIZE ] && echo "$FS size is $CurCap" >> $OUTDIR/dfCurcap.txt
        ST=`echo "$CurCap < $SIZE" | bc`
        [ $ST -eq 1 ] && echo "$FS size is $CurCap" >> $OUTDIR/dfCurcap.txt
        done

        HowMany=$(cat $OUTDIR/dfCurcap.txt | wc -l)
                if [ $HowMany -eq 0 ]
                then
                        violations="Compliant"
                        VALUE="$(cat $OUTDIR/LFSList.txt)"
                else
                        violations="Non-Compliant"
                        VALUE="$(cat $OUTDIR/dfCurcap.txt)"
                fi
  fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile
# A9
DescNo="A9"
DescItem="Swap Space"
policy_reco="SWAP File System Details"
how_to="# swap"
STDBLD="A"
AUTOCHK="A"

LIXSWMDDEV=`swapon -s | grep -v Size | awk '{print $1}'`
LIXSWMDDEVSIZE=`free -m | grep Swap | awk '{print $2}'`

SWAPSIZE=`free -m | grep 'Swap:' | awk '{print $2}'`

if [ "$SWAPSIZE" -gt "2040" ]
        then

         VALUE="SWAP Device: $LIXSWMDDEV and SWAP Size: $LIXSWMDDEVSIZE MB"
         violations="Compliant"

else
         VALUE="SWAP Device: $LIXSWMDDEV and SWAP Size: $LIXSWMDDEVSIZE MB"
         violations="Non-Compliant"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# A10
DescNo="A10"
DescItem="Syslog Notification"
policy_reco="Ensure necessary alert notification configured for syslog."
STDBLD="A"
AUTOCHK="A"

DescItem="Syslog notification Configuration"
policy_reco="Ensure necessary alert notification configured for syslog"
how_to="# cat /etc/syslog.conf"

if [ -f /etc/syslog.conf ]
then
        OS=`uname`
        if [ $OS = "Linux" ]; then
          grep "*.info;mail.none;authpriv.none;cron.none[[:space:]]*/var/log/messages" /etc/syslog.conf | grep -v \# > /dev/null 2>&1;RC1=$?
          if [ $? -eq 0 ]; then
          violations="Compliant"
          VALUE=`grep "/var/log/messages" /etc/syslog.conf`
          else
          violations="Non-Compliant"
          VALUE="Missing Syslog configuration"
          fi
        fi
else
         violations="Non-Compliant"
         VALUE="FILE_NOT_FOUND"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A11
DescNo="A11"
DescItem="Disabled Services in /etc/services"
policy_reco="Checking ftp, tftp and telnet services"
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/services"

if [ -f /etc/services ]
then
        cat /etc/services | grep -v "#" | egrep "^ftp$|^tftp$|^telnet$" > /dev/null 2>&1
                if [ $? -eq 1 ]
                then
                violations="Compliant"
                        VALUE="FTP, TFTP and Telnet services are disabled"
                        else
                violations="Non-Compliant"
                        VALUE="Check FTP, TFTP and Telnet services and disable"
                fi
else
    violations="Non-Compliant"
        VALUE="File Not FOUND"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


DescNo="A12"
DescItem="User Primary Login Prompt"
policy_reco="Configure the prompt to show user id, @ symbol, server name, : symbol , current directory, space and # symbol (for root user) or $ symbol (for non-root user)."
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/bashrc | grep PS1"

cat /etc/bashrc | grep "PS1=" > /dev/null2>&1;RC=$?

if [ $RC  -eq 0 ]
        then
        violations="Compliant"
        VALUE="PS1=[\u@\h \W]\\$"

        else
        violations="Non-Compliant"
        VALUE="echo $PS1"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile



# A13
DescNo="A13"
DescItem="Standard Cronjob"
policy_reco="Ensure required cron for URT check."
STDBLD="C"
AUTOCHK="A"
how_to="# crontab -l | grep collect_urt.sh"

        OS=`uname`
        if [ $OS = "Linux" ]; then
          crontab -l 2> /dev/null| grep -v "^#" | grep /harden/collect_urt.sh > /dev/null 2>&1
          if [ $? -eq 0 ]; then
          violations="Compliant"
          VALUE=`crontab -l 2> /dev/null | grep -v "^#" | grep /harden/collect_urt.sh`
          else
          violations="Non-Compliant"
          VALUE="Cron is not enabled for URT"
          fi
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# A14
DescNo="A14"
DescItem="Standard Cronjob"
policy_reco="Ensure required cron for vmstat collection."
STDBLD="C"
AUTOCHK="A"
how_to="# crontab -l | grep collect.sh"

        OS=`uname`dd
        if [ $OS = "SunOS" ]; then
          crontab -l 2> /dev/null | grep -v "^#" | grep /harden/collect.sh > /dev/null 2>&1
          if [ $? -eq 0 ]; then
          violations="Compliant"
          VALUE=`crontab -l 2> /dev/null | grep -v "^#" | grep /harden/collect.sh`
          else
          violations="Non-Compliant"
          VALUE="Cron is not enabled for vmstat"
          fi
        elif [ $OS = "Linux" ]; then
          crontab -l 2> /dev/null | grep -v "^#" | grep /harden/collect.sh > /dev/null 2>&1
          if [ $? -eq 0 ]; then
          violations="Compliant"
          VALUE=`crontab -l 2> /dev/null | grep -v "^#" | grep /harden/collect.sh`
          else
          violations="Non-Compliant"
          VALUE="Cron is not enabled for vmstat"
          fi
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# A15
DescNo="A15"
DescItem="Standard Cronjob"
policy_reco="Ensure required cron for SSH ISCD weekly collection."
STDBLD="C"
AUTOCHK="A"
how_to="# crontab -l |grep iscd_redhat_ssh.sh"

        OS=`uname`
        if [ $OS = "Linux" ]; then
          crontab -l 2> /dev/null | grep -v "^#" | grep iscd_redhat_ssh.sh > /dev/null 2>&1
          if [ $? -eq 0 ]; then
          violations="Compliant"
          VALUE=`crontab -l  2> /dev/null| grep -v "#" | grep iscd_redhat_ssh.sh`
          else
          violations="Non-Compliant"
          VALUE="Cron is not enabled for SSH ISCD weekly report"
          fi
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#####################################################################################################################
# A16
DescNo="A16"
DescItem="Standard Cronjob"
policy_reco="Ensure required cron for INVENSYS Colllector and Health Check script."
STDBLD="C"
AUTOCHK="A"
how_to="# crontab -l |egrep 'linux_collector.sh|Invensys_Collector_Cron.sh|invensysCron_Linux.sh|invensysHCCron_LINUX.sh|Invensys_HealthCheck_Cron.sh' "

        OS=`uname`
        if [ $OS = "Linux" ]; then
          crontab -l 2> /dev/null | grep -v "^#" | egrep '/home/dbsinvs/invensysCron_Linux.sh|/home/dbsinvs/Invensys_Collector_Cron.sh|/home/dbsinvs/linux_collector.sh' > /dev/null 2>&1; FRC1=$?
          crontab -l 2> /dev/null | grep -v "^#" | egrep "/home/dbsinvs/invensysHCCron_LINUX.sh|/home/dbsinvs/Invensys_HealthCheck_Cron.sh" > /dev/null 2>&1 ;FRC2=$?
          ((RC=$FRC1+$FRC2))
          if [ $RC -eq 0 ]; then
          violations="Compliant"
          VALUE=`crontab -l 2> /dev/null | grep -v "^#" | grep -i 'dbsinvs'`
          else
          violations="Non-Compliant"
          VALUE="Cron is not enabled for INVENSYS"
          fi
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# A17
DescNo="A17"
DescItem="Standard Cronjob"
policy_reco="Ensure required cron for sosreport are set."
STDBLD="C"
AUTOCHK="A"
how_to="# crontab -l | grep -i sosreport"

                if [ -f /usr/sbin/sosreport ]
                then
                violations="Compliant"
                echo "# To Collect sosreport ###" > $OUTDIR/sosreport.out
                echo "0 21 13,28 * * /harden/sosreport.sh" >> $OUTDIR/sosreport.out
                echo " ">> $OUTDIR/sosreport.out
                echo "`ls -ltr /usr/sbin/sosreport`" >> $OUTDIR/sosreport.out
                VALUE=`cat $OUTDIR/sosreport.out`
                else
                violations="Non-Compliant"
                fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# 18
DescNo="A18"
DescItem="VMTools Version / Service"
policy_reco="Ensure vmtool is at recommended level and service is running"
STDBLD="C"
AUTOCHK="A"
how_to="# vmware-toolbox-cmd --version; # ps -efw | grep vmtoolsd"

dmidecode -s system-product-name 2> /dev/null | grep -v "^#" | awk '{print $1}' | grep VMware > /dev/null 2>&1
if [ $? -eq 0 ];	then
	Verchk=`/usr/bin/vmware-toolbox-cmd --version | cut -d"." -f1`
	MCOUNT=`df -h /opt | wc -l`
	if [ ${MCOUNT} -eq 2 ];	then
		OPTRC=`df -h /opt | awk '{print $2}' | grep -v Size | tr -d [A-Z] |awk '{ if ( $OPTSIZE == 6.8 ) print 0;else print 1}'`
	elif [ ${MCOUNT} -eq 3 ];	then
		OPTRC=`df -h /opt | tail -1 | awk '{print $1}'| tr -d [A-Z] |awk '{ if ( $OPTSIZE == 6.8 ) print 0;else print 1}'`
	fi
	if [ ${OPTRC} -eq 0 ];	then
		if [ "$Verchk" -lt "9" ];	then
			violations="Non-Compliant"
			VALUE="Version is below 10<BR>`/usr/bin/vmware-toolbox-cmd --version`"
			VALUE1=""
		else
			ps -efw | grep -v grep | grep vmtoolsd  > /dev/null 2>&1
			if [ $? -eq 0 ];	then
				violations="Compliant"
				VALUE=`ps -efw | grep vmtoolsd | grep -v grep`
				VALUE1=`/usr/bin/vmware-toolbox-cmd --version`
			else
				violations="Non-Compliant"
				VALUE=`ps -efw | grep vmtoolsd | grep -v grep`
				VALUE1=`/usr/bin/vmware-toolbox-cmd --version`
			fi			
		fi
	else
		if [ "$Verchk" -lt "10" ];	then
			violations="Non-Compliant"
			VALUE="Version is below 10<BR>`/usr/bin/vmware-toolbox-cmd --version`"
		else
			ps -efw | grep -v grep | grep vmtoolsd  > /dev/null 2>&1
			if [ $? -eq 0 ];	then
				violations="Compliant"
				VALUE=`ps -efw | grep vmtoolsd | grep -v grep`
				VALUE1=`/usr/bin/vmware-toolbox-cmd --version`
			else
				violations="Non-Compliant"
				VALUE=`ps -efw | grep vmtoolsd | grep -v grep`
				VALUE1=`/usr/bin/vmware-toolbox-cmd --version`
			fi	
		fi	
	fi
else
	violations="NA"
	VALUE="Not Applicable for Physical Server"
	VALUE1=""
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE<br>$VALUE1</pre>" "$violations" >>$HTMLLogFile

#A19
DescNo="A19"
DescItem="OS Patch"
policy_reco="Ensure OS Patch is at recommended level"
STDBLD="M"
AUTOCHK="M"
how_to="# uname -a"
violations="Manual Check"
VALUE=`uname -a`

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#A19
DescNo="A20"
DescItem="Sudo Configuration"
policy_reco="Public key of sudoadm id is exchanged with sudomaster (Ops Centre) for latest sudoers file copied."
how_to="# sudo -V"
STDBLD="C"
AUTOCHK="A"

>$OUTDIR/sudoinfo.txt
sudo -V 2> /dev/null | grep "Sudo version" >> $OUTDIR/sudoinfo.txt 2>&1;RC1=$?
visudo -c >> $OUTDIR/sudoinfo.txt 2>&1;RC2=$?
echo "Current CheckSum :$(cksum /etc/sudoers)" >> $OUTDIR/sudoinfo.txt   2>&1;RC3=$?
ls -l /etc/sudoers >> $OUTDIR/sudoinfo.txt  2>&1;RC4=$?

#OS=`uname`
#if [ $OS = "Linux" ]; then
#        if [ -d /home/sudoadm/.ssh2 ]
#        then
#
#                if [ -f /home/sudoadm/.ssh2/sudoadmT.pub -a -f /home/sudoadm/.ssh2/authorization ]
#                then
#
#                cat /home/sudoadm/.ssh2/authorization | grep sudoadmT.pub > /dev/null 2>&1;RC=$?
#
#                        if [ $RC -eq 0 ]
#                        then
#
#                        #cat /home/sudoadm/.ssh2/authorization | grep sudoadmT.pub >> $OUTDIR/sudoinfo.txt 2>&1
#                        violations="Compliant"
#                        #VALUE="PublicKey Authentication Enabled"
#                        VALUE=""
#                        RC4=0
#
#                        else
#
#                        violations="Non-Compliant"
#                        #VALUE="PublicKey Authentication Not Found"
#                        VALUE=""
#                        RC4=1
#
#                        fi
#
#                else
#          violations="Non-Compliant"
#          VALUE="PublicKey Authentication Not Found"
#                  RC4=1
#
#                fi
#
#        else
#
#          violations="Non-Compliant"
#      VALUE="PublicKey Authentication Not Found"
#          RC4=1
#        fi
#        echo "$VALUE" >> $OUTDIR/sudoinfo.txt 2>&1
#
#fi

((RC=$RC1+$RC2+$RC3+$RC4))

if [ $RC -eq 0 ];	then
	violations="Compliant"
	VALUE="<ol>$(cat $OUTDIR/sudoinfo.txt | sed -e 's/^/<li>/g' -e 's/$/<\/li>/g')</ol>"
	else
	violations="Non-Compliant"
	VALUE="<ol>$(cat $OUTDIR/sudoinfo.txt | sed -e 's/^/<li>/g' -e 's/$/<\/li>/g')</ol>"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

################################################### SECTION C START ########################

####
DrawSubHead "1. SCSI boot (This following steps are applicable only when local SCSI boot is used)"  >>$HTMLLogFile
####
# ROOTVG MIRRORING

######
DrawSubHead "4. STORAGE"  >>$HTMLLogFile
######
#A21
DescNo="A21"
STDBLD="A"
AUTOCHK="A"
how_to="# pkginfo or #rpm -qa "
DescItem="MultiPath Software"
policy_reco="Ensure Proper Multipath software Installed - Linux (device-mapper-multipath)"

OS=`uname`
if [ $OS = "Linux" ]; then
VMWAREVER=`dmidecode -s system-product-name | grep -v "^#" | awk '{print $1}'`
if [ $VMWAREVER = "VMware" ] || [ $VMWAREVER = "VMware7,1" ]
then
VALUE="NA for Linux Virtual Machine"
violations="NA"
else
rpm -qa | grep -i device-mapper-multipath > /dev/null 2>&1;RC1=$?
if [ $RC1 -eq 0 ]; then
 violations="Compliant"
 VALUE=`rpm -qa | grep -i device-mapper-multipath`
 else
 violations="NA"
 VALUE="NA. device-mapper-multipath is not installed"
 fi
 fi
 fi


DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

DescNo="A22"
STDBLD="C"
AUTOCHK="A"
how_to="# Multipath"
DescItem="SAN PATHS"
policy_reco="For SAN attached servers, ensure that all LUNS are dual path and all SAN disks paths are available state."

OS=`uname`

 if [ $OS = "Linux" ]
then
     if [ ! -f "/etc/disk/nosan" ];	then
     SAN=`ls -l /dev/disk/by-path| grep fc | grep -vi part`
     if [ ! -z "$SAN" ]
     then
       if [ -x /sbin/vxdmpadm ]
       then
         CTLRNAME=`/sbin/vxdmpadm listctlr all | egrep -i 'ibm|emc' | awk '{print $1}'`
            for ctlr in $CTLRNAME
            do
              CONSTATE=`/sbin/vxdmpadm listctlr all | grep $ctlr | awk '{print $3}'`
              if [ $CONSTATE != "ENABLED" ]
               then
                VALUE="VERITAS: Controller $ctlr is Not Enabled Multi-Path!!"
                 violations="Non-Compliant"
                elif [ $CONSTATE = "ENABLED" ]
                 then
                    VALUE="VERITAS: Controller $ctlr is Enabled Multi-Path"
                    violations="Compliant"
              fi
             done
         else
             MPXIODSK=`ls -l /dev/mapper | grep mpath`
          if [ ! -z "$MPXIODSK" ]
          then
              MPXIODSK=`ls -l /dev/mapper/ | grep mpath | tail -1 | awk '{print $9}'`
              TOTALPATH=`/sbin/multipath -ll $MPXIODSK 2> /dev/null | sed '1,3d' | awk '{print $3}'| wc -l` 
#            for dev in $MPXDEV
#   do
#   ls -l /sys/block/*/device | grep $dev | awk '{print $11}' | cut -f7 -d'/' >> lixfchost
#   done
# TOTALPATH=`cat lixfchost 2> /dev/null| wc -l`
   if [ $TOTALPATH -ge 2 ]; then
    VALUE="MPATH Device is running on Multiple Path"
    violations="Compliant"
    else
    VALUE="MPATH Device is Not running on Multiple Path"
    violations="Non-Compliant"
   fi
  else
  VALUE="No Multi Path device configured"
  violations="Non-Compliant"
 fi
         fi
     fi
fi

# IBM SDD Devices
 if [ -x /opt/IBMsdd/bin/datapath ];then
        ADAPTER=`/opt/IBMsdd/bin/datapath query adapter |grep -w Adapters |awk -F: '{print $2}'`
        ACTIVE=`/opt/IBMsdd/bin/datapath query adapter |grep -w ACTIVE  |wc -l`
        DEG=`/opt/IBMsdd/bin/datapath query adapter |grep -w DEGRAD  |wc -l`
         if [ $ADAPTER -gt 1 ]; then
          if [ $ACTIVE -lt $ADAPTER ]; then
          VALUE="IBMSDD: SAN is Not Active all Path!!"
          echo "IBMSDD: Server has $ADAPTER but the path is Active on $ACTIVE Path only" >> $OUTDIR/san.lst
          violations="Non-Compliant"
          fi
          if [ $DEG -gt 0 ]; then
           VALUE="IBMSDD: Server has $ADAPTER Adapter and $DEG adapter DEGRADED"
           violations="Non-Compliant"
          fi
         VALUE="IBMSDD: Server has $ADAPTER and $ACTIVE path"
         violations="Compliant"
         else
         VALUE="IBMSDD: SAN is Running on Single Adapter"
         violations="Non-Compliant"
         fi
 fi
# EMC Devices
 if [ -x /etc/powermt ]; then
   EMCDEV=`ls -lrt /dev/dsk/emcpower* |awk '{print $9}' | sort -n | head -1 | cut -f4 -d'/'`
   if test ! -z $EMCDEV
    then
    EMCRDSK=`/etc/powermt display dev=$EMCDEV | grep -v "=" | egrep -vi 'Host|Path' | head -1 | awk '{print $3}'`
        #finding WWN for EMC Device
        luxadm display /dev/rdsk/$EMCRDSK | grep "Host controller port WWN" | awk '{print $5}' | uniq >> $OUTDIR/emcwwn.lst
        # SAN Path Count check
        SANPATH=`luxadm display /dev/rdsk/$EMCRDSK | grep "Host controller port WWN" | awk '{print $5}' | uniq | wc -l`
          if [ $SANPATH -ge 2 ]; then
          VALUE="EMC SAN: Connected to more than 2 WWN Path"
          violations="Compliant"
        for wwn in `cat $OUTDIR/emcwwn.lst`
        do
        fcinfo hba-port -l $wwn | grep State | awk '{print $2}' >> $OUTDIR/emcwwnstat.lst
        done
        EMCONLINE=`grep online $OUTDIR/emcwwnstat.lst | wc -l`
         if [ $EMCONLINE -ge 2 ]; then
         VALUE="EMC SAN: is Online $EMCONLINE paths"
         violations="Compliant"
         else
         VALUE="EMC SAN is not having 2 Paths, $EMCONLINE online"
         violations="Non-Compliant"
         fi
           else
           VALUE="EMC SAN is Connected Multipath"
           violations="Non-Compliant"
       fi
        else
        echo "No EMC PowerPath device configured" >> $OUTDIR/san.lst
        fi
 fi
# Check for MPXIO
 MPXIODSK=`ls -lrt /dev/dsk 2> /dev/null| grep scsi_vhci`
 if test ! -z "$MPXIODSK"
 then
 MPXIODSK=`ls -lrt /dev/dsk | grep scsi_vhci | tail -1 | awk '{print $9}' | cut -f1 -d 's' | cut -f1 -d 'p'`
 TOTALPATH=`/usr/sbin/mpathadm list LU /dev/rdsk/${MPXIODSK}s2 | grep Total | awk '{print $NF}'`
  if [ $TOTALPATH -ge 2 ]; then
  VALUE="MPXIO Device is running on Multiple Path"
  violations="Compliant"
  ACTPATH=`/usr/sbin/mpathadm list LU /dev/rdsk/${MPXIODSK}s2 | grep Operational | awk '{print $NF}'`
  if [ $ACTPATH -lt 2 ]; then
   VALUE="MPXIO Device is running on Single Operational Path"
   violations="Non-Compliant"
  else
   VALUE="MPXIO Device is running on Multiple Operational Path"
   violations="Compliant"
  fi
 else
  VALUE="MPXIO Device is running on Single Path"
  violations="Non-Compliant"
  fi
else
   VALUE="NO SAN DISK"
   violations="NA"
 fi
fi
# Non-SAN

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

DescNo="A23"
STDBLD="C"
AUTOCHK="A"
how_to="# cat hostname_pprc.cfg "
DescItem="PPRC Configuration file details"
policy_reco="Display PPRC Configuration file details"

HostDR=`uname -n | cut -c4`

if [ "$HostDR" = "r" ] || [ "$HostDR" = "R" ]
        then
           VMWAREVER=`dmidecode -s system-product-name | grep -v "^#" | awk '{print $1}'`
           if [ $VMWAREVER = "VMware" ] || [ $VMWAREVER = "VMware7,1" ]
           then
            violations="NA"
            VALUE1=" "
            VALUE="NA for Linux Virtual Machine"
        else
	  if [ ! -f "/etc/pprc/nosan" ];	then
          ls -ld /usr/local/sysmaint/script/ > /dev/null 2>&1
          if [ $? -eq 0 ]; then
                ls -l /usr/local/sysmaint/script/`hostname`_pprc.cfg > /dev/null 2>&1
                R1COUNT=`awk '/^#SOURCE/,/^$/ { print }' /usr/local/sysmaint/script/`uname -n`_pprc.cfg|wc -l`
                R1COUNT=`expr $R1COUNT - 1`
                R2COUNT=`sudo /sysmaint/script/dspprc `uname -n` query |awk '$0~/^=/,/^=$/ { print }'|grep -i "Full Duplex" | wc -l`
                if [ $? -eq 0 ]; then
                        violations="Compliant"
                        VALUE="$(cat /usr/local/sysmaint/script/`hostname`_pprc.cfg)"
                        VALUE1="$R1COUNT=$R2COUNT"

                else
                        violations="Non-Compliant"
                        VALUE="No PPRC configuration file found"
                        VALUE1=" "
                fi
          else
                violations="Non-Compliant"
                VALUE="sysmaint directory is not found"
                VALUE1=" "
          fi
	else
	violations="NA"
	VALUE="No San DISK"
	fi
	fi

else
    violations="NA"
    VALUE1=" "
    VALUE="NOT A DR NODE"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE<br>$VALUE1</pre>" "$violations" >>$HTMLLogFile


#
DescNo="A24"
STDBLD="C"
AUTOCHK="A"
how_to="# cat hostname_flash.cfg "
DescItem="Flash Configuration file details"
policy_reco="Display Flash Configuration file details"

HostDR=`uname -n | cut -c4`

if [ "$HostDR" = "r" ] || [ "$HostDR" = "R" ]
         then
        OS=`uname`
        if [ $OS = "Linux" ]; then
       VMWAREVER=`dmidecode -s system-product-name | grep -v "^#" | awk '{print $1}'`
      if [ $VMWAREVER = "VMware" ] || [ $VMWAREVER = "VMware7,1" ]
      then
      violations="NA"
        VALUE="NA for Linux Virtual Machine"
      else
	if [ ! -f "/etc/pprc/nosan" ];        then
          ls -ld /usr/local/sysmaint/script/ > /dev/null 2>&1
          if [ $? -eq 0 ]; then
                ls -l /usr/local/sysmaint/script/`hostname`_flash.cfg > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                        violations="Compliant"
                        VALUE="$(cat /usr/local/sysmaint/script/`hostname`_flash.cfg)"
                else
                        violations="Non-Compliant"
                        VALUE="No Flash configuration file found"
                fi
          else
                violations="Non-Compliant"
                VALUE="sysmaint directory is not found"
          fi
	else
         violations="NA"
         VALUE="No San DISK"
        fi

        fi

else
    violations="NA"
    VALUE="NOT A DR NODE"
 fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile
# FLASH-PPRC
DescNo="A25"
STDBLD="C"
AUTOCHK="A"
DescItem="FLASH-PPRC Scripts scheduled in cron job"
policy_reco="Ensure PPRC-FLASH Scripts configured"
how_to="# crontab -l | grep sysmaint | grep -v "#""

HostDR=`uname -n | cut -c4`

if [ "$HostDR" = "r" ] || [ "$HostDR" = "R" ]
        then
        OS=`uname`
        if [ $OS = "Linux" ]; then
       VMWAREVER=`dmidecode -s system-product-name | grep -v "^#" | awk '{print $1}'`
       if [ $VMWAREVER = "VMware" ] || [ $VMWAREVER = "VMware7,1" ]
        then
          VALUE="NA for Linux Virtual Machine"
        VALUE1=" "
          violations="NA"
        else
	 if [ ! -f "/etc/pprc/nosan" ];        then 
          ls -ld /usr/local/sysmaint/script/ > /dev/null 2>&1
          if [ $? -eq 0 ]; then
                crontab -l 2> /dev/null | grep -v "^#" | grep sysmaint > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                        violations="Compliant"
                        VALUE="$(crontab -l 2> /dev/null | grep -v "^#" | grep sysmaint)"
                        R1COUNT=`awk '/^#SOURCE/,/^$/ { print }' /usr/local/sysmaint/script/`uname -n`_pprc.cfg|wc -l`
                    R1COUNT=`expr $R1COUNT - 1`
                    R2COUNT=`sudo /sysmaint/script/dspprc `uname -n` query |awk '$0~/^=/,/^=$/ { print }'|grep -i "Full Duplex" | wc -l`
                        VALUE1="$R1COUNT=$R2COUNT"
                else
                        violations="Non-Compliant"
                        VALUE="No cron schedule for PPRC or Flash"
                        VALUE1=" "
                fi
          else
                violations="Non-Compliant"
                VALUE="sysmaint directory is not found"
                VALUE1=" "
          fi
	else
	 violations="NA"
         VALUE="No San DISK"
        fi
        fi

else
    violations="NA"
    VALUE="NOT A DR NODE"
        VALUE1=" "
 fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE<br>$VALUE1</pre>" "$violations" >>$HTMLLogFile


###################
########################### IP FORWARDING
######
DrawSubHead "4. NETWORK"  >>$HTMLLogFile
######
#
DescNo="A26"
DescItem="Adapter speed / duplex mode"
policy_reco="Auto-negotiable"
STDBLD="A"
AUTOCHK="A"
how_to="Check speed, duplex, IPMP/BONING"

OS=`uname`


VMWAREVER=`dmidecode -s system-product-name | grep -v "^#" | awk '{print $1}'`
if [ $VMWAREVER = "VMware" ] || [ $VMWAREVER = "VMware7,1" ]
        then
        echo "NA for Linux Virtual Machine" > $OUTDIR/nic.lst
        violations="NA"
else
        i=0
        j=""
        while true
        do
        ethtool eth$i > /dev/null 2> /dev/null
        k=$? && [ $k -ne 0 ] && break
        j="$j eth$i"
        i=`expr $i + 1`
        done

        echo $j > $OUTDIR/interface

        # To check bonding
        [ -d "/proc/net/bonding/" ] && BOND=`ls -1 /proc/net/bonding/*`
        if [ ! -z "$BOND" ];    then
          BONDDEVICE=`ls -1 /proc/net/bonding/* | cut -d"/" -f5`
          for bond in $BONDDEVICE
          do
          echo "Configuration and Status of Bond Devices:" >> $OUTDIR/nic.lst
            BONDIP=`ifconfig $bond |grep -i "inet addr" |awk '{print $2}'|cut -d":" -f2`
                BONDSUBN=`ifconfig $bond |grep -i "inet addr" |awk '{print $4}'|cut -d":" -f2`
                BONDNIC=`cat /proc/net/bonding/$bond | grep "Slave Interface" | awk {'print $3'}`
                BONDNICCOUNT=`cat /proc/net/bonding/$bond | grep "Slave Interface" | wc -l`
                BONDMODE=`cat /proc/net/bonding/$bond | grep "Bonding Mode" | cut -f2 -d:`
                  echo Bond Name: $bond >> $OUTDIR/nic.lst
                  echo IP Address: $BONDIP >> $OUTDIR/nic.lst
                  echo Subnet Mask: $BONDSUBN >> $OUTDIR/nic.lst
                  echo Bond NICs: $BONDNIC >> $OUTDIR/nic.lst
                  echo Number of NICs in the Bond: $BONDNIC >> $OUTDIR/nic.lst
                  echo Bond Mode: $BONDMODE >> $OUTDIR/nic.lst
                  echo " " >> $OUTDIR/nic.lst
                  echo NIC Details in the Bond: >> $OUTDIR/nic.lst
                  for bnic in $BONDNIC
                   do
                    STAT=`ifconfig $bnic | awk '/MTU/ {print $1}'`
                    if [ $STAT = UP ]; then
                    BNICSTATUS=UP
                        BNICLINK=`/sbin/ethtool $bnic| grep "Link" |cut -d":" -f2| tr -d ' '`
                        BNICSPEED=`/sbin/ethtool $bnic| grep -i "Speed" |cut -d":" -f2| tr -d ' '`
                        BNICMODE=`/sbin/ethtool $bnic| grep -i "Duplex" |cut -d":" -f2| tr -d ' '`
                        BNICMTU=`ifconfig $bnic | awk '/MTU/ {print $6}'| cut -d":" -f2`
                         echo Status: $bnic is $BNICSTATUS >> $OUTDIR/nic.lst
                         echo Link: $BNICLINK >> $OUTDIR/nic.lst
                         echo Speed: $BNICSPEED >> $OUTDIR/nic.lst
                         echo Duplex: $BNICMODE >> $OUTDIR/nic.lst
                         echo MTU: $BNICMTU >> $OUTDIR/nic.lst
                         echo ". . . . ." >> $OUTDIR/nic.lst
                         violations="Manual"
                        else
                         echo Status: $bnic is Down!! >> $OUTDIR/nic.lst
                         echo ". . . . ." >> $OUTDIR/nic.lst
                         violations="Manual"
                        fi
                   done
                   echo " " >> $OUTDIR/nic.lst
          done
                #echo Non-Bonding NIC configuration details: >> $OUTDIR/nic.lst
                echo NIC Configuration Details for Non-Bond: >> $OUTDIR/nic.lst
                # Standalone NIC Configuration
                # excluding Bond NIC from standalone check
                #BONDNIC=`cat /proc/net/bonding/$bond | grep "Slave Interface" | awk {'print $3'}`
                #NONBONDNIC=`cat $OUTDIR/interface | grep -v $BONDNIC`
                 for nbnic in `cat $OUTDIR/interface`
                 do
                  ifconfig $nbnic | grep SLAVE > /dev/null 2>&1
                  if [ $? = 1 ]; then
                 NBSTAT=`ifconfig $nbnic | awk '/MTU/ {print $1}'`
                  if [ $NBSTAT = UP ]; then
                    NBNICSTATUS=UP
                        NBNICIP=`ifconfig $nbnic |grep -i "inet addr" |awk '{print $2}'|cut -d":" -f2`
                    NBNICSUBN=`ifconfig $nbnic |grep -i "inet addr" |awk '{print $4}'|cut -d":" -f2`
                    NBNICLINK=`/sbin/ethtool $nbnic| grep "Link" |cut -d":" -f2| tr -d ' '`
                        NBNICSPEED=`/sbin/ethtool $nbnic| grep -i "Speed" |cut -d":" -f2| tr -d ' '`
                        NBNICMODE=`/sbin/ethtool $nbnic| grep -i "Duplex" |cut -d":" -f2| tr -d ' '`
                        NBNICMTU=`ifconfig $nbnic | awk '/MTU/ {print $5}'| cut -d":" -f2`
                         #echo NIC Configuration Details for Non-Bond: >> $OUTDIR/nic.lst
                         echo NIC: $nbnic >> $OUTDIR/nic.lst
                         echo Status: $NBNICSTATUS >> $OUTDIR/nic.lst
                         echo IP Address: $NBNICIP >> $OUTDIR/nic.lst
                         echo Subnet Mask: $NBNICSUBN >> $OUTDIR/nic.lst
                         echo Link: $NBNICLINK >> $OUTDIR/nic.lst
                         echo Speed: $NBNICSPEED >> $OUTDIR/nic.lst
                         echo Duplex: $NBNICMODE >> $OUTDIR/nic.lst
                         echo MTU: $NBNICMTU >> $OUTDIR/nic.lst
                         echo ". . . . ." >> $OUTDIR/nic.lst
                     violations="Manual"
                        else
                         echo $nbnic is Down!! >> $OUTDIR/nic.lst
                         echo ". . . . ." >> $OUTDIR/nic.lst
                         violations="Manual"
                  fi
                  fi
                 done
                 echo " " >> $OUTDIR/nic.lst
        else
                # Servers without Bonding
                echo No Bonding Configured on this Server!! >> $OUTDIR/nic.lst
                echo " " >> $OUTDIR/nic.lst
                echo NIC Configuration Details for Non-Bond: >> $OUTDIR/nic.lst
                # Standalone NIC Configuration
                 for nbnic in `cat $OUTDIR/interface`
                 do
                 NBSTAT=`ifconfig $nbnic | awk '/MTU/ {print $1}'`
                  if [ $NBSTAT = UP ]; then
                    NBNICSTATUS=UP
                        NBNICIP=`ifconfig $nbnic |grep -i "inet addr" |awk '{print $2}'|cut -d":" -f2`
                    NBNICSUBN=`ifconfig $nbnic |grep -i "inet addr" |awk '{print $4}'|cut -d":" -f2`
                    NBNICLINK=`/sbin/ethtool $nbnic| grep "Link" |cut -d":" -f2| tr -d ' '`
                        NBNICSPEED=`/sbin/ethtool $nbnic| grep -i "Speed" |cut -d":" -f2| tr -d ' '`
                        NBNICMODE=`/sbin/ethtool $nbnic| grep -i "Duplex" |cut -d":" -f2| tr -d ' '`
                        NBNICMTU=`ifconfig $nbnic | awk '/MTU/ {print $5}'| cut -d":" -f2`
                         #echo NIC Configuration Details for Non-Bond: >> $OUTDIR/nic.lst
                         echo NIC: $nbnic >> $OUTDIR/nic.lst
                         echo Status: $NBNICSTATUS >> $OUTDIR/nic.lst
                         echo IP Address: $NBNICIP >> $OUTDIR/nic.lst
                         echo Subnet Mask: $NBNICSUBN >> $OUTDIR/nic.lst
                         echo Link: $NBNICLINK >> $OUTDIR/nic.lst
                         echo Speed: $NBNICSPEED >> $OUTDIR/nic.lst
                         echo Duplex: $NBNICMODE >> $OUTDIR/nic.lst
                         echo MTU: $NBNICMTU >> $OUTDIR/nic.lst
                         echo ". . . . ." >> $OUTDIR/nic.lst
                     violations="Manual"
                        else
                         echo $nbnic is Down!! >> $OUTDIR/nic.lst
                         echo ". . . . ." >> $OUTDIR/nic.lst
                         violations="Manual"
                  fi
                 done
    fi
fi
VALUE=`cat $OUTDIR/nic.lst`
#DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>`cat $OUTDIR/nic.lst`</pre>" "$violations" >>$HTMLLogFile


########################### ENT RFC VALUE

##########################################################################

DrawSecHead " Section B. Standard system software" >> $HTMLLogFile

echo "$(date) : Standard system software Verification "

##########################################################################################################################
#
DescNo="B1"
DescItem="Infra Softwares "
policy_reco="Ensure TSM software is installed."
STDBLD="C"
AUTOCHK="A"
how_to="# rpm -qa --last TIVsm*"

ENVM=`uname -n | cut -c4`

if [ -e /etc/tsm/DMZ ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ -e /etc/tsm/GRID ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ "$ENVM" = "t" ] || [ "$ENVM" = "T" ] || [ "$ENVM" = "D" ] || [ "$ENVM" = "d" ] || [ "$ENVM" = "B" ] || [ "$ENVM" = "b" ]
        then
        VALUE="TSM is not required for Development servers"
        violations="NA"

elif [ -d /opt/tivoli/tsm/client/ba/bin ]
        then
        violations="Compliant"
        PKG=`rpm -qa | grep -i TIVsm-BA`
        VERSION=`rpm -qi $PKG | grep Version | awk '{print $3}'`
        VALUE="$PKG installed $VERSION"

elif [ ! -d /opt/tivoli/tsm/client/ba/bin ]
        then
        violations="Non-Compliant"
        VALUE="TSM not installed"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B2"
DescItem="Infra Softwares "
policy_reco="Ensure Tripwire software is installed."
STDBLD="A"
AUTOCHK="A"
how_to="# rpm -qa TWeagent-*"

ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ]
        then
          violations="N/A"
          VALUE="Tripwire is not required for Development servers"
else
          rpm -qa | grep -i TWeagent- > /dev/null 2>&1;RC1=$?
          if [ $RC1 -eq 0 ]; then
          violations="Compliant"
          PKG=`rpm -qa | grep -i TWeagent-`
          VERSION=`rpm -qi $PKG | grep Version | awk '{print $3}'`
          VALUE="$PKG installed $VERSION"
          else
          violations="Non-Compliant"
          VALUE="Tripwire is not installed"
          fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


DescNo="B3"
DescItem="Infra Softwares "
policy_reco="Ensure TAD4D software is installed."
STDBLD="A"
AUTOCHK="A"
how_to="# Installation path check"

          ls -l /var/itlm/tlmagent.bin > /dev/null 2>&1;RC1=$?
          if [ $RC1 -eq 0 ]; then
          violations="Compliant"
          PKG="TAD4D"
          VERSION=`/var/itlm/tlmagent -v | grep version`
          VALUE="$PKG installed $VERSION"
          else
          violations="Non-Compliant"
          VALUE="TAD4D is not installed"
          fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

DescNo="B4"
DescItem="Infra Softwares "
policy_reco="Ensure SSH software is installed."
STDBLD="A"
AUTOCHK="A"
how_to="# rpm -qa *ssh*"
        OS=`uname`
        if [ $OS = "Linux" ]; then
          rpm -qa | grep -i ssh | grep -i server > /dev/null 2>&1;RC1=$?
          if [ $RC1 -eq 0 ]; then
          violations="Compliant"
          PKG=`rpm -qa | grep -i ssh | grep -i server`
          VERSION=`rpm -qi $PKG | grep Version | awk '{print $3}'`
          VALUE="$PKG installed $VERSION"
          else
          violations="Non-Compliant"
          VALUE="SSH is not installed"
          fi
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B5"
DescItem="Infra Softwares "
policy_reco="Ensure ITM software is installed."
STDBLD="A"
AUTOCHK="A"
how_to="# cinfo -r | grep 'Installer Lvl'"
ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ]
        then
          violations="N/A"
          VALUE="ITM is not required for Development servers"
else

        if [ -f /opt/IBM/ITM/bin/cinfo ]
        then
        ITM=`/opt/IBM/ITM/bin/cinfo -i | grep 'Installer Lvl' | cut -f3 -d':'`
        violations="Compliant"
        elif [ -f /IBM/itm/bin/cinfo ]
        then
        ITM=`/IBM/itm/bin/cinfo -i | grep 'Installer Lvl' | cut -f3 -d':'`
        violations="Compliant"
        elif [ ! -f /opt/IBM/ITM/bin/cinfo ] && [ ! -f /IBM/itm/bin/cinfo ]
        then
        ITM="Not Installed"
        violations="Non-Compliant"
        fi

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>ITM Version $ITM</pre>" "$violations" >>$HTMLLogFile

DescNo="B6"
DescItem="Infra Softwares "
policy_reco="Ensure Lumension software is installed."
STDBLD="A"
AUTOCHK="A"
how_to="# /usr/local/patchagent/patchservice info | grep 'AgentVer'"

          if [ -d /usr/local/patchagent ]; then
          violations="Compliant"
          PKG="Lumension"
          VERSION=`cat /usr/local/patchagent/update.conf | grep AgentVer | cut -f2 -d'"'`
          VALUE="$PKG installed $VERSION"
          else
          violations="Non-Compliant"
          VALUE="Lumension is not installed"
          fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# SCSP
DescNo="B7"
DescItem="Infra Softwares "
policy_reco="Ensure SCSP/SCDS software is installed."
STDBLD="A"
AUTOCHK="A"
how_to="# ./sisipsconfig.sh -v | grep version"

ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ] || [ "$ENVM" = "x01s" ] || [ "$ENVM" = "X01S" ]
        then
          violations="N/A"
          VALUE="SCSP is not required for Development servers"
else
          ps -ef |grep -v grep |grep scsp  > /dev/null 2>&1;RC1=$?
          ps -ef |grep -v grep |grep sdcs > /dev/null 2>&1;RC2=$?
          if ([ $RC1 -eq 0 ] || [ $RC2 -eq 0 ]); then
          violations="Compliant"
        SCSP=`rpm -qa | grep -E "SYMCcsp|SYMCsdcss" | cut -f2-3 -d'-' | tail -1`
		SCSPB=`rpm -qa | grep -E "SYMCcsp|SYMCsdcss" | tail -1`
		SCSPL=`rpm -qi SYMCsdcss-6.5.0-355.x86_64 | grep -i Relocations | awk '{print $NF}'`
          VALUE="$SCSP is installed"
          else
          violations="Non-Compliant"
          VALUE="SCSP is not installed"
          fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#####
DrawSubHead "1. ISCD - Hardware monitoring"  >>$HTMLLogFile
DescNo="B8"
DescItem="SSH ISCD"
policy_reco="Harden the SSH server according to T&O-TS-ISS Linux Hardening Checklist published on http://dbsnet.dbs.com.sg/to/grouptechnologyservices/html/ref.html"
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /harden/iscd_redhat_ssh.sh"

ls -l /harden/iscd_redhat_ssh.sh > /dev/null 2>&1

if [ $? -eq 0 ]
        then
        VALUE="`ls -ltr /harden/iscd_redhat_ssh.sh 2> /dev/null| awk '{print $1,$NF}'`"
        violations="Compliant"
        else
        VALUE="`ls -ltr /harden/iscd_redhat_ssh.sh 2> /dev/null | awk '{print $1,$NF}'`"
        violations="Non-Applicable"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


##################

DrawSubHead "2. Tectia SSH - Shell access / file transfer"  >>$HTMLLogFile
DescNo="B9"
DescItem="SSH Service Startup/Shutdown"
policy_reco="Ensure that Tectia SSH has a rc startup/shutdown script"
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* and ls -l /etc/rc*.d/K*"

        ls -l /etc/rc*.d/S* | grep -i ssh > /dev/null 2>&1;RC1=$?
        ls -l /etc/rc*.d/K* | grep -i ssh > /dev/null 2>&1;RC2=$?

        ((RC=$RC1+$RC2))

        if [ $RC -eq 0 ]
        then
                                violations="Compliant"
                        VALUE=`ls -l /etc/rc*.d/S* | grep -i ssh;  ls -l /etc/rc*.d/K* | grep -i ssh`
                        else
                        violations="Non-Compliant"
                        VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##################

DrawSubHead "3. ITM - Server monitoring" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B10"
DescItem="ITM Service Startup/Shutdown"
policy_reco="Ensure that ITM has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* and ls -l /etc/rc*.d/K*"

ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ]
        then
          violations="N/A"
          VALUE="ITM is not required for Development servers"
else

        ls -l /etc/rc*.d/S* | grep -i itm > /dev/null 2>&1;RC1=$?
        ls -l /etc/rc*.d/K* | grep -i itm > /dev/null 2>&1;RC2=$?

        ((RC=$RC1+$RC2))

        if [ $RC -eq 0 ]
        then
        violations="Compliant"
        VALUE=`ls -l /etc/rc*.d/S* | grep -i itm;  ls -l /etc/rc*.d/K* | grep -i itm`
        else
        violations="Non-Compliant"
        VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
fi


DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###########

#####
DrawSubHead "4. TSM - Backup " >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B11"
DescItem="TSM Service Startup/Shutdown"
policy_reco="Ensure that TSM has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* and ls -l /etc/rc*.d/K*"

ENVM=`uname -n | cut -c4`

if [ -e /etc/tsm/DMZ ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ -e /etc/tsm/GRID ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ "$ENVM" = "t" ] || [ "$ENVM" = "T" ] || [ "$ENVM" = "D" ] || [ "$ENVM" = "d" ] || [ "$ENVM" = "B" ] || [ "$ENVM" = "b" ]
        then
        VALUE="TSM is not required for Development servers"
        violations="NA"

elif [ -d /opt/tivoli/tsm/client/ba/bin ]
        then
        ls -l /etc/rc*.d/S* | egrep -i "tsm|dsmc" > /dev/null 2>&1;RC1=$?
        ls -l /etc/rc*.d/K* | egrep -i "tsm|dsmc" > /dev/null 2>&1;RC2=$?
        ((RC=$RC1+$RC2))
        if [ $RC -eq 0 ]
        then
                violations="Compliant"
                VALUE=`ls -l /etc/rc*.d/S* | egrep -i "tsm|dsmc";  ls -l /etc/rc*.d/K* | egrep -i "tsm|dsmc"`
        else
                violations="Non-Compliant"
                VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi

elif [ ! -d /opt/tivoli/tsm/client/ba/bin ]
        then
        violations="Non-Compliant"
        VALUE="TSM not installed"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B12"
DescItem="TSM Binary Location and version"
policy_reco="TSM Installation location and version"
STDBLD="C"
AUTOCHK="A"
how_to="# ls -ld /opt/tivoli/tsm/client"

ENVM=`uname -n | cut -c4`

if [ -e /etc/tsm/DMZ ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ -e /etc/tsm/GRID ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ "$ENVM" = "t" ] || [ "$ENVM" = "T" ] || [ "$ENVM" = "D" ] || [ "$ENVM" = "d" ] || [ "$ENVM" = "B" ] || [ "$ENVM" = "b" ]
        then
        VALUE="TSM is not required for Development servers"
        violations="NA"

elif [ -d /opt/tivoli/tsm/client ]
        then
        violations="Compliant"
        VALUE=`ls -ld /opt/tivoli/tsm/client`

elif [ ! -d /opt/tivoli/tsm/client ]
        then
        violations="Non-Compliant"
        VALUE="TSM not installed"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B13"
DescItem="TSM Backup VLAN"
policy_reco="Ensure that TSM uses dedicated backup VLAN instead of public VLAN."
STDBLD="C"
AUTOCHK="M"
how_to="# ifconfig -a"

ENVM=`uname -n | cut -c4`

if [ -e /etc/tsm/DMZ ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ -e /etc/tsm/GRID ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ "$ENVM" = "t" ] || [ "$ENVM" = "T" ] || [ "$ENVM" = "D" ] || [ "$ENVM" = "d" ] || [ "$ENVM" = "B" ] || [ "$ENVM" = "b" ]
        then
        VALUE="TSM is not required for Development servers"
        violations="NA"

elif [ -e /opt/tivoli/tsm/client/ba/bin/dsm.sys  ]
        then
		cat /opt/tivoli/tsm/client/ba/bin/dsm.sys | grep -i TCPCLIENTADDRESS | egrep "10|192|172" > /dev/null 2>&1;TSM=`echo $?`
		if [ $TSM -eq 0 ];	then
			TSMIP=`cat /opt/tivoli/tsm/client/ba/bin/dsm.sys | grep -i TCPCLIENTADDRESS | awk '{print $2}' | head -1`
		else
			TSMHN=`cat /opt/tivoli/tsm/client/ba/bin/dsm.sys | grep -i TCPCLIENTADDRESS | awk '{print $2}' | head -1`
			TSMIP=`nslookup $TSMHN | tail -2| grep Address | cut -f2 -d":" -d " "`
		fi
        #TSMIP=`cat /opt/tivoli/tsm/client/ba/bin/dsm.sys | grep -i TCPCLIENTADDRESS | awk '{print $2}' | head -1 | tr -d "\r"`
        ls -ltr /etc/sysconfig/network-scripts/ifcfg-e* | awk '{print $9}' > $OUTDIR/tsmnic.out
        for each in `cat $OUTDIR/tsmnic.out`
                do
                grep $TSMIP $each > /dev/null 2>&1
                        if [ $? -eq 0 ]
                                then
                                TSMNIC=`basename $each | cut -f2 -d"-"`
                                ifconfig $TSMNIC | egrep -v "RX|TX|txq" >> $OUTDIR/tsmnicip.lst
                                echo ------------------------- >> $OUTDIR/tsmnicip.lst
                        fi
        done

        if [ -e $OUTDIR/tsmnicip.lst ]
                then
                        violations="Compliant"
                        VALUE=`cat $OUTDIR/tsmnicip.lst`
                else
                violations="Non-Compliant"
                VALUE="TSM Backup VLAN not configured"
        fi

elif [ ! -e /opt/tivoli/tsm/client/ba/bin/dsm.sys ]
        then
        violations="Non-Compliant"
        VALUE="TSM not installed"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B14"
DescItem="TSM Backup VLAN Ping"
policy_reco="Ensure TSM Master Server IP is able ping."
STDBLD="C"
AUTOCHK="A"
how_to="# ping MASTERIP"

ENVM=`uname -n | cut -c4`

if [ -e /etc/tsm/DMZ ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ -e /etc/tsm/GRID ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ "$ENVM" = "t" ] || [ "$ENVM" = "T" ] || [ "$ENVM" = "D" ] || [ "$ENVM" = "d" ] || [ "$ENVM" = "B" ] || [ "$ENVM" = "b" ]
        then
        VALUE="TSM is not required for Development servers"
        violations="NA"

elif [ -e /opt/tivoli/tsm/client/ba/bin/dsm.sys  ]
        then
        TSMIP=`cat /opt/tivoli/tsm/client/ba/bin/dsm.sys | grep -i TCPServeraddress | awk '{print $2}' | head -1`
                ping -c 3 $TSMIP > $OUTDIR/tsmsvrping.lst

                if [ $? -eq 0 ]
                then
                echo " " >> $OUTDIR/tsmsvrping.lst
                echo "=========Trace Route (INFO)===========" >> $OUTDIR/tsmsvrping.lst
                traceroute $TSMIP 2> /dev/null >> $OUTDIR/tsmsvrping.lst
                VALUE=`cat $OUTDIR/tsmsvrping.lst`
                violations="Compliant"
                else
                VALUE="TCPServeraddress IP is not configured"
                violations="Non-Compliant"
                fi

elif [ ! -e /opt/tivoli/tsm/client/ba/bin/dsm.sys ]
        then
        violations="Non-Compliant"
        VALUE="dsm.sys file is not found"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B15"
DescItem="TSM Backup - dsm.sys configuration"
policy_reco="Validate the TSM dsm.sys"
STDBLD="C"
AUTOCHK="A"
how_to="# cat /opt/tivoli/tsm/client/ba/bin/dsm.sys | grep -v ^*"

ENVM=`uname -n | cut -c4`

if [ -e /etc/tsm/DMZ ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ -e /etc/tsm/GRID ]
        then
        VALUE="Compute Node server does not required backup"
        violations="NA"

elif [ "$ENVM" = "t" ] || [ "$ENVM" = "T" ] || [ "$ENVM" = "D" ] || [ "$ENVM" = "d" ] || [ "$ENVM" = "B" ] || [ "$ENVM" = "b" ]
        then
        VALUE="TSM is not required for Development servers"
        violations="NA"

elif [ -e /opt/tivoli/tsm/client/ba/bin/dsm.sys  ]
        then
        VALUE=`cat /opt/tivoli/tsm/client/ba/bin/dsm.sys | grep -v ^*`
        violations="MANUAL"

elif [ ! -e /opt/tivoli/tsm/client/ba/bin/dsm.sys ]
        then
        violations="Non-Compliant"
        VALUE="dsm.sys file is not found"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########

##################
DrawSubHead "5. TAD4d - Asset discovery"  >>$HTMLLogFile

DescNo="B16"
DescItem="TAD4d Startup/Shutdown"
policy_reco="Ensure that TAD4d has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* and ls -l /etc/rc*.d/K*"

        ls -l /etc/rc*.d/S* | grep -i tlm > /dev/null 2>&1;RC1=$?
        ls -l /etc/rc*.d/K* | grep -i tlm > /dev/null 2>&1;RC2=$?

        ((RC=$RC1+$RC2))

        if [ $RC -eq 0 ]
        then
                                violations="Compliant"
                        VALUE=`ls -l /etc/rc*.d/S* | grep -i tlm;  ls -l /etc/rc*.d/K* | grep -i tlm`
                        else
                        violations="Non-Compliant"
                        VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
# TLM
DescNo="B17"
STDBLD="A"
AUTOCHK="A"
DescItem="TAD4D Agent Heartbeat Status"
policy_reco="Ensure TAD4D TLM Service running"
how_to="# ps -ef | grep tlmagent"

ps -ef |grep -i tlmagent | grep -v grep > /dev/null 2>&1
        if [ $? -eq 0 ]
        then

                VALUE="TAD4D/TLM Agent is running"
                VALUE1=`ps -ef |grep -i tlmagent | grep -v grep`
                violations="Compliant"
        else

                VALUE="TAD4D/TLM Agent is Not running"
                VALUE1=" "
                violations="Non-Compliant"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE<br>$VALUE1</pre>" "$violations" >>$HTMLLogFile

# TLM
DescNo="B18"
STDBLD="A"
AUTOCHK="A"
DescItem="TAD4D Agent Version and Connectivity Status"
policy_reco="Display TAD4D version and status"
how_to=""

#ps -ef |grep -i tlmagent | grep -v grep > /dev/null 2>&1
        if [ -x /var/itlm/tlmagent ]
        then

                echo " " >> $OUTDIR/tad4d-version.lst
                echo "# /var/itlm/tlmagent -p" >> $OUTDIR/tad4d-version.lst
                /var/itlm/tlmagent -p >> $OUTDIR/tad4d-version.lst
                echo " " >> $OUTDIR/tad4d-version.lst
                echo "================================" >> $OUTDIR/tad4d-version.lst
                echo "# /var/itlm/tlmagent -v" >> $OUTDIR/tad4d-version.lst
                /var/itlm/tlmagent -v >> $OUTDIR/tad4d-version.lst
                VALUE=`cat $OUTDIR/tad4d-version.lst`
                violations="Compliant"
        else

                VALUE="TAD4D/TLM tlmagent is found"
                violations="Non-Compliant"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

####
DescNo="B19"
DescItem="TAD4D configuration Parameter in tlmagent.ini"
policy_reco="Validate agentid and server details in tlmagent.ini"
STDBLD="A"
AUTOCHK="A"
how_to="# cat /etc/tlmagent.ini | grep -v ^# | egrep -i agentid|server"

if [ -d /var/itlm ]
then
        if [ -s /etc/tlmagent.ini ]; then
        VALUE=`cat /etc/tlmagent.ini | grep -v ^# | egrep -i "agentid|server"`
        violations="Compliant"

        else

        VALUE="tlmagent.ini FILE NOT FOUND"
        violations="Non-Compliant"

        fi
else

        VALUE="TAD4D Installation PATH NOT FOUND"
        violations="Non-Compliant"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#


##################

DrawSubHead "6. Lumension Patchlink - Patch management"  >>$HTMLLogFile

##########################################################################################################################
#
DescNo="B20"
DescItem="LUMENSION Startup/Shutdown"
policy_reco="Ensure that LUMENSION has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* and ls -l /etc/rc*.d/K*"

        ls -l /etc/rc*.d/S* | grep -i patchagent > /dev/null 2>&1;RC1=$?
        ls -l /etc/rc*.d/K* | grep -i patchagent > /dev/null 2>&1;RC2=$?

        ((RC=$RC1+$RC2))

        if [ $RC -eq 0 ]
        then
                                violations="Compliant"
                        VALUE=`ls -l /etc/rc*.d/S* | grep -i patchagent;  ls -l /etc/rc*.d/K* | grep -i patchagent`
                        else
                        violations="Non-Compliant"
                        VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

######################

DrawSubHead "7. SCSP - Intrusion detection"  >>$HTMLLogFile

##########################################################################################################################
# SCSP
DescNo="B21"
DescItem="SCSP/SCDS Service Startup"
policy_reco="Ensure that SCSP/SCDS has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* and ls -l /etc/rc*.d/K*"

ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ] || [ "$ENVM" = "x01s" ] || [ "$ENVM" = "X01S" ]
        then
          violations="N/A"
          VALUE="SCSP is not required for Development servers"
          VALUE1=" "
else
        ls -l /etc/rc*.d/S* | grep -i sisi > /dev/null 2>&1;RC1=$?
        ls -l /etc/rc*.d/K* | grep -i sisi > /dev/null 2>&1;RC2=$?

        ((RC=$RC1+$RC2))

        if [ $RC -eq 0 ]
        then
        violations="Compliant"
        VALUE=`ls -l /etc/rc*.d/S* | grep -i sisi;  ls -l /etc/rc*.d/K* | grep -i sisi`
        else
        violations="Non-Compliant"
        VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
        fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


##############################
DrawSubHead "8. Tripwire Enterprise - Compliance check"  >>$HTMLLogFile


##########################################################################################################################
#
DescNo="B22"
DescItem="TRIPWIRE Service Startup"
policy_reco="Ensure that Tripwire Enterprise has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* and ls -l /etc/rc*.d/K* or svcs -a teagent"

ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ]
        then
          violations="N/A"
          VALUE="Tripwire is not required for Development servers"
else
                ls -l /etc/rc*.d/S* | grep -i twdaemon > /dev/null 2>&1;RC1=$?
                ls -l /etc/rc*.d/K* | grep -i twdaemon > /dev/null 2>&1;RC2=$?

                ((RC=$RC1+$RC2))

                        if [ $RC -eq 0 ]
                        then
                                violations="Compliant"
                        VALUE=`ls -l /etc/rc*.d/S* | grep -i twdaemon;  ls -l /etc/rc*.d/K* | grep -i twdaemon`
                        else
                        violations="Non-Compliant"
                        VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
                        fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#####################

################
DrawSecHead " Optional system software" >> $HTMLLogFile

echo "$(date) : Optional system software Verification "

DrawSubHead "1. TWS (This following steps are applicable only when TWS is installed)"  >>$HTMLLogFile

DescNo="B23"
DescItem="TWS Service Startup"
policy_reco="Ensure that TWS has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S* "

df -k /opt/maestro > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then

        ls -l /etc/rc*.d/S* | grep -i tws > /dev/null 2>&1;RC1=$?

        if [ $? -eq 0 ]
        then
                                violations="Compliant"
                        VALUE=`ls -l /etc/rc*.d/S* | grep -i tws`
                        else
                        violations="Non-Compliant"
                        VALUE="Start script DOES NOT EXIST"
        fi

else

  violations="NA"
  VALUE="TWS NOT INSTALLED"
  VALIS="NOTWS"

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


##################

######

##################

DrawSubHead "2. VCS (This following steps are applicable only when VCS is installed)"  >>$HTMLLogFile

DescNo="B24"
DescItem="VCS Start/Stop Scripts"
policy_reco="Ensure that VCS has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*/S*"

ps -ef | grep -v grep | grep -i '/opt/VRTSvcs/bin/had' > /dev/null 2>&1

if [ $? -eq 0 ]
        then
        ps -ef | grep -v grep | grep -i '/opt/VRTSvcs/bin/had' | grep onenode > /dev/null 2>&1
        if [ $? -eq 0 ]; then
        VCSVALUE="VCS service is for AppHA"
        ls -l /etc/rc*.d/S* | grep -i vcs > /dev/null 2>&1
        if [ $? -eq 0 ]; then
        ls -l /etc/rc*.d/K* | grep -i vcs > /dev/null 2>&1
        if [ $? -eq 0 ]; then
        VALUE="Startup & Shutdown script found<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
        violations="Compliant"
        else
        VALUE="Missing Shutdown script<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
        violations="Non-Compliant"
        fi
        else
        VALUE="Missing startup script<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
        violations="Non-Compliant"
        fi
        else
        VCSVALUE="VCS service is for cluster server"
        ls -l /etc/rc*.d/S* | grep -i vcs > /dev/null 2>&1
        if [ $? -eq 0 ]; then
        ls -l /etc/rc*.d/K* | grep -i vcs > /dev/null 2>&1
        if [ $? -eq 0 ]; then
        VALUE="Startup & Shutdown script found<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
        violations="Compliant"
        else
        VALUE="Missing Shutdown script<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
        violations="Non-Compliant"
        fi
        else
        VALUE="Missing startup script<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
        violations="Non-Compliant"
        fi
        fi
else
        violations="NA"
        VALUE="VCS IS NOT RUNNING ON THIS SERVER"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VCSVALUE<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#####################################################################################################################
DescNo="B25"
DescItem="VCS HA FAILOVER"
policy_reco="Ensure that VCS groups are online, license status, heartbeat status and ITM monitoring for VCS log."
STDBLD="A"
AUTOCHK="A"
how_to="# hagrp -state, vxlicrep, lltstat, engine log monitoring "

ps -ef | grep -v grep | grep -i /opt/VRTSvcs/bin/had > /dev/null

if [ $? -eq 0 ]; then
        ps -ef | grep -v grep | grep -i '/opt/VRTSvcs/bin/had -onenode' > /dev/null
        if [ $? -eq 0 ]
        then
                violations="NA"
                VALUE="VCS service is for AppHA"
        else
        vxlicrep | grep -i "License Type" | uniq | grep DEMO > /dev/null 2>&1
        if [ $? -eq 0 ]; then
                echo "NON-Compliance - License is DEMO" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst
                else
                echo "License Type: PERMANENT" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst
        fi

        HEARTBEAT=`lltstat -n | awk '{print $NF}' | egrep -v "information|Links" | head -1`
        if [ $HEARTBEAT -lt 3 ]; then
                echo "NON-Compliance - Heartbeat are less than 3" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst
                else
                echo "Heartbeat Count: $HEARTBEAT" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst
        fi

        ITMPATH=`ps -ef | grep -v grep | grep -i itm | awk '{print $8}' | head -1 | cut -f2 -d/`
        HNAME=`hostname`
        ITMCONF=`find /$ITMPATH -name $HNAME.conf`
        [ -z "$ITMCONF" ] && ITMCONF="NA"
        if [ $ITMCONF = NA ]; then
                echo "NON-Compliance - ITM Log file monitoring for VCS is not enabled" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst
                else
                cat $ITMCONF | grep engine_A.log
                if [ $? -eq 1 ]; then
                        echo "NON-Compliance - ITM Log file monitoring for VCS is not enabled" >> $OUTDIR/vcsstatus.lst
                        echo " " >> $OUTDIR/vcsstatus.lst
                        else
                        echo "ITM Log Monitoring: Enabled" >> $OUTDIR/vcsstatus.lst
                        echo " " >> $OUTDIR/vcsstatus.lst
                fi
        fi


        cat $ITMCONF | grep engine_A.log
        if [ $? -eq 1 ]; then
                echo "NON-Compliance - ITM Log file monitoring for VCS is not enabled" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst
                else
                echo "ITM Log Monitoring: Enabled" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst
        fi

        CLUSTERID=`lltstat -C`
        echo "Cluster ID: $CLUSTERID" >> $OUTDIR/vcsstatus.lst
                echo " " >> $OUTDIR/vcsstatus.lst

        grep NON-Compliance $OUTDIR/vcsstatus.lst > /dev/null 2>&1
        if [ $? -eq 0 ]; then
                violations="Non-Compliant"
                VALUE=`cat $OUTDIR/vcsstatus.lst`

                else
                violations="Compliant"
                VALUE=`cat $OUTDIR/vcsstatus.lst`
        fi
        fi
else
        violations="NA"
        VALUE="VCS IS NOT RUNNING ON THIS SERVER"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#####################################
DrawSecHead " Section C. Optional middleware" >> $HTMLLogFile

echo "$(date) : Optional middleware Verification "

DrawSubHead "1. MQ (This following steps are applicable only when MQ is installed)"  >>$HTMLLogFile

##########################################################################################################################
#
DescNo="C1"
DescItem="MQ Start/Stop Scritps"
policy_reco="Ensure that MQ has a rc startup/shutdown script."
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d"

rpm -qa --last | grep MQSeriesServer > /dev/null 2>&1

if [ $? -eq 0 ]
then
        /opt/mqm/bin/dspmq | grep Running > /dev/null 2>&1
        if [ $? -eq 0 ]
                then
                ls -l /etc/rc*.d/S* | grep -i mq > /dev/null 2>&1;RC1=$?
                ls -l /etc/rc*.d/K* | grep -i mq > /dev/null 2>&1;RC2=$?
                ((RC=$RC1+$RC2))

                        if [ $RC -eq 0 ]
                        then
                                violations="Compliant"
                        VALUE=`ls -l /etc/rc*.d/S* | grep -i mq;  ls -l /etc/rc*.d/K* | grep -i mq`
                        else
                        violations="Non-Compliant"
                        VALUE="Start/Stop script DOES NOT EXIST -OR- MUST BE IN BOTH STARTUP/SHUTDOWN"
                        fi
        fi
else
        violations="NA"
        VALUE="MQ IS NOT RUNNING ON THIS SERVER"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
DescNo="C2"
DescItem="MQ Binary location"
policy_reco="Ensure that MQ files are place on separate filesystem /var/mqm"
STDBLD="A"
AUTOCHK="A"
how_to="# df -k "

rpm -qa --last | grep MQSeriesServer > /dev/null 2>&1

if [ $? -eq 0 ]
then
        /opt/mqm/bin/dspmq | grep Running > /dev/null 2>&1

        if [ $? -eq 0 ]
        then
        df -k /var/mqm | grep var > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                 violations="Compliant"
                 VALUE="MQ installed in separate /var/mqm file system"

                else
                violations="Non-Compliant"
                VALUE="MQ Not installed in separate /var/mqm file system"
                fi
        fi
else

  violations="NA"
  VALUE="MQ NOT INSTALLED"
fi


DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

###############################
DrawSubHead "2. WAS (This following steps are applicable only when WAS is installed)"  >>$HTMLLogFile
#
DescNo="C3C3"
DescItem="WAS Start/Stop Scripts"
policy_reco="Ensure WAS has rc StartupShutdown scripts"
STDBLD="A"
AUTOCHK="A"
how_to="# ls -l /etc/rc*.d/S*"

ps -ef | grep -v grep | grep "/WebSphere/AppServer/" > /dev/null 2>&1

if [ $? -eq 0 ]; then

ls -l /etc/rc*.d/S* | egrep -i "vcs|was" > /dev/null 2>&1

if [ $? -eq 0 ]; then
        ls -l /etc/rc*.d/K* | egrep -i "vcs|was" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                        VALUE="Startup & Shutdown script found<br><br>`ls -l /etc/rc3.d/S* | egrep -i "vcs|was"`<br>`ls -l /etc/rc0.d/K* | egrep -i "vcs|was"`"
                        violations="Compliant"
        else
                VALUE="Missing Shutdown script<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
                violations="Non-Compliant"
        fi
else
        VALUE="Missing startup script<br><br>`ls -l /etc/rc3.d/S* | grep -i vcs`<br>`ls -l /etc/rc0.d/K* | grep -i vcs`"
        violations="Non-Compliant"
fi

else
        violations="NA"
        VALUE="WAS IS NOT RUNNING ON THIS SERVER"
        WASSTAT="NOWAS"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
DescNo="C4"
DescItem="WAS Binary location"
policy_reco="Ensure that WAS files are place on separate filesystem /opt/IBM/WebSphere."
STDBLD="A"
AUTOCHK="A"
how_to="# df -k"

if [ "$WASSTAT" != "NOWAS" ]
then
                WASPATH=`find / -name AppServer | head -1`
                df -k $WASPATH | grep WebSphere > /dev/null 2>&1

                        if [ $? -eq 0 ]; then
                                violations="Compliant"
                                VALUE="`df -k $WASPATH`<br><br><br>WAS installed in separate file system"

                        else
                                violations="Non-Compliant"
                                VALUE="WAS Not installed in separate file system"
                        fi

else

  violations="NA"
  VALUE="WAS NOT INSTALLED"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


#####################################################
DrawSubHead "3. Oracle (This following steps are applicable only when Oracle is installed)"  >>$HTMLLogFile
#
DescNo="C5"
DescItem="ORACLE/DB2 Start/Stop Scripts"
policy_reco="Ensure that Oracle has a rc startup/shutdown script."
STDBLD="M"
AUTOCHK="M"
how_to="# ps -ef | grep oracle"

VALUE="DB TEAM DO ORACLE START/STOP"
violations="NA"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
DescNo="C6"
DescItem="ORACLE/DB2 Binary location"
policy_reco="Ensure that Oracle files are placed in seperate file system "
STDBLD="M"
AUTOCHK="M"
how_to="# df -k"

VALUE="DBA Team will check"
violations="NA"
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


####################################
DrawSecHead "Section D: Additional Operating System Settings " >> $HTMLLogFile

echo "$(date) : Additional Operating SystemSettings Verification "


#
DescNo="D1"
STDBLD="A"
AUTOCHK="A"
DescItem="PATH Variable"
policy_reco="Ensure PATH variable updated in /etc/profile"
how_to="# cat /etc/profile"

cat /etc/profile | grep -v "#" | grep -w PATH > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
   violations="Compliant"
   VALUE="$(cat /etc/profile |grep -v "#" | grep -w PATH=)"
   else
   violations="Non-Compliant"
   VALUE="$(cat /etc/profile |grep -v "#" | grep -w PATH=)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
DescNo="D2"
STDBLD="A"
AUTOCHK="A"
DescItem="/etc/resolv.conf Permissions"
policy_reco="Set /etc/resolv.conf permissions to 644"
how_to="# ls -l /etc/resolv.conf"

        if [ -f /etc/resolv.conf ]
                then
                FPERMS=$(ls -l /etc/resolv.conf | awk '{print $1}')

                if [ "$FPERMS" = "-rw-r--r--" ]
                        then
                        violations="Compliant"
                        VALUE="$(ls -l /etc/resolv.conf | awk '{print $1"  "$9}')"

                else
                        violations="Non-Compliant"
                        VALUE="$(ls -l /etc/resolv.conf | awk '{print $1"  "$9}')"
                fi

        else

    violations="Non-Compliant"
    VALUE="File Doesn't Exist"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
DescNo="D3"
STDBLD="A"
AUTOCHK="A"
DescItem="/etc/nsswitch.conf Permissions"
policy_reco="Set /etc/nsswitch.conf permissions to 644"
how_to="# ls -l /etc/nsswitch.conf"

        if [ -f /etc/nsswitch.conf ]
                then
                FPERMS=$(ls -l /etc/nsswitch.conf | awk '{print $1}')

                if [ "$FPERMS" = "-rw-r--r--" ]
                        then
                        violations="Compliant"
                        VALUE="$(ls -l /etc/nsswitch.conf | awk '{print $1"  "$9}')"

                else
                        violations="Non-Compliant"
                        VALUE="$(ls -l /etc/nsswitch.conf | awk '{print $1"  "$9}')"
                fi

        else

    violations="Non-Compliant"
    VALUE="File Doesn't Exist"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
DescNo="D4"
STDBLD="A"
AUTOCHK="A"
DescItem="ntp.conf / chrony.conf Permissions"
policy_reco="Set ntp.conf or chrony.conf permissions to 644"
how_to="# ls -l /etc/ntp.conf or /etc/chrony.conf"

OS=`uname`

if [ $OS = "Linux" ]; then
        if [ -f /etc/ntp.conf ]
                then
                FPERMS=$(ls -l /etc/ntp.conf | awk '{print $1}')

                if [ "$FPERMS" = "-rw-r--r--" ]
                        then
                        violations="Compliant"
                        VALUE="$(ls -l /etc/ntp.conf | awk '{print $1"  "$9}')"

                else
                        violations="Non-Compliant"
                        VALUE="$(ls -l /etc/ntp.conf | awk '{print $1"  "$9}')"
                fi
        elif [ -f /etc/chrony.conf ]
                then
                FPERMS=$(ls -l /etc/chrony.conf | awk '{print $1}')
                if [ "$FPERMS" = "-rw-r--r--" ]
                        then
                        violations="Compliant"
                        VALUE="$(ls -l /etc/chrony.conf | awk '{print $1"  "$9}')"
                else
                        violations="Non-Compliant"
                        VALUE="$(ls -l /etc/chrony.conf | awk '{print $1"  "$9}')"
                fi
        else

    violations="Non-Compliant"
    VALUE="File Doesn't Exist"
        fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# PERM HW Errors

#####
DescNo="D5"
STDBLD="A"
AUTOCHK="A"
DescItem="NTP/CHRONY Service"
policy_reco="NTP or CHRONY client will synch with the NTP/DNS server via the NTP/CHRONY process<br><br>Ensure that NTP/CHRONY process is running on the client."
how_to="# ps -ef | egrep 'xntpd|chrony'"

ps -ef | grep -v grep | egrep "ntpd|chronyd" > /dev/null 2>&1

if [ $? -eq 0 ]; then
                violations="Compliant"
                VALUE=`ps -ef | grep -v grep | grep ntpd`
        else
                violations="Non-Compliant"
                VALUE="NTP Process is not running"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

#
DescNo="D6"
STDBLD="A"
AUTOCHK="A"
DescItem="NTP / CHRONY Port"
policy_reco="Ensure NTP or CHRONY Port opened in /etc/services"
how_to="# cat /etc/services | grep ^ntp"

cat /etc/services | grep ^ntp > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
    violations="Compliant"
    VALUE="$(cat /etc/services | grep ^ntp | head -1)"
  else
    violations="Non-Compliant"
    VALUE="$(cat /etc/services | grep ^ntp | head -1)"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile
#

# TSCM
DescNo="D7"
STDBLD="A"
AUTOCHK="A"
DescItem="TSCM Client"
policy_reco="Ensure that Tivoli Security Compliance Manager (TSCM) is not installed."
how_to=""

ps -ef | grep -v grep | grep jac > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]; then
	if [ -f "/opt/IBM/SCM/client/jacclient" ];	then
		violations="Non-Compliant"
		VALUE="TSCM client installed"
	else
		violations="Compliant"
		VALUE="TSCM not installed"
	fi	
else
	violations="Compliant"
	VALUE="TSCM not installed"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# SCSP
DescNo="D8"
STDBLD="A"
AUTOCHK="A"
DescItem="Intrusion Detection Tool"
policy_reco="Ensure SCSP/SCDS Agent is installed and running</n>See DBS ITA implementation / config standard and policy which is maintained by ITA administrator."
how_to="# ps -ef|grep sisi |grep -v grep  ; sisipsconfig.sh -v ; sisipsconfig.sh -t "
ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1
if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ]
        then
          violations="N/A"
          VALUE="SCSP is not required for Development servers"
          VALUE1=" "
else
        ps -ef|grep sisi|grep -v grep > $OUTDIR/scspps.txt
		SCSPB=`rpm -qa | grep -E "SYMCcsp|SYMCsdcss" | tail -1`
		SCSPL=`rpm -qi ${SCSPB} | grep -i Relocations | awk '{print $NF}'`
        su - sisips -c "${SCSPL}/IPS/sisipsconfig.sh -v" > $OUTDIR/scsptmp.txt
        su - sisips -c "${SCSPL}/IPS/sisipsconfig.sh -t" > $OUTDIR/scsptestcomm.txt
        ps -ef|grep sisi|grep -v grep >/dev/null 2>&1;RC1=$?
        SCSPPF=$(cat $OUTDIR/scsptmp.txt | grep "Prevention Feature" | cut -d"-" -f2 | tr -d ' ')
        cat $OUTDIR/scsptmp.txt | grep "Current Management Server" |  awk -F '-' '{print $2}' | tr -d ' ' | grep -E '10.80.128.121|10.89.52.28|10.197.150.64|10.196.150.129|10.196.150.130|10.190.15.231' > /dev/null 2>&1;RC2=$?
        cat $OUTDIR/scsptestcomm.txt | grep "Connection to server successful" > /dev/null 2>&1;RC3=$?
        if ([ $RC1 -eq 0 ] && [ $RC2 -eq 0 ] && [ $RC3 -eq 0 ] && [ $SCSPPF == "disabled" ]) ; then
#       if [ $? -eq 0 ]; then
        violations="Compliant"
#       VALUE="SCSP agent is running"
        VALUE1="SCSP agent is running"
        VALUE2="$(cat $OUTDIR/scspps.txt)"
        VALUE3="$(cat $OUTDIR/scsptmp.txt)"
        VALUE4="$(cat $OUTDIR/scsptestcomm.txt)"
#       VALUE1="$VALUE2\n$VALUE3\n$VALUE4"
#       VALUE="$VALUE1 \n $VALUE2 \n $VALUE3 \n $VALUE4"
        else
        violations="Non-Compliant"
#       VALUE="SCSP agent is not running, please check"
        VALUE1="SCSP agent is not running, please check"
        VALUE2="$(cat $OUTDIR/scspps.txt)"
        VALUE3="$(cat $OUTDIR/scsptmp.txt)"
        VALUE4="$(cat $OUTDIR/scsptestcomm.txt)"
#        VALUE1="$VALUE2\n$VALUE3\n$VALUE4"
#        VALUE="$VALUE1 \n $VALUE2 \n $VALUE3 \n $VALUE4"
        fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE1<br><br>$VALUE2<br>$VALUE3<br>$VALUE4</pre>" "$violations" >>$HTMLLogFile
#DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

## SENDMAIL
#DescNo="`Desctype`85"
#STDBLD="A"
#AUTOCHK="A"
#DescItem="Sendmail Service"
#policy_reco="Ensure sendmail outbound disabled"
#how_to="# ps -ef | grep sendmail"
#
#ps -ef|grep sendmail|grep -v grep > /dev/null 2>&1
#if [ $? -eq 0 ]; then
#  violations="Non-Compliant"
#  VALUE="Sendmail agent is running"
#  else
#  violations="Compliant"
#  VALUE="Sendmail is not running"
#fi
#
#DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# SYSLOGD
DescNo="D9"
STDBLD="A"
AUTOCHK="A"
DescItem="syslogd Service"
policy_reco="Ensure Syslogd running"
how_to="# ps -ef|grep syslogd | grep -v grep "

ps -ef | grep syslogd | grep -v grep > /dev/null 2>&1;RC=$?
if [ $RC -eq 0 ]
then
 violations="Compliant"
  VALUE="$( ps -ef | grep syslogd | grep -v grep)"
else
  violations="Non-Compliant"
  VALUE="Syslogd is Not Running"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
#
# TRIP
DescNo="D10"
STDBLD="A"
AUTOCHK="A"
DescItem="TripWire Service"
policy_reco="Ensure TripWire Service running"
how_to="# ps -ef | grep -i tripwire"

ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ]
        then
          violations="N/A"
          VALUE="Tripwire is not required for Development servers"
          VALUE1=" "
else
        /usr/local/tripwire/te/agent/bin/twdaemon status | grep -i running  > /dev/null 2>&1
        if [ $? -eq 0 ]
        then

                VALUE=`/usr/local/tripwire/te/agent/bin/twdaemon status`
                violations="Compliant"
        else

                VALUE=`/usr/local/tripwire/te/agent/bin/twdaemon status`
                violations="Non-Compliant"
        fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# TLM
DescNo="D11"
STDBLD="A"
AUTOCHK="A"
DescItem="TAD4D TLM Agent"
policy_reco="Ensure TAD4D TLM Service running"
how_to="# ps -ef | grep tlmagent"

ps -ef |grep -i tlmagent | grep -v grep > /dev/null 2>&1
        if [ $? -eq 0 ]
        then

                VALUE=`ps -ef |grep -i tlmagent | grep -v grep`
                violations="Compliant"
        else

                VALUE="TAD4D/TLM Agent is Not running"
                violations="Non-Compliant"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# CYBERARK
DescNo="D12"
STDBLD="A"
AUTOCHK="A"
DescItem="VASCO And CyberArk Configuration"
policy_reco="Ensure VASCO and CyberArk configured properly"
how_to="# netstat -an"

HOSTS=hostname | cut -c1-3 > /dev/null 2>&1

if [ "$HOSTS" = "x01" ] || [ "$HOSTS" = "x07" ]
        then
        netstat -an | grep -w 60022 | grep LISTEN > /dev/null 2>&1;RC1=$?
        netstat -an | grep -w 61022 | grep LISTEN > /dev/null 2>&1;RC2=$?
        netstat -an | grep -w 63022 | grep LISTEN > /dev/null 2>&1;RC3=$?
        ((RC=$RC1+$RC2+RC3))
        if [ $RC -eq 0 ]
        then

          violations="Compliant"
          VALUE="$(netstat -an | grep LISTEN | egrep "60022|61022|63022")"

       else

          violations="Non-Compliant"
          VALUE="Required ports are not LISTENING "
        fi

elif [ "$HOSTS" = "x03" ]
        then
        netstat -an | grep -w 63022 | grep LISTEN > /dev/null 2>&1
        if [ $RC -eq 0 ]
        then

          violations="Compliant"
          VALUE="$(netstat -an | grep LISTEN | egrep "63022")"

       else

          violations="Non-Compliant"
          VALUE="Required ports are not LISTENING "
        fi
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# ITM
DescNo="D13"
STDBLD="A"
AUTOCHK="A"
DescItem="ITM Configuration"
policy_reco="Ensure ITM Agnets running"
how_to="# cinfo -r"

ENVM=`uname -n | cut -c1-4` > /dev/null 2>&1

if [ "$ENVM" = "x01t" ] || [ "$ENVM" = "x01T" ] || [ "$ENVM" = "x01D" ] || [ "$ENVM" = "x01d" ] || [ "$ENVM" = "x01B" ] || [ "$ENVM" = "x01b" ]
        then
          violations="N/A"
          VALUE="ITM is not required for Development servers"
else

        if [ -f /opt/IBM/ITM/bin/cinfo ]
        then
                ITM=`/opt/IBM/ITM/bin/cinfo -r`
                violations="Compliant"

        elif [ -f /IBM/itm/bin/cinfo ]
        then
                ITM=`/IBM/itm/bin/cinfo -r`
                violations="Compliant"

        elif [ ! -f /opt/IBM/ITM/bin/cinfo ] && [ ! -f /IBM/itm/bin/cinfo ]
        then
                ITM="Not Installed"
                violations="Non-Compliant"
        fi

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$ITM</pre>" "$violations" >>$HTMLLogFile


# SNMP
DescNo="D14"
STDBLD="A"
AUTOCHK="A"
DescItem="SNMP service"
policy_reco="To disable SNMP if not required. If needed, it has to be properly configured and controlled only for sending out SNMP traps and receiving SNMP messages from authorized hosts. <br><br>SNMP required for HACMP clustered servers."
how_to="# ps -ef |grep ^snmpd "

ps -ef | grep ^snmpd | egrep -v "dir|grep" > /dev/null 2>&1
        if [ $? -eq 1 ]
        then

                VALUE="SNMP is Not Running"
                violations="Compliant"
        else

                VALUE=`ps -ef | grep snmpd | egrep -v "dir|grep"`
                violations="Non-Compliant"
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

DescNo="D15"
STDBLD="A"
AUTOCHK="A"
DescItem="URT Script"
policy_reco="Ensure URT Script scheduled in crontab"
how_to="# crontab -l | grep collect_urt.sh"

        OS=`uname`
        if [ $OS = "Linux" ]; then
          crontab -l 2> /dev/null | grep -v "^#" | grep /harden/collect_urt.sh > /dev/null 2>&1;RC1=$?
          if [ $? -eq 0 ]; then
          violations="Compliant"
          VALUE=`crontab -l 2> /dev/null | grep -v "^#" | grep -i urt`
          else
          violations="Non-Compliant"
          VALUE="Missing cron"
          fi
        fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##
DescNo="D16"
DescItem="Timeout Settings"
policy_reco="Ensure session timeout is set to 600 seconds / 10 minutes idle time"
STDBLD="C"
AUTOCHK="A"
how_to="# cat /etc/profile | egrep 'TMOUT|TIMEOUT|readonly'"

PROFTMOUT=`cat /etc/profile | grep -v grep |egrep 'TMOUT|TIMEOUT|readonly' | wc -l`
TMOUT=`cat /etc/profile | grep '^TMOUT'  | cut -f2 -d'='`
TIMEOUT=`cat /etc/profile | grep '^TIMEOUT' | cut -f2 -d'='`
if [ "$PROFTMOUT" = "4" ];	then
	if [ "$TMOUT" = "600" ];	then
		if [ "$TIMEOUT" = "600" ];	then
			violations="Compliant"
			VALUE="TMOUT set to $TMOUT<BR>TIMEOUT set to $TIMEOUT"
		else
			violations="Non-Compliant"
			VALUE="TMOUT set to $TMOUT<BR>TIMEOUT set to $TIMEOUT"
		fi
	else
		violations="Non-Compliant"
		VALUE="TMOUT set to $TMOUT<BR>TIMEOUT set to $TIMEOUT"
	fi
else
	violations="Non-Compliant"
	VALUE="Timeout not set properly.<BR>TMOUT set to $TMOUT<BR>TIMEOUT set to $TIMEOUT"
fi
DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

####
DescNo="D17"
STDBLD="A"
AUTOCHK="A"
DescItem="OS Log HouseKeeping Script"
policy_reco="Ensure HouseKeeping Script (newsyslog) scheduled in crontab"
how_to="# cat /etc/logrotate.d/syslog"

LOGLIST="/var/log/messages<br>/var/log/secure<br>/var/log/maillog<br>/var/log/spooler<br>/var/log/boot.log<br>/var/log/cron"

ls -ltr /etc/logrotate.d/syslog > /dev/null 2>&1

if [ $? -eq 0 ]
        then
        cat /etc/logrotate.d/syslog | grep messages > /dev/null 2>&1
        if [ $? -eq 0 ] ;then
        cat /etc/logrotate.d/syslog | grep secure > /dev/null 2>&1
        if [ $? -eq 0 ] ;then
        cat /etc/logrotate.d/syslog | grep maillog > /dev/null 2>&1
        if [ $? -eq 0 ] ;then
        cat /etc/logrotate.d/syslog | grep spooler > /dev/null 2>&1
        if [ $? -eq 0 ] ;then
        cat /etc/logrotate.d/syslog | grep 'boot.log' > /dev/null 2>&1
        if [ $? -eq 0 ] ;then
        cat /etc/logrotate.d/syslog | grep cron > /dev/null 2>&1
        if [ $? -eq 0 ] ;then
        VALUE="Housekeeping is configured on logrorate<br>$LOGLIST"
        violations="Compliant"
        else
        VALUE="cron log is not configured on logrotate"
        violations="Non-Compliant"
        fi
        else
        VALUE="boot.log is not configured on logrotate"
        violations="Non-Compliant"
        fi
        else
        VALUE="spooler log is not configured on logrotate"
        violations="Non-Compliant"
        fi
        else
        VALUE="maillog log is not configured on logrotate"
        violations="Non-Compliant"
        fi
        else
        VALUE="secure log is not configured on logrotate"
        violations="Non-Compliant"
        fi
        else
        VALUE="messages log is not configured on logrotate"
        violations="Non-Compliant"
        fi
else
        VALUE="Logrotate is not configured"
        violations="Non-Compliant"
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# ID Management
DescNo="D18"
STDBLD="A"
AUTOCHK="A"
DescItem="ID Management Script"
policy_reco="Ensure ID Management script copied with execute eprmissions"
how_to="# SG<BR>ls -lrt /usr/local/bin/paosim<BR><BR>HK<BR>ls -l /usr/local/bin/idmgt<BR><BR>ID<BR>ls -l /usr/local/bin/paosim"
HOSTS=hostname | cut -c1-3 > /dev/null 2>&1

if [ "$HOSTS" = "x01" ]
        then
          ls -l /usr/local/bin/paosim > /dev/null 2>&1
          if [ $RC -eq 0 ]; then
          violations="Compliant"
          VALUE=`ls -l /usr/local/bin/paosim`
          else
          violations="Non-Compliant"
          VALUE="Missing ID Management script"
          fi

elif [ "$HOSTS" = "x03" ]
        then
          ls -l /usr/local/bin/idmgt > /dev/null 2>&1
          if [ $RC -eq 0 ]; then
          violations="Compliant"
          VALUE=`ls -l /usr/local/bin/idmgt`
          else
          violations="Non-Compliant"
          VALUE="Missing ID Management script"
          fi

elif [ "$HOSTS" = "x07" ]
        then
          ls -l /usr/local/bin/paosim > /dev/null 2>&1
          if [ $RC -eq 0 ]; then
          violations="Compliant"
          VALUE=`ls -l /usr/local/bin/paosim`
          else
          violations="Non-Compliant"
          VALUE="Missing ID Management script"
          fi

fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br><BR><BR>$VALUE</pre>" "$violations" >>$HTMLLogFile

##########################################################################################################################
# ID
DescNo="D19"
STDBLD="A"
AUTOCHK="A"
DescItem="Functional UserIds"
policy_reco="Ensure All functional IDs Created"
how_to="# cat /etc/passwd"
HOSTS=hostname | cut -c1-3 > /dev/null 2>&1

if [ "$HOSTS" = "x01" ]
        then
        cat /etc/passwd | grep ^sunadm > /dev/null 2>&1;RC1=$?
        cat /etc/passwd | grep ^osde > /dev/null 2>&1;RC2=$?
        cat /etc/passwd | grep ^stgadm > /dev/null 2>&1;RC3=$?
        cat /etc/passwd | grep ^paosim > /dev/null 2>&1;RC4=$?
        cat /etc/passwd | grep ^sudoadm > /dev/null 2>&1;RC5=$?
        cat /etc/passwd | grep ^dbsinvs > /dev/null 2>&1;RC6=$?
        cat /etc/passwd | grep ^eoadmin > /dev/null 2>&1;RC7=$?
        ((RC=$RC1+$RC2+$RC3+$RC4+$RC5+$RC6+$RC7))

        if [ $RC -eq 0 ]
        then

          violations="Compliant"
          VALUE="$(cat /etc/passwd | egrep "sunadm|osde|stgadm|paosim|sudoadm|dbsinvs|eoadmin" | cut -d: -f1)"

       else
           violations="Non-Compliant"
           VALUE="Missing IDs"

        fi

elif [ "$HOSTS" = "x03" ]
        then
        cat /etc/passwd | grep ^ibmsa > /dev/null 2>&1;RC1=$?
        cat /etc/passwd | grep ^idmgt > /dev/null 2>&1;RC2=$?
        cat /etc/passwd | grep ^sudoadm > /dev/null 2>&1;RC3=$?
        cat /etc/passwd | grep ^dbsinvs > /dev/null 2>&1;RC4=$?
        cat /etc/passwd | grep ^eoadmin > /dev/null 2>&1;RC5=$?
        ((RC=$RC1+$RC2+$RC3+$RC4+$RC5))

        if [ $RC -eq 0 ]
        then

          violations="Compliant"
          VALUE="$(cat /etc/passwd | egrep "ibmsa|idmgt|sudoadm|dbsinvs|eoadmin" | cut -d: -f1)"

       else
           violations="Non-Compliant"
           VALUE="Missing IDs"

        fi

elif [ "$HOSTS" = "x07" ]
        then
        cat /etc/passwd | grep ^sunadm > /dev/null 2>&1;RC1=$?
        cat /etc/passwd | grep ^osde > /dev/null 2>&1;RC2=$?
        cat /etc/passwd | grep ^stgadm > /dev/null 2>&1;RC3=$?
        cat /etc/passwd | grep ^idaidmgt > /dev/null 2>&1;RC4=$?
        cat /etc/passwd | grep ^sudoadm > /dev/null 2>&1;RC5=$?
        cat /etc/passwd | grep ^dbsinvs > /dev/null 2>&1;RC6=$?
        cat /etc/passwd | grep ^eoadmin > /dev/null 2>&1;RC7=$?
        ((RC=$RC1+$RC2+$RC3+$RC4+$RC5+$RC6+$RC7))

        if [ $RC -eq 0 ]
        then

          violations="Compliant"
          VALUE="$(cat /etc/passwd | egrep "sunadm|osde|stgadm|idaidmgt|sudoadm|dbsinvs|eoadmin" | cut -d: -f1)"

       else
           violations="Non-Compliant"
           VALUE="Missing IDs"

        fi
fi


DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile


# SUDOADM
DescNo="D20"
STDBLD="A"
AUTOCHK="A"
DescItem="SUDOADM Publickey"
policy_reco="Ensure PublicKey Authentication enabled from sunmc"
how_to="# Check the DBSINVS user is available in the server"


FRC1=0
FRC2=0
FRC3=0
OS=`uname`
if [ $OS = "Linux" ]; then
	PASSEX=`chage -l dbsinvs | grep -i "^Password expires"| awk '{print $NF}'`
	ACCEX=`chage -l dbsinvs | grep -i "^Account expires"| awk '{print $NF}'`
	PASSST=`passwd -S dbsinvs | awk '{print $2}'`
	echo "Password expires : ${PASSEX}" > $OUTDIR/dbsinvs_s.txt
	echo "Account expires  : ${ACCEX}" >> $OUTDIR/dbsinvs_s.txt
	echo "Account State    : ${PASSST}" >> $OUTDIR/dbsinvs_s.txt
	if [ "${PASSEX}" = "never" ] && [ "${ACCEX}" = "never" ] && [ "${PASSST}" = "LK" ];	then
		FRC1=0
		VALUE="<ol>$(cat $OUTDIR/dbsinvs_s.txt | sed -e 's/^/<li>/g' -e 's/$/<\/li>/g')</ol>"
	else
		FRC1=1
		VALUE="<ol>$(cat $OUTDIR/dbsinvs_s.txt | sed -e 's/^/<li>/g' -e 's/$/<\/li>/g')</ol>"
	fi
fi

HOSTCN=$(hostname | cut -c1-3 | tr -s '[:upper:]' '[:lower:]')
if [ "$HOSTCN" = "x01" ];	then
	HOSTE=`echo ${HOST} | cut -c1-4 | tr -s '[:upper:]' '[:lower:]' | sed 's/^.*\(.\)$/\1/'`
	if [ "$HOSTE" = "g" ] || [ "$HOSTE" = "r" ] || [ "$HOSTE" = "c" ];	then
		FRC2=0; FRC3=0
	else
		echo "Signature File :" >> $OUTDIR/dbsinvs.txt 2>&1
		if [ -f "/home/dbsinvs/`hostname`.csv" ];	then
			cat /home/dbsinvs/`hostname`.csv  2> /dev/null| grep -i `hostname` > /dev/null 2>&1
			[ $? -eq 0 ] && cat /home/dbsinvs/`hostname`.csv | grep -i `hostname` >> $OUTDIR/dbsinvs.txt || FRC2=1
			ls -l /home/dbsinvs/`hostname`.csv >> $OUTDIR/dbsinvs.txt 2>&1
			FRC2=0
		else
			echo "Signature file not configured" >> $OUTDIR/dbsinvs.txt 2>&1
			FRC2=1
		fi
		if [ -d /home/dbsinvs/.ssh2 ];	then
			if [ -f /home/dbsinvs/.ssh2/w01tinvapp3a_dbsinvs.pub -a -f /home/dbsinvs/.ssh2/pdcrtems01_dbsinvs.pub -a -f /home/dbsinvs/.ssh2/authorization ];	then
				echo "Robosys Keys :" >> $OUTDIR/dbsinvs.txt 2>&1
				cat /home/dbsinvs/.ssh2/authorization | grep -i "key w01tinvapp3a_dbsinvs.pub" >> $OUTDIR/dbsinvs.txt 2>&1
				cat /home/dbsinvs/.ssh2/authorization | grep -i "key pdcrtems01_dbsinvs.pub" >> $OUTDIR/dbsinvs.txt 2>&1
			else
				echo "dbsinvs user public key not configured for robosys" >> $OUTDIR/dbsinvs.txt 2>&1
				FRC3=1
			fi
		else
			echo "dbsinvs user public key not configured for robosys" >> $OUTDIR/dbsinvs.txt 2>&1
			FRC3=1
		fi
	fi
else
	FRC2=0; FRC3=0
fi
	
((FRC=$FRC1+$FRC2+$FRC3))
if [ ${FRC} -eq 0 ];	then
	violations="Compliant"
	VALUE=$(cat $OUTDIR/dbsinvs.txt)
	VALUE1=$(cat $OUTDIR/dbsinvs_s.txt)
else
	violations="Non-Compliant"
	VALUE=$(cat $OUTDIR/dbsinvs.txt)
	VALUE1=$(cat $OUTDIR/dbsinvs_s.txt)
fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile



#
DescNo="D21"
STDBLD="A"
AUTOCHK="A"
DescItem="Device Status"
policy_reco="Ensure root is using ext3 or ext4 filesystem"
how_to="# df -T"

df -T | grep -w '/' | egrep 'ext3|ext4' > /dev/null 2>&1

if [ $? -eq 0 ]
        then
        VALUE=`df -T | grep -w '/' | awk '{print $1,$6}'`
        violations="Compliant"
        else
        VALUE=`df -T | grep -w '/' | awk '{print $1,$6}'`
        violations="Non-Compliant"
fi


DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE</pre>" "$violations" >>$HTMLLogFile

# D22
DescNo="D22"
DescItem="File System and File System Usage"
policy_reco="All Infra File System Usage(/ /home /opt /tmp /var ) should be below 80% before live"
how_to="# df -h"
STDBLD="A"
AUTOCHK="A"


  LIXMOUNT=`df -Ph | grep -v Filesystem | awk '{print $6}' | egrep -v "dev|boot|proc|sys|nfs" | egrep -w "/|^/home$|^/opt$|/tmp|^/var$" `
  df -Ph >> $OUTDIR/fsstat.lst
  # File System Usage Check
  for lmnt in $LIXMOUNT
   do
   USAGE=`df -Ph $lmnt | grep -v Filesystem | awk '{print $5}' | sed 's/%//'`
    if [ $USAGE -ge 80 ]; then
         echo $lmnt >> $OUTDIR/lixfsusage.lst
        fi
    done
    # Validate above 80% File System
    if [ -f $OUTDIR/lixfsusage.lst ]; then
     HIGHFS=`cat $OUTDIR/lixfsusage.lst`
         VALUE="$HIGHFS<br><br>Above is infra filesystem using above 80%"
         VALUE1=`df -Ph |awk '{print $2,"\t",$5,"\t",$6}' | egrep -v "dev|boot|proc|sys|nfs"`
         violations="Non-Compliant"
        else
     VALUE="Infra file system are below 80%"
         VALUE1=`df -Ph |awk '{print $2,"\t",$5,"\t",$6}' | egrep -v "dev|boot|proc|sys|nfs"`
     violations="Compliant"
    fi

DrawItem "$DescNo" "$DescItem" "$policy_reco" "$STDBLD" "$AUTOCHK" "<pre>${how_to}<br>$VALUE <br><br>$VALUE1</pre>" "$violations" >>$HTMLLogFile

# Sample Section
DescNo="D23"
STDBLD="A"
AUTOCHK="-"
DescItem="Dual Path Status"
policy_reco="Ensure Dual path OK for all disks  "
how_to="# luxadm or vxdmpadm"
VALUE="Refer Section C39"
violations="NA"


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
echo "<tr><td colspan=7><b>Approver:</b> Ashish BHAN [ashishbhan@dbs.com]</td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><b>Author:</b> Sutharsanan.K [karuppaiah@dbs.com]</td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><b>Reviewer:</b> PRAKASH DAYALAN [prakashdayalan@dbs.com]</td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><b>Check finished at: `date`</b></td></tr>" >>$HTMLLogFile
echo "<tr><td colspan=7><font color='red'>*DBS Confidential Document</font></p>" >>$HTMLLogFile
echo "================================"
echo "Check-list collected under $OUTDIR/"
echo "================================"
chmod 755 $OUTDIR/;chmod 755 $OUTDIR/*;
ls -lrt $OUTDIR/
#/home/dbsinvs/Additional_data_collection_Linux.sh
OS=`uname`
        if [ $OS = "SunOS" ]; then
        cp -p $OUTDIR/${HOSTNAME}.`uname`.infraverification.htm /export/home/dbsinvs

        elif [ $OS = "Linux" ]; then
        cp -p $OUTDIR/${HOSTNAME}.`uname`.infraverification.htm /home/dbsinvs

        fi
echo "$(date) : InfraVerification | COMPLETED |  "
