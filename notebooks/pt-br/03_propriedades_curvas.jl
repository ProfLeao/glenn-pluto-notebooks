### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 03000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using Plots
    using DataFrames
end

# ╔═╡ 03000000-0000-0000-0000-000000000001
md"""
# 03 — Curvas de Propriedades Dependentes da Temperatura

Este caderno gera curvas de $C_p^\circ(T)$, $H^\circ(T)$ e $S^\circ(T)$ para
espécies selecionadas e interpreta suas características físicas: **equipartição
de energia**, **excitação vibracional** e o comportamento assintótico a altas
temperaturas.

Vamos usar `Plots.jl` para visualização e `DataFrames.jl` para tabelas.
"""

# ╔═╡ 03000000-0000-0000-0000-000000000003
md"""
## 1. Espécies de interesse

Selecionamos espécies diatômicas e poliatômicas para comparar seus
comportamentos térmicos:
"""

# ╔═╡ 03000000-0000-0000-0000-000000000004
begin
    SPECIES_LIST = [
        ("O2",   "Oxigênio (diatômico)"),
        ("N2",   "Nitrogênio (diatômico)"),
        ("CO2",  "Dióxido de carbono (triatômico)"),
        ("H2O",  "Água (triatômico)"),
        ("CH4",  "Metano (penta-atômico)"),
    ]
end

# ╔═╡ 03000000-0000-0000-0000-000000000005
md"""
## 2. Curvas de $C_p(T)$
"""

# ╔═╡ 03000000-0000-0000-0000-000000000006
begin
    temps = 250:10:3000
    cp_data = Dict{String, Vector{Float64}}()

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            sp = only(get_available_species(calc, name, exact_match = true))
            results = get_properties_range(calc, sp.id, collect(temps))
            cp_data[label] = [r.cp for r in results]
        end
    end

    p_cp = plot(
        title = "Capacidade Calorífica Molar — Cₚ(T)",
        xlabel = "Temperatura [K]",
        ylabel = "Cₚ [J/(mol·K)]",
        legend = :bottomright,
        size = (800, 500),
    )
    for (name, label) in SPECIES_LIST
        plot!(p_cp, temps, cp_data[label], label = label, lw = 2)
    end
    hline!(p_cp, [20.786], linestyle = :dash, color = :gray,
        label = "Gás monoatômico (5/2 R)")
    hline!(p_cp, [29.099], linestyle = :dash, color = :gray50,
        label = "Gás diatômico clássico (7/2 R)")

    p_cp
end

# ╔═╡ 03000000-0000-0000-0000-000000000007
md"""
### Interpretação

- **300 K**: Gases diatômicos (O₂, N₂) têm $C_p \approx 29$ J/(mol·K) =
  $\frac{7}{2}R$ — 3 translações + 2 rotações ativas
- **> 1000 K**: A $C_p$ sobe com a ativação de modos vibracionais
- **Moléculas poliatômicas** (CO₂, H₂O, CH₄) têm mais graus de liberdade →
  $C_p$ maior
- **Assintota**: Em T muito alta, tende ao limite clássico de equipartição
"""

# ╔═╡ 03000000-0000-0000-0000-000000000008
md"""
## 3. Curvas de $S^\circ(T)$
"""

# ╔═╡ 03000000-0000-0000-0000-000000000009
begin
    s_data = Dict{String, Vector{Float64}}()

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            sp = only(get_available_species(calc, name, exact_match = true))
            results = get_properties_range(calc, sp.id, collect(temps))
            s_data[label] = [r.s for r in results]
        end
    end

    p_s = plot(
        title = "Entropia Padrão — S°(T)",
        xlabel = "Temperatura [K]",
        ylabel = "S° [J/(mol·K)]",
        legend = :topleft,
        size = (800, 500),
    )
    for (name, label) in SPECIES_LIST
        plot!(p_s, temps, s_data[label], label = label, lw = 2)
    end

    p_s
end

