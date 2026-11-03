`ifndef APB_AGENT_SV
`define APB_AGENT_SV

class apb_agent extends uvm_agent;

  apb_monitor      monitor;
  apb_sequencer    sequencer;
  apb_base_driver  driver;     
  apb_config       cfg;

  uvm_analysis_port #(apb_seq_item) item_collected_port;

  `uvm_component_utils(apb_agent)

  function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active))
      is_active = UVM_ACTIVE;
    super.build_phase(phase);

    if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning("NOCFG", "No apb_config found - using defaults (master)")
      cfg = apb_config::type_id::create("cfg");
    end
    uvm_config_db#(apb_config)::set(this, "*", "cfg", cfg);

    item_collected_port = new("item_collected_port", this);
    monitor = apb_monitor::type_id::create("monitor", this);

    if (is_active == UVM_ACTIVE) begin
      sequencer = apb_sequencer::type_id::create("sequencer", this);
      if (cfg.role == APB_MASTER)
        driver = apb_master_driver::type_id::create("driver", this);
      else
        driver = apb_slave_driver::type_id::create("driver", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.item_collected_port.connect(item_collected_port);
    if (is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction : connect_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(get_type_name(),
      $sformatf("APB agent: role=%s, %s", cfg.role.name(), is_active.name()), UVM_LOW)
  endfunction : start_of_simulation_phase

endclass : apb_agent

`endif // APB_AGENT_SV