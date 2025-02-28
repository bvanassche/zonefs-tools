#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2019 Western Digital Corporation or its affiliates.
#

. scripts/test_lib

if [ $# == 0 ]; then
        echo "Number of files using stat (aggr_cnv)"
        exit 0
fi

require_cnv_files

echo "Check for number of files: 1 aggr_cnv, $num_seq_files seq"

zonefs_mkfs "-o aggr_cnv $1"
zonefs_mount "$1"

nr_files=$(file_number "$zonefs_mntdir")

nr_s_files=$nr_seq_files
if [ "$nr_seq_files" != 0 ]; then
	nr_s_files=$(( nr_s_files + 1 ))
fi

if [ $nr_cnv_files != 0 ]; then
	nr_c_files=2
else
	nr_c_files=0
fi

nr_expected_files=$(( nr_s_files + nr_c_files ))
if [ "$nr_files" != "$nr_expected_files" ]; then
        echo " --> Invalid number of total zones file:"
        echo " --> Expected $nr_expected_files, got $nr_files"
        exit 1
fi

zonefs_umount

exit 0
