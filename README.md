# UART Transmitter & Receiver — Verilog HDL

A fully synthesisable, parameterised **UART (Universal Asynchronous Receiver-Transmitter)** implementation in Verilog HDL, supporting the standard **8-N-1** frame format (8 data bits, no parity, 1 stop bit). Verified through a cycle-accurate, self-checking loopback testbench.

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

## Repository Structure

```
uart-verilog/
├── rtl/
│   ├── uart_tx.v        # UART Transmitter
│   ├── uart_rx.v        # UART Receiver
│   └── uart_top.v       # Top-level wrapper (TX + RX)
├── tb/
│   └── tb_uart_loopback.v  # Self-checking loopback testbench
├── sim/                 # (generated) VCD waveform output
└── README.md
```

---

## Frame Format

```
Idle   Start   D0   D1   D2   D3   D4   D5   D6   D7   Stop   Idle
 ____   ____                                              ____   ____
|    | |    | | LSB  .    .    .    .    .    .  MSB | |    | |    |
|  1 |_|  0 |_|__________________________________|_1_|_|  1 | |  1 |
```

---

## Parameters

| Parameter     | Default | Description                                      |
|---------------|---------|--------------------------------------------------|
| `CLKS_PER_BIT`| `868`   | Clock cycles per bit = `f_clk / baud_rate`       |

**Example configurations:**

| System Clock | Baud Rate | `CLKS_PER_BIT` |
|-------------|-----------|----------------|
| 100 MHz     | 115200    | 868            |
| 50 MHz      | 9600      | 5208           |
| 25 MHz      | 115200    | 217            |

---

## Simulation

### Icarus Verilog (free, command-line)

```bash
# Compile
iverilog -o sim/uart_sim \
    tb/tb_uart_loopback.v \
    rtl/uart_tx.v \
    rtl/uart_rx.v

# Run
vvp sim/uart_sim

# View waveform
gtkwave uart_loopback.vcd
```

### Xilinx Vivado

1. Create a new RTL project
2. Add `rtl/*.v` as design sources
3. Add `tb/tb_uart_loopback.v` as simulation source
4. Set `tb_uart_loopback` as the top simulation module
5. Run Behavioral Simulation

### ModelSim / Questa

```tcl
vlib work
vlog rtl/uart_tx.v rtl/uart_rx.v tb/tb_uart_loopback.v
vsim tb_uart_loopback
run -all
```

---

## Expected Simulation Output

```
========================================
  UART 8-N-1 Loopback Testbench
  CLK: 100 MHz | Baud: 115200 | CLKS_PER_BIT: 868
========================================
[PASS] Sent: 0x55 | Received: 0x55
[PASS] Sent: 0xAA | Received: 0xAA
[PASS] Sent: 0xFF | Received: 0xFF
[PASS] Sent: 0x00 | Received: 0x00
[PASS] Sent: 0x41 | Received: 0x41
[PASS] Sent: 0x5A | Received: 0x5A
[PASS] Sent: 0x0F | Received: 0x0F
[PASS] Sent: 0xA3 | Received: 0xA3
========================================
  Results: 8 PASSED, 0 FAILED
  ALL TESTS PASSED
========================================
```

---

## Design Notes

**Transmitter FSM:** `IDLE → START_BIT → DATA_BITS → STOP_BIT → CLEANUP`

- Loads the 8-bit word on `i_tx_valid` assertion
- Shifts out bits LSB-first, each held for exactly `CLKS_PER_BIT` cycles
- Pulses `o_tx_done` for one clock cycle after the stop bit

**Receiver FSM:** `IDLE → START_BIT → DATA_BITS → STOP_BIT → CLEANUP`

- Detects falling edge (start condition) on the synchronised RX line
- Waits `CLKS_PER_BIT/2` cycles to align to mid-bit, then samples every `CLKS_PER_BIT` cycles
- Validates that the stop bit is HIGH before asserting `o_rx_done`

---

## Tools Used

| Tool            | Purpose                        |
|-----------------|-------------------------------|
| Xilinx Vivado   | Synthesis, simulation          |
| ModelSim        | Functional verification        |
| GTKWave         | Waveform analysis              |
| Icarus Verilog  | Open-source simulation         |

---

## Skills Demonstrated

- RTL design and FSM-based digital hardware description in Verilog HDL
- Baud rate clock domain management and parameterised design
- Synchronous reset conventions and metastability mitigation
- Cycle-accurate testbench development with automated pass/fail checking
- FPGA synthesis readiness (Xilinx Vivado)

---

## License

MIT License — free to use, modify, and distribute with attribution.
