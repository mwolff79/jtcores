#!/bin/bash

iverilog test.v ../../doc/k052109*.v ../../doc/cells/*.v -o sim -s test && sim -lxt
rm -f sim