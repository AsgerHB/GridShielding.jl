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
@revise using GridShielding

# ╔═╡ e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
md"""
# Random Walk Example

## Preface
"""

# ╔═╡ 5ae3173f-6abb-4f38-94f8-90300c93d0e9
call(f) = f()

# ╔═╡ 76231c64-67f4-4763-b26c-5f8fac3e6e10
RW = GridShielding.RW

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

# ╔═╡ 665be7af-150f-4d94-9a86-a8dd319e9c41
md"""
## Action Encoding
"""

# ╔═╡ 2f1acecf-3b48-4a32-a3e7-b7730628bb92
md"""
Sets of actions are encoded bitwise in integers for performance reasons.
"""

# ╔═╡ 4811970c-0830-4cf7-bf39-ef072020ba36
actions_to_int([RW.slow])

# ╔═╡ 3392f2db-76c3-4e27-98e6-009d8645adc9
actions_to_int([RW.fast])

# ╔═╡ f31c562f-d438-4f57-a0b2-99bf5eae563b
any_action, no_action = 
	actions_to_int([RW.fast, RW.slow]), actions_to_int([])

# ╔═╡ a6eb5d3b-9b3f-47d2-9746-6cf851b19451
md"""
## Example Function and safety constraint

This notebook uses the Random Walk example, which is included in the RW module.

The player can either move slow and cheap, or fast and expensive. Moving slow will consume less time $t$, on average, but might cover less distance $x$. 
The goal of the game is to reach $x>1.0$ before reaching $t>1.0$. 

The mechanics of the system are defined in the `rwmechanics` struct. Try folding out the values, and you can see the upper and lower bounds, the randomness factor $\epsilon$ and the constant factors $\delta$ and $\tau$, which are added to $x$ and $t$ respectively. These values depend on the actions, which can be either "slow" or "fast".
"""

# ╔═╡ 7a2635dc-a6b6-476c-aa71-63b2a04a8c17
rwmechanics = RW.rwmechanics

# ╔═╡ 6bb714f7-2648-4cc9-af46-21dc06530dcf
md"""
The simulation function is called in the following way. 

Input: The "fast" action and starting from $(x, t)=(0,0)$
"""

# ╔═╡ a58a9727-e833-4ea4-a8f2-a57dda152338
RW.simulate(rwmechanics, 0, 0, RW.fast)

# ╔═╡ 683e286f-0a2c-419f-9144-5efae3d15dd6
md"""
The random outcomes can be specified in advance. This is required of the function for it to be useful when computing all possible outcomes. 

In this example, the randomness factor $\epsilon$ is set to 0 for both axes.
"""

# ╔═╡ ddf8ba55-1e45-44d9-a966-3cfcf706830d
RW.simulate(rwmechanics, 0, 0, RW.fast, [0, 0])

# ╔═╡ c82e064e-5cf1-4a7c-b03f-8bdf0fd6fc14
md"""
### Play the Game -- Try it Out!

The goal of the game is to reach a state where $x>1.0$ before $t>1.0$. 

Use the buttons below, and see if you can achieve this using as few "fast" actions as possible.
"""

# ╔═╡ 3f5edaad-6263-4d78-ace0-58fde4e86c5b
@bind reset_button Button("Reset")

# ╔═╡ 622f76c4-e4e9-439d-9a85-de3006d3e24b
begin
	# x-values, t-values and actions for each step
	reactive_xs = [0.]
	reactive_ts = [0.]
	reactive_as = []
	reset_button
end

# ╔═╡ 2016a048-9a70-4c52-8fb8-db5c4d6b00c4
begin
	reset_button
	@bind fast_button CounterButton("Fast")
end

# ╔═╡ 0789062a-5583-4757-8d47-11101bdfebef
begin
	reset_button
	@bind slow_button CounterButton("Slow")
end

