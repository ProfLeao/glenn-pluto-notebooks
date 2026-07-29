#!/usr/bin/env julia
# =====================================================================
# render.jl — Render all Pluto notebooks to static HTML
#
# Usage:
#   julia --project scripts/render.jl
#
# Generates rendered/ with pre-executed notebooks for GitHub preview.
# Original .jl source files in notebooks/ are left untouched.
# =====================================================================

using Pluto
using Printf

const ROOT = abspath(joinpath(@__DIR__, ".."))
const NOTEBOOKS_DIR = joinpath(ROOT, "notebooks")
const RENDERED_DIR = joinpath(ROOT, "rendered")

const LANGS = ["pt-br", "en", "es"]

function render_all()
    total = 0
    errors = 0

    @printf("Rendering Pluto notebooks to static HTML...\n")
    @printf("Source:      %s\n", NOTEBOOKS_DIR)
    @printf("Destination: %s\n\n", RENDERED_DIR)

    for lang in LANGS
        src_dir = joinpath(NOTEBOOKS_DIR, lang)
        dst_dir = joinpath(RENDERED_DIR, lang)

        if !isdir(src_dir)
            @warn "Directory not found: $src_dir"
            continue
        end

        notebook_files = sort(filter(f -> endswith(f, ".jl"), readdir(src_dir)))

        if isempty(notebook_files)
            @warn "No notebooks found in $src_dir"
            continue
        end

        println("="^60)
        @printf("  %s (%d notebooks)\n", lang, length(notebook_files))
        println("="^60)

        for nb_file in notebook_files
            total += 1
            src_path = joinpath(src_dir, nb_file)
            out_name = replace(nb_file, ".jl" => ".html")
            dst_path = joinpath(dst_dir, out_name)

            print("  $(rpad(nb_file, 45)) ... ")

            try
                # Activate the notebook's environment and run it
                # Pluto will handle package resolution via the notebook's own metadata
                html_contents = Pluto.generate_html(Pluto.load_notebook(Pluto.tamepath(src_path)))

                # Write the HTML output
                write(dst_path, html_contents)

                size_kb = round(filesize(dst_path) / 1024, digits = 1)
                println("✓  $(size_kb) KB")
            catch e
                errors += 1
                println("✗  FAILED")
                @error "Failed to render $src_path" exception = e
            end
        end
        println()
    end

    println("="^60)
    @printf("Total: %d notebooks, %d errors\n", total, errors)
    println("="^60)

    if errors > 0
        exit(1)
    end

    # Create a simple index.html for the rendered directory
    write(
        joinpath(RENDERED_DIR, "index.html"),
        """
        <!DOCTYPE html>
        <html lang="en">
        <head><meta charset="UTF-8"><title>Glenn.jl — Pluto Notebooks (Rendered)</title>
        <style>body{font-family:system-ui,sans-serif;max-width:800px;margin:2em auto;padding:0 1em}
        h1{text-align:center}ul{list-style:none;padding:0}li{margin:.5em 0}
        a{color:#0366d6;text-decoration:none}a:hover{text-decoration:underline}
        .lang{font-weight:bold;margin-top:1.5em}</style></head>
        <body>
        <h1>Glenn.jl — Pluto Notebooks</h1>
        <p style="text-align:center">Pre-rendered static HTML versions with visible outputs.</p>
        """ *
        join([
            "<p class='lang'>$(uppercase(lang))</p><ul>" *
            join([
                "<li><a href=\"$(replace(f, ".jl" => ".html"))\">$(replace(f, ".jl" => ""))</a></li>"
                for f in sort(filter(x -> endswith(x, ".jl"), readdir(joinpath(NOTEBOOKS_DIR, lang))))
            ], "\n") *
            "</ul>"
            for lang in LANGS
        ], "\n") *
        """
        <hr><p style="text-align:center;color:#666;font-size:.85em">
        Original source: <a href="https://github.com/ProfLeao/glenn-pluto-notebooks">github.com/ProfLeao/glenn-pluto-notebooks</a>
        </p></body></html>
        """
    )

    println("\nIndex written to $(joinpath(RENDERED_DIR, "index.html"))")
    println("Done!")
end

render_all()
