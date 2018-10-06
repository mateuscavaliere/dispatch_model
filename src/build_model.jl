#-----------------------------------------------------
#----           Functions to build model          ----
#-----------------------------------------------------

#- Author: Jairo Terra, Guilherme Machado, Mateus Cavaliere ( PUC - 2018 )
#- Description: This module cointains the functions to build the optmization problem

#--- create_model: This function creates the JuMP model and its variables ---
function create_model( case::Case, generators::Gencos)
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local myModel::JuMP.Model                  # Local variable to create optmization model

    #-----------------------
    #---  Creating model ---
    #-----------------------

    myModel = Model( solver = CbcSolver( ) );

    @variable(myModel, f[1:case.nCir, 1:(case.nContScen+1), 1:case.nStages] );
    @variable(myModel, g[1:case.nGen, 1:(case.nContScen+1), 0:case.nStages] >= 0);
    @variable(myModel, commit[1:case.nGen, -3:case.nStages]>= 0, Bin);
    @variable(myModel, delta[1:case.nBus, 1:(case.nContScen+1), 1:case.nStages] >= 0);
    @variable(myModel, pot_disp[1:case.nGen, 0:case.nStages]>=0)
    @variable(myModel, startUpCost[1:case.nGen,1:case.nStages]>=0)
    @variable(myModel, shutDownCost[1:case.nGen,1:case.nStages]>=0)
    
    for u in 1:case.nGen
        for t in 1:size(generators.InitCommit)[2]
            @constraint(myModel, commit[u,1-t] == generators.InitCommit[u,t])
        end
        for c in 1:(case.nContScen+1)
            @constraint(myModel,  g[u,c,0] == generators.InitGen[u])
        end
    end

    if case.Flag_Ang == 1
        @variable(myModel, theta[1:case.nBus, 1:(case.nContScen+1), 1:case.nStages] );        
    end

    if case.Flag_Res == 1
        @variable(myModel, resup[1:case.nGen, 1:case.nStages]  >= 0);
        @variable(myModel, resdown[1:case.nGen, 1:case.nStages]  >= 0);
    end

    return( myModel)
end

#--- add_grid_constraint!: This function creates the maximum and minimum flow constraint ---
function add_grid_constraint!( model::JuMP.Model , case::Case , circuits::Circuits )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local l::Int                                        # Local variable to loop over lines
    local f::Array{JuMP.Variable,3}                     # Local variable to represent flow decision variable
 
    #- Assigning values
    f = model[:f]
    al = case.al

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraint( model , max_circ_cap[l=1:case.nCir,c=1:(case.nContScen+1), t=1:case.nStages] , f[l,c,t]  <= circuits.Cap[l] * al[l,c]  )
    @constraint( model , min_circ_cap[l=1:case.nCir,c=1:(case.nContScen+1), t=1:case.nStages] , -circuits.Cap[l] * al[l,c] <= f[l,c,t]  )

end

#--- add_angle_constraint!: This function creates the angle diff constraint ---
function add_angle_constraint!( model::JuMP.Model , case::Case , circuits::Circuits )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local l::Int                                    # Local variable to loop over lines

    local f::Array{JuMP.Variable,3}                 # Local variable to represent flow decision variable of model
    local theta::Array{JuMP.Variable,3}             # Local variable to represent angle decision variable of model
    local al::Array{Int,2}                          # Local variable to represent contingency

    local angle_lag::Array{JuMP.ConstraintRef,3}    # Local variable to represent angle lag constraint reference
    
    #- Assigning values

    f     = model[:f]
    theta = model[:theta]
    al    = case.al

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------
    @constraint( model , angle_lag[l=1:case.nCir, c=1:(case.nContScen+1), t=1:case.nStages], f[l,c,t] == ( al[l,c] / circuits.Reat[l] ) * ( theta[circuits.BusFrom[l],c,t] - theta[circuits.BusTo[l],c,t] ) )
