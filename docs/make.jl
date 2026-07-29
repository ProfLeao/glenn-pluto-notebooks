using Documenter
using Literate
using Glenn

# ── Build notebooks from Pluto .jl files into markdown ──────────────────────

const NOTEBOOKS_DIR = joinpath(@__DIR__, "..", "notebooks")
const DOCS_SRC = joinpath(@__DIR__, "src")

# Portuguese (Brazil) notebooks
const PT_TITLES = [
    "Primeiros Passos",
    "Polinômios da NASA",
    "Curvas de Propriedades",
    "Entalpia de Formação",
    "Entalpias de Reação",
    "Temperatura de Chama Adiabática",
    "Comparação de Combustíveis",
    "Equilíbrio Químico e Energia Livre de Gibbs",
    "Ciclo Brayton",
    "Propriedades para CFD",
    "Comparação de Fontes de Dados",
]

const EN_TITLES = [
    "Getting Started",
    "NASA Polynomials Under the Hood",
    "Temperature-Dependent Property Curves",
    "Enthalpy of Formation",
    "Reaction Enthalpies",
    "Adiabatic Flame Temperature",
    "Comparing Fuels & Biofuels",
    "Chemical Equilibrium & Gibbs Free Energy",
    "Brayton Gas-Turbine Cycle",
    "Property Provider for CFD",
    "Comparing Thermodynamic Data Sources",
]

const PT_FILES = [
    "01_primeiros_passos.jl",
    "02_polinomios_nasa.jl",
    "03_propriedades_curvas.jl",
    "04_entalpia_formacao.jl",
    "05_entalpias_reacao.jl",
    "06_temperatura_chama_adiabatica.jl",
    "07_comparacao_combustiveis.jl",
    "08_equilibrio_quimico.jl",
    "09_ciclo_brayton.jl",
    "10_propriedades_cfd.jl",
    "11_comparacao_fontes.jl",
]

const EN_FILES = [
    "01_getting_started.jl",
    "02_nasa_polynomials.jl",
    "03_property_curves.jl",
    "04_formation_enthalpy.jl",
    "05_reaction_enthalpies.jl",
    "06_adiabatic_flame_temperature.jl",
    "07_biofuel_comparison.jl",
    "08_equilibrium_gibbs.jl",
    "09_brayton_cycle.jl",
    "10_property_provider.jl",
    "11_comparing_sources.jl",
]

# Spanish notebooks
const ES_TITLES = [
    "Primeros Pasos",
    "Polinomios de la NASA",
    "Curvas de Propiedades",
    "Entalpía de Formación",
    "Entalpías de Reacción",
    "Temperatura de Llama Adiabática",
    "Comparación de Biocombustibles",
    "Equilibrio Químico y Energía Libre de Gibbs",
    "Ciclo Brayton",
    "Proveedor de Propiedades para CFD",
    "Comparación de Fuentes de Datos",
]

const ES_FILES = [
    "01_primeros_pasos.jl",
    "02_polinomios_nasa.jl",
    "03_curvas_propiedades.jl",
    "04_entalpia_formacion.jl",
    "05_entalpias_reaccion.jl",
    "06_temperatura_llama_adiabatica.jl",
    "07_comparacion_biocombustibles.jl",
    "08_equilibrio_gibbs.jl",
    "09_ciclo_brayton.jl",
    "10_proveedor_propiedades.jl",
    "11_comparacion_fuentes.jl",
]

function build_literate(lang_dir, files, titles, lang_name)
    notebook_dir = joinpath(NOTEBOOKS_DIR, lang_dir)

    for (i, (file, title)) in enumerate(zip(files, titles))
        nb_path = joinpath(notebook_dir, file)
        if !isfile(nb_path)
            @warn "Notebook not found: $nb_path"
            continue
        end

        output_name = replace(file, ".jl" => ".md")
        output_dir = joinpath(DOCS_SRC, lang_dir)

        # Convert Pluto notebook to markdown using Literate
        Literate.markdown(
            nb_path,
            output_dir;
            name = replace(file, ".jl" => ""),
            documenter = true,
            credit = false,
            execute = false,  # Pre-executed notebooks
        )
        println("  Literate: $lang_dir/$file → $lang_dir/$output_name")
    end
