# 16-bit RISC Pipelined Processor Design

## Overview
This repository contains the complete design, simulation, and hardware implementation of a custom 16-bit RISC processor with a 5-stage pipelined datapath, heavily inspired by the MIPS architecture. 

This project was originally developed for the COMP3005 - Computer Organization course at Konya Food and Agriculture University during the 2025-2026 Fall semester. The project is divided into an architectural design/visual simulation phase and a Register Transfer Level (RTL) implementation phase using Verilog.

## Key Features & Architecture
* **Architecture Type:** 16-bit RISC, Load/Store Architecture.
* **Pipeline Structure:** 5 stages (Instruction Fetch - IF, Instruction Decode - ID, Execute - EX, Memory Access - MEM, Write Back - WB).
* **Memory Organization:** Harvard Architecture with separate Instruction Memory and Data Memory (512 bytes each). Both memories are byte-addressable, and memory accesses are aligned to even byte addresses.
* **Register File:** 8 general-purpose 16-bit registers (`R0` through `R7`). Register `R0` is hardwired to zero, and `R7` serves as the Return Address Register (`$ra`) for procedure calls.

## Instruction Set Architecture (ISA)
The processor supports a custom 16-bit fixed-length instruction set categorized into three formats: R-Type, I-Type, and J-Type. 
* **Arithmetic & Logic:** `ADD`, `SUB`, `AND`, `OR`, `SLT`, `ADDI`.
* **Memory Operations:** `LW` (Load Word), `SW` (Store Word).
* **Control Flow:** `BEQ`, `BNE`, `J`, `JAL`, `JR`.
* **Shift Operations:** `SLL`, `SRL`.
* **Other:** `NOP` (used for pipeline bubbles).

Procedure calls are fully supported via `JAL` (Jump and Link) and `JR` (Jump Register) instructions, which manipulate the return address in `R7`.

## Hazard Management Mechanisms
To maintain instruction throughput and prevent pipeline stalls, the processor incorporates advanced hardware hazard resolution mechanisms:
* **Data Hazards (Forwarding Unit):** Resolves Read-After-Write (RAW) dependencies by forwarding data directly from the `EX/MEM` and `MEM/WB` pipeline registers to the ALU inputs (EX stage).
* **Load-Use Hazards (Hazard Detection Unit):** Detects when an instruction depends on a preceding load (`LW`) operation and stalls the pipeline by freezing the PC and IF/ID registers for one cycle (inserting a bubble).
* **Control Hazards (Flushing):** Branch and jump decisions are aggressively resolved in the EX stage. If a control-flow change occurs, incorrectly fetched instructions in the IF and ID stages are invalidated using a pipeline flush mechanism.

## Development Phases
### Phase 1: Architectural Design & Python Simulator
* **Logisim Datapath:** The initial processor logic and pipeline routing were implemented and validated using Logisim.
* **Custom Python GUI Simulator:** A cycle-accurate simulator was built using Python and the Tkinter library. It features an Assembly & Machine Code Inspector, a dynamic Stage Visualizer, a scrolling Pipeline Timeline diagram, and real-time register/memory state inspection to trace pipeline execution step-by-step.

### Phase 2: Verilog RTL Implementation
* **Hardware Description:** The microarchitecture was translated into a synthesizable Register Transfer Level (RTL) model using Verilog HDL.
* **Modular Design:** The implementation utilizes a top-level wrapper (`cpu_top.v`) alongside distinct modules for pipeline stages, memory units, ALU, and hazard control units.
* **Verification:** The hardware logic, timing constraints, and control signal propagation were rigorously verified using the Xilinx Vivado Simulator through comprehensive testbenches targeting arithmetic, memory, and complex branching scenarios.

## Project Structure
* `/python simulator`: Contains the Python/Tkinter based cycle-accurate GUI simulator.
* `/RISC_16bit_Processor_verilog`: Contains the Verilog HDL source files (`.v`) and testbenches for the RTL implementation.
* `16-bit PROCESSOR DESIGN REPORT.pdf`: Phase 1 documentation (ISA, datapath, pipelining, Logisim, and Python simulator).
* `Verilog Report.pdf`: Phase 2 documentation (RTL module hierarchy, hazard handling logic, and Xilinx Vivado simulation results).
