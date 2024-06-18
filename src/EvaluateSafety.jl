struct SafetyReport{S, T}
    example_trace::Tuple{Array{S}, Array{T}}
    total_checked::Int64
    unsafe_traces::Int64
end

function do_binom(sr::SafetyReport, coverage_level)
    
    return confint(BinomialTest(sr.total_checked - sr.unsafe_traces, sr.total_checked, 1.0), 
        level=coverage_level, 
        method=:clopper_pearson)
end


function Base.show(io::IO, ::MIME"text/plain", sr::SafetyReport)
    coverage_level = 0.95
    lower, upper = do_binom(sr, coverage_level)
    unsafe = sr.unsafe_traces != 0
    
    print(io, """
    $(unsafe ? "⚠️ Unsafe traces obsrved" : "👍 All traces safe")
    unsafe_traces: $(sr.unsafe_traces)
    total_checked: $(sr.total_checked)
    example_trace: [...]
    
    Probability of a trace being safe is 
    within the interval [$(round(lower, digits=5)), $(round(upper, digits=5))]
    with $(coverage_level*100)% confidence.
    """)
end


function Base.show(io::IO, ::MIME"text/html", sr::SafetyReport)
    unsafe = sr.unsafe_traces != 0
    coverage_level = 0.95
    lower, upper = do_binom(sr, coverage_level)

    print(io, """
    <div class="admonition $(unsafe ? "warning" : "success")">
        <p class="admonition-title">
            $(unsafe ? "⚠️ Unsafe traces obsrved" : "👍 All traces safe")
        </p>
        <p>
            <code>unsafe_traces</code>: $(sr.unsafe_traces)<br/>
            <code>total_checked</code>: $(sr.total_checked)<br/>
            <code>example_trace</code>: [...]
        <p>
            Probability of a trace being safe is
            within the interval <b>[$(round(lower, digits=5)), $(round(upper, digits=5))]</b>
            with $(coverage_level*100)% confidence.
        </p>
    </div>
    """)
end


function check_safe(trace, is_safe::Function)
    for s in trace
        if !is_safe(s)
            return false
        end
    end
    return true
end

"""
    evaluate_safety(generate_trace, is_safe, traces_to_check)

Returns a `SafetyReport` containing information on the number of generated traces that were unsafe.
Show the `SafetyReport` as mimetype plaintext or html to view the probability of a trace being safe.

**Args:**
 - `generate_trace`: A function that takes no arguments, and returns a trace on the form `Tuple{Vector{S}, Vector{A}}`, where `S` is the type of the states, and `A` is the type of actions. Use the policy you wish to evaluate, to generate traces.
 - `is_safe`: A function that takes a state of type `S` (same as above) and returns a bool.
 - `traces_to_check`: A number indicating how many traces should be evaluated. The more traces, the more precise the probability of safety violation becomes.
"""
function evaluate_safety(generate_trace, is_safe, traces_to_check)
    example_trace = nothing
    unsafe_traces = 0
    @progress for i in 1:traces_to_check
        trace = generate_trace()
        states, actions = trace
        for state in states
            if !is_safe(state)
                unsafe_traces += 1
                example_trace = trace
                break
            end
        end
        if i == traces_to_check
            example_trace = something(example_trace, trace)
        end
    end
    
    return SafetyReport(example_trace, traces_to_check, unsafe_traces)
end
