function [ spot_table, link_table ] = import_mastodon_features( mastodon_feature_files, spot_table, link_table )
%IMPORT_MASTODON_FEATURES Import the known mastodon features.
    
    n_feature_files = numel( mastodon_feature_files );
    for i = 1 : n_feature_files
        
        mastodon_feature_file = mastodon_feature_files{ i };
        [ ~, feature_name, ~ ] = fileparts( mastodon_feature_file );
        
        switch ( feature_name )
            
            case { 'Update stack Link', 'Update stack Spot' }
                % Do not import.
                continue
                
            case 'Spot radius'
                projections = import_spot_radius_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            case 'Detection quality'
                projections = import_feature_scalar_double( mastodon_feature_file );
                add_to = 'Spot';
                    
            case 'Link cost'
                projections = import_feature_scalar_double( mastodon_feature_file );
                add_to = 'Link';
                
            case 'Link displacement'
                projs = import_lazy_feature( mastodon_feature_file, ...
                    { [ 'The link displacement in physical units ' ...
                        'as the distance between the source spot and the target spot.' ] } );
                projections = projs{ 1 };
                add_to = 'Link';
                
            case 'Link velocity' 
                projs = import_lazy_feature( mastodon_feature_file, ...
                    { [ 'The link velocity as the distance between the ' ...
                        'source and target spots divided by their frame difference. ' ...
                        'Units are in physical distance per frame.' ] } );
                projections = projs{ 1 };
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
                
            case 'Spot intensity'
                projections = import_spot_intensity_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            case 'Spot center intensity'
                projections = import_spot_center_intensity_feature( mastodon_feature_file );
                add_to = 'Spot';

            case 'Spot quick mean'
                projections = import_spot_quick_mean_feature( mastodon_feature_file );
                add_to = 'Spot';
                
            otherwise 
                warning( 'import_mastodon:UnkownFeature', ...
                    'Do not know how to import feature "%s".', feature_name )
                continue

        end
        
        switch ( add_to )
            
            case 'Spot'
                n_projections = numel( projections );
                for iproj = 1 : n_projections
                    spot_table = add_projection_to_table( spot_table, projections( iproj ) );
                end
                
            case 'Link'
                n_projections = numel( projections );
                for iproj = 1 : n_projections
                    link_table = add_projection_to_table( link_table, projections( iproj ) );
                end
                
            otherwise
                error( 'import_mastodon:UnkownFeatureTarget', ...
                    'Unknown feature target "%s".', add_to )

        end
        
    end
    
    %% Sub-functions.
    
    
    function projections = import_lazy_feature( mastodon_feature_file, infos )
    %% IMPORT_LAZY_FEATURE Import the features serialized by the lazy feature serializer
    % See https://github.com/mastodon-sc/mastodon/blob/dev/src/main/java/org/mastodon/feature/io/LazyFeatureSerializer.java
        reader = JavaRawReader( mastodon_feature_file );
        n_entries       = reader.read_int();        
        n_projs         = reader.read_int(); 
        projections = cell( n_projs, 1 );        
        for j = 1 : n_projs
            projection.key         = reader.read_utf8();
            projection.dimension   = reader.read_utf8();
            projection.units       = reader.read_utf8();
            projection.info        = infos{ j };
            projection.map         = import_double_map( reader, n_entries );
            projections{ j } = projection;
        end
                
        reader.close()
    end
    
    function T = add_projection_to_table( T, projection )
        
        col = NaN( height( T ), 1 );
        [ ~, idx ] = ismember( projection.map( : ,1 ), T.id );
        col( idx ) = projection.map( :, 2 );
        T.( matlab.lang.makeValidName( projection.key ) ) = col;
        
        T.Properties.VariableUnits{ width( T ) }        = projection.units;
        T.Properties.VariableDescriptions{ width( T ) } = projection.info;
    end

    function projection = import_spot_radius_feature( mastodon_feature_file )
        
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Spot radius';
        projection.info        = 'The spot equivalent radius. This is the radius of the sphere that would have the same volume that of the spot.';
        projection.dimension   = 'LENGTH';
        projection.units       = reader.read_utf8();
        if isempty( projection.units )
            projection.units = '';
        end
        projection.map = import_double_map( reader );
        reader.close()
    end

    function projections = import_spot_sum_intensity_feature( mastodon_feature_file )
        info = [ 'The total intensity inside a spot, ' ...
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
        info = [ 'The median intensity inside a spot, ' ...
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
        info = [ 'The average intensity and its standard deviation inside spots over all ' ...
            'sources of the dataset. The average is calculated by a weighted mean over the pixels ' ...
            'of the spot, weighted by a gaussian centered in the spot and with a sigma value equal ' ...
            'to the minimal radius of the ellipsoid divided by 2.' ];
        reader = JavaRawReader( mastodon_feature_file );
        n_sources = reader.read_int();
        for ch = 1 : n_sources
            
            % Mean.
            projection.key         = sprintf( 'Spot gaussian filtered intensity Mean ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 2 * ch - 1 ) = projection; %#ok<AGROW>
            
            % Std.
            projection.key         = sprintf( 'Spot gaussian filtered intensity Std ch%d', ch );
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
        projection.info        = 'The number of spots in a track.';
        projection.dimension   = 'NONE';
        projection.units       = '';
        projection.map         = import_int_map( reader );
        reader.close()
    end
    
    function projection = import_spot_track_id_feature( mastodon_feature_file )        
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Spot track ID';
        projection.info        = 'The ID of the track each spot belongs to.';
        projection.dimension   = 'NONE';
        projection.units       = '';
        projection.map         = import_int_map( reader );
        reader.close()
    end
   
    function projection = import_spot_n_links_feature( mastodon_feature_file )        
        reader = JavaRawReader( mastodon_feature_file );
        projection.key         = 'Spot N links';
        projection.info        = 'The number of links that touch a spot.';
        projection.dimension   = 'NONE';
        projection.units       = '';
        projection.map         = import_int_map( reader );
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

function projections = import_spot_intensity_feature( mastodon_feature_file )
        info = [ 'Spot intensity features like mean, median, etc for all the channels of the source image. ' ...
            'All the pixels within the spot ellipsoid are taken into account' ];
        reader = JavaRawReader( mastodon_feature_file );
        n_sources = reader.read_int();
        for ch = 1 : n_sources
            
            % Mean.
            projection.key         = sprintf( 'Spot intensity Mean ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 6 * ch - 5 ) = projection; %#ok<AGROW>
            
            % Std.
            projection.key         = sprintf( 'Spot intensity Std ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 6 * ch - 4 ) = projection; %#ok<AGROW>

            % Min.
            projection.key         = sprintf( 'Spot intensity Min ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 6 * ch - 3 ) = projection; %#ok<AGROW>

            % Max.
            projection.key         = sprintf( 'Spot intensity Max ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 6 * ch - 2 ) = projection; %#ok<AGROW>

            % Medians.
            projection.key         = sprintf( 'Spot intensity Median ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 6 * ch - 1 ) = projection; %#ok<AGROW>

            % Sums.
            projection.key         = sprintf( 'Spot intensity Sum ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( 6 * ch ) = projection; %#ok<AGROW>

        end
        reader.close()
    end

    function projections = import_spot_center_intensity_feature( mastodon_feature_file )
        info = [ 'Computes the intensity at the center of spots by taking the mean of pixel intensity ' ...
            'weigthted by a gaussian. The gaussian weights are centered int the spot, ' ...
            'and have a sigma value equal to the minimal radius of the ellipsoid divided by 2.' ];
        reader = JavaRawReader( mastodon_feature_file );
        n_sources               = reader.read_int();
        for ch = 1 : n_sources
            projection.key         = sprintf( 'Spot center intensity ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( ch ) = projection; %#ok<AGROW>
        end
        reader.close()
    end

    function projections = import_spot_quick_mean_feature( mastodon_feature_file )
        info = [ 'Computes the mean intensity of spots using the highest resolution level to speedup calculation. ' ...
					'It is recommended to use the "Spot intensity" feature when the best accuracy is required.' ];
        reader = JavaRawReader( mastodon_feature_file );
        n_sources               = reader.read_int();
        for ch = 1 : n_sources
            projection.key         = sprintf( 'Spot center intensity ch%d', ch );
            projection.info        = info;
            projection.dimension   = 'INTENSITY';
            projection.units       = 'Counts';
            projection.map         = import_double_map( reader );
            projections( ch ) = projection; %#ok<AGROW>
        end
        reader.close()
    end

    function map = import_double_map( reader, n_entries )
        if nargin < 2
            n_entries   = reader.read_int();
        end
        map = NaN( n_entries, 2 );
        for proj = 1 : n_entries
            map( proj , 1 ) = reader.read_int();
            map( proj , 2 ) = reader.read_double_rev();
        end
        
    end


    function map = import_int_map( reader, n_entries )
        if nargin < 2
            n_entries   = reader.read_int();
        end
        map = NaN( n_entries, 2 );
        for proj = 1 : n_entries
            map( proj , 1 ) = reader.read_int();
            map( proj , 2 ) = reader.read_int();
        end
        
    end

end

