`ifndef APB_SEQ_ITEM_SV
`define APB_SEQ_ITEM_SV

class apb_seq_item extends uvm_sequence_item;

  rand logic [31:0]    paddr;
  rand apb_direction_e pwrite;
  rand logic [31:0]    pwdata;
  rand int unsigned    delay_cycles;  // idle cycles before the transfer (used by master)
  rand int unsigned    wait_cycles;   // PREADY=0 cycles inserted (used by slave)

logic [31:0] prdata = '0;

  `uvm_object_utils_begin(apb_seq_item)
    `uvm_field_int (paddr,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(apb_direction_e, pwrite, UVM_ALL_ON)
    `uvm_field_int (pwdata,       UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (prdata,       UVM_ALL_ON | UVM_HEX)
    `uvm_field_int (delay_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int (wait_cycles,  UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  constraint c_aligned_addr { paddr[1:0] == 2'b00; }

  constraint c_addr_range   { soft paddr inside {[0:252]}; }

  constraint c_delay        { delay_cycles inside {[0:3]}; }
  constraint c_wait         { wait_cycles  inside {[0:3]}; }

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("Addr=0x%08x Dir=%s WData=0x%08x RData=0x%08x Delay=%0d Wait=%0d",
                     paddr, pwrite.name(), pwdata, prdata, delay_cycles, wait_cycles);
  endfunction : convert2string

endclass : apb_seq_item

`endif // APB_SEQ_ITEM_SV