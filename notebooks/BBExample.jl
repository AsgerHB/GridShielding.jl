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
	Pkg.activate(".")
	Pkg.develop("GridShielding")
	
	using Plots
	using PlutoLinks
	using PlutoUI
	using PlutoTest
	using Unzip
	using AbstractTrees
	using Printf
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

# ╔═╡ 5ae3173f-6abb-4f38-94f8-90300c93d0e9
call(f) = f()

# ╔═╡ 76231c64-67f4-4763-b26c-5f8fac3e6e10
BB = GridShielding.BB

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
bbshieldlabels = 	["{hit, nohit}", "{hit}", "{nohit}", "{}"]

# ╔═╡ 2f5e4800-eb30-413a-9031-9afd00bc11cc
bbshieldcolors = [colorant"#ff9178", colorant"#a1eaff",  colorant"#a1eaaa",  colorant"#ffffff"]

# ╔═╡ 93f81afe-bd36-4a1e-96a7-9fc53316a770
md"""
### The Simulation Function

The function for taking a single step needs to be wrapped up, so that it has the signature `(point::AbstractVector, action, random_variables::AbstractVector) -> updated_point`. 
"""

# ╔═╡ 3c8d70bd-2d7b-4260-8304-4f1e4ea74719
rand(Uniform(-1, 1))

# ╔═╡ 78b78798-aca2-4fcd-9f18-2a22c70c3829
md"""
## Creating the shield
"""

# ╔═╡ 099c6d2a-d125-4f67-9e30-5d204a634b38
md"""
### Simulation function

The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point`, `action` and `random_outcomes`.
"""

# ╔═╡ a659ab0a-1955-457f-9f8d-6a7e2699d0aa
simulation_function(p, a, r) = 
	BB.simulate_point(BB.bbmechanics, p, r, a, min_v_on_impact=1)

# ╔═╡ 279fc983-2cbc-406f-babd-1ad0c0f9c05a
simulation_function((3, 7), BB.hit, rand(Uniform(-1, 1)))

# ╔═╡ b98bfecf-e99c-44b3-ac5f-4edd4f577217
simulation_function((0.1, 0), BB.hit, rand(Uniform(-1, 1)))

# ╔═╡ 30741a93-47b2-4502-a9c2-4bd6f8baefad
md"""
## Safety Property

The ball should never "come to a stop." However, coming to a stop includes doing an infinite amount of bounces in a finite amount of time, until the velocity becomes zero.

In practice, this means it should bounce back with more than $1^m/{}_s$. 
"""

# ╔═╡ fcd23ebf-2465-41b5-9b75-f6d43c518b60
begin
	is_safe(state) = abs(state[1]) > 1 || state[2] > 0
	is_safe(bounds::Bounds) = is_safe((bounds.lower[1], bounds.lower[2]))
end

# ╔═╡ fe4f171c-a582-475b-9719-a77e7369c4bd
md"""
### Grid
The grid is defined by the upper and lower bounds on the state space, and some `granularity` which determines the size of the partitions.

`granularity_v =` $(@bind granularity_v NumberField(0.001:0.001:1, default=0.02))

`granularity_p =` $(@bind granularity_p NumberField(0.001:0.001:1, default=0.02))
"""

# ╔═╡ 0791f41e-ccb8-4f62-a006-26448778c373
granularity = [granularity_v, granularity_p]

# ╔═╡ 9cbfce51-3a4d-49ad-abc9-101294b96724
any_action, no_action = actions_to_int([]), actions_to_int([BB.hit BB.nohit])

# ╔═╡ 0a25f7fe-db47-4d20-856f-6417474b1c2a
begin
	grid = Grid(granularity, (-15, 0), (15, 8))

	initialize!(grid, x -> is_safe(x) ? no_action : any_action)
end

# ╔═╡ f88cd709-a35f-4365-9624-91244a0c113a
md"""

The initialized grid is shown in the following figure.

Choosing a very fine granularity might make the figure hard to see, and cause slowness. There is also a bug where chosing an uneven granularity will cause the grid to be misaligned. So it can be turned off below.

`show_grid:` $(@bind show_grid CheckBox(default=false))
"""

