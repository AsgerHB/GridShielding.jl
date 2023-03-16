struct SupportingPoints
    per_axis
    bounds::Bounds

    function SupportingPoints(per_axis, bounds::Bounds)
        if per_axis isa Number
            per_axis = [per_axis for _ in 1:get_dim(bounds)]
        end
        new(per_axis, bounds)
    end

    function SupportingPoints(per_axis, partition::Partition)
        SupportingPoints(per_axis, Bounds(partition))
    end
end

function get_spacing_sizes(s::SupportingPoints, dimensionality)
    upper, lower = s.bounds.upper, s.bounds.lower
    spacings = [upper[dim] - lower[dim] for dim in 1:dimensionality]
    spacings = [s.per_axis[dim] == 1 ?  0 :  spacing/(s.per_axis[dim] - 1) 
        for (dim, spacing) in enumerate(spacings)]
end

Base.length(s::SupportingPoints) = begin
    if s.bounds.upper == s.bounds.lower
        return 1
    end
    return prod(s.per_axis[dim] for dim in 1:get_dim(s.bounds))
end

Base.iterate(s::SupportingPoints) = begin
    if any([per_axis - 1 < 0 for per_axis in s.per_axis])
        throw(ArgumentError("Samples per axis must be at least 1."))
    end
    dimensionality = get_dim(s.bounds)

    lower, upper = s.bounds.lower, s.bounds.upper

    if upper == lower
        return lower, :terminate
    end
    
    spacings = get_spacing_sizes(s, dimensionality)
    
    # The iterator state  is (spacings, indices).
    # First sample always in the lower-left corner. 
    return Tuple(lower), (spacings, zeros(Int, dimensionality))
end

Base.iterate(s::SupportingPoints, terminate::Symbol) = begin
    if  terminate != :terminate
        error("Call error.")
    end
    return nothing
end

Base.iterate(s::SupportingPoints, state) = begin
    
    dimensionality = get_dim(s.bounds)
    spacings, indices = state
    indices = copy(indices)

    for dim in 1:dimensionality
        indices[dim] += 1
        if indices[dim] <= s.per_axis[dim] - 1
            break
        else
            if dim < dimensionality
                indices[dim] = 0
                # Proceed to incrementing next row
            else
                return nothing
            end
        end
    end

    sample = Tuple(i*spacings[dim] + s.bounds.lower[dim] 
                    for (dim, i) in enumerate(indices))
    
    sample, (spacings, indices)
end