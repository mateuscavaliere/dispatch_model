#-----------------------------------------------------
#----           Functions to build model          ----
#-----------------------------------------------------

#- Author: Jairo Terra, Guilherme Machado, Mateus Cavaliere ( PUC - 2018 )
#- Description: This module cointains the functions to build the optmization problem

#--- create_model: This function creates the JuMP model and its variables ---
function create_model( case::Case, generators::Gencos )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local myModel::JuMP.Model                  # Local variable to create optmization model

    local f::Array{JuMP.Variable,3}            # Represent lines flow
    local g::JuMP.JuMPArray{JuMP.Variable,3}            # Represent generators generations
    local v::JuMP.JuMPArray{JuMP.Variable,2}            # Represent generators commitment
    local r::Array{JuMP.Variable,3}            # Represent system deficit 
    local p::JuMP.JuMPArray{JuMP.Variable,2}            # Represent generators maximum available power 
    local startcost::Array{JuMP.Variable,2}    # Represent generators startup cost
    local downcost::Array{JuMP.Variable,2}     # Represent generators shutdown cost
    local theta::Array{JuMP.Variable,3}        # Represent buses angles
    local resup::Array{JuMP.Variable,2}        # Represent generators reserve up 
    local resdown::Array{JuMP.Variable,2}      # Represent generators reserve down
    
    local u::Int                               # Local variable to loop over generators
    local t::Int                               # Local variable to loop over stages
    local c::Int                               # Local variable to loop over scenarios

    #-----------------------
    #---  Creating model ---
    #-----------------------

    myModel = Model( solver = CbcSolver( ) );

    #--- Adding variables

    @variable( myModel, f[ 1:case.nCir , 1:(case.nContScen+1) , 1:case.nStages ]                           );
    @variable( myModel, g[ 1:case.nGen , 1:(case.nContScen+1) , 0:case.nStages ]                 >= 0      );
    @variable( myModel, v[ 1:case.nGen , (-1 * size( generators.InitCommit )[2] ):case.nStages ] >= 0, Bin );
    @variable( myModel, r[ 1:case.nBus , 1:(case.nContScen+1) , 1:case.nStages ]                 >= 0      );
    @variable( myModel, p[ 1:case.nGen , 0:case.nStages ]                                        >=0       );
    @variable( myModel, startcost[ 1:case.nGen , 1:case.nStages ]                                >=0       );
    @variable( myModel, downcost[  1:case.nGen , 1:case.nStages ]                                >=0       );

    #--- Variables that depends on users input
    if case.Flag_Ang == 1
        @variable( myModel, theta[ 1:case.nBus , 1:(case.nContScen+1) , 1:case.nStages ] );        
    end

    if case.Flag_Res == 1
        @variable( myModel, resup[   1:case.nGen , 1:case.nStages ] >= 0 );
        @variable( myModel, resdown[ 1:case.nGen , 1:case.nStages ] >= 0 );
    end

    #--- Setting initials conditions
    
    for u in 1:case.nGen
        
        #- Previous commit state
        for t in 1:size( generators.InitCommit )[2]
            @constraint( myModel, v[ u , 1-t ] == generators.InitCommit[ u , t ] )
        end

        #- Generation in t = 0
        for c in 1:( case.nContScen+1 )
            @constraint( myModel,  g[ u , c , 0 ] == generators.InitGen[ u ] )
        end

    end

    return( myModel )
end

#-----------------------------------------------
#---            System constraint            ---
#-----------------------------------------------

