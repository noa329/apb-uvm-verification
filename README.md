# UVM APB UVC

A reusable **UVM Universal Verification Component (UVC)** for the **AMBA APB** protocol, written in SystemVerilog.
The agent can act as an APB **master (Requester)** or **slave (Completer)**, in **active** or **passive** mode,
and comes with protocol assertions, sequences, and a testbench that verifies it against a simple APB slave DUT.
As an extra check, a master agent and a slave agent are connected directly to each other (no DUT).

Built as a hands-on verification exercise, following the *AMBA APB Protocol Specification* (ARM IHI 0024E).

## Features

- **Master and slave agents** selected by a configuration object (`apb_config.role`)
- **Active / passive** operation using the standard `is_active` setting
- **Separate drivers** (`apb_master_driver`, `apb_slave_driver`) built on a common base driver;
  the only role-specific behavior is `drive_to_dut()`
- **Interface with three modports** (`master_mp`, `slave_mp`, `monitor_mp`), each used by the matching component
- **SystemVerilog Assertions** in the interface (see below)
- **Monitor** that collects completed transfers, counts wait states, and publishes them on an analysis port
- **Wait-state support**: the slave driver can hold `PREADY` low for a random number of cycles
- **Sequence library**: single transfer, random series, write-then-readback, and an endless slave response sequence

## Architecture

```
uvm_test
 ├── master_agent (apb_agent, role = MASTER)
 │    ├── sequencer ──► apb_master_driver ──┐
 │    └── apb_monitor ◄─────────────────────┤
 │                                          ▼
 │                                      apb_if  ◄──►  DUT (apb_slave)
 │                                          ▲          or
 └── slave_agent  (apb_agent, role = SLAVE) │
      ├── sequencer ──► apb_slave_driver ───┘
      └── apb_monitor
```

The agent builds the driver that matches `cfg.role`. In the agent-to-agent test the DUT is removed and the two agents
share one `apb_if`.

## Repository layout

```
sv/                      The UVC (reusable)
  apb_if.sv              Interface: signals, modports, SVA (compiled before the package)
  apb_pkg.sv             Package: imports UVM, includes all files in dependency order
  apb_types.sv           Enums: transfer direction, agent role
  apb_seq_item.sv        Transaction item
  apb_seq_lib.sv         Sequences
  apb_config.sv          Agent configuration object
  apb_sequencer.sv       Sequencer
  apb_monitor.sv         Monitor
  apb_base_driver.sv     Common driver logic
  apb_master_driver.sv   Master driver
  apb_slave_driver.sv    Slave driver
  apb_agent.sv           Agent
tb/                      Testbench
  tb_top.sv              Clock, reset, interface, DUT, config DB, run_test()
  apb_test_lib.sv        Tests
  apb_slave.sv           APB slave DUT with a small memory
sim/
  files.f                Xcelium file list
```

## Protocol checks (SVA in `apb_if`)

| Assertion | Rule |
|---|---|
| `a_penable_needs_psel` | `PENABLE` is never high without `PSEL` |
| `a_setup_to_access` | SETUP is always followed by ACCESS in the next cycle |
| `a_stable_while_wait` | Address, direction, select, enable and write data stay stable while `PREADY` is low |
| `a_penable_drops` | `PENABLE` drops after the transfer completes |
| `a_no_x_ctrl` | No X/Z on `PSEL`/`PENABLE` after reset |
| `a_pready_known` | `PREADY` is known during the ACCESS phase |

## Tests

| Test | What it does |
|---|---|
| `apb_single_test` | One random transfer from an active master |
| `apb_series_test` | A random series of transfers (1 to 10) |
| `apb_write_read_test` | Writes random data to random addresses, reads every address back, and compares |
| `apb_a2a_test` | **No DUT.** A master agent and a slave agent communicate directly, with random wait states |

## Running

Tested with Cadence Xcelium 24.09 and the bundled UVM 1.2 (`-uvmhome CDNS-1.2`). Run from `sim/`.

Against the DUT:

```
xrun -f files.f +UVM_TESTNAME=apb_write_read_test +UVM_VERBOSITY=UVM_MEDIUM
```

Agent-to-agent (no DUT):

```
xrun -f files.f -clean +define+APB_NO_DUT +UVM_TESTNAME=apb_a2a_test +UVM_VERBOSITY=UVM_MEDIUM
```

Add `-gui` to open SimVision. A waveform database (`apb_waves.shm`) is written by `tb_top.sv`.
Use `-clean` when switching between the DUT and no-DUT builds.

## Results

All four tests finish with `UVM_ERROR: 0`, `UVM_FATAL: 0` and no assertion failures.

- `apb_write_read_test` and `apb_a2a_test` report `Readback check PASSED`.
- In the agent-to-agent test both monitors collect the same transfers, including transfers with 1 to 3 wait states.

## Design notes

- **Driving style.** Drivers change signals with non-blocking assignments right after the clock edge, so the monitor and
  the DUT sample the previous values at that edge and there is no race.
- **Monitor.** Samples on every `posedge PCLK`: SETUP captures the request, ACCESS counts wait cycles until `PREADY`, and the
  completing edge captures read data.
- **Slave driver.** Needs an item to be ready before a transfer starts, so the slave runs `apb_slave_resp_seq`, which
  supplies items forever. That sequence deliberately raises no objection; the run phase ends when the master side is done.
- **Slave memory.** Unwritten locations return their own address, matching the initial contents of the DUT memory.
- **DUT fixes.** The DUT used in the exercise needed small corrections (port declarations with direction and width,
  32-bit memory entries, address indexing). The state machine behavior is unchanged.

## Scope and limitations

- Implemented signals: `PCLK`, `PRESETn`, `PADDR`, `PSEL`, `PENABLE`, `PWRITE`, `PWDATA`, `PREADY`, `PRDATA`.
- Not implemented: `PSLVERR`, `PSTRB`, `PPROT`, and the APB5 extensions (wake-up, user signals, parity, RME).
- No scoreboard or functional coverage yet.
- A reset asserted in the middle of a transfer is not handled by the drivers.
- Passive mode is supported by the agent but has no dedicated test.

## Possible extensions

Scoreboard, functional coverage in the monitor, `PSLVERR` and `PSTRB` support, a passive-mode test, and mid-transfer reset handling.

## Reference

AMBA APB Protocol Specification, Arm document IHI 0024E (available from the Arm Developer website).