# ╔═╡ 0533cbab-dbc8-4daa-9930-af34ebaef314
call() do 
	if slow_button > 0 && reactive_xs[end] < rwmechanics.x_max
		a = RW.slow
		x, t = RW.simulate(rwmechanics, reactive_xs[end], reactive_ts[end], a)
		push!(reactive_xs, x)
		push!(reactive_ts, t)
		push!(reactive_as, a)
	end
	"Slow"
end

# ╔═╡ 020d217e-b4ca-47c7-bcb6-f3ca880eb13f
call() do 
	if fast_button > 0 && reactive_xs[end] < rwmechanics.x_max
		a = RW.fast
		x, t = RW.simulate(rwmechanics, reactive_xs[end], reactive_ts[end], a)
		push!(reactive_xs, x)
		push!(reactive_ts, t)
		push!(reactive_as, a)
	end
	"Fast"
end

# ╔═╡ 350ddf9d-5963-4779-9c6d-a8b03cd2b48c
begin
	reset_button, slow_button, fast_button
	plot(aspectratio=:equal, size=(500, 500), xlabel="x", ylabel="t")
	xlims!(rwmechanics.x_min, rwmechanics.x_max + 0.1)
	ylims!(rwmechanics.t_min, rwmechanics.t_max + 0.1)
	RW.draw_walk!(reactive_xs, reactive_ts, reactive_as)
	RW.draw_next_step!(rwmechanics, reactive_xs[end], reactive_ts[end])
	plot!(lims=(0, 1.2))
end

# ╔═╡ 07c0b465-9d2e-4da8-901a-c96b8ee35653
begin
	reset_button, slow_button, fast_button
	if  reactive_xs[end] >= rwmechanics.x_max && reactive_ts[end] < rwmechanics.x_max
		md"""
		!!! success "Winner!"
		"""
	elseif reactive_ts[end] >= rwmechanics.t_max
		md"""
		!!! danger "Time Exceeded"
		"""
	end
end

# ╔═╡ 78b78798-aca2-4fcd-9f18-2a22c70c3829
md"""
## Creating the shield
"""

# ╔═╡ 099c6d2a-d125-4f67-9e30-5d204a634b38
md"""
### Simulation function

The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point`, `action` and `random_outcomes`.
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
### Safety property
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
### Grid
The grid is defined by the upper and lower bounds on the state space, and some `granularity` which determines the size of the partitions.

`granularity =` $(@bind granularity NumberField(0.001:0.001:1, default=0.1))
"""

# ╔═╡ 0a25f7fe-db47-4d20-856f-6417474b1c2a
begin
	grid = Grid(granularity, [rwmechanics.x_min, rwmechanics.t_min], 
		[rwmechanics.x_max + 0.2, 
		 rwmechanics.t_max + 0.2])

	initialize!(grid, is_safe)
end

# ╔═╡ f88cd709-a35f-4365-9624-91244a0c113a
md"""

The initialized grid is shown in the following figure.

Choosing a very low granularity might make the figure hard to see, and cause slowness. There is also a bug where chosing an uneven granularity will cause the grid to be misaligned. So it can be turned off below.

`show_grid:` $(@bind show_grid CheckBox(default=true))
"""

# ╔═╡ fbf86b61-57a2-4250-8c1b-fac7110a6429
md"""
### Reachability Function
The next step is to create the reachability function. It takes a partition and an action, and returns the set of partitions reachable from that initial partition.

It it uses a set of supporting points, which are a set of regularly spaced points within the bounds of a partition. The number of supporting points is defined by how many should be sampled per action.

Try experimenting with different values.

`samples_per_axis =` $(@bind samples_per_axis NumberField(1:30, default=3))
"""

# ╔═╡ 9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
md"""
The reachability function can be illustrated in the grid above.

Check the box to view the reachability function:

show: $(@bind show_barbaric_transition CheckBox())

And now you can move the "cursor" over different partitions by adjusting these sliders.

x: $(@bind x Slider(0.01:0.01:1, default=0.1))
t: $(@bind t Slider(0.01:0.01:1, default=0.1))

Action: $(@bind action Select(RW.Pace |> instances |> collect, default=RW.fast))
"""

