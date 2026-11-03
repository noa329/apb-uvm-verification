`ifndef APB_CONFIG_SV
`define APB_CONFIG_SV

class apb_config extends uvm_object;

  apb_role_e   role = APB_MASTER;

  // Master driver: give up if PREADY stays low for this many cycles
  int unsigned max_wait_cycles = 1000;

  `uvm_object_utils_begin(apb_config)
    `uvm_field_enum(apb_role_e, role, UVM_ALL_ON)
    `uvm_field_int (max_wait_cycles,  UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "apb_config");
    super.new(name);
  endfunction : new

endclass : apb_config

`endif // APB_CONFIG_SV