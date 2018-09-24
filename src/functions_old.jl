#       ------------------------------------------------
#                  Defining general functions 
#       ------------------------------------------------

#--- csv2bin : Function to convert from CSV to Binary
function csv2bin( path::String, file_name::String )
    local iofile::Ptr{UInt8}

    iofile  = PSRIOGrafResult_create( 0 );
    PSRIOGrafResult_toBinary(  iofile , string( path , file_name , ".csv" ) , string( path , file_name , ".hdr" ) , string( path , file_name , ".bin" ) )
end

#--- w_Log: Function to write the log ---
function w_Log( msg::String, path::String , flagConsole::Int = 1, flagLog::Int = 1 , logName = "cmgdem_pld.log" , wType = "a" )
    
    if flagLog == 1
        logFile = open( joinpath( path , logName ) , wType )
        write( logFile , string( msg , "\n" ) )
        Base.close( logFile )
    end

    if flagConsole == 1
        Base.print( string( msg , "\n" ) )
    end

    return nothing
end

#--- stringConv: Function to convert read strings to another type ---
function string_converter( self::String , tipo::Type , msg::String ) 
    try
        parse( tipo , self )
    catch
        error( msg )
    end
end;

#--- getPaths: Function to get paths ---
function get_paths( path::String = pwd() )
    
    local aux_path::String
    local path_case::String
    
    try
        aux_path = readlines( joinpath( path , "path.dat" ) )[2][27:end]
    catch
        Base.print("  ERROR: File not found (path.dat)")
        exit()
    end
    
    if is_windows()
        path_case  = normpath( string( aux_path, "\\") ) ;
    else    
        path_case  = normpath( string( aux_path, "/") );
    end

    if isdir( path_case ) == false
        Base.print("  ERROR: Directory doesnt exist $(path_case)")
        exit()
    end

    return path_case
end

#--- convert_files: Function to convert SDDP CSV outputs to binary files
function convert_files( path::String , files_name::Array{String} )
    
    local i::String

    for i in files_name
        if !( isfile( joinpath( path , string( i , ".bin" ) ) ) )
            w_Log( string("     " , i ) , path )
            csv2bin( path , i )
        end
    end

    return nothing
end

#--- check_files: Function to check if all required files are in path ---
function check_files( path::String )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local files_name::Array{String , 1}     # Name of possible files to be converted
    local status_duraci::Int                # Flag indicating the existence of duraci file
    local status_cmgdem::Int                # Flag indicating the existence of cmgdem file
    local status_cmgdemsm::Int              # Flag indicating the existence of cmgdemsm file

    files_name      = Array{String,1}( 0 )
    status_duraci   = 0
    status_cmgdem   = 0
    status_cmgdemsm = 0
    
    #- Checking existence of sddp.dat
    if !( isfile( joinpath( path , "sddp.dat" ) ) )
        w_Log( "  ERROR: SDDP control file not found (sddp.dat) " , path )
        exit()
    end

    #- Checking existence of limites_pld.dat
    if !( isfile( joinpath( path , "limites_pld.dat" ) ) )
        w_Log( "  WARNING: Execution halted. File with PLD limits not found (limites_pld.dat) \n" , path )
        exit()
    end

    #- Checking existence of duraci
    if isfile( joinpath( path , "duraci.bin" ) )
        # do nothing
    elseif isfile( joinpath( path , "duraci.csv" ) )
        push!( files_name , "duraci" )
    else
        w_Log( "  WARNING: Summary files will not be generated. File with block duration not found (duraci) \n" , path )
        status_duraci = -1
    end

    #- Checking existence of cmgdem
    if isfile( joinpath( path , "cmgdem.bin" ) )
        # do nothing
    elseif isfile( joinpath( path , "cmgdem.csv" ) )
        push!( files_name , "cmgdem" )
    else
        w_Log( "  WARNING: PLD of physical simulation  will not be generated. Demand marginal cost file not found (cmgdem) \n" , path )
        status_cmgdem = -1
    end

    #- Checking existence of cmgdemsm
    if isfile( joinpath( path , "cmgdemsm.bin" ) )
        # do nothing
    elseif isfile( joinpath( path , "cmgdemsm.csv" ) )
        push!( files_name , "cmgdemsm" )
    else
        w_Log( "  WARNING: PLD of commercial simulation will not be generated. Demand marginal cost file not found (cmgdemsm) \n" , path )
        status_cmgdemsm = -1
    end

    #- Checking existence of cmgdem and cmgdemsm
    if ( status_cmgdem == -1 ) & (status_cmgdemsm == -1 )
        w_Log( "\n  WARNING: Demand marginal cost files of physical and commercial cases not found (cmgdem and cmgdemsm) \n  Execution halted !!" , path )
        exit()
    end

    #- Checking if convertion is required

    if length( files_name ) != 0
        w_Log( "  Converting CSV to BIN" , path )
        time_counter = @elapsed convert_files( path , files_name )
        w_Log( "\n  File conversion took $(round(time_counter,3)) seconds \n" , path )
    end
    
    return ( status_duraci , status_cmgdem , status_cmgdemsm )
