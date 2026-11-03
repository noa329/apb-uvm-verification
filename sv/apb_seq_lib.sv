`ifndef APB_SEQ_LIB_SV
`define APB_SEQ_LIB_SV

class apb_base_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_base_seq)

  function new(string name = "apb_base_seq");
    super.new(name);
    // Raise/drop the run_phase objection automatically while the sequence runs
    // (needed when the sequence is set as a default_sequence)
    set_automatic_phase_objection(1);
  endfunction
endclass : apb_base_seq


class apb_single_seq extends apb_base_seq;
  `uvm_object_utils(apb_single_seq)

  function new(string name = "apb_single_seq");
    super.new(name);
  endfunction

  virtual task body();
    req = apb_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize())
      `uvm_fatal(get_type_name(), "Randomization failed")
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("Sent: %s", req.convert2string()), UVM_MEDIUM)
  endtask
endclass : apb_single_seq


class apb_series_seq extends apb_base_seq;
  `uvm_object_utils(apb_series_seq)

  rand int unsigned num_trans;
  constraint c_num_trans { num_trans inside {[1:10]}; }

  function new(string name = "apb_series_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Starting series of %0d transfers", num_trans), UVM_LOW)
    repeat (num_trans) begin
      `uvm_do(req)
      `uvm_info(get_type_name(), $sformatf("Sent: %s", req.convert2string()), UVM_MEDIUM)
    end
  endtask
endclass : apb_series_seq


class apb_write_read_seq extends apb_base_seq;
  `uvm_object_utils(apb_write_read_seq)

  rand int unsigned num_trans;
  constraint c_num_trans { num_trans inside {[2:8]}; }

  function new(string name = "apb_write_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [31:0] expected [bit [31:0]];  
    int        errors = 0;

    // Phase 1: writes
    repeat (num_trans) begin
      `uvm_do_with(req, { pwrite == APB_WRITE; })
      expected[req.paddr] = req.pwdata;
    end

    foreach (expected[addr]) begin
      `uvm_do_with(req, { pwrite == APB_READ; paddr == addr; })
      if (req.prdata !== expected[addr]) begin
        `uvm_error(get_type_name(),
          $sformatf("Readback mismatch @0x%08x: expected 0x%08x, got 0x%08x",
                    addr, expected[addr], req.prdata))
        errors++;
      end
    end

    if (errors == 0)
      `uvm_info(get_type_name(), "Readback check PASSED", UVM_LOW)
  endtask
endclass : apb_write_read_seq

class apb_slave_resp_seq extends uvm_sequence #(apb_seq_item);
  `uvm_object_utils(apb_slave_resp_seq)

  function new(string name = "apb_slave_resp_seq");
    super.new(name);
  endfunction

  virtual task body();
    forever begin
      `uvm_do(req)
      `uvm_info(get_type_name(), $sformatf("Slave answered: %s", req.convert2string()), UVM_HIGH)
    end
  endtask
endclass : apb_slave_resp_seq

`endif // APB_SEQ_LIB_SV