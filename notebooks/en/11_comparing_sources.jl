### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 11000000-0000-0000-0000-000000000001
md"""
# 11 — Comparing Thermodynamic Data Sources

This notebook compares thermodynamic property values obtained from different
sources:

1. **Glenn.jl** — NASA-7 polynomials (`thermo.inp` from NASA Glenn)
2. **NIST-JANAF** — Reference thermochemical tables (Chase, 1998)
3. **Conventional tables** — Textbook tabulated values

The goal is to quantify discrepancies between sources and understand when
each is appropriate.

> **Note:** Glenn.jl has already been validated against NIST-JANAF for 7
> species (CO₂, N₂, CO, H₂O, O₂, NH₃, SO₂) in `docs/audit/audit.jl`.
"""

# ╔═╡ 11000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 11000000-0000-0000-0000-000000000003
md"""
## 1. Reference values from literature
"""

# ╔═╡ 11000000-0000-0000-0000-000000000004
begin
    const REFERENCE_DATA = Dict(
        "O2"  => (29.376, 205.152, 0.0),
        "N2"  => (29.124, 191.609, 0.0),
        "CO2" => (37.135, 213.795, -393.51),
        "H2O" => (33.590, 188.835, -241.83),
        "CH4" => (35.700, 186.251, -74.87),
        "CO"  => (29.142, 197.660, -110.53),
    )
end

# ╔═╡ 11000000-0000-0000-0000-000000000005
md"""
## 2. Side-by-side comparison
"""

# ╔═╡ 11000000-0000-0000-0000-000000000006
begin
    T_ref = 298.15
    comparison_results = []

    Calculator() do calc
        for (name, (cp_ref, s_ref, hf_ref)) in REFERENCE_DATA
            try
                sp = only(get_available_species(calc, name, exact_match = true))
                props = calculate_properties(calc, sp.id, T_ref)

                cp_glenn = props.cp
                cp_err_pct = (cp_glenn - cp_ref) / cp_ref * 100.0
                s_glenn = props.s
                s_err_pct = (s_glenn - s_ref) / s_ref * 100.0
                hf_glenn = props.h_relative / 1000.0

                push!(comparison_results, (
                    name = name, cp_ref = cp_ref, cp_glenn = cp_glenn,
                    cp_err = cp_err_pct, s_ref = s_ref, s_glenn = s_glenn,
                    s_err = s_err_pct, hf_ref = hf_ref, hf_glenn = hf_glenn,
                ))
            catch e
                @warn "Error processing $name: $e"
            end
        end
    end

    df_comp = DataFrame(
        Species = [r.name for r in comparison_results],
        Cp_ref = [r.cp_ref for r in comparison_results],
        Cp_glenn = round.([r.cp_glenn for r in comparison_results], digits = 3),
        Cp_err_pct = round.([r.cp_err for r in comparison_results], digits = 3),
        S_ref = [r.s_ref for r in comparison_results],
        S_glenn = round.([r.s_glenn for r in comparison_results], digits = 3),
        S_err_pct = round.([r.s_err for r in comparison_results], digits = 3),
        Hf_ref_kJ = [r.hf_ref for r in comparison_results],
        Hf_glenn_kJ = round.([r.hf_glenn for r in comparison_results], digits = 2),
    )

    println("=== Cp [J/(mol·K)] ===")
    show(select(df_comp, :Species, :Cp_ref, :Cp_glenn, :Cp_err_pct), allcols = true)
    println()
    println("=== S° [J/(mol·K)] ===")
    show(select(df_comp, :Species, :S_ref, :S_glenn, :S_err_pct), allcols = true)
    println()
    println("=== ΔfH° [kJ/mol] ===")
    show(select(df_comp, :Species, :Hf_ref_kJ, :Hf_glenn_kJ), allcols = true)
end

# ╔═╡ 11000000-0000-0000-0000-000000000007
md"""
## 3. Discrepancy analysis

### Sources of differences:

1. **Base data set**: NASA Glenn uses `thermo.inp`; NIST-JANAF uses the
   Shomate equation with independently fitted coefficients

2. **Fitting method**: NASA-7 polynomials are *piecewise* fits with $C^1$
   continuity; Shomate/NIST may use different methodologies

3. **Updates**: NASA Glenn reference values may come from a different version
   than the most recent NIST-JANAF tables

4. **Typical differences**:
   - $C_p$: < 0.5% for most species
   - $S^\circ$: < 0.2% for most species
   - $\Delta_f H^\circ$: < 1% for common compounds

For most engineering applications (combustion, cycles, CFD), the differences
are **negligible** compared to other model uncertainties.
"""

# ╔═╡ 11000000-0000-0000-0000-000000000008
md"""
## 4. When to use each source

| Application | Recommended Source |
|-------------|-------------------|
| Engineering calculations (combustion, cycles) | Glenn.jl / NASA-7 |
| High-precision validation | NIST-JANAF (Shomate) |
| Teaching and education | Glenn.jl (simple, dependency-free) |
| CFD and chemical kinetics | Glenn.jl (fast, programmable) |
| Scientific publications | Cross-check NASA + NIST |
"""

# ╔═╡ 11000000-0000-0000-0000-000000000009
md"""
## Summary

In this notebook you:

- Compared Glenn.jl (NASA-7) with literature reference values
- Quantified discrepancies (< 1% for most properties)
- Understood the origins of differences between databases
- Learned recommendations for which source to use in each context

---

This was the final notebook in the series. The 11 notebooks cover everything
from database connection fundamentals to advanced applications in CFD and data
source comparison.

**We hope this material is useful for your learning and research!**

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 11000000-0000-0000-0000-000000000010
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
