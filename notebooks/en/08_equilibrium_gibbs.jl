### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 08000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 08000000-0000-0000-0000-000000000001
md"""
# 08 — Chemical Equilibrium & Gibbs Free Energy

This notebook explores **chemical equilibrium** using the standard **Gibbs free
energy** $\Delta_r G^\circ(T)$ and the **equilibrium constant** $K(T)$.

The fundamental relations are:

$$\Delta_r G^\circ(T) = \Delta_r H^\circ(T) - T \cdot \Delta_r S^\circ(T)$$

$$K(T) = \exp\left(-\frac{\Delta_r G^\circ(T)}{RT}\right)$$

Topics covered:

1. Computing $\Delta_r G^\circ(T)$ and $K(T)$
2. **Water-gas shift reaction** — temperature dependence
3. **van't Hoff equation**
4. High-temperature dissociation
"""

# ╔═╡ 08000000-0000-0000-0000-000000000003
md"""
## 1. Gibbs free energy and equilibrium constant
"""

# ╔═╡ 08000000-0000-0000-0000-000000000004
begin
    function reaction_gibbs_free_energy(calc, reactants, products, T)
        function get_props(name)
            sp = only(get_available_species(calc, name, exact_match = true))
            return calculate_properties(calc, sp.id, T)
        end

        ΔrH = 0.0
        ΔrS = 0.0
        for (name, nu) in products
            p = get_props(name)
            ΔrH += nu * p.h_relative
            ΔrS += nu * p.s
        end
        for (name, nu) in reactants
            p = get_props(name)
            ΔrH -= nu * p.h_relative
            ΔrS -= nu * p.s
        end

        ΔrG = ΔrH - T * ΔrS
        return ΔrG, ΔrH, ΔrS
    end

    function equilibrium_constant(calc, reactants, products, T)
        ΔrG, _, _ = reaction_gibbs_free_energy(calc, reactants, products, T)
        return exp(-ΔrG / (Glenn.R_UNIVERSAL * T))
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000005
md"""
## 2. Water-Gas Shift Reaction

$$\text{CO} + \text{H}_2\text{O} \rightleftharpoons \text{CO}_2 + \text{H}_2$$
"""

# ╔═╡ 08000000-0000-0000-0000-000000000006
Calculator() do calc
    reactants = [("CO", 1), ("H2O", 1)]
    products  = [("CO2", 1), ("H2", 1)]

    println("=== Water-Gas Shift: CO + H₂O ⇌ CO₂ + H₂ ===")
    println(rpad("T [K]", 10), rpad("ΔrG° [kJ/mol]", 18),
            rpad("ΔrH° [kJ/mol]", 18), rpad("K", 14), "Favors")
    println("—"^68)

    for T in [300, 500, 800, 1000, 1200, 1500]
        ΔrG, ΔrH, ΔrS = reaction_gibbs_free_energy(calc, reactants, products, T)
        K = equilibrium_constant(calc, reactants, products, T)
        favors = K > 1 ? "→ products" : K < 1 ? "← reactants" : "equilibrium"
        @printf("%-10.0f %+14.1f kJ/mol  %+14.1f kJ/mol  %10.3e  %s\n",
            T, ΔrG / 1000.0, ΔrH / 1000.0, K, favors)
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000007
md"""
### Interpretation

- The reaction is **exothermic** ($\Delta_r H^\circ < 0$)
- At low temperatures, $K > 1$ — favors products (CO₂ + H₂)
- At high temperatures, $K < 1$ — favors reactants (CO + H₂O)
- This follows **Le Chatelier's Principle**: increasing $T$ shifts equilibrium
  toward the endothermic direction (reactants)
"""

# ╔═╡ 08000000-0000-0000-0000-000000000008
md"""
## 3. Van't Hoff equation verification
"""

# ╔═╡ 08000000-0000-0000-0000-000000000009
Calculator() do calc
    reactants = [("CO", 1), ("H2O", 1)]
    products  = [("CO2", 1), ("H2", 1)]

    T1, T2 = 500.0, 1000.0
    K1 = equilibrium_constant(calc, reactants, products, T1)
    K2 = equilibrium_constant(calc, reactants, products, T2)
    _, ΔrH1, _ = reaction_gibbs_free_energy(calc, reactants, products, T1)
    _, ΔrH2, _ = reaction_gibbs_free_energy(calc, reactants, products, T2)
    ΔrH_avg = (ΔrH1 + ΔrH2) / 2.0
    K2_pred = K1 * exp(-ΔrH_avg / Glenn.R_UNIVERSAL * (1/T2 - 1/T1))

    println("=== Van't Hoff Verification ===")
    @printf("K(%.0f K) = %.3e\n", T1, K1)
    @printf("K(%.0f K) = %.3e (exact)\n", T2, K2)
    @printf("K(%.0f K) = %.3e (van't Hoff)\n", T2, K2_pred)
end

# ╔═╡ 08000000-0000-0000-0000-000000000010
md"""
## 4. CO₂ dissociation at high temperatures

$$\text{CO}_2 \rightleftharpoons \text{CO} + \tfrac{1}{2}\text{O}_2$$
"""

# ╔═╡ 08000000-0000-0000-0000-000000000011
Calculator() do calc
    reactants = [("CO2", 1)]
    products  = [("CO", 1), ("O2", 0.5)]

    println("=== CO₂ Dissociation ===")
    println(rpad("T [K]", 10), rpad("ΔrG° [kJ/mol]", 18), rpad("K", 14), "Status")
    println("—"^52)

    for T in [1000, 1500, 2000, 2500, 3000, 3500]
        ΔrG, ΔrH, _ = reaction_gibbs_free_energy(calc, reactants, products, T)
        K = equilibrium_constant(calc, reactants, products, T)
        status = K > 0.1 ? "significant dissociation" :
                 K > 0.001 ? "moderate dissociation" : "CO₂ stable"
        @printf("%-10.0f %+14.1f kJ/mol  %10.3e  %s\n",
            T, ΔrG / 1000.0, K, status)
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000012
md"""
## Summary

In this notebook you:

- Computed $\Delta_r G^\circ(T)$ and $K(T)$ from $H^\circ$ and $S^\circ$
- Analyzed the water-gas shift reaction as a function of temperature
- Verified the van't Hoff equation
- Explored CO₂ dissociation at high temperatures

In the [next notebook](09_brayton_cycle.jl) we apply these concepts to the
**Brayton gas-turbine cycle**.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 08000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═08000000-0000-0000-0000-000000000001
# ╠═08000000-0000-0000-0000-000000000002
# ╠═08000000-0000-0000-0000-000000000003
# ╠═08000000-0000-0000-0000-000000000004
# ╠═08000000-0000-0000-0000-000000000005
# ╠═08000000-0000-0000-0000-000000000006
# ╠═08000000-0000-0000-0000-000000000007
# ╠═08000000-0000-0000-0000-000000000008
# ╠═08000000-0000-0000-0000-000000000009
# ╠═08000000-0000-0000-0000-000000000010
# ╠═08000000-0000-0000-0000-000000000011
# ╠═08000000-0000-0000-0000-000000000012
# ╠═08000000-0000-0000-0000-000000000013
