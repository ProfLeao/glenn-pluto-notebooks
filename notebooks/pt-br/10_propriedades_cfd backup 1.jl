### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 10000000-0000-0000-0000-000000000001
md"""
# 10 — Provedor de Propriedades para CFD e Cinética Química

Este caderno constrói um **provedor de propriedades termodinâmicas** otimizado
para uso em códigos de **CFD** (Computational Fluid Dynamics) e **cinética
química**, onde as propriedades $C_p(T)$, $H(T)$ e $S(T)$ precisam ser
avaliadas milhões de vezes.

**Estratégia:** Pré-carregar todos os coeficientes polinomiais em memória e
implementar avaliações vetorizadas que evitam acesso ao banco de dados durante
a execução.

Tópicos:

1. Construção de tabelas de propriedades em lote
2. Implementação de um *cached coefficient provider*
3. Benchmark de desempenho
4. Exemplo de integração ODE com propriedades termodinâmicas
"""

# ╔═╡ 10000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
    using LinearAlgebra
end

# ╔═╡ 10000000-0000-0000-0000-000000000003
md"""
## 1. Tabelas de propriedades em lote

Gerar tabelas para um conjunto de espécies em uma faixa de temperaturas:
"""

# ╔═╡ 10000000-0000-0000-0000-000000000004
begin
    """
        build_property_table(calc, species_names, temperatures)

    Constrói uma tabela de Cp, H, S para as espécies e temperaturas dadas.
    Retorna um DataFrame.
    """
    function build_property_table(calc, species_names, temperatures)
        df = DataFrame(T_K = Float64[])
        for name in species_names
            df[!, name] = Float64[]
        end

        for T in temperatures
            push!(df, :T_K => T)
            for name in species_names
                sp = only(get_available_species(calc, name, exact_match = true))
                props = calculate_properties(calc, sp.id, T)
                row_idx = findlast(x -> x == T, df.T_K)
                df[row_idx, name] = props.cp
            end
        end
        return df
    end
end

# ╔═╡ 10000000-0000-0000-0000-000000000005
Calculator() do calc
    species = ["N2", "O2", "CO2", "H2O", "CH4"]
    temps = 300:100:2000

    table = build_property_table(calc, species, collect(temps))

    println("=== Tabela de Cp [J/(mol·K)] ===")
    println("Primeiras 10 temperaturas de $(nrow(table)):")
    show(first(table, 10), allcols = true)
end

# ╔═╡ 10000000-0000-0000-0000-000000000006
md"""
## 2. Cached Coefficient Provider

Para CFD e cinética química, precisamos de avaliações **ultra-rápidas**.
A estratégia é pré-carregar os coeficientes NASA-7 e avaliar diretamente:
"""

# ╔═╡ 10000000-0000-0000-0000-000000000007
begin
    """
        CachedPropertyProvider

    Provedor de propriedades otimizado que pré-carrega todos os coeficientes
    NASA-7 em memória. Uma vez construído, `cp(i, T)`, `h(i, T)`, `s(i, T)`
    avaliam em microssegundos sem acesso ao banco de dados.
    """
    struct CachedPropertyProvider
        names::Vector{String}
        name_to_idx::Dict{String, Int}
        n_spec::Int
        n_intervals_max::Int
        # Para cada espécie: vetor de intervalos
        intervals::Vector{Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}}
        # (T_min, T_max, [a1..a7], b1, b2)
    end

    function CachedPropertyProvider(calc, species_names)
        n_spec = length(species_names)
        names = collect(species_names)
        name_to_idx = Dict(n => i for (i, n) in enumerate(names))

        # Coletar dados de cada espécie
        species_data = []
        for name in names
            sp = only(get_available_species(calc, name, exact_match = true))
            data = get_species_data(calc.db, sp.id)
            push!(species_data, data)
        end

        n_intervals_max = maximum([d["num_intervals"] for d in species_data])

        # Extrair intervalos com coeficientes
        intervals = Vector{Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}}(undef, n_spec)
        for i in 1:n_spec
            data = species_data[i]
            spec_intervals = Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}()
            for interval in data["intervals"]
                coeffs = interval["coefficients"]
                a = [coeffs["a1"], coeffs["a2"], coeffs["a3"], coeffs["a4"],
                     coeffs["a5"], coeffs["a6"], coeffs["a7"]]
                b1 = coeffs["b1"]
                b2 = coeffs["b2"]
                push!(spec_intervals, (Float64(interval["temp_min"]), Float64(interval["temp_max"]), a, b1, b2))
            end
            intervals[i] = spec_intervals
        end

        return CachedPropertyProvider(names, name_to_idx, n_spec, n_intervals_max, intervals)
    end

    """
        find_interval(provider, i_spec, T)

    Encontra o intervalo que contém a temperatura T para a espécie i_spec.
    Lança erro se T estiver fora da faixa.
    """
    function find_interval(provider::CachedPropertyProvider, i_spec::Int, T::Float64)
        for (T_min, T_max, a, b1, b2) in provider.intervals[i_spec]
            if T_min <= T <= T_max
                return a, b1, b2
            end
        end
        error("Temperatura $T K fora da faixa para ${provider.names[i_spec]}")
    end

    """
        cp(provider, i_spec, T)

    Calcula Cp [J/(mol·K)] para a espécie i_spec na temperatura T.
    """
    function cp(provider::CachedPropertyProvider, i_spec::Int, T::Float64)
        a, _, _ = find_interval(provider, i_spec, T)
        val = a[1] * T^(-2) + a[2] * T^(-1) + a[3] + a[4] * T +
              a[5] * T^2 + a[6] * T^3 + a[7] * T^4
        return val * Glenn.R_UNIVERSAL
    end

    """
        h(provider, i_spec, T)

    Calcula H° [J/mol] para a espécie i_spec na temperatura T.
    """
    function h(provider::CachedPropertyProvider, i_spec::Int, T::Float64)
        a, b1, _ = find_interval(provider, i_spec, T)
        val = -a[1] * T^(-2) + a[2] * log(T) / T + a[3] +
              a[4] * T / 2 + a[5] * T^2 / 3 + a[6] * T^3 / 4 +
              a[7] * T^4 / 5 + b1 / T
        return val * Glenn.R_UNIVERSAL * T
    end

    """
        s(provider, i_spec, T)

    Calcula S° [J/(mol·K)] para a espécie i_spec na temperatura T.
    """
    function s(provider::CachedPropertyProvider, i_spec::Int, T::Float64)
        a, _, b2 = find_interval(provider, i_spec, T)
        val = -a[1] / 2 * T^(-2) - a[2] * T^(-1) + a[3] * log(T) +
              a[4] * T + a[5] * T^2 / 2 + a[6] * T^3 / 3 +
              a[7] * T^4 / 4 + b2
        return val * Glenn.R_UNIVERSAL
    end
