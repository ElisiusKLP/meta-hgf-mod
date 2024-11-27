
include("/work/HGF_MOD/HierarchicalGaussianFiltering.jl/src/HierarchicalGaussianFiltering.jl")
using .HierarchicalGaussianFiltering

### SETUP HGF INIT STRUCTURE ###

nodes_sensory = [
    # SEGREGATION
	ContinuousInput(
		name = "u_A",
		input_noise = -2,
		bias = 0
	),
	ContinuousInput(
		name = "u_V",
		input_noise = -2,
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
update_order_sensory = ["u_A", "u_V", "Seg_sA", "Seg_sV", "FF_sAV"]

families_dict = Dict{String, Tuple{Vararg{String}}}()
families_dict["Segregation"] = ("Seg_sA", "Seg_sV")
families_dict["ForcedFusion"] = ("FF_sAV",)

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

### TEST Initialization of Structure ###

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

### Give INPUTS ###

# Load input data

# Feed inputs