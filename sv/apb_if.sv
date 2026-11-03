`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if (input logic pclk, input logic presetn);

  // Requester (master) -> Completer (slave)
  logic [31:0] paddr;
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [31:0] pwdata;

  // Completer (slave) -> Requester (master)
  logic        pready;
  logic [31:0] prdata;

  // ---------------------------------------------------------------------------
  // Modports
  // ---------------------------------------------------------------------------
  modport master_mp (
    input  pclk, presetn, pready, prdata,
    output paddr, psel, penable, pwrite, pwdata
  );

  modport slave_mp (
    input  pclk, presetn, paddr, psel, penable, pwrite, pwdata,
    output pready, prdata
  );

  modport monitor_mp (
    input pclk, presetn, paddr, psel, penable, pwrite, pwdata, pready, prdata
  );

  // ---------------------------------------------------------------------------
  // Protocol assertions
  // ---------------------------------------------------------------------------
  // 1. PENABLE is never high without PSEL
  a_penable_needs_psel: assert property (
    @(posedge pclk) disable iff (!presetn)
    penable |-> psel
  ) else $error("APB: PENABLE high without PSEL");

  // 2. SETUP (psel=1, penable=0) is always followed by ACCESS in the next cycle
  a_setup_to_access: assert property (
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable) |=> (psel && penable)
  ) else $error("APB: SETUP phase not followed by ACCESS phase");

  // 3. While PREADY is low in ACCESS, the request must stay stable
  a_stable_while_wait: assert property (
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && !pready) |=>
      ($stable(paddr) && $stable(pwrite) && $stable(psel) &&
       $stable(penable) && (!pwrite || $stable(pwdata)))
  ) else $error("APB: signals changed during wait state");

  // 4. After the transfer completes (PREADY=1), PENABLE drops
  a_penable_drops: assert property (
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pready) |=> !penable
  ) else $error("APB: PENABLE stayed high after the transfer completed");

  // 5. No X/Z on the control signals after reset
  a_no_x_ctrl: assert property (
    @(posedge pclk) disable iff (!presetn)
    !$isunknown({psel, penable})
  ) else $error("APB: X on PSEL/PENABLE");

  // 6. PREADY must be known whenever it is sampled (ACCESS phase)
  a_pready_known: assert property (
    @(posedge pclk) disable iff (!presetn)
    (psel && penable) |-> !$isunknown(pready)
  ) else $error("APB: PREADY is X during ACCESS phase");

endinterface : apb_if

`endif // APB_IF_SV