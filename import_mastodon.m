function [ G, tss ] = import_mastodon( source_file )

    % Uncompress data file into temp dir.
    filenames = unzip( source_file, fullfile( tempdir, source_file ) );
    
    %% Read the model file.
    
    % Find the uncompressed file for the graph -> model.raw.
    mastodon_model_file = get_model_file( filenames );
    % Deserialize it.
    [ spot_table, link_table ] = import_mastodon_graph( mastodon_model_file );
    
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