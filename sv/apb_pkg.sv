`ifndef APB_PKG_SV
`define APB_PKG_SV

package apb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Types (enums) - used by everything below
  `include "apb_types.sv"

  // 2. Transaction item and sequences
  `include "apb_seq_item.sv"
  `include "apb_seq_lib.sv"

  // 3. Agent building blocks
  `include "apb_config.sv"
  `include "apb_sequencer.sv"
  `include "apb_monitor.sv"
  `include "apb_base_driver.sv"
  `include "apb_master_driver.sv"
  `include "apb_slave_driver.sv"

  // 4. Agent - last, it uses everything above
  `include "apb_agent.sv"

endpackage : apb_pkg

`endif // APB_PKG_SV