# ╔═╡ 03000000-0000-0000-0000-000000000010
md"""
### Interpretação

- A entropia sempre cresce com $T$ (Terceira Lei: $S \to 0$ quando $T \to 0$)
- Moléculas maiores têm entropia maior (mais microestados acessíveis)
- CH₄ tem a maior entropia entre as espécies comparadas
"""

# ╔═╡ 03000000-0000-0000-0000-000000000011
md"""
## 4. Curvas de $H^\circ(T)$ (entalpia sensível)
"""

# ╔═╡ 03000000-0000-0000-0000-000000000012
begin
    h_data = Dict{String, Vector{Float64}}()

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            sp = only(get_available_species(calc, name, exact_match = true))
            results = get_properties_range(calc, sp.id, collect(temps))
            h_data[label] = [(r.h_relative - calculate_properties(calc, sp.id, 298.15).h_relative) / 1000.0 for r in results]
        end
    end

    p_h = plot(
        title = "Entalpia Sensível — H°(T) - H°(298.15)",
        xlabel = "Temperatura [K]",
        ylabel = "ΔH [kJ/mol]",
        legend = :topleft,
        size = (800, 500),
    )
    for (name, label) in SPECIES_LIST
        plot!(p_h, temps, h_data[label], label = label, lw = 2)
    end

    p_h
end

# ╔═╡ 03000000-0000-0000-0000-000000000013
md"""
### Interpretação

- A curvatura positiva reflete o aumento de $C_p$ com $T$
- Moléculas poliatômicas acumulam mais entalpia (maior $C_p$)
- Essas curvas são essenciais para balanços de energia em processos de combustão
"""

# ╔═╡ 03000000-0000-0000-0000-000000000014
md"""
## 5. Tabela de propriedades com DataFrames.jl
"""

# ╔═╡ 03000000-0000-0000-0000-000000000015
begin
    prop_table = DataFrame()
    prop_table.T_K = Float64[]

    Calculator() do calc
        for (name, label) in SPECIES_LIST
            col_name = name * " (J/mol/K)"
            prop_table[!, col_name] = Float64[]

            selected_temps = [300, 400, 500, 600, 800, 1000, 1500, 2000]
            for (i, T) in enumerate(selected_temps)
                sp = only(get_available_species(calc, name, exact_match = true))
                props = calculate_properties(calc, sp.id, T)
                if name == SPECIES_LIST[1][1]
                    push!(prop_table.T_K, T)
                end
                push!(prop_table[!, col_name], props.cp)
            end
        end
    end

    prop_table
end

# ╔═╡ 03000000-0000-0000-0000-000000000016
md"""
## Resumo

Neste caderno você:

- Gerou curvas de $C_p(T)$, $S^\circ(T)$ e $H^\circ(T)$ para várias espécies
- Interpretou as características físicas: equipartição, vibração, comportamento assintótico
- Criou tabelas de propriedades com DataFrames.jl

No [próximo caderno](04_entalpia_formacao.jl) vamos explorar como obter a
**entalpia de formação** a partir dos polinômios da NASA.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 03000000-0000-0000-0000-000000000017
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═03000000-0000-0000-0000-000000000001
# ╠═03000000-0000-0000-0000-000000000002
# ╠═03000000-0000-0000-0000-000000000003
# ╠═03000000-0000-0000-0000-000000000004
# ╠═03000000-0000-0000-0000-000000000005
# ╠═03000000-0000-0000-0000-000000000006
# ╠═03000000-0000-0000-0000-000000000007
# ╠═03000000-0000-0000-0000-000000000008
# ╠═03000000-0000-0000-0000-000000000009
# ╠═03000000-0000-0000-0000-000000000010
# ╠═03000000-0000-0000-0000-000000000011
# ╠═03000000-0000-0000-0000-000000000012
# ╠═03000000-0000-0000-0000-000000000013
# ╠═03000000-0000-0000-0000-000000000014
# ╠═03000000-0000-0000-0000-000000000015
# ╠═03000000-0000-0000-0000-000000000016
# ╠═03000000-0000-0000-0000-000000000017
