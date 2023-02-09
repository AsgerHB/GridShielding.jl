module GridShielding

using Plots

export Bounds,  get_dim, bounded, magnitude
include("Bounds.jl")

export Grid, Partition, box, bounds, set_value!, get_value, clear!, initialize!, indexof, draw, cover, robust_grid_serialization, stringdump, get_c_library_header
include("Grids.jl")

export SupportingPoints, get_spacing_sizes
include("SuppotingPoints.jl")

export SimulationModel, possible_outcomes, get_reachable_area, get_barbaric_reachability_function, draw_barbaric_transition_3D!, draw_barbaric_transition!, set_reachable_area!
include("BarbaricReachability.jl")

export actions_to_int, int_to_actions
include("ActionConversion.jl")


module RW
using Plots
export rwmechanics, Pace, simulate, draw_next_step!, draw_walk!, take_walk, evaluate
include("RWExample.jl")
end#module

end#module
