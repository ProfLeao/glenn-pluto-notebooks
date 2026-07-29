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
# 06 — Temperatura de Chama Adiabática

A **temperatura de chama adiabática** $T_{ad}$ é a temperatura máxima atingida
quando um combustível queima em condições adiabáticas (sem troca de calor com
o ambiente) a pressão constante.

O balanço de energia é:

$$H_{\text{reagentes}}(T_0) = H_{\text{produtos}}(T_{ad})$$

$$\sum_r n_r H_r^\circ(T_0) = \sum_p n_p H_p^\circ(T_{ad})$$

Este caderno resolve essa equação para vários combustíveis, explorando o
efeito da **razão de equivalência**, **pré-aquecimento** e **dissociação**.
"""

# ╔═╡ 06000000-0000-0000-0000-000000000003
md"""
## 1. Função para calcular $T_{ad}$
"""

# ╔═╡ 06000000-0000-0000-0000-000000000004
begin
    """
        adiabatic_flame_temperature(calc, fuel, T_initial, phi)

    Calcula a temperatura de chama adiabática para combustão completa.

    - `fuel`: nome da espécie do combustível
    - `T_initial`: temperatura inicial dos reagentes [K]
    - `phi`: razão de equivalência (1.0 = estequiométrico)

    Para hidrocarbonetos CₓHᵧ, assume combustão completa:
        CₓHᵧ + (x + y/4)/φ O₂ → x CO₂ + (y/2) H₂O + (x + y/4)(1/φ - 1) O₂

    Retorna T_ad em Kelvin.
    """
    function adiabatic_flame_temperature(calc, fuel, T_initial = 300.0, phi = 1.0)
        # Obter dados do combustível
        sp = only(get_available_species(calc, fuel, exact_match = true))
        formula = something(sp.formula, "")

        # Contar átomos na fórmula (simplificado: assume CxHy)
        # Para uma implementação completa, use um parser de fórmulas
        nC, nH = 1, 4  # default CH4
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

        # Reagentes a T_initial
        h_fuel = calculate_properties(calc, sp.id, T_initial).h_relative
        o2 = only(get_available_species(calc, "O2", exact_match = true))
        h_o2 = calculate_properties(calc, o2.id, T_initial).h_relative
        H_react = h_fuel + nO2_actual * h_o2

        # Se phi > 1 (rico), há excesso de O2 nos produtos
        nO2_excess = max(0.0, nO2_actual - nO2_stoich)

        # Produtos: CO2, H2O(g), excesso O2
        co2 = only(get_available_species(calc, "CO2", exact_match = true))
        h2o = only(get_available_species(calc, "H2O", exact_match = true))

        function H_products(T)
            h = 0.0
            h += nC * calculate_properties(calc, co2.id, T).h_relative
            h += (nH / 2) * calculate_properties(calc, h2o.id, T).h_relative
            if nO2_excess > 0
                h += nO2_excess * calculate_properties(calc, o2.id, T).h_relative
            end
            return h
        end

        # Resolver H_react = H_products(T_ad)
        f(T) = H_products(T) - H_react
        T_ad = find_zero(f, (300.0, 6000.0))

        return T_ad
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000005
md"""
## 2. Temperatura de chama para vários combustíveis
"""

# ╔═╡ 06000000-0000-0000-0000-000000000006
md"""
### Combustão estequiométrica ($\phi = 1.0$)
"""

# ╔═╡ 06000000-0000-0000-0000-000000000007
Calculator() do calc
    fuels = ["CH4", "C2H5OH", "C3H8", "H2"]

    println("=== Temperaturas de Chama Adiabática (φ=1, T₀=300 K) ===")
    println(rpad("Combustível", 16), rpad("T_ad [K]", 14), "T_ad [°C]")
    println("—"^44)

    for fuel in fuels
        try
            T_ad = adiabatic_flame_temperature(calc, fuel, 300.0, 1.0)
            @printf("%-16s %10.0f K    %8.0f °C\n",
                fuel, T_ad, T_ad - 273.15)
        catch e
            @printf("%-16s erro: %s\n", fuel, e)
        end
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000008
md"""
> **Nota:** Os valores reais de $T_{ad}$ são menores devido à dissociação
> (CO₂ → CO + ½ O₂, H₂O → H₂ + ½ O₂) que consome energia. Este cálculo é
> uma primeira aproximação (combustão completa).
"""

# ╔═╡ 06000000-0000-0000-0000-000000000009
md"""
## 3. Efeito da razão de equivalência ($\phi$)
"""

# ╔═╡ 06000000-0000-0000-0000-000000000010
Calculator() do calc
    fuel = "CH4"
    phis = [0.5, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.5]

    println("=== Efeito de φ — $fuel (T₀=300 K) ===")
    println(rpad("φ", 8), rpad("T_ad [K]", 14), "Observação")
    println("—"^40)

    for phi in phis
        try
            T_ad = adiabatic_flame_temperature(calc, fuel, 300.0, phi)
            obs = if phi < 1.0
                "pobre (excesso O₂)"
            elseif phi > 1.0
                "rico (falta O₂)"
            else
                "estequiométrico"
            end
            @printf("%-8.1f %10.0f K    %s\n", phi, T_ad, obs)
        catch e
            @printf("%-8.1f erro\n", phi)
        end
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000011
md"""
## 4. Efeito do pré-aquecimento
"""

# ╔═╡ 06000000-0000-0000-0000-000000000012
Calculator() do calc
    fuel = "CH4"
    T_initials = [300, 400, 500, 600, 800]

    println("=== Efeito do Pré-aquecimento — $fuel (φ=1.0) ===")
    println(rpad("T₀ [K]", 10), rpad("T_ad [K]", 14), rpad("ΔT_ad [K]", 14))
    println("—"^42)

    T_ad_base = adiabatic_flame_temperature(calc, fuel, 300.0, 1.0)
    for T0 in T_initials
        T_ad = adiabatic_flame_temperature(calc, fuel, Float64(T0), 1.0)
        @printf("%-10.0f %10.0f K    %+10.0f K\n",
            T0, T_ad, T_ad - T_ad_base)
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000013
md"""
## Resumo

Neste caderno você:

- Implementou o balanço de energia para $T_{ad}$ usando `find_zero`
- Calculou $T_{ad}$ para CH₄, C₂H₅OH, C₃H₈ e H₂
- Explorou o efeito da razão de equivalência $\phi$ e do pré-aquecimento
- Observou que a $T_{ad}$ máxima ocorre em $\phi = 1.0$

No [próximo caderno](07_comparacao_combustiveis.jl) vamos comparar
**sistematicamente combustíveis e biocombustíveis**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 06000000-0000-0000-0000-000000000014
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
# ╠═06000000-0000-0000-0000-000000000013
# ╠═06000000-0000-0000-0000-000000000014
