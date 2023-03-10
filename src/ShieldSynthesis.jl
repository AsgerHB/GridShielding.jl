function get_transitions(reachability_function, actions, grid)
	result = Dict()
	
	for action in actions
		result[action] = Array{Vector{Any}}(undef, size(grid))
	end
	
	for partition in grid
		for action in actions
			result[action][partition.indices...] = reachability_function(partition, action)
		end
	end
	result
end

function get_transitions(reachability_function, actions::Type, grid)
	get_transitions(reachability_function, instances(actions), grid)
end

function make_shield(reachability_function::Function, actions, grid::Grid; max_steps=typemax(Int))
	R_computed = get_transitions(reachability_function, actions, grid)
	make_shield(R_computed, actions, grid; max_steps)
end

function get_new_value(R_computed::Dict{Any}, actions, partition::Partition)
	bad = actions_to_int([]) # No actions allowed in this partition; do not go here.
	value = get_value(partition)

	if value == bad # Bad partitions stay bad. 
		return bad
	end
	
 	result = []

	for action in actions
		reachable = R_computed[action][partition.indices...]
		reachable = [Partition(partition.grid, i) for i in reachable]
		
		action_allowed = true
		for partition′ in reachable
			if get_value(partition′) == bad
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

function get_new_value(R_computed::Dict{Any}, actions::Type, partition::Partition)
	get_new_value(R_computed, instances(actions), partition)
end

#Take a single step in the fixed point compuation.
function shield_step(R_computed::Dict{Any}, actions, grid::Grid)
	grid′ = Grid(grid.granularity, grid.bounds.lower, grid.bounds.upper)

	for partition in grid
		grid′.array[partition.indices...] = get_new_value(R_computed, actions, partition)
	end
	grid′
end

function make_shield(R_computed::Dict{Any}, actions, grid::Grid; max_steps=typemax(Int))
	i = max_steps
	grid′ = nothing
	while i > 0
		grid′ = shield_step(R_computed, actions, grid)
		if grid′.array == grid.array
			break
		end
		grid = grid′
		i -= 1
	end
	(result=grid′, max_steps_reached=i==0)
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
