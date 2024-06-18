# The "Random Walk" example.

struct RWMechanics
    t_min
    t_max
    x_min
    x_max
    ϵ
    δ_fast
    δ_slow
    τ_fast
    τ_slow

    function RWMechanics(
        t_min=0.0,
        t_max=1.0,
        x_min=0.0,
        x_max=1.0,
        ϵ=0.04,
        δ_fast=0.17,
        δ_slow=0.1,
        τ_fast=0.05,
        τ_slow=0.12)
    
        new(t_min, t_max, x_min, x_max, ϵ, δ_fast, δ_slow, τ_fast, τ_slow)
    end
end

rwmechanics = RWMechanics()

@enum Pace slow fast

function simulate(m::RWMechanics, x, t, a, random_outcomes)
    if x > m.x_max # game has ended.
        return x, 0
    end

	x′, t′ =  x, t

	if a == fast
		x′ = x + m.δ_fast + random_outcomes[1]
		t′ = t + m.τ_fast + random_outcomes[2]
	else
		x′ = x + m.δ_slow + random_outcomes[1]
		t′ = t + m.τ_slow + random_outcomes[2]
	end
	
	x′, t′
end


function simulate(m::RWMechanics, x, t, a)
	random_outcomes = (rand(-m.ϵ:0.005:m.ϵ), rand(m.ϵ:0.005:m.ϵ))
	simulate(m::RWMechanics, x, t, a, random_outcomes)
end

struct Trace
	states::Vector{Tuple{Float64, Float64}}
	actions::Vector{Pace}
	total_cost::Float64
end

function simulate_trace(m::RWMechanics, 
					policy::Function;
                    cost_function=(x, t, a) -> a == fast ? 2 : 1)
	xs, ts, actions = [m.x_min], [m.t_min], []
	total_cost = 0.

	while last(xs) < m.x_max && last(ts) < m.t_max
		a = policy(last(xs), last(ts))
		x, t = simulate(m, last(xs), last(ts), a)
		total_cost += cost_function(last(xs), last(ts), a)
		push!(xs, x)
		push!(ts, t)
		push!(actions, a)
	end

	Trace(collect(zip(xs, ts)), actions, total_cost)
end

slow_color, fast_color = :coral, :cornflowerblue


function draw_next_step!(m::RWMechanics, x, t, a=:both;
			colors=(slow=slow_color, fast=fast_color, line=:black))

	if a == :both
		draw_next_step!(m, x, t, fast, colors=colors)
		return draw_next_step!(m, x, t, :slow, colors=colors)
	end
	color = a == fast ? colors.fast : colors.slow
	linestyle = a == fast ? :solid : :dash
	scatter!([x], [t], 
		markersize=3, 
		markerstrokewidth=0,
		color=colors.line,
		label=nothing)

	δ, τ = a == fast ? (m.δ_fast, m.τ_fast) : (m.δ_slow, m.τ_slow)
	δ, τ = δ + x, τ + t

	plot!(Shape([δ - m.ϵ, δ - m.ϵ, δ + m.ϵ, δ + m.ϵ], 
				[τ - m.ϵ, τ + m.ϵ, τ + m.ϵ, τ - m.ϵ]), 
			color=color,
			opacity=0.8,
			linewidth=0,
			label=nothing)

	plot!([x, δ], [t, τ], 
		linestyle=linestyle, 
		linewidth=1, 
		linecolor=color, 
		label=nothing)
end


function draw_walk!(xs, ts, actions; 
		cost=nothing,
        colors=(slow=slow_color, fast=fast_color, line=:black))
    
    linecolors = [a == fast ? colors.fast : colors.slow for a in actions]
    linestyles = [a == fast ? :solid : :dash for a in actions]
    push!(linecolors, colors.line)
    push!(linestyles, :solid)

    if !isnothing(cost)
        scatter!([], m=(0, :white), msw=0, label="cost: $cost")
    end
    
    plot!(xs, ts,
        markershape=:circle,
        markersize=3,
        markercolor=colors.line,
        markerstrokewidth=0,
        linewidth=3,
        linecolor=linecolors,
        linestyle=linestyles,
		lim=(0, 1.2),
		xlabel="x",
		ylabel="t",
        label=nothing)

	hline!([1], color=:gray, label=nothing)
	vline!([1], color=:gray, label=nothing)
end

function draw_walk!(states, actions;
		cost=nothing,
		colors=(slow=slow_color, fast=fast_color, line=:black))

	draw_walk!(
		[x for (x, t) in states],
		[t for (x, t) in states],
		actions; 
		cost,
		colors
	)
end