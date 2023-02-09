module GridShielding

using Plots

export Bounds,  get_dim, bounded, magnitude
include("Bounds.jl")

export SupportingPoints, get_spacing_sizes
include("SuppotingPoints.jl")

export Grid, Partition, box, bounds, set_value!, get_value, clear!, initialize!, indexof, draw, cover, robust_grid_serialization, stringdump, get_c_library_header
include("Grids.jl")


module RW
using Plots
export rwmechanics, Pace, simulate, draw_next_step!, draw_walk!, take_walk, evaluate
include("RWExample.jl")
end#module

end#module
