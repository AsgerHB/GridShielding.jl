### A Pluto.jl notebook ###
# v0.19.20

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
	Pkg.activate(".")
	Pkg.develop("GridShielding")
	
	using Plots
	using PlutoLinks
	using PlutoUI
	using PlutoTest
	using Unzip
	using AbstractTrees
	using Printf
	TableOfContents()
end

# ╔═╡ 515c5c0b-a734-406c-b89d-6c921001a777
begin
	@revise using GridShielding
	using GridShielding.RW
end

# ╔═╡ e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
md"""
# Scratchpad

## Preface
"""

# ╔═╡ 5ae3173f-6abb-4f38-94f8-90300c93d0e9
call(f) = f()

# ╔═╡ 816cbb33-8a9a-4fb4-a701-339c4b9e4bcb
begin
	colors = 
		(TURQUOISE = colorant"#1abc9c", 
		EMERALD = colorant"#2ecc71", 
		PETER_RIVER = colorant"#3498db", 
		AMETHYST = colorant"#9b59b6", 
		WET_ASPHALT = colorant"#34495e",
		
		GREEN_SEA   = colorant"#16a085", 
		NEPHRITIS   = colorant"#27ae60", 
		BELIZE_HOLE  = colorant"#2980b9", 
		WISTERIA     = colorant"#8e44ad", 
		MIDNIGHT_BLUE = colorant"#2c3e50", 
		
		SUNFLOWER = colorant"#f1c40f",
		CARROT   = colorant"#e67e22",
		ALIZARIN = colorant"#e74c3c",
		CLOUDS   = colorant"#ecf0f1",
		CONCRETE = colorant"#95a5a6",
		
		ORANGE = colorant"#f39c12",
		PUMPKIN = colorant"#d35400",
		POMEGRANATE = colorant"#c0392b",
		SILVER = colorant"#bdc3c7",
		ASBESTOS = colorant"#7f8c8d")
	[colors...]
end

# ╔═╡ dea51a45-9282-4828-8a3b-efd3b7433ef7
RW.rwmechanics

# ╔═╡ 9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
@bind granularity NumberField(0.001:0.001:1, default=0.2)

# ╔═╡ bf131a2d-b087-4f19-9990-6a6fee723b6d
@bind samples_per_axis NumberField(1:30, default=3)

# ╔═╡ fbf86b61-57a2-4250-8c1b-fac7110a6429
@bind action Select(Pace |> instances |> collect, default=RW.fast)

# ╔═╡ 0a25f7fe-db47-4d20-856f-6417474b1c2a
grid = Grid(granularity, [rwmechanics.x_min, rwmechanics.t_min], 
	[rwmechanics.x_max + 0.3, 
	 rwmechanics.t_max + 0.3])

# ╔═╡ 1cc3c41b-4d47-4951-a2d5-d7441a200092
simulation_function(point, action) = 
	RW.simulate(rwmechanics, point..., action, unlucky=true)

# ╔═╡ dc971f77-a2bd-47bd-a9df-0786041e77b0
model = SimulationModel(simulation_function, samples_per_axis)

# ╔═╡ 63b1f19e-1e27-49c5-a742-5f7e67de84e3
function scatter_supporting_points!(model::SimulationModel, partition)

	scatter!(SupportingPoints(model.samples_per_axis, partition) |> collect |> unzip,
		marker=(:+, 5, colors.WET_ASPHALT),
		markerstrokewidth=4,
		label="Supporting points")

	scatter!(possible_outcomes(model, partition, action) |> unzip,
		marker=(:circle, 2, colors.CONCRETE),
		markerstrokewidth=0,
		label="Possible outcomes")
end

# ╔═╡ f93e9e9b-7622-406b-b7d4-482365833fbd
partition = box(grid, 0.1,0.1)

# ╔═╡ ae886eaa-b8e1-471d-9804-2e724352ad4e
begin
	draw(grid, [:,:], show_grid=true)

	scatter_supporting_points!(model, partition)
end

# ╔═╡ 2d02e8df-a044-4dd2-bef0-07c80e68293b
SupportingPoints(model.samples_per_axis, partition) |> collect

# ╔═╡ Cell order:
# ╟─e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
# ╠═bb902940-a858-11ed-2f11-1d6f5af61e4a
# ╠═5ae3173f-6abb-4f38-94f8-90300c93d0e9
# ╠═515c5c0b-a734-406c-b89d-6c921001a777
# ╟─816cbb33-8a9a-4fb4-a701-339c4b9e4bcb
# ╠═dea51a45-9282-4828-8a3b-efd3b7433ef7
# ╠═9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
# ╠═bf131a2d-b087-4f19-9990-6a6fee723b6d
# ╠═fbf86b61-57a2-4250-8c1b-fac7110a6429
# ╠═0a25f7fe-db47-4d20-856f-6417474b1c2a
# ╠═1cc3c41b-4d47-4951-a2d5-d7441a200092
# ╠═dc971f77-a2bd-47bd-a9df-0786041e77b0
# ╠═f93e9e9b-7622-406b-b7d4-482365833fbd
# ╟─63b1f19e-1e27-49c5-a742-5f7e67de84e3
# ╠═2d02e8df-a044-4dd2-bef0-07c80e68293b
# ╠═ae886eaa-b8e1-471d-9804-2e724352ad4e
