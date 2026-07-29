### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 04000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 04000000-0000-0000-0000-000000000001
md"""
# 04 — Entalpía de Formación a partir de los Polinomios de la NASA

Este cuaderno muestra cómo obtener la **entalpía de formación estándar**
$\Delta_f H^\circ$ a partir de los datos almacenados en la base de datos de
Glenn.jl.

**Concepto fundamental:** En la escala NASA, la entalpía estandarizada
$H^\circ(T)$ (campo `h_relative`) ya **incluye la entalpía de formación**.
Por lo tanto:

- Para un **elemento en el estado de referencia** (ej: O₂, N₂, H₂, C(graf)):
  $H^\circ(298.15\,\text{K}) \approx 0$
- Para un **compuesto** (ej: CH₄, CO₂, H₂O):
  $H^\circ(298.15\,\text{K}) = \Delta_f H^\circ(298.15\,\text{K})$
"""

# ╔═╡ 04000000-0000-0000-0000-000000000003
md"""
## 1. Obteniendo $\Delta_f H^\circ$ directamente

`calculate_formation_enthalpy(calc, id)` devuelve la entalpía de formación a
298.15 K:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000004
Calculator() do calc
    println("=== Entalpías de Formación Estándar ===")
    println(rpad("Especie", 10), rpad("ΔfH°(298.15 K) [kJ/mol]", 28), "Fuente")
    println("—"^55)

    for (name, desc) in [
        ("CH4", "metano"),
        ("C2H5OH", "etanol"),
        ("CO2", "dióxido de carbono"),
        ("H2O", "agua (gas)"),
        ("O2", "elemento referencia"),
        ("N2", "elemento referencia"),
        ("H2", "elemento referencia"),
        ("C", "carbono (grafito)"),
    ]
        sp = only(get_available_species(calc, name, exact_match = true))
        h_f = calculate_formation_enthalpy(calc, sp.id)
        if h_f !== nothing
            @printf("%-10s %12.1f kJ/mol               %s\n",
                name, h_f / 1000.0, desc)
        else
            @printf("%-10s %12s                       %s\n",
                name, "N/D", desc)
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000005
md"""
## 2. Obteniendo $\Delta_f H^\circ$ vía `h_relative`

Como el campo `heat_of_formation_298K` puede no estar poblado en la base de
datos, el método alternativo es usar `h_relative` a 298.15 K:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000006
Calculator() do calc
    println("=== Comparación: h_relative vs API ===")
    println(rpad("Especie", 10), rpad("h_relative(298.15)", 22),
            rpad("API ΔfH°", 18), rpad("Diferencia", 16))
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
                name, props.h_relative, "N/D", "—")
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000007
md"""
## 3. Validación contra valores de la literatura
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
    println("=== Validación contra Literatura ===")
    println(rpad("Especie", 10), rpad("Glenn.jl", 16),
            rpad("Literatura", 16), rpad("Error Rel.", 14))
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
## 4. Aplicación: $\Delta_f H^\circ$ para biocombustibles
"""

# ╔═╡ 04000000-0000-0000-0000-000000000011
Calculator() do calc
    biofuels = [
        ("CH3OH",     "Metanol"),
        ("C2H5OH",    "Etanol"),
        ("CH3COOH",   "Ácido acético"),
    ]

    println("=== Entalpías de Formación — Biocombustibles ===")
    println(rpad("Especie", 12), rpad("Nombre", 18),
            rpad("ΔfH° [kJ/mol]", 18), "Fase")
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
            @printf("%-12s %-18s %s\n", formula, name, "no encontrado")
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000012
md"""
## Resumen

En este cuaderno aprendió:

- Que `h_relative` a 298.15 K = $\Delta_f H^\circ$ para compuestos
- Que `calculate_formation_enthalpy()` es el método directo recomendado
- A validar valores contra la literatura
- La importancia de la entalpía de formación para cálculos de reacción

En el [siguiente cuaderno](05_entalpias_reaccion.jl) usaremos estos valores
para calcular **entalpías de reacción** y **calores de combustión**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 04000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═04000000-0000-0000-0000-000000000001
# ╠═04000000-0000-0000-0000-000000000002
# ╠═04000000-0000-0000-0000-000000000003
# ╠═04000000-0000-0000-0000-000000000004
# ╠═04000000-0000-0000-0000-000000000005
# ╠═04000000-0000-0000-0000-000000000006
# ╠═04000000-0000-0000-0000-000000000007
# ╠═04000000-0000-0000-0000-000000000008
# ╠═04000000-0000-0000-0000-000000000009
# ╠═04000000-0000-0000-0000-000000000010
# ╠═04000000-0000-0000-0000-000000000011
# ╠═04000000-0000-0000-0000-000000000012
# ╠═04000000-0000-0000-0000-000000000013
