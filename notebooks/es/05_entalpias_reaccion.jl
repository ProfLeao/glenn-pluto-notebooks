### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 05000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 05000000-0000-0000-0000-000000000001
md"""
# 05 — Entalpías de Reacción y Calores de Combustión

Este cuaderno demuestra cómo calcular **entalpías de reacción**
$\Delta_r H^\circ$ y **calores de combustión** (PCI/PCS — LHV/HHV) usando
Glenn.jl.

**Principio fundamental:** En la escala NASA, la entalpía de una reacción es
simplemente la suma estequiométrica de las entalpías estandarizadas de los
productos menos reactivos:

$$\Delta_r H^\circ(T) = \sum_{p} \nu_p H_p^\circ(T) - \sum_{r} \nu_r H_r^\circ(T)$$

> **Nota:** Este cálculo asume **gas ideal**. Para aplicaciones con gases
> reales, deben aplicarse correcciones de no idealidad.
"""

# ╔═╡ 05000000-0000-0000-0000-000000000003
md"""
## 1. Función auxiliar para $\Delta_r H^\circ$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000004
begin
    """
        reaction_enthalpy(calc, reactants, products, T)

    Calcula ΔrH°(T) a partir de la suma estequiométrica.
    """
    function reaction_enthalpy(calc, reactants, products, T)
        function get_h(name)
            sp = only(get_available_species(calc, name, exact_match = true))
            props = calculate_properties(calc, sp.id, T)
            return props.h_relative
        end

        ΔH = 0.0
        for (name, nu) in products
            ΔH += nu * get_h(name)
        end
        for (name, nu) in reactants
            ΔH -= nu * get_h(name)
        end
        return ΔH
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000005
md"""
## 2. Ejemplo 1: Combustión del metano

$$\text{CH}_4 + 2\text{O}_2 \rightarrow \text{CO}_2 + 2\text{H}_2\text{O}$$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000006
Calculator() do calc
    reactants = [("CH4", 1), ("O2", 2)]
    products  = [("CO2", 1), ("H2O", 2)]

    for T in [298.15, 500.0, 1000.0, 1500.0]
        ΔrH = reaction_enthalpy(calc, reactants, products, T)
        @printf("T = %6.0f K  →  ΔrH° = %10.1f kJ/mol\n", T, ΔrH / 1000.0)
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000007
md"""
### Ley de Kirchhoff

La dependencia de $\Delta_r H^\circ$ con la temperatura está dada por la
**Ley de Kirchhoff**:

$$\frac{d(\Delta_r H^\circ)}{dT} = \Delta_r C_p^\circ$$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000008
md"""
## 3. Ejemplo 2: Poder Calorífico (PCI/PCS — LHV/HHV)
"""

# ╔═╡ 05000000-0000-0000-0000-000000000009
Calculator() do calc
    ΔH_vap_H2O = 44.0e3  # J/mol

    function fuel_heating_values(calc, fuel_name, nC, nH)
        reactants = [(fuel_name, 1), ("O2", nC + nH / 4)]
        products  = [("CO2", Float64(nC)), ("H2O", Float64(nH) / 2)]

        ΔrH_lhv = reaction_enthalpy(calc, reactants, products, 298.15)
        lhv = -ΔrH_lhv
        hhv = lhv + (nH / 2) * ΔH_vap_H2O
        return lhv, hhv
    end

    fuels = [
        ("CH4",     "Metano",      1, 4),
        ("C2H5OH",  "Etanol",      2, 6),
        ("C3H8",    "Propano",     3, 8),
    ]

    println("=== Poderes Caloríficos ===")
    println(rpad("Combustible", 14), rpad("PCI (LHV)", 20),
            rpad("PCS (HHV)", 20), rpad("PCI [MJ/kg]", 16))
    println("—"^70)

    for (name, label, nC, nH) in fuels
        try
            sp = only(get_available_species(calc, name, exact_match = true))
            MW = something(sp.molecular_weight, 0.0)
            lhv, hhv = fuel_heating_values(calc, name, nC, nH)
            lhv_MJkg = lhv / MW / 1000.0
            @printf("%-14s %14.1f kJ/mol  %14.1f kJ/mol  %12.2f MJ/kg\n",
                label, lhv / 1000.0, hhv / 1000.0, lhv_MJkg)
        catch e
            @printf("%-14s %s\n", label, "no disponible")
        end
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000010
md"""
## 4. Ejemplo 3: Ley de Hess

Verificación para: $\text{C} + \text{O}_2 \rightarrow \text{CO}_2$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000011
Calculator() do calc
    T = 298.15

    ΔrH_direct = reaction_enthalpy(
        calc,
        [("C", 1), ("O2", 1)],
        [("CO2", 1)],
        T
    )

    ΔrH_step1 = reaction_enthalpy(
        calc,
        [("C", 1), ("O2", 0.5)],
        [("CO", 1)],
        T
    )
    ΔrH_step2 = reaction_enthalpy(
        calc,
        [("CO", 1), ("O2", 0.5)],
        [("CO2", 1)],
        T
    )
    ΔrH_indirect = ΔrH_step1 + ΔrH_step2

    println("=== Verificación de la Ley de Hess ===")
    @printf("Camino directo:      %10.1f kJ/mol\n", ΔrH_direct / 1000.0)
    @printf("Camino indirecto:    %10.1f kJ/mol\n", ΔrH_indirect / 1000.0)
end

# ╔═╡ 05000000-0000-0000-0000-000000000012
md"""
## Resumen

En este cuaderno aprendió:

- A calcular $\Delta_r H^\circ$ vía suma estequiométrica de `h_relative`
- La Ley de Kirchhoff: dependencia de $\Delta_r H^\circ$ con $T$
- A calcular PCI (LHV) y PCS (HHV) para combustibles
- A verificar la Ley de Hess

En el [siguiente cuaderno](06_temperatura_llama_adiabatica.jl) usaremos estos
conceptos para calcular la **temperatura de llama adiabática**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 05000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═05000000-0000-0000-0000-000000000001
# ╠═05000000-0000-0000-0000-000000000002
# ╠═05000000-0000-0000-0000-000000000003
# ╠═05000000-0000-0000-0000-000000000004
# ╠═05000000-0000-0000-0000-000000000005
# ╠═05000000-0000-0000-0000-000000000006
# ╠═05000000-0000-0000-0000-000000000007
# ╠═05000000-0000-0000-0000-000000000008
# ╠═05000000-0000-0000-0000-000000000009
# ╠═05000000-0000-0000-0000-000000000010
# ╠═05000000-0000-0000-0000-000000000011
# ╠═05000000-0000-0000-0000-000000000012
# ╠═05000000-0000-0000-0000-000000000013