# ╔═╡ fbf86b61-57a2-4250-8c1b-fac7110a6429
md"""
### Reachability Function
The next step is to create the reachability function. It takes a partition and an action, and returns the set of partitions reachable from that initial partition.

It it uses a set of supporting points, which are a set of regularly spaced points within the bounds of a partition. The number of supporting points is defined by how many should be sampled per action.

Try experimenting with different values.

`samples_per_axis_v =` $(@bind samples_per_axis_v NumberField(1:30, default=3))

`samples_per_axis_p =` $(@bind samples_per_axis_p NumberField(1:30, default=3))

"""

# ╔═╡ 80efecb0-d269-45a1-974a-de8a4c8a06d3
samples_per_axis = (samples_per_axis_v, samples_per_axis_p)

# ╔═╡ 9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
md"""
The reachability function can be illustrated in the grid above.

Check the box to view the reachability function:

show: $(@bind show_barbaric_transition CheckBox())

And now you can move the "cursor" over different partitions by adjusting these sliders.

v: $(@bind v Slider(grid.bounds.lower[1]:grid.granularity[1]:grid.bounds.upper[1] - grid.granularity[1], default=0))
p: $(@bind p Slider(grid.bounds.lower[2]:grid.granularity[2]:grid.bounds.upper[2] - grid.granularity[2], default=0))

Action: $(@bind action Select(BB.Action |> instances |> collect, default=BB.nohit))
"""

# ╔═╡ 0ae7a407-9bf8-470e-977f-a1701302f4a3
v, p

# ╔═╡ f93e9e9b-7622-406b-b7d4-482365833fbd
partition = box(grid, v, p)

# ╔═╡ 04dbeb6f-024d-4899-a9eb-0634f8f352f1
md"""
### Including Randomness

The results of the random outcomes can be specified in the simulation function, as seen above. 

This is required, as otherwise it will only consider the average outcome, and not take the worst case into account.

Use the following checkbox to add the random factor to the number of supporting points.

enable: $(@bind enable_randomness CheckBox())
"""

# ╔═╡ 4124666b-384b-4451-8c36-fb1649ed85b3
if enable_randomness
md""" 
`samples_per_axis_random =` $(@bind samples_per_axis_random NumberField(1:30, default=3))"""
else
	samples_per_axis_random = 0
	nothing # Suppress output
end

# ╔═╡ 63866178-5ad2-48b8-88d2-9eaadd73fabf
if enable_randomness
	randomness_space = Bounds((-1,), (1,))
else
	randomness_space = Bounds((-1,), (-1,))
end;

# ╔═╡ 53937382-f37e-4935-bd8c-88d8c3c4240b
md"""
**Number of Supporting Points:**
$(length(SupportingPoints(samples_per_axis, partition))*
length(SupportingPoints(samples_per_axis, randomness_space)))
"""

# ╔═╡ 48c1b86b-983d-4a55-a0d2-652c1ce2c544
md"""
### Simulation Model

All of this is wrapped up in the following model `struct` just to make the call signatures shorter.
"""

# ╔═╡ dc971f77-a2bd-47bd-a9df-0786041e77b0
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, (samples_per_axis_random,))

# ╔═╡ ae886eaa-b8e1-471d-9804-2e724352ad4e
begin
	draw(grid, [:,:]; show_grid, colors=bbshieldcolors, color_labels=bbshieldlabels)

	if show_barbaric_transition
		draw_barbaric_transition!(model, partition, action, [:,:])
	
		# cursor
		#=
		scatter!([v], [p],
			marker=(5, :rtriangle, :white),
			markerstroke=1,
			label=nothing)
		=#
	end

	# plot settings
	plot!(size=(700, 500),
		xlim=(grid.bounds.lower[1], grid.bounds.upper[1]), 
		ylim=(grid.bounds.lower[2], grid.bounds.upper[2]), 
		legend=:outerright,
		xlabel="v",
		ylabel="p")
end

# ╔═╡ 2d02e8df-a044-4dd2-bef0-07c80e68293b
SupportingPoints(model.samples_per_axis, partition) |> collect

# ╔═╡ b0138efc-3a7d-46a5-9095-528ba9d7663f
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ 7fdda9f4-0dc4-44c6-af98-be1df62ce635
md"""
### Result

The reachability function from above can be used to compute a safety strategy from the initial `grid`.
"""

# ╔═╡ 492a369c-c21f-4900-b736-e36ee7d72a33
begin
	grid, model # reactivity
	@bind make_shield_button CounterButton("Make Shield")
