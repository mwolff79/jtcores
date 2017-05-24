#!/bin/bash

DUMP=NODUMP
CHR_DUMP=NOCHR_DUMP
RAM_INFO=NORAM_INFO

while [ $# -gt 0 ]; do
	if [ "$1" = "-w" ]; then
		DUMP=DUMP
		echo Signal dump enabled
		shift
		continue
	fi
	if [ "$1" = "-ch" ]; then
		CHR_DUMP=CHR_DUMP
		echo Character dump enabled
		shift
		continue
	fi
	if [ "$1" = "-info" ]; then
		RAM_INFO=RAM_INFO
		echo RAM information enabled
		shift
		continue
	fi
	echo "Unknown option $1"
	exit 1
done

iverilog jt_gng_test.v \
	../../hdl/*.v \
	../../modules/mc6809/{mc6809.v,mc6809i.v} \
	-s jt_gng_test -o sim \
	-D$DUMP -D$CHR_DUMP -D$RAM_INFO\
&& sim -lxt