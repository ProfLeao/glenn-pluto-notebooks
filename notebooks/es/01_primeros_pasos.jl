### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 01000000-0000-0000-0000-000000000004
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 01000000-0000-0000-0000-000000000029
begin
    using Glenn:
        ThermoCalcError,
        DatabaseNotConnectedError,
        SpeciesNotFoundError,
        TemperatureOutOfRangeError

    println("=== Jerarquía de Excepciones ===")
    for exc in (DatabaseNotConnectedError, SpeciesNotFoundError, TemperatureOutOfRangeError)
        println("  $(rpad(string(exc), 30)) ¿es un ThermoCalcError? $(exc <: ThermoCalcError)")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000001
md"""
# 01 — Primeros Pasos con `Glenn.jl`

**`Glenn.jl`** es un calculador de propiedades termoquímicas para Julia que
reconstruye tres propiedades molares en el estado estándar como funciones
analíticas de la temperatura,

$$C_p^\circ(T), \qquad H^\circ(T), \qquad S^\circ(T),$$

a partir de **coeficientes polinomiales de la NASA** almacenados en una base de
datos **SQLite** empaquetada. La base de datos se distribuye con el paquete y
contiene aproximadamente **2030 especies químicas** (gases y fases condensadas)
distribuidas en **3772 intervalos de temperatura**, derivadas del conjunto de
datos `thermo.inp` del NASA Glenn.

Este primer cuaderno cubre los fundamentos:

1. Conexión a la base de datos empaquetada
2. Inspección del contenido de la base de datos
3. Búsqueda de especies
4. Cálculo de $C_p^\circ$, $H^\circ$ y $S^\circ$ a una temperatura dada
5. Comprensión de los valores devueltos
6. Diferencias de entalpía y tablas de propiedades
7. Manejo elegante de errores

> **Autor del paquete:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000002
md"""
## Contenido

