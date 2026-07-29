### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 10000000-0000-0000-0000-000000000001
md"""
# 10 — Property Provider for CFD & Chemical Kinetics

This notebook builds an optimized **thermodynamic property provider** for use
in **CFD** (Computational Fluid Dynamics) and **chemical kinetics** codes,
where $C_p(T)$, $H(T)$ and $S(T)$ must be evaluated millions of times.

**Strategy:** Pre-load all polynomial coefficients into memory and implement
vectorized evaluations that avoid database access during execution.

Topics:

1. Batch property tables
2. Cached coefficient provider implementation
3. Performance benchmark
"""

# ╔═╡ 10000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 10000000-0000-0000-0000-000000000003
md"""
## 1. Batch property tables
"""

# ╔═╡ 10000000-0000-0000-0000-000000000004
begin
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
    println("=== Cp Table [J/(mol·K)] — First 10 rows ===")
    show(first(table, 10), allcols = true)
end

# ╔═╡ 10000000-0000-0000-0000-000000000006
md"""
## 2. Cached Coefficient Provider

Ultra-fast property evaluation by pre-loading NASA-7 coefficients:
"""

# ╔═╡ 10000000-0000-0000-0000-000000000007
begin
    struct CachedPropertyProvider
        names::Vector{String}
        name_to_idx::Dict{String, Int}
        n_spec::Int
        intervals::Vector{Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}}
    end

    function CachedPropertyProvider(calc, species_names)
        n_spec = length(species_names)
        names = collect(species_names)
        name_to_idx = Dict(n => i for (i, n) in enumerate(names))

        species_data = []
        for name in names
            sp = only(get_available_species(calc, name, exact_match = true))
            push!(species_data, get_species_data(calc.db, sp.id))
        end

        intervals = Vector{Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}}(undef, n_spec)
        for i in 1:n_spec
            data = species_data[i]
            spec_intervals = Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}()
            for interval in data["intervals"]
                coeffs = interval["coefficients"]
                a = [coeffs["a1"], coeffs["a2"], coeffs["a3"], coeffs["a4"],
                     coeffs["a5"], coeffs["a6"], coeffs["a7"]]
                push!(spec_intervals, (Float64(interval["temp_min"]),
                    Float64(interval["temp_max"]), a, coeffs["b1"], coeffs["b2"]))
            end
            intervals[i] = spec_intervals
        end

        return CachedPropertyProvider(names, name_to_idx, n_spec, intervals)
    end

    function find_interval(provider::CachedPropertyProvider, i_spec::Int, T::Float64)
        for (T_min, T_max, a, b1, b2) in provider.intervals[i_spec]
            if T_min <= T <= T_max
                return a, b1, b2
            end
        end
        error("Temperature $T K out of range for $(provider.names[i_spec])")
    end

    function cp(provider::CachedPropertyProvider, i_spec::Int, T::Float64)
        a, _, _ = find_interval(provider, i_spec, T)
        val = a[1] * T^(-2) + a[2] * T^(-1) + a[3] + a[4] * T +
              a[5] * T^2 + a[6] * T^3 + a[7] * T^4
        return val * Glenn.R_UNIVERSAL
    end

    function h(provider::CachedPropertyProvider, i_spec::Int, T::Float64)
        a, b1, _ = find_interval(provider, i_spec, T)
        val = -a[1] * T^(-2) + a[2] * log(T) / T + a[3] +
              a[4] * T / 2 + a[5] * T^2 / 3 + a[6] * T^3 / 4 +
              a[7] * T^4 / 5 + b1 / T
        return val * Glenn.R_UNIVERSAL * T
    end

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
## 3. Validation & Benchmark
"""

# ╔═╡ 10000000-0000-0000-0000-000000000009
begin
    println("=== Cached Provider Validation ===")
    Calculator() do calc
        species = ["N2", "O2", "CO2", "H2O"]
        provider = CachedPropertyProvider(calc, species)

        for T in [300, 500, 1000, 2000]
            for (i, name) in enumerate(species)
                sp = only(get_available_species(calc, name, exact_match = true))
                api = calculate_properties(calc, sp.id, T)
                err_cp = abs(cp(provider, i, T) - api.cp)
                @assert err_cp < 1e-6 "Cp mismatch for $name at $T K: $err_cp"
            end
        end
        println("✓ All validations passed")

        # Benchmark
        n_eval = 50000
        # Warmup
        for _ in 1:100; for i in 1:4; cp(provider, i, 1000.0); end; end

        t0 = time()
        for _ in 1:n_eval; for i in 1:4; cp(provider, i, 1000.0); end; end
        t_cached = time() - t0

        species_ids = []
        for name in species
            sp = only(get_available_species(calc, name, exact_match = true))
            push!(species_ids, sp.id)
        end

        t0 = time()
        for _ in 1:min(1000, n_eval); for id in species_ids
            calculate_properties(calc, id, 1000.0)
        end; end
        t_api = time() - t0

        println("Cached Provider: $(round(t_cached * 1000, digits=2)) ms ($(n_eval*4) evals)")
        println("Speedup vs API:  $(round(t_api/t_cached * n_eval/1000, digits=1))x")
    end
end

# ╔═╡ 10000000-0000-0000-0000-000000000010
md"""
## Summary

In this notebook you:

- Built batch property tables for species sets
- Implemented a `CachedPropertyProvider` with pre-loaded coefficients
- Validated against the official API
- Measured significant speedup (~10-100x faster than API)

This provider is suitable for integration with CFD solvers and chemical
kinetics codes where property evaluations are the computational bottleneck.

In the [final notebook](11_comparing_sources.jl) we compare different
thermodynamic data sources.

> **Author:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 10000000-0000-0000-0000-000000000011
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
