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

# ╔═╡ 8564347e-489d-47a6-b0be-ba6b69445707
rwshieldlabels = 	["{fast, slow}", "{fast}", "{}"]

# ╔═╡ 2f5e4800-eb30-413a-9031-9afd00bc11cc
rwshieldcolors = 	[colorant"#ff9178", colorant"#a1eaff", colorant"#ffffff"]

# ╔═╡ a6eb5d3b-9b3f-47d2-9746-6cf851b19451
md"""
## Example Function and safety constraint

This notebook uses the Random Walk example, which is included in the RW module.
"""

# ╔═╡ f31c562f-d438-4f57-a0b2-99bf5eae563b
any_action, no_action = 
	actions_to_int(instances(Pace)), actions_to_int([])

# ╔═╡ f05e0180-27ca-4f7c-b9a9-ff20052539ca
evaluate(rwmechanics, (_, _) -> RW.slow)

# ╔═╡ 350ddf9d-5963-4779-9c6d-a8b03cd2b48c
begin
	plot(aspectratio=:equal, size=(300, 300), xlabel="x", ylabel="t")
	xlims!(rwmechanics.x_min, rwmechanics.x_max + 0.1)
	ylims!(rwmechanics.t_min, rwmechanics.t_max + 0.1)
	draw_walk!(take_walk(rwmechanics, (_, _) -> rand([RW.slow, RW.fast]))...)
end

# ╔═╡ 099c6d2a-d125-4f67-9e30-5d204a634b38
md"""
The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point` and `action`.

The kwarg `unlucky=true` will tell the function to pick the worst-case outcome, i.e. the one where the ball preserves the least amount of power on impact. 

!!! info "TODO"
	Model random outcomes as an additional dimension, removing the need for assumptions about a "worst-case" outcome.
"""

# ╔═╡ b1fef68b-2ad0-4431-9b0e-a6f7566fef21
simulation_function(point, action, random_outcomes) = RW.simulate(
	rwmechanics, 
	point[1], 
	point[2], 
	action,
	random_outcomes)

# ╔═╡ 096ec85c-5b7c-4c76-b813-33fef355b9bf
md"""
The goal of the game is to reach `x >= x_max` without reaching `t >= t_max`. 

This corresponds to the below safety property. It is defined both for a single `(x, t)` point, as well as for a set of points given by `Bounds`.
"""

# ╔═╡ a38aedbd-9ee2-4840-9ace-ee0298bd83e1
begin
	is_safe(point) = point[2] <= rwmechanics.t_max
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.upper[2]))
end

# ╔═╡ fe4f171c-a582-475b-9719-a77e7369c4bd
md"""
## The Grid
"""

# ╔═╡ 9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
@bind granularity NumberField(0.001:0.001:1, default=0.1)

# ╔═╡ f88cd709-a35f-4365-9624-91244a0c113a
@bind show_grid CheckBox(default=true)

# ╔═╡ bf131a2d-b087-4f19-9990-6a6fee723b6d
@bind samples_per_axis NumberField(1:30, default=3)

# ╔═╡ fbf86b61-57a2-4250-8c1b-fac7110a6429
@bind action Select(Pace |> instances |> collect, default=RW.fast)

# ╔═╡ 0a25f7fe-db47-4d20-856f-6417474b1c2a
begin
	grid = Grid(granularity, [rwmechanics.x_min, rwmechanics.t_min], 
		[rwmechanics.x_max + 0.2, 
		 rwmechanics.t_max + 0.2])

	initialize!(grid, is_safe)
end

# ╔═╡ 1685ea67-dcb2-4484-a58b-24c68b9ff2f2
ϵ = rwmechanics.ϵ

# ╔═╡ 63866178-5ad2-48b8-88d2-9eaadd73fabf
randomness_space = Bounds((-ϵ,  -ϵ), (ϵ, ϵ))

# ╔═╡ dc971f77-a2bd-47bd-a9df-0786041e77b0
model = SimulationModel(simulation_function, randomness_space, samples_per_axis)

# ╔═╡ e565e49f-26e8-492b-8ec4-06587cffd46b
@bind x Slider(0.01:0.01:1)

# ╔═╡ 0b0e711e-61da-4cbf-974f-950e4222d2d2
@bind t Slider(0.01:0.01:1)

# ╔═╡ f93e9e9b-7622-406b-b7d4-482365833fbd
partition = box(grid, x, t)

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