end

#--- add_gen_constraint!: This function creates the maximum and minimum generation constraint ---
function add_gen_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                    # Local variable to loop over generators
    
    local resup::Array{JuMP.Variable,2}               # Local variable to represent reserve up decision variable
    local resdown::Array{JuMP.Variable,2}             # Local variable to represent reserve down decision variable
     
    local max_gen::Array{JuMP.ConstraintRef,2}      # Local variable to represent maximum generation constraint reference
    local min_gen::Array{JuMP.ConstraintRef,2}      # Local variable to represent minimum generation constraint reference

    #- Assigning values

    g = model[:g]

    if case.Flag_Res == 1
        resup   = model[:resup]
        resdown = model[:resdown]
    end
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------
    
    if case.Flag_Res == 1
        @constraint(model, max_gen[u=1:case.nGen, t=1:case.nStages],   g[u,1,t] + resup[u,t] <= generators.PotMax[u] )

        @constraint(model, min_gen[u=1:case.nGen, t=1:case.nStages],  0 <=  g[u,1,t] - resdown[u,t] )
    else
        @constraint(model, max_gen[u=1:case.nGen, t=1:case.nStages],   g[u,1,t] <= generators.PotMax[u] )
    end
end

#--- add_reserve_constraint!: This function creates the maximum and minimum reserve constraint ---
function add_reserve_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                    # Local variable to loop over generators
    
    local resup::Array{JuMP.Variable,2}               # Local variable to represent reserve up decision variable
    local resdown::Array{JuMP.Variable,2}             # Local variable to represent reserve down decision variable
    
    local max_resup::Array{JuMP.ConstraintRef,2}      # Local variable to represent maximum reserve up constraint reference
    local max_resdown::Array{JuMP.ConstraintRef,2}    # Local variable to represent maximum reserve down constraint reference

    #- Assigning values

    resup   = model[:resup]
    resdown = model[:resdown]
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraint(model, max_resup[u=1:case.nGen, t=1:case.nStages]   ,  resup[u,t] <= generators.ReserveUp[u]    )
    @constraint(model, max_resdown[u=1:case.nGen, t=1:case.nStages] , resdown[u,t] <= generators.ReserveDown[u] )
end

#--- add_load_balance_constraint!: This function creates the load balance constraint ---
function add_load_balance_constraint!( model::JuMP.Model , case::Case , generators::Gencos , circuits::Circuits , demands::Demands )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                                    # Local variable to loop over generators
    local l::Int                                                    # Local variable to loop over lines
    local b::Int                                                    # Local variable to loop over buses
    local d::Int                                                    # Local variable to loop over demands

    local f::Array{JuMP.Variable,3}                                 # Local variable to represent flow decision variable
    local delta::Array{JuMP.Variable,3}                                 # Local variable to represent deficit variable

    local load_balance::Array{JuMP.ConstraintRef,3}                 # Local variable to represent load balance constraint reference

    #- Assigning values

    g     = model[:g]
    f     = model[:f]
    delta = model[:delta]

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraint(model, load_balance[b=1:case.nBus, c=1:(case.nContScen+1), t=1:case.nStages], 
    + sum(g[u,c,t] for u in 1:case.nGen if generators.Bus[u] == b) 
    + sum(f[l,c,t] for l in 1:case.nCir if circuits.BusTo[l] == b)
    - sum(f[l,c,t] for l in 1:case.nCir if circuits.BusFrom[l] == b)
    ==  sum(demands.Dem[d] * demands.Profile[d,t] for d in 1:case.nDem if demands.Bus[d] == b) 
    )
    
end

