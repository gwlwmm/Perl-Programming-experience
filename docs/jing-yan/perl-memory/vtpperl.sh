#!/bin/bash
#$1设置为true，表示恢复所有服务，否则，使用perlproxy方式启动
back=$1
VTPPERL="/sf/bin/vtpperl.pl"

function tovtpperl
{
    local filepath=$(dirname $1)
    local filename=$(basename $1)
    local filename_vtpperl="${filename}.vtpperl"

    cd ${filepath} > /dev/null
    if [ -z ${back} ]; then
        [ -e ${filename_vtpperl} ] && return 0
        mv ${filename} ${filename_vtpperl}
        ln -sf ${VTPPERL} ${filename}
        echo -e "[\033[;32muse vtpproxy for $1\033[0m]"
    else
        [ ! -e ${filename_vtpperl} ] && return 0
        rm -f ${filename}
        mv ${filename_vtpperl} ${filename}
        echo -e "[\033[;32mback from vtpproxy for $1\033[0m]"
    fi
    cd - >/dev/null
    return 0
}
tovtpperl /sf/sbin/vtp-datareportd && /sf/etc/init.d/vtp-datareportd restart
tovtpperl /sf/sbin/vtp-vmmonitor   && /sf/etc/init.d/vtp-vmmonitor restart
tovtpperl /sf/sbin/vtp-vmstatusd   && /sf/etc/init.d/vtp-vmstatusd restart
tovtpperl /sf/cluster/bin/vtprgm   && /sf/etc/init.d/vtprgm restart
tovtpperl /sf/bin/network_topod    && /sf/etc/init.d/network_topod restart
tovtpperl /sf/bin/vtpdaemon && /sf/etc/init.d/vtpdaemon restart
tovtpperl /sf/bin/vtpalertd && /sf/etc/init.d/vtpalertd restart
tovtpperl /sf/bin/vtpqueued && /sf/etc/init.d/vtpqueued restart
tovtpperl /sf/bin/vtpmaild  && /sf/etc/init.d/vtpmaild restart
tovtpperl /sf/bin/vtpstatd  && /sf/etc/init.d/vtpstatd restart
tovtpperl /sf/bin/vtp-drs   && /sf/etc/init.d/vtp-drs restart
tovtpperl /sf/bin/vtplogd   && /sf/etc/init.d/vtplogd restart
tovtpperl /sf/bin/cacher    && /sf/etc/init.d/cacher restart
tovtpperl /sf/bin/DRXd      && /sf/etc/init.d/DRXd restart