end

#--- set_header_config: Function to set header options according to the PSR Graph model ---
function set_header_config( graph::Graph , sequential::Bool )

    PSRIOGrafResultBase_setInitialStage(    graph.Ptr , graph.IniStg   );
    PSRIOGrafResultBase_setInitialYear(     graph.Ptr , graph.IniYear  );
    PSRIOGrafResultBase_setTotalSeries(     graph.Ptr , graph.nScen    );
    PSRIOGrafResultBase_setTotalBlocks(     graph.Ptr , graph.nBlcs    );
    PSRIOGrafResultBase_setStageType(       graph.Ptr , graph.StgType  );
    PSRIOGrafResultBase_setVariableBySerie( graph.Ptr , graph.FlagScen );
    PSRIOGrafResultBase_setVariableByBlock( graph.Ptr , graph.FlagBlc  );
    PSRIOGrafResultBase_setUnit(            graph.Ptr , graph.Unit2    );
    PSRIOGrafResultBase_setSequencialModel( graph.Ptr , sequential     );

    return nothing
end

#--- get_header_config: Function to read header options according to the PSR Graph model ---
function get_header_config( graph::Graph )

    local ini_stg::Int
    local ini_year::Int
    local n_stgs::Int
    local n_scen::Int
    local n_blocks::Int
    local unit2::String
    local flag_blc::Int
    local flag_scen::Int
    local stg_type::Int
    
    
    ini_stg   = PSRIOGrafResultBase_getInitialStage(    graph.Ptr )
    ini_year  = PSRIOGrafResultBase_getInitialYear(     graph.Ptr )
    n_stgs    = PSRIOGrafResultBase_getTotalStages(     graph.Ptr )
    n_scen    = PSRIOGrafResultBase_getTotalSeries(     graph.Ptr )
    n_blocks  = PSRIOGrafResultBase_getTotalBlocks(     graph.Ptr )
    unit2     = PSRIOGrafResultBase_getUnit(            graph.Ptr )
    stg_type  = PSRIOGrafResultBase_getStageType(       graph.Ptr )
    flag_blc  = PSRIOGrafResultBase_getVariableByBlock( graph.Ptr )
    flag_scen = PSRIOGrafResultBase_getVariableBySerie( graph.Ptr )
    
    return ( ini_stg , ini_year , n_stgs , n_scen , n_blocks , unit2 , stg_type , flag_scen , flag_blc )
end
#--- graph_create_pointer_save: Function to create graph pointer ---
function graph_create_pointer_load( file_path::String , file_name::String )
    if isfile( joinpath( file_path , string( file_name , ".bin" ) ) ) & isfile( joinpath( file_path , string( file_name , ".hdr" ) ) )
        return ( PSRIOGrafResultBinary_create(0) , 2 );
    elseif isfile( joinpath( file_path , string( file_name , ".csv" ) ) )
        return ( PSRIOGrafResult_create(0) , 1 );
    else
        w_Log("\n  ERROR: File not found $(file_name). Execution halted" , file_path )
        exit()
    end
