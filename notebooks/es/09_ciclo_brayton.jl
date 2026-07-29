### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 09000000-0000-0000-0000-000000000001
md"""
# 09 — Ciclo Brayton de Turbina de Gas

Este cuaderno implementa el **ciclo Brayton estándar-aire** con propiedades
termodinámicas **reales** ($C_p$ dependiente de la temperatura), sustituyendo
la hipótesis de gas calóricamente perfecto.

El ciclo consta de 4 procesos:

1. **Compresión isentrópica** (1 → 2): compresor
2. **Adición de calor isobárica** (2 → 3): cámara de combustión
3. **Expansión isentrópica** (3 → 4): turbina
4. **Rechazo de calor isobárico** (4 → 1): escape

$$\eta_{\text{térmico}} = \frac{W_{\text{neto}}}{Q_{\text{ent}}} \qquad
bwr = \frac{W_{\text{comp}}}{W_{\text{turb}}}$$
"""

# ╔═╡ 09000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using Roots
end

# ╔═╡ 09000000-0000-0000-0000-000000000003
md"""
## 1. Implementación del ciclo con $C_p(T)$ real
"""

# ╔═╡ 09000000-0000-0000-0000-000000000004
begin
    function brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = 10.0)
        air = only(get_available_species(calc, "N2", exact_match = true))

        p1 = calculate_properties(calc, air.id, T1)
        h1, s1 = p1.h_relative, p1.s

        s2_target = s1 + Glenn.R_UNIVERSAL * log(rp)
        T2 = find_zero(T -> calculate_properties(calc, air.id, T).s - s2_target,
            (T1 * 1.5, T1 * 5.0))
        h2 = calculate_properties(calc, air.id, T2).h_relative
        w_comp = h2 - h1

        p3 = calculate_properties(calc, air.id, T3)
        h3, s3 = p3.h_relative, p3.s

        s4_target = s3 - Glenn.R_UNIVERSAL * log(rp)
        T4 = find_zero(T -> calculate_properties(calc, air.id, T).s - s4_target,
            (T3 * 0.5, T3 * 0.95))
        h4 = calculate_properties(calc, air.id, T4).h_relative
        w_turb = h3 - h4

        q_in = h3 - h2
        w_net = w_turb - w_comp
        eta_th = w_net / q_in
        bwr = w_comp / w_turb

        return Dict("T1"=>T1,"T2"=>T2,"T3"=>T3,"T4"=>T4,
            "w_comp"=>w_comp,"w_turb"=>w_turb,"w_net"=>w_net,
            "q_in"=>q_in,"eta_th"=>eta_th,"bwr"=>bwr,"rp"=>rp)
    end
end

# ╔═╡ 09000000-0000-0000-0000-000000000005
md"""
## 2. Ejemplo: $r_p = 10$
"""

# ╔═╡ 09000000-0000-0000-0000-000000000006
Calculator() do calc
    r = brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = 10.0)
    println("=== Ciclo Brayton — rp = $(r["rp"]) ===")
    for (label, T) in [("1 (ent comp)", r["T1"]), ("2 (sal comp)", r["T2"]),
                        ("3 (ent turb)", r["T3"]), ("4 (sal turb)", r["T4"])]
        @printf("  %-18s  T = %7.1f K\n", label, T)
    end
    println()
    @printf("  w_comp  = %10.1f kJ/mol\n", r["w_comp"] / 1000.0)
    @printf("  w_turb  = %10.1f kJ/mol\n", r["w_turb"] / 1000.0)
    @printf("  w_neto  = %10.1f kJ/mol\n", r["w_net"] / 1000.0)
    @printf("  η_térm  = %10.3f  (%5.1f %%)\n", r["eta_th"], r["eta_th"] * 100)
end

# ╔═╡ 09000000-0000-0000-0000-000000000007
md"""
## 3. Eficiencia vs relación de presión
"""

# ╔═╡ 09000000-0000-0000-0000-000000000008
begin
    rp_range = [4, 6, 8, 10, 12, 15, 18, 20, 25, 30]
    eta_list = Float64[]
    Calculator() do calc
        for rp in rp_range
            r = brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = Float64(rp))
            push!(eta_list, r["eta_th"])
        end
    end

    println("=== η vs rp ===")
    for (i, rp) in enumerate(rp_range)
        @printf("rp=%-3d  η=%5.1f %%\n", rp, eta_list[i] * 100)
    end
end

# ╔═╡ 09000000-0000-0000-0000-000000000009
md"""
### Interpretación

1. La eficiencia crece con $r_p$
2. Límite práctico: $r_p$ limitado por temperatura máxima de materiales

En el [siguiente cuaderno](10_proveedor_propiedades.jl) construiremos un
**proveedor de propiedades** optimizado para CFD.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 09000000-0000-0000-0000-000000000010
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
