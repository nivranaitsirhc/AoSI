#!/sbin/sh
#
#	Addon Script Installer(iMulator)
#
#	This Script is part of Code C.A. Template
# 	It will not work if not called by update-binary
#
#
#	Title:		aosi
#	src:		N/A
#	api:		XX
#

# CodR C.A. Installer Template
#	-Global Variables	
#	-Function Variables
#	-Pre-Initialization
#	-Functions
#	-Post-Initialization
# 	-Main
#	 -Mount
#	 -Extract
#	 -Wipe Old Files
#	 -Place Files
#	 -uMount
#	-Cleanup
# -Post-Scripts
#

. $LIBS/aslib.functions

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
LogType=flashmode		# flashmode or upgrademode
logfileName=$app_name	# Logfile name
loggingLevel=3			# 1 - basic, 2 - enough, 3 - full
LT1=LogMsg_dummy		# we need to default to dummy if aslib.functions is missing
LT2=LogMsg_dummy		# we need to default to dummy if aslib.functions is missing
LT3=LogMsg_dummy		# we need to default to dummy if aslib.functions is missing

# Title Header Function
TMH0=" "
TMH1="**************************"
TMH2="  Addon Script Imulator "
TMH3="**************************"
TMH4="$app_name $app_src_ver"
TMH5="rev: $app_rev"

# catch the zip file pass by update-binary
for ZIPFILE in $* ;do
	if [ -e $ZIPFILE ];then
		ZIP=$ZIPFILE
	fi
done

# Intall_System && Extract_System Dependent Variables
SOURCEDIR=/sdcard/__tmp/system/
SOURCE=/sdcard/__tmp

# Pre-Initialization
#--------------------------------------------------------------------------#

# Functions
#--------------------------------------------------------------------------#

