### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 06000000-0000-0000-0000-000000000001
md"""
# 06 — Temperatura de Llama Adiabática

La **temperatura de llama adiabática** $T_{ad}$ es la temperatura máxima
alcanzada cuando un combustible arde en condiciones adiabáticas (sin
intercambio de calor con el entorno) a presión constante.

El balance de energía es:

$$H_{\text{reactivos}}(T_0) = H_{\text{productos}}(T_{ad})$$

Este cuaderno resuelve esta ecuación para varios combustibles, explorando el
efecto de la **razón de equivalencia**, **precalentamiento** y **disociación**.
"""

# ╔═╡ 06000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using Roots
end

# ╔═╡ 06000000-0000-0000-0000-000000000003
md"""
## 1. Función para calcular $T_{ad}$
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
## 2. Combustión estequiométrica ($\phi = 1.0$)
"""

# ╔═╡ 06000000-0000-0000-0000-000000000006
Calculator() do calc
    fuels = ["CH4", "C2H5OH", "C3H8", "H2"]
    println("=== Temperaturas de Llama Adiabática (φ=1, T₀=300 K) ===")
    println(rpad("Combustible", 16), rpad("T_ad [K]", 14), "T_ad [°C]")
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
> **Nota:** Los valores reales de $T_{ad}$ son menores debido a la disociación
> (CO₂ → CO + ½ O₂, H₂O → H₂ + ½ O₂) que consume energía. Este cálculo es
> una primera aproximación.
"""

# ╔═╡ 06000000-0000-0000-0000-000000000008
md"""
## 3. Efecto de la razón de equivalencia ($\phi$)
"""

# ╔═╡ 06000000-0000-0000-0000-000000000009
Calculator() do calc
    fuel = "CH4"
    phis = [0.5, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.5]
    println("=== Efecto de φ — $fuel (T₀=300 K) ===")
    for phi in phis
        try
            T_ad = adiabatic_flame_temperature(calc, fuel, 300.0, phi)
            obs = phi < 1.0 ? "pobre (exceso O₂)" :
                  phi > 1.0 ? "rico (falta O₂)" : "estequiométrico"
            @printf("φ=%-4.1f  T_ad=%8.0f K  %s\n", phi, T_ad, obs)
        catch e
            @printf("φ=%-4.1f  error\n", phi)
        end
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000010
md"""
## 4. Efecto del precalentamiento
"""

# ╔═╡ 06000000-0000-0000-0000-000000000011
Calculator() do calc
    fuel = "CH4"
    T_initials = [300, 400, 500, 600, 800]
    println("=== Efecto del Precalentamiento — $fuel (φ=1.0) ===")
    T_ad_base = adiabatic_flame_temperature(calc, fuel, 300.0, 1.0)
    for T0 in T_initials
        T_ad = adiabatic_flame_temperature(calc, fuel, Float64(T0), 1.0)
        @printf("T₀=%-5.0f K  T_ad=%8.0f K  ΔT=%+6.0f K\n", T0, T_ad, T_ad - T_ad_base)
    end
end

# ╔═╡ 06000000-0000-0000-0000-000000000012
md"""
## Resumen

En este cuaderno usted:

- Implementó el balance de energía para $T_{ad}$ usando `find_zero`
- Calculó $T_{ad}$ para CH₄, C₂H₅OH, C₃H₈ y H₂
- Exploró el efecto de la razón de equivalencia $\phi$ y del precalentamiento

En el [siguiente cuaderno](07_comparacion_biocombustibles.jl) compararemos
**sistemáticamente combustibles y biocombustibles**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 06000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
