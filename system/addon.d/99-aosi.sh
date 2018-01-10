#!/sbin/sh
#
#	Addon Scrip Installer(iMulator)
#
#	This Script is part of CodR C.A. Template
# 	It will not work if aslib.functions is not loaded.
#
#
#	Title:		aosi
#	src:		N/A
#	api:		XX
#

# CodR C.A. Addon.d Script Template
#	-Global Variables	
#	-Function Variables
#	-Pre-Initialization
#	-Functions
#	-Post-Initialization
#	-Main Case
# 	 -backup
#	 -restore
#	 -pre-backup
#	 -post-backup
#	 -pre-restore
#	 -post-restore
#
#

. /tmp/backuptool.functions

# Global Variable Settings
#--------------------------------------------------------------------------#
app_name=aosi
app_src_ver=b1.0.0.0
app_rev=08-19-2017

# aosi_script variables
aosi_bak_dir=/tmp/aosi_backup_tmp
aosi_add2=/sdcard/.aosi/aosi.zip
aosi_add1=/data/.aosi/aosi.zip
install_tmp=/tmp/aosi_install_tmp

# Function Variables
#--------------------------------------------------------------------------#

# LogMsg() dependent Variables
Logging=true			# Enable or Disable Logging
LogType=upgrademode		# flashmode or upgrademode
logfileName=$app_name	# Logfile name
loggingLevel=3			# 1 - basic, 2 - enough, 3 - full
LT1=LogMsg_dummy		# we need to default to dummy if aslib.functions is missing
LT2=LogMsg_dummy		# we need to default to dummy if aslib.functions is missing
LT3=LogMsg_dummy		# we need to default to dummy if aslib.functions is missing

# Pre-Initialization
#--------------------------------------------------------------------------#

# Title Header
TMH0="addon.script"
TMH1="**************************"
TMH2="  Addon Script Imulator "
TMH3="**************************"
TMH4="$app_name $app_src_ver"
TMH5="rev: $app_rev"

# FD failsafe
OUTFD=`ps | grep -v grep | grep -oE "update(.*)" | cut -d" " -f3`

# Local Functions
#--------------------------------------------------------------------------#

# Load aslib in strategic locations
addon_aslib_loader() {
	# search for default location
	if	 [ -e "/data/aslib/aslib.functions" ];then
		. /data/aslib/aslib.functions
		_as=0
	elif [ -e "/tmp/libcore/aslib.functions" ];then
			. /tmp/libcore/aslib.functions
			_as=0
	elif [ -e "/system/addon.d/libcore.zip" ];then
			if [ ! -e /tmp/libcore ];then
				mkdir /tmp/libcore
			fi
			unzip -o "/system/addon.d/libcore.zip" -d "/tmp/libcore"
			if [ -e /tmp/libcore/aslib.functions ];then
				. /tmp/libcore/aslib.functions
				_as=0
			else
				_as=1
			fi
	fi
	if ($_as);then
		ui_print "addon - $app_name"
		ui_print "FATAL ERROR!: failed to locate aslib."
		exit 1
	fi
}

# Initial ui_print Function 
ui_print(){
	echo -n -e "ui_print $1\n" >> /proc/self/fd/$OUTFD
	echo -n -e "ui_print\n" >> /proc/self/fd/$OUTFD
}

