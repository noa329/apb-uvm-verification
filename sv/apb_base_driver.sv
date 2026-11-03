`ifndef APB_BASE_DRIVER_SV
`define APB_BASE_DRIVER_SV

class apb_base_driver extends uvm_driver #(apb_seq_item);

  `uvm_component_utils(apb_base_driver)

  apb_config     cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning("NOCFG", "No apb_config found - using defaults")
      cfg = apb_config::type_id::create("cfg");
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    reset_signals();
    wait_reset_release();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), {"Driving: ", req.convert2string()}, UVM_HIGH)
      drive_to_dut(req);
      seq_item_port.item_done();
    end
  endtask : run_phase

  virtual task wait_reset_release();
    `uvm_fatal("ABSTRACT", "wait_reset_release() must be implemented by the master/slave driver")
  endtask : wait_reset_release

  virtual task reset_signals();
    `uvm_fatal("ABSTRACT", "reset_signals() must be implemented by the master/slave driver")
  endtask : reset_signals

  virtual task drive_to_dut(apb_seq_item item);
    `uvm_fatal("ABSTRACT", "drive_to_dut() must be implemented by the master/slave driver")
  endtask : drive_to_dut

endclass : apb_base_driver

`endif // APB_BASE_DRIVER_SV