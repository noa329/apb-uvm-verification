`ifndef APB_SLAVE_DRIVER_SV
`define APB_SLAVE_DRIVER_SV

class apb_slave_driver extends apb_base_driver;

  `uvm_component_utils(apb_slave_driver)

  virtual apb_if.slave_mp vif;

  protected bit [31:0] mem [bit [31:0]];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if.slave_mp)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"Virtual interface (slave_mp) must be set for: ", get_full_name(), ".vif"})
  endfunction : build_phase

  virtual task wait_reset_release();
    wait (vif.presetn === 1'b1);
  endtask : wait_reset_release

  virtual task reset_signals();
    vif.pready <= 1'b0;
    vif.prdata <= '0;
  endtask : reset_signals

  virtual task drive_to_dut(apb_seq_item item);
    bit [31:0] addr, wdata;
    bit        is_write;

    // ---------------- wait for the SETUP phase ----------------
    do @(posedge vif.pclk);
    while (!(vif.psel === 1'b1 && vif.penable === 1'b0));

    // Setup values are visible on this edge: capture the request
    addr     = vif.paddr;
    is_write = vif.pwrite;
    wdata    = vif.pwdata;

    item.paddr  = addr;
    item.pwrite = apb_direction_e'(is_write);
    item.pwdata = is_write ? wdata : '0;

    // Read data is placed on the bus for the ACCESS phase
    if (!is_write) begin
      item.prdata = mem.exists(addr) ? mem[addr] : addr;
      vif.prdata <= item.prdata;
    end

    // ---------------- ACCESS phase: wait states ----------------
    vif.pready <= (item.wait_cycles == 0);
    for (int i = 0; i < item.wait_cycles; i++) begin
      @(posedge vif.pclk);                       // end of a wait cycle
      if (i == item.wait_cycles - 1) vif.pready <= 1'b1;
    end

    // ---------------- ACCESS phase: completing cycle ----------------
    @(posedge vif.pclk);                         // transfer completes here
    if (is_write) mem[addr] = wdata;

    // back to idle
    vif.pready <= 1'b0;
    vif.prdata <= '0;
  endtask : drive_to_dut

endclass : apb_slave_driver

`endif // APB_SLAVE_DRIVER_SV