end

#--- graph_create_pointer_save: Function to create graph pointer ---
function graph_create_pointer_save( graph::Graph )
    if graph.Ext == 1
        return PSRIOGrafResult_create(0);
    elseif graph.Ext == 2
        return PSRIOGrafResultBinary_create(0);
    else
        error( "Invalid IO option" )
    end
end

#--- graph_init_load: Function to load graphs
function graph_init_load( graph::Graph , file_path::String , file_name::String )
    if graph.Ext == 2
        PSRIOGrafResultBinary_initLoad( graph.Ptr , joinpath( file_path , string( file_name ,".hdr" ) ) , joinpath( file_path , string( file_name ,".bin" ) ) );
    elseif graph.Ext == 1
        PSRIOGrafResult_initLoad( graph.Ptr , joinpath( file_path , string( file_name , ".csv" ) ) , PSRIO_GRAF_FORMAT_DEFAULT )
    else
        w_Log("  ERROR: File not found $(file_name)" , file_path , 0 )
        error("File not found $(file_name)")
    end
end

#--- graph_init_save: function to save graphs
function graph_init_save( graph::Graph , file_path::String , file_name::String )
    if graph.Ext == 1
        PSRIOGrafResult_initSave( graph.Ptr , joinpath( file_path , string( file_name , ".csv" ) ) , PSRIO_GRAF_FORMAT_DEFAULT )
    elseif graph.Ext == 2
        PSRIOGrafResultBinary_initSave( graph.Ptr , joinpath( file_path , string( file_name ,".hdr" ) ) , joinpath( file_path , string( file_name ,".bin" ) ) );
    else
        error( "Invalid IO option" )
    end
end

#--- graph_close: function to initilize all kind of graphs
function graph_close( graph::Graph , flag_close::Int )
    
    if flag_close == 1
        PSRIOGrafResult_closeSave( graph.Ptr )
    elseif flag_close == 2
        PSRIOGrafResult_closeLoad( graph.Ptr )
    else
        error( "Invalid flag option" )
    end
    
    return nothing
end

#--- initpsrc: Function to load DLL ---
function initpsrc(path_psrc::String)
    Libdl.dlopen( joinpath(path_psrc,"PSRClasses") )
    return nothing
end

#--- initClasses: Function to initialize PSRClasses ---
function initClasses(path::String)
    
    path = normpath(path)

    #- Configuring Log Manager
    ilog = PSRManagerLog_getInstance(0);
    PSRManagerLog_initPortuguese(ilog);
    ilogcons = PSRLogSimpleConsole_create(0);
    PSRManagerLog_addLog(ilog, ilogcons);

    #- Configuring the Mask and Models Manager
    igmsk = PSRManagerIOMask_getInstance(0);
    iret  = PSRManagerIOMask_importFile(igmsk, joinpath(path,"Masks_SDDP_V10.2.pmk"));
    iret  = PSRManagerIOMask_importFile(igmsk, joinpath(path,"Masks_SDDP_V10.3.pmk"));
    iret  = PSRManagerIOMask_importFile(igmsk, joinpath(path,"Masks_SDDP_Blocks.pmk"));
    igmdl = PSRManagerModels_getInstance(0);
    iret  = PSRManagerModels_importFile(igmdl, joinpath(path,"Models_SDDP_V10.2.pmd"));
    iret  = PSRManagerModels_importFile(igmdl, joinpath(path,"Models_SDDP_V10.3.pmd"));
    iret  = PSRManagerModels_importFile(igmdl, joinpath(path,"Models_SDDP_Keywords.pmd"));

    return nothing;
end

#       ------------------------------------------------
#              Defining functions to read database 
#       ------------------------------------------------