# ╔═╡ f93e9e9b-7622-406b-b7d4-482365833fbd
partition = box(grid, x, t)

# ╔═╡ 04dbeb6f-024d-4899-a9eb-0634f8f352f1
md"""
### Including Randomness

The results of the random outcomes can be specified in the simulation function, as seen above. 

This is required, as otherwise it will only consider the average outcome, and not take the worst case into account.

Use the following checkbox to add the random factor $\epsilon$ to the number of supporting points.

enable: $(@bind enable_randomness CheckBox())
"""

# ╔═╡ 1685ea67-dcb2-4484-a58b-24c68b9ff2f2
ϵ = rwmechanics.ϵ

# ╔═╡ 63866178-5ad2-48b8-88d2-9eaadd73fabf
if enable_randomness
	randomness_space = Bounds((-ϵ,  -ϵ), (ϵ, ϵ))
else
	randomness_space = Bounds((0, 0), (0, 0))
end

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
model = SimulationModel(simulation_function, randomness_space, samples_per_axis)

# ╔═╡ ae886eaa-b8e1-471d-9804-2e724352ad4e
begin
	draw(grid, [:,:]; show_grid, colors=rwshieldcolors, color_labels=rwshieldlabels)

	if show_barbaric_transition
		draw_barbaric_transition!(model, partition, action, [:,:])
	
		# cursor
		scatter!([x], [t],
			marker=(5, :rtriangle, :white),
			markerstroke=1,
			label=nothing)
	end

	# plot settings
	plot!(axisratio=:equal, 
		size=(700, 500),
		lim=(grid.bounds.lower[1], grid.bounds.upper[1]), 
		legend=:outerright,
		xlabel="x",
		ylabel="t")
end

# ╔═╡ 2d02e8df-a044-4dd2-bef0-07c80e68293b
SupportingPoints(model.samples_per_axis, partition) |> collect

# ╔═╡ b0138efc-3a7d-46a5-9095-528ba9d7663f
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ 7fdda9f4-0dc4-44c6-af98-be1df62ce635
md"""
### Result

Putting it all together.
"""

# ╔═╡ 492a369c-c21f-4900-b736-e36ee7d72a33
begin
	grid, samples_per_axis # reactivity
	@bind make_shield_button CounterButton("Make Shield")
end

# ╔═╡ ca166647-c150-43dc-8271-f3ac47ccb051
md"""
Try starting at 1 and then stepping through the iterations.

`max_steps=` $(@bind max_steps NumberField(1:1000, default=100))
"""

# ╔═╡ d112a057-f541-43cf-89cf-68f74887cdfa
begin
	shield, max_steps_reached = nothing, false
	
	if make_shield_button > 0

		# here is the computation
		shield, max_steps_reached = 
			make_shield(reachability_function, RW.Pace, grid; max_steps)
		
	end
end

# ╔═╡ 0ee2563c-e191-47db-a01f-b9308f814d78
if shield !== nothing
	draw(shield, [:,:]; show_grid, colors=rwshieldcolors, color_labels=rwshieldlabels)
	
	plot!(axisratio=:equal, 
		size=(700, 500),
		lim=(grid.bounds.lower[1], grid.bounds.upper[1]), 
		legend=:outerright,
		xlabel="x",
		ylabel="t")
end

# ╔═╡ 78dbd9b5-4c89-48dd-821e-458d30b15473
md"""
## Evaluating the shield

TODO
"""

# ╔═╡ f05e0180-27ca-4f7c-b9a9-ff20052539ca
RW.evaluate(rwmechanics, (_, _) -> RW.slow)

