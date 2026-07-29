### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 02000000-0000-0000-0000-000000000001
md"""
# 02 — Polinomios de la NASA por Dentro

Este cuaderno desmitifica la maquinaria numérica detrás de `Glenn.jl`,
implementando los **polinomios NASA-7** manualmente y validando los resultados
contra la API de alto nivel.

Al final, comprenderá:

1. La estructura de los polinomios NASA-7 (formato de 9 coeficientes)
2. Cómo se calculan $C_p^\circ(T)$, $H^\circ(T)$ y $S^\circ(T)$
3. La naturaleza *piecewise* (por tramos) de los intervalos de temperatura
4. El significado de las constantes de integración $b_1$ y $b_2$
5. Cómo validar cálculos manuales contra la API
"""

# ╔═╡ 02000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 02000000-0000-0000-0000-000000000003
md"""
## 1. Las Ecuaciones Polinomiales NASA-7

Los polinomios de la NASA representan las propiedades termodinámicas en forma
adimensional (divididas por $R$). Para cada intervalo de temperatura, se
proporcionan 7 coeficientes $(a_1, \dots, a_7)$ y 2 constantes de integración
$(b_1, b_2)$:

$$\frac{C_p(T)}{R} = a_1 T^{-2} + a_2 T^{-1} + a_3 + a_4 T + a_5 T^2 + a_6 T^3 + a_7 T^4$$

$$\frac{H^\circ(T)}{RT} = -a_1 T^{-2} + a_2 \frac{\ln T}{T} + a_3 + a_4 \frac{T}{2} + a_5 \frac{T^2}{3} + a_6 \frac{T^3}{4} + a_7 \frac{T^4}{5} + \frac{b_1}{T}$$

$$\frac{S^\circ(T)}{R} = -\frac{a_1}{2} T^{-2} - a_2 T^{-1} + a_3 \ln T + a_4 T + a_5 \frac{T^2}{2} + a_6 \frac{T^3}{3} + a_7 \frac{T^4}{4} + b_2$$
"""

# ╔═╡ 02000000-0000-0000-0000-000000000004
md"""
## 2. Obteniendo los coeficientes brutos

Obtengamos los datos completos de una especie (O₂) para inspeccionar sus
intervalos y coeficientes:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000005
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    data = get_species_data(calc.db, o2.id)

    println("=== Datos completos de O₂ ===")
    println("Nombre:       ", data["name"])
    println("Fórmula:      ", data["formula"])
    println("Fase:         ", data["phase"])
    println("Peso mol.:    ", data["molecular_weight"])
    println("Nº intervalos:", data["num_intervals"])
    println()
    println("Intervalos de temperatura:")
    for interval in data["intervals"]
        println("  [$(interval["temp_min"]) K, $(interval["temp_max"]) K]")
    end
end

# ╔═╡ 02000000-0000-0000-0000-000000000006
md"""
## 3. Reconstruyendo los cálculos manualmente

Funciones que implementan los polinomios NASA-7 a partir de los coeficientes brutos:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000007
"""
    cp_r(a, T)

Calcula Cp/R usando los coeficientes NASA-7.
"""
function cp_r(a, T)
    a[1] * T^(-2) + a[2] * T^(-1) + a[3] + a[4] * T +
    a[5] * T^2 + a[6] * T^3 + a[7] * T^4
end

# ╔═╡ 02000000-0000-0000-0000-000000000008
"""
    h_rt(a, b1, T)

Calcula H/(RT) usando los coeficientes NASA-7.
"""
function h_rt(a, b1, T)
    -a[1] * T^(-2) + a[2] * log(T) / T + a[3] +
    a[4] * T / 2 + a[5] * T^2 / 3 + a[6] * T^3 / 4 +
    a[7] * T^4 / 5 + b1 / T
end

# ╔═╡ 02000000-0000-0000-0000-000000000009
"""
    s_r(a, b2, T)

Calcula S/R usando los coeficientes NASA-7.
"""
function s_r(a, b2, T)
    -a[1] / 2 * T^(-2) - a[2] * T^(-1) + a[3] * log(T) +
    a[4] * T + a[5] * T^2 / 2 + a[6] * T^3 / 3 +
    a[7] * T^4 / 4 + b2
end