# install_zip
install_zip(){
	$LT1 "FUNC install_zip $1, $2"
	TARGET=$install_tmp/META-INF/com/google/android/update-binary
	$LT3 "$(unzip -o "$2" "META-INF/com/google/android/*" -d "$install_tmp")"
	if [ ! -f $TARGET ];then
		ui_print "ERROR: not a valid script!"
	else
		chown 0.0 $TARGET
		chmod 755 $TARGET
		ash "$TARGET" "$1" "$OUTFD" "$2"
		rm -rf $install_tmp/META-INF/com/google/android/* 2>&1 | $LT2
		if [ -e $TARGET ];then
			ui_print "FAILURE TO REMOVE RESIDUAL WASTE"
		fi
	fi
}

# aosi_script for addon.d
aosi_script(){
	# let's sleep aosi for 20s
	sleep 20
	# let's remount sdcard && data
	remount_mountpoint /data rw
	remount_mountpoint /sdcard rw
	remount_mountpoint /sdcard1 rw
	$LT1 "FUNC aosi_script"
	tittle_header
	ui_print "- Scanning AOSI folder for zip"
	install_zip_loc=$(find /data/aosi/* /sdcard*/aosi/* -name *.zip -type f -follow 2>/dev/null)
	install_zip_bak=$(find /sdcard*/aosi/backup/* -name *.zip -type f -follow 2>/dev/null)

	if [ -z "$install_zip_loc" ] && [ -z "$install_zip_bak" ] && [ ! -e "$aosi_add1" ] && [ ! -e "$aosi_add2" ];then
		ui_print " "
		ui_print "Warning!: No install zip found in strategic locations"
	fi

	# Find backup if it exist in add1 location
	if [ -e "$aosi_add1" ];then
		ui_print "- Extracting AOSI from Backup 1"
		$LT1 $(unzip -o "$aosi_add1" -d "$aosi_bak_dir")
		for ZIP_FILES in $(ls $aosi_bak_dir);do
			ui_print " "
			ui_print "--------------------------"
			ui_print "Installing $ZIP_FILES"
			ui_print "--------------------------"
			install_zip "$1" "$aosi_bak_dir/$ZIP_FILES"
		done
	elif [ -e "$aosi_add2" ];then
		ui_print "- Extracting AOSI from Backup 2"
		$LT1 $(unzip -o "$aosi_add2" -d "$aosi_bak_dir")
		for ZIP_FILES in $(ls $aosi_bak_dir);do
			ui_print " "
			ui_print "--------------------------"
			ui_print "Installing $ZIP_FILES"
			ui_print "--------------------------"
			install_zip "$1" "$aosi_bak_dir/$ZIP_FILES"
		done
	else
		$LT1 "Backup locations seems to be empty"
	fi
	
	# install zip from
	if [ ! -z "$install_zip_loc" ];then
		ui_print "- Installing Zip from Strategic Locations"
		for AOSI_ZIP in $install_zip_loc;do
			ui_print " "
			ui_print "--------------------------"
			ui_print "Installing $AOSI_ZIP"
			ui_print "--------------------------"
			install_zip "$1" "$AOSI_ZIP"
		done
	else
		ui_print " "
		ui_print "ERROR!: No zip found in Strategic Locations"
	fi
	
	# backup aosi
	aosi_backup
}

# aosi_script
aosi_backup(){
	$LT1 "FUNC aosi_backup"
	# copy all backup to tmp/aosi_backup_tmp if exist
	if [ ! -z "$install_zip_bak" ];then
		ui_print "- backing up"
		for FILE in $install_zip_bak;do
			cp -rf $FILE $aosi_bak_dir
		done
		if [ ! -z "`ls $aosi_bak_dir`" ];then
			cd $aosi_bak_dir
			zip -m aosi.zip *
			if [ ! -e $aosi_bak_dir/aosi.zip ];then
				ui_print "- Error: Failed to compress backup"
			else
				remount_mountpoint /system rw
				$LT2 "Copying Backup to Backup Folder 1"
				dd if=$aosi_bak_dir/aosi.zip of=/data/.aosi/aosi.zip 2>&1 | $LT2
				set_perm 0 0 755 /data/.aosi/aosi.zip
				$LT2 "Copying Backup to Backup Folder 2"
				dd if=$aosi_bak_dir/aosi.zip of=/sdcard/.aosi/aosi.zip 2>&1 | $LT2
				set_perm 0 0 755 /sdcard/.aosi/aosi.zip
				if [ ! -e /data/.aosi/aosi.zip ] && [ ! -e /sdcard/.aosi/aosi.zip ];then
					ex_s "Failed to backup install Zip's."
				else
					# remove backup from backup locations
					for INZIP in $install_zip_bak;do
						rm -rf $INZIP 2>&1 | $LT2
					done
				fi
			fi
		fi
	fi
}

# asosi_script
asosi_init(){
	# setup aosi folders
	$LT1 "- Setup aosi folders" "uip"
	aosi_folders="
	/data/aosi
	/sdcard/aosi
	/sdcard1/aosi
	"
	aosi_backup_folders="
	/data/.aosi
	/sdcard/.aosi
	/sdcard1/.aosi
	"
	for AOSI_FOLDER in $aosi_folders $aosi_backup_folders;do
		if [ ! -e $AOSI_FOLDER ];then
			mkdir $AOSI_FOLDER 2>&1 | $LT2
		fi
	done
	# setup aosi bak
	$LT1 "- Setting aosi backup" "uip"
	if [ -e $aosi_bak_dir ];then
		rm -rf $aosi_bak_dir 2>&1 | $LT2
	fi
	mkdir $aosi_bak_dir 2>&1 | $LT2
}

addon_wipe_list(){
	# Wipe old files from wipe list


}
# Post-Initialization
#--------------------------------------------------------------------------#

# Main
#--------------------------------------------------------------------------#

case "$1" in
  backup)
	# Stub
  ;;
  restore)
	# Stub
  ;;
  pre-backup)
	# Stub
  ;;
  post-backup)
	# Stub
  ;;
  pre-restore)
	# Stub
  ;;
  post-restore)
	# detect aslib in strategic locations
	addon_aslib_loader
	# init fd from aslib
	init_fd
	# init LogMsg from aslib
	init_LogMsg
	# aosi_init
	asosi_init
	# Post-Initialization
	#--------------------------------
	# aosi setup install_tmp
	$LT1 "- Setting install_tmp" "uip"
	if [ -e $install_tmp ];then
		rm -rf $install_tmp 2>&1 | $LT2
	fi
	mkdir $install_tmp 2>&1 | $LT2
	#--------------------------------
	$LT1 "- Running Mainscript" "uip"
	(aosi_script) &
  ;;
esac
