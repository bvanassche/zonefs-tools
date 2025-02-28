#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2019 Western Digital Corporation or its affiliates.
#

. scripts/test_lib

if [ $# == 0 ]; then
	echo "Conventional file random write (aggr_cnv)"
        exit 0
fi

require_cnv_files
require_program fio

echo "Check conventional file random write, aggr_cnv"

zonefs_mkfs "-o aggr_cnv $1"
zonefs_mount "$1"

fio --name=cnv_rndwr --filename="$zonefs_mntdir"/cnv/0 \
    --rw=randwrite --ioengine=libaio --iodepth=8 --size="$(aggr_cnv_size)" \
    --bs=131072 --verify=md5 --do_verify=1 --overwrite=1 \
    --continue_on_error=none || \
    exit_failed " --> FAILED"

zonefs_umount

exit 0