# Install_System
install_system(){
	# Install System Files
	$LT1 "FUNC Install_System"
	_msg1="Reading. : -"
	_msg2="Type     : Directory"
	_msg3="Type     : File"
	_msg4="Installing."
	_msg5="Progress :"
	progress 0 0
	_count=0
	for dummy in $(find $SOURCEDIR); do
		_count=$(($_count + 1))
	done
	_arbiter=$(awk "BEGIN {printf \"%.5f\",1/$_count}")
	_progress=0
	for FILE in $(find $SOURCEDIR); do
		_progress=$(awk "BEGIN {printf \"%.5f\",$_progress + $_arbiter}")
		set_progress $_progress
		$LT2 "$_msg1 ${FILE#$SOURCEDIR}"
		if [ -d "$FILE" ]; then
			TDIR=${FILE#$SOURCE}
			$LT2 "$_msg2"
			if [ ! -e "$TDIR" ]; then
				mkdir "$TDIR" 2>&1 | $LT2
				set_perm 0 0 0655 "$TDIR"
			fi
		else
			# Copy the file
			TFILE=${FILE#$SOURCE}
			$LT2 "$_msg3"
			$LT1 "$_msg4 ${FILE#$SOURCEDIR}"
			dd if="$FILE" of="$TFILE" 2>&1 | $LT2
			set_perm 0 0 0755 "$TFILE"
			$LT1 "$_msg5 $(awk "BEGIN {printf \"%.1f\",$_progress * 100}")%"
		fi
	done
	set_progress 1.0000000
}

# Extract_System
extract_system(){
	# Extract System Files
	$LT1 "FUNC Extract_System"
	if [ -e "$SOURCE" ]; then
		rm -rf "$SOURCE" 2>&1 | $LT2
		if [ -e "$SOURCE" ]; then
			LogMsg "Failed to remove $SOURCE (shame...)"
			SOURCE=/sdcard/__tmp2
			LogMsg "Using $SOURCE as tmp folder.."
		fi
	fi
	mkdir "$SOURCE" 2>&1 | $LT2
	if [ ! -e "$SOURCE" ]; then
		ui_print "- Unable to access sdcard"
		exit 1
	fi
	unzip -o "$ZIP" "system/*" -d "$SOURCE"
	if [ ! -e "$SOURCE" ]; then
		ui_print "- Unsuccessful.. Exiting."
		exit 1
	else
		$LT1 "successfully extracted files"
	fi
}

# aslib_init
install_aslib(){
	# -Backup aslib.func for addon.d
	$LT1 "- Backing aslib.func for addon.d" "uip"
	remount_mountpoint /data rw
	remount_mountpoint /system rw
	if [ ! -e /data/aslib ];then
		mkdir /data/aslib
	fi
	dd if=$LIBS/aslib.functions of=/data/aslib/aslib.functions 2>&1 | $LT2
	set_perm 0 0 0755 /data/aslib/aslib.functions
	# zip /tmp/core and put to addon.d
	cd /tmp/core/library
	zip libcore.zip aslib.functions
	cd /
	dd if=/tmp/core/library/libcore.zip of=/system/addon.d/libcore.zip 2>&1 | $LT2
	set_perm 0 0 0755 /system/addon.d/libcore.zip
	if [ ! -e "/data/aslib/aslib.functions" ] && [ ! -e "/system/addon.d/core.zip" ];then
		ui_print "!WARNING! failed to setup aslib"
		ui_print " -aslib dependent addon script might fail."
	fi
}

# init_wipe_list
init_wipe_list(){
	$LT1 "FUNC init_wipe_list"
	wipe_list=
	# Load Wipe list file from core
	for FILES in $(ls $COREDIR | grep .list | grep wipe);do
		if [ -e $COREDIR/$FILES ];then
			DATA=`cat $COREDIR/$FILES`
			wipe_list="${wipe_list}"$'\n'"${DATA}"
			wipe_list="$(echo "${wipe_list}" | sort -u | sed '/^$/d')"
		fi
	done
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

# aosi_script
aosi_script(){
	$LT1 "FUNC aosi_script"
	ui_print "- Scanning AOSI folder for zip"
	install_zip_loc=$(find /data/aosi/* /sdcard*/aosi/* -name *.zip -type f -follow 2>/dev/null)
	install_zip_bak=$(find /sdcard*/aosi/backup/* -name *.zip -type f -follow 2>/dev/null)

	if [ -z "$install_zip_loc" ] && [ -z "$install_zip_bak" ] && [ ! -e "$aosi_add1" ] && [ ! -e "$aosi_add2" ];then
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


# Post-Initialization
#--------------------------------------------------------------------------#

# init fd from aslib
init_fd

# init LogMsg from aslib
init_LogMsg

# print_header
tittle_header

# install aslib
install_aslib

# load wipe list
init_wipe_list

# aosi_init
asosi_init

# aosi setup install_tmp
$LT1 "- Setting install_tmp" "uip"
if [ -e $install_tmp ];then
	rm -rf $install_tmp 2>&1 | $LT2
fi
mkdir $install_tmp 2>&1 | $LT2

# Main
#--------------------------------------------------------------------------#
ui_print "- mounting system, data, sdcard"
remount_mountpoint /system ro
remount_mountpoint /data rw
remount_mountpoint /sdcard rw
remount_mountpoint /sdcard1 rw
mount -o rw, remount /      2>&1 | $LT2
mount -o rw, remount / /    2>&1 | $LT2

# Extract Files
#--------------------------------
ui_print "- Extracting files"
extract_system

# Remounting system
#--------------------------------
remount_mountpoint /system rw

# Removing unwanted files before installing
#--------------------------------
ui_print "- Removing Old Files"
if [ ! -z "$wipe_list" ];then
	wipe_files "$wipe_list"
fi

# remove existing addon.script
$LT1 "removing addon.d files"
rm -rf /system/addon.d/*$app_name* 2>&1 | $LT2

# Placing Files
#--------------------------------
ui_print "- Placing files"
install_system

# Main Script
#--------------------------------
ui_print "- Running Mainscript"
aosi_script

# Let's backup aosi zips
aosi_backup

# Cleaning
#--------------------------------
ui_print "- Cleaning up.."
# Cleaning /source
rm -rf "$SOURCE" 2>&1 | $LT2
if [ -e "$SOURCE" ]; then
	ui_print "-- Unable to remove $SOURCE"
	ui_print "-- please remove it manually."
fi

# aosi_script cleanup
for RMH in $aosi_bak_dir $install_tmp;do
	rm -rf $RMH
done

# Done
#--------------------------------
ui_print_always "- Done !"
if (! $LESSLOGGING); then
	sleep 5
fi