# Verilog Design of a Bicycle Computer

## Overview
This repository contains the implementation of a **Bicycle Computer** in **Verilog HDL**, developed as part of the *Design of Integrated Systems* course at Universität Ulm.  
The project implements the **calculation unit** of a bicycle computer that displays instantaneous speed, trip distance, average speed, trip time, and maximum speed on an LCD interface.  

The design has been verified through behavioral and post-synthesis simulation, and synthesis reports are provided for FPGA implementation.

---

## Project Specification
The bicycle computer replicates the functionality of a commercial bike computer, with the following features:

- **Instantaneous Speed (KMH):** 0–99 km/h, resolution 1 km/h  
- **Trip Distance (DAY):** 0.0–999.9 km, resolution 0.1 km  
- **Average Speed (AVS):** 0.0–99.9 km/h, resolution 0.1 km/h  
- **Trip Time (TIM):** 00:00–99:59 (min:sec or h:min format)  
- **Maximum Speed (MAX):** 0–99 km/h  
- **Wheel Circumference (CIRC):** configurable, 100–255 cm  

### Inputs
- `CLK` (2.048 kHz system clock)  
- `REED` (wheel revolution pulses from reed contact)  
- `MODE`, `RESET` keys  
- `CIRC` constant (wheel circumference)  

### Outputs
- LCD control signals (`UPPER10_ASCII`, `LOWER1_ASCII`, etc.)  
- Mode indicators (`DAY`, `AVS`, `TIM`, `MAX`)  
- Symbols (`POINT` for decimals, `COL` for time separator)  

### Special Behavior
- Mode indicators blink if **instantaneous speed > 65 km/h**.  
- Display updates once per second, except immediate updates on key press.  

---

## System Architecture
The architecture follows a **modular design**, with each calculation handled in a dedicated Verilog module:

### 1. Controller
- Handles `MODE`/`RESET` keys and mode selection.
- Manages blinking signals if speed > 65 km/h.
- Synchronizes display update timing.

### 2. Instantaneous Speed Module
- Measures the period between wheel pulses (`REED`) using clock counts.  
- Computes speed:  
  \[
  v = \frac{CIRC \times 2048 \times 3600}{COUNT \times 100000}
  \]  
- Output in integer km/h.

### 3. Trip Distance Module
- Accumulates distance:  
  \[
  \text{DISTANCE} \, [\text{cm}] += CIRC
  \]  
- Converted to km with 0.1 km resolution.

### 4. Trip Time Module
- Counts elapsed seconds when speed ≥ 5 km/h.  
- Provides formatted output (MM:SS or HH:MM).

### 5. Maximum Speed Module
- Stores the highest instantaneous speed observed.

### 6. Average Speed Module
- Computes average speed:  
  \[
  AVS = \frac{\text{DAY} \times 3600}{\text{TIM}}
  \]  
- Excludes time when bicycle is stationary (< 5 km/h).

### 7. Display Controller
- Selects current mode output and converts values into **BCD → ASCII**.  
- Manages:
  - Decimal point (`POINT`) for AVS/DAY.  
  - Colon (`COL`) blinking for TIM.  
  - Mode indicators (`DAY`, `AVS`, `TIM`, `MAX`).  
- Interfaces with submodules `dual2bcd` and `bcd2ascii`.

---

## Repository Structure
├── Project specification.pdf # Full project requirements
├── Initial presentation.pdf # Proposed architecture & solution
├── sources/
│ ├── student/ # Main project modules (calculation units, controller, display logic)
│ ├── submodules/ # Provided helpers (dual2bcd, bcd2ascii)
│ ├── testbench/ # Simulation testbenches
│ ├── constraints/ # FPGA constraints files
│ ├── synthesis/ # Synthesizable project files
│ └── tcl/ # TCL scripts for synthesis flow
├── reports/ # Synthesis and timing analysis reports

---

## Verification
- **Simulation**:  
  Each module has a dedicated testbench under `sources/testbench`.  
  Behavioral and post-synthesis simulations were performed.  
- **Synthesis**:  
  The design was synthesized for a Xilinx FPGA.  
  Reports on resource utilization and timing are available in `reports/`.

---

## Key Contributions
- Modular and synthesizable Verilog design.  
- Accurate computation of speed, distance, and time metrics.  
- Real-time display control with **ASCII encoding**.  
- Compliance with project constraints (2.048 kHz clock, blinking behavior, reset conditions).  

---

## References
- Project Specification: *Verilog Design of a Bicycle Computer*, Universität Ulm  
- Initial Presentation: *System Architecture Proposal*  
