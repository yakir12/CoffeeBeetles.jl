using Documenter, CoffeeBeetles

makedocs(;
    modules=[CoffeeBeetles],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/yakir12/CoffeeBeetles.jl/blob/{commit}{path}#L{line}",
    sitename="CoffeeBeetles.jl",
    authors="yakir12",
    assets=String[],
)

deploydocs(;
    repo="github.com/yakir12/CoffeeBeetles.jl",
)
