# conservation-spectral-ada

Production-grade spectral graph theory library for conservation analysis, built in Ada to DO-178C avionics certification standards — Laplacian construction, eigendecomposition, anomaly detection, and Cheeger bounds.

## Why Ada?

Ada was designed for safety-critical systems (missiles, aircraft, spacecraft). This SDK leverages every safety feature the language provides:

| Feature | How We Use It |
|---------|--------------|
| **Range types** | `Probability` can never be negative — the compiler enforces it |
| **Pre/post conditions** | `Build_Laplacian` guarantees a valid Laplacian output |
| **Tasking** | `Anomaly_Detector` runs as a concurrent Ada task with rendezvous synchronization |
| **Generic packages** | Works with any floating-point precision (`Float`, `Long_Float`, etc.) |
| **Protected objects** | `Statistics_Collector` is thread-safe by construction |
| **Strong typing** | Cannot accidentally pass a `Transition_Matrix` where a `Laplacian_Matrix` is expected |

## What This Gives You

- **Laplacian construction** — `L = D - A` from transition matrices, with compiler-verified dimensions
- **Eigendecomposition** — QR algorithm, power iteration, Fiedler value extraction
- **Spectral gap & Cheeger bounds** — Graph connectivity analysis
- **Entropy computation** — Spectral entropy for information-theoretic measures
- **Thread-safe anomaly detection** — Concurrent `Anomaly_Detector` task with baseline tracking
- **Generic precision** — Same algorithms work at `Float`, `Long_Float`, or any precision

## Quick Start

### Build and run

```bash
# Install GNAT compiler
sudo apt install gnat

# Build and test
make
make run
```

Compiler flags: `-gnat2022` (Ada 2022 mode), `-gnata` (assertions), `-gnato` (overflow checks), `-O2`.

### Using the SDK

```ada
with Conservation_Spectral; use Conservation_Spectral;
with Eigen;

-- Build a Laplacian from a 4-node ring graph
N : constant := 4;
subtype Idx is Graph_Index range 1 .. N;
Trans : Transition_Matrix (Idx, Idx);
Lap   : Laplacian_Matrix  (Idx, Idx);

-- Initialize transition matrix...
Build_Laplacian (Trans, Lap);

-- Compute conservation report
Report : Conservation_Report := Analyze (Lap);
--  Report contains: spectral_gap, cheeger_bound, entropy, fiedler_value
```

## Architecture

```
conservation_spectral.ads/adb   — Core: Laplacian, spectral gap, Cheeger bound, entropy
eigen.ads/adb                   — Eigendecomposition: QR algorithm, power iteration, Fiedler value
anomaly.ads/adb                 — Thread-safe anomaly detection with baseline tracking
generic_conservation.ads/adb    — Generic (template) package for any float precision
main.adb                        — Comprehensive test driver
```

## How It Fits

- **[conservation-protocol](https://github.com/SuperInstance/conservation-protocol)** — Rust library for spectral agent identity; this Ada SDK provides the same math for safety-critical environments
- **[constraint-hamiltonian](https://github.com/SuperInstance/constraint-hamiltonian)** — Constrained dynamics use spectral properties for constraint surface analysis
- **[cocapn-health-rs](https://github.com/SuperInstance/cocapn-health-rs)** — Anomaly detection patterns inform fleet health monitoring

## Testing

The `main.adb` test driver exercises all packages: Laplacian construction, eigenvalue computation, anomaly detection, and the generic package.

```bash
make run
```

## Installation

```bash
git clone https://github.com/SuperInstance/conservation-spectral-ada.git
cd conservation-spectral-ada
make
```

Requires GNAT (Ada 2022 compiler).

## License

MIT

Part of the [SuperInstance OpenConstruct](https://github.com/SuperInstance) ecosystem.
