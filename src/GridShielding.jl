module GridShielding

using Plots
using ProgressLogging
using HypothesisTests

# Serialization stuff
using Serialization
using JSON
using PyCall
using ZipFile

# TODO: Only export relevant names (remember to update the testing-notebooks).
export Bounds, get_dim, bounded, magnitude, centre
include("Bounds.jl")

export Grid, Partition, get_size, box, bounds, set_value!, get_value, clear!, initialize!, indexof, draw, cover
include("Grids.jl")

export robust_grid_serialization, robust_grid_deserialization, get_libshield, export_numpy_array, get_meta_info, export_meta_info, numpy_zip_file
include("Serialisation.jl")

export SupportingPoints, get_spacing_sizes
include("SuppotingPoints.jl")

export SimulationModel, worst_case_memory_usage, possible_outcomes, get_reachable_area, get_barbaric_reachability_function, draw_barbaric_transition_3D!, draw_barbaric_transition!, set_reachable_area!
include("BarbaricReachability.jl")

export actions_to_int, int_to_actions
include("ActionConversion.jl")

export get_transitions, make_shield, shield_step, draw_shield, shielding_function, get_shielding_function
include("ShieldSynthesis.jl")

export evaluate_safety
include("EvaluateSafety.jl")


module RW
using Plots
export rwmechanics, Pace, simulate, draw_next_step!, draw_walk!, simulate_trace
include("RWExample.jl")
end#module

module BB
using Plots
using StatsBase
using Distributions
export bbmechanics, Action, hit, nohit, simulate_point, simulate_sequence, evaluate, evaluate_safety, animate_trace, random_policy
include("BBExample.jl")
end#module

end#module
