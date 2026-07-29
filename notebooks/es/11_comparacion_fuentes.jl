### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 11000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 11000000-0000-0000-0000-000000000001
md"""
# 11 — Comparación de Fuentes de Datos Termodinámicos

Este cuaderno compara los valores de propiedades termodinámicas obtenidos de
diferentes fuentes:

1. **Glenn.jl** — Polinomios NASA-7 (base de datos `thermo.inp` del NASA Glenn)
2. **NIST-JANAF** — Tablas termoquímicas de referencia (Chase, 1998)
3. **Tablas convencionales** — Valores tabulados de libros de texto
"""

# ╔═╡ 11000000-0000-0000-0000-000000000003
md"""
## 1. Valores de referencia de la literatura
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
## 2. Comparación lado a lado
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
                @warn "Error: $name: $e"
            end
        end
    end

    df_comp = DataFrame(
        Especie = [r.name for r in comparison_results],
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
    show(select(df_comp, :Especie, :Cp_ref, :Cp_glenn, :Cp_err_pct), allcols = true)
    println()
    println("=== S° [J/(mol·K)] ===")
    show(select(df_comp, :Especie, :S_ref, :S_glenn, :S_err_pct), allcols = true)
    println()
    println("=== ΔfH° [kJ/mol] ===")
    show(select(df_comp, :Especie, :Hf_ref_kJ, :Hf_glenn_kJ), allcols = true)
end

# ╔═╡ 11000000-0000-0000-0000-000000000007
md"""
## 3. Análisis de discrepancias

### Orígenes de las diferencias:

1. **Conjunto de datos base**: NASA Glenn vs NIST-JANAF (Shomate)
2. **Método de ajuste**: Polinomios NASA-7 *piecewise* vs otros métodos
3. **Diferencias típicas**: $C_p$ < 0.5%, $S^\circ$ < 0.2%, $\Delta_f H^\circ$ < 1%

Para la mayoría de aplicaciones de ingeniería, las diferencias son
**despreciables**.
"""

# ╔═╡ 11000000-0000-0000-0000-000000000008
md"""
## 4. Cuándo usar cada fuente

| Aplicación | Fuente Recomendada |
|-----------|-------------------|
| Cálculos de ingeniería | Glenn.jl / NASA-7 |
| Validación de alta precisión | NIST-JANAF (Shomate) |
| Enseñanza | Glenn.jl (simple, sin dependencias) |
| CFD y cinética química | Glenn.jl (rápido, programable) |

---

¡Este fue el último cuaderno de la serie! Los 11 cuadernos cubren desde los
fundamentos hasta aplicaciones avanzadas.

**¡Esperamos que este material sea útil para su aprendizaje e investigación!**

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 11000000-0000-0000-0000-000000000009
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═11000000-0000-0000-0000-000000000001
# ╠═11000000-0000-0000-0000-000000000002
# ╠═11000000-0000-0000-0000-000000000003
# ╠═11000000-0000-0000-0000-000000000004
# ╠═11000000-0000-0000-0000-000000000005
# ╠═11000000-0000-0000-0000-000000000006
# ╠═11000000-0000-0000-0000-000000000007
# ╠═11000000-0000-0000-0000-000000000008
# ╠═11000000-0000-0000-0000-000000000009
