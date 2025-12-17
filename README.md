# Function-Generator (FPGA DDFS)
A high accuracy function generator core for a digital instrumentation system (.e.g oscilloscopes, curve tracers)
This project focuses on **accurate frequency generation** using a **Direct Digital Frequency Synthesis (DDFS)** architecture.

## General Overview
At the heart of the design is a **phase accumulator** realization of frequency synthesis. A programmable frequency control word (FCW) advances the phase each sample clock, producing an accurate output frequency.


Waveform generation strategy:
- **Computed directly** from phase (logic-cheap and deterministic):
  - DC
  - Square
  - Ramp
  - Triangle
- **Lookup table (LUT)** for higher quality waveform:
  - Sine (stored LUT; computation via trig would be too expensive in FPGA fabric)

The initial version supports **one fixed amplitude** (external analog circuitry handles amplification/attenuation). Later versions will add amplitude control, offsets, and calibration.

## Key Features (v0)

- DDS-based frequency synthesis (phase accumulator + FCW)
- Waveform selection: `DC`, `Square`, `Ramp`, `Triangle`, `Sine`
- Fixed amplitude output (digital full-scale), suitable for external conditioning
- Parameter updates via registers



## DDS Model (Concept)

Let:
- `f_clk` = sample clock (100 MHz in this case) 
- `N` = phase accumulator width (24 bits)
- `FCW` = frequency control word (N-bit)

Then the output frequency is:

`f_out = (FCW * f_clk) / 2^N`

Frequency resolution:

`Δf = f_clk / 2^N`


## Project Structure

- `hdl/`
  - `dds_core.sv`        — phase accumulator + FCW interface with wave generation
  - `spi_dac_controller` - spi-based controller for the MCP4921 DAC
  - `sine_lut.sv`        — ROM-based sine LUT
  - `top.sv`             — integrates modules and output formatting for the board peripherals
- `sim/`
  - testbenches and reference models
- `docs/`
  - design notes, timing, and interface docs


 ## Hardware Overview
 Component | Description
 ________________________
 FPGA     | Xilinx Artix-7 Basys3 board
 
 

