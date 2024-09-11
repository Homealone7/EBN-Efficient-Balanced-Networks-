
# Efficient Balanced Networks (EBN) Hardware Implementation

This repository contains the hardware implementation of the **Efficient Balanced Networks (EBN)** model, based on the MATLAB implementation by **Professor Alireza Alemi**. The original EBN design was created for simulation in MATLAB, and this project aims to translate it to hardware using **Verilog/SystemVerilog** and target an **FPGA**.

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [How to Use](#how-to-use)
- [Dependencies](#dependencies)
- [Memory Initialization](#memory-initialization)
- [Credits](#credits)
- [License](#license)

## Overview
This project implements an **Efficient Balanced Networks (EBN)** model in hardware, converting the original MATLAB model into an FPGA design using **Verilog/SystemVerilog**. The hardware implementation focuses on efficient use of FPGA resources while maintaining the accuracy of the model. The design includes:
- **Synaptic Core** for learning and weight updates.
- **Neuron Core** based on a Leaky Integrate-and-Fire (LIF) model.
- **Memory Manager** for handling data storage in BRAM.
- **Spike Filter** for managing spike activity.

The design is optimized for deployment on the **Zynq-7000** series FPGA (or other compatible platforms).

## Project Structure
The project is organized as follows:
- `/srcs`: Contains all SystemVerilog files for the hardware implementation.
- `/constraints`: FPGA-specific constraint files for pin mapping and clock management.
- `/Python`: Contains a Python script to convert `.txt` files into `.coe` files for initializing memory in BRAM.
- `/Mem`: Pre-generated `.coe` memory initialization files for the design.
- `/testbench`: Contains the testbenches used to verify the functionality of individual modules.

## How to Use
### Requirements
- **Vivado**: The project is designed for synthesis and implementation in Xilinx Vivado.
- **FPGA Board**: The design is targeted for the **ZedBoard** or compatible **Zynq-7000** FPGA devices.

### Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ebn-hardware.git
   cd ebn-hardware
   ```
2. Open the project in **Vivado**:
   - Launch Vivado and open the project file or create a new one by importing the source files from the `/srcs` folder.
   - Set up your board constraints using the provided `.xdc` file in the `/constraints` folder.
   
3. Synthesize, implement, and generate the bitstream for your FPGA.

4. Load the bitstream onto the FPGA and monitor the output through appropriate debugging tools (e.g., UART, LEDs).

### Testbench
- The project includes testbenches for individual modules like the **Synaptic Core** and **Neuron Core**.
- Run these testbenches in **ModelSim** or **Vivado**'s built-in simulator to verify functionality before deploying the design on hardware.

## Memory Initialization
- **Python Script**: In the `/Python` folder, you'll find a Python script that converts `.txt` files into `.coe` format for use in initializing BRAM memory in the design.
- **Mem Folder**: The `/Mem` folder contains pre-generated `.coe` files which are used to initialize memory blocks for the design. These memory files are used during synthesis and can be modified using the Python script if needed.

## Dependencies
- **Vivado**: Version 2020.2 or newer is recommended.
- **Python**: To run the memory file conversion script, you need Python 3 installed on your system.
- **ModelSim** or another Verilog simulation tool for running the testbenches.

## Credits
This project is based on the MATLAB implementation of the **Efficient Balanced Networks (EBN)** model by **Professor Alireza Alemi**. The hardware translation and implementation were carried out under the supervision of **Professor Venkatesh Akella** as part of the task to port the model to an FPGA platform.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