1. [Conectando a la base de datos](#1-conectando-a-la-base-de-datos)
2. [Inspeccionando la base de datos](#2-inspeccionando-la-base-de-datos)
3. [Buscando especies](#3-buscando-especies)
4. [Calculando propiedades](#4-calculando-propiedades)
5. [Entendiendo los valores devueltos](#5-entendiendo-los-valores-devueltos)
6. [Diferencias de entalpía](#6-diferencias-de-entalpía)
7. [Manejo de errores](#7-manejo-de-errores)
"""

# ╔═╡ 01000000-0000-0000-0000-000000000003
md"""
## Requisitos previos

Asegúrese de que los paquetes necesarios estén instalados:

```julia
using Pkg
Pkg.add("Glenn")
Pkg.add("Pluto")
Pkg.add("Plots")
Pkg.add("DataFrames")
```
"""

# ╔═╡ 01000000-0000-0000-0000-000000000005
md"""
## 1. Conectando a la base de datos

`Calculator()` usa automáticamente la base de datos `thermo.db` empaquetada
con el paquete — **configuración cero**.

La forma recomendada es usar el **bloque `do`** (context manager), que
garantiza el cierre automático de la conexión:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000006
Calculator() do calc
    println("¡Conectado exitosamente!")
    println("calc es un objeto Calculator: $(typeof(calc))")
end

# ╔═╡ 01000000-0000-0000-0000-000000000007
md"""
También es posible abrir y cerrar manualmente:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000008
let
    calc = Calculator()
    println("connect: calc conectado")
    close(calc)
    println("close: calc cerrado")
end

# ╔═╡ 01000000-0000-0000-0000-000000000009
md"""
## 2. Inspeccionando la base de datos

El objeto de consulta subyacente se expone como `calc.db` (una instancia de
`ThermoDB`). Su método `get_statistics()` proporciona una visión general
rápida del conjunto de datos.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000010
Calculator() do calc
    stats = Glenn.get_statistics(calc.db)

    println("=== Estadísticas de la Base de Datos ===")
    for (key, value) in stats
        println("  $(rpad(key, 24)): $value")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000011
md"""
La base de datos contiene:
- **2030 especies** (766 fases condensadas, 1264 gases)
- **3772 intervalos de temperatura**
- **3772 conjuntos de coeficientes** (polinomios NASA-7)
"""

# ╔═╡ 01000000-0000-0000-0000-000000000012
md"""
## 3. Buscando especies

### Búsqueda por subcadena

`get_available_species(calc, "patrón")` devuelve todas las especies cuyo
nombre **contiene** el patrón proporcionado (insensible a mayúsculas):
"""

# ╔═╡ 01000000-0000-0000-0000-000000000013
Calculator() do calc
    species = get_available_species(calc, "CH4")
    println("Búsqueda \"CH4\" — $(length(species)) resultados:")
    for s in species[1:min(8, end)]
        @printf("  id=%5d  %-20s  phase=%s\n", s.id, s.name, s.phase)
    end
    if length(species) > 8
        println("  ... y $(length(species) - 8) más")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000014
md"""
### Búsqueda exacta (recomendado)

Use `exact_match=true` para búsqueda exacta insensible a mayúsculas — `"O2"`
devuelve solo O₂, no Al₂O₂ ni Be₃N₂.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000015
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    println("Búsqueda exacta \"O2\":")
    @printf("  id=%d  name=%s  formula=%s  phase=%s  MW=%.4f\n",
        o2.id, o2.name,
        something(o2.formula, "—"),
        o2.phase,
        something(o2.molecular_weight, 0.0))
end

# ╔═╡ 01000000-0000-0000-0000-000000000016
md"""
### Navegando por todo el catálogo

Pasar una cadena vacía pagina por todas las ~2030 especies. Aquí solo las
contamos y previsualizamos las primeras.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000017
Calculator() do calc
    all_species = get_available_species(calc)
    println("Total de especies en el catálogo: $(length(all_species))")
    println()
    println("Primeras 8 (en orden alfabético):")
    for s in all_species[1:min(8, end)]
        @printf("  %-25s  %s\n", s.name, s.phase)
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000018
md"""
## 4. Calculando propiedades

`calculate_properties(calc, id, T)` devuelve un struct `ThermoProperties` con
$C_p$, $H^\circ$ (entalpía relativa) y $S^\circ$ a la temperatura $T$ (en Kelvin).

Todas las propiedades se devuelven en **unidades SI**:
- $C_p$, $S^\circ$ → J/(mol·K)
- $H^\circ$ → J/mol
"""

# ╔═╡ 01000000-0000-0000-0000-000000000019
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    props = calculate_properties(calc, o2.id, 1000.0)

    println("=== Propiedades de $(props.species_name) ($(props.phase)) ===")
    println("Temperatura: $(round(props.temperature, digits=2)) K")
    println()
    println("  Cp  = $(round(props.cp, digits=3)) J/(mol·K)")
    println("  H°  = $(round(props.h_relative, digits=1)) J/mol")
    println("  S°  = $(round(props.s, digits=3)) J/(mol·K)")
end

# ╔═╡ 01000000-0000-0000-0000-000000000020
md"""
### Barriendo un rango de temperatura

`get_properties_range(calc, id, Ts)` calcula propiedades para múltiples
temperaturas a la vez:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000021
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    temps = [300, 500, 800, 1200, 1800, 2500]
    results = get_properties_range(calc, o2.id, temps)

    println("=== O₂ — Propiedades vs Temperatura ===")
    println(rpad("  T [K]", 10), rpad("Cp [J/mol/K]", 18),
            rpad("S [J/mol/K]", 18), rpad("H [kJ/mol]", 15))
    for r in results
        @printf("  %-8.0f  %-16.3f  %-16.3f  %-13.3f\n",
            r.temperature, r.cp, r.s, r.h_relative / 1000.0)
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000022
md"""
## 5. Entendiendo los valores devueltos

El campo `h_relative` es la **entalpía molar estandarizada en la escala NASA**
— ya incluye la entalpía de formación. En consecuencia:

- **Elementos en el estado de referencia** tienen $H^\circ(298.15\,\text{K}) \approx 0$
- **Compuestos** tienen $H^\circ(298.15\,\text{K})$ igual a su $\Delta_f H^\circ$
- Las entalpías de reacción son simples sumas estequiométricas
"""

# ╔═╡ 01000000-0000-0000-0000-000000000023
Calculator() do calc
    ch4 = only(get_available_species(calc, "CH4", exact_match = true))
    props_ch4 = calculate_properties(calc, ch4.id, 298.15)

    o2 = only(get_available_species(calc, "O2", exact_match = true))
    props_o2 = calculate_properties(calc, o2.id, 298.15)

    println("=== Verificación de h_relative a 298.15 K ===")
    @printf("  CH4 (compuesto): H° = %12.1f J/mol  (%8.3f kJ/mol)\n",
        props_ch4.h_relative, props_ch4.h_relative / 1000.0)
    @printf("  O2  (elemento):  H° = %12.1f J/mol  (%8.3f kJ/mol)\n",
        props_o2.h_relative, props_o2.h_relative / 1000.0)
end

# ╔═╡ 01000000-0000-0000-0000-000000000024
md"""
## 6. Diferencias de entalpía

`calculate_enthalpy_change(calc, id, T1, T2)` calcula
$\Delta H = H(T_2) - H(T_1)$.

Esto es útil para balances de energía en procesos donde la composición química
no cambia (calentamiento/enfriamiento sensible).
"""

# ╔═╡ 01000000-0000-0000-0000-000000000025
Calculator() do calc
    co2 = only(get_available_species(calc, "CO2", exact_match = true))

    dh = calculate_enthalpy_change(calc, co2.id, 300.0, 1500.0)
    @printf("CO₂: ΔH(300→1500 K) = %.1f J/mol = %.1f kJ/mol\n", dh, dh / 1000.0)

    p1 = calculate_properties(calc, co2.id, 300.0)
    p2 = calculate_properties(calc, co2.id, 1500.0)
    dh_check = p2.h_relative - p1.h_relative
    @printf("Verificación: H(1500) - H(300) = %.1f J/mol\n", dh_check)
end

# ╔═╡ 01000000-0000-0000-0000-000000000026
md"""
### Entalpía de formación

`calculate_formation_enthalpy(calc, id)` devuelve $\Delta_f H^\circ$ a 298.15 K:
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
            @printf("%-6s  ΔH°f(298.15 K) = no disponible\n", name)
        end
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000028
md"""
## 7. Manejo de errores

Glenn.jl define una jerarquía de excepciones para el manejo elegante de errores:

- `ThermoCalcError` — clase base
- `DatabaseNotConnectedError` — operación sin conexión
- `SpeciesNotFoundError` — especie no encontrada
- `TemperatureOutOfRangeError` — temperatura fuera del rango válido
"""

# ╔═╡ 01000000-0000-0000-0000-000000000030
md"""
### Capturando errores con `try/catch`
"""

# ╔═╡ 01000000-0000-0000-0000-000000000031
begin
    calc_test = Calculator()
    try
        get_available_species(calc_test, "XYZ123", exact_match = true)
        println("No debería llegar aquí")
    catch e
        if e isa SpeciesNotFoundError
            println("✓ SpeciesNotFoundError capturado: ", e.msg)
        else
            println("Error inesperado: ", e)
        end
    end

    try
        o2_test = only(get_available_species(calc_test, "O2", exact_match = true))
        calculate_properties(calc_test, o2_test.id, 100000.0)
    catch e
        if e isa TemperatureOutOfRangeError
            println("✓ TemperatureOutOfRangeError capturado: ", e.msg)
        else
            println("Error inesperado: ", e)
        end
    end

    close(calc_test)
end

# ╔═╡ 01000000-0000-0000-0000-000000000032
md"""
## Resumen

Ahora sabe cómo:

- Conectarse a la base de datos empaquetada (preferiblemente mediante el bloque `do`);
- Inspeccionarla con `get_statistics()`;
- Buscar especies con `get_available_species()` y resolver nombres exactos;
- Calcular $C_p^\circ$, $S^\circ$ y $H^\circ$ con `calculate_properties()`;
- Barrer rangos de temperatura con `get_properties_range()`;
- Obtener $\Delta_f H^\circ$ con `calculate_formation_enthalpy()`;
- Manejar errores con `try/catch` usando la jerarquía `ThermoCalcError`.

En el [siguiente cuaderno](02_polinomios_nasa.jl) profundizaremos en los
**polinomios de la NASA** que alimentan estos cálculos.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 01000000-0000-0000-0000-000000000033
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═01000000-0000-0000-0000-000000000001
# ╠═01000000-0000-0000-0000-000000000002
# ╠═01000000-0000-0000-0000-000000000003
# ╠═01000000-0000-0000-0000-000000000004
# ╠═01000000-0000-0000-0000-000000000005
# ╠═01000000-0000-0000-0000-000000000006
# ╠═01000000-0000-0000-0000-000000000007
# ╠═01000000-0000-0000-0000-000000000008
# ╠═01000000-0000-0000-0000-000000000009
# ╠═01000000-0000-0000-0000-000000000010
# ╠═01000000-0000-0000-0000-000000000011
# ╠═01000000-0000-0000-0000-000000000012
# ╠═01000000-0000-0000-0000-000000000013
# ╠═01000000-0000-0000-0000-000000000014
# ╠═01000000-0000-0000-0000-000000000015
# ╠═01000000-0000-0000-0000-000000000016
# ╠═01000000-0000-0000-0000-000000000017
# ╠═01000000-0000-0000-0000-000000000018
# ╠═01000000-0000-0000-0000-000000000019
# ╠═01000000-0000-0000-0000-000000000020
# ╠═01000000-0000-0000-0000-000000000021
# ╠═01000000-0000-0000-0000-000000000022
# ╠═01000000-0000-0000-0000-000000000023
# ╠═01000000-0000-0000-0000-000000000024
# ╠═01000000-0000-0000-0000-000000000025
# ╠═01000000-0000-0000-0000-000000000026
# ╠═01000000-0000-0000-0000-000000000027
# ╠═01000000-0000-0000-0000-000000000028
# ╠═01000000-0000-0000-0000-000000000029
# ╠═01000000-0000-0000-0000-000000000030
# ╠═01000000-0000-0000-0000-000000000031
# ╠═01000000-0000-0000-0000-000000000032
# ╠═01000000-0000-0000-0000-000000000033
