### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# ╔═╡ 05000000-0000-0000-0000-000000000002
begin
    using Glenn
    using Printf
end

# ╔═╡ 05000000-0000-0000-0000-000000000001
md"""
# 05 — Entalpias de Reação e Calores de Combustão

Este caderno demonstra como calcular **entalpias de reação** $\Delta_r H^\circ$
e **calores de combustão** (PCI/PCS — LHV/HHV) usando o Glenn.jl.

**Princípio fundamental:** Na escala NASA, a entalpia de uma reação é
simplesmente a soma estequiométrica das entalpias padronizadas dos produtos
menos reagentes:

$$\Delta_r H^\circ(T) = \sum_{p} \nu_p H_p^\circ(T) - \sum_{r} \nu_r H_r^\circ(T)$$

> **Nota:** Este cálculo assume **gás ideal**. Para aplicações com gases reais,
> correções de não-idealidade devem ser aplicadas.
"""

# ╔═╡ 05000000-0000-0000-0000-000000000003
md"""
## 1. Função auxiliar para cálculo de $\Delta_r H^\circ$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000004
begin
    """
        reaction_enthalpy(calc, reactants, products, T)

    Calcula ΔrH°(T) a partir da soma estequiométrica.

    - `reactants`: vetor de tuplas (nome, coeficiente estequiométrico)
    - `products`:  vetor de tuplas (nome, coeficiente estequiométrico)
    - `T`: temperatura em Kelvin

    Coeficientes positivos para reagentes E produtos.
    Retorna ΔrH° em J/mol (da reação como escrita).
    """
    function reaction_enthalpy(calc, reactants, products, T)
        function get_h(name)
            sp = only(get_available_species(calc, name, exact_match = true))
            props = calculate_properties(calc, sp.id, T)
            return props.h_relative
        end

        ΔH = 0.0
        for (name, nu) in products
            ΔH += nu * get_h(name)
        end
        for (name, nu) in reactants
            ΔH -= nu * get_h(name)
        end
        return ΔH
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000005
md"""
## 2. Exemplo 1: Combustão do metano

$$\text{CH}_4 + 2\text{O}_2 \rightarrow \text{CO}_2 + 2\text{H}_2\text{O}$$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000006
Calculator() do calc
    reactants = [("CH4", 1), ("O2", 2)]
    products  = [("CO2", 1), ("H2O", 2)]

    for T in [298.15, 500.0, 1000.0, 1500.0]
        ΔrH = reaction_enthalpy(calc, reactants, products, T)
        @printf("T = %6.0f K  →  ΔrH° = %10.1f kJ/mol\n", T, ΔrH / 1000.0)
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000007
md"""
### Lei de Kirchhoff

A dependência de $\Delta_r H^\circ$ com a temperatura é dada pela **Lei de
Kirchhoff**:

$$\frac{d(\Delta_r H^\circ)}{dT} = \Delta_r C_p^\circ = \sum_p \nu_p C_{p,p}^\circ - \sum_r \nu_r C_{p,r}^\circ$$

Ou na forma integrada:

$$\Delta_r H^\circ(T_2) = \Delta_r H^\circ(T_1) + \int_{T_1}^{T_2} \Delta_r C_p^\circ(T) \, dT$$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000008
md"""
## 3. Exemplo 2: Poder Calorífico (PCI/PCS — LHV/HHV)

O **Poder Calorífico Superior** (PCS / HHV) considera a água produto no estado
líquido. O **Poder Calorífico Inferior** (PCI / LHV) considera a água no estado
vapor.

$$\text{PCI} = -\Delta_r H^\circ(\text{com } \text{H}_2\text{O(g)})$$
$$\text{PCS} = -\Delta_r H^\circ(\text{com } \text{H}_2\text{O(l)}) + n_{\text{H}_2\text{O}} \cdot \Delta H_{\text{vap}}$$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000009
Calculator() do calc
    # Constante: entalpia de vaporização da água a 298.15 K
    ΔH_vap_H2O = 44.0e3  # J/mol

    function fuel_heating_values(calc, fuel_name, nC, nH)
        reactants = [(fuel_name, 1), ("O2", nC + nH / 4)]
        products  = [("CO2", Float64(nC)), ("H2O", Float64(nH) / 2)]

        # LHV: H2O como gás
        ΔrH_lhv = reaction_enthalpy(calc, reactants, products, 298.15)
        lhv = -ΔrH_lhv  # J/mol de combustível

        # HHV: H2O como líquido (aproximação)
        hhv = lhv + (nH / 2) * ΔH_vap_H2O

        return lhv, hhv
    end

    fuels = [
        ("CH4",     "Metano",      1, 4),
        ("C2H5OH",  "Etanol",      2, 6),
        ("C3H8",    "Propano",     3, 8),
    ]

    println("=== Poderes Caloríficos ===")
    println(rpad("Combustível", 14), rpad("PCI (LHV)", 20),
            rpad("PCS (HHV)", 20), rpad("PCI [MJ/kg]", 16))
    println("—"^70)

    for (name, label, nC, nH) in fuels
        try
            sp = only(get_available_species(calc, name, exact_match = true))
            MW = something(sp.molecular_weight, 0.0)  # g/mol
            lhv, hhv = fuel_heating_values(calc, name, nC, nH)
            lhv_MJkg = lhv / MW / 1000.0  # J/mol → MJ/kg
            @printf("%-14s %14.1f kJ/mol  %14.1f kJ/mol  %12.2f MJ/kg\n",
                label, lhv / 1000.0, hhv / 1000.0, lhv_MJkg)
        catch e
            @printf("%-14s %s\n", label, "não disponível")
        end
    end
