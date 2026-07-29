### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 04000000-0000-0000-0000-000000000001
md"""
# 04 — Enthalpy of Formation from NASA Polynomials

This notebook shows how to obtain the **standard enthalpy of formation**
$\Delta_f H^\circ$ from the data stored in the Glenn.jl database.

**Key concept:** On the NASA scale, the standardized enthalpy
$H^\circ(T)$ (`h_relative` field) already **includes the enthalpy of
formation**. Therefore:

- For a **reference-state element** (e.g. O₂, N₂, H₂, C(graphite)):
  $H^\circ(298.15\,\text{K}) \approx 0$
- For a **compound** (e.g. CH₄, CO₂, H₂O):
  $H^\circ(298.15\,\text{K}) = \Delta_f H^\circ(298.15\,\text{K})$
"""

# ╔═╡ 04000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 04000000-0000-0000-0000-000000000003
md"""
## 1. Direct $\Delta_f H^\circ$ retrieval

`calculate_formation_enthalpy(calc, id)` returns the enthalpy of formation at
298.15 K:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000004
Calculator() do calc
    println("=== Standard Enthalpies of Formation ===")
    println(rpad("Species", 10), rpad("ΔfH°(298.15 K) [kJ/mol]", 28), "Source")
    println("—"^55)

    for (name, desc) in [
        ("CH4", "methane"),
        ("C2H5OH", "ethanol"),
        ("CO2", "carbon dioxide"),
        ("H2O", "water (gas)"),
        ("O2", "reference element"),
        ("N2", "reference element"),
        ("H2", "reference element"),
        ("C", "carbon (graphite)"),
    ]
        sp = only(get_available_species(calc, name, exact_match = true))
        h_f = calculate_formation_enthalpy(calc, sp.id)
        if h_f !== nothing
            @printf("%-10s %12.1f kJ/mol               %s\n",
                name, h_f / 1000.0, desc)
        else
            @printf("%-10s %12s                       %s\n",
                name, "N/A", desc)
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000005
md"""
## 2. Obtaining $\Delta_f H^\circ$ via `h_relative`

Since the `heat_of_formation_298K` column may not be populated in the database,
the alternative method is using `h_relative` at 298.15 K:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000006
Calculator() do calc
    println("=== Comparison: h_relative vs API ===")
    println(rpad("Species", 10), rpad("h_relative(298.15)", 22),
            rpad("API ΔfH°", 18), rpad("Difference", 16))
    println("—"^66)

    for name in ["CH4", "CO2", "H2O", "C2H5OH", "O2", "N2"]
        sp = only(get_available_species(calc, name, exact_match = true))
        props = calculate_properties(calc, sp.id, 298.15)
        h_f_api = calculate_formation_enthalpy(calc, sp.id)

        if h_f_api !== nothing
            diff = props.h_relative - h_f_api
            @printf("%-10s %18.1f J/mol  %14.1f  %14.1f\n",
                name, props.h_relative, h_f_api, diff)
        else
            @printf("%-10s %18.1f J/mol  %14s  %14s\n",
                name, props.h_relative, "N/A", "—")
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000007
md"""
## 3. Validation against literature values

We compare the obtained values with standard enthalpies of formation from the
literature:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000008
begin
    const LITERATURE_VALUES = Dict(
        "CH4"    => -74.87,
        "CO2"    => -393.51,
        "H2O"    => -241.83,  # gas
        "C2H5OH" => -234.8,
        "O2"     => 0.0,
        "N2"     => 0.0,
    )
end

# ╔═╡ 04000000-0000-0000-0000-000000000009
Calculator() do calc
    println("=== Validation against Literature ===")
    println(rpad("Species", 10), rpad("Glenn.jl", 16),
            rpad("Literature", 16), rpad("Rel. Error", 14))
    println("—"^56)

    for name in ["CH4", "CO2", "H2O", "C2H5OH", "O2", "N2"]
        sp = only(get_available_species(calc, name, exact_match = true))
        h_f = calculate_formation_enthalpy(calc, sp.id)

        if h_f !== nothing && haskey(LITERATURE_VALUES, name)
            lit = LITERATURE_VALUES[name] * 1000.0
            err_pct = (h_f - lit) / abs(lit) * 100.0
            @printf("%-10s %12.1f J/mol  %12.1f J/mol  %+8.3f %%\n",
                name, h_f, lit, err_pct)
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000010
md"""
## 4. Application: $\Delta_f H^\circ$ for biofuels
"""

# ╔═╡ 04000000-0000-0000-0000-000000000011
Calculator() do calc
    biofuels = [
        ("CH3OH",     "Methanol"),
        ("C2H5OH",    "Ethanol"),
        ("CH3COOH",   "Acetic acid"),
    ]

    println("=== Enthalpies of Formation — Biofuels ===")
    println(rpad("Species", 12), rpad("Name", 18),
            rpad("ΔfH° [kJ/mol]", 18), "Phase")
    println("—"^56)

    for (formula, name) in biofuels
        try
            sp = only(get_available_species(calc, formula, exact_match = true))
            h_f = calculate_formation_enthalpy(calc, sp.id)
            if h_f !== nothing
                @printf("%-12s %-18s %+12.1f kJ/mol     %s\n",
                    formula, name, h_f / 1000.0, sp.phase)
            end
        catch e
            @printf("%-12s %-18s %s\n", formula, name, "not found")
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000012
md"""
## Summary

In this notebook you learned:

- That `h_relative` at 298.15 K = $\Delta_f H^\circ$ for compounds
- That `calculate_formation_enthalpy()` is the recommended direct method
- To validate values against the literature
- The importance of formation enthalpy for reaction calculations

In the [next notebook](05_reaction_enthalpies.jl) we will use these values to
compute **reaction enthalpies** and **heats of combustion**.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 04000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
