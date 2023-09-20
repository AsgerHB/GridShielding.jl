function memory_usage_for_precomputed_reachability(result_size, grid::Grid)
	# Assuming 1 byte per integer. 
	# A partition is saved with 1 integer per dimension.
	# And then these are stored in a matrix same size as the grid.
	"$(round((result_size*grid.dimensions + length(grid))/1.049e+6, digits=2))mb"
end

function get_transitions(reachability_function::Function, 
			actions::A, 
			grid::Grid
		)::Dict{T, Array{Vector{Vector{Int64}}}} where {T, A<:AbstractArray{T}}

	result = Dict{T, Array{Vector{Vector{Int64}}}}()
	result_size = 0
	print_every = 10000
	
	for action in actions
		result[action] = Array{Vector{Vector{Int64}}}(undef, size(grid))
	end
	
	for (i, partition) in enumerate(grid)
		get_value(partition) == actions_to_int([]) && continue
		for action in actions
			reachable::Vector{Vector{Int64}} = reachability_function(partition, action)
			result_size += length(reachable)
			result[action][partition.indices...] = reachable
		end

		#i%print_every == 0 && @debug "Precomputed for partition $i out of $(length(grid)).\nMemory usage: $(memory_usage_for_precomputed_reachability(result_size, grid))."
	end
	#@debug "Precomputed for partition $(length(grid)) out of $(length(grid)).\nMemory usage: $(memory_usage_for_precomputed_reachability(result_size, grid))."
	result
end

function get_transitions(reachability_function::Function, actions::Type, grid::Grid)
	get_transitions(reachability_function, instances(actions) |> collect, grid)
end

function make_shield(reachability_function::Function, actions, grid::Grid; max_steps=typemax(Int))
	R_computed = get_transitions(reachability_function, actions, grid)
	make_shield(R_computed, actions, grid; max_steps)
end

function get_new_value(R_computed::Dict{Y, Array{Vector{Vector{Int64}}}}, actions::Vector, partition::Partition{T})::T where {T, Y}
	bad::T = actions_to_int([]) # No actions allowed in this partition; do not go here.
	value = get_value(partition)
	array = partition.grid.array

	if value == bad # Bad partitions stay bad. 
		return bad
	end
	
 	result = []

	for action in actions
		reachable::Vector{Vector{Int64}} = R_computed[action][partition.indices...]
		
		action_allowed = true
		for r in reachable # For each reachable partition... (partition data type not used, to save time.)
			if array[r...]::T == bad # I didn't know you could type-decorate specific things like this. For some reason, julia can't infer that type, so this is a huge speed-up.
				action_allowed = false
				break
			end
		end

		if action_allowed 
			push!(result, action)
		end
	end

	actions_to_int(result)
end

#Take a single step in the fixed point compuation.
function shield_step(R_computed::Dict, actions::Vector, grid::Grid)
	grid′ = Grid(grid.granularity, grid.dimensions, grid.bounds, grid.size, copy(grid.array))

	for partition in grid
		grid′.array[partition.indices...] = get_new_value(R_computed, actions, partition)
	end
	grid′
end

function make_shield(R_computed::Dict, actions::Vector, grid::Grid; max_steps=typemax(Int))
	i = 0
	grid′ = grid
	while i < max_steps
		grid′ = shield_step(R_computed, actions, grid)
		if grid′.array == grid.array
			break
		end
		grid = grid′
		i += 1
		@debug "Finished fixed point iteration $i."
	end
	(result=grid′, max_steps_reached=i==max_steps)
end

function make_shield(R_computed::Dict, actions, grid::Grid; max_steps=typemax(Int))
	make_shield(R_computed, actions |> instances |> collect, grid; max_steps)
end


function draw_shield(shield::Grid, actions; v_ego=0, plotargs...)
	
	partition = box(shield, [v_ego, 0, 0])
	index = partition.indices[1]
	slice = [index, :, :]

	# Count number of allowed actions in each partition
	shield′ = Grid(shield.granularity, shield.bounds.lower, shield.bounds.upper)
	for partition in shield
		partition′ = Partition(shield′, partition.indices)
		
		allowed_actions = get_value(partition)
		allowed_actions = int_to_actions(actions, allowed_actions)
		
		set_value!(partition′, length(allowed_actions))
	end
	
	draw(shield′, slice, 
		colors=shieldcolors, 
		color_labels=shieldlabels,
		legend=:bottomleft,
		xlabel="v_front",
		ylabel="distance",
		title="v_ego=$v_ego";
		plotargs...)
end

function shielding_function(shield::Grid, actions, fallback_policy::Function, 
		s, action)

	# Return the same action if the state is out of bounds
	if !(s ∈ shield)
		return action
	end
	
	partition = box(shield, s)
	allowed = int_to_actions(actions, get_value(partition))

	if action ∈ allowed
		return action
	end

	if length(allowed) == 0
		return action
	end

	corrected_action = fallback_policy(s, allowed)

	if !(corrected_action ∈ allowed)
		throw(error("Fallback policy returned illegal action"))
	end

	corrected_action
end


get_shielding_function(shield::Grid, actions, fallback_policy::Function) = 
	(s, a) -> shielding_function(shield, actions, fallback_policy, s, a)
