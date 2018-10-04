#--------------------------------------------------------
#----           Functions to read data base          ----
#--------------------------------------------------------

#- Author: Jairo Terra, Guilherme Machado, Mateus Cavaliere ( PUC - 2018 )
#- Description: This module cointains the functions to read all the data base

#--- read_options: Function to read model options ---
function read_options( path::String , file_name::String = "dispatch.dat" )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to gencos.dat file
    local iodata::Array{String,1}           # Local variable to buffer information from read gencos.dat file
    local flag_res::Int                     # Local variable to buffer reserve option
    local flag_ang::Int                     # Local variable to buffer angular diff option
    local flag_cont::Int                    # Local variable to buffer contingency option
    local flag_cont_crit::Int               # Local variable to buffer contingency criteria option
    local nStages::Int                      # Local variable to buffer the number of stages

    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #-----------------------
    #--- Assigning data  ---
    #-----------------------
    
    flag_ang       = string_converter( iodata[1][27:30]  , Int , "Invalid entry for angular diff option")
    flag_res       = string_converter( iodata[2][27:30]  , Int , "Invalid entry for reserve option")
    flag_cont      = string_converter( iodata[3][27:30]  , Int , "Invalid entry for contingency option")
    flag_cont_crit = string_converter( iodata[4][27:30]  , Int , "Invalid entry for contingency criteria option")
    nStages        = string_converter( iodata[5][27:30]  , Int , "Invalid entry for the number of stages")

    #--- Checking user input consistency

    #- Reserve option
    if (flag_res != 0) & (flag_res != 1)
        exit()
    end

    #- Angular diff option
    if (flag_ang != 0) & (flag_ang != 1)
        exit()
    end

    #- Contingency option
    if (flag_cont != 0) & (flag_cont != 1) & (flag_cont != 2) & (flag_cont != 3)
        exit()
    end

    #- Number of stages
    if nStages < 1 
        w_Log("     ERROR: The number of stages must be at least 1 ($(nStages)) ", path );
        exit()
    end

    return( flag_res , flag_ang , flag_cont, flag_cont_crit , nStages )
end 

