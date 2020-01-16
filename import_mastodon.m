function graph = import_mastodon( source_file )

    % Uncompress data file into temp dir.
    filenames = unzip( source_file, fullfile( tempdir, source_file ) );
    
    % Find the uncompressed file for the graph -> model.raw.
    mastodon_model_file = get_model_file( filenames );
    % Deserialize it.
    graph = import_mastodon_graph( mastodon_model_file );
    
    
    %% Functions.
    
    function model_file = get_model_file( filenames )
        
        id = find( ~cellfun( @isempty, regexp( filenames, '.*model.raw$') ) );
        if isempty( id )
            error( 'MastodonImporter:missingModelFile', ...
                'Could not find model file in Mastodon file.' )
        end
        
        model_file = filenames{ id };
    end

end