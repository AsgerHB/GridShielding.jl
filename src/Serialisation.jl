⨝ = joinpath

## Robust Grid (De)Serialisation ##

"""
    robust_grid_serialization(file, grid::Grid)	

Serialize grid into a tuple of simple types and an array. 
This makes deserialization much more reliable compared to serializing a struct of type Grid. 

Even if the type definition changes, the old version might still be readable.
"""
function robust_grid_serialization(file, grid::Grid)
	grid_as_tuple = (;grid.granularity,
					  grid.dimensions,
					  grid.bounds.lower, grid.bounds.upper,
					  grid.size,
					  grid.array)
	serialize(file, grid_as_tuple)
end

"""
    robust_grid_deserialization(file)

Returns an object of type `Grid` by reading from a file which has been exported using `robust_grid_serialization`.
"""
function robust_grid_deserialization(file)
	f = deserialize(file)

	# Check that the imported file has the correct fields
	actual_fields = fieldnames(typeof(f))
	expected_fields = [:granularity, :dimensions, :lower, :upper, :size, :array]
	if length(actual_fields ∩ expected_fields) < 6
		throw(error("The selected file does not have the correct format.\nExpected: $expected_fields\nActual:  $actual_fields"))
	end
	
	# Get the type of the values stored in the array
	data_type = typeof(f.array).parameters[1]
	
	grid = Grid(f.granularity, f.lower, f.upper; data_type)
	for partition in grid
		set_value!(partition, f.array[partition.indices...])
	end
	
	grid
end

## Exporting as C library ##

function file_replace(file_path, replacements...)
	lines = readlines(file_path)
	open(file_path, "w") do file_buffer
		for line in lines
			println(file_buffer, replace(line, replacements...))
		end
	end
end

shield_c_path = joinpath(@__DIR__, "../misc/shield.c")

# Header containing the constants needed to read the shield
function get_header(grid::Grid)	
	arrayify(x) = "{ $(join(x, ", ")) }"
	granularity = arrayify(grid.granularity)
	size = arrayify(grid.size)
	lower_bounds = arrayify(grid.bounds.lower)
	upper_bounds = arrayify(grid.bounds.upper)
	hader = """
/* This code was automatically generated by julia function get_header */
const double granularity[] = $(granularity);
const int dimensions = $(grid.dimensions);
const int size[] = $(size);
const double lower_bounds[] = $(lower_bounds);
const double upper_bounds[] = $(upper_bounds);
extern char _binary_shield_start[];
extern char _binary_shield_end[];
	"""
end

# Dump binary data using `ld` command
function export_to_shield_dump_o(grid::Grid; working_dir=mktempdir())

	# The `ld` utility names the variables it creates after the path it is given
	# So annoying! So I'm specifying a very simple relative path
	# to ensure simple and consistent naming.
	previous_working_dir = pwd()
	cd(working_dir)
	
	# Force encode as Int64 array to ensure consistent binary layout
	array = Array{Int64}(grid.array)

	# htol = convert host endianness to little endian
	write("shield", htol.(array))
	
	read(`ld -r -b binary "shield" -o "shield_dump.o"`)
	# println(`objdump -x shield_dump.o` |> read |> String)
	cd(previous_working_dir)

	return joinpath(working_dir, "shield_dump.o")
end

"""
    get_libshield(shield::Grid; [destination, working_dir, force=false])

Serialize the provided grid into a shared object (.so) file along with a C function to look up its values.
Easily access the shield with any application that can make C function calls. 

The so-file exports the function `get_value(double s1, double s2, double s3)`. 
Number of arguments is the same as the dimensionality of the shield. 
Returns the integer value for the corresponding state.

!!! example
    For a Random Walk shield, `get_value(0.9, 0.1)` would return `3`, 
    indicating that in the state `(x=0.9, t=0.1)` the actions {fast, slow} are both allowed. 
    (see `int_to_actions`)

**Returns:** Path to the exported `libshield.so` shared object.

**Arguments**
- `shield`: Shield to export.
- `destination`: Optional filepath. The compiled file will be copied to here.
- `working_dir`: Temp folder by default. Several files will be generated here.
- `force`: Whether to overwrite existing file at destination, if it exists.
"""
function get_libshield(shield::Grid; destination=nothing, working_dir=mktempdir(), force=false)
	# Dump binary data using `ld` command
	shield_dump_o = export_to_shield_dump_o(shield; working_dir)

	# Header containing the constants needed to read the shield
	shield_h = working_dir ⨝ "shield.h"
	write(shield_h, get_header(shield))

	# shield.c source file that contains lookup functions
	shield_c = working_dir ⨝ "shield.c"
	cp(shield_c_path, shield_c, force=true)
	# Rewrite function `get_value` to take the correct number of parameters.
	# Should correspond to size of the state vector.
	vars = join(["s$i" for i in 1:shield.dimensions], ", ")
	double_vars = join(["double s$i" for i in 1:shield.dimensions], ", ")
	file_replace(shield_c, 
		"s1, s2" => vars,
		"double s1, double s2" => double_vars)

	# Compile
	shield_o = working_dir ⨝ "shield.o"
	libshield_so = working_dir ⨝ "libshield.so"
	`gcc -c -fPIC $shield_c -o $shield_o` |> run
	`gcc -shared $shield_dump_o $shield_o $shield_h  -o $libshield_so` |> run

	# Optionally copy to destination
	if !isnothing(destination)
        if isdir(destination)
		    destination = destination ⨝ basename(libshield_so)
        end
		cp(libshield_so, destination; force)
		return destination
	end
	
	return libshield_so
