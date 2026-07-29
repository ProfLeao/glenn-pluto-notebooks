### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 01000000-0000-0000-0000-000000000001
md"""
# 01 — Primeiros Passos com `Glenn.jl`

**`Glenn.jl`** é um calculador de propriedades termoquímicas para Julia que
reconstrói três propriedades molares no estado padrão como funções analíticas
da temperatura,

$$C_p^\circ(T), \qquad H^\circ(T), \qquad S^\circ(T),$$

a partir de **coeficientes polinomiais da NASA** armazenados em um banco de
dados **SQLite** empacotado. O banco de dados acompanha o pacote e contém
aproximadamente **2030 espécies químicas** (gases e fases condensadas)
distribuídas em **3772 intervalos de temperatura**, derivadas do conjunto de
dados `thermo.inp` do NASA Glenn.

Este primeiro caderno cobre os fundamentos:

1. Conexão com o banco de dados empacotado
2. Inspeção do conteúdo do banco de dados
3. Busca por espécies
4. Cálculo de $C_p^\circ$, $H^\circ$ e $S^\circ$ em uma dada temperatura
5. Compreensão dos valores retornados
6. Diferenças de entalpia e tabelas de propriedades
7. Tratamento elegante de erros

> **Autor do pacote:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000002
md"""
## Conteúdo

