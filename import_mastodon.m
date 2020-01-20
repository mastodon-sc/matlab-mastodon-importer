function [ G, tss ] = import_mastodon( source_file )

    % Uncompress data file into temp dir.
    filenames = unzip( source_file, fullfile( tempdir, source_file ) );
    
    %% Read the model file.
    
    % Find the uncompressed file for the graph -> model.raw.
    mastodon_model_file = get_model_file( filenames );
    % Deserialize it.
    G = import_mastodon_graph( mastodon_model_file );
    
    %% Read the tag file.
    
    % Find the uncompressed file for the tags -> tags.raw.
    mastodon_tag_file = get_tag_file( filenames );
    % Deserialize it.
   [ tag_table_vertices, tag_table_edges, tss ]  = import_mastodon_tags( mastodon_tag_file );
   
   % Merge model table and tag table.
   n_tag_set = numel( tss );
   
   for i = 1 : n_tag_set
       
       tag_set_name = tss( i ).name;
       
       col = categorical();
       col( numnodes( G ), 1 ) = '<undefined>';
       
       [ ~, idx ] = ismember( tag_table_vertices.id, G.Nodes.id );
       col( idx ) = tag_table_vertices.( tag_set_name );
       G.Nodes.( tag_set_name ) = col;
       
   end
   
   for i = 1 : n_tag_set
       
       tag_set_name = tss( i ).name;
       
       col = categorical();
       col( numedges( G ), 1 ) = '<undefined>';
       
       [ ~, idx ] = ismember( tag_table_edges.id, G.Nodes.id );
       col( idx ) = tag_table_edges.( tag_set_name );
       G.Edges.( tag_set_name ) = col;
       
   end
   
   %% Read feature files.
   
    mastodon_feature_files = get_feature_files( filenames );
    
    n_feature_files = numel( mastodon_feature_files );
    for i = 1 : n_feature_files
        
        mastodon_feature_file = mastodon_feature_files{ i };
        [ ~, feature_name, ~ ] = fileparts( mastodon_feature_file );
        
        switch ( feature_name )
            
            case { 'Update stack Link', 'Update stack Spot' }
                % Do not import.
                
            case 'Detection quality'
                projections = import_feature_scalar_double( mastodon_feature_file );
                add_to = 'Spot';
                    
            case 'Link cost'
                projections = import_feature_scalar_double( mastodon_feature_file );
                add_to = 'Link';
                
            case 'Link displacement'
                projections = import_link_displacement_feature( mastodon_feature_file );
                add_to = 'Link';
                
            case 'Link velocity' 
                projections = import_link_velocity_feature( mastodon_feature_file );
                add_to = 'Link';
                
            case 'Spot N links'
                projections = import_spot_n_links_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            case 'Spot track ID'
                projections = import_spot_track_id_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            case 'Track N spots'
                projections = import_track_n_spots_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            case 'Spot gaussian-filtered intensity'
                projections = import_spot_gaussian_filtered_intensity_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            case 'Spot median intensity'
                projections = import_spot_median_intensity_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            case 'Spot sum intensity'
                projections = import_spot_sum_intensity_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            otherwise 
                warning( 'import_mastodon:UnkownFeature', ...
                    'Do not know how to import feature "%s".', feature_name )

        end
        
        switch ( add_to )
            
            case 'Spot'
                n_projections = numel( projections );
                for iproj = 1 : n_projections
                    G.Nodes = add_projection_to_table( G.Nodes, projections( iproj ) );
                end
                
            case 'Link'
