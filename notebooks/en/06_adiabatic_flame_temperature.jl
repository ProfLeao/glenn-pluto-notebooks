### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 06000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using Roots
end

# ╔═╡ 06000000-0000-0000-0000-000000000001
md"""
# 06 — Adiabatic Flame Temperature

The **adiabatic flame temperature** $T_{ad}$ is the maximum temperature achieved
when a fuel burns under adiabatic conditions (no heat exchange with the
surroundings) at constant pressure.

The energy balance is:

$$H_{\text{reactants}}(T_0) = H_{\text{products}}(T_{ad})$$

This notebook solves this equation for various fuels, exploring the effects of
**equivalence ratio**, **preheating**, and **dissociation**.
"""

# ╔═╡ 06000000-0000-0000-0000-000000000003
md"""
## 1. Adiabatic flame temperature function

Computes $T_{ad}$ for complete combustion of a hydrocarbon fuel.

> **Note:** Actual values are lower due to dissociation (CO₂ → CO + ½O₂,
> H₂O → H₂ + ½O₂), which consumes energy. This is a first approximation.
"""

# ╔═╡ 06000000-0000-0000-0000-000000000004
begin
    function adiabatic_flame_temperature(calc, fuel, T_initial = 300.0, phi = 1.0)
        sp = only(get_available_species(calc, fuel, exact_match = true))

        nC, nH = 1, 4
        if fuel == "CH4"
            nC, nH = 1, 4
        elseif fuel == "C2H5OH"
            nC, nH = 2, 6
        elseif fuel == "C3H8"
            nC, nH = 3, 8
        elseif fuel == "H2"
            nC, nH = 0, 2
        end

        nO2_stoich = nC + nH / 4
        nO2_actual = nO2_stoich / phi

        h_fuel = calculate_properties(calc, sp.id, T_initial).h_relative
        o2 = only(get_available_species(calc, "O2", exact_match = true))
        h_o2 = calculate_properties(calc, o2.id, T_initial).h_relative
        H_react = h_fuel + nO2_actual * h_o2

        nO2_excess = max(0.0, nO2_actual - nO2_stoich)
        co2 = only(get_available_species(calc, "CO2", exact_match = true))
        h2o = only(get_available_species(calc, "H2O", exact_match = true))

        function H_products(T)
            h = nC * calculate_properties(calc, co2.id, T).h_relative
            h += (nH / 2) * calculate_properties(calc, h2o.id, T).h_relative
            if nO2_excess > 0
                h += nO2_excess * calculate_properties(calc, o2.id, T).h_relative
            end
            return h
        end

        f(T) = H_products(T) - H_react
        T_ad = find_zero(f, (300.0, 6000.0))
        return T_ad
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000005
md"""
## 2. Stoichiometric combustion ($\phi = 1.0$)
"""

# ╔═╡ 06000000-0000-0000-0000-000000000006
Calculator() do calc
    fuels = ["CH4", "C2H5OH", "C3H8", "H2"]
    println("=== Adiabatic Flame Temperatures (φ=1, T₀=300 K) ===")
    println(rpad("Fuel", 16), rpad("T_ad [K]", 14), "T_ad [°C]")
    println("—"^44)
    for fuel in fuels
        try
            T_ad = adiabatic_flame_temperature(calc, fuel, 300.0, 1.0)
            @printf("%-16s %10.0f K    %8.0f °C\n", fuel, T_ad, T_ad - 273.15)
        catch e
            @printf("%-16s error: %s\n", fuel, e)
        end
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000007
md"""
## 3. Effect of equivalence ratio ($\phi$)
"""

# ╔═╡ 06000000-0000-0000-0000-000000000008
Calculator() do calc
    fuel = "CH4"
    phis = [0.5, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.5]
    println("=== Effect of φ — $fuel (T₀=300 K) ===")
    println(rpad("φ", 8), rpad("T_ad [K]", 14), "Note")
    println("—"^40)
    for phi in phis
        try
            T_ad = adiabatic_flame_temperature(calc, fuel, 300.0, phi)
            obs = phi < 1.0 ? "lean (excess O₂)" :
                  phi > 1.0 ? "rich (O₂ deficient)" : "stoichiometric"
            @printf("%-8.1f %10.0f K    %s\n", phi, T_ad, obs)
        catch e
            @printf("%-8.1f error\n", phi)
        end
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000009
md"""
## 4. Effect of preheating
"""

# ╔═╡ 06000000-0000-0000-0000-000000000010
Calculator() do calc
    fuel = "CH4"
    T_initials = [300, 400, 500, 600, 800]
    println("=== Preheating Effect — $fuel (φ=1.0) ===")
    T_ad_base = adiabatic_flame_temperature(calc, fuel, 300.0, 1.0)
    for T0 in T_initials
        T_ad = adiabatic_flame_temperature(calc, fuel, Float64(T0), 1.0)
        @printf("T₀=%-5.0f K  T_ad=%8.0f K  ΔT=%+6.0f K\n", T0, T_ad, T_ad - T_ad_base)
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000011
md"""
## Summary

In this notebook you:

- Implemented the energy balance for $T_{ad}$ using `find_zero`
- Calculated $T_{ad}$ for CH₄, C₂H₅OH, C₃H₈ and H₂
- Explored the effects of equivalence ratio $\phi$ and preheating

In the [next notebook](07_biofuel_comparison.jl) we systematically compare
**fuels and biofuels**.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 06000000-0000-0000-0000-000000000012
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═06000000-0000-0000-0000-000000000001
# ╠═06000000-0000-0000-0000-000000000002
# ╠═06000000-0000-0000-0000-000000000003
# ╠═06000000-0000-0000-0000-000000000004
# ╠═06000000-0000-0000-0000-000000000005
# ╠═06000000-0000-0000-0000-000000000006
# ╠═06000000-0000-0000-0000-000000000007
# ╠═06000000-0000-0000-0000-000000000008
# ╠═06000000-0000-0000-0000-000000000009
# ╠═06000000-0000-0000-0000-000000000010
# ╠═06000000-0000-0000-0000-000000000011
# ╠═06000000-0000-0000-0000-000000000012
