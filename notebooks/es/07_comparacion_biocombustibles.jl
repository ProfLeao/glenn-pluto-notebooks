### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 07000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 07000000-0000-0000-0000-000000000001
md"""
# 07 — Comparación de Combustibles y Biocombustibles

Este cuaderno compara sistemáticamente combustibles convencionales y
biocombustibles usando métricas termodinámicas y ambientales:

- **Densidad energética** (PCI/PCS por kg)
- **Relación aire-combustible estequiométrica**
- **Intensidad de CO₂** (kg CO₂ por kg de combustible y por MJ)
- **Temperatura de llama adiabática**

> **Caso de uso GESESC:** Evaluación de biocombustibles para motores.
"""

# ╔═╡ 07000000-0000-0000-0000-000000000003
md"""
## 1. Definiciones de combustibles
"""

# ╔═╡ 07000000-0000-0000-0000-000000000004
begin
    const FUEL_DEFS = [
        ("CH4",     "Metano (GN)",          1, 4, 0, "Fósil"),
        ("C3H8",    "Propano (GLP)",        3, 8, 0, "Fósil"),
        ("CH3OH",   "Metanol",              1, 4, 1, "Biocombustible"),
        ("C2H5OH",  "Etanol",               2, 6, 1, "Biocombustible"),
        ("H2",      "Hidrógeno",            0, 2, 0, "Renovable"),
    ]
end

# ╔═╡ 07000000-0000-0000-0000-000000000005
md"""
## 2. Análisis de combustibles
"""

# ╔═╡ 07000000-0000-0000-0000-000000000006
begin
    function analyze_fuels()
        results = []
        MW_O2 = 31.9988
        MW_CO2 = 44.0095

        Calculator() do calc
            for (name, label, nC, nH, nO, cat) in FUEL_DEFS
                try
                    sp = only(get_available_species(calc, name, exact_match = true))
                    MW = something(sp.molecular_weight, 0.0)

                    nO2_stoich = nC + nH/4 - nO/2
                    AF_stoich = (nO2_stoich * MW_O2 + nO2_stoich * 3.76 * 28.0134) / MW

                    reactants = [(name, 1), ("O2", nO2_stoich)]
                    products  = [("CO2", Float64(nC)), ("H2O", Float64(nH)/2)]
                    ΔrH = 0.0
                    for (rn, nu) in products
                        rsp = only(get_available_species(calc, rn, exact_match = true))
                        ΔrH += nu * calculate_properties(calc, rsp.id, 298.15).h_relative
                    end
                    for (rn, nu) in reactants
                        rsp = only(get_available_species(calc, rn, exact_match = true))
                        ΔrH -= nu * calculate_properties(calc, rsp.id, 298.15).h_relative
                    end
                    LHV = -ΔrH

                    CO2_per_kg_fuel = (nC * MW_CO2) / (MW / 1000.0)
                    LHV_MJkg = LHV / MW * 1000.0 / 1e6
                    CO2_per_MJ = CO2_per_kg_fuel / LHV_MJkg

                    push!(results, (
                        name = label, category = cat, MW_gmol = MW,
                        LHV_MJkg = LHV_MJkg, LHV_kJmol = LHV / 1000.0,
                        AF_stoich = AF_stoich,
                        CO2_kg_per_kg = CO2_per_kg_fuel,
                        CO2_kg_per_MJ = CO2_per_MJ,
                    ))
                catch e
                    @warn "Error al procesar $name: $e"
                end
            end
        end
        return results
    end

    fuel_results = analyze_fuels()
end

# ╔═╡ 07000000-0000-0000-0000-000000000007
md"""
## 3. Tabla comparativa
"""

# ╔═╡ 07000000-0000-0000-0000-000000000008
begin
    df = DataFrame(
        Combustible = [r.name for r in fuel_results],
        Categoría = [r.category for r in fuel_results],
        LHV_MJkg = round.([r.LHV_MJkg for r in fuel_results], digits = 2),
        LHV_kJmol = round.([r.LHV_kJmol for r in fuel_results], digits = 0),
        AF_estequiom = round.([r.AF_stoich for r in fuel_results], digits = 1),
        CO2_kg_por_kg = round.([r.CO2_kg_per_kg for r in fuel_results], digits = 2),
        CO2_kg_por_MJ = round.([r.CO2_kg_per_MJ for r in fuel_results], digits = 4),
    )
    sort!(df, :LHV_MJkg, rev = true)
    df
end

# ╔═╡ 07000000-0000-0000-0000-000000000009
md"""
## 4. Análisis

### Observaciones principales:

1. **Densidad energética:** Hidrocarburos puros (CH₄, C₃H₈) tienen mayor PCI
   por kg. Los oxigenados (metanol, etanol) tienen menor PCI por kg.

2. **Relación aire-combustible:** Combustibles oxigenados necesitan menos aire
   (ya contienen oxígeno).

3. **Intensidad de CO₂:** Por MJ, el metano tiene la menor intensidad entre los
   fósiles. Hidrógeno: cero emisiones directas de CO₂.
"""

# ╔═╡ 07000000-0000-0000-0000-000000000010
md"""
## Resumen

En este cuaderno usted:

- Comparó combustibles fósiles y biocombustibles usando métricas cuantitativas
- Calculó PCI, relación aire-combustible e intensidad de CO₂

En el [siguiente cuaderno](08_equilibrio_gibbs.jl) exploraremos el **equilibrio
químico** y la **energía libre de Gibbs**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 07000000-0000-0000-0000-000000000011
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═07000000-0000-0000-0000-000000000001
# ╠═07000000-0000-0000-0000-000000000002
# ╠═07000000-0000-0000-0000-000000000003
# ╠═07000000-0000-0000-0000-000000000004
# ╠═07000000-0000-0000-0000-000000000005
# ╠═07000000-0000-0000-0000-000000000006
# ╠═07000000-0000-0000-0000-000000000007
# ╠═07000000-0000-0000-0000-000000000008
# ╠═07000000-0000-0000-0000-000000000009
# ╠═07000000-0000-0000-0000-000000000010
# ╠═07000000-0000-0000-0000-000000000011
