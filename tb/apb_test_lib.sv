
class apb_base_test extends uvm_test;

  `uvm_component_utils(apb_base_test)

  apb_agent   master_agent;
  apb_config  master_cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Configuration object: this agent is a master
    master_cfg = apb_config::type_id::create("master_cfg");
    master_cfg.role = APB_MASTER;
    uvm_config_db#(apb_config)::set(this, "master_agent", "cfg", master_cfg);

    // Active agent (driver + sequencer + monitor)
    uvm_config_db#(uvm_active_passive_enum)::set(this, "master_agent", "is_active", UVM_ACTIVE);

    master_agent = apb_agent::type_id::create("master_agent", this);
  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  virtual task run_phase(uvm_phase phase);
    uvm_objection obj = phase.get_objection();
    obj.set_drain_time(this, 100ns);
  endtask : run_phase

endclass : apb_base_test


class apb_single_test extends apb_base_test;

  `uvm_component_utils(apb_single_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_wrapper::set(this, "master_agent.sequencer.run_phase",
                            "default_sequence", apb_single_seq::get_type());
  endfunction : build_phase

endclass : apb_single_test


class apb_series_test extends apb_base_test;

  `uvm_component_utils(apb_series_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_wrapper::set(this, "master_agent.sequencer.run_phase",
                            "default_sequence", apb_series_seq::get_type());
  endfunction : build_phase

endclass : apb_series_test


class apb_write_read_test extends apb_base_test;

  `uvm_component_utils(apb_write_read_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_wrapper::set(this, "master_agent.sequencer.run_phase",
                            "default_sequence", apb_write_read_seq::get_type());
  endfunction : build_phase

endclass : apb_write_read_test


class apb_a2a_test extends apb_base_test;

  `uvm_component_utils(apb_a2a_test)

  apb_agent   slave_agent;
  apb_config  slave_cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);   // creates the master agent

    // Second agent: ACTIVE SLAVE
    slave_cfg = apb_config::type_id::create("slave_cfg");
    slave_cfg.role = APB_SLAVE;
    uvm_config_db#(apb_config)::set(this, "slave_agent", "cfg", slave_cfg);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "slave_agent", "is_active", UVM_ACTIVE);
    slave_agent = apb_agent::type_id::create("slave_agent", this);

    // Master: write then read back. Slave: answer every transfer.
    uvm_config_wrapper::set(this, "master_agent.sequencer.run_phase",
                            "default_sequence", apb_write_read_seq::get_type());
    uvm_config_wrapper::set(this, "slave_agent.sequencer.run_phase",
                            "default_sequence", apb_slave_resp_seq::get_type());
  endfunction : build_phase

endclass : apb_a2a_test