end

"""
!!! warn "Deprecated"
    Use `get_libshield` instead.
"""
function get_c_library_header(grid::Grid, description)
	arrayify(x) = "{ $(join(x, ", ")) }"
	
	granularity = arrayify(grid.granularity)
	size = arrayify(grid.size)
	lower_bounds = arrayify(grid.bounds.lower)
	upper_bounds = arrayify(grid.bounds.upper)
	return """
/* This code was automatically generated by function get_c_library_header*/
const int char_offset = $char_offset;
const char grid[] = "$(stringdump(grid))";
const float granularity[] = $(granularity);
const int dimensions = $(grid.dimensions);
const int size[] = $(size);
const float lower_bounds[] = $(lower_bounds);
const float upper_bounds[] = $(upper_bounds);
// Description: $description """
end

# Offset for the ascii table. The zero value is offset to A and so on all the way to Z at 90.
# After this comes [ \ ] ^ _ and ` 
# Why these are here I don't know, but then come the lower case letters.
char_offset = 65

function stringdump(grid)
	result = Vector{Char}(repeat('?', prod(grid.size)))

	for (i, v) in enumerate(grid.array)
		v + char_offset > 126 && error("Value $v in grid is out of range. Max value supported: $(126 - 65)")
		result[i] = Char(v + char_offset)
	end
	
	return String(result)
end

## Exporting to Numpy array + JSON ##

function export_numpy_array(grid, destination)
	np = pyimport("numpy")
	pyshield = np.array(grid.array)
	open(destination, write=true, create=true) do 🗋
		np.save(🗋, pyshield)
	end
end

"""
	get_meta_info(grid::Grid; variables::A, binary_variables::A, actions::Type, env_id::S) 
		where {A<:AbstractArray, S<:AbstractString}

Returns a dictionary containing structured meta-info on the grid. 

Arguments: (NB: Mostly KW)
 - `grid`: The grid in question. Bounds and granularity are inferred from this.
 - `variables`: Axis labels for axes that are not binary.
 - `binary_variables`: Labels for axes that are binary.
 - `actions`: Enum representing the available axes. This will be used to create an `id_to_actionset` list.
 - `env_id`: Descriptive name of the grid.

Example: 

	get_meta_info(grid′,
		variables=["x", "y"], 
		binary_variables=["a"],
		actions=Action,
		env_id="test grid")
"""
function get_meta_info(grid::Grid; variables::A, binary_variables::AA, actions::Type, env_id::S) where {A<:AbstractArray, AA<:AbstractArray, S<:AbstractString}
	meta = (
		"variables" => variables,
		"env_id" => env_id,
	
		"id_to_actionset" => [
			(a => [a′ ∈ int_to_actions(actions, a) for a′ in instances(actions)])
			for a in unique(grid.array) ],
	
		"n_actions" => length(instances(actions)),
		"actions" => instances(actions),
		"bounds" => [grid.bounds.lower, grid.bounds.upper],
		"granularity" => grid.granularity,
		"bvars" => binary_variables
	)
end

"""
	numpy_zip_file(grid::Grid, destination; variables::A, binary_variables::AA, actions::Type, env_id::S) 
	where {A<:AbstractArray, AA<:AbstractArray, S<:AbstractString}

Returns a dictionary containing structured meta-info on the grid. 

Arguments: (NB: Mostly KW)
 - `grid`: The grid in question. Bounds and granularity are inferred from this.
 - `destination`: File path to save to. Errors if exists.
 - `variables`: Axis labels for axes that are not binary.
 - `binary_variables`: Labels for axes that are binary.
 - `actions`: Enum representing the available axes. This will be used to create an `id_to_actionset` list.
 - `env_id`: Descriptive name of the grid.

Example: 

	numpy_zip_file(grid′, "path/to/save/grid.zip",
		variables=["x", "y"], 
		binary_variables=["a"],
		actions=Action,
		env_id="test grid")
"""
function numpy_zip_file(grid::Grid, destination; variables::A, binary_variables::AA, actions::Type, env_id::S) where {A<:AbstractArray, AA<:AbstractArray, S<:AbstractString}
	w = ZipFile.Writer(destination)

	np = pyimport("numpy")
	pyshield = np.array(grid.array)
	np.save(ZipFile.addfile(w, "grid.npy"), pyshield)
	
	meta_info = get_meta_info(grid; variables, binary_variables, actions, env_id)
	
	write(ZipFile.addfile(w, "meta.json"), JSON.json(meta_info))
	close(w)
end