#--- add_load_balance_constraint!: This function creates the load balance constraint ---
function add_load_balance_constraint!( model::JuMP.Model , case::Case , generators::Gencos , circuits::Circuits , demands::Demands )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local load_balance_cstr::Array{JuMP.ConstraintRef,3}            # Local variable to represent load balance constraint reference

    local f::Array{JuMP.Variable,3}                                 # Represent circuits flow
    local g::JuMP.JuMPArray{JuMP.Variable,3}                                 # Represent generators generations

    local gen_bus::Array{Int,1}                                     # Local variable with generator's buses
    local cir_BusTo::Array{Int,1}                                   # Local variable with circuits bus to
    local cir_BusFrom::Array{Int,1}                                 # Local variable with circuits bus from
    local dem_load::Array{Float64,1}                                # Local variable with demand load
    local dem_profile::Array{Float64,2}                             # Local variable with demand profile
    local dem_bus::Array{Int,1}                                     # Local variable with demand bus

    local u::Int                                                    # Local variable to loop over generators
    local l::Int                                                    # Local variable to loop over lines
    local b::Int                                                    # Local variable to loop over buses
    local d::Int                                                    # Local variable to loop over demands
    
    #-------------------------
    #---  Assigning values ---
    #-------------------------

    g     = model[:g]
    f     = model[:f]
    
    gen_bus = generators.Bus

    cir_BusTo   = circuits.BusTo
    cir_BusFrom = circuits.BusFrom

    dem_load    = demands.Dem
    dem_profile = demands.Profile
    dem_bus     = demands.Bus

    nStgs = case.nStages
    nScen = case.nContScen
    nGen = case.nGen
    nCir = case.nCir
    nDem = case.nDem
    nBus = case.nBus

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref load_balance_cstr[ 1:nBus , 1:( nScen + 1 ) , 1:nStgs ]

    for b = 1:nBus , c = 1:( nScen + 1 ) , t = 1:nStgs
        load_balance_cstr[ b , c , t ] = @constraint( model,  + sum( g[ u , c , t ] for u in 1:nGen if gen_bus[u]                       == b ) 
                                                              + sum( f[ l , c , t ] for l in 1:nCir if cir_BusTo[l]                     == b )
                                                              - sum( f[ l , c , t ] for l in 1:nCir if cir_BusFrom[l]                   == b )
                                                            ==  sum( dem_load[ d ] * dem_profile[ d , t ] for d in 1:nDem if dem_bus[d] == b ) 
        )
    end

    return nothing
end

#-------------------------------------------------
#---            Circuits constraint            ---
#-------------------------------------------------

#--- add_grid_constraint!: This function creates the maximum and minimum flow constraint ---
function add_grid_constraint!( model::JuMP.Model , case::Case , circuits::Circuits )

    #---------------------------
    #---  Defining variables ---
    #---------------------------
    
    local circ_maxcap_cstr::Array{JuMP.ConstraintRef,3}      # Constraint to represent the circuits maximum capacity
    local circ_mincap_cstr::Array{JuMP.ConstraintRef,3}      # Constraint to represent the circuits minumum capacity
    
    local f::Array{JuMP.Variable,3}                          # Variable to represent circuits flow
    
    local l::Int                                        # Local variable to loop over circuits
    local c::Int                                        # Local variable to loop over scenarios
    local t::Int                                        # Local variable to loop over stages

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    f  = model[:f]

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref circ_maxcap_cstr[ 1:case.nCir , 1:(case.nContScen+1) , 1:case.nStages ]
    @constraintref circ_mincap_cstr[ 1:case.nCir , 1:(case.nContScen+1) , 1:case.nStages ]

    for l = 1:case.nCir , c = 1:(case.nContScen+1) , t = 1:case.nStages
        circ_maxcap_cstr[ l , c , t ] = @constraint( model , f[ l , c , t ]                        <= circuits.Cap[ l ] * case.al[ l , c ]  )
        circ_mincap_cstr[ l , c , t ] = @constraint( model , -circuits.Cap[ l ] * case.al[ l , c ] <= f[ l , c , t ]                        )
    end

    return nothing
end

#--- add_angle_constraint!: This function creates the angle diff constraint ---
function add_angle_constraint!( model::JuMP.Model , case::Case , circuits::Circuits )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local circ_anglag_cstr::Array{JuMP.ConstraintRef,3}      # Constraint to represent the buses angles 

    local f::Array{JuMP.Variable,3}                          # Variable to represent lines flow
    local theta::Array{JuMP.Variable,3}                      # Variable to represent buses angle 
    
    local al::Array{Int,2}                                   # Local variable to represent contingency scenarios
    
    local l::Int                                             # Local variable to loop over circuits
    local c::Int                                             # Local variable to loop over scenarios
    local t::Int                                             # Local variable to loop over stages
    
    #-------------------------
    #---  Assigning values ---
    #-------------------------

    f     = model[:f]
    theta = model[:theta]
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref circ_anglag_cstr[ 1:case.nCir, 1:( case.nContScen + 1 ) , 1:case.nStages ]

    for l = 1:case.nCir, c = 1:( case.nContScen + 1 ) , t = 1:case.nStages 
        circ_anglag_cstr[ l , c , t ] = @constraint( model , f[ l , c , t ] == ( case.al[ l , c ] / circuits.Reat[ l ] ) * ( theta[ circuits.BusFrom[ l ] , c , t ] - theta[ circuits.BusTo[ l ] , c , t ] ) )
    end

    return nothing
end

