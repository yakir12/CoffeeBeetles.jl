using CoffeeBeetles
using Test

@testset "CoffeeBeetles.jl" begin
    main()
    files = ["figure$i.pdf" for i in 4:7]
    append!(files, ["table1.txt", "table2.csv"])
    @test all(isfile(file) for file in files)
end
