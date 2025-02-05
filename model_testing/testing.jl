
#using ActionModels
include("/work/HGF_MOD/HierarchicalGaussianFiltering.jl/src/HierarchicalGaussianFiltering.jl")
using .HierarchicalGaussianFiltering

using CSV
using DataFrames
using Plots

### SETUP HGF INIT STRUCTURE ###

nodes_sensory = [
    # SEGREGATION
	ContinuousInput(
		name = "u_A",
		input_noise = -1,
		bias = 0
	),
	ContinuousInput(
		name = "u_V",
		input_noise = -1,
		bias = 0
	),
    ContinuousState(
		name = "Seg_sA",
		volatility = -2,
		drift = 0,
		autoconnection_strength = 1,
		initial_mean = 0,
		initial_precision = 1
	),
	ContinuousState(
		name = "Seg_sV",
		volatility = -2,
		drift = 0,
		autoconnection_strength = 1,
		initial_mean = 0,
		initial_precision = 1
	),
    # FORCED FUSION
	ContinuousState(
		name = "FF_sAV",
		volatility = -2,
		drift = 0,
		autoconnection_strength = 1,
		initial_mean = 0,
		initial_precision = 1
	),
	ModelComparisonInput(
		name = "CausalInference"
	)
]


edges_sensory = Dict(
	("u_A", "Seg_sA") => ObservationCoupling(),
	("u_A", "FF_sAV") => ObservationCoupling(),
	("u_V", "FF_sAV") => ObservationCoupling(),
	("u_V", "Seg_sV") => ObservationCoupling(),
)

#CHANGE THIS TO THE CORRECT ORDER
# TODO Right now the model comparison is treated as outside the ordered_nodes
# because the model_comparison always happens at a fixed time after input nodes, before state updates

update_order_sensory = ["u_A", "u_V", "Seg_sA", "Seg_sV", "FF_sAV"]

#=
families_dict = Dict{String, Tuple{Vararg{String}}}()
families_dict["Segregation"] = ("Seg_sA", "Seg_sV")
families_dict["ForcedFusion"] = ("FF_sAV",)
=#

families_dict = Dict(
    "Segregation" => ["Seg_sA", "Seg_sV", "u_A", "u_V"],
    "ForcedFusion" => ["FF_sAV", "u_A", "u_V"],
)

hgf_sensory = init_hgf(
    nodes = nodes_sensory,
    edges = edges_sensory,
    update_order = update_order_sensory,
    families = families_dict
)

########################################
### TEST Initialization of Structure ###
########################################

#=
hgf_sensory.all_nodes
hgf_sensory.all_nodes.families
hgf_sensory.input_nodes

for node in values(hgf_sensory.all_nodes)
    node_type = typeof(node)
    node_fields = fieldnames(node_type)
    println("Node Name: ", node.name)
    println("Node Type: ", node_type)
    println("Fields: ", node_fields)
    println("--------------------------")
end

hgf_sensory.all_nodes["Seg_sV"].parameters.coupling_strengths

print(hgf_sensory.all_nodes)

# Check if a modelcomparison node exists
node_types = []
#check in input nodes because comparison node is an input node
for node in values(hgf_sensory.input_nodes)
	node_type = typeof(node)
	push!(node_types, node_type)
end

if Main.HierarchicalGaussianFiltering.ModelComparisonNode in node_types
	print("Succes")
end

print(get_parameters(hgf_sensory))

function print_families_overview(hgf)
    for (family, nodes) in hgf.nodes_by_family
        println("Family: $family")
        for node in nodes
            println("  - Node Name: $(node.name), Node Type: $(typeof(node))")
        end
        println()  # Blank line between families for readability
    end
end

# Call the function
print_families_overview(hgf_sensory)

hgf_sensory.all_nodes["Seg_sV"].edges

println(fieldnames(typeof(hgf_sensory.all_nodes["Seg_sV"].edges)))

hgf_sensory.state_nodes
=#

hgf_sensory.all_nodes["u_A"].parameters.coupling_strengths

hgf_sensory.all_nodes["FF_sAV"].edges.observation_children

###################
### Give INPUTS ###
###################

# Load input data

# changed timstep to range 0 to 1000
file_path = "/work/HGF_MOD/model_testing/input_data/data_sim3_2024-10-23_111804.csv"

# import data
using CSV
using DataFrames

# Load the CSV file into a DataFrame
df = CSV.read(file_path, DataFrame)


