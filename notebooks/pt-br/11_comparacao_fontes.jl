### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 11000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 11000000-0000-0000-0000-000000000001
md"""
# 11 — Comparação de Fontes de Dados Termodinâmicos

Este caderno compara os valores de propriedades termodinâmicas obtidos de
diferentes fontes:

1. **Glenn.jl** — Polinômios NASA-7 (banco de dados `thermo.inp` do NASA Glenn)
2. **NIST-JANAF** — Tabelas termoquímicas de referência (Chase, 1998)
3. **Tabelas convencionais** — Valores tabulados de livros-texto

O objetivo é quantificar as discrepâncias entre as fontes e entender quando
cada uma é apropriada.

> **Nota:** O Glenn.jl já foi validado contra NIST-JANAF para 7 espécies
> (CO₂, N₂, CO, H₂O, O₂, NH₃, SO₂) no script `docs/audit/audit.jl`.
"""

# ╔═╡ 11000000-0000-0000-0000-000000000003
md"""
## 1. Valores de referência da literatura

Selecionamos valores de $C_p^\circ$, $S^\circ$ e $\Delta_f H^\circ$ da
literatura para comparação:
"""

# ╔═╡ 11000000-0000-0000-0000-000000000004
begin
    # Referência: NIST-JANAF / livros-texto padrão
    # Formato: espécie => (Cp [J/(mol·K)], S° [J/(mol·K)], ΔfH° [kJ/mol]) a 298.15 K
    const REFERENCE_DATA = Dict(
        "O2"  => (29.376, 205.152, 0.0),
        "N2"  => (29.124, 191.609, 0.0),
        "CO2" => (37.135, 213.795, -393.51),
        "H2O" => (33.590, 188.835, -241.83),
        "CH4" => (35.700, 186.251, -74.87),
        "CO"  => (29.142, 197.660, -110.53),
    )
end

# ╔═╡ 11000000-0000-0000-0000-000000000005
md"""
## 2. Comparação lado a lado
"""

# ╔═╡ 11000000-0000-0000-0000-000000000006
begin
    T_ref = 298.15

    comparison_results = []

    Calculator() do calc
        for (name, (cp_ref, s_ref, hf_ref)) in REFERENCE_DATA
            try
                sp = only(get_available_species(calc, name, exact_match = true))
                props = calculate_properties(calc, sp.id, T_ref)

                # Cp
                cp_glenn = props.cp
                cp_err_pct = (cp_glenn - cp_ref) / cp_ref * 100.0

                # S
                s_glenn = props.s
                s_err_pct = (s_glenn - s_ref) / s_ref * 100.0

                # ΔfH° via h_relative
                hf_glenn = props.h_relative / 1000.0  # J → kJ
                hf_api = calculate_formation_enthalpy(calc, sp.id)
                hf_api_kJ = hf_api !== nothing ? hf_api / 1000.0 : NaN

                push!(comparison_results, (
                    name = name,
                    cp_ref = cp_ref, cp_glenn = cp_glenn, cp_err = cp_err_pct,
                    s_ref = s_ref, s_glenn = s_glenn, s_err = s_err_pct,
                    hf_ref = hf_ref, hf_glenn = hf_glenn, hf_api = hf_api_kJ,
                ))
            catch e
                @warn "Erro ao processar $name: $e"
            end
        end
    end

    # Criar DataFrame
    df_comp = DataFrame(
        Espécie = [r.name for r in comparison_results],
        Cp_ref = [r.cp_ref for r in comparison_results],
        Cp_glenn = round.([r.cp_glenn for r in comparison_results], digits = 3),
        Cp_err_pct = round.([r.cp_err for r in comparison_results], digits = 3),
        S_ref = [r.s_ref for r in comparison_results],
        S_glenn = round.([r.s_glenn for r in comparison_results], digits = 3),
        S_err_pct = round.([r.s_err for r in comparison_results], digits = 3),
        Hf_ref_kJ = [r.hf_ref for r in comparison_results],
        Hf_h_relative_kJ = round.([r.hf_glenn for r in comparison_results], digits = 2),
    )

    println("=== Comparação Glenn.jl vs Literatura (T = $T_ref K) ===")
    println()
    println("Cp [J/(mol·K)]:")
    show(select(df_comp, :Espécie, :Cp_ref, :Cp_glenn, :Cp_err_pct), allcols = true)
    println()
    println("S° [J/(mol·K)]:")
    show(select(df_comp, :Espécie, :S_ref, :S_glenn, :S_err_pct), allcols = true)
    println()
    println("ΔfH° [kJ/mol]:")
    show(select(df_comp, :Espécie, :Hf_ref_kJ, :Hf_h_relative_kJ), allcols = true)
