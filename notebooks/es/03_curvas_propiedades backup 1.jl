### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 03000000-0000-0000-0000-000000000001
md"""
# 03 — Curvas de Propiedades Dependientes de la Temperatura

Este cuaderno genera curvas de $C_p^\circ(T)$, $H^\circ(T)$ y $S^\circ(T)$ para
especies seleccionadas e interpreta sus características físicas:
**equipartición de energía**, **excitación vibracional** y el comportamiento
asintótico a altas temperaturas.

Usaremos `Plots.jl` para visualización y `DataFrames.jl` para tablas.
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
## 1. Especies de interés

Seleccionamos especies diatómico y poliatómicas para comparar sus
comportamientos térmicos:
"""

# ╔═╡ 03000000-0000-0000-0000-000000000004
begin
    SPECIES_LIST = [
        ("O2",   "Oxígeno (diatómico)"),
        ("N2",   "Nitrógeno (diatómico)"),
        ("CO2",  "Dióxido de carbono (triatómico)"),
        ("H2O",  "Agua (triatómico)"),
        ("CH4",  "Metano (pentatómico)"),
    ]
end

# ╔═╡ 03000000-0000-0000-0000-000000000005
md"""
## 2. Curvas de $C_p(T)$
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
        title = "Capacidad Calorífica Molar — Cₚ(T)",
        xlabel = "Temperatura [K]",
        ylabel = "Cₚ [J/(mol·K)]",
        legend = :bottomright,
        size = (800, 500),
    )
    for (name, label) in SPECIES_LIST
        plot!(p_cp, temps, cp_data[label], label = label, lw = 2)
    end
    hline!(p_cp, [20.786], linestyle = :dash, color = :gray,
        label = "Gas monoatómico (5/2 R)")
    hline!(p_cp, [29.099], linestyle = :dash, color = :gray50,
        label = "Gas diatómico clásico (7/2 R)")

    p_cp
end

# ╔═╡ 03000000-0000-0000-0000-000000000007
md"""
### Interpretación

- **300 K**: Gases diatómicos (O₂, N₂) tienen $C_p \approx 29$ J/(mol·K) =
  $\frac{7}{2}R$ — 3 traslaciones + 2 rotaciones activas
- **> 1000 K**: $C_p$ sube con la activación de modos vibracionales
- **Moléculas poliatómicas** (CO₂, H₂O, CH₄) tienen más grados de libertad →
  mayor $C_p$
- **Asíntota**: A T muy alta, tiende al límite clásico de equipartición
"""

# ╔═╡ 03000000-0000-0000-0000-000000000008
md"""
## 3. Curvas de $S^\circ(T)$
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
        title = "Entropía Estándar — S°(T)",
        xlabel = "Temperatura [K]",
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
### Interpretación

- La entropía siempre crece con $T$ (Tercera Ley: $S \to 0$ cuando $T \to 0$)
- Moléculas más grandes tienen mayor entropía (más microestados accesibles)
- CH₄ tiene la mayor entropía entre las especies comparadas
"""

# ╔═╡ 03000000-0000-0000-0000-000000000011
md"""
## 4. Curvas de $H^\circ(T)$ (entalpía sensible)
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
        title = "Entalpía Sensible — H°(T) - H°(298.15)",
        xlabel = "Temperatura [K]",
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
### Interpretación

- La curvatura positiva refleja el aumento de $C_p$ con $T$
- Moléculas poliatómicas acumulan más entalpía (mayor $C_p$)
- Estas curvas son esenciales para balances de energía en procesos de combustión
"""

# ╔═╡ 03000000-0000-0000-0000-000000000014
md"""
## 5. Tabla de propiedades con DataFrames.jl
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
## Resumen

En este cuaderno usted:

- Generó curvas de $C_p(T)$, $S^\circ(T)$ y $H^\circ(T)$ para varias especies
- Interpretó las características físicas: equipartición, vibración, comportamiento asintótico
- Creó tablas de propiedades con DataFrames.jl

En el [siguiente cuaderno](04_entalpia_formacion.jl) exploraremos cómo obtener
la **entalpía de formación** a partir de los polinomios de la NASA.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 03000000-0000-0000-0000-000000000017
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
