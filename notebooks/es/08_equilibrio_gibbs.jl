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
# 08 — Equilibrio Químico y Energía Libre de Gibbs

Este cuaderno explora el **equilibrio químico** usando la **energía libre de
Gibbs** estándar $\Delta_r G^\circ(T)$ y la **constante de equilibrio** $K(T)$.

La relación fundamental es:

$$\Delta_r G^\circ(T) = \Delta_r H^\circ(T) - T \cdot \Delta_r S^\circ(T)$$

$$K(T) = \exp\left(-\frac{\Delta_r G^\circ(T)}{RT}\right)$$

Temas abordados:

1. Cálculo de $\Delta_r G^\circ(T)$ y $K(T)$
2. **Reacción water-gas shift** — dependencia con $T$
3. Ecuación de **van't Hoff**
4. Disociación a altas temperaturas
"""

# ╔═╡ 08000000-0000-0000-0000-000000000003
md"""
## 1. Energía libre de Gibbs y constante de equilibrio
"""

# ╔═╡ 08000000-0000-0000-0000-000000000004
begin
    function reaction_gibbs_free_energy(calc, reactants, products, T)
        function get_props(name)
            sp = only(get_available_species(calc, name, exact_match = true))
            return calculate_properties(calc, sp.id, T)
        end
        ΔrH = 0.0; ΔrS = 0.0
        for (name, nu) in products
            p = get_props(name); ΔrH += nu * p.h_relative; ΔrS += nu * p.s
        end
        for (name, nu) in reactants
            p = get_props(name); ΔrH -= nu * p.h_relative; ΔrS -= nu * p.s
        end
        return ΔrH - T * ΔrS, ΔrH, ΔrS
    end

    function equilibrium_constant(calc, reactants, products, T)
        ΔrG, _, _ = reaction_gibbs_free_energy(calc, reactants, products, T)
        return exp(-ΔrG / (Glenn.R_UNIVERSAL * T))
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000005
md"""
## 2. Reacción Water-Gas Shift

$$\text{CO} + \text{H}_2\text{O} \rightleftharpoons \text{CO}_2 + \text{H}_2$$
"""

# ╔═╡ 08000000-0000-0000-0000-000000000006
Calculator() do calc
    reactants = [("CO", 1), ("H2O", 1)]
    products  = [("CO2", 1), ("H2", 1)]

    println("=== Water-Gas Shift: CO + H₂O ⇌ CO₂ + H₂ ===")
    println(rpad("T [K]", 10), rpad("ΔrG° [kJ/mol]", 18),
            rpad("ΔrH° [kJ/mol]", 18), rpad("K", 14), "Favorece")
    println("—"^68)

    for T in [300, 500, 800, 1000, 1200, 1500]
        ΔrG, ΔrH, ΔrS = reaction_gibbs_free_energy(calc, reactants, products, T)
        K = equilibrium_constant(calc, reactants, products, T)
        favorece = K > 1 ? "→ productos" : K < 1 ? "← reactivos" : "equilibrio"
        @printf("%-10.0f %+14.1f kJ/mol  %+14.1f kJ/mol  %10.3e  %s\n",
            T, ΔrG / 1000.0, ΔrH / 1000.0, K, favorece)
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000007
md"""
### Interpretación

- La reacción es **exotérmica** ($\Delta_r H^\circ < 0$)
- A bajas temperaturas, $K > 1$ — favorece productos (CO₂ + H₂)
- A altas temperaturas, $K < 1$ — favorece reactivos (CO + H₂O)
- Esto sigue el **Principio de Le Chatelier**
"""

# ╔═╡ 08000000-0000-0000-0000-000000000008
md"""
## 3. Verificación de van't Hoff
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

    println("=== Verificación de van't Hoff ===")
    @printf("K(%.0f K) = %.3e\n", T1, K1)
    @printf("K(%.0f K) = %.3e (exacto)\n", T2, K2)
    @printf("K(%.0f K) = %.3e (van't Hoff)\n", T2, K2_pred)
end

# ╔═╡ 08000000-0000-0000-0000-000000000010
md"""
## 4. Disociación del CO₂ a altas temperaturas

$$\text{CO}_2 \rightleftharpoons \text{CO} + \tfrac{1}{2}\text{O}_2$$
"""

# ╔═╡ 08000000-0000-0000-0000-000000000011
Calculator() do calc
    reactants = [("CO2", 1)]
    products  = [("CO", 1), ("O2", 0.5)]

    println("=== Disociación del CO₂ ===")
    for T in [1000, 1500, 2000, 2500, 3000, 3500]
        ΔrG, ΔrH, _ = reaction_gibbs_free_energy(calc, reactants, products, T)
        K = equilibrium_constant(calc, reactants, products, T)
        status = K > 0.1 ? "disociación significativa" :
                 K > 0.001 ? "disociación moderada" : "CO₂ estable"
        @printf("T=%-5.0f K  ΔrG°=%+8.1f kJ/mol  K=%.2e  %s\n",
            T, ΔrG / 1000.0, K, status)
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000012
md"""
## Resumen

En este cuaderno usted:

- Calculó $\Delta_r G^\circ(T)$ y $K(T)$ a partir de $H^\circ$ y $S^\circ$
- Analizó la reacción water-gas shift en función de la temperatura
- Verificó la ecuación de van't Hoff
- Exploró la disociación del CO₂ a altas temperaturas

En el [siguiente cuaderno](09_ciclo_brayton.jl) aplicaremos estos conceptos al
**ciclo Brayton** de turbinas de gas.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
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
