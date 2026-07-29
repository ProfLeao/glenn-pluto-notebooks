### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# ╔═╡ 09000000-0000-0000-0000-000000000001
md"""
# 09 — Ciclo Brayton de Turbina a Gás

Este caderno implementa o **ciclo Brayton padrão-ar** com propriedades
termodinâmicas **reais** ($C_p$ dependente da temperatura), substituindo a
hipótese de gás caloricamente perfeito ($C_p$ constante).

O ciclo é composto por 4 processos:

1. **Compressão isentrópica** (1 → 2): compressor
2. **Adição de calor isobárica** (2 → 3): câmara de combustão
3. **Expansão isentrópica** (3 → 4): turbina
4. **Rejeição de calor isobárica** (4 → 1): exaustão

As eficiências são calculadas como:

$$\eta_{\text{térmico}} = \frac{W_{\text{liq}}}{Q_{\text{in}}}$$
$$bwr = \frac{W_{\text{comp}}}{W_{\text{turb}}}$$
"""

# ╔═╡ 09000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
    using Roots
end

# ╔═╡ 09000000-0000-0000-0000-000000000003
md"""
## 1. Implementação do ciclo Brayton com $C_p(T)$ real
"""

# ╔═╡ 09000000-0000-0000-0000-000000000004
begin
    """
        brayton_states(calc; T1, T3, rp)

    Calcula os 4 estados do ciclo Brayton padrão-ar usando propriedades reais.

    - `T1`: temperatura de entrada do compressor [K]
    - `T3`: temperatura de entrada da turbina [K]
    - `rp`: razão de pressão (p2/p1 = p3/p4)

    Retorna um Dict com (T, h) para cada estado.
    """
    function brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = 10.0)
        air = only(get_available_species(calc, "N2", exact_match = true))

        # Estado 1: entrada do compressor
        p1 = calculate_properties(calc, air.id, T1)
        h1 = p1.h_relative
        s1 = p1.s

        # Estado 2: saída do compressor (isentrópico)
        # s2 = s1 + R * ln(rp)  (gás ideal)
        s2_target = s1 + Glenn.R_UNIVERSAL * log(rp)

        function s2_error(T)
            p2 = calculate_properties(calc, air.id, T)
            return p2.s - s2_target
        end

        T2 = find_zero(s2_error, (T1 * 1.5, T1 * 5.0))
        h2 = calculate_properties(calc, air.id, T2).h_relative
        w_comp = h2 - h1  # trabalho do compressor

        # Estado 3: entrada da turbina (após combustão)
        p3 = calculate_properties(calc, air.id, T3)
        h3 = p3.h_relative
        s3 = p3.s

        # Estado 4: saída da turbina (isentrópico)
        s4_target = s3 - Glenn.R_UNIVERSAL * log(rp)

        function s4_error(T)
            p4 = calculate_properties(calc, air.id, T)
            return p4.s - s4_target
        end

        T4 = find_zero(s4_error, (T3 * 0.5, T3 * 0.95))
        h4 = calculate_properties(calc, air.id, T4).h_relative
        w_turb = h3 - h4  # trabalho da turbina

        # Eficiência
        q_in = h3 - h2
        w_net = w_turb - w_comp
        eta_th = w_net / q_in
        bwr = w_comp / w_turb

        return Dict(
            "states" => [
                ("1 (entrada compressor)", T1, h1),
                ("2 (saída compressor)", T2, h2),
                ("3 (entrada turbina)", T3, h3),
                ("4 (saída turbina)", T4, h4),
            ],
            "w_comp" => w_comp,
            "w_turb" => w_turb,
            "w_net" => w_net,
            "q_in" => q_in,
            "eta_th" => eta_th,
            "bwr" => bwr,
            "rp" => rp,
        )
    end
end

# ╔═╡ 09000000-0000-0000-0000-000000000005
md"""
## 2. Exemplo: ciclo com $r_p = 10$
"""

# ╔═╡ 09000000-0000-0000-0000-000000000006
Calculator() do calc
    result = brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = 10.0)

    println("=== Ciclo Brayton — rp = $(result["rp"]) ===")
    println()
    println("Estados:")
    for (label, T, h) in result["states"]
        @printf("  %-25s  T = %7.1f K  h = %10.1f J/mol\n", label, T, h)
    end

    println()
    println("Desempenho:")
    @printf("  w_comp  = %10.1f kJ/mol\n", result["w_comp"] / 1000.0)
    @printf("  w_turb  = %10.1f kJ/mol\n", result["w_turb"] / 1000.0)
    @printf("  w_net   = %10.1f kJ/mol\n", result["w_net"] / 1000.0)
    @printf("  q_in    = %10.1f kJ/mol\n", result["q_in"] / 1000.0)
    @printf("  η_térm  = %10.3f  (%5.1f %%)\n",
        result["eta_th"], result["eta_th"] * 100)
    @printf("  bwr     = %10.3f  (%5.1f %%)\n",
        result["bwr"], result["bwr"] * 100)
end

# ╔═╡ 09000000-0000-0000-0000-000000000007
md"""
## 3. Eficiência vs Razão de Pressão
"""

# ╔═╡ 09000000-0000-0000-0000-000000000008
begin
    rp_range = [4, 6, 8, 10, 12, 15, 18, 20, 25, 30]
    eta_list = Float64[]
    bwr_list = Float64[]

    Calculator() do calc
        for rp in rp_range
            result = brayton_states(calc; T1 = 300.0, T3 = 1400.0, rp = Float64(rp))
            push!(eta_list, result["eta_th"])
            push!(bwr_list, result["bwr"])
        end
    end

    println("=== Eficiência vs Razão de Pressão ===")
    println(rpad("rp", 8), rpad("η_térm [%]", 16), rpad("bwr [%]", 14))
    println("—"^38)
    for (i, rp) in enumerate(rp_range)
        @printf("%-8d %12.1f %%     %10.1f %%\n",
            rp, eta_list[i] * 100, bwr_list[i] * 100)
    end
end

# ╔═╡ 09000000-0000-0000-0000-000000000009
md"""
### Interpretação

1. **Eficiência cresce com $r_p$**: Maior razão de pressão → maior eficiência
   térmica (mais trabalho líquido por unidade de calor)
2. **Backwork ratio (bwr) cresce com $r_p$**: O compressor consome uma fração
   maior do trabalho da turbina
3. **Limite prático**: $r_p$ é limitado pela temperatura máxima dos materiais
   ($T_3$) e pela complexidade do compressor

No ciclo ideal com $C_p$ constante (gás caloricamente perfeito):
$\eta = 1 - r_p^{(1-\gamma)/\gamma}$. Com $C_p(T)$ real, a eficiência é
ligeiramente diferente.
"""

# ╔═╡ 09000000-0000-0000-0000-000000000010
md"""
## Resumo

Neste caderno você:

- Implementou o ciclo Brayton com propriedades reais ($C_p(T)$)
- Usou `find_zero` para resolver estados isentrópicos
- Calculou eficiência térmica e backwork ratio
- Analisou o efeito da razão de pressão no desempenho

No [próximo caderno](10_propriedades_cfd.jl) vamos construir um **provedor de
propriedades** otimizado para CFD e cinética química.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 09000000-0000-0000-0000-000000000011
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
"""
