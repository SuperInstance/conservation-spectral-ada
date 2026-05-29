# Conservation Spectral SDK — Ada

> Production-grade spectral graph theory library for conservation analysis, built in Ada to DO-178C avionics certification standards.

## Why Ada?

Ada was designed in the 1980s for safety-critical systems (missiles, aircraft, spacecraft). This SDK leverages every safety feature the language provides:

| Feature | How We Use It |
|---------|--------------|
| **Range types** | `Probability` can never be negative — the compiler enforces it |
| **Pre/post conditions** | `Build_Laplacian` guarantees a valid Laplacian output |
| **Tasking** | `Anomaly_Detector` runs as a concurrent Ada task with rendezvous synchronization |
| **Generic packages** | Works with any floating-point precision (`Float`, `Long_Float`, etc.) |
| **Protected objects** | `Statistics_Collector` is thread-safe by construction |
| **Exception handling** | Singular matrices raise `Constraint_Error` |
| **Strong typing** | You cannot accidentally pass a `Transition_Matrix` where a `Laplacian_Matrix` is expected |

## Architecture

```
conservation_spectral.ads/adb   — Core package: Laplacian, spectral gap, Cheeger bound, entropy
eigen.ads/adb                   — Eigendecomposition: QR algorithm, power iteration, Fiedler value
anomaly.ads/adb                 — Thread-safe anomaly detection with baseline tracking
generic_conservation.ads/adb    — Generic (template) package for any float precision
main.adb                        — Comprehensive test driver
Makefile                        — Build with GNAT (Ada 2022, assertions enabled)
```

## Build & Run

```bash
# Install GNAT compiler
sudo apt install gnat

# Build
make

# Run tests
make run
```

## Compiler Flags

```makefile
-gnat2022   # Ada 2022 mode (modern pre/post conditions)
-gnata      # Enable assertions
-gnato      # Overflow checks
-O2         # Optimization level 2
```

## Core Algorithms

### Laplacian Construction
```
L = D - A
```
Where `D` is the degree matrix and `A` is the adjacency/weight matrix derived from the transition matrix.

### Spectral Gap (Fiedler Value)
Second-smallest eigenvalue of `L`, computed via inverse power iteration with deflation against the trivial eigenvector `[1,1,...,1]`.

### Cheeger Inequality
```
h(G) ≥ √(2·λ₁)
```
Lower bound on graph conductance from the spectral gap.

### Conservation Ratio
```
CR = tr(L^T · P · L) / tr(L^T · L)
```
Measures how much transition structure is preserved by the Laplacian mapping.

## Thread Safety

The `Anomaly_Detector` is an Ada **task** (lightweight thread) with rendezvous-based synchronization:

```ada
task type Anomaly_Detector is
   entry Set_Baseline (Report : Conservation_Report);
   entry Check (Spectral_Gap, Cheeger_Constant, Conservation, Entropy : Float;
                Is_Anomalous : out Boolean; Severity : out Anomaly_Severity);
   entry Stop;
end Anomaly_Detector;
```

No mutexes, no locks, no race conditions — Ada's rendezvous model handles it all.

## License

MIT

Part of the [SuperInstance OpenConstruct](https://github.com/SuperInstance/OpenConstruct) ecosystem.