#---------------------------------------------------
#---            Generators constraint            ---
#---------------------------------------------------

#--- add_startupcost_constraint!: This function creates constraints to define what is the startup cost for each generator in each period ---
function add_startupcost_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local genco_startupcost_cstr::Array{JuMP.ConstraintRef,3}      # Constraint to represent the generators startup cost
    
    local startcost::Array{JuMP.Variable,2}                        # Variable to represent generators start up cost
    local v::JuMP.JuMPArray{JuMP.Variable,2}                                # Variable to represent generators commitment
           
    local u::Int                                                   # Local variable to loop over generators
    local pat::Int                                                 # Local variable to loop over the stairwise startup cost
    local t::Int                                                   # Local variable to loop over stages

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    v = model[:v]
    startcost = model[:startcost]

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_startupcost_cstr[ 1:case.nGen , 1:case.nStages , 1:3 ]

    for u = 1:case.nGen , t = 1:case.nStages , pat = 1:3

        genco_startupcost_cstr[ u , t , pat ] = @constraint( model , startcost[ u , t ] >= generators.StartUpCost[ u , pat ] * ( v[ u , t ] - sum( v[ u , t-n ] for n = 1:pat ) ) )
      
    end

    return nothing

end

#--- add_startupcost_constraint!: This function creates constraints to define what is the shutdown cost for each generator ---
function add_shutdowncost_constraint!( model::JuMP.Model , case::Case , generators::Gencos )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local genco_shutdowncost_cstr::Array{JuMP.ConstraintRef,2}      # Constraint to represent the generators shutdown cost

    local downcost::Array{JuMP.Variable,2}                          # Variable to represent generators shutdown cost
    local v::JuMP.JuMPArray{JuMP.Variable,2}                                 # Variable to represent generators commitment

    local u::Int                                                    # Local variable to loop over generators
    local t::Int                                                    # Local variable to loop over stages

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    v        = model[:v]
    downcost = model[:downcost]

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_shutdowncost_cstr[ 1:case.nGen , 1:case.nStages ]

    for u = 1:case.nGen , t = 1:case.nStages

        genco_shutdowncost_cstr[ u , t ] = @constraint(model, downcost[ u , t ] >= generators.ShutdownCost[u] *( v[ u , t - 1 ]- v[ u , t ] ) )
      
    end

    return nothing
end

#--- add_generation_limits!: This function creates constraints to limitate the generation of each genco in each period ---
function add_generation_limits_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local genco_maxgen_cstr::Array{JuMP.ConstraintRef,3}     # Constraint to represent maximmum generation bound
    local genco_mingen_cstr::Array{JuMP.ConstraintRef,3}     # Constraint to represent minimum generation bound

    local g::JuMP.JuMPArray{JuMP.Variable,3}                          # Variable to represent generators generations
    local v::JuMP.JuMPArray{JuMP.Variable,2}                          # Variable to represent generators commitment
    local p::JuMP.JuMPArray{JuMP.Variable,2}                          # Variable to represent generators maximum available power 
    local resup::Array{JuMP.Variable,2}                      # Variable to represent generators reserve up 
    local resdown::Array{JuMP.Variable,2}                    # Variable to represent generators reserve down

    local u::Int                                             # Local variable to loop over generators
    local t::Int                                             # Local variable to loop over stages
    local c::Int                                             # Local variable to loop over scenarios

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    g = model[:g]
    v = model[:v]
    p = model[:p]

    if case.Flag_Res == 1
        resup   = model[:resup]
        resdown = model[:resdown]
    end

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_maxgen_cstr[ 1:case.nGen , 1:( case.nContScen + 1 )  , 1:case.nStages ]
    @constraintref genco_mingen_cstr[ 1:case.nGen , 1:( case.nContScen + 1 )  , 1:case.nStages ]

    if case.Flag_Res == 1
        for u = 1:case.nGen , c = 1:( case.nContScen + 1 ) , t = 1:case.nStages
            # genco_maxgen_cstr[ u , c , t ] = @constraint( model , g[ u , c , t ]                    <= resup[ u , t ] + p[ u , t ] )
            # genco_mingen_cstr[ u , c , t ] = @constraint( model , g[ u , c , t ] + resdown[ u , t ] >= generators.PotMin[ u ] * v[ u , t ] )
            genco_maxgen_cstr[ u , c , t ] = @constraint( model , g[ u , c , t ] + resup[ u , t ]   <= p[ u , t ] )
            genco_mingen_cstr[ u , c , t ] = @constraint( model , g[ u , c , t ] + resdown[ u , t ] >= generators.PotMin[ u ] * v[ u , t ] )
        end
    else
        for u = 1:case.nGen , c = 1:( case.nContScen + 1 ) , t = 1:case.nStages
            genco_maxgen_cstr[ u , c , t ] = @constraint( model , g[ u , c , t ]  <= p[ u , t ] )
            genco_mingen_cstr[ u , c , t ] = @constraint( model , g[ u , c , t ]  >= generators.PotMin[ u ] * v[ u , t ] )
        end
    end

    return nothing
