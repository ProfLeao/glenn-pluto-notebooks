### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 05000000-0000-0000-0000-000000000001
md"""
# 05 — Reaction Enthalpies & Heats of Combustion

This notebook demonstrates how to compute **reaction enthalpies** $\Delta_r H^\circ$
and **heats of combustion** (LHV/HHV) using Glenn.jl.

**Fundamental principle:** On the NASA scale, the enthalpy of a reaction is
simply the stoichiometric sum of standardized enthalpies of products minus
reactants:

$$\Delta_r H^\circ(T) = \sum_{p} \nu_p H_p^\circ(T) - \sum_{r} \nu_r H_r^\circ(T)$$

> **Note:** This calculation assumes **ideal gas**. For real gas applications,
> non-ideality corrections should be applied.
"""

# ╔═╡ 05000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 05000000-0000-0000-0000-000000000003
md"""
## 1. Helper function for $\Delta_r H^\circ$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000004
begin
    """
        reaction_enthalpy(calc, reactants, products, T)

    Computes ΔrH°(T) from stoichiometric sums.

    - `reactants`: vector of (name, stoichiometric coefficient) tuples
    - `products`:  vector of (name, stoichiometric coefficient) tuples
    - `T`: temperature in Kelvin

    Positive coefficients for both reactants and products.
    Returns ΔrH° in J/mol (of reaction as written).
    """
    function reaction_enthalpy(calc, reactants, products, T)
        function get_h(name)
            sp = only(get_available_species(calc, name, exact_match = true))
            props = calculate_properties(calc, sp.id, T)
            return props.h_relative
        end

        ΔH = 0.0
        for (name, nu) in products
            ΔH += nu * get_h(name)
        end
        for (name, nu) in reactants
            ΔH -= nu * get_h(name)
        end
        return ΔH
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000005
md"""
## 2. Example 1: Methane combustion

$$\text{CH}_4 + 2\text{O}_2 \rightarrow \text{CO}_2 + 2\text{H}_2\text{O}$$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000006
Calculator() do calc
    reactants = [("CH4", 1), ("O2", 2)]
    products  = [("CO2", 1), ("H2O", 2)]

    for T in [298.15, 500.0, 1000.0, 1500.0]
        ΔrH = reaction_enthalpy(calc, reactants, products, T)
        @printf("T = %6.0f K  →  ΔrH° = %10.1f kJ/mol\n", T, ΔrH / 1000.0)
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000007
md"""
### Kirchhoff's Law

The temperature dependence of $\Delta_r H^\circ$ is given by **Kirchhoff's Law**:

$$\frac{d(\Delta_r H^\circ)}{dT} = \Delta_r C_p^\circ$$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000008
md"""
## 3. Example 2: Heating values (LHV/HHV)

**LHV** considers product water as vapor. **HHV** considers product water as
liquid (includes condensation enthalpy).
"""

# ╔═╡ 05000000-0000-0000-0000-000000000009
Calculator() do calc
    ΔH_vap_H2O = 44.0e3  # J/mol

    function fuel_heating_values(calc, fuel_name, nC, nH)
        reactants = [(fuel_name, 1), ("O2", nC + nH / 4)]
        products  = [("CO2", Float64(nC)), ("H2O", Float64(nH) / 2)]

        ΔrH_lhv = reaction_enthalpy(calc, reactants, products, 298.15)
        lhv = -ΔrH_lhv
        hhv = lhv + (nH / 2) * ΔH_vap_H2O
        return lhv, hhv
    end

    fuels = [
        ("CH4",     "Methane",      1, 4),
        ("C2H5OH",  "Ethanol",      2, 6),
        ("C3H8",    "Propane",      3, 8),
    ]

    println("=== Heating Values ===")
    println(rpad("Fuel", 14), rpad("LHV", 20),
            rpad("HHV", 20), rpad("LHV [MJ/kg]", 16))
    println("—"^70)

    for (name, label, nC, nH) in fuels
        try
            sp = only(get_available_species(calc, name, exact_match = true))
            MW = something(sp.molecular_weight, 0.0)
            lhv, hhv = fuel_heating_values(calc, name, nC, nH)
            lhv_MJkg = lhv / MW / 1000.0
            @printf("%-14s %14.1f kJ/mol  %14.1f kJ/mol  %12.2f MJ/kg\n",
                label, lhv / 1000.0, hhv / 1000.0, lhv_MJkg)
        catch e
            @printf("%-14s %s\n", label, "not available")
        end
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000010
md"""
## 4. Example 3: Hess's Law

Hess's Law states that the enthalpy of a reaction is independent of the path.
Let's verify for: $\text{C} + \text{O}_2 \rightarrow \text{CO}_2$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000011
Calculator() do calc
    T = 298.15

    ΔrH_direct = reaction_enthalpy(
        calc,
        [("C", 1), ("O2", 1)],
        [("CO2", 1)],
        T
    )

    ΔrH_step1 = reaction_enthalpy(
        calc,
        [("C", 1), ("O2", 0.5)],
        [("CO", 1)],
        T
    )
    ΔrH_step2 = reaction_enthalpy(
        calc,
        [("CO", 1), ("O2", 0.5)],
        [("CO2", 1)],
        T
    )
    ΔrH_indirect = ΔrH_step1 + ΔrH_step2

    println("=== Hess's Law Verification ===")
    @printf("Direct path:        %10.1f kJ/mol\n", ΔrH_direct / 1000.0)
    @printf("Indirect path:      %10.1f kJ/mol\n", ΔrH_indirect / 1000.0)
end

# ╔═╡ 05000000-0000-0000-0000-000000000012
md"""
## Summary

In this notebook you learned:

- To compute $\Delta_r H^\circ$ via stoichiometric sum of `h_relative`
- Kirchhoff's Law: temperature dependence of $\Delta_r H^\circ$
- To calculate LHV and HHV for fuels
- To verify Hess's Law

In the [next notebook](06_adiabatic_flame_temperature.jl) we will use these
concepts to calculate the **adiabatic flame temperature**.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 05000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
