### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
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
	using ZipFile
	using PyCall
	TableOfContents()
end

# ╔═╡ 515c5c0b-a734-406c-b89d-6c921001a777
@revise using GridShielding

# ╔═╡ e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
md"""
# Serializatoin Tests

## Preface
"""

# ╔═╡ 1c03e3a8-6de3-49ff-a05d-c22fc41a5de7
⨝ = joinpath

# ╔═╡ 670ff2b2-cb12-4840-857f-7d720bc71834
md"""
## Example Grid
"""

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
		title="z=0",
		colors=[:white, :wheat],
		aspectratio=:equal,
		size=(500, 300))

	scatter!([x], [y], label=nothing, marker=(4, :x, :black))
end
  ╠═╡ =#

# ╔═╡ 37d1be0a-8920-4df5-8e4e-8682ef8b86fc
md"""
##  Robust Grid (De)Serialization
"""

# ╔═╡ 9af0dcfa-6699-4eb9-bfe1-e99ff010b12f
begin
	# Reactivity
	@use_file "/home/asger/.julia/dev/GridShielding/misc/shield.c"
	grid

	working_dir = mktempdir()
end

# ╔═╡ 292ecf52-e588-4ee6-96f7-f313fb825a64
@bind open_folder_button CounterButton("Open Folder")

# ╔═╡ c62e53c0-c580-4313-8f1a-1c8f63299a5e
if open_folder_button > 0
	run(`nautilus $working_dir`, wait=false)
end; "This cell opens `$working_dir` in nautilus"

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

# ╔═╡ 55a1d42d-8ac9-4322-8e8b-d9d7980fd576
md"""
## Libshield
"""

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

# ╔═╡ e3b566eb-95e8-4341-a75f-c7f8a2273497
md"""
## JSON
"""

# ╔═╡ 7690a969-bdad-4c10-a56f-9f627a35c995
grid_json = working_dir ⨝ "grid.json"

# ╔═╡ 6939a347-2733-4450-8212-8a3c454de3e7
unique(grid.array)

# ╔═╡ c873b20d-189f-46b6-b323-fd370a6d43d0
md"""
## Scratchpad

It would make more sense to make a whole new notebook but I'm having fun so trashy code time :3
"""

# ╔═╡ 9db5c940-7590-43bb-a686-5911a7ab7526
hypagrid = read_from_json("/tmp/bouncing_ball.json")

# ╔═╡ 0f462999-cf4c-4d1b-9650-4594132d6469
let
	slice::Vector{Any} = [:, :]
	
	draw(hypagrid, slice,
		xlabel="v",
		ylabel="p",
		title="Exported from UPPAAL HYPA",
		colors=[:lightgrey, :wheat, :beige, :moccasin],
		aspectratio=:equal,
		size=(500, 300))
end

# ╔═╡ 65457eee-e990-4797-9929-cefb437c855d
md"""
## Python Export

For some reason the values of the grid is randomized for this one.
"""

# ╔═╡ f9a4f12e-d3a9-4875-ace2-e214f7bf1c00
@enum Action foo bar

# ╔═╡ a521bc66-2fc7-403b-a73e-fdf5ef42ec15
get_meta_info(grid, actions=Action)

# ╔═╡ f1f22c01-8c21-457e-9288-2f7a0c3d2543
begin
	to_json(grid, grid_json, meta_info=get_meta_info(grid, actions=Action))
	json_file_exported = true
end

# ╔═╡ c22ff289-3585-4ed5-b815-1d291be6c925
if json_file_exported let
	grid″ = read_from_json(grid_json, data_type=Int64)
	@test grid″ == grid
end end

# ╔═╡ ffaf9dbd-8608-4bd6-814e-cc6fa6aad57d
begin
	grid′ = Grid(grid.granularity, grid.bounds)

	for partition in grid
		partition′ = Partition(grid′, partition.indices)
		set_value!(partition′, get_value(partition) >= 1 ? rand((1, 2, 3)) : 0)
	end
end

# ╔═╡ be9d9689-c594-4536-9ef5-d6b7f5c1d218
@doc get_meta_info

# ╔═╡ 5aec68ca-10ea-4705-81c5-6ae7d4d3c299
typeof([])<:AbstractArray

# ╔═╡ 5db23cbc-8251-4a9a-b4e9-6decf1a6efa6
let
	slice::Vector{Any} = partition.indices
	slice[1] = slice[2] = Colon()
	
	draw(grid′, slice,
		xlabel="x",
		ylabel="y",
		title="z=0",
		colors=[:white, :wheat, :beige, :moccasin],
		aspectratio=:equal,
		size=(500, 300))