end

# ╔═╡ 11000000-0000-0000-0000-000000000007
md"""
## 3. Análise das discrepâncias
"""

# ╔═╡ 11000000-0000-0000-0000-000000000008
md"""
### Origens das diferenças:

1. **Conjunto de dados base**: O NASA Glenn usa o conjunto `thermo.inp`, enquanto
   o NIST-JANAF usa a equação de Shomate com coeficientes ajustados
   independentemente

2. **Método de ajuste**: Os polinômios NASA-7 são ajustes *piecewise* com
   continuidade $C^1$ nas emendas; os ajustes Shomate/NIST podem usar
   metodologias diferentes

3. **Atualizações**: Os valores de referência da NASA Glenn podem ser de uma
   versão diferente das tabelas NIST-JANAF mais recentes

4. **Diferenças típicas**:
   - $C_p$: < 0.5% para a maioria das espécies
   - $S^\circ$: < 0.2% para a maioria das espécies
   - $\Delta_f H^\circ$: < 1% para compostos comuns

Para a maioria das aplicações de engenharia (combustão, ciclos, CFD), as
diferenças são **desprezíveis** comparadas a outras incertezas do modelo.
"""

# ╔═╡ 11000000-0000-0000-0000-000000000009
md"""
## 4. Quando usar cada fonte

| Aplicação | Fonte Recomendada |
|-----------|------------------|
| Cálculos de engenharia (combustão, ciclos) | Glenn.jl / NASA-7 |
| Validação de alta precisão | NIST-JANAF (Shomate) |
| Ensino e didática | Glenn.jl (simples, sem dependências) |
| CFD e cinética química | Glenn.jl (rápido, programático) |
| Publicações científicas | Cross-check NASA + NIST |
"""

# ╔═╡ 11000000-0000-0000-0000-000000000010
md"""
## Resumo

Neste caderno você:

- Comparou Glenn.jl (NASA-7) com valores de referência da literatura
- Quantificou as discrepâncias (< 1% para a maioria das propriedades)
- Entendeu as origens das diferenças entre bases de dados
- Aprendeu recomendações sobre qual fonte usar em cada contexto

---

Este foi o último caderno da série. Os 11 cadernos cobrem desde os fundamentos
de conexão ao banco de dados até aplicações avançadas em CFD e comparação de
fontes de dados.

**Esperamos que este material seja útil para seu aprendizado e pesquisa!**

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 11000000-0000-0000-0000-000000000011
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═11000000-0000-0000-0000-000000000001
# ╠═11000000-0000-0000-0000-000000000002
# ╠═11000000-0000-0000-0000-000000000003
# ╠═11000000-0000-0000-0000-000000000004
# ╠═11000000-0000-0000-0000-000000000005
# ╠═11000000-0000-0000-0000-000000000006
# ╠═11000000-0000-0000-0000-000000000007
# ╠═11000000-0000-0000-0000-000000000008
# ╠═11000000-0000-0000-0000-000000000009
# ╠═11000000-0000-0000-0000-000000000010
# ╠═11000000-0000-0000-0000-000000000011