1. [Conectando ao banco de dados](#1-conectando-ao-banco-de-dados)
2. [Inspecionando o banco de dados](#2-inspecionando-o-banco-de-dados)
3. [Buscando espécies](#3-buscando-espécies)
4. [Calculando propriedades](#4-calculando-propriedades)
5. [Entendendo os valores retornados](#5-entendendo-os-valores-retornados)
6. [Diferenças de entalpia](#6-diferenças-de-entalpia)
7. [Tratamento de erros](#7-tratamento-de-erros)
"""

# ╔═╡ 01000000-0000-0000-0000-000000000003
md"""
## Pré-requisitos

Certifique-se de que os pacotes necessários estão instalados:

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
## 1. Conectando ao banco de dados

O `Calculator()` usa automaticamente o banco de dados `thermo.db` empacotado
com o pacote — **zero configuração**.

A forma recomendada é usar o **bloco `do`** (context manager), que garante o
fechamento automático da conexão:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000006
Calculator() do calc
    println("Conectado com sucesso!")
    println("calc é um objeto Calculator: $(typeof(calc))")
end

# ╔═╡ 01000000-0000-0000-0000-000000000007
md"""
Também é possível abrir e fechar manualmente:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000008
let
    calc = Calculator()
    println("connect: calc conectado")
    close(calc)
    println("close: calc fechado")
end

# ╔═╡ 01000000-0000-0000-0000-000000000009
md"""
## 2. Inspecionando o banco de dados

O objeto de consulta subjacente é exposto como `calc.db` (uma instância de
`ThermoDB`). O método `get_statistics()` fornece uma visão geral rápida do
conjunto de dados.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000010
Calculator() do calc
    stats = Glenn.get_statistics(calc.db)

    println("=== Estatísticas do Banco de Dados ===")
    for (key, value) in stats
        println("  $(rpad(key, 24)): $value")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000011
md"""
O banco contém:
- **2030 espécies** (766 fases condensadas, 1264 gases)
- **3772 intervalos de temperatura**
- **3772 conjuntos de coeficientes** (polinômios NASA-7)
"""

# ╔═╡ 01000000-0000-0000-0000-000000000012
md"""
## 3. Buscando espécies

### Busca por substring

`get_available_species(calc, "padrão")` retorna todas as espécies cujo nome
**contém** o padrão fornecido (case-insensitive):
"""

# ╔═╡ 01000000-0000-0000-0000-000000000013
Calculator() do calc
    species = get_available_species(calc, "CH4")
    println("Busca por \"CH4\" — $(length(species)) resultados:")
    for s in species[1:min(8, end)]
        @printf("  id=%5d  %-20s  phase=%s\n", s.id, s.name, s.phase)
    end
    if length(species) > 8
        println("  ... e mais $(length(species) - 8) resultados")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000014
md"""
### Busca exata (recomendado)

Use `exact_match=true` para busca exata case-insensitive — `"O2"` retorna
apenas O₂, não Al₂O₂ nem Be₃N₂.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000015
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    println("Busca exata \"O2\":")
    @printf("  id=%d  name=%s  formula=%s  phase=%s  MW=%.4f\n",
        o2.id, o2.name,
        something(o2.formula, "—"),
        o2.phase,
        something(o2.molecular_weight, 0.0))
end

# ╔═╡ 01000000-0000-0000-0000-000000000016
md"""
### Navegando por todo o catálogo

Passar uma string vazia pagina por todas as ~2030 espécies. Aqui apenas as
contamos e visualizamos as primeiras.
"""

# ╔═╡ 01000000-0000-0000-0000-000000000017
Calculator() do calc
    all_species = get_available_species(calc)
    println("Total de espécies no catálogo: $(length(all_species))")
    println()
    println("Primeiras 8 (em ordem alfabética):")
    for s in all_species[1:min(8, end)]
        @printf("  %-25s  %s\n", s.name, s.phase)
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000018
md"""
## 4. Calculando propriedades

`calculate_properties(calc, id, T)` retorna um struct `ThermoProperties` com
$C_p$, $H^\circ$ (entalpia relativa) e $S^\circ$ na temperatura $T$ (em Kelvin).

Todas as propriedades são retornadas em **unidades SI**:
- $C_p$, $S^\circ$ → J/(mol·K)
- $H^\circ$ → J/mol
"""

# ╔═╡ 01000000-0000-0000-0000-000000000019
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    props = calculate_properties(calc, o2.id, 1000.0)

    println("=== Propriedades de $(props.species_name) ($(props.phase)) ===")
    println("Temperatura: $(round(props.temperature, digits=2)) K")
    println()
    println("  Cp  = $(round(props.cp, digits=3)) J/(mol·K)")
    println("  H°  = $(round(props.h_relative, digits=1)) J/mol")
    println("  S°  = $(round(props.s, digits=3)) J/(mol·K)")
end

# ╔═╡ 01000000-0000-0000-0000-000000000020
md"""
### Varrendo uma faixa de temperatura

`get_properties_range(calc, id, Ts)` calcula propriedades para múltiplas
temperaturas de uma vez:
"""

# ╔═╡ 01000000-0000-0000-0000-000000000021
Calculator() do calc
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    temps = [300, 500, 800, 1200, 1800, 2500]
    results = get_properties_range(calc, o2.id, temps)

    println("=== O₂ — Propriedades vs Temperatura ===")
    println(rpad("  T [K]", 10), rpad("Cp [J/mol/K]", 18),
            rpad("S [J/mol/K]", 18), rpad("H [kJ/mol]", 15))
    for r in results
        @printf("  %-8.0f  %-16.3f  %-16.3f  %-13.3f\n",
            r.temperature, r.cp, r.s, r.h_relative / 1000.0)
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000022
md"""
## 5. Entendendo os valores retornados

O campo `h_relative` é a **entalpia molar padronizada na escala NASA** — ela
já inclui a entalpia de formação. Consequentemente:

- **Elementos no estado de referência** têm $H^\circ(298.15\,\text{K}) \approx 0$
- **Compostos** têm $H^\circ(298.15\,\text{K})$ igual ao seu $\Delta_f H^\circ$
- Entalpias de reação são simples somas estequiométricas
"""

# ╔═╡ 01000000-0000-0000-0000-000000000023
Calculator() do calc
    # CH4 é um composto: H°(298.15 K) ≈ ΔfH°(CH4)
    ch4 = only(get_available_species(calc, "CH4", exact_match = true))
    props_ch4 = calculate_properties(calc, ch4.id, 298.15)

    # O2 é um elemento de referência: H°(298.15 K) ≈ 0
    o2 = only(get_available_species(calc, "O2", exact_match = true))
    props_o2 = calculate_properties(calc, o2.id, 298.15)

    println("=== Verificação do h_relative a 298.15 K ===")
    @printf("  CH4 (composto):  H° = %12.1f J/mol  (%8.3f kJ/mol)\n",
        props_ch4.h_relative, props_ch4.h_relative / 1000.0)
    @printf("  O2  (elemento):  H° = %12.1f J/mol  (%8.3f kJ/mol)\n",
        props_o2.h_relative, props_o2.h_relative / 1000.0)
end

# ╔═╡ 01000000-0000-0000-0000-000000000024
md"""
## 6. Diferenças de entalpia

`calculate_enthalpy_change(calc, id, T1, T2)` calcula
$\Delta H = H(T_2) - H(T_1)$.

Isso é útil para balanços de energia em processos onde a composição química
não muda (aquecimento/resfriamento sensível).
"""

# ╔═╡ 01000000-0000-0000-0000-000000000025
Calculator() do calc
    co2 = only(get_available_species(calc, "CO2", exact_match = true))

    # Aquecimento de 300 K → 1500 K
    dh = calculate_enthalpy_change(calc, co2.id, 300.0, 1500.0)
    @printf("CO₂: ΔH(300→1500 K) = %.1f J/mol = %.1f kJ/mol\n", dh, dh / 1000.0)

    # Verificação cruzada: H(1500) - H(300)
    p1 = calculate_properties(calc, co2.id, 300.0)
    p2 = calculate_properties(calc, co2.id, 1500.0)
    dh_check = p2.h_relative - p1.h_relative
    @printf("Verificação: H(1500) - H(300) = %.1f J/mol\n", dh_check)
end

# ╔═╡ 01000000-0000-0000-0000-000000000026
md"""
### Entalpia de formação

`calculate_formation_enthalpy(calc, id)` retorna $\Delta_f H^\circ$ a 298.15 K:
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
            @printf("%-6s  ΔH°f(298.15 K) = não disponível\n", name)
        end
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000028
md"""
## 7. Tratamento de erros

Glenn.jl define uma hierarquia de exceções para tratamento elegante de erros:

- `ThermoCalcError` — classe base
- `DatabaseNotConnectedError` — operação sem conexão
- `SpeciesNotFoundError` — espécie não encontrada
- `TemperatureOutOfRangeError` — temperatura fora do intervalo válido
"""

# ╔═╡ 01000000-0000-0000-0000-000000000029
begin
    using Glenn:
        ThermoCalcError,
        DatabaseNotConnectedError,
        SpeciesNotFoundError,
        TemperatureOutOfRangeError

    println("=== Hierarquia de Exceções ===")
    for exc in (DatabaseNotConnectedError, SpeciesNotFoundError, TemperatureOutOfRangeError)
        println("  $(rpad(string(exc), 30)) é um ThermoCalcError? $(exc <: ThermoCalcError)")
    end
end

# ╔═╡ 01000000-0000-0000-0000-000000000030
md"""
### Capturando erros com `try/catch`
"""

# ╔═╡ 01000000-0000-0000-0000-000000000031
begin
    # Espécie inexistente
    calc_test = Calculator()
    try
        get_available_species(calc_test, "XYZ123", exact_match = true)
        println("Não deveria chegar aqui")
    catch e
        if e isa SpeciesNotFoundError
            println("✓ SpeciesNotFoundError capturado: ", e.msg)
        else
            println("Erro inesperado: ", e)
        end
    end

    # Temperatura fora da faixa
    try
        o2_test = only(get_available_species(calc_test, "O2", exact_match = true))
        calculate_properties(calc_test, o2_test.id, 100000.0)
    catch e
        if e isa TemperatureOutOfRangeError
            println("✓ TemperatureOutOfRangeError capturado: ", e.msg)
        else
            println("Erro inesperado: ", e)
        end
    end

    close(calc_test)
end

# ╔═╡ 01000000-0000-0000-0000-000000000032
md"""
## Resumo

Agora você sabe como:

- Conectar ao banco de dados empacotado (preferencialmente via bloco `do`);
- Inspecioná-lo com `get_statistics()`;
- Buscar espécies com `get_available_species()` e resolver nomes exatos;
- Calcular $C_p^\circ$, $S^\circ$ e $H^\circ$ com `calculate_properties()`;
- Varrer faixas de temperatura com `get_properties_range()`;
- Obter $\Delta_f H^\circ$ com `calculate_formation_enthalpy()`;
- Tratar erros com `try/catch` usando a hierarquia `ThermoCalcError`.

No [próximo caderno](02_polinomios_nasa.jl) vamos mergulhar nos **polinômios
da NASA** que alimentam esses cálculos.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 01000000-0000-0000-0000-000000000033
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