%                 n_projections = numel( projections );
%                 for iproj = 1 : n_projections
%                     G.Edges = add_projection_to_table( G.Edges, projections( iproj ) );
%                 end
                
            otherwise
                error( 'import_mastodon:UnkownFeatureTarget', ...
                    'Unknown feature target "%s".', add_to )

        end
        
    end
   
    
    %% Functions.
    
    function T = add_projection_to_table( T, projection )
        
        col = NaN( height( T ), 1 );
        [ ~, idx ] = ismember( projection.map( : ,1 ), T.id );
        col( idx ) = projection.map( :, 2 );
        T.( matlab.lang.makeValidName( projection.key ) ) = col;
        
        T.Properties.VariableUnits{ width( T ) }        = projection.units;
        T.Properties.VariableDescriptions{ width( T ) } = projection.info;
    end

    function projections = import_spot_sum_intensity_feature( mastodon_feature_file )
        info = [ 'Computes the total intensity inside a spot, ' ...
            'for the pixels inside the spot ellipsoid.' ];
        reader = JavaRawReader( mastodon_feature_file );
        n_sources               = reader.read_int();
        for ch = 1 : n_sources
            projections.key         = sprintf( 'Spot sum intensity ch%d', ch );
            projections.info        = info;
            projections.dimension   = 'INTENSITY';
            projections.units       = 'Counts';
            projections.map         = import_double_map( reader );
            projections( ch ) = projections; %#ok<AGROW>
        end
        reader.close()
    end

    function projections = import_spot_median_intensity_feature( mastodon_feature_file )
        info = [ 'Computes the median intensity inside a spot, ' ...
            'for the pixels inside the largest box that fits into the spot ellipsoid.' ];
        reader = JavaRawReader( mastodon_feature_file );
        n_sources               = reader.read_int();
        for ch = 1 : n_sources
            projections.key         = sprintf( 'Spot median intensity ch%d', ch );
            projections.info        = info;
            projections.dimension   = 'INTENSITY';
            projections.units       = 'Counts';
            projections.map         = import_double_map( reader );
            projections( ch ) = projections; %#ok<AGROW>
        end
        reader.close()
    end
    
    function projections = import_spot_gaussian_filtered_intensity_feature( mastodon_feature_file )
        info = [ 'Computes the average intensity and its standard deviation inside spots over all ' ...
            'sources of the dataset. The average is calculated by a weighted mean over the pixels ' ...
            'of the spot, weighted by a gaussian centered in the spot and with a sigma value equal ' ...
            'to the minimal radius of the ellipsoid divided by 2.' ];
        reader = JavaRawReader( mastodon_feature_file );
        n_sources = reader.read_int();
        for ch = 1 : n_sources
            
            % Mean.
            projection.key         = sprintf( 'Spot gaussian-filtered intensity Mean ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 2 * ch - 1 ) = projection; %#ok<AGROW>
            
            % Std.
            projection.key         = sprintf( 'Spot gaussian-filtered intensity Std ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 2 * ch ) = projection; %#ok<AGROW>
            
        end
        reader.close()
    end
    
    function projection = import_track_n_spots_feature( mastodon_feature_file )        
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Track N spots';
        projection.info        = 'Returns the number of spots in a track.';
        projection.dimension   = 'NONE';
        projection.units       = '';
        projection.map         = import_int_map( reader );
        reader.close()
    end
    
    function projection = import_spot_track_id_feature( mastodon_feature_file )        
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Spot track ID';
        projection.info        = 'Returns the ID of the track each spot belongs to.';
        projection.dimension   = 'NONE';
        projection.units       = '';
        projection.map         = import_int_map( reader );
        reader.close()
    end
   
    function projection = import_spot_n_links_feature( mastodon_feature_file )        
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Spot N links';
        projection.info        = 'Computes the number of links that touch a spot.';
        projection.dimension   = 'NONE';
        projection.units       = '';
        projection.map         = import_int_map( reader );
        reader.close()
    end
    
    function projection = import_link_displacement_feature( mastodon_feature_file )
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Link displacement';
        projection.info        = 'Computes the link displacement in physical units as the distance between the source spot and the target spot.';
        projection.dimension   = 'LENGTH';
        projection.units       = reader.read_utf8();
        projection.map         = import_double_map( reader );
        reader.close()
    end

    function projection = import_link_velocity_feature( mastodon_feature_file )
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Link velocity';
        projection.info        = 'Computes the link velocity as the distance between the source and target spots divided by their frame difference. Units are in physical distance per frame.';
        projection.dimension   = 'VELOCITY';
        projection.units       = reader.read_utf8();
        projection.map         = import_double_map( reader );
        reader.close()
    end
    
    function projection = import_feature_scalar_double( mastodon_feature_file )
        
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = reader.read_utf8();
        projection.info        = reader.read_utf8();
        projection.dimension   = reader.read_enum();
        projection.units       = reader.read_utf8();
        if isempty( projection.units )
            projection.units = '';
        end
        projection.map = import_double_map( reader );
        reader.close()
    end

    function map = import_double_map( reader )
        n_entries   = reader.read_int();
        map = NaN( n_entries, 2 );
        for proj = 1 : n_entries
            map( proj , 1 ) = reader.read_int();
            map( proj , 2 ) = reader.read_double_rev();
        end
        
    end

    function map = import_int_map( reader )
        n_entries   = reader.read_int();
        map = NaN( n_entries, 2 );
        for proj = 1 : n_entries
            map( proj , 1 ) = reader.read_int();
            map( proj , 2 ) = reader.read_int();
        end
        
    end

    function mastodon_feature_files = get_feature_files( filenames )
        
        ids = ~cellfun( @isempty, regexp( filenames, '.*/features/.*\.raw$') );
        mastodon_feature_files = filenames( ids );
    end

    function model_file = get_model_file( filenames )
        
        id = find( ~cellfun( @isempty, regexp( filenames, '.*model.raw$') ) );
        if isempty( id )
            error( 'MastodonImporter:missingModelFile', ...
                'Could not find model file in Mastodon file.' )
        end
        
        model_file = filenames{ id };
    end

    function tag_file = get_tag_file( filenames )
        
        id = find( ~cellfun( @isempty, regexp( filenames, '.*tags.raw$') ) );
        if isempty( id )
            error( 'MastodonImporter:missingTagFile', ...
                'Could not find tag file in Mastodon file.' )
        end
        
        tag_file = filenames{ id };
    end

end