end

# ╔═╡ d5e3fd5a-8f0d-4d13-a134-04ddaf8483b7
if make_shield_button > 0
	reachability_function_precomputed = 
		get_transitions(reachability_function, BB.Action, grid)
end

# ╔═╡ ca166647-c150-43dc-8271-f3ac47ccb051
md"""
Try starting at 1 and then stepping through the iterations.

`max_steps=` $(@bind max_steps NumberField(1:1000, default=1000))
"""

# ╔═╡ d112a057-f541-43cf-89cf-68f74887cdfa
begin
	shield, max_steps_reached = nothing, false
	
	if make_shield_button > 0

		# here is the computation
		shield, max_steps_reached = 
			make_shield(reachability_function_precomputed, BB.Action, grid; max_steps)

	else
		shield = grid
	end
end

# ╔═╡ 0ee2563c-e191-47db-a01f-b9308f814d78
if shield !== nothing
	shield_plot = draw(shield, [:,:]; show_grid, colors=bbshieldcolors, color_labels=bbshieldlabels)
	
	plot!(size=(700, 500),
		xlim=(grid.bounds.lower[1], grid.bounds.upper[1]), 
		ylim=(grid.bounds.lower[2], grid.bounds.upper[2]), 
		legend=:outertop,
		xlabel="velocity",
		ylabel="position")
end

# ╔═╡ 072735c7-10ce-4e89-9f9a-a531caad5af5
function apply_shield(shield::Grid, policy)
    return (s) -> begin
		a = policy(s)
		if s ∉ shield
			return a
		end
        allowed = int_to_actions(BB.Action, get_value(box(shield, s...)))
        if a ∈ allowed
            return a
        elseif length(allowed) > 0
			a′ = rand(allowed)
            return a′
        else
            return a
        end
    end
end

# ╔═╡ 78dbd9b5-4c89-48dd-821e-458d30b15473
md"""
## Evaluating the shield

There are no formal guarantees, but let's see if we can provide statistical guarantees.

Adjust the number of runs you want to simulate, and let us see if the agent is able to keep itself safe for that long.
"""

# ╔═╡ 51e9dec7-e55e-48c8-8b18-f19e4f75b358
@bind refresh_button Button("Refresh")

# ╔═╡ 2785eca1-90df-470e-8461-d243a5deb7ee
hits_rarely = BB.random_policy(0.05)

# ╔═╡ c96fe092-9bf8-4ee5-95db-de9e66d90a13
[hits_rarely((v, p)) for _ in 1:10]

# ╔═╡ 98c53a10-e832-440d-931e-23006f22d3b4
shielded_hits_rarely = apply_shield(shield, hits_rarely)

# ╔═╡ 3ce807e9-f681-472b-9411-6215d2574b55
[shielded_hits_rarely((v, p)) for _ in 1:10]

# ╔═╡ 1a14c4c9-8630-4396-a50c-be7a37ba9a6b
shielded_hits_rarely((1, 5))

# ╔═╡ 0379ff26-3df9-47d8-a93f-4f4cb4f724b4
shielded_hits_rarely((7, 0))

# ╔═╡ 211419f0-8e80-4463-bcf3-e15f3e3272e0
refresh_button; @bind runs NumberField(1:100000, default=100)

# ╔═╡ e77ccf1a-1e75-400e-967a-7412fd76ca51
refresh_button; safety_violations = 		
	BB.check_safety(BB.bbmechanics, 
		shielded_hits_rarely, 
		120, 
		runs=runs)

# ╔═╡ 296a0e19-3178-4329-91de-54bdafdacdd1
begin
	

	if safety_violations > 0
		Markdown.parse("""
		!!! danger "Not Safe"
			There were $safety_violations safety violations in $runs runs. 
		""")
	else
		Markdown.parse("""
		!!! success "Seems Safe"
			No safety violations observed in $runs runs.
		""")
	end
end

# ╔═╡ fe4bd8df-67ab-4572-89bb-7ef7e4aab267
if make_shield_button > 0 let
	refresh_button
	shielded_lazy = apply_shield(shield, _ -> nohit)
	
	BB.animate_trace(BB.simulate_sequence(BB.bbmechanics, 
			(0, 7), 
			shielded_hits_rarely, 10)...,
		left_background=shield_plot)