# ╔═╡ 2d02e8df-a044-4dd2-bef0-07c80e68293b
SupportingPoints(model.samples_per_axis, partition) |> collect

# ╔═╡ ae886eaa-b8e1-471d-9804-2e724352ad4e
begin
	draw(grid, [:,:]; show_grid, colors=rwshieldcolors, color_labels=rwshieldlabels)

	draw_barbaric_transition!(model, partition, RW.fast, [:,:])

	# cursor
	scatter!([x], [t],
		marker=(5, :rtriangle, :white),
		markerstroke=1,
		label=nothing)

	# plot settings
	plot!(axisratio=:equal, 
		size=(800, 600),
		lim=(grid.bounds.lower[1], grid.bounds.upper[1]), 
		legend=:outerright)
end

# ╔═╡ b0138efc-3a7d-46a5-9095-528ba9d7663f
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ ca166647-c150-43dc-8271-f3ac47ccb051
@bind max_steps NumberField(1:1000)

# ╔═╡ d112a057-f541-43cf-89cf-68f74887cdfa
shield, max_steps_reached = 
	make_shield(reachability_function, Pace, grid; max_steps)

# ╔═╡ 0ee2563c-e191-47db-a01f-b9308f814d78
begin
	draw(shield, [:,:]; show_grid, colors=rwshieldcolors, color_labels=rwshieldlabels)
	
	plot!(axisratio=:equal, 
		lim=(grid.bounds.lower[1], grid.bounds.upper[1]), 
		legend=:outerright)
end

# ╔═╡ 26119c6f-c2c0-42b9-93c0-3e9ec1d857d9
SupportingPoints(1, Bounds([], [])) |> collect

# ╔═╡ Cell order:
# ╟─e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
# ╠═bb902940-a858-11ed-2f11-1d6f5af61e4a
# ╠═5ae3173f-6abb-4f38-94f8-90300c93d0e9
# ╠═515c5c0b-a734-406c-b89d-6c921001a777
# ╟─816cbb33-8a9a-4fb4-a701-339c4b9e4bcb
# ╠═8564347e-489d-47a6-b0be-ba6b69445707
# ╠═2f5e4800-eb30-413a-9031-9afd00bc11cc
# ╟─a6eb5d3b-9b3f-47d2-9746-6cf851b19451
# ╠═f31c562f-d438-4f57-a0b2-99bf5eae563b
# ╠═f05e0180-27ca-4f7c-b9a9-ff20052539ca
# ╠═350ddf9d-5963-4779-9c6d-a8b03cd2b48c
# ╟─099c6d2a-d125-4f67-9e30-5d204a634b38
# ╠═b1fef68b-2ad0-4431-9b0e-a6f7566fef21
# ╟─096ec85c-5b7c-4c76-b813-33fef355b9bf
# ╠═a38aedbd-9ee2-4840-9ace-ee0298bd83e1
# ╟─fe4f171c-a582-475b-9719-a77e7369c4bd
# ╠═9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
# ╠═f88cd709-a35f-4365-9624-91244a0c113a
# ╠═bf131a2d-b087-4f19-9990-6a6fee723b6d
# ╠═fbf86b61-57a2-4250-8c1b-fac7110a6429
# ╠═0a25f7fe-db47-4d20-856f-6417474b1c2a
# ╠═1685ea67-dcb2-4484-a58b-24c68b9ff2f2
# ╠═63866178-5ad2-48b8-88d2-9eaadd73fabf
# ╠═dc971f77-a2bd-47bd-a9df-0786041e77b0
# ╠═e565e49f-26e8-492b-8ec4-06587cffd46b
# ╠═0b0e711e-61da-4cbf-974f-950e4222d2d2
# ╠═f93e9e9b-7622-406b-b7d4-482365833fbd
# ╟─63b1f19e-1e27-49c5-a742-5f7e67de84e3
# ╠═2d02e8df-a044-4dd2-bef0-07c80e68293b
# ╠═ae886eaa-b8e1-471d-9804-2e724352ad4e
# ╠═b0138efc-3a7d-46a5-9095-528ba9d7663f
# ╠═ca166647-c150-43dc-8271-f3ac47ccb051
# ╠═d112a057-f541-43cf-89cf-68f74887cdfa
# ╠═0ee2563c-e191-47db-a01f-b9308f814d78
# ╠═26119c6f-c2c0-42b9-93c0-3e9ec1d857d9
