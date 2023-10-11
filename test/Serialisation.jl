### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ bb902940-a858-11ed-2f11-1d6f5af61e4a
begin
	using Pkg
	Pkg.activate("../notebooks")
	Pkg.develop("GridShielding")
	
	using Plots
	using PlutoTest
	using PlutoLinks
	using PlutoUI
	using Distributions
	TableOfContents()
end

# ╔═╡ 515c5c0b-a734-406c-b89d-6c921001a777
@revise using GridShielding

# ╔═╡ e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
md"""
# Bouncing Ball Example

## Preface
"""

# ╔═╡ 7612a253-eda4-47a8-bb93-d5fcccc6c628
begin
end

# ╔═╡ 1c03e3a8-6de3-49ff-a05d-c22fc41a5de7
⨝ = joinpath

# ╔═╡ 55cd8522-c016-455b-bfb5-0257e8ccc334
r = 0.9

# ╔═╡ 2a90dc85-62ab-42a9-85ba-5ad4f1d58aae
function initialization_function(bounds)
	x, y, z = (bounds.lower .+ bounds.upper) ./ 2
	if x^2 + y^2 + z^2 < r 
		return 99999999999 # Value large enough to exceed size of char and int32
	else
		return 0
	end
end

# ╔═╡ 76231c64-67f4-4763-b26c-5f8fac3e6e10
begin
	grid = Grid(0.05, Bounds((-1, 0, -1), (1, 1, 0)), data_type=Int64)
	initialize!(grid, initialization_function)
end

# ╔═╡ 6e395fff-e3d9-4b69-9fa2-0b012883a1c4
md"""
`x =` $(@bind x NumberField(
       grid.bounds.lower[1]:grid.granularity[1]/2:grid.bounds.upper[1], 
       default=0))

`y =` $(@bind y NumberField(
       grid.bounds.lower[2]:grid.granularity[2]/2:grid.bounds.upper[2], 
       default=0.5))

`z =` $(@bind z NumberField(
       grid.bounds.lower[3]:grid.granularity[3]/2:grid.bounds.upper[3], 
       default=-0.5))

"""

# ╔═╡ 5827c1bd-9932-4bf4-a7ab-aee75894443a
partition = box(grid, x, y, z)

# ╔═╡ d1a62487-04c8-4162-815e-8a9257f6d049
get_value(partition)

# ╔═╡ 189387ac-d7fa-4328-ad11-df2740ace9a2
# ╠═╡ skip_as_script = true
#=╠═╡
let
	slice::Vector{Any} = partition.indices
	slice[1] = slice[2] = Colon()
	
	draw(grid, slice,
		xlabel="x",
		ylabel="y",
		label="z=0",
		colors=[:white, :wheat],
		aspectratio=:equal,
		size=(500, 300))

	scatter!([x], [y], label=nothing, marker=(4, :x, :black))
end
  ╠═╡ =#

# ╔═╡ 9af0dcfa-6699-4eb9-bfe1-e99ff010b12f
begin
	@use_file "/home/asger/.julia/dev/GridShielding/misc/shield.c"
	grid
	working_dir = mktempdir()
end

# ╔═╡ 8c814127-99fa-4eb0-99a9-d82c68d2fd4e
grid

# ╔═╡ 9d84159b-6bd7-4e86-89cd-fc0673c2b6ef
begin
	serialized_to = working_dir⨝"circle.grid"
	robust_grid_serialization(serialized_to, grid)
end

# ╔═╡ 91ad5f38-27c6-4de7-8514-3af5b0714fcf
deserialized_grid = robust_grid_deserialization(serialized_to)

# ╔═╡ 0ab7d81e-0b2f-4780-b804-6836cb2e02a3
@test deserialized_grid == grid

# ╔═╡ fa683a49-d741-405d-9f5e-683d31455ce0
const libshield = get_libshield(grid; working_dir)

# ╔═╡ 5ac0cd91-a25f-44b4-822e-df285009eae2
length(grid)

# ╔═╡ ae9d67fc-58c9-4d09-83bf-5419e7b010df
size(grid)

# ╔═╡ a30d40c4-a63f-4b56-b704-c6edcb44a7c6
convert_index(ix, iy, iz) = @ccall libshield.convert_index(Cint[ix, iy, iz]::Ptr{Cint})::Cint

# ╔═╡ 43523329-23a3-4b7d-902a-1b1f06cea08f
@test 0 == convert_index(0, 0, 0)

# ╔═╡ 364033a2-0a2f-4e86-87d7-9c73412c9ded
@test 1 == convert_index(1, 0, 0)

# ╔═╡ 7d55e500-b997-493a-91cc-64e126a238cc
@test size(grid)[1] == convert_index(0, 1, 0)

# ╔═╡ bac169db-56f0-46fe-ba6c-6a7375d5fc3c
@test size(grid)[1]*size(grid)[2] == convert_index(0, 0, 1)

# ╔═╡ b0bcbaff-cddf-4f01-a563-b400b280df9a
size(grid) .- 1

# ╔═╡ f98f469f-0b14-4c45-9dc7-435c767539bd
@test length(grid) - 1 == convert_index(size(grid) .- 1...)