end

# ╔═╡ 05000000-0000-0000-0000-000000000010
md"""
## 4. Exemplo 3: Lei de Hess

A **Lei de Hess** afirma que a entalpia de uma reação é a mesma
independentemente do caminho. Vamos verificar para a reação:

$$\text{C} + \text{O}_2 \rightarrow \text{CO}_2$$

via dois caminhos:
1. Direto: $\text{C} + \text{O}_2 \rightarrow \text{CO}_2$
2. Indireto: $\text{C} + \frac{1}{2}\text{O}_2 \rightarrow \text{CO}$,
   depois $\text{CO} + \frac{1}{2}\text{O}_2 \rightarrow \text{CO}_2$
"""

# ╔═╡ 05000000-0000-0000-0000-000000000011
Calculator() do calc
    T = 298.15

    # Caminho direto
    ΔrH_direct = reaction_enthalpy(
        calc,
        [("C", 1), ("O2", 1)],
        [("CO2", 1)],
        T
    )

    # Caminho indireto (via CO)
    ΔrH_step1 = reaction_enthalpy(
        calc,
        [("C", 1), ("O2", 0.5)],
        [("CO", 1)],
        T
    )
    ΔrH_step2 = reaction_enthalpy(
        calc,
        [("CO", 1), ("O2", 0.5)],
        [("CO2", 1)],
        T
    )
    ΔrH_indirect = ΔrH_step1 + ΔrH_step2

    println("=== Verificação da Lei de Hess ===")
    @printf("Caminho direto:     %10.1f kJ/mol\n", ΔrH_direct / 1000.0)
    @printf("Caminho indireto:   %10.1f kJ/mol\n", ΔrH_indirect / 1000.0)
    @printf("    Etapa 1 (C→CO): %10.1f kJ/mol\n", ΔrH_step1 / 1000.0)
    @printf("    Etapa 2 (CO→CO₂): %8.1f kJ/mol\n", ΔrH_step2 / 1000.0)
    @printf("\nDiferença: %e kJ/mol\n", (ΔrH_direct - ΔrH_indirect) / 1000.0)
end

# ╔═╡ 05000000-0000-0000-0000-000000000012
md"""
## Resumo

Neste caderno você aprendeu:

- A calcular $\Delta_r H^\circ$ via soma estequiométrica de `h_relative`
- A Lei de Kirchhoff: dependência de $\Delta_r H^\circ$ com $T$
- A calcular PCI (LHV) e PCS (HHV) para combustíveis
- A verificar a Lei de Hess

No [próximo caderno](06_temperatura_chama_adiabatica.jl) vamos usar esses
conceitos para calcular a **temperatura de chama adiabática**.

> **Autor:** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG
"""

# ╔═╡ 05000000-0000-0000-0000-000000000013
md"""
---
*Glenn.jl v$(Glenn.__version__) — $(Glenn.__author__)*
""

# ╔═╡ Cell order:
# ╠═05000000-0000-0000-0000-000000000001
# ╠═05000000-0000-0000-0000-000000000002
# ╠═05000000-0000-0000-0000-000000000003
# ╠═05000000-0000-0000-0000-000000000004
# ╠═05000000-0000-0000-0000-000000000005
# ╠═05000000-0000-0000-0000-000000000006
# ╠═05000000-0000-0000-0000-000000000007
# ╠═05000000-0000-0000-0000-000000000008
# ╠═05000000-0000-0000-0000-000000000009
# ╠═05000000-0000-0000-0000-000000000010
# ╠═05000000-0000-0000-0000-000000000011
# ╠═05000000-0000-0000-0000-000000000012
# ╠═05000000-0000-0000-0000-000000000013