# ╔═╡ Cell order:
# ╟─e4f088b7-b48a-4c6f-aa36-fc9fd4746d9b
# ╠═bb902940-a858-11ed-2f11-1d6f5af61e4a
# ╠═5ae3173f-6abb-4f38-94f8-90300c93d0e9
# ╠═515c5c0b-a734-406c-b89d-6c921001a777
# ╟─76231c64-67f4-4763-b26c-5f8fac3e6e10
# ╟─816cbb33-8a9a-4fb4-a701-339c4b9e4bcb
# ╠═8564347e-489d-47a6-b0be-ba6b69445707
# ╠═2f5e4800-eb30-413a-9031-9afd00bc11cc
# ╟─665be7af-150f-4d94-9a86-a8dd319e9c41
# ╟─2f1acecf-3b48-4a32-a3e7-b7730628bb92
# ╠═4811970c-0830-4cf7-bf39-ef072020ba36
# ╠═3392f2db-76c3-4e27-98e6-009d8645adc9
# ╠═f31c562f-d438-4f57-a0b2-99bf5eae563b
# ╟─a6eb5d3b-9b3f-47d2-9746-6cf851b19451
# ╠═7a2635dc-a6b6-476c-aa71-63b2a04a8c17
# ╟─6bb714f7-2648-4cc9-af46-21dc06530dcf
# ╠═a58a9727-e833-4ea4-a8f2-a57dda152338
# ╟─683e286f-0a2c-419f-9144-5efae3d15dd6
# ╠═ddf8ba55-1e45-44d9-a966-3cfcf706830d
# ╟─c82e064e-5cf1-4a7c-b03f-8bdf0fd6fc14
# ╟─3f5edaad-6263-4d78-ace0-58fde4e86c5b
# ╟─622f76c4-e4e9-439d-9a85-de3006d3e24b
# ╟─2016a048-9a70-4c52-8fb8-db5c4d6b00c4
# ╟─0533cbab-dbc8-4daa-9930-af34ebaef314
# ╟─0789062a-5583-4757-8d47-11101bdfebef
# ╟─020d217e-b4ca-47c7-bcb6-f3ca880eb13f
# ╟─350ddf9d-5963-4779-9c6d-a8b03cd2b48c
# ╟─07c0b465-9d2e-4da8-901a-c96b8ee35653
# ╟─78b78798-aca2-4fcd-9f18-2a22c70c3829
# ╟─099c6d2a-d125-4f67-9e30-5d204a634b38
# ╠═b1fef68b-2ad0-4431-9b0e-a6f7566fef21
# ╟─096ec85c-5b7c-4c76-b813-33fef355b9bf
# ╠═a38aedbd-9ee2-4840-9ace-ee0298bd83e1
# ╟─fe4f171c-a582-475b-9719-a77e7369c4bd
# ╠═0a25f7fe-db47-4d20-856f-6417474b1c2a
# ╟─f88cd709-a35f-4365-9624-91244a0c113a
# ╟─ae886eaa-b8e1-471d-9804-2e724352ad4e
# ╟─fbf86b61-57a2-4250-8c1b-fac7110a6429
# ╟─9273fb89-dfcf-41f7-acc2-009b8dfb9b1e
# ╠═f93e9e9b-7622-406b-b7d4-482365833fbd
# ╠═53937382-f37e-4935-bd8c-88d8c3c4240b
# ╠═04dbeb6f-024d-4899-a9eb-0634f8f352f1
# ╠═1685ea67-dcb2-4484-a58b-24c68b9ff2f2
# ╠═63866178-5ad2-48b8-88d2-9eaadd73fabf
# ╟─48c1b86b-983d-4a55-a0d2-652c1ce2c544
# ╠═dc971f77-a2bd-47bd-a9df-0786041e77b0
# ╠═2d02e8df-a044-4dd2-bef0-07c80e68293b
# ╠═b0138efc-3a7d-46a5-9095-528ba9d7663f
# ╟─7fdda9f4-0dc4-44c6-af98-be1df62ce635
# ╟─492a369c-c21f-4900-b736-e36ee7d72a33
# ╟─ca166647-c150-43dc-8271-f3ac47ccb051
# ╠═d112a057-f541-43cf-89cf-68f74887cdfa
# ╟─0ee2563c-e191-47db-a01f-b9308f814d78
# ╟─78dbd9b5-4c89-48dd-821e-458d30b15473
# ╠═f05e0180-27ca-4f7c-b9a9-ff20052539ca