end end

# ╔═╡ Cell order:
# ╟─e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
# ╠═bb902940-a858-11ed-2f11-1d6f5af61e4a
# ╠═5ae3173f-6abb-4f38-94f8-90300c93d0e9
# ╠═515c5c0b-a734-406c-b89d-6c921001a777
# ╠═76231c64-67f4-4763-b26c-5f8fac3e6e10
# ╟─816cbb33-8a9a-4fb4-a701-339c4b9e4bcb
# ╠═8564347e-489d-47a6-b0be-ba6b69445707
# ╠═2f5e4800-eb30-413a-9031-9afd00bc11cc
# ╟─93f81afe-bd36-4a1e-96a7-9fc53316a770
# ╠═3c8d70bd-2d7b-4260-8304-4f1e4ea74719
# ╠═279fc983-2cbc-406f-babd-1ad0c0f9c05a
# ╠═b98bfecf-e99c-44b3-ac5f-4edd4f577217
# ╟─78b78798-aca2-4fcd-9f18-2a22c70c3829
# ╟─099c6d2a-d125-4f67-9e30-5d204a634b38
# ╠═a659ab0a-1955-457f-9f8d-6a7e2699d0aa
# ╟─30741a93-47b2-4502-a9c2-4bd6f8baefad
# ╠═fcd23ebf-2465-41b5-9b75-f6d43c518b60
# ╟─fe4f171c-a582-475b-9719-a77e7369c4bd
# ╠═0791f41e-ccb8-4f62-a006-26448778c373
# ╠═0a25f7fe-db47-4d20-856f-6417474b1c2a
# ╠═9cbfce51-3a4d-49ad-abc9-101294b96724
# ╟─f88cd709-a35f-4365-9624-91244a0c113a
# ╟─ae886eaa-b8e1-471d-9804-2e724352ad4e
# ╟─fbf86b61-57a2-4250-8c1b-fac7110a6429
# ╠═80efecb0-d269-45a1-974a-de8a4c8a06d3
# ╟─9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
# ╟─53937382-f37e-4935-bd8c-88d8c3c4240b
# ╠═0ae7a407-9bf8-470e-977f-a1701302f4a3
# ╠═f93e9e9b-7622-406b-b7d4-482365833fbd
# ╟─04dbeb6f-024d-4899-a9eb-0634f8f352f1
# ╟─4124666b-384b-4451-8c36-fb1649ed85b3
# ╠═63866178-5ad2-48b8-88d2-9eaadd73fabf
# ╟─48c1b86b-983d-4a55-a0d2-652c1ce2c544
# ╠═dc971f77-a2bd-47bd-a9df-0786041e77b0
# ╠═2d02e8df-a044-4dd2-bef0-07c80e68293b
# ╠═b0138efc-3a7d-46a5-9095-528ba9d7663f
# ╟─7fdda9f4-0dc4-44c6-af98-be1df62ce635
# ╟─492a369c-c21f-4900-b736-e36ee7d72a33
# ╠═d5e3fd5a-8f0d-4d13-a134-04ddaf8483b7
# ╟─ca166647-c150-43dc-8271-f3ac47ccb051
# ╠═d112a057-f541-43cf-89cf-68f74887cdfa
# ╟─0ee2563c-e191-47db-a01f-b9308f814d78
# ╠═072735c7-10ce-4e89-9f9a-a531caad5af5
# ╟─78dbd9b5-4c89-48dd-821e-458d30b15473
# ╠═51e9dec7-e55e-48c8-8b18-f19e4f75b358
# ╠═2785eca1-90df-470e-8461-d243a5deb7ee
# ╠═c96fe092-9bf8-4ee5-95db-de9e66d90a13
# ╠═98c53a10-e832-440d-931e-23006f22d3b4
# ╠═3ce807e9-f681-472b-9411-6215d2574b55
# ╠═1a14c4c9-8630-4396-a50c-be7a37ba9a6b
# ╠═0379ff26-3df9-47d8-a93f-4f4cb4f724b4
# ╠═211419f0-8e80-4463-bcf3-e15f3e3272e0
# ╠═e77ccf1a-1e75-400e-967a-7412fd76ca51
# ╟─296a0e19-3178-4329-91de-54bdafdacdd1
# ╟─fe4bd8df-67ab-4572-89bb-7ef7e4aab267
