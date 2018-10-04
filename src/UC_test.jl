# -------------------
# --- unit commitment
# -------------------
local g::Array{JuMP.Variable,2}                 # Local variable to represent generation decision variable
local commit::Array{JuMP.ConstraintRef,1}      # Local variable to represent commitment decision
local nStages::Int      # Local variable to represent number of stages
local gmin::Array{Float64,1}      # Local variable to represent minimum generation
@variable(m, commit[1:nGen,1:nStages]>=0)
@variable(m, pot_disp[1:nGen,1:nStages]>=0)

# constraint for plant`s minumum generation with commitment
# bound the generation by the minimum power output and the maximum available power output
@constraints(m, commit_maxgen[p=1:nGen, t=1:nStages], g[p,s] <= pot_disp[p,t] * commit[p,t] )
@constraints(m, commit_mingen[p=1:nGen, t=1:nStages], g[p,s] >= gmin[p] * commit[p,t])

# disponible power constraints
@constraints(m, pot_disp_cstr[p=1:nGen, t=1:nStages], pot_disp[p,t] <= generators.Pot[p] * commit[p,t])

# --------------------
# --- Production cost
# --------------------
#-- variable
local nCostSeg::Int # number of cost production segments 
local cost_seg::Array{Float64,2} # local variable for plant`s cost segment
local min_cost::Array{Float64,1} # local variable for plants minimal cost
local T::Array{Float64,1} # local variable for generation segment. T[,1] = gmin T[,n] = gmax 
local g::Array{JuMP.Variable,2}                 # Local variable to represent generation decision variable
local min_gen::Array{JuMP.ConstraintRef,1}      # Local variable to represent minimum generation constraint reference
local commit::Array{JuMP.ConstraintRef,1}      # Local variable to represent commitment decision

@variable(m, prod_cost[1:nGen]>=0)
@variable(m, power_seg[1:nGen, 1:nCostSeg]>=0)

# constraint that bounds plant generation to production segmentss
@constraints(m, power_seg_cstr[p=1:nGen, c=1:nScen], g[p,c] == sum(power_seg[p,:]) + min_gen[p] * commit[p])

# constraint that bounds production cost to plant's generation
@constraints(m, prod_cost_seg_cstr[p=1:nGen], prod_cost[p] == sum(cost_seg[p,s] * power_seg[p,s] for s in 1:nCostSeg) + min_cost[p] * commit[p])

# constraint that limits power segments
@constraints(m, power_seg_limit[p=1:nGen, s=1:nCostSeg], power_seg[p,s] <= T[p,s+1] - T[p,s])

#todo: considerar tempo
#todo: considerar cenario de contingencia
# ----------------------
#--- Ramping constraits
# ----------------------
local g::Array{JuMP.Variable,2}                 # Local variable to represent generation decision variable
local ramp_up::Array{Float64,1}                 # Local variable to represent ramp up generation variable
local ramp_down::Array{Float64,1}                 # Local variable to represent ramp down generation variable
local start_up::Array{Float64,1}                 # Local variable to represent start up ramp variable
local shutdown::Array{Float64,1}                 # Local variable to represent shutdown ramp variable
# generation is constrained by ramp-up and startup ramp rates

# ramp up & start-up
@constraints(m, ramp_up_cstr[p=1:nGen, t=1:nStages], pot_disp[p,t] <= g[p,t-1] 
                                                    + ramp_up[p] * commit[p,t-1]
                                                    + start_up[p] * (commit[p,t] - commit[p,t-1])
                                                    + generators.Pot[p] * (1 - commit[p,t]))
# shutdown ramp rate
@constraints(m, shutdown_cstr[p=1:nGen, t=1:(nStages-1)], pot_disp[p,t] <= generators.Pot[p] * commit[p,t+1] 
+ shutdown[p] * (commit[p,t] - commit[p,t+1]))

# ramp down 
@constraints(m, ramp_down_cstr[p=1:nGen, t=1:nStages], pot_disp[p,t-1] - pot_disp[p,t] <= ramp_down[p] * commit[p,t]
                                                    + shutdown[p] * (commit[p,t-1] + commit[p,t])
                                                    + generators.Pot[p] * (1 - commit[p,t-1]))

# -----------------------------------------
# --- Minimum Up time and Minimum down time
# -----------------------------------------

# ---------------
# --- Startup cost
# ---------------

# ----------------
#--- Shutdown cost
# ----------------