
# Log

## 5 feb - correcting the adjustment of coupling strenghts

Inside the continous_state_node.jl in calculate_posterior_precision update function i commented out the original update terms from observation children.
Observation children is a child type defined inside the init_node_edge.jl script which is defined from the ObservationCoupling().
I just created a temporary solution where WeightedObservationCoupling also created observation_children and then all these adhere to the update function of the WeightedCouplingType().

I would still need to adjust the fulle node_update folder with WeightedObservationCoupling().

Decision 1:
at the calculate_posterior_precision_increment for the WeightedObservationCoupling we haven't introduced any scaling yet. 
We can introduce a scaling parameter of the coupling strength to completely shut off any influence the child would have on the parent, also regarding precision.
I guess without any weighting the parents mean is weighted but the precision "leaks" through fully.

### To DO;
- [ ] Adjust the surprise function that it gathers surprise non-contingent on the adjusted coupling strength but on the precision without adjusted coupling strength.

## 14 feb

I thyink theres something which i get quite confused about. It's because my coupling strengths mainly influences the computation of posteriors at time n-1 which then of course influences prediction update implicitly at time n. To calculate the counterfactual would i then need to rerun the update step from before from computing posteriors? But if i recompute posterior then it doesn't even influence the surprise caclulation? But then i of course still have the "factual" computation which is based on the adjusted coupling strength. So i do the actual computations and then when im at the get_surprise for each family step i recalculate the posterior from before under each counterfactual, then the precision given the input and adjust accordingly. Is this the right approach or am i off?

### To DO;
- [ ] Create an get_node_posterior function which can take a weighted
- create a get_node_precision which can take a weighted_obs_override
- enable the model comparison node to compute surprise for the precisions that were made using the counterfactual from each family.
