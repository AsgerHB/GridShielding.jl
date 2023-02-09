struct Grid
    granularity::Real
    dimensions::Int
    bounds::Bounds
    size::Vector{Int}
    array
end

    
function Grid(granularity, lower_bounds, upper_bounds)
    dimensions = length(lower_bounds)
    
    if dimensions != length(upper_bounds)
        throw(ArgumentError("Inconsistent dimensionality"))
    end

    size = zeros(Int, dimensions)
    for (i, (lb, ub)) in enumerate(zip(lower_bounds, upper_bounds))
        size[i] = ceil((ub-lb)/granularity)
    end
    
    array = zeros(Int8, (size...,))
    Grid(granularity, dimensions, Bounds(lower_bounds, upper_bounds), size, array)
end

Base.show(io::IO, grid::Grid) = println(io, 
"Grid($(grid.granularity), $(grid.bounds.lower), $(grid.bounds.upper))")

# Makes the grid iterable, returning each partition in turn.
Base.length(grid::Grid) = length(grid.array)

Base.size(grid::Grid) = size(grid.array)

struct Partition
    grid::Grid
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
			throw(ArgumentError("State is out of bounds for this grid"))
		end
		
		indices[dim] = floor(Int, (state[dim] - grid.bounds.lower[dim])/grid.granularity) + 1
	end
	
	Partition(grid, indices)
end

function box(grid::Grid, state...)
	box(grid, (state))
end

Base.in(state::Union{Vector, Tuple}, grid::Grid) = begin
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

	upper = [i*granularity + lower[dim] 
		for (dim, i) in enumerate(partition.indices)]

	lower = [b - granularity for b in upper]
	Bounds(lower, upper)
end

Base.in(s::Union{Vector, Tuple}, partition::Partition) = begin
	bounds = Bounds(partition)
	for dim in 1:length(s)
		if !(bounds.lower[dim] <= s[dim] < bounds.upper[dim])
			return false
		end
	end
	return true
end

function set_value!(partition::Partition, value)
	partition.grid.array[partition.indices...] = value
end

function set_values!(squares::Vector{Partition}, value)
	for partition in squares
		set_value!(partition, value)
	end
end

function get_value(partition::Partition)
	partition.grid.array[partition.indices...]
end

function clear!(grid::Grid)
	for partition in grid
		set_value!(partition, 0)
	end
end

function initialize!(grid::Grid, value_function=(_) -> 1)
	for partition in grid
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

function draw(grid::Grid, slice;
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
	y_lower = grid.bounds.lower[y]
	y_upper = grid.bounds.upper[y]
	
	x_tics = x_lower:grid.granularity:x_upper
	y_tics = y_lower:grid.granularity:y_upper
	
	array = view(grid.array, slice...)
	array = transpose(array) # Transpose argument for heatmap() seems to be ignored.
	hm = heatmap(x_tics, y_tics, 
					array,
					c=colors,
					colorbar=nothing)

	if show_grid && length(grid.bounds.lower[x]:grid.granularity:grid.bounds.lower[x]) < 100
		
		vline!(grid.bounds.lower[x]:grid.granularity:grid.bounds.upper[x], 
				color=:gray, label=nothing)
		
		hline!(grid.bounds.lower[y]:grid.granularity:grid.bounds.upper[y], 
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

function cover(grid::Grid, lower, upper)
	throw(Error("Not updated"))
	iv_lower = floor((v_lower - grid.v_min)/grid.granularity) + 1 # Julia indexes start at 1
	iv_upper = floor((v_upper - grid.v_min)/grid.granularity) + 1
	
	ip_lower = floor((p_lower - grid.p_min)/grid.granularity) + 1
	ip_upper = floor((p_upper - grid.p_min)/grid.granularity) + 1
	
	# Discard squares outside the grid dimensions
	iv_lower = max(iv_lower, 1)
	iv_upper = min(iv_upper, grid.v_count)
	
	ip_lower = max(ip_lower, 1)
	ip_upper = min(ip_upper, grid.p_count)
	
	[ (iv, ip)
		for iv in iv_lower:iv_upper
		for ip in ip_lower:ip_upper
	]
end

# My grids keep breaking because of the type circus I have.
# This is my own fault for not making a proper package. 
function robust_grid_serialization(file, grid::Grid)	
	grid_as_tuple = (;grid.granularity,
					  grid.dimensions,
					  grid.bounds.lower, grid.bounds.upper,
					  grid.size,
					  grid.array)
	serialize(file, grid_as_tuple)
end

# ╔═╡ 861aacdf-e310-410d-a73f-1c6957f35073
function robust_grid_deserialization(file)
	f = deserialize(file)

	# Check that the imported file has the correct fields
	if length(fieldnames(typeof(f)) ∩ fieldnames(typeof(Grid(1, [0, 0], [3, 3])))) < 6
		throw(ArgumentError("The selected file does not have the correct format."))
	end
	
	grid = Grid(f.granularity, f.bounds.lower, f.bounds.upper)
	for partition in grid
		set_value!(partition, f.array[partition.indices...])
	end
	
	grid
end

# Offset for the ascii table. The zero value is offset to A and so on all the way to Z at 90.
# After this comes [ \ ] ^ _ and ` 
# Why these are here I don't know, but then come the lower case letters.
char_offset = 65

function stringdump(grid)
	result = Vector{Char}(repeat('?', prod(grid.size)))

	for (i, v) in enumerate(grid.array)
		result[i] = Char(v + char_offset)
	end
	
	return String(result)
end

function get_c_library_header(grid::Grid, description)
	arrayify(x) = "{ $(join(x, ", ")) }"
	
	bounds.lower = arrayify(grid.bounds.lower)
	bounds.upper = arrayify(grid.bounds.upper)
	size = arrayify(grid.size)
	"""
/* This code was automatically generated by function get_c_library_header*/
const int char_offset = $char_offset;
const char grid[] = "$(stringdump(grid))";
const float granularity = $(grid.granularity);
const int dimensions = $(grid.dimensions);
const int size[] = $(size);
const float bounds.lower[] = $(bounds.lower);
const float bounds.upper[] = $(bounds.upper);
// Description: $description """
end