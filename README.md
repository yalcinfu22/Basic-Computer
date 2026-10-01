# Basic Computer

A Verilog CPU project developed by a two-person team for ITU's BLG222E coursework. The design connects an arithmetic logic unit, register files and memory to a control unit that sequences instruction execution.

## Design

The project was built in two stages:

1. **Datapath:** registers, register files, the ALU, instruction/data registers, memory and the multiplexers connecting them.
2. **Control unit:** instruction decoding and control signals for the fetch, decode and execution steps.

The datapath combines 32-bit general-purpose/scratch registers with 16-bit address registers and instructions. Memory transfers one byte at a time. The controller selects register operations, ALU functions, memory access and data routing across multiple timing steps.

## Start here

| File | Purpose |
|---|---|
| [CPUSystem.v](./CPUSystem.v) | Instruction decoding and CPU control sequencing |
| [ArithmeticLogicUnitSystem.v](./ArithmeticLogicUnitSystem.v) | Integrated datapath |
| [CPUSystemSimulation.v](./CPUSystemSimulation.v) | CPU testbench with expected-value checks |
| [Report_project1.pdf](./Report_project1.pdf) | Datapath design report |
| [Report.pdf](./Report.pdf) | Control unit and instruction-set report |

The repository also contains earlier module variants. Use the source lists in [Run.bat](./Run.bat) and [Run_project1.bat](./Run_project1.bat) to identify the files compiled by each simulation.

## Simulations

The Windows scripts use **Vivado's XSIM tools**: `xvlog`, `xelab` and `xsim`. They currently point to Vivado 2017.4 at `C:\Xilinx\Vivado\2017.4\settings64.bat`.

Before running them:

1. Install a Vivado version that provides these simulation tools.
2. Update the first line of each script to your local `settings64.bat` path.
3. In each script, correct the directory-change line to `cd "%folder%"`; the checked-in line is missing its closing quote.
4. Run from the repository root so the relative source paths and `RAM.mem` resolve correctly.

| Command | Simulations |
|---|---|
| `Run_project1.bat` | Registers, register files, ALU and integrated datapath |
| `Run.bat` | `CPUSystemSimulation` and `CPUSystemSimulation_Factorial` |

The main CPU testbench checks reset, register operations, memory access, a subroutine call and a bitwise operation.

### Results and memory images

- The scripts copy the root `RAM.mem` into `Simulation_Files/`, where `Memory.v` reads it.
- Additional memory images are included as `RAM_project1.mem` and `RAM_factorial.mem`. The scripts do not select them automatically; ensure the working-directory `RAM.mem` matches the program being simulated.
- `Helper.v` writes expected/actual comparisons to `evaluation.csv` and `debug.txt`, and prints pass/fail counts.
- Existing files under `Simulation_Files/` are saved outputs. Re-run the relevant testbench to obtain results for your checkout and environment.

## Project credits

This is a **two-person coursework project**. Team information is retained in [GroupMembers.xlsx](./GroupMembers.xlsx), and the original design reports remain available above.

Some source headers carry additional author credits: `Memory.v` and `Helper.v` credit Kadir Ozlem, and `CPUSystemSimulation.v` credits Omur F Erzurumluoglu of the ITU Computer Engineering Department. Preserve these credits when using or adapting those files.
