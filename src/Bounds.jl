struct Bounds{T}
    lower::Vector{T}
    upper::Vector{T}

    function Bounds(lower::Vector{T}, upper::Vector{T}) where T
        if length(lower) != length(upper)
            error("Inconsistent dimensionality")
        end
        return new{T}(lower, upper)
    end
end

function Bounds(lower::Tuple, upper::Tuple)
    Bounds(lower |> collect, upper |> collect)
end

function Bounds(lower::Dict, upper::Dict, dimensionality)
    lower′ = [-Inf for _ in 1:dimensionality]
    upper′ = [ Inf for _ in 1:dimensionality]

    for (k, v) in lower
        lower′[k] = v
    end
    for (k, v) in upper
        upper′[k] = v
    end
    Bounds(lower′, upper′)
end

function get_dim(bounds::Bounds)
    length(bounds.lower)
end


Base.in(a, b::Bounds) = begin
    dimensionality = length(b.lower)
    for i in 1:dimensionality
        if a[i] < b.lower[i] || a[i] >= b.upper[i]
            return false
        end
    end
    return true
end

Base.:(==)(a::Bounds, b::Bounds)  = begin
    for (x, y) in hcat(zip(a.lower, b.lower)..., zip(a.upper, b.upper)...)
        if x != y
            return false
        end
    end
    return true
end

Base.isapprox(a::Bounds, b::Bounds, params...) = begin
    for (x, y) in hcat(zip(a.lower, b.lower)..., zip(a.upper, b.upper)...)
        if !isapprox(x, y, params...)
            return false
        end
    end
    return true
end

Base.intersect(a::Bounds, b::Bounds) = begin
	if get_dim(a) != get_dim(b) 
		error("Inconsistent dimensionality")
	end
	dimensionality = get_dim(a)
	lower, upper = [], []
	for dim in 1:dimensionality
		push!(lower, max(a.lower[dim], b.lower[dim]))
		push!(upper, min(a.upper[dim], b.upper[dim]))
	end
	Bounds(lower, upper)
end

Base.clamp(x::V, bounds::Bounds) where V<:AbstractVector = begin
	x′ = copy(x)
	clamp!(x, bounds)
end

Base.clamp!(x::V, bounds::Bounds) where V<:AbstractVector = begin
	for i in 1:get_dim(bounds)
        upper = bounds.upper[i]
        if typeof(upper) <: AbstractFloat
            upper = prevfloat(upper)
        elseif  typeof(upper) <: Integer
            upper -= 1
        else
            error("Unsupported type for upper bound: $(typeof(upper)) in bounds: $bounds")
        end

		x[i] = clamp(x[i], bounds.lower[i], upper)
	end
	x
end


Base.clamp!(bounds::Bounds, x::V) where V<:AbstractVector = begin
    clamp!(x, bounds)
end

Base.clamp(bounds::Bounds, x::V) where V<:AbstractVector = begin
    clamp(x, bounds)
end


function bounded(bounds::Bounds)
	for b in bounds.lower
		if b == -Inf || b == Inf
			return false
		end
	end
	for b in bounds.upper
		if b == Inf || b == -Inf
			return false
		end
	end
	return true
end

function magnitude(bounds::Bounds)
    bounds.upper .- bounds.lower
end

function magnitude(bounds::Bounds, axis)
    bounds.upper[axis] - bounds.lower[axis]
end

# Draw bounds as rectangles
@recipe function rectangle(bounds::Bounds, pad=0.00) 
	l, u = bounds.lower, bounds.upper
	xl, yl = l .- pad
	xu, yu = u .+ pad
	Shape(
		[xl, xl, xu, xu],
		[yl, yu, yu, yl])
end

# # Draw bounds as rectangles
# @recipe function rectangle(bounds::AbstractArray{Bounds}, pad=0.00)
# 	[rectangle(b, pad) for b in bounds]
# end