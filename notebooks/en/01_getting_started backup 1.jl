### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 01000000-0000-0000-0000-000000000001
md"""
# 01 — Getting Started with `Glenn.jl`

**`Glenn.jl`** is a thermochemical properties calculator for Julia that
reconstructs three standard-state molar properties as analytical functions
of temperature,

$$C_p^\circ(T), \qquad H^\circ(T), \qquad S^\circ(T),$$

from **NASA polynomial coefficients** stored in a bundled **SQLite** database.
The database ships with the package and contains roughly **2030 chemical
species** (gases and condensed phases) spanning **3772 temperature intervals**,
derived from NASA Glenn's `thermo.inp` data set.

This first notebook covers the essentials:

1. Connecting to the bundled database
2. Inspecting the database contents
3. Searching for species
4. Computing $C_p^\circ$, $H^\circ$ and $S^\circ$ at a given temperature
5. Understanding the values that are returned
6. Enthalpy differences and property tables
7. Graceful error handling

> **Author of the package:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000002
md"""
## Contents

1. [Connecting to the database](#1-connecting-to-the-database)
2. [Inspecting the database](#2-inspecting-the-database)
3. [Searching for species](#3-searching-for-species)
4. [Computing properties](#4-computing-properties)
5. [Understanding the returned values](#5-understanding-the-returned-values)
6. [Enthalpy differences](#6-enthalpy-differences)
7. [Error handling](#7-error-handling)
"""

# ╔═╡ 01000000-0000-0000-0000-000000000003
md"""
## Prerequisites

Make sure the required packages are installed:

```julia
using Pkg
Pkg.add("Glenn")
Pkg.add("Pluto")
Pkg.add("Plots")
Pkg.add("DataFrames")
```
"""

# ╔═╡ 01000000-0000-0000-0000-000000000004
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 01000000-0000-0000-0000-000000000005
md"""
## 1. Connecting to the database

`Calculator()` automatically uses the bundled `thermo.db` — **zero
configuration** needed.

The recommended approach is the **`do`-block** (context manager), which
guarantees automatic connection cleanup:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000006
Calculator() do calc
    println("Connected successfully!")
    println("calc is a Calculator object: $(typeof(calc))")
end

# ╔═╡ 01000000-0000-0000-0000-000000000007
md"""
You can also open and close manually:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000008
let
    calc = Calculator()
    println("connect: calc connected")
    close(calc)
    println("close: calc closed")
end

# ╔═╡ 01000000-0000-0000-0000-000000000009
md"""
## 2. Inspecting the database

The underlying query object is exposed as `calc.db` (a `ThermoDB` instance).
Its `get_statistics()` method gives a quick overview of the data set.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000010
Calculator() do calc
    stats = Glenn.get_statistics(calc.db)

    println("=== Database Statistics ===")
    for (key, value) in stats
        println("  $(rpad(key, 24)): $value")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000011
md"""
The database contains:
- **2030 species** (766 condensed phases, 1264 gases)
- **3772 temperature intervals**
- **3772 coefficient sets** (NASA-7 polynomials)
"""

# ╔═╡ 01000000-0000-0000-0000-000000000012
md"""
## 3. Searching for species

### Substring search

`get_available_species(calc, "pattern")` returns all species whose name
**contains** the given pattern (case-insensitive):
"""

# ╔═╡ 01000000-0000-0000-0000-000000000013
Calculator() do calc
    species = get_available_species(calc, "CH4")
    println("Search for \"CH4\" — $(length(species)) results:")
    for s in species[1:min(8, end)]
        @printf("  id=%5d  %-20s  phase=%s\n", s.id, s.name, s.phase)
    end
    if length(species) > 8
        println("  ... and $(length(species) - 8) more results")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000014
md"""
### Exact match (recommended)

Use `exact_match=true` for case-insensitive exact search — `"O2"` returns
only O₂, not Al₂O₂ or Be₃N₂.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000015
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    println("Exact match \"O2\":")
    @printf("  id=%d  name=%s  formula=%s  phase=%s  MW=%.4f\n",
        o2.id, o2.name,
        something(o2.formula, "—"),
        o2.phase,
        something(o2.molecular_weight, 0.0))
end

# ╔═╡ 01000000-0000-0000-0000-000000000016
md"""
### Browsing the entire catalog

Passing an empty string pages through all ~2030 species. Here we just count
them and preview the first few.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000017
Calculator() do calc
    all_species = get_available_species(calc)
    println("Total species in catalog: $(length(all_species))")
    println()
    println("First 8 (alphabetical order):")
    for s in all_species[1:min(8, end)]
        @printf("  %-25s  %s\n", s.name, s.phase)
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000018
md"""
## 4. Computing properties

`calculate_properties(calc, id, T)` returns a `ThermoProperties` struct with
$C_p$, $H^\circ$ (relative enthalpy) and $S^\circ$ at temperature $T$ (in Kelvin).

All properties are returned in **SI units**:
- $C_p$, $S^\circ$ → J/(mol·K)
- $H^\circ$ → J/mol
"""

# ╔═╡ 01000000-0000-0000-0000-000000000019
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    props = calculate_properties(calc, o2.id, 1000.0)

    println("=== Properties of $(props.species_name) ($(props.phase)) ===")
    println("Temperature: $(round(props.temperature, digits=2)) K")
    println()
    println("  Cp  = $(round(props.cp, digits=3)) J/(mol·K)")
    println("  H°  = $(round(props.h_relative, digits=1)) J/mol")
    println("  S°  = $(round(props.s, digits=3)) J/(mol·K)")
end

# ╔═╡ 01000000-0000-0000-0000-000000000020
md"""
### Sweeping a temperature range

`get_properties_range(calc, id, Ts)` computes properties for multiple
temperatures at once:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000021
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    temps = [300, 500, 800, 1200, 1800, 2500]
    results = get_properties_range(calc, o2.id, temps)

    println("=== O₂ — Properties vs Temperature ===")
    println(rpad("  T [K]", 10), rpad("Cp [J/mol/K]", 18),
            rpad("S [J/mol/K]", 18), rpad("H [kJ/mol]", 15))
    for r in results
        @printf("  %-8.0f  %-16.3f  %-16.3f  %-13.3f\n",
            r.temperature, r.cp, r.s, r.h_relative / 1000.0)
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000022
md"""
## 5. Understanding the returned values

The `h_relative` field is the **standardized molar enthalpy on the NASA
scale** — it already includes the enthalpy of formation. Consequently:

- **Reference-state elements** have $H^\circ(298.15\,\text{K}) \approx 0$
- **Compounds** have $H^\circ(298.15\,\text{K})$ equal to their $\Delta_f H^\circ$
- Reaction enthalpies are simple stoichiometric sums
"""

# ╔═╡ 01000000-0000-0000-0000-000000000023
Calculator() do calc
    # CH4 is a compound: H°(298.15 K) ≈ ΔfH°(CH4)
    ch4 = only(get_available_species(calc, "CH4", exact_match = true))
    props_ch4 = calculate_properties(calc, ch4.id, 298.15)

    # O2 is a reference element: H°(298.15 K) ≈ 0
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    props_o2 = calculate_properties(calc, o2.id, 298.15)

    println("=== Verifying h_relative at 298.15 K ===")
    @printf("  CH4 (compound):  H° = %12.1f J/mol  (%8.3f kJ/mol)\n",
        props_ch4.h_relative, props_ch4.h_relative / 1000.0)
    @printf("  O2  (element):   H° = %12.1f J/mol  (%8.3f kJ/mol)\n",
        props_o2.h_relative, props_o2.h_relative / 1000.0)
end

# ╔═╡ 01000000-0000-0000-0000-000000000024
md"""
## 6. Enthalpy differences

`calculate_enthalpy_change(calc, id, T1, T2)` computes
$\Delta H = H(T_2) - H(T_1)$.

This is useful for energy balances in processes where the chemical composition
does not change (sensible heating/cooling).
"""

# ╔═╡ 01000000-0000-0000-0000-000000000025
Calculator() do calc
    co2 = only(get_available_species(calc, "CO2", exact_match = true))

    # Heating from 300 K → 1500 K
    dh = calculate_enthalpy_change(calc, co2.id, 300.0, 1500.0)
    @printf("CO₂: ΔH(300→1500 K) = %.1f J/mol = %.1f kJ/mol\n", dh, dh / 1000.0)

    # Cross-check: H(1500) - H(300)
    p1 = calculate_properties(calc, co2.id, 300.0)
    p2 = calculate_properties(calc, co2.id, 1500.0)
    dh_check = p2.h_relative - p1.h_relative
    @printf("Check: H(1500) - H(300) = %.1f J/mol\n", dh_check)
end

# ╔═╡ 01000000-0000-0000-0000-000000000026
md"""
### Enthalpy of formation

`calculate_formation_enthalpy(calc, id)` returns $\Delta_f H^\circ$ at 298.15 K:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000027
Calculator() do calc
    for name in ["CH4", "O2", "CO2", "H2O"]
        sp = only(get_available_species(calc, name, exact_match = true))
        h_f = calculate_formation_enthalpy(calc, sp.id)
        if h_f !== nothing
            @printf("%-6s  ΔH°f(298.15 K) = %12.1f J/mol  (%8.3f kJ/mol)\n",
                name, h_f, h_f / 1000.0)
        else
            @printf("%-6s  ΔH°f(298.15 K) = not available\n", name)
        end
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000028
md"""
## 7. Error handling

Glenn.jl defines an exception hierarchy for graceful error handling:

- `ThermoCalcError` — base class
- `DatabaseNotConnectedError` — operation without connection
- `SpeciesNotFoundError` — species not found
- `TemperatureOutOfRangeError` — temperature out of valid range
"""

# ╔═╡ 01000000-0000-0000-0000-000000000029
begin
    using Glenn:
        ThermoCalcError,
        DatabaseNotConnectedError,
        SpeciesNotFoundError,
        TemperatureOutOfRangeError

    println("=== Exception Hierarchy ===")
    for exc in (DatabaseNotConnectedError, SpeciesNotFoundError, TemperatureOutOfRangeError)
        println("  $(rpad(string(exc), 30)) is a ThermoCalcError? $(exc <: ThermoCalcError)")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000030
md"""
### Catching errors with `try/catch`
"""

# ╔═╡ 01000000-0000-0000-0000-000000000031
begin
    # Non-existent species
    calc_test = Calculator()
    try
        get_available_species(calc_test, "XYZ123", exact_match = true)
        println("Should not reach here")
    catch e
        if e isa SpeciesNotFoundError
            println("✓ SpeciesNotFoundError caught: ", e.msg)
        else
            println("Unexpected error: ", e)
        end
    end

    # Temperature out of range
    try
        o2_test = only(get_available_species(calc_test, "O2", exact_match = true))
        calculate_properties(calc_test, o2_test.id, 100000.0)
    catch e
        if e isa TemperatureOutOfRangeError
            println("✓ TemperatureOutOfRangeError caught: ", e.msg)
        else
            println("Unexpected error: ", e)
        end
    end

    close(calc_test)
end

# ╔═╡ 01000000-0000-0000-0000-000000000032
md"""
## Summary

You now know how to:

- Connect to the bundled database (preferably via the `do` block);
- Inspect it with `get_statistics()`;
- Search for species with `get_available_species()` and resolve exact names;
- Compute $C_p^\circ$, $S^\circ$ and $H^\circ$ with `calculate_properties()`;
- Sweep temperature ranges with `get_properties_range()`;
- Obtain $\Delta_f H^\circ$ with `calculate_formation_enthalpy()`;
- Handle errors with `try/catch` using the `ThermoCalcError` hierarchy.

In the [next notebook](02_nasa_polynomials.jl) we will dive into the **NASA
polynomials** that power these calculations.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 01000000-0000-0000-0000-000000000033
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