# ╔═╡ ba798155-81c5-4f36-968c-742b140d2a44


# ╔═╡ 3d756dc2-08f1-4f16-9f52-45450298fd9e
c_get_value(x, y, z) = @ccall libshield.get_value(x::Cdouble, y::Cdouble, z::Cdouble)::Clong

# ╔═╡ d039f598-5070-421b-be08-dabe61927b97
c_get_value(x, y, z)

# ╔═╡ 097c4d30-9f59-42e5-9018-26847b89a09b
@test c_get_value(x, y, z) == get_value(partition)

# ╔═╡ 0ce4325e-1486-46d3-bf87-c29f40dd6dbf
c_box(v, dim) = @ccall libshield.box(v::Cdouble, dim::Cint)::Cint

# ╔═╡ b496674e-3dd6-41d7-8938-49f352df3845
c_box_full(x, y, z) = [c_box(x, 0), c_box(y, 1), c_box(z, 2)]

# ╔═╡ 4c994427-caac-4106-8c73-0ced38302059
# Mind that C indexing is off by one
@test (c_box_full(x, y, z) .+ 1) == box(grid, x, y, z).indices

# ╔═╡ 3e50f49b-ae5a-4c9b-9930-d2abf3539dbc
let
	X = Uniform(grid.bounds.lower[1], grid.bounds.upper[1])
	Y = Uniform(grid.bounds.lower[2], grid.bounds.upper[2])
	Z = Uniform(grid.bounds.lower[3], grid.bounds.upper[3])

	tests = []
	for _ in 1:20
		x, y, z = rand(X), rand(Y), rand(Z)
		t = @test (c_box_full(x, y, z) .+ 1) == box(grid, x, y, z).indices
		push!(tests, t)
	end
	sort(tests, by=t -> t isa PlutoTest.Fail, rev=true)
end

# ╔═╡ 880437c4-f74d-4e0b-9795-acf52fe40332
let
	sample_space = collect(grid)

	tests = []
	for p in rand(sample_space, 20)
		s = Bounds(p).lower .+ (grid.granularity/2)
		t = @test get_value(p) == c_get_value(s...)
		push!(tests, t)
	end
	sort(tests, by=t -> t isa PlutoTest.Fail, rev=true)
end

# ╔═╡ Cell order:
# ╟─e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
# ╠═bb902940-a858-11ed-2f11-1d6f5af61e4a
# ╠═7612a253-eda4-47a8-bb93-d5fcccc6c628
# ╠═1c03e3a8-6de3-49ff-a05d-c22fc41a5de7
# ╠═515c5c0b-a734-406c-b89d-6c921001a777
# ╠═55cd8522-c016-455b-bfb5-0257e8ccc334
# ╠═2a90dc85-62ab-42a9-85ba-5ad4f1d58aae
# ╠═76231c64-67f4-4763-b26c-5f8fac3e6e10
# ╠═5827c1bd-9932-4bf4-a7ab-aee75894443a
# ╠═d1a62487-04c8-4162-815e-8a9257f6d049
# ╟─6e395fff-e3d9-4b69-9fa2-0b012883a1c4
# ╟─189387ac-d7fa-4328-ad11-df2740ace9a2
# ╠═9af0dcfa-6699-4eb9-bfe1-e99ff010b12f
# ╠═8c814127-99fa-4eb0-99a9-d82c68d2fd4e
# ╠═9d84159b-6bd7-4e86-89cd-fc0673c2b6ef
# ╠═91ad5f38-27c6-4de7-8514-3af5b0714fcf
# ╠═0ab7d81e-0b2f-4780-b804-6836cb2e02a3
# ╠═fa683a49-d741-405d-9f5e-683d31455ce0
# ╠═5ac0cd91-a25f-44b4-822e-df285009eae2
# ╠═ae9d67fc-58c9-4d09-83bf-5419e7b010df
# ╠═a30d40c4-a63f-4b56-b704-c6edcb44a7c6
# ╠═43523329-23a3-4b7d-902a-1b1f06cea08f
# ╠═364033a2-0a2f-4e86-87d7-9c73412c9ded
# ╠═7d55e500-b997-493a-91cc-64e126a238cc
# ╠═bac169db-56f0-46fe-ba6c-6a7375d5fc3c
# ╠═b0bcbaff-cddf-4f01-a563-b400b280df9a
# ╠═f98f469f-0b14-4c45-9dc7-435c767539bd
# ╠═ba798155-81c5-4f36-968c-742b140d2a44
# ╠═3d756dc2-08f1-4f16-9f52-45450298fd9e
# ╠═d039f598-5070-421b-be08-dabe61927b97
# ╠═097c4d30-9f59-42e5-9018-26847b89a09b
# ╠═0ce4325e-1486-46d3-bf87-c29f40dd6dbf
# ╠═b496674e-3dd6-41d7-8938-49f352df3845
# ╠═4c994427-caac-4106-8c73-0ced38302059
# ╠═3e50f49b-ae5a-4c9b-9930-d2abf3539dbc
# ╠═880437c4-f74d-4e0b-9795-acf52fe40332