#--- read_sddp_config: Function to read SDDP configuration ---
function read_sddp_config( path::String )

    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to sddp.dat files
    local iodata::Array{String,1}           # Local variable to buffer information from read sddp.dat files
    
    local sddp::Case                        # Local variable to buffer main informations

    #-------------------------------
    #--- Reading file (sddp.dat) ---
    #-------------------------------

    iofile = open( joinpath( path , "sddp.dat" ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    sddp          = Case()
    sddp.IniStg   = string_converter( iodata[13][27:30] , Int , "Invalid entry for sddp initial stage" )
    sddp.IniYear  = string_converter( iodata[14][27:30] , Int , "Invalid entry for sddp initial year" )
    sddp.nStgs    = string_converter( iodata[15][27:30] , Int , "Invalid entry for sddp number of stages" )
    sddp.nSyst    = string_converter( iodata[18][27:30] , Int , "Invalid entry for sddp number of systems" )
    sddp.nScen    = string_converter( iodata[19][27:30] , Int , "Invalid entry for sddp number of scenarios" )
    sddp.nBlcs    = string_converter( iodata[21][27:30] , Int , "Invalid entry for sddp number of blocks" )
    sddp.addYears = string_converter( iodata[22][27:30] , Int , "Invalid entry for sddp aditional years" )

    #----------------------------------
    #--- Checking data consistency  ---
    #----------------------------------

    if ( sddp.IniStg < 1 ) | ( sddp.IniStg > 12 )
        w_Log( "  ERROR: Initial stage must be between 1 and 12")
        exit()
    end

    if ( sddp.IniYear < 1 ) 
        w_Log( "  ERROR: Initial year must be grater than 1")
        exit()
    end

    if ( sddp.nStgs < 1 ) 
        w_Log( "  ERROR: The number of stages must be at least 1")
        exit()
    end

    if ( sddp.nSyst < 1 ) 
        w_Log( "  ERROR: The number of systems must be at least 1")
        exit()
    end

    if ( sddp.nScen < 1 ) 
        w_Log( "  ERROR: The number of scenarios must be at least 1")
        exit()
    end

    if ( sddp.nBlcs < 1 ) 
        w_Log( "  ERROR: The number of blocks must be at least 1")
        exit()
    end

    if ( sddp.addYears < 0 ) 
        w_Log( "  ERROR: The number of blocks must be at least 0")
        exit()
    end
    
    return sddp
end

#--- read_pld_limits: Function to read PLD limits ---
function read_pld_limits( path::String , stdy::Case )
    
    #---------------------------
    #---  Defining variables ---
    #---------------------------

    local iofile::IOStream                  # Local variable to buffer connection to sddp.dat files
    local iodata::Array{String,1}           # Local variable to buffer information from read sddp.dat files
    local i::Int                            # Local variable to loop over limits periods
    local stg::Int                          # Local variable to loop over stages
    
    local usr_io_opt::Int                   # Local variable to buffer user output file extension (  0 -> BIN  |  1 -> CSV  )
    local pld_limits::Array{Float64}        # Local variable to buffer read pld limits

    local limits_n_periods::Int             # Local variable to buffer number of limits periods
    local limits_dates::Array{Date}         # Local variable to buffer limits periods
    local limits_values::Array{Float64}     # Local variable to buffer limits values

    local aux_ini_date::Date                # Auxiliar variable to buffer read dates
    local aux_fin_date::Date                # Auxiliar variable to buffer read dates
    local aux_stg::Date                     # Auxiliar variable
    local aux_limits::Array{Float64}        # Auxiliar variable
    

    #-------------------------------
    #--- Reading file (sddp.dat) ---
    #-------------------------------

    iofile = open( joinpath( path , "limites_pld.dat" ) , "r" )
    iodata = readlines( iofile );
    Base.close( iofile )

    #-----------------------
    #--- Assigning data  ---
    #-----------------------

    usr_io_opt  = string_converter( iodata[1][27:30] , Int , "Invalid entry for the output extension type")

    if ( usr_io_opt != 1 ) & ( usr_io_opt != 2 )
        w_Log( "  ERROR: Invalid value for output $(usr_io_opt). Value must be 0 or 1 (limites_pld.dat) " , path )
        exit()
    end
    
    if ( length( iodata ) - 3 < 1 )
        w_Log( "  ERROR: Invalid file format (limites_pld.dat) " , path )
        exit()
    else
        limits_n_periods = length( iodata ) - 3
    end

    limits_dates     = Array{Date}( limits_n_periods , 2 )
    limits_values    = Array{Float64}( limits_n_periods , 2 )

    for i in 1:limits_n_periods
        
        aux_ini_date = Date( strip( iodata[i+3][1:8]  ) , Dates.DateFormat("m/y") )
        aux_fin_date = Date( strip( iodata[i+3][9:16] ) , Dates.DateFormat("m/y") )
        

        if i == 1
            if aux_ini_date > Date( stdy.IniYear , stdy.IniStg , 1)
                w_Log( "  ERROR: First PLD limit stage is later than study begins" , path )
                #error()
            end

            if Dates.year( aux_ini_date ) < stdy.IniYear
                w_Log( "  ERROR: First year of PLD limit must be the same as the study initial year" , path )
                #error()
            end
        else
            if aux_ini_date <= limits_dates[( i - 1) , 2]
                w_Log("  ERROR: There is an overlap between PLD limits dates    Line: $(i+3) (limites_pld.dat)" , path )
                #error()
            end
        end

        if i == limits_n_periods
            if aux_fin_date < Date( stdy.IniYear , stdy.IniStg , 1) + Dates.Month( stdy.nStgs - 1 )
                w_Log( "  ERROR: Last PLD limit stage is earlier than study ends" , path )
                #error()
            end

            if Dates.year( aux_fin_date ) > Dates.year( Date( stdy.IniYear , stdy.IniStg , 1) + Dates.Month( stdy.nStgs - 1 ) + Dates.Year( stdy.addYears ) )
                w_Log( "  ERROR: Last year of PLD limit must be the same as the study last year plus additional years" , path )
                #error()
            end
        end

        limits_dates[i,1] = aux_ini_date
        limits_dates[i,2] = aux_fin_date
        limits_values[i,1] = string_converter( iodata[i+3][22:28] ,  Float64 , "Invalid entry for the minimum pld limit    Line: $(i+3) (limites_pld.dat)")
        limits_values[i,2] = string_converter( iodata[i+3][34:40] ,  Float64 , "Invalid entry for the maximum pld limit    Line: $(i+3) (limites_pld.dat)")
    end
    

    #- Assigning limits to each stage
    
    pld_limits = Array{Float64}( stdy.nStgs , 2 )

    for stg in 1:stdy.nStgs
        aux_limits = [-1.0 -1.0]
        aux_stg    = Date( stdy.IniYear , stdy.IniStg , 1) + Dates.Month(stg - 1)

        for i in 1:limits_n_periods
            if ( limits_dates[ i , 1 ] <= aux_stg ) & ( aux_stg <= limits_dates[ i , 2 ] )
                aux_limits = limits_values[ i , : ]
                break
            end
        end

        if aux_limits == [-1.0 -1.0]
            w_Log( "  ERROR: PLD limit for this stage not found $(stg) " , path )
            exit()
        else
            pld_limits[ stg , : ] = aux_limits
        end   
    end
    
    return ( pld_limits ,  usr_io_opt );
end

#--- readDataBase: Main function to read all required data ---
function read_data_base( path::String )

    #---- Loading SDDP configuration ----
    w_Log("     SDDP configuration", path );
    SDDP = read_sddp_config( path )
    
    #---- Loading TSB configuration ----
    w_Log("     TSB configuration", path );
    PLD_LIMITS , usrOptIO =  read_pld_limits( path , SDDP )
      
    return ( SDDP , PLD_LIMITS , usrOptIO );
end

#       ----------------------------------------------------
#              Defining functions to apply PLD limits       
#       ----------------------------------------------------

#--- apply_limits: Function to apply the regulatory cap and floor to the CMO ---
function apply_limits( self::Float64 , inf_limit::Float64 , sup_limit::Float64 )

    local pld::Float64

    if self < inf_limit
        pld = inf_limit
    elseif self > sup_limit
        pld = sup_limit
    else
        pld = self
    end

    return pld
end

#--- calculate_pld_scenario: Function to calculate PLD in each scenario 
function calculate_pld_scenario( ptr_cmgdem::Ptr{UInt8} , ptr_preco::Ptr{UInt8} , stdy::Case , pld_limits::Array{Float64} , scenario::Int )

    local stg::Int
    local blc::Int
    local syst::Int
    local cmo::Float64
    local pld::Float64
    local nBlcs_stg::Int

    PSRIOGrafResultBase_setCurrentSerie( ptr_preco , scenario );

    for stg in 1:stdy.nStgs
        
        PSRIOGrafResult_seekStage2( ptr_cmgdem , stg , scenario , 1 );
        nBlcs_stg = PSRIOGrafResultBase_getTotalBlocks2( ptr_cmgdem , stg)
        
        PSRIOGrafResultBase_setCurrentStage( ptr_preco , stg );
        
        for blc in 1:nBlcs_stg

            PSRIOGrafResultBase_setCurrentBlock( ptr_preco , blc );

            for syst in 1:stdy.nSyst

                cmo = PSRIOGrafResultBase_getData( ptr_cmgdem , syst - 1 )
                
                pld = apply_limits( cmo , pld_limits[ stg , 1 ] , pld_limits[ stg , 2 ] )

                PSRIOGrafResultBase_setData( ptr_preco , syst - 1 , pld )

            end

            PSRIOGrafResultBase_writeRegistry( ptr_preco )

            PSRIOGrafResult_nextRegistry( ptr_cmgdem , false )

        end
    end

    return nothing
end

#--- calculate_pld: Function to calculate PLD for all stages, scenarios and block
function calculate_pld( path::String , input_file_name::String , output_file_name::String , stdy::Case , pld_limits::Array{Float64} , usr_io_opt::Int)

    local input_file::Graph
    local output_file::Graph
    
    local agent_name::String
    local scen::Int

    #-----------------------------------------
    #--- Configuring input file parameters ---
    #-----------------------------------------

    input_file = Graph()

    #- Creating pointer to file
    input_file.Ptr , input_file.Ext = graph_create_pointer_load( path , input_file_name )

    #- Loading file
    graph_init_load( input_file , path , input_file_name )

    #- Getting header information from original file
    input_file.IniStg , input_file.IniYear , input_file.nStgs , input_file.nScen , input_file.nBlcs , input_file.Unit2 , input_file.StgType , input_file.FlagScen , input_file.FlagBlc = get_header_config( input_file )
    
    #------------------------------------------
    #--- Configuring output file parameters ---
    #------------------------------------------

    output_file          = Graph()
    output_file.Ext      = usr_io_opt
    output_file.IniStg   = input_file.IniStg
    output_file.IniYear  = input_file.IniYear
    output_file.nStgs    = input_file.nStgs
    output_file.nScen    = input_file.nScen
    output_file.nBlcs    = input_file.nBlcs
    output_file.Unit2    = input_file.Unit2
    output_file.StgType  = input_file.StgType
    output_file.FlagBlc  = input_file.FlagBlc
    output_file.FlagScen = input_file.FlagScen

    #- Creating pointer to output files
    output_file.Ptr = graph_create_pointer_save( output_file )
    
    #- Setting header configuration
    
    set_header_config( output_file , false )
    
    #- Adding agents
    for syst in 1:stdy.nSyst
        agent_name = PSRIOGrafResultBase_getAgent( input_file.Ptr , syst - 1 )
        PSRIOGrafResultBase_addAgent( output_file.Ptr , agent_name )
    end
    
    #- Creating output files
    graph_init_save( output_file , path , output_file_name )
    
    for scen in 1:stdy.nScen
        calculate_pld_scenario( input_file.Ptr , output_file.Ptr , stdy , pld_limits , scen )
    end

    graph_close( input_file  , 2 )
    graph_close( output_file , 1 )

    return nothing
end


#       ----------------------------------------------------
#                           Main function
#       ----------------------------------------------------

function main( PATH_SRC::String , PATH_PSRCLASSES::String )

    #------------------------------------
    #----     Defining constants     ----
    #------------------------------------

    local PATH_CASE::String
    local SDDP::Case
    local PLD_LIMITS::Array{Float64}
    local usrOptIO::Int
    local time_counter::Float64
    local status_duraci::Int 
    local status_cmgdem::Int
    local status_cmgdemsm::Int

    #- Getting paths
    PATH_CASE = get_paths( PATH_SRC );

    #-------------------------------------
    #----     Initializing Module     ----
    #-------------------------------------

    #--- Remove preveous log file ---
    if isfile( joinpath( PATH_CASE , "cmgdem_pld.log" ) )
        rm( joinpath( PATH_CASE , "cmgdem_pld.log" ) )
    else
        w_Log( "" , PATH_CASE , 0 , 1 , "cmgdem_pld.log" , "w" )
    end

    w_Log( "\n  #-----------------------------------------#"            , PATH_CASE );
    w_Log( "  #               CMGDEM 2 PLD              #"              , PATH_CASE );
    w_Log( "  #-----------------------------------------#\n"            , PATH_CASE );
    w_Log( "  Execution date: $(Dates.format(now(),"dd-u-yyyy HH:MM"))" , PATH_CASE );
    w_Log( "  Directory: $PATH_CASE \n"                                 , PATH_CASE );

    #--- Checking if files are in the directory ---
    status_duraci , status_cmgdem , status_cmgdemsm = check_files( PATH_CASE )

    #-----------------------------------------
    #----     Initializing PSRClasses     ----
    #-----------------------------------------

    #- Comentario: comentei aqui para testar o modulo com as bibliotecas
    #initpsrc(PATH_PSRCLASSES);
    initClasses(PATH_PSRCLASSES);
    
    w_Log("  PSRClasses - Ok \n" , PATH_CASE , 0 );

    #--------------------------------
    #----     Loading inputs     ----
    #--------------------------------

    w_Log( "  Loading inputs" , PATH_CASE );

    time_counter = @elapsed ( SDDP , PLD_LIMITS , usrOptIO ) = read_data_base( PATH_CASE );
    
    w_Log( "\n  Loading data took $(round(time_counter,3)) seconds" , PATH_CASE );

    #-----------------------------------------------
    #----     Applying cap and floor on OMC     ----
    #-----------------------------------------------
    
    if status_cmgdem == 0 
        w_Log("\n  Applying limits on demand marginal cost (SF)", PATH_CASE );

        time_counter = @elapsed calculate_pld( PATH_CASE , "cmgdem" , "preco" , SDDP , PLD_LIMITS , usrOptIO )
        
        w_Log("  Applying limits on demand marginal cost (SF) took $(round(time_counter,3)) seconds", PATH_CASE);
    end

    if status_cmgdemsm == 0
        w_Log("\n  Applying limits on demand marginal cost (SC)", PATH_CASE );

        time_counter = @elapsed calculate_pld( PATH_CASE , "cmgdemsm" , "precosm" , SDDP , PLD_LIMITS , usrOptIO )
        
        w_Log("  Applying limits on demand marginal cost (SC) took $(round(time_counter,3)) seconds", PATH_CASE);
    end
    
    #----------------------------
    #----     Finishing      ----
    #----------------------------

    w_Log("\n  Successfully finished!", PATH_CASE);

    return nothing
end
