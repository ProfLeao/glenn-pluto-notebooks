### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 03000000-0000-0000-0000-000000000001
md"""
# 03 — Temperature-Dependent Property Curves

This notebook generates $C_p^\circ(T)$, $H^\circ(T)$ and $S^\circ(T)$ curves
for selected species and interprets their physical features: **energy
equipartition**, **vibrational excitation**, and asymptotic behavior at high
temperatures.

We'll use `Plots.jl` for visualization and `DataFrames.jl` for tables.
"""

# ╔═╡ 03000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using Plots
    using DataFrames
end

# ╔═╡ 03000000-0000-0000-0000-000000000003
md"""
## 1. Species of interest

We select diatomic and polyatomic species to compare their thermal behavior:
"""

# ╔═╡ 03000000-0000-0000-0000-000000000004
begin
    SPECIES_LIST = [
        ("O2",   "Oxygen (diatomic)"),
        ("N2",   "Nitrogen (diatomic)"),
        ("CO2",  "Carbon dioxide (triatomic)"),
        ("H2O",  "Water (triatomic)"),
        ("CH4",  "Methane (penta-atomic)"),
    ]
end

# ╔═╡ 03000000-0000-0000-0000-000000000005
md"""
## 2. $C_p(T)$ curves
"""

# ╔═╡ 03000000-0000-0000-0000-000000000006
begin
    temps = 250:10:3000
    cp_data = Dict{String, Vector{Float64}}()

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            sp = only(get_available_species(calc, name, exact_match = true))
            results = get_properties_range(calc, sp.id, collect(temps))
            cp_data[label] = [r.cp for r in results]
        end
    end

    p_cp = plot(
        title = "Molar Heat Capacity — Cₚ(T)",
        xlabel = "Temperature [K]",
        ylabel = "Cₚ [J/(mol·K)]",
        legend = :bottomright,
        size = (800, 500),
    )
    for (name, label) in SPECIES_LIST
        plot!(p_cp, temps, cp_data[label], label = label, lw = 2)
    end
    hline!(p_cp, [20.786], linestyle = :dash, color = :gray,
        label = "Monatomic gas (5/2 R)")
    hline!(p_cp, [29.099], linestyle = :dash, color = :gray50,
        label = "Classical diatomic (7/2 R)")

    p_cp
end

# ╔═╡ 03000000-0000-0000-0000-000000000007
md"""
### Interpretation

- **300 K**: Diatomic gases (O₂, N₂) have $C_p \approx 29$ J/(mol·K) =
  $\frac{7}{2}R$ — 3 translations + 2 rotations active
- **> 1000 K**: $C_p$ rises with activation of vibrational modes
- **Polyatomic molecules** (CO₂, H₂O, CH₄) have more degrees of freedom →
  higher $C_p$
- **Asymptote**: At very high T, tends toward the classical equipartition limit
"""

# ╔═╡ 03000000-0000-0000-0000-000000000008
md"""
## 3. $S^\circ(T)$ curves
"""

# ╔═╡ 03000000-0000-0000-0000-000000000009
begin
    s_data = Dict{String, Vector{Float64}}()

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            sp = only(get_available_species(calc, name, exact_match = true))
            results = get_properties_range(calc, sp.id, collect(temps))
            s_data[label] = [r.s for r in results]
        end
    end

    p_s = plot(
        title = "Standard Entropy — S°(T)",
        xlabel = "Temperature [K]",
        ylabel = "S° [J/(mol·K)]",
        legend = :topleft,
        size = (800, 500),
    )
    for (name, label) in SPECIES_LIST
        plot!(p_s, temps, s_data[label], label = label, lw = 2)
    end

    p_s
end

# ╔═╡ 03000000-0000-0000-0000-000000000010
md"""
### Interpretation

- Entropy always increases with $T$ (Third Law: $S \to 0$ as $T \to 0$)
- Larger molecules have higher entropy (more accessible microstates)
- CH₄ has the highest entropy among the compared species
"""

# ╔═╡ 03000000-0000-0000-0000-000000000011
md"""
## 4. $H^\circ(T)$ (sensible enthalpy)
"""

# ╔═╡ 03000000-0000-0000-0000-000000000012
begin
    h_data = Dict{String, Vector{Float64}}()

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            sp = only(get_available_species(calc, name, exact_match = true))
            results = get_properties_range(calc, sp.id, collect(temps))
            h_data[label] = [(r.h_relative - calculate_properties(calc, sp.id, 298.15).h_relative) / 1000.0 for r in results]
        end
    end

    p_h = plot(
        title = "Sensible Enthalpy — H°(T) - H°(298.15)",
        xlabel = "Temperature [K]",
        ylabel = "ΔH [kJ/mol]",
        legend = :topleft,
        size = (800, 500),
    )
    for (name, label) in SPECIES_LIST
        plot!(p_h, temps, h_data[label], label = label, lw = 2)
    end

    p_h
end

# ╔═╡ 03000000-0000-0000-0000-000000000013
md"""
### Interpretation

- Positive curvature reflects the increase in $C_p$ with $T$
- Polyatomic molecules accumulate more enthalpy (higher $C_p$)
- These curves are essential for energy balances in combustion processes
"""

# ╔═╡ 03000000-0000-0000-0000-000000000014
md"""
## 5. Property table with DataFrames.jl
"""

# ╔═╡ 03000000-0000-0000-0000-000000000015
begin
    prop_table = DataFrame()
    prop_table.T_K = Float64[]

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            col_name = name * " (J/mol/K)"
            prop_table[!, col_name] = Float64[]

            selected_temps = [300, 400, 500, 600, 800, 1000, 1500, 2000]
            for (i, T) in enumerate(selected_temps)
                sp = only(get_available_species(calc, name, exact_match = true))
                props = calculate_properties(calc, sp.id, T)
                if name == SPECIES_LIST[1][1]
                    push!(prop_table.T_K, T)
                end
                push!(prop_table[!, col_name], props.cp)
            end
        end
    end

    prop_table
end

# ╔═╡ 03000000-0000-0000-0000-000000000016
md"""
## Summary

In this notebook you:

- Generated $C_p(T)$, $S^\circ(T)$ and $H^\circ(T)$ curves for various species
- Interpreted physical features: equipartition, vibration, asymptotic behavior
- Created property tables with DataFrames.jl

In the [next notebook](04_formation_enthalpy.jl) we will explore how to obtain
the **enthalpy of formation** from NASA polynomials.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 03000000-0000-0000-0000-000000000017
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