end

# ╔═╡ d5e30af2-ee54-4132-847e-74e8b1af3eb2
get_meta_info(grid′,
	variables=["x", "y"], 
	binary_variables=Int[],
	actions=Action,
	env_id="test grid")

# ╔═╡ 70fc0404-ac2e-491c-8776-c49d4bb16bbb
grid_zip = working_dir ⨝ "grid.zip"

# ╔═╡ e1af4cc0-c631-49e4-8df3-73000e96243a
begin
	numpy_zip_file(grid′, grid_zip,
		variables=["x", "y"],
		binary_variables=Int[],
		actions=Action,
		env_id="test grid")

	zip_file_exported = true
end;

# ╔═╡ b10e5910-99bb-4ba3-b366-ebf78ab0b9fe
np = pyimport("numpy")

# ╔═╡ 24b3e394-3f00-4720-86d0-4acd9cc51b00
if zip_file_exported let
	array = nothing
	for f in ZipFile.Reader(grid_zip).files
		if f.name == "grid.npy"
			grid_npy = working_dir ⨝ "grid.npy"
			write(grid_npy, f)
			array = np.load(grid_npy)
			break
		end
	end
	@test grid′.array == array
end end

# ╔═╡ Cell order:
# ╟─e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
# ╠═bb902940-a858-11ed-2f11-1d6f5af61e4a
# ╠═1c03e3a8-6de3-49ff-a05d-c22fc41a5de7
# ╠═515c5c0b-a734-406c-b89d-6c921001a777
# ╟─670ff2b2-cb12-4840-857f-7d720bc71834
# ╠═55cd8522-c016-455b-bfb5-0257e8ccc334
# ╠═2a90dc85-62ab-42a9-85ba-5ad4f1d58aae
# ╠═76231c64-67f4-4763-b26c-5f8fac3e6e10
# ╠═5827c1bd-9932-4bf4-a7ab-aee75894443a
# ╠═d1a62487-04c8-4162-815e-8a9257f6d049
# ╟─6e395fff-e3d9-4b69-9fa2-0b012883a1c4
# ╟─189387ac-d7fa-4328-ad11-df2740ace9a2
# ╟─37d1be0a-8920-4df5-8e4e-8682ef8b86fc
# ╠═9af0dcfa-6699-4eb9-bfe1-e99ff010b12f
# ╠═292ecf52-e588-4ee6-96f7-f313fb825a64
# ╠═c62e53c0-c580-4313-8f1a-1c8f63299a5e
# ╠═8c814127-99fa-4eb0-99a9-d82c68d2fd4e
# ╠═9d84159b-6bd7-4e86-89cd-fc0673c2b6ef
# ╠═91ad5f38-27c6-4de7-8514-3af5b0714fcf
# ╠═0ab7d81e-0b2f-4780-b804-6836cb2e02a3
# ╟─55a1d42d-8ac9-4322-8e8b-d9d7980fd576
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
# ╟─e3b566eb-95e8-4341-a75f-c7f8a2273497
# ╠═a521bc66-2fc7-403b-a73e-fdf5ef42ec15
# ╠═7690a969-bdad-4c10-a56f-9f627a35c995
# ╠═f1f22c01-8c21-457e-9288-2f7a0c3d2543
# ╠═6939a347-2733-4450-8212-8a3c454de3e7
# ╠═c22ff289-3585-4ed5-b815-1d291be6c925
# ╠═c873b20d-189f-46b6-b323-fd370a6d43d0
# ╠═9db5c940-7590-43bb-a686-5911a7ab7526
# ╟─0f462999-cf4c-4d1b-9650-4594132d6469
# ╟─65457eee-e990-4797-9929-cefb437c855d
# ╠═f9a4f12e-d3a9-4875-ace2-e214f7bf1c00
# ╠═ffaf9dbd-8608-4bd6-814e-cc6fa6aad57d
# ╠═be9d9689-c594-4536-9ef5-d6b7f5c1d218
# ╠═5aec68ca-10ea-4705-81c5-6ae7d4d3c299
# ╟─5db23cbc-8251-4a9a-b4e9-6decf1a6efa6
# ╠═d5e30af2-ee54-4132-847e-74e8b1af3eb2
# ╠═70fc0404-ac2e-491c-8776-c49d4bb16bbb
# ╠═e1af4cc0-c631-49e4-8df3-73000e96243a
# ╠═b10e5910-99bb-4ba3-b366-ebf78ab0b9fe
# ╠═24b3e394-3f00-4720-86d0-4acd9cc51b00
