#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2022 Western Digital Corporation or its affiliates.
#

. scripts/test_lib

if [ $# == 0 ]; then
	echo "Sysfs seq files active after write (default)"
        exit 0
fi

require_sysfs

zonefs_mkfs "$1"
zonefs_mount "$1"

i=0
maxact=$(get_max_active_zones "$1")
if [ ${maxact} -eq 0 ]; then
	maxact=4
fi

# Write 4K in maxact files
for((i=1; i<=${maxact}; i++)); do
	echo "Writing seq file ${i}"

	dd if=/dev/zero of="${zonefs_mntdir}/seq/${i}" bs=4096 \
		count=1 oflag=direct || \
		exit_failed "Write seq file ${i} failed"

	nract=$(sysfs_nr_active_seq_files "$1")
	[[ ${nract} -eq ${i} ]] || \
		exit_failed "nr_active_seq_files is ${nract} (should be ${i})"

	nrwro=$(sysfs_nr_wro_seq_files "$1")
	[[ ${nrwro} -eq 0 ]] || \
		exit_failed "nr_wro_seq_files is ${nrwro} after close (should be 0)"
done

# Remount and check again
zonefs_umount
zonefs_mount "$1"

nract=$(sysfs_nr_active_seq_files "$1")
[[ ${nract} -eq ${maxact} ]] || \
	exit_failed "nr_active_seq_files is ${nract} (should be ${maxact})"

nrwro=$(sysfs_nr_wro_seq_files "$1")
[[ ${nrwro} -eq 0 ]] || \
	exit_failed "nr_wro_seq_files is ${nrwro} after close (should be 0)"

# Fill-up the files: the active count should go to 0
for((i=1; i<=${maxact}; i++)); do
	echo "Filling seq file ${i}"

	fsize=$(file_max_size "${zonefs_mntdir}/seq/${i}")
	wcount=$(( fsize / 4096 - 1 ))

	dd if=/dev/zero of="${zonefs_mntdir}/seq/${i}" bs=4096 \
		seek=1 count=${wcount} oflag=direct conv=notrunc || \
		exit_failed "Fill seq file ${i} failed"

	n=$(( maxact - i ))

	nract=$(sysfs_nr_active_seq_files "$1")
	[[ ${nract} -eq ${n} ]] || \
		exit_failed "nr_active_seq_files is ${nract} (should be ${n})"

	nrwro=$(sysfs_nr_wro_seq_files "$1")
	[[ ${nrwro} -eq 0 ]] || \
		exit_failed "nr_wro_seq_files is ${nrwro} after close (should be 0)"
done

zonefs_umount

exit 0
