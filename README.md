# RISC-V Pipelined SoC with AXI4 Memory Interface

> A **5-stage pipelined RISC-V RV32I processor** integrated into a complete **System-on-Chip (SoC)** with instruction and data caches and an AXI4-Lite read interface — implemented in Verilog HDL for Xilinx Vivado.

---

## Overview

This project implements a full **RISC-V RV32I SoC** built around a 5-stage in-order pipeline. Unlike a simple single-cycle core, this design introduces real hardware challenges: pipeline hazards, data forwarding, cache hierarchies, and bus protocol integration.

The SoC connects a pipelined RISC-V core to a unified cache subsystem (separate instruction and data caches) that fetches missing cache lines from external memory over an **AXI4 read channel**. This mirrors how real microprocessors interact with off-chip memory.

### Key Features

- **5-Stage Pipeline**: Fetch → Decode → Execute → Memory → Write-Back
- **Hazard Detection and Stall Logic**: Automatically stalls the pipeline on cache misses and data hazards
- **Separate I-Cache and D-Cache**: Direct-mapped caches with a shared AXI4 read master
- **AXI4-Lite Read Interface**: Industry-standard bus protocol for memory access
- **AXI Interconnect**: Routes the core's AXI master to the external slave memory
- **Full Testbench**: Includes an AXI slave memory model pre-loaded with test instructions

---

## Architecture

### SoC Block Diagram

```
  +-------------------------------------------------------------------+
  |                         SoC Top (soc_top.v)                       |
  |                                                                   |
  |  +------------------+       +-------------------+                |
  |  | RISC-V Core      |       |  Cache Subsystem  |                |
  |  | (riscv_top.v)    |       |  (cache_top.v)    |                |
  |  |                  |       |                   |                |
  |  | Fetch  ---icache_req---> | I-Cache           |                |
  |  | Decode            |      |                   |                |
  |  | Execute           |      | D-Cache           |                |
  |  | Memory ---dcache_req---> |                   |                |
  |  | Writeback         |      |  Cache Arbiter    |                |
  |  +------------------+       +--------+----------+                |
  |                                      |                           |
  |                             +--------v----------+                |
  |                             | AXI Master        |                |
  |                             | Interface         |                |
  |                             | (axi_master_      |                |
  |                             |  interface.v)     |                |
  |                             +--------+----------+                |
  |                                      |                           |
  |                             +--------v----------+                |
  |                             | AXI Interconnect  |                |
  |                             | (axi_interconnect)|                |
  |                             +--------+----------+                |
  |                                      |                           |
  +--------------------------------------+---------------------------+
                                         |  AXI4 Read Channel
                                         v
                              +------------------+
                              |  External Memory |
                              |  (Slave / TB)    |
                              +------------------+
```

### 5-Stage Pipeline

```
  +-------+    +--------+    +---------+    +--------+    +-----------+
  | FETCH |    | DECODE |    | EXECUTE |    | MEMORY |    | WRITEBACK |
  |       |--->|        |--->|         |--->|        |--->|           |
  |  PC   |    | Reg    |    | ALU     |    | D-Cache|    | Result    |
  | I-Cach|    | File   |    | Branch  |    | R/W    |    | Mux       |
  |       |    | Imm-Gen|    | Target  |    |        |    | Reg Write |
  +-------+    +--------+    +---------+    +--------+    +-----------+
       ^            ^
       |            |
  +----+------------+----+
  |   Hazard & Forwarding |
  |   Unit                |
  |   (hazard_forwarding) |
  +-----------------------+
```

### Cache Miss Flow

When the pipeline requests an instruction or data word not in cache:

```
  Core requests address
         |
    Cache miss detected
         |
    Cache sends AXI read request (ARADDR, ARVALID)
         |
    AXI Master drives AXI4 bus handshake
         |
    Memory responds with data (RDATA, RVALID)
         |
    Cache is updated (cache line filled)
         |
    Pipeline stall released, core resumes
```

---

## Source File Reference

### RTL Design Sources (`riscv_axi_soc.srcs/sources_1/new/`)

| File | Module | Role |
|---|---|---|
| `soc_top.v` | `soc_top` | Top-level SoC: instantiates and wires all subsystems |
| `riscv_top.v` | `riscv_top` | 5-stage pipeline core; interfaces to cache system |
| `fetch.v` | `fetch` | IF stage: Program Counter and fetch request logic |
| `decode.v` | `decode` | ID stage: Instruction decode, register read, immediate generation |
| `execute.v` | `execute` | EX stage: ALU operations, branch target calculation |
| `memory_stage.v` | `memory_stage` | MEM stage: Data cache read/write interface |
| `writeback.v` | `writeback` | WB stage: Selects ALU result or memory data for register write |
| `hazard_forwarding.v` | `hazard_forwarding` | Detects hazards; generates stall and flush signals |
| `cache_top.v` | `cache_top` | Combines I-Cache, D-Cache, and arbiter into one block |
| `cache_controller.v` | `cache_controller` | Direct-mapped cache FSM (handles hit/miss, AXI fill) |
| `AXI Master Interface.v` | `axi_master_interface` | AXI4 read master: drives ARADDR/ARVALID and collects RDATA |
| `axi_interconnect.v` | `axi_interconnect` | Routes AXI master signals to the SoC's external AXI slave port |

