`ifndef APB_MASTER_DRIVER_SV
`define APB_MASTER_DRIVER_SV

class apb_master_driver extends apb_base_driver;

  `uvm_component_utils(apb_master_driver)

  virtual apb_if.master_mp vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if.master_mp)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"Virtual interface (master_mp) must be set for: ", get_full_name(), ".vif"})
  endfunction : build_phase

  virtual task wait_reset_release();
    wait (vif.presetn === 1'b1);
  endtask : wait_reset_release

  virtual task reset_signals();
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
    vif.paddr   <= '0;
    vif.pwrite  <= 1'b0;
    vif.pwdata  <= '0;
  endtask : reset_signals

  virtual task drive_to_dut(apb_seq_item item);
    int unsigned waits = 0;

    repeat (item.delay_cycles) @(posedge vif.pclk);

    // ---------------- SETUP phase ----------------
    @(posedge vif.pclk);
    vif.psel    <= 1'b1;
    vif.penable <= 1'b0;
    vif.paddr   <= item.paddr;
    vif.pwrite  <= item.pwrite;
    vif.pwdata  <= (item.pwrite == APB_WRITE) ? item.pwdata : '0;

    // ---------------- ACCESS phase ----------------
    @(posedge vif.pclk);
    vif.penable <= 1'b1;

    // Stay in ACCESS until the completer asserts PREADY
    do begin
      @(posedge vif.pclk);
      if (vif.pready !== 1'b1) begin
        waits++;
        if (waits > cfg.max_wait_cycles) begin
          `uvm_error(get_type_name(),
            $sformatf("PREADY not asserted after %0d cycles - giving up", cfg.max_wait_cycles))
          break;
        end
      end
    end while (vif.pready !== 1'b1);

    // Transfer completes on this edge: capture the response
    if (item.pwrite == APB_READ) item.prdata = vif.prdata;
    item.wait_cycles = waits;   // observed wait states

    // ---------------- back to IDLE ----------------
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
  endtask : drive_to_dut

endclass : apb_master_driver

`endif // APB_MASTER_DRIVER_SV