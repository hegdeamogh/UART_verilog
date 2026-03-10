# UART Transmitter & Receiver

A fully synthesisable, parameterised **UART (Universal Asynchronous Receiver-Transmitter)** implementation in Verilog, supporting the standard **8-N-1** frame format (8 data bits, no parity, 1 stop bit). Verified through a cycle-accurate, self-checking loopback testbench.

---

## Features

- **Configurable baud rate** via `CLKS_PER_BIT` parameter — works with any system clock
- **8-N-1 framing**: start bit → 8 data bits (LSB first) → stop bit
- **Mid-bit sampling** in the receiver for maximum noise immunity
- **Double-flop synchroniser** on RX input to prevent metastability
- **Self-checking testbench** with 8 test vectors; reports PASS/FAIL per transaction
- **VCD waveform dump** compatible with GTKWave
- Clean FSM-based RTL — ready for FPGA synthesis (tested with Xilinx Vivado)

---


## Tools Used

| Tool            | Purpose                        |
|-----------------|-------------------------------|
| Xilinx Vivado   | Synthesis, simulation          |
| ModelSim        | Functional verification        |
| GTKWave         | Waveform analysis              |
| Icarus Verilog  | Open-source simulation         |

---
