### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 07000000-0000-0000-0000-000000000001
md"""
# 07 — Comparação de Combustíveis e Biocombustíveis

Este caderno compara sistematicamente combustíveis convencionais e
biocombustíveis usando métricas termodinâmicas e ambientais:

- **Densidade energética** (PCI/PCS por kg e por volume)
- **Razão ar-combustível estequiométrica**
- **Intensidade de CO₂** (kg CO₂ por kg de combustível e por MJ de energia)
- **Temperatura de chama adiabática**

> **Caso de uso GESESC:** Avaliação de biocombustíveis para motores de
> combustão interna.
"""

# ╔═╡ 07000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 07000000-0000-0000-0000-000000000003
md"""
## 1. Definições dos combustíveis
"""

# ╔═╡ 07000000-0000-0000-0000-000000000004
begin
    # (nome_especie, nome_exibicao, nC, nH, nO, categoria)
    const FUEL_DEFS = [
        ("CH4",     "Metano (GN)",          1, 4, 0, "Fóssil"),
        ("C3H8",    "Propano (GLP)",        3, 8, 0, "Fóssil"),
        ("CH3OH",   "Metanol",              1, 4, 1, "Biocombustível"),
        ("C2H5OH",  "Etanol",               2, 6, 1, "Biocombustível"),
        ("H2",      "Hidrogênio",           0, 2, 0, "Renovável"),
    ]
end

# ╔═╡ 07000000-0000-0000-0000-000000000005
md"""
## 2. Cálculo de métricas para cada combustível
"""

# ╔═╡ 07000000-0000-0000-0000-000000000006
begin
    function analyze_fuels()
        results = []
        MW_O2 = 31.9988   # g/mol
        MW_CO2 = 44.0095  # g/mol

        Calculator() do calc
            for (name, label, nC, nH, nO, cat) in FUEL_DEFS
                try
                    sp = only(get_available_species(calc, name, exact_match = true))
                    MW = something(sp.molecular_weight, 0.0)

                    # Estequiometria
                    nO2_stoich = nC + nH/4 - nO/2
                    AF_stoich = (nO2_stoich * MW_O2 + nO2_stoich * 3.76 * 28.0134) / MW  # kg ar / kg comb

                    # Poder calorífico
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
                    LHV = -ΔrH  # J/mol comb

                    # CO2 produzido por kg de combustível
                    CO2_per_kg_fuel = (nC * MW_CO2) / (MW / 1000.0)  # g_CO2 / g_fuel → kg_CO2 / kg_fuel

                    # CO2 por MJ
                    LHV_MJkg = LHV / MW * 1000.0 / 1e6  # MJ/kg
                    CO2_per_MJ = CO2_per_kg_fuel / LHV_MJkg  # kg_CO2 / MJ

                    push!(results, (
                        name = label,
                        category = cat,
                        MW_gmol = MW,
                        nC = nC, nH = nH, nO = nO,
                        LHV_MJkg = LHV_MJkg,
                        LHV_kJmol = LHV / 1000.0,
                        AF_stoich = AF_stoich,
                        CO2_kg_per_kg = CO2_per_kg_fuel,
                        CO2_kg_per_MJ = CO2_per_MJ,
                    ))
                catch e
                    @warn "Erro ao processar $name: $e"
                end
            end
        end
        return results
    end

    fuel_results = analyze_fuels()
end

# ╔═╡ 07000000-0000-0000-0000-000000000007
md"""
## 3. Tabela comparativa
"""

# ╔═╡ 07000000-0000-0000-0000-000000000008
begin
    df = DataFrame(
        Combustível = [r.name for r in fuel_results],
        Categoria = [r.category for r in fuel_results],
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
## 4. Análise
"""

# ╔═╡ 07000000-0000-0000-0000-000000000010
md"""
### Principais observações:

1. **Densidade energética (LHV por kg):**
   - Hidrocarbonetos puros (CH₄, C₃H₈) têm maior LHV por kg
   - Oxigenados (metanol, etanol) têm LHV por kg menor (o oxigênio na molécula "dilui" a energia)

2. **Razão ar-combustível:**
   - Combustíveis oxigenados precisam de menos ar (já contêm oxigênio)
   - Isso afeta o dimensionamento de sistemas de admissão

3. **Intensidade de CO₂:**
   - Biocombustíveis emitem CO₂ biogênico (ciclo curto do carbono)
   - Por MJ, o metano tem a menor intensidade de CO₂ entre os fósseis
   - Hidrogênio: zero emissão direta de CO₂

4. **Implicações práticas:**
   - Etanol: menor autonomia (menos energia/kg), mas menor dependência fóssil
   - Metano: boa relação energia/CO₂, mas é gás (armazenamento)
   - Hidrogênio: ideal ambientalmente, mas desafios de produção e armazenamento
"""

# ╔═╡ 07000000-0000-0000-0000-000000000011
md"""
## Resumo

Neste caderno você:

- Comparou combustíveis fósseis e biocombustíveis usando métricas quantitativas
- Calculou PCI (LHV), razão ar-combustível e intensidade de CO₂
- Interpretou os resultados no contexto de engenharia de combustão

No [próximo caderno](08_equilibrio_quimico.jl) vamos explorar o **equilíbrio
químico** e a **energia livre de Gibbs**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 07000000-0000-0000-0000-000000000012
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
