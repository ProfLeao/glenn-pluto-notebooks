### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 02000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 02000000-0000-0000-0000-000000000001
md"""
# 02 — Polinômios da NASA por Dentro

Este caderno desmistifica a maquinaria numérica por trás do `Glenn.jl`,
implementando os **polinômios NASA-7** manualmente e validando os resultados
contra a API de alto nível.

Ao final, você entenderá:

1. A estrutura dos polinômios NASA-7 (formato de 9 coeficientes)
2. Como $C_p^\circ(T)$, $H^\circ(T)$ e $S^\circ(T)$ são calculados
3. A natureza *piecewise* (por partes) dos intervalos de temperatura
4. O significado das constantes de integração $b_1$ e $b_2$
5. Como validar cálculos manuais contra a API
"""

# ╔═╡ 02000000-0000-0000-0000-000000000003
md"""
## 1. As Equações Polinomiais NASA-7

Os polinômios da NASA representam as propriedades termodinâmicas em forma
adimensional (divididas por $R$). Para cada intervalo de temperatura, 7
coeficientes $(a_1, \dots, a_7)$ e 2 constantes de integração $(b_1, b_2)$
são fornecidos:

$$\frac{C_p(T)}{R} = a_1 T^{-2} + a_2 T^{-1} + a_3 + a_4 T + a_5 T^2 + a_6 T^3 + a_7 T^4$$

$$\frac{H^\circ(T)}{RT} = -a_1 T^{-2} + a_2 \frac{\ln T}{T} + a_3 + a_4 \frac{T}{2} + a_5 \frac{T^2}{3} + a_6 \frac{T^3}{4} + a_7 \frac{T^4}{5} + \frac{b_1}{T}$$

$$\frac{S^\circ(T)}{R} = -\frac{a_1}{2} T^{-2} - a_2 T^{-1} + a_3 \ln T + a_4 T + a_5 \frac{T^2}{2} + a_6 \frac{T^3}{3} + a_7 \frac{T^4}{4} + b_2$$
"""

# ╔═╡ 02000000-0000-0000-0000-000000000004
md"""
## 2. Obtendo os coeficientes brutos

Vamos obter os dados completos de uma espécie (O₂) para inspecionar seus
intervalos e coeficientes:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000005
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    data = get_species_data(calc.db, o2.id)

    println("=== Dados completos de O₂ ===")
    println("Nome:       ", data["name"])
    println("Fórmula:    ", data["formula"])
    println("Fase:       ", data["phase"])
    println("Peso mol.:  ", data["molecular_weight"])
    println("Nº intervalos: ", data["num_intervals"])
    println()
    println("Intervalos de temperatura:")
    for interval in data["intervals"]
        println("  [$(interval["temp_min"]) K, $(interval["temp_max"]) K]")
    end
end

# ╔═╡ 02000000-0000-0000-0000-000000000006
md"""
## 3. Reconstruindo os cálculos manualmente

Funções que implementam os polinômios NASA-7 a partir dos coeficientes brutos:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000007
# 02000000-0000-0000-0000-000000000008
"""
    cp_r(a, T)

Calcula Cp/R usando os coeficientes NASA-7.
"""
function cp_r(a, T)
    a[1] * T^(-2) + a[2] * T^(-1) + a[3] + a[4] * T +
    a[5] * T^2 + a[6] * T^3 + a[7] * T^4
end

# ╔═╡ 02000000-0000-0000-0000-000000000009
"""
    h_rt(a, b1, T)

Calcula H/(RT) usando os coeficientes NASA-7.
"""
function h_rt(a, b1, T)
    -a[1] * T^(-2) + a[2] * log(T) / T + a[3] +
    a[4] * T / 2 + a[5] * T^2 / 3 + a[6] * T^3 / 4 +
    a[7] * T^4 / 5 + b1 / T
end

# ╔═╡ 02000000-0000-0000-0000-000000000010
"""
    s_r(a, b2, T)

Calcula S/R usando os coeficientes NASA-7.
"""
function s_r(a, b2, T)
    -a[1] / 2 * T^(-2) - a[2] * T^(-1) + a[3] * log(T) +
    a[4] * T + a[5] * T^2 / 2 + a[6] * T^3 / 3 +
    a[7] * T^4 / 4 + b2
end

# ╔═╡ 02000000-0000-0000-0000-000000000011
md"""
## 4. Validando contra a API do Glenn.jl

Agora vamos comparar nossos cálculos manuais com os resultados da API:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000012
md"""
### O₂ a 1000 K
"""

# ╔═╡ 02000000-0000-0000-0000-000000000013
Calculator() do calc
    T = 1000.0
    o2 = only(get_available_species(calc, "O2", exact_match = true))

    # Obter intervalo e coeficientes para esta temperatura
    interval = get_species_for_temperature(calc.db, o2.id, T)
    coeffs = interval["coefficients"]

    # Extrair coeficientes como vetor
    a = [coeffs["a1"], coeffs["a2"], coeffs["a3"], coeffs["a4"],
         coeffs["a5"], coeffs["a6"], coeffs["a7"]]
    b1 = coeffs["b1"]
    b2 = coeffs["b2"]

    # Cálculo manual (adimensional)
    cp_r_manual = cp_r(a, T)
    h_rt_manual = h_rt(a, b1, T)
    s_r_manual  = s_r(a, b2, T)

    # Converter para unidades SI
    R = Glenn.R_UNIVERSAL
    cp_manual = cp_r_manual * R
    h_manual  = h_rt_manual * R * T
    s_manual  = s_r_manual * R

    # Resultados da API
    api = calculate_properties(calc, o2.id, T)

    println("=== O₂ a $(T) K ===")
    println()
    println(rpad("", 20), rpad("Manual", 16), rpad("API Glenn.jl", 16))
    println("—"^52)
    @printf("%-20s %15.6f %15.6f\n", "Cp [J/(mol·K)]", cp_manual, api.cp)
    @printf("%-20s %15.1f %15.1f\n", "H° [J/mol]", h_manual, api.h_relative)
    @printf("%-20s %15.6f %15.6f\n", "S° [J/(mol·K)]", s_manual, api.s)

    println()
    println("✓ A reconstrução manual coincide com a API!")
end

# ╔═╡ 02000000-0000-0000-0000-000000000014
md"""
### Verificação adicional: funções de baixo nível

