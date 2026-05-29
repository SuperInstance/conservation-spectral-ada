# conservation-spectral-ada

Ada 2012 port of the Conservation Spectral SDK — spectral graph theory for conservation analysis, designed for DO-178C avionics certification standards.

## What This Gives You

- **SPARK-compatible** — pre/post conditions, type-range constraints, formal verification
- **Spectral analysis** — Laplacian eigenvalues, conservation ratios, Cheeger constant
- **Bounded types** — `Probability` (0.0..1.0), `Conservation_Ratio` (-100.0..100.0), `Graph_Index` (1..1000)
- **Anomaly classification** — severity levels with confidence scores
- **DO-178C target** — designed for avionics-grade software certification

## Quick Start

```ada
with Conservation_Spectral;

procedure Demo is
   Transition : Conservation_Spectral.Transition_Matrix (1..3, 1..3) :=
     (others => (others => 0.0));
   Laplacian  : Conservation_Spectral.Laplacian_Matrix (1..3, 1..3);
   Report     : Conservation_Spectral.Conservation_Report;
begin
   -- Build transition matrix (row-stochastic)
   Transition := ((0.0, 0.5, 0.5),
                  (0.5, 0.0, 0.5),
                  (0.5, 0.5, 0.0));

   -- Compute Laplacian
   Conservation_Spectral.Build_Laplacian (Transition, Laplacian);

   -- Analyze
   Report := Conservation_Spectral.Analyze (Laplacian);

   Ada.Text_IO.Put_Line ("Conservation Score: " &
     Float'Image (Report.Conservation_Score));
   Ada.Text_IO.Put_Line ("Spectral Gap: " &
     Float'Image (Report.Spectral_Gap));
end Demo;
```

## API Reference

| Type | Description |
|---|---|
| `Transition_Matrix` | Row-stochastic probability matrix |
| `Laplacian_Matrix` | Symmetric positive semi-definite |
| `Conservation_Report` | Full analysis: spectral gap, Cheeger, anomalies |
| `Anomaly_Severity` | (None, Low, Medium, High, Critical) |

| Procedure / Function | Description |
|---|---|
| `Build_Laplacian` | Transition → Laplacian (with pre/post conditions) |
| `Is_Valid_Laplacian` | Verify positive semi-definiteness |
| `Is_Row_Stochastic` | Verify row-stochastic property |
| `Analyze` | Full conservation report |

## How It Fits

The **Ada port** of the conservation spectral ecosystem — certified-grade alternative to:

- [conservation-spectral-python](https://github.com/SuperInstance/conservation-spectral-python) — Python SDK
- [conservation-spectral-js](https://github.com/SuperInstance/conservation-spectral-js) — TypeScript SDK
- [conservation-conformance](https://github.com/SuperInstance/conservation-conformance) — cross-language conformance tests
- [conservation-protocol](https://github.com/SuperInstance/conservation-protocol) — Rust messaging protocol

## Building

```bash
gnatmake -P conservation_spectral.gpr
```

Requires GNAT 2021+ or AdaCore SPARK Pro.

## License

MIT