end

#--- add_max_available_power!: This function creates constraints to limitate the maximum available power of each genco in each period ---
function add_max_available_power_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local genco_maxdispgen_cstr::JuMP.JuMPArray{JuMP.ConstraintRef,2}     # Constraint to represent maximmum generation bound

    local v::JuMP.JuMPArray{JuMP.Variable,2}                              # Variable to represent generators commitment
    local p::JuMP.JuMPArray{JuMP.Variable,2}                              # Variable to represent generators maximum available power 
             
    local u::Int                                                          # Local variable to loop over generators
    local t::Int                                                          # Local variable to loop over stages

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    v = model[:v]
    p = model[:p]

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_maxdispgen_cstr[ 1:case.nGen , 0:case.nStages ]

    for u = 1:case.nGen , t = 0:case.nStages
        genco_maxdispgen_cstr[ u , t ] = @constraint(model, p[ u , t ] <= generators.PotMax[ u ] * v[ u , t ] )
    end

    return nothing
end

#--- add_ramping_constraint!: This function creates constraints to limitate the ramp-up and rump-down of each genco in each period ----
function add_ramping_constraint!( model::JuMP.Model , case::Case , generators::Gencos )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local genco_rampup_cstr::Array{JuMP.ConstraintRef,2}           # Constraint to represent generators ramp-up and startup limits
    local genco_rampdown_cstr::Array{JuMP.ConstraintRef,2}         # Constraint to represent generators ramp-down limits
    local genco_shutdownrate_cstr::Array{JuMP.ConstraintRef,2}     # Constraint to represent generatos shutdown ramp limits

    local g::JuMP.JuMPArray{JuMP.Variable,3}                                # Variable to represent generators generations
    local v::JuMP.JuMPArray{JuMP.Variable,2}                                # Variable to represent generators commitment
    local p::JuMP.JuMPArray{JuMP.Variable,2}                                # Variable to represent generators maximum available power 
    
    local ramp_up::Array{Float64,1}                                # Local variable to represent ramp up generation variable
    local ramp_down::Array{Float64,1}                              # Local variable to represent ramp down generation variable
    local start_up::Array{Float64,1}                               # Local variable to represent start up ramp variable
    local shutdown::Array{Float64,1}                               # Local variable to represent shutdown ramp variable
    local pot_max::Array{Float64,1}                                # Local variable to represent generator's maximum power 

    local u::Int                                                   # Local variable to loop over generators
    local t::Int                                                   # Local variable to loop over stages

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    g = model[:g]
    v = model[:v]
    p = model[:p]
    
    ramp_up   = generators.RampUp  
    ramp_down = generators.RampDown
    start_up  = generators.StartUpRamp
    shut_down =  generators.ShutdownRamp
    pot_max   = generators.PotMax

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_rampup_cstr[       1:case.nGen, 1:case.nStages ]
    @constraintref genco_rampdown_cstr[     1:case.nGen, 1:case.nStages ]
    @constraintref genco_shutdownrate_cstr[ 1:case.nGen, 1:case.nStages ]

    #--- Ramp-up and Start-up

    for u = 1:case.nGen , t = 1:case.nStages
        genco_rampup_cstr[ u , t ] = @constraint( model , p[ u , t ] <= g[ u , 1 , t - 1 ] + ( ramp_up[ u ] * v[ u , t - 1 ] ) + ( start_up[ u ] * ( v[ u , t ] - v[ u , t - 1 ] ) ) + ( pot_max[ u ]  * ( 1 - v[ u , t ] ) ) )
    end
    
    #--- Shutdown ramp rate

    for u = 1:case.nGen , t = 1:( case.nStages - 1)
        genco_rampdown_cstr[ u , t ] = @constraint( model , p[ u , t ] <= pot_max[ u ] * v[ u , t + 1 ] + shut_down[u] * ( v[ u , t ] - v[ u , t + 1 ] ) )
    end
    
    #--- Ramp down limits

    for u = 1:case.nGen , t = 1:case.nStages
        genco_shutdownrate_cstr[ u , t ] = @constraint( model , g[ u , 1 , t - 1 ] - g[ u , 1 , t ] <= ramp_down[ u ] * v[ u , t ]                      +
                                                                                                       shut_down[ u ] * ( v[ u , t - 1 ] - v[ u , t ] ) + 
                                                                                                       pot_max[ u ] * ( 1 - v[ u , t - 1 ] )             )
    end

    return nothing
