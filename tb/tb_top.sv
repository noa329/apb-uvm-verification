module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import apb_pkg::*;
  `include "apb_test_lib.sv"

  logic pclk;
  logic presetn;

  initial begin
    pclk = 1'b0;
    forever #5 pclk = ~pclk;
  end

  initial begin
    presetn = 1'b0;
    repeat (5) @(posedge pclk);
    presetn <= 1'b1;
  end

  apb_if apb_vif (.pclk(pclk), .presetn(presetn));

`ifndef APB_NO_DUT
  apb_slave dut (
    .pclk    (pclk),
    .rst_n   (presetn),
    .paddr   (apb_vif.paddr),
    .psel    (apb_vif.psel),
    .penable (apb_vif.penable),
    .pwrite  (apb_vif.pwrite),
    .pwdata  (apb_vif.pwdata),
    .pready  (apb_vif.pready),
    .prdata  (apb_vif.prdata)
  );
`endif   // APB_NO_DUT: agent-to-agent mode has no DUT

  initial begin
    $shm_open("apb_waves.shm");
    $shm_probe("AS");
  end

  initial begin
    uvm_config_db#(virtual apb_if.master_mp )::set(null, "uvm_test_top.master_agent.driver", "vif", apb_vif.master_mp);
    uvm_config_db#(virtual apb_if.slave_mp  )::set(null, "uvm_test_top.slave_agent.driver",  "vif", apb_vif.slave_mp);
    uvm_config_db#(virtual apb_if.monitor_mp)::set(null, "uvm_test_top.*.monitor",            "vif", apb_vif.monitor_mp);
    run_test();
  end

endmodule : tb_top