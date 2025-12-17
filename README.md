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

Figure: DDS Architecture  Diagram

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

 Figure : System diagram
 
| Component | Description |
|-----------|-------------|
| FPGA     | Xilinx Artix-7 Basys3 board |
| DAC      | MCP4921, SPI-based 12-bit |
| System Clock | 100MHz     |
| Output range | 0 - VDD (3.3V) |
| Accuracy     | TBD |

Figure: Hand soldered MCP4921 breakout

## System Block Diagram


Figure: Functional overview of the DDFS -> SPI DAC -> Analog output chain

## Measured Performance

| Parameter | Value |
|-----------|-------------|
| Frequency resolution     | Xilinx Artix-7 Basys3 board |
| Frequency accuracy      | MCP4921, SPI-based 12-bit |
| Max output frequency |  limited by the DAC update rate, limited by the number of peripherals (sw)     |


## Verification
Simulation and validation for this project was performed using
- Vivado simulator + `gtkwave` for digital verification
- Keysight DSOX1102G for waveform validation
- Python for reference model comparison

## Gallery

Figure : Scope shots for various frequencies

Figure : Scope setup shot

GIF: Waveform switching

GIF : Step frequency 

## Future Work
Integration into instrumentation systems (DSO and digital curve tracer)


## References & Resources

I relied on the following documentation and articles while designing and validating this project:

- **FPGA Board / Hardware Docs**
  - AMD/Xilinx **Basys 3 Reference Manual** (Digilent):  
    https://www.amd.com/content/dam/amd/en/documents/university/aup-boards/XUPBasys3/documentation/Basys3_rm_8_22_2014.pdf

- **Course / Lab Infrastructure**
  - MIT FPGA / 6.205 course site (tooling and workflows):  
    https://fpga.mit.edu/6205/F25

- **DAC Datasheet**
  - Microchip **MCP4921/MCP4922** 12-bit SPI DAC datasheet:  
    https://ww1.microchip.com/downloads/en/devicedoc/21897b.pdf

- **DDS Background**
  - Analog Devices (Analog Dialogue): **DDS generates high-quality waveforms efficiently**:  
    https://www.analog.com/en/resources/analog-dialogue/articles/dds-generates-high-quality-waveforms-efficiently.html

### Figures
All block diagram for this repository are created using **Excalidraw** .