### Simulation Sources (`riscv_axi_soc.srcs/sim_1/new/`)

| File | Module | Role |
|---|---|---|
| `tb_soc_top.v` | `tb_soc_top` | Top-level testbench; drives clock/reset and monitors AXI traffic |
| `memory_model.v` | `memory_model` | AXI4 slave: 4 KB SRAM pre-loaded with test instructions |

---

## Supported Instructions (RV32I)

### R-Type (Register-Register)
| Instruction | Operation |
|---|---|
| `ADD`, `SUB` | Integer add / subtract |
| `AND`, `OR`, `XOR` | Bitwise logical |
| `SLL`, `SRL`, `SRA` | Shift left / right (logical / arithmetic) |
| `SLT`, `SLTU` | Set less than (signed / unsigned) |

### I-Type (Immediate and Load)
| Instruction | Operation |
|---|---|
| `ADDI`, `ANDI`, `ORI`, `XORI` | Immediate arithmetic and logical |
| `SLLI`, `SRLI`, `SRAI` | Immediate shifts |
| `SLTI`, `SLTIU` | Set less than immediate |
| `LW` | `rd = Mem[rs1 + imm]` |
| `JALR` | `rd = PC+4; PC = rs1 + imm` |

### S-Type (Store)
| Instruction | Operation |
|---|---|
| `SW` | `Mem[rs1 + imm] = rs2` |

### B-Type (Branch)
| Instruction | Operation |
|---|---|
| `BEQ` | Branch if `rs1 == rs2` |
| `BNE` | Branch if `rs1 != rs2` |

### U-Type (Upper Immediate)
| Instruction | Operation |
|---|---|
| `LUI` | `rd = imm << 12` |
| `AUIPC` | `rd = PC + (imm << 12)` |

### J-Type (Jump)
| Instruction | Operation |
|---|---|
| `JAL` | `rd = PC+4; PC += imm` |

---

## Project File Structure

```
RISCV_Pipelined_AXI_SoC/
|
|-- README.md                               <- This file
|-- .gitignore                              <- Vivado build artifact exclusions
|-- riscv_axi_soc.xpr                      <- Vivado project file
|
`-- riscv_axi_soc.srcs/
    |
    |-- sources_1/new/                      <- RTL Design Sources
    |   |-- soc_top.v                       <- Top-level SoC integration
    |   |-- riscv_top.v                     <- 5-stage pipelined RISC-V core
    |   |-- fetch.v                         <- IF: Program Counter and fetch logic
    |   |-- decode.v                        <- ID: Instruction decode and imm-gen
    |   |-- execute.v                       <- EX: ALU and branch target calc
    |   |-- memory_stage.v                  <- MEM: Data cache interface
    |   |-- writeback.v                     <- WB: Result selection MUX
    |   |-- hazard_forwarding.v             <- Hazard detection and stall control
    |   |-- cache_top.v                     <- Cache subsystem (I$ + D$ + arbiter)
    |   |-- cache_controller.v              <- Direct-mapped cache FSM
    |   |-- AXI Master Interface.v          <- AXI4 read master FSM
    |   `-- axi_interconnect.v              <- 1:1 master-slave bus routing
    |
    `-- sim_1/new/                          <- Simulation Sources
        |-- tb_soc_top.v                    <- Top-level testbench
        `-- memory_model.v                  <- AXI slave memory model (4 KB)
```

---

## Getting Started

### Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| **Xilinx Vivado** | 2024.1 or later | Synthesis, Implementation, Simulation |
| **Git** | 2.x | Version control |

### Clone and Open

```bash
# Clone the repository
git clone https://github.com/Kpooja-embedded/RISCV_Pipelined_AXI_SoC.git
cd RISCV_Pipelined_AXI_SoC

# Open in Vivado (from Tcl Console)
open_project riscv_axi_soc.xpr
```

Or in the Vivado GUI: **File -> Open Project -> select `riscv_axi_soc.xpr`**

---

## Simulation and Verification

### Testbench Architecture

The testbench (`tb_soc_top.v`) instantiates the complete SoC and connects it to a 4 KB AXI slave memory model pre-loaded with RISC-V instructions:

```
  +----------------+       AXI4 Read Channel       +----------------+
  |   soc_top      |----ARADDR, ARVALID, ARREADY--->|  memory_model  |
  |    (DUT)       |<---RDATA, RVALID, RREADY-------|  (AXI Slave)   |
  +----------------+                               +----------------+
```

### Pre-Loaded Test Program

