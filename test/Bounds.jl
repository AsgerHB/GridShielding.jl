using GridShielding
using Test

@testset "Bounds.jl" begin
    # Integer bounds
    let
        bounds = Bounds([-1, -100, 0], [1, 100, 5])
        @test [0.53, 30, 2.9] ∈ bounds  # Some point definitely inside
        @test [5, 200, 30] ∉ bounds  # Some point definitely outside
        @test [-1, -100, 0] ∈ bounds    # Lower bounds inclusive
        @test [1, 100, 5] ∉ bounds      # Upper bounds strict

        # Clamp 
        @test clamp([0.53, 30, 2.9], bounds) ∈ bounds  # Some point definitely inside
        @test clamp([5, 200, 30], bounds) ∈ bounds  # Some point definitely outside
        @test clamp([-1, -100, 0], bounds) ∈ bounds    # Lower bounds inclusive
        @test clamp([1, 100, 5], bounds) ∈ bounds      # Upper bounds strict
    end

    # Float64 bounds
    let
        bounds = Bounds(Float64[-1, -100, 0], Float64[1, 100, 5])
        @test [0.53, 30, 2.9] ∈ bounds  # Some point definitely inside
        @test [5, 200, 30] ∉ bounds  # Some point definitely outside
        @test [-1, -100, 0] ∈ bounds    # Lower bounds inclusive
        @test [1, 100, 5] ∉ bounds      # Upper bounds strict

        # Clamp 
        @test clamp(Float64[0.53, 30, 2.9], bounds) ∈ bounds  # Some point definitely inside
        @test clamp(Float64[5, 200, 30], bounds) ∈ bounds  # Some point definitely outside
        @test clamp(Float64[-1, -100, 0], bounds) ∈ bounds    # Lower bounds inclusive
        @test clamp(Float64[1, 100, 5], bounds) ∈ bounds      # Upper bounds strict
    end

    # Float32 bounds
    let
        bounds = Bounds(Float32[-1, -100, 0], Float32[1, 100, 5])
        @test [0.53, 30, 2.9] ∈ bounds  # Some point definitely inside
        @test [5, 200, 30] ∉ bounds  # Some point definitely outside
        @test [-1, -100, 0] ∈ bounds    # Lower bounds inclusive
        @test [1, 100, 5] ∉ bounds      # Upper bounds strict

        # Clamp 
        @test clamp(Float32[0.53, 30, 2.9], bounds) ∈ bounds  # Some point definitely inside
        @test clamp(Float32[5, 200, 30], bounds) ∈ bounds  # Some point definitely outside
        @test clamp(Float32[-1, -100, 0], bounds) ∈ bounds    # Lower bounds inclusive
        @test clamp(Float32[1, 100, 5], bounds) ∈ bounds      # Upper bounds strict
    end
end