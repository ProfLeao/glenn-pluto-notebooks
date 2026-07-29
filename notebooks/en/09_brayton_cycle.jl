### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 09000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using Roots
end

# ╔═╡ 09000000-0000-0000-0000-000000000001
md"""
# 09 — Brayton Gas-Turbine Cycle

This notebook implements the **air-standard Brayton cycle** with **real**
thermodynamic properties (temperature-dependent $C_p$), replacing the
calorically perfect gas assumption.

The cycle consists of 4 processes:

1. **Isentropic compression** (1 → 2): compressor
2. **Isobaric heat addition** (2 → 3): combustion chamber
3. **Isentropic expansion** (3 → 4): turbine
4. **Isobaric heat rejection** (4 → 1): exhaust

Performance metrics:

$$\eta_{\text{thermal}} = \frac{W_{\text{net}}}{Q_{\text{in}}}$$
$$bwr = \frac{W_{\text{comp}}}{W_{\text{turb}}}$$
"""

# ╔═╡ 09000000-0000-0000-0000-000000000003
md"""
## 1. Brayton cycle implementation with real $C_p(T)$
"""

# ╔═╡ 09000000-0000-0000-0000-000000000004
begin
    function brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = 10.0)
        air = only(get_available_species(calc, "N2", exact_match = true))

        # State 1: compressor inlet
        p1 = calculate_properties(calc, air.id, T1)
        h1, s1 = p1.h_relative, p1.s

        # State 2: compressor outlet (isentropic)
        s2_target = s1 + Glenn.R_UNIVERSAL * log(rp)
        function s2_error(T)
            p2 = calculate_properties(calc, air.id, T)
            return p2.s - s2_target
        end
        T2 = find_zero(s2_error, (T1 * 1.5, T1 * 5.0))
        h2 = calculate_properties(calc, air.id, T2).h_relative
        w_comp = h2 - h1

        # State 3: turbine inlet
        p3 = calculate_properties(calc, air.id, T3)
        h3, s3 = p3.h_relative, p3.s

        # State 4: turbine outlet (isentropic)
        s4_target = s3 - Glenn.R_UNIVERSAL * log(rp)
        function s4_error(T)
            p4 = calculate_properties(calc, air.id, T)
            return p4.s - s4_target
        end
        T4 = find_zero(s4_error, (T3 * 0.5, T3 * 0.95))
        h4 = calculate_properties(calc, air.id, T4).h_relative
        w_turb = h3 - h4

        q_in = h3 - h2
        w_net = w_turb - w_comp
        eta_th = w_net / q_in
        bwr = w_comp / w_turb

        return Dict(
            "T1" => T1, "T2" => T2, "T3" => T3, "T4" => T4,
            "w_comp" => w_comp, "w_turb" => w_turb, "w_net" => w_net,
            "q_in" => q_in, "eta_th" => eta_th, "bwr" => bwr, "rp" => rp,
        )
    end
end

# ╔═╡ 09000000-0000-0000-0000-000000000005
md"""
## 2. Example: cycle with $r_p = 10$
"""

# ╔═╡ 09000000-0000-0000-0000-000000000006
Calculator() do calc
    r = brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = 10.0)

    println("=== Brayton Cycle — rp = $(r["rp"]) ===")
    println()
    for (label, T) in [("1 (comp in)", r["T1"]), ("2 (comp out)", r["T2"]),
                        ("3 (turb in)", r["T3"]), ("4 (turb out)", r["T4"])]
        @printf("  %-18s  T = %7.1f K\n", label, T)
    end
    println()
    println("Performance:")
    @printf("  w_comp  = %10.1f kJ/mol\n", r["w_comp"] / 1000.0)
    @printf("  w_turb  = %10.1f kJ/mol\n", r["w_turb"] / 1000.0)
    @printf("  w_net   = %10.1f kJ/mol\n", r["w_net"] / 1000.0)
    @printf("  η_therm = %10.3f  (%5.1f %%)\n", r["eta_th"], r["eta_th"] * 100)
    @printf("  bwr     = %10.3f  (%5.1f %%)\n", r["bwr"], r["bwr"] * 100)
end

# ╔═╡ 09000000-0000-0000-0000-000000000007
md"""
## 3. Efficiency vs pressure ratio
"""

# ╔═╡ 09000000-0000-0000-0000-000000000008
begin
    rp_range = [4, 6, 8, 10, 12, 15, 18, 20, 25, 30]
    eta_list = Float64[]
    bwr_list = Float64[]

    Calculator() do calc
        for rp in rp_range
            r = brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = Float64(rp))
            push!(eta_list, r["eta_th"])
            push!(bwr_list, r["bwr"])
        end
    end

    println("=== Efficiency vs Pressure Ratio ===")
    println(rpad("rp", 8), rpad("η_therm [%]", 16), rpad("bwr [%]", 14))
    println("—"^38)
    for (i, rp) in enumerate(rp_range)
        @printf("%-8d %12.1f %%     %10.1f %%\n",
            rp, eta_list[i] * 100, bwr_list[i] * 100)
    end
end

# ╔═╡ 09000000-0000-0000-0000-000000000009
md"""
### Interpretation

1. **Efficiency increases with $r_p$**: Higher pressure ratio → higher thermal
   efficiency
2. **BWR increases with $r_p$**: Compressor consumes a larger fraction of
   turbine work
3. **Practical limit**: $r_p$ limited by maximum material temperature ($T_3$)
   and compressor complexity
"""

# ╔═╡ 09000000-0000-0000-0000-000000000010
md"""
## Summary

In this notebook you:

- Implemented the Brayton cycle with real $C_p(T)$
- Used `find_zero` to solve for isentropic states
- Calculated thermal efficiency and backwork ratio
- Analyzed the effect of pressure ratio on performance

In the [next notebook](10_property_provider.jl) we build an optimized
**property provider** for CFD and chemical kinetics.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 09000000-0000-0000-0000-000000000011
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═09000000-0000-0000-0000-000000000001
# ╠═09000000-0000-0000-0000-000000000002
# ╠═09000000-0000-0000-0000-000000000003
# ╠═09000000-0000-0000-0000-000000000004
# ╠═09000000-0000-0000-0000-000000000005
# ╠═09000000-0000-0000-0000-000000000006
# ╠═09000000-0000-0000-0000-000000000007
# ╠═09000000-0000-0000-0000-000000000008
# ╠═09000000-0000-0000-0000-000000000009
# ╠═09000000-0000-0000-0000-000000000010
# ╠═09000000-0000-0000-0000-000000000011
