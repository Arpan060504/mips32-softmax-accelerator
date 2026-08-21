# MIPS32 Softmax Accelerator

A research-oriented RTL implementation of a MIPS32-based processor extended with a custom instruction for accelerating the Softmax operation used in Transformer architectures.

## Motivation

Softmax is a fundamental operation in Transformer attention:

    Softmax(x_i) = exp(x_i) / sum(exp(x_j))

Although matrix multiplication is computationally dominant in many Transformer workloads, Softmax contains expensive nonlinear operations such as exponential, accumulation, and normalization.

This project investigates whether a dedicated hardware implementation of Softmax, invoked through a custom MIPS32 instruction, can reduce execution latency and improve hardware efficiency compared with a software-based implementation.

## Architecture

The project is based on a 5-stage MIPS32 pipeline:

    IF → ID → EX → MEM → WB

A custom Softmax instruction is added to the processor ISA.

    MIPS32 CPU
          |
          | Custom Softmax instruction
          v
    Softmax Accelerator
          |
          +── Exponential approximation
          +── Accumulation
          +── Normalization
          |
          v
       Softmax output

The exact exponential approximation and arithmetic representation will be evaluated as part of the research.

## Research Objectives

- Design a custom instruction for Softmax acceleration.
- Design the corresponding RTL Softmax accelerator.
- Investigate low-cost hardware implementations of the exponential function.
- Integrate the accelerator with a pipelined MIPS32 processor.
- Compare hardware-accelerated Softmax with a software-based baseline.
- Evaluate latency, resource utilization, and numerical accuracy.
- Study the trade-off between hardware cost and Softmax approximation accuracy.

## Baseline vs Proposed Design

### Baseline

Softmax is executed using normal MIPS32 instructions and software-controlled computation.

### Proposed

A custom MIPS32 instruction invokes dedicated Softmax hardware.

    Baseline:
    MIPS32 → normal instructions → Softmax computation

    Proposed:
    MIPS32 → custom instruction → Softmax accelerator

The two implementations will be compared using:

- Clock cycles
- Latency
- LUT utilization
- Flip-flop utilization
- DSP utilization
- BRAM utilization
- Power consumption (where supported)
- Numerical error

## Repository Structure

    rtl/
    ├── cpu/
    ├── softmax/
    └── custom_isa/

    tb/
    ├── cpu/
    └── softmax/

    software/
    ├── baseline/
    └── accelerated/

    docs/
    ├── architecture.md
    ├── isa_extension.md
    └── results.md

## Current Status

### Completed

- MIPS32 5-stage processor implementation
- Transformer architecture study
- Literature study on custom ISA-based Transformer acceleration
- Study of Softmax hardware optimization techniques

### In Progress

- Research architecture definition
- Custom instruction definition
- Exponential approximation study
- Softmax RTL design

### Planned

- Implement exponential hardware
- Implement Softmax accelerator
- Integrate accelerator with MIPS32 pipeline
- Develop baseline software Softmax
- Develop custom-instruction-based Softmax
- Functional verification
- FPGA synthesis
- Performance and resource comparison

## References

The project is based on research in:

- RISC-V custom instruction extensions for Transformer acceleration
- Hardware Softmax optimization
- Transformer accelerator architectures
- Hardware approximation of exponential functions

Individual papers and their implementation relevance are documented separately.

## Author

Arpan
