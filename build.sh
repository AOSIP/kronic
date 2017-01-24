#!/usr/bin/env bash
export logfile="kronic/logs/${device}/$(date +%Y%m%d-%H%M).log";
export AOSIP_BUILDTYPE="Official";
mkdir -pv ./kronic/logs/${device};
. build/envsetup.sh >> $logfile;
rm -rf .repo/local_manifests;
./sync.sh >> $logfile;
make clobber 2>&1 | tee -a $logfile;
export device=$1
if [ -z $device ];
	then
	echo -e "No device found, exiting!" >> $logfile
	exit 1
fi
lunch aosip_$device-userdebug
export USE_CCACHE=1
export CCACHE_DIR=${HOME}/.ccache-${device}
ccache -M 25G >> $logfile
if [ -z $THREAD ];
	then
	export THREAD=$(grep -c "^processor" /proc/cpuinfo)
fi
time make -j8 kronic 2>&1 | tee -a ${logfile};
if [ "$(ls ${OUT}/AOSiP*.zip 2> /dev/null | wc -l)" != "0" ];
	then
	echo "BUILD SUCCESFUL" >> $logfile;
	rsync -av $OUT/A* kronic@aosip.xyz:downloads.aosip.xyz/n-mr1/${device} >> $logfile;
else
	echo "BUILD FAILED" >> $logfile;
	echo "Check for errors in ${logfile}";
fi

echo -e "Stopping jack server" >> $logfile;
./prebuilts/sdk/tools/jack-admin stop-server >> $logfile;

echo -e "Pushing logs up!";
cd kronic;
git add -A; git commit -asm $(date +%Y%m%d); git fetch origin master; git rebase origin/master; git push origin master;
cd -;