#--- add_contingency_constraint!: this function creates the contingency constraint
function add_contingency_constraint!( model::JuMP.Model , case::Case , generators::Gencos )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                    # Local variable to loop over generators
    
    local resup::Array{JuMP.Variable,2}             # Local variable to represent reserve up decision variable
    local resdown::Array{JuMP.Variable,2}           # Local variable to represent reserve down decision variable
    local ag::Array{Int,2}                          # Local variable to represent contingency variable
    
    #- Assigning values

    g = model[:g]
    ag = case.ag

    if case.Flag_Res == 1
        resup   = model[:resup]
        resdown = model[:resdown]
    end
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------
    @constraint(model, cont_max_gen[u=1:case.nGen,c=2:(case.nContScen+1), t=1:case.nStages],   g[u,c,t] <= (g[u,1,t] + resup[u,t])*ag[u,c])
    
    @constraint(model, cont_min_gen[u=1:case.nGen,c=2:(case.nContScen+1), t=1:case.nStages], (g[u,1,t] - resdown[u,t])*ag[u,c] <= g[u,c,t]) 
end

function add_unit_commitment( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                                    # Local variable to loop over generators


    local commit_maxgen::Array{JuMP.ConstraintRef,3}                 # Local variable to represent maximmum generation bound
    local commit_mingen::Array{JuMP.ConstraintRef,3}                 # Local variable to represent minimum generation bound
    
    local gmin::Array{Float64,1}                                     # Local variable to represent minimum generation

    #- Assigning values
    g = model[:g]
    commit = model[:commit]
    gmin = generators.PotMin 
    pot_disp = model[:pot_disp]

    if case.Flag_Res == 1
        resup   = model[:resup]
        resdown = model[:resdown]
    end

    # constraint for plant`s minumum generation with commitment
    # bound the generation by the minimum power output and the maximum available power output
    if case.Flag_Res == 1
        @constraint(model, commit_maxgen[u=1:case.nGen, c=1:(case.nContScen+1), t=1:case.nStages], g[u,c,t] <= resup[u,t] + pot_disp[u,t])
        @constraint(model, commit_mingen[u=1:case.nGen, c=1:(case.nContScen+1), t=1:case.nStages], g[u,c,t] + resdown[u,t] >= (gmin[u] ) * commit[u,t])
    else
        @constraint(model, commit_maxgen[u=1:case.nGen, c=1:(case.nContScen+1), t=1:case.nStages], g[u,c,t] <= pot_disp[u,t])
    @constraint(model, commit_mingen[u=1:case.nGen, c=1:(case.nContScen+1), t=1:case.nStages], g[u,c,t] >= (gmin[u] ) * commit[u,t])
    end
    

    # disponible power constraints
    # resup[u,t]
    @constraint(model, pot_disp_cstr[u=1:case.nGen, t=0:case.nStages], pot_disp[u,t] <= (generators.PotMax[u]) * commit[u,t])
end


function add_ramping_constraint( model::JuMP.Model , case::Case , generators::Gencos )
    #---------------------------
    #---  Defining variables ---
    #---------------------------
    local u::Int                                    # Local variable to loop over generators

    local ramp_up::Array{Float64,1}                 # Local variable to represent ramp up generation variable
    local ramp_down::Array{Float64,1}               # Local variable to represent ramp down generation variable
    local start_up::Array{Float64,1}                # Local variable to represent start up ramp variable
    local shutdown::Array{Float64,1}                # Local variable to represent shutdown ramp variable
    
    #- Assigning values
    g = model[:g]
    commit = model[:commit]
    gmin = generators.PotMin 
    pot_disp = model[:pot_disp]
    
    ramp_up = generators.RampUp  
    ramp_down = generators.RampDown
    start_up = generators.StartUpRamp
    shut_down =  generators.ShutdownRamp

    # Ramp-up and Start-up
    @constraint(model, ramp_up_cstr[u=1:case.nGen, t=1:case.nStages], pot_disp[u,t] <= g[u,1,t-1]
                                                        + ramp_up[u] * commit[u,t-1]
                                                        + start_up[u] * (commit[u,t] - commit[u,t-1])
                                                        + (generators.PotMax[u] * (1 - commit[u,t]) ) )

    # Shutdown ramp rate
    @constraint( model, shutdown_rate_cstr[u=1:case.nGen,t=1:(case.nStages-1)] , pot_disp[u,t] <= (generators.PotMax[u] * commit[u,t+1] ) + ( shut_down[u] * (commit[u,t] - commit[u,t+1] ) ) )

    # Ramp down limits
    @constraint(model, ramp_down_limits_cstr[u=1:case.nGen, t=1:case.nStages], ( g[u,1,t-1] - g[u,1,t] ) <= ( ramp_down[u] * commit[u,t] ) + ( shut_down[u] * ( commit[u,t-1] - commit[u,t] ) ) + ( generators.PotMax[u])  * ( 1 - commit[u,t-1] ) )
end

function add_updowntime_constraint( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------
    
    local u::Int                                                    # Local variable to loop over generators
    
    local nMon::Array{Int64,1}
    local nMoff::Array{Int64,1}

    commit = model[:commit]
    

    
    nMon = min.(case.nStages*ones(Float64, case.nGen), (generators.UpTime-generators.InitOnTime).*generators.InitCommit[:,1])
    nMoff = min.(case.nStages*ones(Float64, case.nGen), (generators.DownTime-generators.InitOffTime).*(1-generators.InitCommit[:,1]))
    # nMon = min.(case.nStages*ones(Float64, case.nGen), max.(generators.UpTime-generators.InitOnTime, 0).*generators.InitCommit[:,1])
    # nMoff = min.(case.nStages*ones(Float64, case.nGen), max.(generators.DownTime-generators.InitOffTime,0).*(1-generators.InitCommit[:,1]))
    
    # maximum Uptime on initial periods
    @constraint(model, must_On[u=1:case.nGen], sum(1-commit[u,t] for t in 1:nMon[u] if nMoff[u] >= 1) == 0 )
    @constraint(model, must_Off[u=1:case.nGen], sum(commit[u,t] for t in 1:nMoff[u] if nMoff[u] >=1) == 0 )

    nMon  = max.(nMon , zeros(Float64, case.nGen))
    nMoff = max.(nMoff , zeros(Float64, case.nGen))

    # define references for loop
    @constraintref minuptime_cstr1[1:case.nGen, 1:case.nStages]  # (nMon+1):(case.nStages-generators.UpTime[p]+1)
    @constraintref minuptime_cstr2[1:case.nGen, 1:case.nStages]  # (nMon+1):(case.nStages-generators.UpTime[p]+1)
    @constraintref mindowntime_cstr1[1:case.nGen, 1:case.nStages]
    @constraintref mindowntime_cstr2[1:case.nGen, 1:case.nStages]

    for u in 1:case.nGen
        # minimum uptime in middle periods
        for (i,k) in enumerate((nMon[u]+1):(case.nStages-generators.UpTime[u]+1))
            minuptime_cstr1[u,i] =  @constraint( model, sum( commit[u,n] for n=k:( k+generators.UpTime[u]-1 ) ) >=  generators.UpTime[u] * ( commit[u,k]-commit[u,k-1] ) )
        end
        
        # minimum uptime in final periods
        for (i,k) in enumerate((case.nStages-generators.UpTime[u]+2):(case.nStages))
            minuptime_cstr2[u,i] = @constraint( model, sum(commit[u,n]-( commit[u,k]-commit[u,k-1] ) for n=k:case.nStages ) >= 0 )
        end
    end
    
    for u in 1:case.nGen
        # minimum downtime in middle periods
        
        for (i,k) in enumerate((nMoff[u]+1):(case.nStages-generators.DownTime[u]+1))
            
            mindowntime_cstr1[u,i] = @constraint( model, sum( 1-commit[u,n] for n in k:(k+generators.DownTime[u]-1 ) ) >=  generators.DownTime[u] * ( commit[u,k-1] - commit[u,k] ) )
            
        end
        
        # minimum downtime in final periods
        for (i,k) in enumerate((case.nStages-generators.DownTime[u]+2):(case.nStages))
            mindowntime_cstr2[u,i] = @constraint( model, sum( 1-commit[u,n]-( commit[u,k-1]-commit[u,k] ) for n=k:case.nStages ) >= 0 )
        end
    end
end

function add_startupcost_shutdowncost_constraint( model::JuMP.Model , case::Case , generators::Gencos)
    #---------------------------
    #---  Defining variables ---
    #---------------------------
    local u::Int                                                    # Local variable to loop over generators

    local upCost::Array{Float64}
    local startUpCost:: Array{JuMP.Variable,2}
    local shutDownCost:: Array{JuMP.Variable,2}

    commit = model[:commit]
    startUpCost = model[:startUpCost]
    shutDownCost = model[:shutDownCost]
    #--- Startup cost
    upCost = hcat(generators.StartUpCost_1,  generators.StartUpCost_2,  generators.StartUpCost_3)
    
    @constraintref startupcost1[1:case.nGen, 1:case.nStages, 1:3]
    
    for u=1:case.nGen,t=1:case.nStages, pat=1:3

        startupcost1[u, t, pat] = @constraint(model, startUpCost[u,t] >= upCost[u,pat]*(commit[u,t]-sum(commit[u,t-n] for n=1:pat)))
      
    end
        
    @constraint(model, shutdowncost1[u=1:case.nGen, t=1:case.nStages], shutDownCost[u,t] >= generators.ShutdownCost[u] *(commit[u,t-1]- commit[u,t]))

end

#--- add_obj_fun!: This function creates and append the objective function to the model ---
function add_obj_fun!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local u::Int                                                    # Local variable to loop over generators
    
    local resup::Array{JuMP.Variable,2}                               # Local variable to represent reserve up decision variable
    local resdown::Array{JuMP.Variable,2}                             # Local variable to represent reserve down decision variable

     local syst_cost::JuMP.GenericAffExpr{Float64,JuMP.Variable}     # Local variable to represent system total cost
    
    #- Assigning values

    g = model[:g]
    startUpCost = model[:startUpCost]
    shutDownCost = model[:shutDownCost]

    if case.Flag_Res == 1
        resup   = model[:resup]
        resdown = model[:resdown]
    end

    #-----------------------------------
    #---  Adding objective function  ---
    #-----------------------------------
    if case.Flag_Res == 1
        @objective(  model , Min       , 
        + sum(g[u,1,t] * generators.CVU[u] for u in 1:case.nGen, t  in 1:case.nStages)
        + sum(resup[u,t] * generators.ReserveUpCost[u] for u in 1:case.nGen, t  in 1:case.nStages)
        + sum(resdown[u,t] * generators.ReserveDownCost[u] for u in 1:case.nGen, t  in 1:case.nStages)
        + sum(startUpCost[u,t]+shutDownCost[u,t] for u in 1:case.nGen, t  in 1:case.nStages))
    else
        @objective(  model , Min       , 
        + sum(g[u,1,t] * generators.CVU[u] for u in 1:case.nGen, t  in 1:case.nStages)
        + sum(startUpCost[u,t]+shutDownCost[u,t] for u in 1:case.nGen, t  in 1:case.nStages)
        )
    end

    nothing
end

#--- solve_dispatch: This function calls the solver and write output into .log file ---
function solve_dispatch( path::String , model::JuMP.Model , case::Case , circuits::Circuits , generators::Gencos , buses::Buses )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local b::Int                            # Local variable to loop over buses
    local u::Int                            # Local variable to loop over generators
    local l::Int                            # Local variable to loop over lines

    local status::Symbol                    # Local variable to represent optmization status

    local prices::Array{Float64}            # Local variable to buffer dual variable (prices) after optmization
    local cir_flow::Array{Float64}          # Local variable to buffer optimal circuit flow
    local res_up_gen::Array{Float64}        # Local variable to buffer optimal up reserve
    local res_down_gen::Array{Float64}      # Local variable to buffer optimal down reserve
    local bus_ang::Array{Float64}           # Local variable to buffer optimal angle diff


    #--- Creating optmization problem
    JuMP.build( model );

    #--- Solving optmization problem
    status = JuMP.solve( model );

    #--- Reporting results
    if status  == :Optimal

        prices = getdual(getindex(model, :load_balance))
        generation = getvalue( model, :g )
        cir_flow   = getvalue( model, :f )
        commit     = getvalue(model, :commit)
        potdisp     = getvalue(model, :pot_disp)

        if case.Flag_Res == 1
            res_up_gen   = getvalue( model, :resup )
            res_down_gen = getvalue( model, :resdown )
        end
        
        if case.Flag_Ang == 1
            bus_ang = getvalue( model, :theta )
        end

        #--- Writing to log the optimal solution

        w_Log("\n     Optimal solution found!\n" , path )

        for b in 1:case.nBus
            w_Log("     Marginal cost for the bus $(buses.Name[b]): $(round.(sum(prices[b,:,:]),2)) R\$/MWh" , path )
        end
        # write bus output
        write_outputs("results_bus.csv", path, prices[:,1,:], buses.Name)
        
        w_Log( " " , path )
        
        for u in 1:case.nGen
            w_Log("     Optimal generation of $(generators.Name[u]): $(round.(generation[u,1,:],2)) MWh" , path )
        end
        # write generation output
        write_outputs("results_gen.csv", path, generation[:,1,:], generators.Name)
        
        w_Log( " " , path )
        
        for l in 1:case.nCir
            w_Log("     Optimal flow in line $(circuits.Name[l]): $(round.(cir_flow[l,1,:],2)) MW" , path )
        end
        # write generation output
        write_outputs("results_circ.csv", path, cir_flow[:,1,:], circuits.Name)
        
        if case.Flag_Res == 1
            
            w_Log( " " , path )
            
            for u in 1:case.nGen
                w_Log("     Optimal Reserve Up of $(generators.Name[u]): $(round.(res_up_gen[u,:],2)) MWh" , path )
            end
            # write reserve up output
            write_outputs("results_resup.csv", path, res_up_gen, generators.Name)
            
            w_Log( " " , path )
            
            for u in 1:case.nGen
                w_Log("     Optimal Reserve Down of $(generators.Name[u]): $(round.(res_down_gen[u,:],2)) MWh" , path )
            end
            # write reserve down output
            write_outputs("results_resdown.csv", path, res_down_gen, generators.Name)
            
        end
        
        if case.Flag_Ang == 1
            
            w_Log( " " , path )
            
            for b in 1:case.nBus
                w_Log("     Optimal bus angle $(buses.Name[b]): $(round.(bus_ang[b,1,:],2)) grad" , path )
            end
            # write reserve down output
            write_outputs("results_busang.csv", path, bus_ang[:,1,:], buses.Name)
        end
        
        # commit output
        w_Log( " " , path )
        for u in 1:case.nGen
            w_Log("     Commitment of $(generators.Name[u]): $(round.(commit[u,:],2))" , path )
        end
        # write reserve down output
        write_outputs("results_commit.csv", path, commit, generators.Name)
        
        # write potdisp
        write_outputs("results_potdisp.csv", path, potdisp, generators.Name)
    

    defcit = getvalue( model, :delta )
    w_Log("\n    Total cost = $(round(getobjectivevalue(model)/1000,2)) k\$" ,  path)

    elseif status == :Infeasible
        
        w_Log("\n     No solution found!\n\n     This problem is Infeasible!" , path )
        # w_Log("\n     $(case.ag)" , path )
        # w_Log("\n     $(case.al)" , path )
    end

end