# Convert all column names to lowercase
rename!(df, Dict(col => lowercase(col) for col in names(df)))

println("First few rows of the DataFrame:")
println(first(df, 5))
print(names(df))


# Create the vector using comprehension
input_vector =[]
input_vector = [ [row.auditory_position, row.visual_position] for row in eachrow(df) ]


### Feed inputs ###

# cut down on input length
input_vector = input_vector[1:1000]

reset!(hgf_sensory)

typeof(hgf_sensory)
hgf_sensory.all_nodes

give_inputs!(hgf_sensory, input_vector)

history = get_history(hgf_sensory)

mc_history = get_history(hgf_sensory, "CausalInference")

full_history = merge(history, mc_history)

for key in enumerate(keys(full_history))
	println("this is the key $key")
end

###########
## PLOTS ##
###########

# plotting the CausalInference node parameters

using Plots

plotting_variable = full_history[("CausalInference", "probabilities")]
#plotting_variable = function_history["posterior_probability"]

ForcedFusion_probabilties = [dict["ForcedFusion"] for dict in plotting_variable]

# 1. BINDING TENDENCY
time = 1:length(plotting_variable)
posterior_plot = plot(time, ForcedFusion_probabilties,
	xlabel = "Timestep",
	ylabel = "surprise difference",
	title = "HGF Posterior probability (common cause) over time",
	)

# 2. INPUT Positions
time = 1:length(plotting_variable)
input_vector
auditory_position = [vector[1] for vector in input_vector]
visual_position = [vector[2] for vector in input_vector]

input_plot = plot(time, auditory_position,
xlabel = "Timestep",
ylabel = "Position",
label = "auditory_position",
color = :blue,
title = "Input vector visualization",
)
plot!(time, visual_position, label="visual_position", color = :red)

@assert input_plot !== nothing "First plot is not defined"

# Combination
combined_plot = plot(input_plot, posterior_plot, layout = (2, 1), size = (1200,1200))

# 3. ESTIMATED Signals
FF_sAV_est = full_history[("FF_sAV", "posterior_mean")][2:end]
Seg_sA = full_history[("Seg_sA", "posterior_mean")][2:end]
Seg_sV = full_history[("Seg_sV", "posterior_mean")][2:end]
time = 1:1000

# Plot FF_sAV_est in solid purple
output_plot = plot(
    time,
    FF_sAV_est,
    label = "FF_sAV",
    color = :purple,
    linestyle = :solid,
    xlabel = "Time",
    ylabel = "Estimates"
)

# Add Seg_sA in dotted blue
plot!(
    time,
    Seg_sA,
    label = "Seg_sA",
    color = :blue,
    linestyle = :dot
)

# Add Seg_sV in dotted red
plot!(
    time,
    Seg_sV,
    label = "Seg_sV",
    color = :red,
    linestyle = :dot
)

display(output_plot)

# 4. TEXT PLOT
# ADD in all parameter SETTINGS
sensory_io = IOBuffer()
print(sensory_io, get_parameters(hgf_sensory))
sensory_hgf_params = String(take!(sensory_io))

meta_io = IOBuffer()
print(meta_io, get_parameters(hgf_sensory))
meta_hgf_params = String(take!(meta_io))

combined_params_text = """
Sensory HGF Parameters:
$sensory_hgf_params

Meta HGF Parameters:
$meta_hgf_params
"""
# Function to split long text into smaller chunks for annotation
function wrap_text(text, max_length=80)
    lines = split(text, '\n')
    wrapped_lines = []
    for line in lines
        while length(line) > max_length
            push!(wrapped_lines, line[1:max_length])
            line = line[max_length+1:end]
        end
        push!(wrapped_lines, line)
    end
    return wrapped_lines
end

# Wrap the combined text to avoid long lines
wrapped_text_lines = wrap_text(combined_params_text, 120)

# Create the text-only plot
text_plot = plot(axis=([], false), margin=0Plots.cm)
y_position = 1.0           # Start at top of the plot
y_step = 0.05              # Spacing between each line

# Annotate each wrapped line in the plot
for line in wrapped_text_lines
    annotate!(text_plot, 0.5, y_position, text(line, :center, 6, :black))
    y_position -= y_step   # Move down for the next line
end

display(text_plot)

#paring inputs and output plot
combined_plot = plot(input_plot, output_plot, posterior_plot, text_plot, layout = (4, 1), size = (1200,1200))

# INSPECTING