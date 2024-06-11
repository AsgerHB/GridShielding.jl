"""
	Grid(granularity, bounds_lower, bounds_upper; [data_type=Int8])
	Grid(granularity, bounds::Bounds; [data_type=Int8])
"""
struct Grid{T, N<:Number, U<:Number, M<:Number}
    granularity::Vector{N}
    dimensions::U
    bounds::Bounds{M}
    size::Vector{U}
    array::Array{T}	# TODO: ::A<:Array{T}
end


"""
    get_size(granularity, bounds::Bounds)

Compute the size for a grid with the given bounds and granualrities. Might be good to call before actually allocating that amount of memoryy.
"""
function get_size(granularity, bounds::Bounds)
    dimensions = get_dim(bounds)
	size = zeros(Int, dimensions)
    for (i, (lb, ub)) in enumerate(zip(bounds.lower, bounds.upper))
        size[i] = ceil((ub-lb)/granularity[i])
    end
	size
end

function Grid(granularity, bounds_lower, bounds_upper; data_type=Int8)
	Grid(granularity, Bounds(bounds_lower, bounds_upper); data_type)
end

function Grid(granularity, bounds::Bounds; data_type=Int8)
    dimensions = get_dim(bounds)
	if granularity isa Number
		granularity = [granularity for _ in 1:dimensions]
	end

    size = get_size(granularity, bounds)

	if granularity isa Number
		granularity = Tuple(granularity for _ in 1:dimensions)
	end
	# NO-COMMIT: let user choose instead.
    array = zeros(data_type, (size...,))
    Grid(granularity, dimensions, bounds, size, array)
end

Base.show(io::IO, grid::Grid) = println(io, 
"Grid($(grid.granularity), $(grid.bounds.lower), $(grid.bounds.upper))")

# Makes the grid iterable, returning each partition in turn.
Base.length(grid::Grid) = length(grid.array)

Base.size(grid::Grid) = size(grid.array)

struct Partition{T}
    grid::Grid{T}
    indices::Vector{Int}
end

# Begin iteration.
# State is the indices of the previous partition
Base.iterate(grid::Grid) = begin
    indices = ones(Int, grid.dimensions)
    partition = Partition(grid, indices)
    partition, indices
end

Base.iterate(grid::Grid, state) = begin
    indices = copy(state)
    
    for dim in 1:grid.dimensions
        indices[dim] += 1
        if indices[dim] <= grid.size[dim]
            break
        else
            if dim < grid.dimensions
                indices[dim] = 1
                # Proceed to incrementing next row
            else
                return nothing
            end
        end
    end
    Partition(grid, indices), indices
end

function box(grid::Grid, state)
	indices = zeros(Int, grid.dimensions)

	for dim in 1:grid.dimensions
		if !(grid.bounds.lower[dim] <= state[dim] < grid.bounds.upper[dim])
			throw(ArgumentError("State $state is outside this grid's bounds $(grid.bounds)"))
		end
		
		indices[dim] = floor(Int, (state[dim] - grid.bounds.lower[dim])/grid.granularity[dim]) + 1
	end
	
	Partition(grid, indices)
end

function box(grid::Grid, state...)
	box(grid, (state))
end

Base.:(==)(a::Grid, b::Grid) = a.array == b.array

#= I'm beginning to understand the advice of not having too specific type decorations because this function signature has been an issue for me multiple times. It used to be Base.in(state::Union{Vector, Tuple}, grid::Grid), but many times I've tried to check things like Int ∈ Grid by mistake. 
The ∈ operator has a bunch of type signatures, including just returning "false" in the most general case (which is very slow for some reason). So if I made a type error when using it with a grid or partition, it would just silently return "false" because I'd specified the check to only be for tuples and vectors.
=#
Base.in(state, grid::Grid) = begin
	for dim in 1:grid.dimensions
		if !(grid.bounds.lower[dim] <= state[dim] < grid.bounds.upper[dim])
			return false
		end
	end
	return true
end

Base.in(partition::Partition, grid::Grid) = partition.grid == grid

function Bounds(partition::Partition)
	grid = partition.grid
	granularity, lower = grid.granularity, grid.bounds.lower

	upper = Tuple(i*granularity[dim] + lower[dim] 
		for (dim, i) in enumerate(partition.indices))

	lower = Tuple(u - granularity[dim] for (dim, u) in enumerate(upper))
	Bounds(lower, upper)
end

Base.in(s, partition::Partition) = begin
	bounds = Bounds(partition)
	for dim in 1:length(s)
		if !(bounds.lower[dim] <= s[dim] < bounds.upper[dim])
			return false
		end
	end
	return true
end

Base.isequal(a::Partition, b::Partition) = a.indices == b.indices && a.grid === b.grid

Base.deepcopy(grid::Grid) = begin
	
	result = Grid(grid.granularity, grid.bounds.lower, grid.bounds.upper)
	for (i, v) in enumerate(grid.array)
		result.array[i] = v
	end
	return result
end

function set_value!(partition::Partition, value)
	partition.grid.array[partition.indices...] = value
end

function set_values!(partitions::Vector{Partition}, value)
	for partition in partitions
		set_value!(partition, value)
	end
end

function get_value(partition::Partition{T})::T where T
	partition.grid.array[partition.indices...]
end

function clear!(grid::Grid)
	for partition in grid
		set_value!(partition, 0)
	end
end

function initialize!(grid::Grid, value_function=(_) -> 1)
	@progress for partition in grid
		set_value!(partition, value_function(Bounds(partition)))
	end
end


function indexof(clause, list)
	result = []
	for (i, v) in enumerate(list)
		if clause(v)
			push!(result, i)
		end
	end
	result
end

function draw(grid::Grid, slice=[:,:];
				colors=[:white, :black], 
				color_labels=[],
				show_grid=false, 
				plotargs...)
	
	colors = cgrad(colors, length(colors), categorical=true)

	if 2 != count((==(Colon())), slice)
		throw(ArgumentError("The slice argument should be an array of indices and exactly two colons. Example: [:, 10, :]"))
	end
	
	x, y = indexof((==(Colon())), slice)
	
	x_lower = grid.bounds.lower[x]
	x_upper = grid.bounds.upper[x]
	x_count = grid.size[x]
	y_lower = grid.bounds.lower[y]
	y_upper = grid.bounds.upper[y]
	y_count = grid.size[y]
	
	x_tics = [x_lower + i*grid.granularity[x] for i in 0:x_count]
	y_tics = [y_lower + i*grid.granularity[y] for i in 0:y_count]
	
	array = view(grid.array, slice...)
	array = transpose(array) # Transpose argument for heatmap() seems to be ignored.
	hm = heatmap(x_tics, y_tics, 
					array,
					c=colors,
					colorbar=nothing)

	if show_grid && length(grid.bounds.lower[x]:grid.granularity[x]:grid.bounds.lower[x]) < 100
		
		vline!(grid.bounds.lower[x]:grid.granularity[x]:grid.bounds.upper[x], 
				color=:gray, label=nothing)
		
		hline!(grid.bounds.lower[y]:grid.granularity[y]:grid.bounds.upper[y], 
				color=:gray, label=nothing)
	end

	# Show labels
	if length(color_labels) > 0
		if length(color_labels) != length(colors)
			throw(ArgumentError("Length of argument color_labels does not match  number of colors."))
		end
		for (color, label) in zip(colors, color_labels)
			# Apparently shapes are added to the legend even if the list is empty
		    plot!(Float64[], Float64[], seriestype=:shape, 
		        label=label, color=color)
		end
	end

	plot!(;plotargs...) # Pass additional arguments to Plots.jl
end