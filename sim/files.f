// files.f - run from apb_lab/sim:
//   xrun -f files.f +UVM_TESTNAME=apb_write_read_test +UVM_VERBOSITY=UVM_MEDIUM

-uvm
-uvmhome CDNS-1.2
-access +rwc
-timescale 1ns/1ps

-incdir ../sv
-incdir ../tb

// Order matters: interface first, then the package that uses it
../sv/apb_if.sv
../sv/apb_pkg.sv

// Testbench
../tb/apb_slave.sv
../tb/tb_top.sv

-top tb_top