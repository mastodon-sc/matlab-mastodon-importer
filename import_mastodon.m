function [ G, tss ] = import_mastodon( source_file )

    % Uncompress data file into temp dir.
    filenames = unzip( source_file, fullfile( tempdir, source_file ) );
    
    % Find the uncompressed file for the graph -> model.raw.
    mastodon_model_file = get_model_file( filenames );
    % Deserialize it.
    G = import_mastodon_graph( mastodon_model_file );
    
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
   
    
    %% Functions.
    
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