end

# ── Build the documentation ────────────────────────────────────────────────

println("Building literate documentation...")
println("  Portuguese (pt-br):")
build_literate("pt-br", PT_FILES, PT_TITLES, "Português")
println("  English:")
build_literate("en", EN_FILES, EN_TITLES, "English")
println("  Spanish:")
build_literate("es", ES_FILES, ES_TITLES, "Español")

# ── Generate index pages ───────────────────────────────────────────────────

function generate_index(lang_dir, files, titles, lang_label, lang_meta)
    index_path = joinpath(DOCS_SRC, lang_dir, "index.md")
    open(index_path, "w") do io
        write(io, "# Glenn.jl — $(lang_meta["notebooks_label"])\n\n")
        write(io, "$(lang_meta["description"])\n\n")
        write(io, "---\n\n")
        write(io, "## $(lang_meta["notebooks_heading"])\n\n")
        for (file, title) in zip(files, titles)
            name = replace(file, ".jl" => "")
            write(io, "- [$title]($name.md)\n")
        end
        write(io, "\n---\n\n")
        write(io, "## $(lang_meta["about_heading"])\n\n")
        write(io, "**$(lang_meta["author_label"]):** Dr. Reginaldo G. Leão Jr. — GESESC / IFMG\n\n")
        write(io, "**$(lang_meta["repo_label"]):** [ProfLeao/glenn-pluto-notebooks](https://github.com/ProfLeao/glenn-pluto-notebooks)\n")
    end
end

const PT_META = Dict(
    "notebooks_label" => "Cadernos Pluto (Português)",
    "description" => "Coleção de cadernos interativos **Pluto.jl** demonstrando a biblioteca\n[**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl) para cálculo de\npropriedades termoquímicas.",
    "notebooks_heading" => "Cadernos",
    "about_heading" => "Sobre",
    "author_label" => "Autor",
    "repo_label" => "Repositório",
)

const EN_META = Dict(
    "notebooks_label" => "Pluto Notebooks (English)",
    "description" => "A collection of interactive **Pluto.jl** notebooks demonstrating the\n[**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl) thermochemical\nproperties calculator.",
    "notebooks_heading" => "Notebooks",
    "about_heading" => "About",
    "author_label" => "Author",
    "repo_label" => "Repository",
)

const ES_META = Dict(
    "notebooks_label" => "Cuadernos Pluto (Español)",
    "description" => "Colección de cuadernos interactivos **Pluto.jl** que demuestran la\nbiblioteca [**Glenn.jl**](https://github.com/ProfLeao/Glenn.jl) para\ncálculo de propiedades termoquímicas.",
    "notebooks_heading" => "Cuadernos",
    "about_heading" => "Acerca de",
    "author_label" => "Autor",
    "repo_label" => "Repositorio",
)

generate_index("pt-br", PT_FILES, PT_TITLES, "Português", PT_META)
generate_index("en", EN_FILES, EN_TITLES, "English", EN_META)
generate_index("es", ES_FILES, ES_TITLES, "Español", ES_META)

# ── Main documentation build ───────────────────────────────────────────────

makedocs(
    modules = [Glenn],
    sitename = "Glenn.jl — Pluto Notebooks",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://profleao.github.io/glenn-pluto-notebooks/stable/",
    ),
    pages = [
        "Home" => "index.md",
        "Português (Brasil)" => [
            "Índice" => "pt-br/index.md",
            [joinpath("pt-br", replace(f, ".jl" => ".md")) for f in PT_FILES]...
        ],
        "English" => [
            "Index" => "en/index.md",
            [joinpath("en", replace(f, ".jl" => ".md")) for f in EN_FILES]...
        ],
        "Español" => [
            "Índice" => "es/index.md",
            [joinpath("es", replace(f, ".jl" => ".md")) for f in ES_FILES]...
        ],
    ],
    warnonly = [:missing_docs, :cross_references],
)

# ── Deploy ─────────────────────────────────────────────────────────────────

deploydocs(
    repo = "github.com/ProfLeao/glenn-pluto-notebooks.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)