end

#--- add_uptime_constraint!: This function creates constraints to limitate the number of periods that generators must stay on after power-on ----
function add_uptime_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------
    
    local genco_muston_cstr::Array{JuMP.ConstraintRef,1}            # Constraint to represent initial periods that generators must stay on
    local genco_minuptime_cstr1::Array{JuMP.ConstraintRef,2}        # Constraint to represent number of periods that generators must stay on after power-on in middle stages
    local genco_minuptime_cstr2::Array{JuMP.ConstraintRef,2}        # Constraint to represent number of periods that generators must stay on after power-on in final stages
 
    local v::JuMP.JuMPArray{JuMP.Variable,2}                                 # Variable to represent generators commitment
    
    local nStgs_mustOn::Array{Int,1}                                # Local variable to represent number of initial stages that generator must remain on 
    local uptime::Array{Int,1}                                      # Local variable to represent the number of minumum stages that generator must remain on afte power-on
    local init_on_time::Array{Int,1}                                # Local variable to represent the number of stages that generator havve been on since t = 0
    local init_commit::Array{Int,2}                                 # Local variable with lasts generators commitment
    local nStgs::Int                                                # Local variable with the number of stages of the case
    local nGen::Int                                                 # Local variable to represent the number of generators in the case
    
    local u::Int                                                    # Local variable to loop over generators
    local t::Int                                                    # Local variable to loop over stages
    local i::Int                                                    # Local variable to loop over indexes
    local k::Int                                                    # Local variable to loop over indexes                        
    local n::Int                                                    # Local variable to loop over indexes

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    v = model[:v]
    
    nStgs = case.nStages
    nGen  = case.nGen

    uptime        = generators.UpTime
    init_on_time  = generators.InitOnTime
    init_commit   = generators.InitCommit

    nStgs_mustOn = max.( min.( nStgs * ones( Float64, nGen ), ( uptime - init_on_time ).*init_commit[ : , 1 ] ) , zeros( Float64 , nGen ) )

    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_muston_cstr[ 1:nGen ]
    @constraintref genco_minuptime_cstr1[ 1:nGen , 1:nStgs ]
    @constraintref genco_minuptime_cstr2[ 1:nGen , 1:nStgs ]

    #--- Must-On stages

    for u in 1:nGen
        if nStgs_mustOn[u] > 0
            genco_muston_cstr[ u ] = @constraint( model , sum( 1 - v[ u , t ] for t in 1:nStgs_mustOn[ u ]) == 0 )
        end
    end

    #--- Minimum Up-time

    for u in 1:case.nGen
        
        #- Middle periods
        for ( i , k ) in enumerate( ( nStgs_mustOn[ u ] + 1 ):( nStgs - uptime[ u ] + 1 ) )
            genco_minuptime_cstr1[ u , i ] =  @constraint( model , sum( v[ u , n ] for n = k:( k + uptime[ u ] - 1 ) ) >=  uptime[ u ] * ( v[ u , k ] - v[ u , k - 1 ] ) )
        end
        
        #- Final periods
        for ( i , k ) in enumerate( ( nStgs - uptime[ u ] + 2 ):( nStgs ) )
            genco_minuptime_cstr2[ u , i ] = @constraint( model, sum( v[ u , n ] - ( v[ u , k ] - v[ u , k - 1 ] ) for n = k:nStgs ) >= 0 )
        end
    end
    
    return nothing
end

