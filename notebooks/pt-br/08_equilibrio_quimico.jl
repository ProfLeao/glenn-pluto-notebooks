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
# 08 — Equilíbrio Químico e Energia Livre de Gibbs

Este caderno explora o **equilíbrio químico** usando a **energia livre de
Gibbs** padrão $\Delta_r G^\circ(T)$ e a **constante de equilíbrio** $K(T)$.

A relação fundamental é:

$$\Delta_r G^\circ(T) = \Delta_r H^\circ(T) - T \cdot \Delta_r S^\circ(T)$$

$$K(T) = \exp\left(-\frac{\Delta_r G^\circ(T)}{RT}\right)$$

Tópicos abordados:

1. Cálculo de $\Delta_r G^\circ(T)$ e $K(T)$
2. **Water-gas shift reaction** — dependência com $T$
3. Equação de **van't Hoff**
4. Dissociação a altas temperaturas
"""

# ╔═╡ 08000000-0000-0000-0000-000000000003
md"""
## 1. Funções para $\Delta_r G^\circ$ e $K$
"""

# ╔═╡ 08000000-0000-0000-0000-000000000004
begin
    """
        reaction_gibbs_free_energy(calc, reactants, products, T)

    Calcula ΔrG°(T) = ΔrH°(T) - T·ΔrS°(T).
    """
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

    """
        equilibrium_constant(calc, reactants, products, T)

    Calcula K(T) = exp(-ΔrG°(T) / (RT)).
    """
    function equilibrium_constant(calc, reactants, products, T)
        ΔrG, _, _ = reaction_gibbs_free_energy(calc, reactants, products, T)
        return exp(-ΔrG / (Glenn.R_UNIVERSAL * T))
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000005
md"""
## 2. Water-Gas Shift Reaction

$$\text{CO} + \text{H}_2\text{O} \rightleftharpoons \text{CO}_2 + \text{H}_2$$

Esta é uma das reações mais importantes em processos de gaseificação e reforma.
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
        favorece = if K > 1
            "→ produtos"
        elseif K < 1
            "← reagentes"
        else
            "equilíbrio"
        end
        @printf("%-10.0f %+14.1f kJ/mol  %+14.1f kJ/mol  %10.3e  %s\n",
            T, ΔrG / 1000.0, ΔrH / 1000.0, K, favorece)
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000007
md"""
### Interpretação

- A reação é **exotérmica** ($\Delta_r H^\circ < 0$)
- A temperaturas baixas, $K > 1$ — favorece produtos (CO₂ + H₂)
- A temperaturas altas, $K < 1$ — favorece reagentes (CO + H₂O)
- Isso segue o **Princípio de Le Chatelier**: aumento de $T$ desloca o
  equilíbrio no sentido endotérmico (reagentes)
"""

# ╔═╡ 08000000-0000-0000-0000-000000000008
md"""
## 3. Equação de van't Hoff

A dependência de $K$ com $T$ é descrita pela equação de van't Hoff:

$$\frac{d \ln K}{dT} = \frac{\Delta_r H^\circ}{RT^2}$$

Para $\Delta_r H^\circ$ aproximadamente constante:

$$\ln\left(\frac{K_2}{K_1}\right) = -\frac{\Delta_r H^\circ}{R}
\left(\frac{1}{T_2} - \frac{1}{T_1}\right)$$
"""

# ╔═╡ 08000000-0000-0000-0000-000000000009
Calculator() do calc
    reactants = [("CO", 1), ("H2O", 1)]
    products  = [("CO2", 1), ("H2", 1)]

    T1, T2 = 500.0, 1000.0
    K1 = equilibrium_constant(calc, reactants, products, T1)
    K2 = equilibrium_constant(calc, reactants, products, T2)

    # Aproximação: ΔrH° constante (média)
    _, ΔrH1, _ = reaction_gibbs_free_energy(calc, reactants, products, T1)
    _, ΔrH2, _ = reaction_gibbs_free_energy(calc, reactants, products, T2)
    ΔrH_avg = (ΔrH1 + ΔrH2) / 2.0

    K2_pred = K1 * exp(-ΔrH_avg / Glenn.R_UNIVERSAL * (1/T2 - 1/T1))

    println("=== Verificação de van't Hoff ===")
    @printf("K(%.0f K) = %.3e\n", T1, K1)
    @printf("K(%.0f K) = %.3e (exato)\n", T2, K2)
    @printf("K(%.0f K) = %.3e (van't Hoff)\n", T2, K2_pred)
    @printf("Erro relativo: %.3f %%\n", abs(K2 - K2_pred) / K2 * 100)
end

# ╔═╡ 08000000-0000-0000-0000-000000000010
md"""
## 4. Dissociação a altas temperaturas

A altas temperaturas, moléculas estáveis se dissociam. Vamos examinar:

$$\text{CO}_2 \rightleftharpoons \text{CO} + \tfrac{1}{2}\text{O}_2$$
"""

# ╔═╡ 08000000-0000-0000-0000-000000000011
Calculator() do calc
    reactants = [("CO2", 1)]
    products  = [("CO", 1), ("O2", 0.5)]

    println("=== Dissociação: CO₂ ⇌ CO + ½ O₂ ===")
    println(rpad("T [K]", 10), rpad("ΔrG° [kJ/mol]", 18),
            rpad("ΔrH° [kJ/mol]", 18), rpad("K", 14), "Estado")
    println("—"^68)

    for T in [1000, 1500, 2000, 2500, 3000, 3500]
        ΔrG, ΔrH, _ = reaction_gibbs_free_energy(calc, reactants, products, T)
        K = equilibrium_constant(calc, reactants, products, T)
        estado = if K > 0.1
            "dissociação significativa"
        elseif K > 0.001
            "dissociação moderada"
        else
            "CO₂ estável"
        end
        @printf("%-10.0f %+14.1f kJ/mol  %+14.1f kJ/mol  %10.3e  %s\n",
            T, ΔrG / 1000.0, ΔrH / 1000.0, K, estado)
    end
end

# ╔═╡ 08000000-0000-0000-0000-000000000012
md"""
### Implicações

- A dissociação do CO₂ se torna significativa acima de ~2500 K
- Isso afeta a composição dos gases de combustão em câmaras de alta temperatura
- Explica por que $T_{ad}$ real é menor que a calculada sem dissociação (a
  dissociação consome energia)
"""

# ╔═╡ 08000000-0000-0000-0000-000000000013
md"""
## Resumo

Neste caderno você:

- Calculou $\Delta_r G^\circ(T)$ e $K(T)$ a partir de $H^\circ$ e $S^\circ$
- Analisou a reação water-gas shift em função da temperatura
- Verificou a equação de van't Hoff
- Explorou a dissociação do CO₂ a altas temperaturas

No [próximo caderno](09_ciclo_brayton.jl) vamos aplicar esses conceitos ao
**ciclo Brayton** de turbinas a gás.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 08000000-0000-0000-0000-000000000014
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
# ╠═08000000-0000-0000-0000-000000000014
