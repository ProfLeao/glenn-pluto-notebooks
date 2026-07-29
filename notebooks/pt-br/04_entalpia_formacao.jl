### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 04000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 04000000-0000-0000-0000-000000000001
md"""
# 04 — Entalpia de Formação a partir dos Polinômios da NASA

Este caderno mostra como obter a **entalpia de formação padrão**
$\Delta_f H^\circ$ a partir dos dados armazenados no banco de dados do
Glenn.jl.

**Conceito fundamental:** Na escala NASA, a entalpia padronizada
$H^\circ(T)$ (campo `h_relative`) já **inclui a entalpia de formação**.
Portanto:

- Para um **elemento no estado de referência** (ex: O₂, N₂, H₂, C(graf)):
  $H^\circ(298.15\,\text{K}) \approx 0$
- Para um **composto** (ex: CH₄, CO₂, H₂O):
  $H^\circ(298.15\,\text{K}) = \Delta_f H^\circ(298.15\,\text{K})$
"""

# ╔═╡ 04000000-0000-0000-0000-000000000003
md"""
## 1. Obtendo $\Delta_f H^\circ$ diretamente

`calculate_formation_enthalpy(calc, id)` retorna a entalpia de formação a
298.15 K:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000004
Calculator() do calc
    println("=== Entalpias de Formação Padrão ===")
    println(rpad("Espécie", 10), rpad("ΔfH°(298.15 K) [kJ/mol]", 28), "Fonte")
    println("—"^55)

    for (name, desc) in [
        ("CH4", "metano"),
        ("C2H5OH", "etanol"),
        ("CO2", "dióxido de carbono"),
        ("H2O", "água (gás)"),
        ("O2", "elemento referência"),
        ("N2", "elemento referência"),
        ("H2", "elemento referência"),
        ("C", "carbono (grafite)"),
    ]
        sp = only(get_available_species(calc, name, exact_match = true))
        h_f = calculate_formation_enthalpy(calc, sp.id)
        if h_f !== nothing
            @printf("%-10s %12.1f kJ/mol               %s\n",
                name, h_f / 1000.0, desc)
        else
            @printf("%-10s %12s                       %s\n",
                name, "N/D", desc)
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000005
md"""
## 2. Obtendo $\Delta_f H^\circ$ via `h_relative`

Como o campo `heat_of_formation_298K` pode não estar populado no banco de
dados, o método alternativo é usar `h_relative` a 298.15 K:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000006
begin
    """
        formation_enthalpy_from_h_relative(calc, name)

    Obtém ΔfH° a partir de h_relative a 298.15 K.
    Retorna (ΔfH°, valor de h_relative, valor da API).
    """
    function formation_enthalpy_from_h_relative(calc, name)
        sp = only(get_available_species(calc, name, exact_match = true))
        props = calculate_properties(calc, sp.id, 298.15)
        h_f_api = calculate_formation_enthalpy(calc, sp.id)
        return props.h_relative, h_f_api
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000007
Calculator() do calc
    println("=== Comparação: h_relative vs API ===")
    println(rpad("Espécie", 10), rpad("h_relative(298.15)", 22),
            rpad("API ΔfH°", 18), rpad("Diferença", 16))
    println("—"^66)

    for name in ["CH4", "CO2", "H2O", "C2H5OH", "O2", "N2"]
        sp = only(get_available_species(calc, name, exact_match = true))
        props = calculate_properties(calc, sp.id, 298.15)
        h_f_api = calculate_formation_enthalpy(calc, sp.id)

        if h_f_api !== nothing
            diff = props.h_relative - h_f_api
            @printf("%-10s %18.1f J/mol  %14.1f  %14.1f\n",
                name, props.h_relative, h_f_api, diff)
        else
            @printf("%-10s %18.1f J/mol  %14s  %14s\n",
                name, props.h_relative, "N/D", "—")
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000008
md"""
## 3. Validação contra valores da literatura

Comparamos os valores obtidos com entalpias de formação padrão da literatura:
"""