| Address | Hex Encoding | Assembly | Operation |
|---|---|---|---|
| `0x00` | `0x00500113` | `li x2, 5` | Load immediate 5 into x2 |
| `0x04` | `0x00600193` | `li x3, 6` | Load immediate 6 into x3 |
| `0x08` | `0x00310233` | `add x4, x2, x3` | x4 = x2 + x3 = 11 |

### Simulation Parameters

| Parameter | Value |
|---|---|
| **Clock Frequency** | 50 MHz (period = 20 ns) |
| **Reset Duration** | 100 ns (active-low `rst_n`) |
| **Simulation Duration** | 1100 ns total |
| **Timescale** | `1ns / 1ps` |

### Running in Vivado

```
1. Open the project in Vivado
2. Flow Navigator -> Simulation -> Run Behavioral Simulation
3. Observe AXI handshake, cache hit/miss, and register write-back in waveforms
```

Or from the Tcl Console:

```tcl
launch_simulation
run 1100ns

# Add key signals to waveform
add_wave /tb_soc_top/uut/u_riscv_core/pc_fetch
add_wave /tb_soc_top/axi_addr
add_wave /tb_soc_top/axi_rdata
add_wave /tb_soc_top/uut/u_cache_system/u_icache/cache_hit
```

### Expected Simulation Behavior

| Time | Event |
|---|---|
| 0 – 100 ns | Reset active; PC = 0; no AXI transactions |
| 100 ns | Reset released; first I-Cache miss triggers AXI read request |
| ~120 ns | Memory model responds with instruction `0x00500113` |
| After 120 ns | PC advances; subsequent instructions benefit from cache hits |

---

## Design Specifications

### Resource Utilization (Post-Synthesis Estimate)

| Resource | Estimate |
|---|---|
| **LUTs** | ~2,500 |
| **Flip-Flops** | ~1,800 |
| **Block RAM** | 0 (distributed RAM used for caches) |
| **DSP Slices** | 0 |

### Performance

| Metric | Value |
|---|---|
| **Target Clock** | 50 MHz |
| **CPI (Cache Hit)** | 1 cycle per instruction (ideal) |
| **Cache Hit Latency** | 1 clock cycle |
| **Cache Miss Penalty** | ~3 clock cycles (AXI handshake overhead) |

---

## Pipeline Control Signals Reference

### Main Datapath Control

| Signal | Width | Source | Description |
|---|---|---|---|
| `pc_src` | 1 | Control Unit | 0 = PC+4, 1 = Branch target |
| `alu_src_b_sel` | 1 | Control Unit | 0 = Register, 1 = Immediate |
| `alu_control` | 4 | ALU Decoder | ALU operation select |
| `mem_to_reg` | 1 | Control Unit | 0 = ALU result, 1 = Memory data |
| `dcache_we` | 1 | Control Unit | Data cache write enable |

### Pipeline Stall and Flush Control

| Signal | Width | Source | Description |
|---|---|---|---|
| `global_stall` | 1 | `riscv_top` | Asserted when any cache is not ready |
| `stall_fetch` | 1 | Hazard Unit | Freezes the Fetch stage |
| `stall_decode` | 1 | Hazard Unit | Freezes the Decode stage |
| `flush_execute` | 1 | Hazard Unit | Inserts a NOP bubble into the Execute stage |

---

## Design Notes

### Why a Pipelined Core?
Compared to the single-cycle approach, the pipeline overlaps the execution of multiple instructions, achieving much higher throughput. The key challenges that this design addresses are:

- **Structural Hazards**: Resolved by having separate I-Cache and D-Cache
- **Data Hazards**: Handled by the hazard detection unit (stall + flush)
- **Control Hazards**: Branch resolution in the Execute stage; the pipeline is flushed on taken branches

### Cache Architecture
Both I-Cache and D-Cache are **direct-mapped** with a configurable cache line size. On a miss, the cache controller FSM:
1. Asserts an AXI read request to the AXI Master Interface
2. Waits for the AXI handshake to complete
3. Fills the cache line with the returned data
4. Returns `ready` to the pipeline so it can continue

### AXI4 Read Protocol
The AXI Master Interface implements the two-channel AXI4 read protocol:
- **AR Channel** (Address Read): `ARADDR`, `ARVALID`, `ARREADY`
- **R Channel** (Read Data): `RDATA`, `RVALID`, `RREADY`

---

## References

- [The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA](https://riscv.org/technical/specifications/)
- [ARM AMBA AXI and ACE Protocol Specification](https://developer.arm.com/architectures/system-architectures/amba)
- *Digital Design and Computer Architecture: RISC-V Edition* — Harris and Harris (Elsevier)
- [Xilinx / AMD Vivado Design Suite](https://www.xilinx.com/products/design-tools/vivado.html)
- [RISC-V Foundation](https://riscv.org)

---

## License

This project is released for **academic and educational use**. Feel free to study, modify, and extend it with attribution.