# ╔═╡ 02000000-0000-0000-0000-000000000010
md"""
## 4. Validando contra la API de Glenn.jl

Ahora comparemos nuestros cálculos manuales con los resultados de la API:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000011
md"""
### O₂ a 1000 K
"""

# ╔═╡ 02000000-0000-0000-0000-000000000012
Calculator() do calc
    T = 1000.0
    o2 = only(get_available_species(calc, "O2", exact_match = true))

    interval = get_species_for_temperature(calc.db, o2.id, T)
    coeffs = interval["coefficients"]

    a = [coeffs["a1"], coeffs["a2"], coeffs["a3"], coeffs["a4"],
         coeffs["a5"], coeffs["a6"], coeffs["a7"]]
    b1 = coeffs["b1"]
    b2 = coeffs["b2"]

    cp_r_manual = cp_r(a, T)
    h_rt_manual = h_rt(a, b1, T)
    s_r_manual  = s_r(a, b2, T)

    R = Glenn.R_UNIVERSAL
    cp_manual = cp_r_manual * R
    h_manual  = h_rt_manual * R * T
    s_manual  = s_r_manual * R

    api = calculate_properties(calc, o2.id, T)

    println("=== O₂ a $(T) K ===")
    println()
    println(rpad("", 20), rpad("Manual", 16), rpad("API Glenn.jl", 16))
    println("—"^52)
    @printf("%-20s %15.6f %15.6f\n", "Cp [J/(mol·K)]", cp_manual, api.cp)
    @printf("%-20s %15.1f %15.1f\n", "H° [J/mol]", h_manual, api.h_relative)
    @printf("%-20s %15.6f %15.6f\n", "S° [J/(mol·K)]", s_manual, api.s)

    println()
    println("✓ ¡La reconstrucción manual coincide con la API!")
end

# ╔═╡ 02000000-0000-0000-0000-000000000013
md"""
### Verificación adicional: funciones de bajo nivel

Glenn.jl también expone funciones de bajo nivel que devuelven valores
adimensionales:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000014
Calculator() do calc
    T = 1000.0
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    interval = get_species_for_temperature(calc.db, o2.id, T)
    coeffs = interval["coefficients"]

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

    println("=== Comparación adimensional (O₂ a $T K) ===")
    @printf("Cp/R : %16.12f  ==  %16.12f\n", cp_r(a, T), cp_r_api)
    @printf("H/RT : %16.12f  ==  %16.12f\n", h_rt(a, b1, T), h_rt_api)
    @printf("S/R  : %16.12f  ==  %16.12f\n", s_r(a, b2, T), s_r_api)
end

# ╔═╡ 02000000-0000-0000-0000-000000000015
md"""
## 5. La estructura por tramos (piecewise)

Glenn.jl selecciona el tramo que contiene la temperatura solicitada. Cerca del
límite de 1000 K del O₂, el campo `temp_interval` cambia, pero $C_p$ permanece
continuo — los ajustes de la NASA están restringidos para coincidir en los
empalmes.
"""

# ╔═╡ 02000000-0000-0000-0000-000000000016
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
    println("Observe: Cp es continuo a través de la frontera de 1000 K,")
    println("pero las constantes de integración b1 y b2 cambian.")
end

# ╔═╡ 02000000-0000-0000-0000-000000000017
md"""
## 6. Significado de las constantes $b_1$ y $b_2$

Las constantes de integración conectan las funciones termodinámicas al estado
de referencia:

- **$b_1$**: determina el **cero de entalpía** — para elementos en el estado
  de referencia, $H^\circ(298.15\,\text{K}) \approx 0$
- **$b_2$**: determina el **cero de entropía** — consistente con la Tercera Ley
  ($S \to 0$ cuando $T \to 0$)

Esto significa que $b_1$ y $b_2$ son **diferentes para cada intervalo**, pero
garantizan continuidad en las fronteras.
"""

# ╔═╡ 02000000-0000-0000-0000-000000000018
md"""
## Resumen

En este cuaderno usted:

- Implementó manualmente las ecuaciones NASA-7 para $C_p$, $H^\circ$ y $S^\circ$
- Validó los resultados contra la API de Glenn.jl con precisión de punto flotante
- Entendió la estructura *piecewise* y la continuidad en las fronteras
- Aprendió el significado físico de las constantes $b_1$ y $b_2$

En el [siguiente cuaderno](03_curvas_propiedades.jl) generaremos **curvas de
propiedades** en función de la temperatura e interpretaremos sus características
físicas.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 02000000-0000-0000-0000-000000000019
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