# ╔═╡ 04000000-0000-0000-0000-000000000009
begin
    # Valores de referência da literatura [kJ/mol] a 298.15 K
    const LITERATURE_VALUES = Dict(
        "CH4"    => -74.87,
        "CO2"    => -393.51,
        "H2O"    => -241.83,  # gás
        "C2H5OH" => -234.8,
        "O2"     => 0.0,
        "N2"     => 0.0,
    )
end

# ╔═╡ 04000000-0000-0000-0000-000000000010
Calculator() do calc
    println("=== Validação contra Literatura ===")
    println(rpad("Espécie", 10), rpad("Glenn.jl", 16),
            rpad("Literatura", 16), rpad("Erro Rel.", 14))
    println("—"^56)

    for name in ["CH4", "CO2", "H2O", "C2H5OH", "O2", "N2"]
        sp = only(get_available_species(calc, name, exact_match = true))
        h_f = calculate_formation_enthalpy(calc, sp.id)

        if h_f !== nothing && haskey(LITERATURE_VALUES, name)
            lit = LITERATURE_VALUES[name] * 1000.0  # kJ → J
            err_pct = (h_f - lit) / abs(lit) * 100.0
            @printf("%-10s %12.1f J/mol  %12.1f J/mol  %+8.3f %%\n",
                name, h_f, lit, err_pct)
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000011
md"""
## 4. Aplicação: calculando $\Delta_f H^\circ$ para biocombustíveis
"""

# ╔═╡ 04000000-0000-0000-0000-000000000012
Calculator() do calc
    biofuels = [
        ("CH3OH",     "Metanol"),
        ("C2H5OH",    "Etanol"),
        ("CH3COOH",   "Ácido acético"),
    ]

    println("=== Entalpias de Formação — Biocombustíveis ===")
    println(rpad("Espécie", 12), rpad("Nome", 18),
            rpad("ΔfH° [kJ/mol]", 18), "Fase")
    println("—"^56)

    for (formula, name) in biofuels
        try
            sp = only(get_available_species(calc, formula, exact_match = true))
            h_f = calculate_formation_enthalpy(calc, sp.id)
            if h_f !== nothing
                @printf("%-12s %-18s %+12.1f kJ/mol     %s\n",
                    formula, name, h_f / 1000.0, sp.phase)
            end
        catch e
            @printf("%-12s %-18s %s\n", formula, name, "não encontrado")
        end
    end
end

# ╔═╡ 04000000-0000-0000-0000-000000000013
md"""
## Resumo

Neste caderno você aprendeu:

- Que `h_relative` a 298.15 K = $\Delta_f H^\circ$ para compostos
- Que `calculate_formation_enthalpy()` é o método direto recomendado
- A validar valores contra a literatura
- A importância da entalpia de formação para cálculos de reação

No [próximo caderno](05_entalpias_reacao.jl) vamos usar esses valores para
calcular **entalpias de reação** e **calores de combustão**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 04000000-0000-0000-0000-000000000014
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═04000000-0000-0000-0000-000000000001
# ╠═04000000-0000-0000-0000-000000000002
# ╠═04000000-0000-0000-0000-000000000003
# ╠═04000000-0000-0000-0000-000000000004
# ╠═04000000-0000-0000-0000-000000000005
# ╠═04000000-0000-0000-0000-000000000006
# ╠═04000000-0000-0000-0000-000000000007
# ╠═04000000-0000-0000-0000-000000000008
# ╠═04000000-0000-0000-0000-000000000009
# ╠═04000000-0000-0000-0000-000000000010
# ╠═04000000-0000-0000-0000-000000000011
# ╠═04000000-0000-0000-0000-000000000012
# ╠═04000000-0000-0000-0000-000000000013
# ╠═04000000-0000-0000-0000-000000000014
