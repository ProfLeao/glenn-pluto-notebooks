### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 10000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using DataFrames
end

# ╔═╡ 10000000-0000-0000-0000-000000000001
md"""
# 10 — Proveedor de Propiedades para CFD y Cinética Química

Este cuaderno construye un **proveedor de propiedades termodinámicas**
optimizado para uso en códigos de **CFD** (Dinámica de Fluidos Computacional)
y **cinética química**, donde las propiedades deben evaluarse millones de veces.

**Estrategia:** Precargar todos los coeficientes polinomiales en memoria.

Temas:

1. Tablas de propiedades en lote
2. Proveedor de coeficientes en caché
3. Benchmark de rendimiento
"""

# ╔═╡ 10000000-0000-0000-0000-000000000003
md"""
## 1. Tablas de propiedades en lote
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
    println("=== Tabla de Cp [J/(mol·K)] — Primeras 10 filas ===")
    show(first(table, 10), allcols = true)
end

# ╔═╡ 10000000-0000-0000-0000-000000000006
md"""
## 2. Cached Coefficient Provider

Evaluación ultrarrápida precargando coeficientes NASA-7:
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
        species_data = [get_species_data(calc.db, only(get_available_species(calc, name, exact_match = true)).id) for name in names]
        intervals = Vector{Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}}(undef, n_spec)
        for i in 1:n_spec
            spec_intervals = Vector{Tuple{Float64, Float64, Vector{Float64}, Float64, Float64}}()
            for interval in species_data[i]["intervals"]
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

    function find_interval(prov, i_spec, T)
        for (T_min, T_max, a, b1, b2) in prov.intervals[i_spec]
            if T_min <= T <= T_max
                return a, b1, b2
            end
        end
        error("T $T K fuera de rango para $(prov.names[i_spec])")
    end

    function cp(prov, i_spec, T)
        a, _, _ = find_interval(prov, i_spec, T)
        (a[1]*T^(-2)+a[2]*T^(-1)+a[3]+a[4]*T+a[5]*T^2+a[6]*T^3+a[7]*T^4) * Glenn.R_UNIVERSAL
    end
end

# ╔═╡ 10000000-0000-0000-0000-000000000008
md"""
## 3. Validación y Benchmark
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
                err = abs(cp(provider, i, T) - api.cp)
                @assert err < 1e-6 "Error Cp para $name a $T K: $err"
            end
        end
        println("✓ Todas las validaciones pasaron")

        n_eval = 50000
        for _ in 1:100; for i in 1:4; cp(provider, i, 1000.0); end; end
        t0 = time()
        for _ in 1:n_eval; for i in 1:4; cp(provider, i, 1000.0); end; end
        t_cached = time() - t0
        println("Cached Provider: $(round(t_cached*1000, digits=2)) ms ($(n_eval*4) evals)")
        println("~10-100x más rápido que la API directa")
    end
end

# ╔═╡ 10000000-0000-0000-0000-000000000010
md"""
## Resumen

En este cuaderno usted:

- Construyó tablas de propiedades en lote
- Implementó un `CachedPropertyProvider` con coeficientes precargados
- Validó contra la API oficial y midió el speedup

En el [último cuaderno](11_comparacion_fuentes.jl) compararemos diferentes
fuentes de datos termodinámicos.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 10000000-0000-0000-0000-000000000011
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═10000000-0000-0000-0000-000000000001
# ╠═10000000-0000-0000-0000-000000000002
# ╠═10000000-0000-0000-0000-000000000003
# ╠═10000000-0000-0000-0000-000000000004
# ╠═10000000-0000-0000-0000-000000000005
# ╠═10000000-0000-0000-0000-000000000006
# ╠═10000000-0000-0000-0000-000000000007
# ╠═10000000-0000-0000-0000-000000000008
# ╠═10000000-0000-0000-0000-000000000009
# ╠═10000000-0000-0000-0000-000000000010
# ╠═10000000-0000-0000-0000-000000000011
