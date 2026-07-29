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
# 07 — Comparing Fuels & Biofuels

This notebook systematically compares conventional fuels and biofuels using
thermodynamic and environmental metrics:

- **Energy density** (LHV/HHV per kg and per volume)
- **Stoichiometric air-fuel ratio**
- **CO₂ intensity** (kg CO₂ per kg fuel and per MJ energy)
- **Adiabatic flame temperature**

> **GESESC use case:** Biofuel evaluation for internal combustion engines.
"""

# ╔═╡ 07000000-0000-0000-0000-000000000003
md"""
## 1. Fuel definitions
"""

# ╔═╡ 07000000-0000-0000-0000-000000000004
begin
    const FUEL_DEFS = [
        ("CH4",     "Methane (NG)",         1, 4, 0, "Fossil"),
        ("C3H8",    "Propane (LPG)",        3, 8, 0, "Fossil"),
        ("CH3OH",   "Methanol",             1, 4, 1, "Biofuel"),
        ("C2H5OH",  "Ethanol",              2, 6, 1, "Biofuel"),
        ("H2",      "Hydrogen",             0, 2, 0, "Renewable"),
    ]
end

# ╔═╡ 07000000-0000-0000-0000-000000000005
md"""
## 2. Analyze all fuels
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
                        nC = nC, nH = nH, nO = nO,
                        LHV_MJkg = LHV_MJkg, LHV_kJmol = LHV / 1000.0,
                        AF_stoich = AF_stoich,
                        CO2_kg_per_kg = CO2_per_kg_fuel,
                        CO2_kg_per_MJ = CO2_per_MJ,
                    ))
                catch e
                    @warn "Error processing $name: $e"
                end
            end
        end
        return results
    end

    fuel_results = analyze_fuels()
end

# ╔═╡ 07000000-0000-0000-0000-000000000007
md"""
## 3. Comparison table
"""

# ╔═╡ 07000000-0000-0000-0000-000000000008
begin
    df = DataFrame(
        Fuel = [r.name for r in fuel_results],
        Category = [r.category for r in fuel_results],
        LHV_MJkg = round.([r.LHV_MJkg for r in fuel_results], digits = 2),
        LHV_kJmol = round.([r.LHV_kJmol for r in fuel_results], digits = 0),
        AF_stoich = round.([r.AF_stoich for r in fuel_results], digits = 1),
        CO2_kg_per_kg = round.([r.CO2_kg_per_kg for r in fuel_results], digits = 2),
        CO2_kg_per_MJ = round.([r.CO2_kg_per_MJ for r in fuel_results], digits = 4),
    )
    sort!(df, :LHV_MJkg, rev = true)
    df
end

# ╔═╡ 07000000-0000-0000-0000-000000000009
md"""
## 4. Analysis

### Key observations:

1. **Energy density (LHV per kg):** Pure hydrocarbons (CH₄, C₃H₈) have higher
   LHV per kg. Oxygenated fuels (methanol, ethanol) have lower LHV per kg.

2. **Air-fuel ratio:** Oxygenated fuels need less air (already contain oxygen).

3. **CO₂ intensity:** Per MJ, methane has the lowest CO₂ intensity among
   fossil fuels. Hydrogen: zero direct CO₂ emissions.

4. **Practical implications:**
   - Ethanol: lower range but reduced fossil dependence
   - Methane: good energy/CO₂ ratio but gaseous storage challenges
   - Hydrogen: ideal environmentally but production/storage challenges
"""

# ╔═╡ 07000000-0000-0000-0000-000000000010
md"""
## Summary

In this notebook you:

- Compared fossil fuels and biofuels using quantitative metrics
- Calculated LHV, air-fuel ratio, and CO₂ intensity
- Interpreted results in combustion engineering context

In the [next notebook](08_equilibrium_gibbs.jl) we explore **chemical
equilibrium** and **Gibbs free energy**.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
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
