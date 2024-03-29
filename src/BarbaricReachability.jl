struct SimulationModel
	simulation_function::Function
	randomness_space::Bounds
	samples_per_axis
	samples_per_random_axis
end

function worst_case_memory_usage(m::SimulationModel, grid::Grid)
	# We assume every sample reaches a different partition
	axis_samples = prod(m.samples_per_axis)
	randomness_samples = prod(m.samples_per_axis[i] for (i, _) in enumerate(m.randomness_space.lower))
	result = (grid.dimensions*length(grid)*(axis_samples + randomness_samples))/1.049e+6
	result = round(result, digits=2)
	"$(result)mb"
end

# Returns a list of states that are possible outcomes from the initial partition
# according to the supporting points.
function possible_outcomes(model::SimulationModel, partition::Partition, action)
	
	result = []
	bounds = Bounds(partition)
	bounds = Bounds(bounds.lower, [prevfloat(u) for u in bounds.upper]) # Upper bounds are not inclusive
	for point in SupportingPoints(model.samples_per_axis, bounds)
		for random_outcomes in SupportingPoints(model.samples_per_random_axis, model.randomness_space)
			point′ = model.simulation_function(point, action, random_outcomes)
			push!(result, point′)
		end
	end
	result
end

function get_reachable_area(model::SimulationModel, partition::Partition, action)
	result = Set()
	bounds = Bounds(partition)
	bounds = Bounds(bounds.lower, [prevfloat(u) for u in bounds.upper]) # Upper bounds are not inclusive
	for point in SupportingPoints(model.samples_per_axis, bounds)
		for random_outcomes in SupportingPoints(model.samples_per_random_axis, model.randomness_space)
			point′ = model.simulation_function(point, action, random_outcomes)
			if point′ ∉ partition.grid
				continue
			end
			
			partition′ = box(partition.grid, point′)
			indices = partition′.indices
			push!(result, indices)
		end
	end
	[result...]
end

function get_barbaric_reachability_function(model::SimulationModel)
	return (partition, action) ->
		get_reachable_area(model, partition, action)
end

function draw_barbaric_transition_3D!(model, 
		partition::Partition, action;
		colors=(:black, :gray),
		plotargs...)
	
	samples = [s for s in SupportingPoints(model.samples_per_axis, partition)]
	scatter!([s[1] for s in samples], [s[2] for s in samples], [s[3] for s in samples],
			markersize=2,
			markerstrokewidth=0,
			label="initial partition",
			color=colors[1],
			plotargs...)
	
	reach = possible_outcomes(model, partition, action)
	scatter!([r[1] for r in reach], [r[2] for r in reach], [r[3] for r in reach],
			markersize=2,
			markerstrokewidth=0,
			color=colors[2],
			label="possible outcomes of $action",
			plotargs...)
end

function draw_barbaric_transition!(model, 
		partition::Partition, 
		action, 
		slice=[:,:];
		colors=(:black, :gray),
		plotargs...)

	
	ix, iy = 0, 0
	if 1 == count((==(Colon())), slice)
		ix = iy = 1
	elseif 2 != count((==(Colon())), slice)
		throw(ArgumentError("The slice argument should be an array of indices and exactly two colons. Example: [:, 10, :]"))
	else
		ix, iy = indexof((==(Colon())), slice)
	end
	
	samples = [s for s in SupportingPoints(model.samples_per_axis, partition)]
	scatter!([s[ix] for s in samples], [s[iy] for s in samples],
			markershape=:+,
			markersize=5,
			markerstrokewidth=4,
			label="initial",
			color=colors[1];
			plotargs...)
	
	reach = possible_outcomes(model, partition, action)
	scatter!([r[ix] for r in reach], [r[iy] for r in reach],
			markersize=2,
			markerstrokewidth=0,
			color=colors[2],
			label="$action")
end

"""Update the value of every partition reachable from the given `partition`.
"""
function set_reachable_area!(model, partition::Partition, action, value)
	
	reachable_area = get_reachable_area(model, partition::Partition, action)
	for indices in reachable_area
		partition.grid.array[indices...] = value
	end
end
