struct SimulationModel
	simulation_function::Function
	randomness_space::Bounds
	samples_per_axis
end

# Returns a list of states that are possible outcomes from the initial partition
# according to the supporting points.
function possible_outcomes(model::SimulationModel, partition::Partition, action)
	
	result = []
	for point in SupportingPoints(model.samples_per_axis, partition)
		for random_outcomes in SupportingPoints(model.samples_per_axis, model.randomness_space)
			point′ = model.simulation_function(point, action, random_outcomes)
			push!(result, point′)
		end
	end
	result
end

function get_reachable_area(model::SimulationModel, partition::Partition, action)
	result = Set()
	for point in SupportingPoints(model.samples_per_axis, partition)
		for random_outcomes in SupportingPoints(model.samples_per_axis, model.randomness_space)
			point′ = model.simulation_function(point, action, random_outcomes)
			point′ isa Tuple ||@show point′
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
		slice;
		colors=(:black, :gray),
		plotargs...)

	ix, iy = indexof((==(Colon())), slice)
	
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
