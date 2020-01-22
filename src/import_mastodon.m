function [ G, metadata, tss ] = import_mastodon( source_file )

    % Uncompress data file into temp dir.
    filenames = unzip( source_file, fullfile( tempdir, source_file ) );
    
    %% Read the metadata from master file.
    
    % Find the uncompressed master XML file -> project.xml.
    mastodon_master_file = get_master_file( filenames );
    % Import it.
    metadata = import_mastodon_metadata( mastodon_master_file );
    
    % Deal with relative path -> make it absolute.
    if strcmp( metadata.spim_data_file_path_type, 'relative' )

        % Path to the source file folder.
        io_file = java.io.File( source_file );
        if ~io_file.isAbsolute()            
            full_path = fullfile( pwd, source_file );
        else
            full_path = source_file;
        end
        file_path = fileparts( full_path );
        
        % Remove the first "../" because we are relative to the folder
        % where the Mastodon file is already.
        pruned_file_path = metadata.spim_data_file_path(4 : end );
        
        % Simplify path.
        full_path = java.io.File( fullfile( ...
            file_path, ...
            pruned_file_path ) );
        full_path_trimmed = char( full_path.getCanonicalPath() );
        
        metadata.spim_data_file_path = full_path_trimmed;
        metadata.spim_data_file_path_type = 'absolute';            
    end
    
    %% Read the model file.
    
    % Find the uncompressed file for the graph -> model.raw.
    mastodon_model_file = get_model_file( filenames );
    % Deserialize it.
    [ spot_table, link_table ] = import_mastodon_graph( mastodon_model_file );

    % Fix the variable units.
    % Spot position.
    spot_table.Properties.VariableUnits( 2:4 ) = { metadata.space_units };
    % Spot time, which is always 'frame' units.
    spot_table.Properties.VariableUnits( 5 ) = { metadata.time_units };
    % Covariance matrix.
    spot_table.Properties.VariableUnits( 6:12 ) = { sprintf( '%s^2', metadata.space_units ) };

    
    %% Read the tag file.
    
    % Find the uncompressed file for the tags -> tags.raw.
    mastodon_tag_file = get_tag_file( filenames );
    % Deserialize it.
    [ spot_table, link_table, tss ]  = import_mastodon_tags( mastodon_tag_file, spot_table, link_table );
    
    %% Read feature files.
    
    % Find the collection of feature raw files.
    mastodon_feature_files = get_feature_files( filenames );
    % Read them and append them to the model tables.
    [ spot_table, link_table ] = import_mastodon_features( mastodon_feature_files, spot_table, link_table );
    
    
    %% Assemble graph.
    
    G = digraph( link_table, spot_table );
    
    % Finished!
    
    
    
    %% Functions.
        
    function master_file = get_master_file( filenames )
        id = find( ~cellfun( @isempty, regexp( filenames, '.*project.xml$') ) );
        if isempty( id )
            error( 'MastodonImporter:missingMasterFile', ...
                'Could not find master file in Mastodon file.' )
        end
            
        master_file = filenames{ id };
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