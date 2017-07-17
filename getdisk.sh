#!/usr/bin/ksh 
###############################################################################
# Script name : getdisk.sh                                                    #
#     Purpose : Add disk and extend the file system in VM                     #
#                                                                             #
#      Author : RAJA SELVARAJ                                                 #
#             : IBM SINGAPORE PTE LTD                                         #
#     Created : 01/05/2017                                                    #
###############################################################################
LOG=/tmp/fssize.log
FS=$1
SIZE=$2
SCSCIID=$3
if [ $# -ne 3 ] 
then
   echo "Script Usage Wrong...$0 <FS NAME> <FS SIZE> <SCSIID>"
   exit 1
 fi
SERVERTYPE=`dmidecode -s system-product-name`	
FSTYPE=`grep -i root /etc/fstab|awk '{ print $3 }'`
if [ $SERVERTYPE != "VirtualBox" ] 
 then 
   exit 1;
  fi

CreateNewVG()
{
DISK=`lsscsi | grep -i "$3"|awk ' { print $6}'`
NEWVGNAME="appvg"
/usr/sbin/vgcreate $NEWVGNAME $DISK
if [ $? -eq 0 ]
 then
   NEWDEVNAME=`echo "$1""lv"|tr -d '/'`
   lvcreate -L $2 -n $NEWDEVNAME $NEWVGNAME
    if [ $? -eq 0 ]
     then
          echo "$NEWDEVNAME is created successfully"
       mkfs.xfs /dev/$NEWVGNAME/$NEWDEVNAME
       echo "FS is created successfully"
        if [ -d $1 ]
             then
                 mount /dev/$NEWVGNAME/$NEWDEVNAME $1
             else
                mkdir -p $1
                mount /dev/$NEWVGNAME/$NEWDEVNAME $1
              fi
         else
           echo "Unable to create fs";exit 1
         fi

 else
    echo "Error in creating $NEWVGNAME..";exit 1
fi
}

AddExistingVG()
 {
   DEVNAME=`df -k | grep -iw / | awk ' { print $1 }'`
   VGNAME=`/usr/sbin/lvs $DEVNAME --noheadings --separator , 2>/dev/null|awk -F, '{ print $2 }'`
   OtherVG=`vgs --noheadings  2>/dev/null| grep -iv $VGNAME | awk '{ print $1 }'`
   if [ -n "$OtherVG" ] ;
   then
     DISK=`lsscsi | grep -i "$3"|awk ' { print $6}'`
     NEWDEVNAME=`echo "$1""lv"|tr -d '/'`
     vgextend $OtherVG $DISK
     if [ $? -eq 0 ]
     then
      echo "$VGNAME extended successfully with $DISK"
      lvcreate -L $2 -n $NEWDEVNAME $OtherVG
      if [ $? -eq 0 ]
       then
         echo "$NEWDEVNAME is created successfully"
         mkfs.xfs /dev/$OtherVG/$NEWDEVNAME
         if [ $? -eq 0 ]
          then
            echo "FS is created successfully"
            if [ -d $1 ]
             then
                 mount /dev/$OtherVG/$NEWDEVNAME $1
             else
                mkdir -p $1
                mount /dev/$OtherVG/$NEWDEVNAME $1
              fi
         else
            echo "Unable to create fs";exit 1
         fi
     else
      echo "unable to create LV";exit 1
    fi
 else
   echo "Unable to extend the VG"; exit 1
 fi

else
    CreateNewVG $FS $SIZE $SCSCIID
fi
}


ExistingFS()
{
CHECKFS=`df -k | grep -i $FS | awk ' { print $6 }'`
if [ -z "$CHECKFS" ] 
then 
    echo " File system is not exist" 
    AddExistingVG $FS $SIZE $SCSCIID
else 
echo "File System exist... Please extend the size" 
DEVNAME=`df -k | grep -iw $FS | awk ' { print $1 }'`
VGNAME=`/usr/sbin/lvs $DEVNAME --noheadings --separator , 2>/dev/null|awk -F, '{ print $2 }'`
df -k >/tmp/curFS.txt
if [ -f /tmp/curFS.txt ] 
then 
   CURSIZE=`grep -i $FS /tmp/curFS.txt|awk '{ print ($2/1024)}' `
   REQSIZE=`vgs $VGNAME --noheadings | awk -v s=$SIZE '{ if($s>=$7) { print "OK"; } else { print "NOTOK" } }'`
   if [ "$REQSIZE" = "OK" ] 
   then 
    lvextend -L +$SIZE $DEVNAME
    if [ $FSTYPE = "xfs" ] 
    then 
     /usr/sbin/xfs_growfs $DEVNAME
    else 
    resize2fs $CHECKFS
    fi 
    df -k >/tmp/afterFS.txt
    aftSIZE=`grep -i $FS /tmp/afterFS.txt |awk '{ print ($2/1024)}'`
   else 
    echo "Space is not enough to extend the filesystem. Please add additional Disks to add"  
   fi 
else
   echo "df command output is not captured properly before execution"
fi
fi 
}

ValidateMountpoint()
  { 
    if [ -z "$checkMNT" ]
     then 
       echo "Mount Point is not exist";
      else 
         echo "Mount point is exist";
       fi
  }



main()
 { 
    ExistingFS
  }

main