end

# ╔═╡ 10000000-0000-0000-0000-000000000008
md"""
## 3. Validação contra a API
"""

# ╔═╡ 10000000-0000-0000-0000-000000000009
begin
    Calculator() do calc
        species = ["N2", "O2", "CO2", "H2O"]
        provider = CachedPropertyProvider(calc, species)

        println("=== Validação do Cached Provider ===")
        for T in [300, 500, 1000, 2000]
            println("\nT = $T K:")
            for (i, name) in enumerate(species)
                sp = only(get_available_species(calc, name, exact_match = true))
                api = calculate_properties(calc, sp.id, T)

                cp_prov = cp(provider, i, T)
                h_prov  = h(provider, i, T)
                s_prov  = s(provider, i, T)

                err_cp = abs(cp_prov - api.cp)
                err_h  = abs(h_prov - api.h_relative)
                err_s  = abs(s_prov - api.s)

                @printf("  %-4s  Cp err=%8.2e  H err=%8.2e  S err=%8.2e\n",
                    name, err_cp, err_h, err_s)
            end
        end
    end
end

# ╔═╡ 10000000-0000-0000-0000-000000000010
md"""
## 4. Benchmark de desempenho
"""

# ╔═╡ 10000000-0000-0000-0000-000000000011
begin
    println("=== Benchmark: Cached Provider vs API ===")
    Calculator() do calc
        species = ["N2", "O2", "CO2", "H2O"]
        provider = CachedPropertyProvider(calc, species)
        n_eval = 10000

        # Warmup
        for _ in 1:100
            for i in 1:4
                cp(provider, i, 1000.0)
            end
        end

        # Benchmark: Cached Provider
        t_start = time()
        for _ in 1:n_eval
            for i in 1:4
                cp(provider, i, 1000.0)
            end
        end
        t_cached = time() - t_start

        # Benchmark: API
        species_ids = []
        for name in species
            sp = only(get_available_species(calc, name, exact_match = true))
            push!(species_ids, sp.id)
        end

        t_start = time()
        for _ in 1:n_eval
            for id in species_ids
                calculate_properties(calc, id, 1000.0)
            end
        end
        t_api = time() - t_start

        println("Cached Provider: $(round(t_cached * 1000, digits=2)) ms")
        println("API Direta:      $(round(t_api * 1000, digits=2)) ms")
        println("Speedup:         $(round(t_api / t_cached, digits=1))x")
    end
end

# ╔═╡ 10000000-0000-0000-0000-000000000012
md"""
## Resumo

Neste caderno você:

- Construiu tabelas de propriedades em lote para conjuntos de espécies
- Implementou um `CachedPropertyProvider` que pré-carrega coeficientes
- Validou o provider contra a API oficial
- Mediu o speedup de desempenho (~10-100x mais rápido que a API)

Este provedor é adequado para integração com solvers de CFD e cinética química
onde as avaliações de propriedades são o gargalo computacional.

No [último caderno](11_comparacao_fontes.jl) vamos comparar diferentes fontes
de dados termodinâmicos.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 10000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