#--- add_downtime_constraint!: This function creates constraints to limitate the number of periods that generators must stay off after power-off ----
function add_downtime_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------
    
    local genco_mustoff_cstr::Array{JuMP.ConstraintRef,1}           # Constraint to represent initial periods that generators must stay off
    local genco_mindowntime_cstr1::Array{JuMP.ConstraintRef,2}      # Constraint to represent number of periods that generators must stay off after power-off in middle stages
    local genco_mindowntime_cstr2::Array{JuMP.ConstraintRef,2}      # Constraint to represent number of periods that generators must stay off after power-off in final stages

    local v::JuMP.JuMPArray{JuMP.Variable,2}                                 # Variable to represent generators commitment

    local nStgs_mustOff::Array{Int,1}                               # Local variable to represent number of initial stages that generator must remain off 
    local downtime::Array{Int,1}                                    # Local variable to represent the number of minumum stages that generator must remain off afte power-off
    local init_off_time::Array{Int,1}                               # Local variable to represent the number of stages that generator have been off since t = 0
    local init_commit::Array{Int,2}                                 # Local variable with lasts generators commitment
    local nStgs::Int                                                # Local variable with the number of stages of the case
    local nGen::Int                                                 # Local variable to represent the number of generators in the case

    local u::Int                                                    # Local variable to loop over generators
    local t::Int                                                    # Local variable to loop over stages
    local i::Int                                                    # Local variable to loop over indexes
    local k::Int                                                    # Local variable to loop over indexes                        
    local n::Int                                                    # Local variable to loop over indexes

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    v = model[:v]
    
    nStgs = case.nStages
    nGen  = case.nGen

    downtime      = generators.DownTime
    init_off_time = generators.InitOffTime
    init_commit   = generators.InitCommit

    nStgs_mustOff = max.( min.( nStgs * ones( Float64 , nGen ) , ( downtime - init_off_time ).*( 1 - init_commit[ : , 1 ] ) ) , zeros( Float64, nGen ) )
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_mustoff_cstr[      1:nGen ]
    @constraintref genco_mindowntime_cstr1[ 1:nGen , 1:nStgs ]
    @constraintref genco_mindowntime_cstr2[ 1:nGen , 1:nStgs ]

    #--- Must-off stages

    for u in 1:nGen
        if nStgs_mustOff[ u ] > 0
            genco_mustoff_cstr[ u ] = @constraint(model, sum( v[ u , t ] for t in 1:nStgs_mustOff[ u ] ) == 0 )
        end
    end

    #--- Minimum downtime
    
    for u in 1:case.nGen
        
        #- Middle periods
        
        for ( i , k ) in enumerate( ( nStgs_mustOff[ u ] + 1 ):( nStgs - downtime[ u ] + 1 ) )
            genco_mindowntime_cstr1[ u , i ] = @constraint( model, sum( 1 - v[ u , n ] for n in k:( k + downtime[ u ]-1 ) ) >=  downtime[ u ] * ( v[ u , k - 1 ] - v[ u , k ] ) )
        end
        
        #- Final periods
        for ( i , k ) in enumerate( ( nStgs - downtime[ u ] + 2 ):nStgs )
            genco_mindowntime_cstr2[ u , i ] = @constraint( model, sum( 1 - v[ u , n ] - ( v[ u , k - 1 ] - v[ u , k ] ) for n = k:nStgs ) >= 0 )
        end
    end

    return nothing
end

#--- add_reserve_constraint!: This function creates the maximum and minimum reserve constraint ---
function add_reserve_constraint!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local genco_maxresup_cstr::Array{JuMP.ConstraintRef,2}      # Constraint to represent maximum reserve up
    local genco_maxresdown_cstr::Array{JuMP.ConstraintRef,2}    # Constraint to represent maximum reserve down

    local resup::Array{JuMP.Variable,2}                         # Variable to represent generators reserve up 
    local resdown::Array{JuMP.Variable,2}                       # Variable to represent generators reserve down

    local maxResUp::Array{Float64,1}                            # Local variable to represent the maximum reserve up of each generator
    local maxResDown::Array{Float64,1}                          # Local variable to represent the maximum reserve down of each generator

    local nStgs::Int                                            # Local variable with the number of stages of the case
    local nGen::Int                                             # Local variable to represent the number of generators in the case

    local u::Int                                                # Local variable to loop over generators
    local t::Int                                                # Local variable to loop over stages
    
    #-------------------------
    #---  Assigning values ---
    #-------------------------

    resup   = model[:resup]
    resdown = model[:resdown]

    nGen  = case.nGen
    nStgs = case.nStages

    maxResUp   = generators.ReserveUp
    maxResDown = generators.ReserveDown
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_maxresup_cstr[   1:nGen , 1:nStgs ]
    @constraintref genco_maxresdown_cstr[ 1:nGen , 1:nStgs ]

    for u = 1:nGen , t = 1:nStgs
        genco_maxresup_cstr[   u , t ] = @constraint( model , resup[   u , t ] <= maxResUp[   u ] )
        genco_maxresdown_cstr[ u , t ] = @constraint( model , resdown[ u , t ] <= maxResDown[ u ] )
    end

    return nothing
    
end