function read_gencos( path::String , case::Case , buses::Buses , file_name::String = "gencos.csv")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                      # Local variable to buffer connection to gencos.dat file
    local iodata::Array{String,1}               # Local variable to buffer information from read gencos.dat file
    local auxdata::Array{SubString{String},1}   # Local variable to buffer information after parsing
    local u::Int                                # Local variable to loop over gencos 
    local nGen::Int                             # Local variable to buffer the number of gencos
    local gencos::Gencos                        # Local variable to buffer gencos information
    
    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------
    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nGen = length( iodata )

    #- Create struct to buffer gencos information

    gencos                 = Gencos()
    gencos.Num             = Array{Int}(nGen)
    gencos.Name            = Array{String}(nGen)
    gencos.Bus             = Array{Int}(nGen)
    gencos.PotMin          = Array{Float64}(nGen)
    gencos.PotMax          = Array{Float64}(nGen)
    gencos.PotPat1         = Array{Float64}(nGen)
    gencos.PotPat2         = Array{Float64}(nGen)
    gencos.StartUpRamp     = Array{Float64}(nGen)
    gencos.RampUp          = Array{Float64}(nGen)
    gencos.ShutdownRamp    = Array{Float64}(nGen)
    gencos.RampDown        = Array{Float64}(nGen)
    gencos.ReserveUp       = Array{Float64}(nGen)
    gencos.ReserveDown     = Array{Float64}(nGen)
    gencos.UpTime          = Array{Int}(nGen)
    gencos.DownTime        = Array{Int}(nGen)
    gencos.CVU             = Array{Float64}(nGen)
    gencos.CVUPat1         = Array{Float64}(nGen)
    gencos.CVUPat2         = Array{Float64}(nGen)
    gencos.CVUPat3         = Array{Float64}(nGen)
    gencos.StartUpCost_1   = Array{Float64}(nGen)
    gencos.StartUpCost_2   = Array{Float64}(nGen)
    gencos.StartUpCost_3   = Array{Float64}(nGen)
    gencos.ShutdownCost    = Array{Float64}(nGen)
    gencos.ReserveUpCost   = Array{Float64}(nGen)
    gencos.ReserveDownCost = Array{Float64}(nGen)
    
    #- Looping over the read information from gencos.dat 

    for u in 1:nGen
        auxdata = split( iodata[u] , "," )
        gencos.Num[u]             = string_converter( auxdata[1]  , Int , "Invalid entry for the number of genco $(u) ")
        gencos.Name[u]            = strip( auxdata[2] )
        gencos.Bus[u]             = string_converter( auxdata[3]  , Int     , "Invalid entry for the bus of genco $(u)")
        gencos.PotMin[u]          = string_converter( auxdata[4]  , Float64 , "Invalid entry for the min pot of genco $(u) ")
        gencos.PotMax[u]          = string_converter( auxdata[5]  , Float64 , "Invalid entry for the max pot of genco $(u) ")
        gencos.PotPat1[u]         = string_converter( auxdata[6]  , Float64 , "Invalid entry for the Pot Pat 1 of genco $(u) ")
        gencos.PotPat2[u]         = string_converter( auxdata[7]  , Float64 , "Invalid entry for the Pot Pat 2 of genco $(u) ")
        gencos.StartUpRamp[u]     = string_converter( auxdata[8]  , Float64 , "Invalid entry for the Start-Up Ramp of genco $(u) ")
        gencos.RampUp[u]          = string_converter( auxdata[9]  , Float64 , "Invalid entry for the Ramp-Up of genco $(u) ")
        gencos.ShutdownRamp[u]    = string_converter( auxdata[10]  , Float64 , "Invalid entry for the Shutdown Ramp of genco $(u) ")
        gencos.RampDown[u]        = string_converter( auxdata[11]  , Float64 , "Invalid entry for the Ramp-Down of genco $(u) ")
        gencos.ReserveUp[u]       = string_converter( auxdata[12]  , Float64 , "Invalid entry for the Reserve-Up of genco $(u) ")
        gencos.ReserveDown[u]     = string_converter( auxdata[13]  , Float64 , "Invalid entry for the Reserve-Down of genco $(u) ")
        gencos.UpTime[u]          = string_converter( auxdata[14]  , Int     , "Invalid entry for the Up Time of genco $(u) ")
        gencos.DownTime[u]        = string_converter( auxdata[15]  , Int     , "Invalid entry for the Down Time of genco $(u) ")
        gencos.CVU[u]             = string_converter( auxdata[16]  , Float64 , "Invalid entry for the CVU of genco $(u) ")
        gencos.CVUPat1[u]         = string_converter( auxdata[17]  , Float64 , "Invalid entry for the CVU Pat 1 of genco $(u) ")
        gencos.CVUPat2[u]         = string_converter( auxdata[18]  , Float64 , "Invalid entry for the CVU Pat 2 of genco $(u) ")
        gencos.CVUPat3[u]         = string_converter( auxdata[19]  , Float64 , "Invalid entry for the CVU Pat 3 of genco $(u) ")
        gencos.StartUpCost_1[u]   = string_converter( auxdata[20]  , Float64 , "Invalid entry for the Start-Up Cost 1 of genco $(u) ")
        gencos.StartUpCost_2[u]   = string_converter( auxdata[21]  , Float64 , "Invalid entry for the Start-Up Cost 2 of genco $(u) ")
        gencos.StartUpCost_3[u]   = string_converter( auxdata[22]  , Float64 , "Invalid entry for the Start-Up Cost 3 of genco $(u) ")
        gencos.ShutdownCost[u]    = string_converter( auxdata[23]  , Float64 , "Invalid entry for the Shutdown Cost of genco $(u) ")
        gencos.ReserveUpCost[u]   = string_converter( auxdata[24]  , Float64 , "Invalid entry for the Reserve Up Cost of genco $(u) ")
        gencos.ReserveDownCost[u] = string_converter( auxdata[25]  , Float64 , "Invalid entry for the Reserve Down Cost of genco $(u) ")
    end

    #--- Checking data consistency

    for u in 1:nGen
        
        #- Generator number
        if gencos.Num[u] < 1
            w_Log("     ERROR: Invalid number of generator $(u) (must be greater than 1) ", path );
            exit()
        end

        #- Generator bus
        if gencos.Bus[u] < 1
            w_Log("     ERROR: Invalid number of generators bus $(u) (must be greater than 1) ", path );
            exit()
        end

        if !(gencos.Bus[u] in buses.Num)
            w_Log("     ERROR: The bus of generator $(d) is not a valid ($(demands.Bus[d]))", path );
            exit()
        end

        #- Negative power capacity
        
        if gencos.PotMin[u] < 0
            w_Log("     ERROR: Minimum power capacity of generator $(u) is negative ($(gencos.PotMin[u]) MW)", path );
            exit()
        end

        if gencos.PotPat1[u] < 0
            w_Log("     ERROR: Power capacity of Pat 1 of generator $(u) is negative ($(gencos.PotPat1[u]) MW)", path );
            exit()
        end

        if gencos.PotPat2[u] < 0
            w_Log("     ERROR: Power capacity of Pat 2 of generator $(u) is negative ($(gencos.PotPat2[u]) MW)", path );
            exit()
        end

        if gencos.PotMax[u] < 0
            w_Log("     ERROR: Maximum power capacity of generator $(u) is negative ($(gencos.PotMax[u]) MW)", path );
            exit()
        end

        #- Generator minimum power capacity greater than power capacity of Pat 1
        if gencos.PotMin[u] > gencos.PotPat1[u]
            w_Log("     ERROR: Minimum power capacity of generator $(u) is greater than power capacity of Pat 1 
            ($(gencos.PotMin[u]) MW > $(gencos.PotPat1[u]) MW)", path );
            exit()
        end

        #- Generator power capacity of Pat 1 greater than power capacity of Pat 2
        if gencos.PotPat1[u] > gencos.PotPat2[u]
            w_Log("     ERROR: Power capacity of Pat 1 of generator $(u) is greater than the power capacity of Pat 2
            ($(gencos.PotPat1[u]) MW > $(gencos.PotPat2[u]) MW)", path );
            exit()
        end

        #- Generator power capacity of Pat 2 greater than maximum power capacity
        if gencos.PotPat2[u] > gencos.PotMax[u]
            w_Log("     ERROR: Power capacity of Pat 2 of generator $(u) is greater than the maximum power capacity
            ($(gencos.PotPat2[u]) MW > $(gencos.PotMax[u]) MW)", path );
            exit()
        end

        #- StartUpRamp small than 1
        if gencos.StartUpRamp[u] < 1
            w_Log("     ERROR: Start-up ramp of generator $(u) must be grater than 1 ($(gencos.StartUpRamp[u]) h)", path );
            exit()
        end

        #- Ramp up small than 1
        if gencos.RampUp[u] < 1
            w_Log("     ERROR: Ramp up of generator $(u) must be grater than 1 ($(gencos.RampUp[u]) h)", path );
            exit()
        end

        #- Shutdown Ramp small than 1
        if gencos.ShutdownRamp[u] < 1
            w_Log("     ERROR: Shutdown ramp of generator $(u) must be grater than 1 ($(gencos.ShutdownRamp[u]) h)", path );
            exit()
        end

        #- Ramp down small than 1
        if gencos.RampDown[u] < 1
            w_Log("     ERROR: Ramp down of generator $(u) must be grater than 1 ($(gencos.RampDown[u]) h)", path );
            exit()
        end

        #- Negative reserve up
        if gencos.ReserveUp[u] < 0
            w_Log("     ERROR: Reserve up of generator $(u) must be grater than 0 ($(gencos.ReserveUp[u]) h)", path );
            exit()
        end

        #- Negative reserve down
        if gencos.ReserveDown[u] < 0
            w_Log("     ERROR: Reserve down of generator $(u) must be grater than 0 ($(gencos.ReserveDown[u]) h)", path );
            exit()
        end

        #- Negative CVU

        if gencos.CVU[u] < 0
            w_Log("     ERROR: CVU of generator $(u) must be grater than 0 ($(gencos.CVU[u]) R\$/MWh)", path );
            exit()
        end

        if gencos.CVUPat1[u] < 0
            w_Log("     ERROR: CVU of generator $(u) in Pat 1 must be grater than 0 ($(gencos.CVUPat1[u]) R\$/MWh)", path );
            exit()
        end
        
        if gencos.CVUPat2[u] < 0
            w_Log("     ERROR: CVU of generator $(u) in Pat 2 must be grater than 0 ($(gencos.CVUPat2[u]) R\$/MWh)", path );
            exit()
        end

        if gencos.CVUPat3[u] < 0
            w_Log("     ERROR: CVU of generator $(u) in Pat 3 must be grater than 0 ($(gencos.CVUPat3[u]) R\$/MWh)", path );
            exit()
        end

        #- CVU is greater than the CVU Pat 1
        if gencos.CVU[u] > gencos.CVUPat1[u]
            w_Log("     ERROR: CVU of generator $(u) is greater than the CVU Pat 1 
            ($(gencos.CVU[u]) R\$/MWh > $(gencos.CVUPat1[u]) R\$/MWh)", path );
            exit()
        end

        #- CVU Pat 1 is greater than the CVU Pat 2
        if gencos.CVUPat1[u] > gencos.CVUPat2[u]
            w_Log("     ERROR: CVU Pat 1 of generator $(u) is greater than the CVU Pat 2 
            ($(gencos.CVUPat1[u]) R\$/MWh > $(gencos.CVUPat2[u]) R\$/MWh)", path );
            exit()
        end

        #- CVU Pat 2 is greater than the CVU Pat 3
        if gencos.CVUPat2[u] > gencos.CVUPat3[u]
            w_Log("     ERROR: CVU Pat 2 of generator $(u) is greater than the CVU Pat 3 
            ($(gencos.CVUPat2[u]) R\$/MWh > $(gencos.CVUPat3[u]) R\$/MWh)", path );
            exit()
        end
        
        #- Negative Start-up cost
        
        if gencos.StartUpCost_1[u] < 0
            w_Log("     ERROR: Start-up cost 1 of generator $(u) must be grater than 0 ($(gencos.StartUpCost_1[u]) R\$/MWh)", path );
            exit()
        end

        if gencos.StartUpCost_2[u] < 0
            w_Log("     ERROR: Start-up cost 2 of generator $(u) must be grater than 0 ($(gencos.StartUpCost_2[u]) R\$/MWh)", path );
            exit()
        end

        if gencos.StartUpCost_3[u] < 0
            w_Log("     ERROR: Start-up cost 3 of generator $(u) must be grater than 0 ($(gencos.StartUpCost_3[u]) R\$/MWh)", path );
            exit()
        end

        #- Negative shutdown cost
        if gencos.ShutdownCost[u] < 0
            w_Log("     ERROR: Shutdown cost of generator $(u) must be grater than 0 ($(gencos.ShutdownCost[u]) R\$/MWh)", path );
            exit()
        end

        #- Negative reserve up cost
        if gencos.ReserveUpCost[u] < 0
            w_Log("     ERROR: Reserve up cost of generator $(u) must be grater than 0 ($(gencos.ReserveUpCost[u]) R\$/MWh)", path );
            exit()
        end

        #- Negative reserve down cost
        if gencos.ReserveDownCost[u] < 0
            w_Log("     ERROR: Reserve down cost of generator $(u) must be grater than 0 ($(gencos.ReserveDownCost[u]) R\$/MWh)", path );
            exit()
        end

        #- Invalid entry for up time
        if gencos.UpTime[u] < 1
            w_Log("     ERROR: Up time of generator $(u) must be grater than 1 ($(gencos.UpTime[u]) h)", path );
            exit()
        end

        if gencos.UpTime[u] > case.nStages
            w_Log("     WARNING: Up time of generator $(u) is greater than the number of stages of this case ($(gencos.UpTime[u]) h > $(case.nStages) h)", path );
            gencos.UpTime[u] = case.nStages
        end

        #- Invalid entry for down time
        if gencos.DownTime[u] < 1
            w_Log("     ERROR: Down time of generator $(u) must be grater than 1 ($(gencos.DownTime[u]) h)", path );
            exit()
        end

        if gencos.DownTime[u] > case.nStages
            w_Log("     WARNING: Down time of generator $(u) is greater than the number of stages of this case ($(gencos.DownTime[u]) h > $(case.nStages) h)", path );
            gencos.DownTime[u] = case.nStages
        end
        
    end

    return( nGen , gencos )
end

function read_init_commit( path::String , case::Case , file_name::String = "init_commit.csv")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                      # Local variable to buffer connection to gencos.dat file
    local iodata::Array{String,1}               # Local variable to buffer information from read gencos.dat file
    local auxdata::Array{SubString{String},1}   # Local variable to buffer information after parsing
    local u::Int                                # Local variable to loop over gencos 
    local nGen::Int                             # Local variable to buffer the number of gencos
    local initCommit::Array{Int}                # Local variable to buffer the initial commit stage of each generator
    local initGen::Array{Float64}               # Local variable to buffer the initial generation of each generator
    local initOffTime::Array{Int}               # Local variable to buffer the off-line time of each generator in t = 0
    local initOnTime::Array{Int}                # Local variable to buffer the on-line time of each generator in t = 0

    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------
    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nGen = length( iodata )

    #- Check input consistency

    if case.nGen != nGen
        w_Log("     ERROR: Number of generator in init_commit.csv is different from gencos.csv", path );
        exit()
    end

    #- Create struct to buffer gencos information

    initCommit  = Array{Int}(nGen,3)
    initGen     = Array{Float64}(nGen)
    initOffTime = Array{Int}(nGen)
    initOnTime  = Array{Int}(nGen)

    #- Looping over the read information from init_commit.csv 

    for u in 1:nGen
        auxdata         = split( iodata[u] , "," )
        initGen[u]      = string_converter( auxdata[3]  , Float64 , "Invalid entry for the intial generation of genco $(u) ")
        initOffTime[u]  = string_converter( auxdata[4]  , Int     , "Invalid entry for the off-line time in t = 0 of genco $(u)")
        initOnTime[u]   = string_converter( auxdata[5]  , Int     , "Invalid entry for the on-line time in t = 0 of genco $(u) ")  
        for pat in 1:3
            initCommit[u,pat]   = string_converter( auxdata[5+pat]  , Int     , "Invalid entry for the initial commit stage of genco $(u) ")
        end
    end

    #- Check input consistency

    for u in 1:nGen
        for pat in 1:3
            if (initCommit[u,pat] != 0) && (initCommit[u,pat] != 1)
                w_Log("     ERROR: Invalid commit value for the generator $(u) in t = 0", path );
                exit()
            end
        end

        if (initGen[u] < 0)
            w_Log("     ERROR: Invalid generation value for the generator $(u) in t = 0", path );
            exit()
        end

        if (initOffTime[u] < 0)
            w_Log("     ERROR: Invalid off-line time in t = 0 of genco $(u)", path );
            exit()
        end

        if (initOnTime[u] < 0)
            w_Log("     ERROR: Invalid off-line time in t = 0 of genco $(u)", path );
            exit()
        end
    end

    return( initCommit , initGen , initOffTime , initOnTime )

end

#--- read_demands: Function to read demands configuration ---
function read_demands( path::String , case::Case , buses::Buses , file_name::String = "demand.csv")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                      # Local variable to buffer connection to demands.dat file
    local iodata::Array{String,1}               # Local variable to buffer information from read demands.dat file
    local auxdata::Array{SubString{String},1}   # Local variable to buffer information after parsing
    local d::Int                                # Local variable to loop over loads 
    local t::Int                                # Local variable to loop over periods
    local nDem::Int                             # Local variable to buffer the number of demands
    local demands::Demands                      # Local variable to buffer demands information
    
    #---------------------------------
    #--- Reading file (demand.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]
    
    #- Get number of demand stages
    nStages = length(split(iodata[1],",")) - 4

    #- Check input
    if nStages != case.nStages
        w_Log("     ERROR: The number of demand stages must be equal to the number of stages of the case", path );
        exit()
    end

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated demand
    nDem = length( iodata )

    #- Create struct to buffer demands information
    demands         = Demands()
    demands.Num     = Array{Int}(nDem)
    demands.Name    = Array{String}(nDem)
    demands.Bus     = Array{Int}(nDem)
    demands.Dem     = Array{Float64}(nDem)
    demands.Profile = Array{Float64}(nDem,nStages)

    #- Looping over the read information from demand.dat 
    for d in 1:nDem
        auxdata         = split( iodata[d] , "," )
        demands.Num[d]  = string_converter( auxdata[1]  , Int , "Invalid entry for the number of demand $(d)")  
        demands.Name[d] = strip( auxdata[2] ) 
        demands.Bus[d]  = string_converter( auxdata[3]  , Int     , "Invalid entry for the demand bus $(d)") 
        demands.Dem[d]  = string_converter( auxdata[4]  , Float64 , "Invalid entry for the load of demand $(d)")
        for t in 1:nStages
            demands.Profile[d,t] = string_converter( auxdata[4+t]  , Float64 , "Invalid entry for the load profile of demand $(d) in hour $(t)")
        end
    end

    #- Checking inputs consistency

    for d in 1:nDem

        #- Demand number
        if demands.Num[d] < 1
            w_Log("     ERROR: The number of demand $(d) must be at least 1 ($(demands.Num[d]))", path );
            exit()
        end

        #- Demand bus
        if demands.Bus[d] < 1
            w_Log("     ERROR: The number of bus of demand $(d) must be at least 1 ($(demands.Bus[d]))", path );
            exit()
        end

        if !(demands.Bus[d] in buses.Num)
            w_Log("     ERROR: The bus of demand $(d) is not a valid ($(demands.Bus[d]))", path );
            exit()
        end

        #- Load of demand
        if demands.Dem[d] < 0
            w_Log("     ERROR: Load of demand $(d) must be greater than 0 ($(demands.Dem[d]) MW )", path );
            exit()
        end

        #- Demand profile
        for t in 1:nStages
            if demands.Profile[d,t] < 0
                w_Log("     ERROR: Load of demand $(d) at time $(t) must be greater than 0 ($(demands.Profile[d,t]) MW)", path );
                exit()
            end
        end
    end

    return( nDem , demands, nStages )
end

#--- read_circuits: Function to read circuits configuration ---
function read_circuits( path::String , buses::Buses , file_name::String = "circs.csv")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                      # Local variable to buffer connection to circs.dat file
    local iodata::Array{String,1}               # Local variable to buffer information from read circs.dat file
    local auxdata::Array{SubString{String},1}   # Local variable to buffer information after parsing
    local l::Int                                # Local variable to loop over circuits 
    local nCir::Int                             # Local variable to buffer the number of circuits
    local circuits::Circuits                    # Local variable to buffer circuits information
    
    #---------------------------------
    #--- Reading file (gencos.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nCir = length( iodata )

    #- Create struct to buffer gencos information

    circuits         = Circuits()
    circuits.Num     = Array{Int}(nCir)
    circuits.Name    = Array{String}(nCir)
    circuits.Cap     = Array{Float64}(nCir)
    circuits.Reat    = Array{Float64}(nCir)
    circuits.BusFrom = Array{Int}(nCir)
    circuits.BusTo   = Array{Int}(nCir)
    
    #- Looping over the read information from circs.dat 
    for l in 1:nCir
        auxdata              = split( iodata[l] , "," )
        circuits.Num[l]      = string_converter( auxdata[1]  , Int , "Invalid entry for the number of CIRCUIT")
        circuits.Name[l]     = strip( auxdata[2] )
        circuits.Cap[l]      = string_converter( auxdata[3]  , Float64 , "Invalid entry for the CIRCUIT capacity" )
        circuits.Reat[l]     = string_converter( auxdata[4]  , Float64 , "Invalid entry for the CIRCUIT reactance" )
        circuits.BusFrom[l]  = string_converter( auxdata[5]  , Int     , "Invalid entry for the CIRCUIT bus from" )
        circuits.BusTo[l]    = string_converter( auxdata[6]  , Int     , "Invalid entry for the CIRCUIT bus to" )
    end

    #- Checking inputs consistency

    for l in 1:nCir

        #- Circuit number
        if circuits.Num[l] < 1
            w_Log("     ERROR: The number of circuit $(l) must be at least 1 ($(circuits.Num[l]))", path );
            exit()
        end

        #- Circuit capacity
        if circuits.Cap[l] < 1
            w_Log("     ERROR: The capacity of circuit $(l) must be greater than 0 ($(circuits.Cap[l]) MW)", path );
            exit()
        end

        #- Circuit reactance
        if circuits.Reat[l] < 1
            w_Log("     ERROR: The reactance of circuit $(l) must be greater than 0 ($(circuits.Reat[l]) p.u.)", path );
            exit()
        end

        #- Circuit bus from

        if !(circuits.BusFrom[l] in buses.Num)
            w_Log("     ERROR: The bus from of circuit $(l) is not a valid ($(circuits.BusFrom[l]))", path );
            exit()
        end

        #- Circuit bus to

        if !(circuits.BusTo[l] in buses.Num)
            w_Log("     ERROR: The bus to of circuit $(l) is not a valid ($(circuits.BusTo[l]))", path );
            exit()
        end

    end

    return( nCir , circuits )

end

#--- read_buses: Function to read buses configuration ---
function read_buses( path::String , file_name::String = "buses.csv")

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                      # Local variable to buffer connection to buses.dat file
    local iodata::Array{String,1}               # Local variable to buffer information from read buses.dat file
    local auxdata::Array{SubString{String},1}   # Local variable to buffer information after parsing
    local b::Int                                # Local variable to loop over buses 
    local nGen::Int                             # Local variable to buffer the number of buses
    local buses::Buses                          # Local variable to buffer buses information
   
    #---------------------------------
    #--- Reading file (buses.dat) ---
    #---------------------------------

    iofile = open( joinpath( path , file_name ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #- Removing header
    iodata = iodata[2:end]

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    #- Get the number of simulated gencos
    nBus = length( iodata )

    #- Create struct to buffer gencos information
    buses         = Buses()
    buses.Num     = Array{Int}(nBus)
    buses.Name    = Array{String}(nBus)

    #- Looping over the read information from buses.dat 
    for b in 1:nBus
        auxdata        = split( iodata[b] , "," )
        buses.Num[b]   = string_converter( auxdata[1]  , Int , "Invalid entry for the number of BUS")
        buses.Name[b]  = strip( auxdata[2] )
    end

    return( nBus , buses )

end