### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 02000000-0000-0000-0000-000000000001
md"""
# 02 — NASA Polynomials Under the Hood

This notebook demystifies the numerical machinery behind `Glenn.jl` by
implementing the **NASA-7 polynomials** from scratch and validating the results
against the high-level API.

By the end, you will understand:

1. The structure of NASA-7 polynomials (9-coefficient format)
2. How $C_p^\circ(T)$, $H^\circ(T)$ and $S^\circ(T)$ are computed
3. The piecewise nature of temperature intervals
4. The meaning of the integration constants $b_1$ and $b_2$
5. How to validate manual calculations against the API
"""

# ╔═╡ 02000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 02000000-0000-0000-0000-000000000003
md"""
## 1. The NASA-7 Polynomial Equations

The NASA polynomials represent thermodynamic properties in dimensionless form
(divided by $R$). For each temperature interval, 7 coefficients $(a_1, \dots, a_7)$
and 2 integration constants $(b_1, b_2)$ are provided:

$$\frac{C_p(T)}{R} = a_1 T^{-2} + a_2 T^{-1} + a_3 + a_4 T + a_5 T^2 + a_6 T^3 + a_7 T^4$$

$$\frac{H^\circ(T)}{RT} = -a_1 T^{-2} + a_2 \frac{\ln T}{T} + a_3 + a_4 \frac{T}{2} + a_5 \frac{T^2}{3} + a_6 \frac{T^3}{4} + a_7 \frac{T^4}{5} + \frac{b_1}{T}$$

$$\frac{S^\circ(T)}{R} = -\frac{a_1}{2} T^{-2} - a_2 T^{-1} + a_3 \ln T + a_4 T + a_5 \frac{T^2}{2} + a_6 \frac{T^3}{3} + a_7 \frac{T^4}{4} + b_2$$
"""

# ╔═╡ 02000000-0000-0000-0000-000000000004
md"""
## 2. Retrieving raw coefficients

Let's obtain the complete data for O₂ to inspect its intervals and coefficients:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000005
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    data = get_species_data(calc.db, o2.id)

    println("=== Complete O₂ data ===")
    println("Name:       ", data["name"])
    println("Formula:    ", data["formula"])
    println("Phase:      ", data["phase"])
    println("Mol. weight:", data["molecular_weight"])
    println("N intervals:", data["num_intervals"])
    println()
    println("Temperature intervals:")
    for interval in data["intervals"]
        println("  [$(interval["temp_min"]) K, $(interval["temp_max"]) K]")
    end
end

# ╔═╡ 02000000-0000-0000-0000-000000000006
md"""
## 3. Reconstructing calculations manually

Functions implementing the NASA-7 polynomials from raw coefficients:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000007
"""
    cp_r(a, T)

Compute Cp/R using NASA-7 coefficients.
"""
function cp_r(a, T)
    a[1] * T^(-2) + a[2] * T^(-1) + a[3] + a[4] * T +
    a[5] * T^2 + a[6] * T^3 + a[7] * T^4
end

# ╔═╡ 02000000-0000-0000-0000-000000000008
"""
    h_rt(a, b1, T)

Compute H/(RT) using NASA-7 coefficients.
"""
function h_rt(a, b1, T)
    -a[1] * T^(-2) + a[2] * log(T) / T + a[3] +
    a[4] * T / 2 + a[5] * T^2 / 3 + a[6] * T^3 / 4 +
    a[7] * T^4 / 5 + b1 / T
end

# ╔═╡ 02000000-0000-0000-0000-000000000009
"""
    s_r(a, b2, T)

Compute S/R using NASA-7 coefficients.
"""
function s_r(a, b2, T)
    -a[1] / 2 * T^(-2) - a[2] * T^(-1) + a[3] * log(T) +
    a[4] * T + a[5] * T^2 / 2 + a[6] * T^3 / 3 +
    a[7] * T^4 / 4 + b2
end

# ╔═╡ 02000000-0000-0000-0000-000000000010
md"""
## 4. Validating against the Glenn.jl API

Let's compare our manual calculations with the API results:
"""

# ╔═╡ 02000000-0000-0000-0000-000000000011
md"""
### O₂ at 1000 K
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

    println("=== O₂ at $(T) K ===")
    println()
    println(rpad("", 20), rpad("Manual", 16), rpad("Glenn.jl API", 16))
    println("—"^52)
    @printf("%-20s %15.6f %15.6f\n", "Cp [J/(mol·K)]", cp_manual, api.cp)
    @printf("%-20s %15.1f %15.1f\n", "H° [J/mol]", h_manual, api.h_relative)
    @printf("%-20s %15.6f %15.6f\n", "S° [J/(mol·K)]", s_manual, api.s)

    println()
    println("✓ Manual reconstruction matches the API!")
end

# ╔═╡ 02000000-0000-0000-0000-000000000013
md"""
### Additional check: low-level functions

Glenn.jl also exposes low-level functions that return dimensionless values:
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

    println("=== Dimensionless comparison (O₂ at $T K) ===")
    @printf("Cp/R : %16.12f  ==  %16.12f\n", cp_r(a, T), cp_r_api)
    @printf("H/RT : %16.12f  ==  %16.12f\n", h_rt(a, b1, T), h_rt_api)
    @printf("S/R  : %16.12f  ==  %16.12f\n", s_r(a, b2, T), s_r_api)
end

# ╔═╡ 02000000-0000-0000-0000-000000000015
md"""
## 5. The piecewise structure

Glenn.jl selects the interval that contains the requested temperature. Near
the 1000 K boundary for O₂, the `temp_interval` field changes, but $C_p$
remains continuous — NASA fits are constrained to match at the splices.
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

        @printf("T = %6.1f K  →  interval [%d, %d]  →  Cp = %.6f J/(mol·K)\n",
            T, interval["temp_min"], interval["temp_max"], cp_val)
    end

    println()
    println("Notice: Cp is continuous across the 1000 K boundary,")
    println("but the integration constants b1 and b2 change.")
end

# ╔═╡ 02000000-0000-0000-0000-000000000017
md"""
## 6. Meaning of $b_1$ and $b_2$

The integration constants connect the thermodynamic functions to the reference
state:

- **$b_1$**: determines the **enthalpy zero** — for reference-state elements,
  $H^\circ(298.15\,\text{K}) \approx 0$
- **$b_2$**: determines the **entropy zero** — consistent with the Third Law
  ($S \to 0$ as $T \to 0$)

This means $b_1$ and $b_2$ are **different for each interval**, but guarantee
continuity at the boundaries.
"""

# ╔═╡ 02000000-0000-0000-0000-000000000018
md"""
## Summary

In this notebook you:

- Manually implemented the NASA-7 equations for $C_p$, $H^\circ$ and $S^\circ$
- Validated results against the Glenn.jl API to floating-point precision
- Understood the piecewise structure and continuity at boundaries
- Learned the physical meaning of $b_1$ and $b_2$

In the [next notebook](03_property_curves.jl) we will generate **property
curves** as functions of temperature and interpret physical features.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 02000000-0000-0000-0000-000000000019
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