#--- add_contingency_constraint!: this function creates the contingency constraint
function add_contingency_constraint!( model::JuMP.Model , case::Case , generators::Gencos )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local genco_maxgen_cont_cstr::JuMP.JuMPArray{JuMP.ConstraintRef,3}       # Constraint to represent maximum generation in each contingency scenario
    local genco_mingen_cont_cstr::JuMP.JuMPArray{JuMP.ConstraintRef,3}       # Constraint to represent minimum generation in each contingency scenario
    
    local g::JuMP.JuMPArray{JuMP.Variable,3}                                 # Represent generators generations
    local resup::Array{JuMP.Variable,2}                             # Represent generators reserve up 
    local resdown::Array{JuMP.Variable,2}                           # Represent generators reserve down
    
    local ag::Array{Int,2}                                          # Local variable to represent contingency scenarios
    local nScen::Int                                                # Local variable to represent number of contingency scenarios
    local nStgs::Int                                                # Local variable to represent number of stages of case
    local nGen::Int                                                 # Local variable to represent number of generators

    local u::Int                                                    # Local variable to loop over generators
    local t::Int                                                    # Local variable to loop over stages
    local c::Int                                                    # Local variable to loop over scenarios
    
    #-------------------------
    #---  Assigning values ---
    #-------------------------

    g = model[:g]
    
    if case.Flag_Res == 1
        resup   = model[:resup]
        resdown = model[:resdown]
    end

    ag    = case.ag
    nScen = case.nContScen
    nStgs = case.nStages
    nGen  = case.nGen
    
    #-----------------------------------------
    #---  Adding constraints in the model  ---
    #-----------------------------------------

    @constraintref genco_maxgen_cont_cstr[ 1:nGen , 2:( nScen + 1 ) , 1:nStgs ]
    @constraintref genco_mingen_cont_cstr[ 1:nGen , 2:( nScen + 1 ) , 1:nStgs ]

    if case.Flag_Res == 1
        for u = 1:nGen , c = 2:( nScen + 1 ) , t = 1:nStgs
            genco_maxgen_cont_cstr[ u , c , t ] = @constraint( model,   g[ u , c , t ]                                    <= ( g[ u , 1 , t ] + resup[ u , t ]) * ag[ u , c ] )
            genco_mingen_cont_cstr[ u , c , t ] = @constraint( model, ( g[ u , 1 , t ] - resdown[ u , t ] ) * ag[ u , c ] <= g[ u , c , t ]                                   ) 
        end
    else
        for u = 1:nGen , c = 2:( nScen + 1 ) , t = 1:nStgs
            genco_maxgen_cont_cstr[ u , c , t ] = @constraint( model,   g[ u , c , t ]               <= g[ u , 1 , t ] * ag[ u , c ] )
            genco_mingen_cont_cstr[ u , c , t ] = @constraint( model,   g[ u , 1 , t ] * ag[ u , c ] <= g[ u , c , t ]               ) 
        end
    end

    
end

