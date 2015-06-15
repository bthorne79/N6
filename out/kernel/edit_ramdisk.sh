#!/sbin/sh
#ramdisk_gov_sed.sh by show-p1984
#Features:
#extracts ramdisk
#finds busbox in /system or sets default location if it cannot be found
#add init.d support if not already supported
#removes governor overrides
#removes min freq overrides
#repacks the ramdisk

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
cd /

#remove cmdline parameters we do not want
#maxcpus=2 in this case, which limits smp activation to the first 2 cpus
echo $(cat /tmp/boot.img-cmdline | sed -e 's/maxcpus=[^ ]\+//')>/tmp/boot.img-cmdline

#add init.d support if not already supported
#this is no longer needed as the ramdisk now inserts our modules, but we will
#keep this here for user comfort, since having run-parts init.d support is a
#good idea anyway.
found=$(find /tmp/ramdisk/init.rc -type f | xargs grep -oh "run-parts /system/etc/init.d");
if [ "$found" != 'run-parts /system/etc/init.d' ]; then
        #find busybox in /system
        bblocation=$(find /system/ -name 'busybox')
        if [ -n "$bblocation" ] && [ -e "$bblocation" ] ; then
                echo "BUSYBOX FOUND!";
                #strip possible leading '.'
                bblocation=${bblocation#.};
        else
                echo "BUSYBOX NOT FOUND! init.d support will not work without busybox!";
                echo "Setting busybox location to /system/xbin/busybox! (install it and init.d will work)";
                #set default location since we couldn't find busybox
                bblocation="/system/xbin/busybox";
        fi
	#append the new lines for this option at the bottom
        echo "" >> /tmp/ramdisk/init.rc
        echo "service userinit $bblocation run-parts /system/etc/init.d" >> /tmp/ramdisk/init.rc
        echo "    oneshot" >> /tmp/ramdisk/init.rc
        echo "    class late_start" >> /tmp/ramdisk/init.rc
        echo "    user root" >> /tmp/ramdisk/init.rc
        echo "    group root" >> /tmp/ramdisk/init.rc
fi

#copy custom init.shamu.power.rc
cp /tmp/init.shamu.power.rc /tmp/ramdisk/init.shamu.power.rc
chmod 750 /tmp/ramdisk/init.shamu.power.rc

#copy custom init.shamu.rc
cp /tmp/fstab.shamu /tmp/ramdisk/fstab.shamu
chmod 750 /tmp/ramdisk/fstab.shamu

#remove governor overrides, use kernel default
#sed -i '/\/sys\/devices\/system\/cpu\/cpufreq\/interactive\/hispeed_freq/d' /tmp/ramdisk/init.shamu.power.rc
#sed -i '/\/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.shamu.power.rc
#sed -i '/\/sys\/devices\/system\/cpu\/cpu1\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.shamu.power.rc
#sed -i '/\/sys\/devices\/system\/cpu\/cpu2\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.shamu.power.rc
#sed -i '/\/sys\/devices\/system\/cpu\/cpu3\/cpufreq\/scaling_governor/d' /tmp/ramdisk/init.shamu.power.rc
#remove min_freq overrides, use kernel default
#sed -i '/\/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_min_freq/d' /tmp/ramdisk/init.shamu.power.rc
#sed -i '/\/sys\/devices\/system\/cpu\/cpu1\/cpufreq\/scaling_min_freq/d' /tmp/ramdisk/init.shamu.power.rc
#sed -i '/\/sys\/devices\/system\/cpu\/cpu2\/cpufreq\/scaling_min_freq/d' /tmp/ramdisk/init.shamu.power.rc
#sed -i '/\/sys\/devices\/system\/cpu\/cpu3\/cpufreq\/scaling_min_freq/d' /tmp/ramdisk/init.shamu.power.rc

#build.prop tweaks
cp /system/build.prop /system/build.prop.bak
mv /system/build.prop /tmp/build.prop
echo "windowsmgr.max_events_per_sec=150
ro.min_pointer_dur=8
ro.max.fling_velocity=12000
ro.min.fling_velocity=8000
video.accelerate.hw=1
debug.performance.tuning=1
persist.service.lgospd.enable=0
persist.service.pcsync.enable=0
touch.pressure.scale=0.003" >> /tmp/build.prop
mv /tmp/build.prop /system/build.prop
#some TCP stack tweaks:)
cp /system/etc/sysctl.conf /system/etc/sysctl.conf.bak
mv /system/etc/sysctl.conf /tmp/sysctl.conf
chmod 777 /tmp/sysctl.conf
echo "net.core.default_qdisc = fq_codel" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_rfc1337 = 1" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_window_scaling = 1" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_workaround_signed_windows = 1" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_sack = 1" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_fack = 1" >> /tmp/sysctl.conf
echo "net.ipv4.ip_no_pmtu_disc = 0" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_mtu_probing = 1" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_frto = 2" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_frto_response = 2" >> /tmp/sysctl.conf
echo "net.ipv4.tcp_slow_start_after_idle = 0" >> /tmp/sysctl.conf
echo 'net.core.wmem_max=12582912' >> /tmp/sysctl.conf
echo 'net.core.rmem_max=12582912' >> /tmp/sysctl.conf
echo 'net.ipv4.tcp_rmem= 10240 87380 12582912' >> /tmp/sysctl.conf
echo 'net.ipv4.tcp_wmem= 10240 87380 12582912' >> /tmp/sysctl.conf
mv /tmp/sysctl.conf /system/etc/sysctl.conf
rm /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz
cd /tmp/ramdisk/
find . | cpio -o -H newc | gzip > ../boot.img-ramdisk.gz
cd /
rm -rf /tmp/ramdisk

