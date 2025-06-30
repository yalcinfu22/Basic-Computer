# Basic Computer

## Overview
This project implements a basic CPU architecture using Verilog. It is divided into two main parts:

- **Part 1**: Design and implementation of core CPU components such as the ALU, registers, and the ALU system.
- **Part 2**: Design and integration of the control unit, responsible for orchestrating instruction execution by sending control signals to the ALU system.

---

## Part 1: ALU System

### Description
This part focuses on the foundational components of the CPU and includes:

1. **Register and Register File Design**  
   Registers are used to store various types of data including addresses and instructions.

2. **Arithmetic Logic Unit (ALU) Design**  
   The ALU is responsible for performing operations such as addition, subtraction, and other logic operations on the data stored in registers.

### More Details
See [Report 1](./Report_project1.pdf) for an in-depth explanation of the ALU system.

---

## Part 2: Control Unit

### Description
The control unit was designed to work in tandem with the ALU system, enabling the execution of a set of 36 instructions. It generates the appropriate control signals based on the instruction set to guide the operation of the CPU.

### More Details
See [Report 2](./Report.pdf) for details on the control unit design and supported instruction set.