#--- add_obj_fun!: This function creates and append the objective function to the model ---
function add_obj_fun!( model::JuMP.Model , case::Case , generators::Gencos )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local syst_cost::JuMP.GenericAffExpr{Float64,JuMP.Variable}         # Local variable to represent system total cost

    local g::JuMP.JuMPArray{JuMP.Variable,3}                            # Represent generators generations
    local startcost::Array{JuMP.Variable,2}                             # Represent generators startup cost
    local downcost::Array{JuMP.Variable,2}                              # Represent generators shutdown cost
    local resup::Array{JuMP.Variable,2}                                 # Represent generators reserve up 
    local resdown::Array{JuMP.Variable,2}                               # Represent generators reserve down

    local gen_cvu::Array{Float64,1}                                     # Represent the generators CVU
    local cost_resup::Array{Float64,1}                                  # Represent the generators reserve up cost
    local cost_resdown::Array{Float64,1}                                # Represent the generators reserve up cost

    local nStgs::Int                                                    # Local variable with the number of stages of the case
    local nGen::Int                                                     # Local variable to represent the number of generators in the case
    
    local u::Int                                                        # Local variable to loop over generators
    local t::Int                                                        # Local variable to loop over stages

    #-------------------------
    #---  Assigning values ---
    #-------------------------

    g         = model[:g]
    startcost = model[:startcost]
    downcost  = model[:downcost]

    if case.Flag_Res == 1
        resup   = model[:resup]
        resdown = model[:resdown]
    end

    gen_cvu = generators.CVU
    cost_resup = generators.ReserveUpCost
    cost_resdown = generators.ReserveDownCost

    nGen = case.nGen
    nStgs = case.nStages

    #-----------------------------------
    #---  Adding objective function  ---
    #-----------------------------------

    if case.Flag_Res == 1
        @objective( model , Min , + sum( g[ u , 1 , t ] * gen_cvu[ u ] for u in 1:nGen , t  in 1:nStgs )
                                  + sum( resup[ u , t ] * cost_resup[u] for u in 1:nGen , t  in 1:nStgs )
                                  + sum( resdown[ u , t ] * cost_resdown[u] for u in 1:nGen , t  in 1:nStgs )
                                  + sum( startcost[ u , t ] + downcost[ u , t ] for u in 1:nGen , t  in 1:nStgs ) )
        
    else
        @objective( model , Min , + sum( g[ u , 1 , t ] * gen_cvu[ u ] for u in 1:nGen , t  in 1:nStgs )
                                  + sum( startcost[ u , t ] + downcost[ u , t ] for u in 1:nGen , t  in 1:nStgs ) )
    end

    return nothing
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

        #prices     = getdual(getindex( model , :load_balance ) )
        generation = getvalue( model, :g )
        cir_flow   = getvalue( model, :f )
        v          = getvalue( model, :v )
        potdisp    = getvalue( model, :p )

        if case.Flag_Res == 1
            res_up_gen   = getvalue( model, :resup   )
            res_down_gen = getvalue( model, :resdown )
        end
        
        if case.Flag_Ang == 1
            bus_ang = getvalue( model, :theta )
        end

        #--- Writing to log the optimal solution

        w_Log("\n     Optimal solution found!\n" , path )

        #- Marginal cost

        # for b in 1:case.nBus
        #     w_Log("     Marginal cost for the bus $(buses.Name[b]): $(round.(sum(prices[b,:,:]),2)) R\$/MWh" , path )
        # end

        # write_outputs("results_bus.csv", path, prices[:,1,:], buses.Name)
        
        # w_Log( " " , path )
        
        #- Gencos generation

        for u in 1:case.nGen
            w_Log("     Optimal generation of $(generators.Name[u]): $(round.(generation[u,1,:],2)) MWh" , path )
        end
        
        write_outputs( "results_gen.csv" , path, generation[:,1,:] , generators.Name)

        #- Commitment

        w_Log( " " , path )
        for u in 1:case.nGen
            w_Log("     Commitment of $(generators.Name[u]): $(round.(v[u,:],2))" , path )
        end
        
        write_outputs("results_commit.csv", path, v, generators.Name)

        #- Reserve generation 

        if case.Flag_Res == 1
            
            w_Log( " " , path )
            
            for u in 1:case.nGen
                w_Log("     Optimal Reserve Up of $(generators.Name[u]): $(round.(res_up_gen[u,:],2)) MWh" , path )
            end
            # write reserve up output
            write_outputs( "results_resup.csv" , path , res_up_gen , generators.Name )
            
            w_Log( " " , path )
            
            for u in 1:case.nGen
                w_Log("     Optimal Reserve Down of $(generators.Name[u]): $(round.(res_down_gen[u,:],2)) MWh" , path )
            end
            # write reserve down output
            write_outputs( "results_resdown.csv" , path , res_down_gen , generators.Name )
            
        end
        
        w_Log( " " , path )

        #- Circuits flow
        
        for l in 1:case.nCir
            w_Log("     Optimal flow in line $(circuits.Name[l]): $(round.(cir_flow[l,1,:],2)) MW" , path )
        end
        
        write_outputs("results_circ.csv", path, cir_flow[:,1,:], circuits.Name)
        
        #- Buses angles

        if case.Flag_Ang == 1
            
            w_Log( " " , path )
            
            for b in 1:case.nBus
                w_Log("     Optimal bus angle $(buses.Name[b]): $(round.(bus_ang[b,1,:],2)) grad" , path )
            end
            # write reserve down output
            write_outputs("results_busang.csv", path, bus_ang[:,1,:], buses.Name)
        end
        
        # write potdisp
        # write_outputs("results_potdisp.csv", path, potdisp, generators.Name)
    
    w_Log("\n    Total cost = $(round(getobjectivevalue(model)/1000,2)) k\$" ,  path)

    elseif status == :Infeasible
        w_Log("\n     No solution found!\n\n     This problem is Infeasible!" , path )
        # w_Log("\n     $(case.ag)" , path )
        # w_Log("\n     $(case.al)" , path )
    end

end