`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  virtual apb_if.monitor_mp vif;

  uvm_analysis_port #(apb_seq_item) item_collected_port;

  int unsigned num_trans;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    if (!uvm_config_db#(virtual apb_if.monitor_mp)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"Virtual interface (monitor_mp) must be set for: ", get_full_name(), ".vif"})
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    collect_transfers();
  endtask : run_phase

  virtual task collect_transfers();
    apb_seq_item item;
    int unsigned waits;

    wait (vif.presetn === 1'b1);

    forever begin
      @(posedge vif.pclk);
      if (vif.presetn !== 1'b1) continue;

      // SETUP phase detected
      if (vif.psel === 1'b1 && vif.penable === 1'b0) begin
        item        = apb_seq_item::type_id::create("item");
        item.paddr  = vif.paddr;
        item.pwrite = apb_direction_e'(vif.pwrite);
        item.pwdata = (item.pwrite == APB_WRITE) ? vif.pwdata : '0;

        // ACCESS phase: loop until the completer asserts PREADY
        waits = 0;
        do begin
          @(posedge vif.pclk);
          if (vif.pready !== 1'b1) waits++;
        end while (vif.pready !== 1'b1);

        item.wait_cycles = waits;
        if (item.pwrite == APB_READ) item.prdata = vif.prdata;

        num_trans++;
        `uvm_info(get_type_name(), {"Collected: ", item.convert2string()}, UVM_MEDIUM)
        item_collected_port.write(item);
      end
    end
  endtask : collect_transfers

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("Collected %0d transfers", num_trans), UVM_LOW)
  endfunction : report_phase

endclass : apb_monitor

`endif // APB_MONITOR_SV