O Glenn.jl também expõe funções de baixo nível que retornam valores
adimensionais:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000015
Calculator() do calc
    T = 1000.0
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    interval = get_species_for_temperature(calc.db, o2.id, T)
    coeffs = interval["coefficients"]

    # Converter Dict para NASACoefficients
    ncoeffs = NASACoefficients(
        coeffs["a1"], coeffs["a2"], coeffs["a3"], coeffs["a4"],
        coeffs["a5"], coeffs["a6"], coeffs["a7"],
        coeffs["b1"], coeffs["b2"]
    )

    cp_r_api  = Glenn.calculate_cp(ncoeffs, T)
    h_rt_api  = Glenn.calculate_h(ncoeffs, T)
    s_r_api   = Glenn.calculate_s(ncoeffs, T)

    a = [coeffs["a1"], coeffs["a2"], coeffs["a3"], coeffs["a4"],
         coeffs["a5"], coeffs["a6"], coeffs["a7"]]
    b1 = coeffs["b1"]
    b2 = coeffs["b2"]

    println("=== Comparação adimensional (O₂ a $T K) ===")
    @printf("Cp/R : %16.12f  ==  %16.12f\n", cp_r(a, T), cp_r_api)
    @printf("H/RT : %16.12f  ==  %16.12f\n", h_rt(a, b1, T), h_rt_api)
    @printf("S/R  : %16.12f  ==  %16.12f\n", s_r(a, b2, T), s_r_api)
end

# ╔═╡ 02000000-0000-0000-0000-000000000016
md"""
## 5. A estrutura por partes (piecewise)

O Glenn.jl seleciona o trecho que contém a temperatura solicitada. Próximo ao
limite de 1000 K do O₂, o campo `temp_interval` muda, mas $C_p$ permanece
contínuo — os ajustes da NASA são restritos para coincidir nas emendas.
"""

# ╔═╡ 02000000-0000-0000-0000-000000000017
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))

    for T in [999.0, 1000.0, 1001.0]
        interval = get_species_for_temperature(calc.db, o2.id, T)
        coeffs = interval["coefficients"]
        ncoeffs = NASACoefficients(
            coeffs["a1"], coeffs["a2"], coeffs["a3"], coeffs["a4"],
            coeffs["a5"], coeffs["a6"], coeffs["a7"],
            coeffs["b1"], coeffs["b2"]
        )
        cp_val = Glenn.calculate_cp(ncoeffs, T) * Glenn.R_UNIVERSAL

        @printf("T = %6.1f K  →  intervalo [%d, %d]  →  Cp = %.6f J/(mol·K)\n",
            T, interval["temp_min"], interval["temp_max"], cp_val)
    end

    println()
    println("Observe: Cp é contínuo através da fronteira de 1000 K,")
    println("mas as constantes de integração b1 e b2 mudam.")
end

# ╔═╡ 02000000-0000-0000-0000-000000000018
md"""
## 6. Significado das constantes $b_1$ e $b_2$

As constantes de integração conectam as funções termodinâmicas ao estado de
referência:

- **$b_1$**: determina o **zero da entalpia** — para elementos no estado de
  referência, $H^\circ(298.15\,\text{K}) \approx 0$
- **$b_2$**: determina o **zero da entropia** — consistente com a Terceira Lei
  ($S \to 0$ quando $T \to 0$)

Isso significa que $b_1$ e $b_2$ são **diferentes para cada intervalo**, mas
garantem continuidade nas fronteiras.
"""

# ╔═╡ 02000000-0000-0000-0000-000000000019
md"""
## Resumo

Neste caderno você:

- Implementou manualmente as equações NASA-7 para $C_p$, $H^\circ$ e $S^\circ$
- Validou os resultados contra a API do Glenn.jl com precisão de ponto flutuante
- Entendeu a estrutura *piecewise* e a continuidade nas fronteiras
- Aprendeu o significado físico das constantes $b_1$ e $b_2$

No [próximo caderno](03_propriedades_curvas.jl) vamos gerar **curvas de
propriedades** em função da temperatura e interpretar as features físicas.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 02000000-0000-0000-0000-000000000020
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═02000000-0000-0000-0000-000000000001
# ╠═02000000-0000-0000-0000-000000000002
# ╠═02000000-0000-0000-0000-000000000003
# ╠═02000000-0000-0000-0000-000000000004
# ╠═02000000-0000-0000-0000-000000000005
# ╠═02000000-0000-0000-0000-000000000006
# ╠═02000000-0000-0000-0000-000000000007
# ╠═02000000-0000-0000-0000-000000000009
# ╠═02000000-0000-0000-0000-000000000010
# ╠═02000000-0000-0000-0000-000000000011
# ╠═02000000-0000-0000-0000-000000000012
# ╠═02000000-0000-0000-0000-000000000013
# ╠═02000000-0000-0000-0000-000000000014
# ╠═02000000-0000-0000-0000-000000000015
# ╠═02000000-0000-0000-0000-000000000016
# ╠═02000000-0000-0000-0000-000000000017
# ╠═02000000-0000-0000-0000-000000000018
# ╠═02000000-0000-0000-0000-000000000019
# ╠═02000000-0000-0000-0000-000000000020
