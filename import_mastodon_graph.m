function graph = import_mastodon_graph( mastodon_model_file )

   
    %% Open file.

    reader = JavaRawReader( mastodon_model_file );
    
    %% Read the graph.
    
    [ spot_table, link_table ] = read_graph( reader );
    
    %% Read the label property.
    
    
    [ labels, idx ]  = read_label_property( reader );
    
    % Put labels as row names in the spot table.
    row_names =  cell( size( spot_table, 1), 1 );
    row_names(:) = { '' };
    % We assume that the row indices are equal to the vertex id + 1.
    row_names( idx + 1 ) = labels;
    
    spot_table.label = row_names;
    empty = cell( 13, 1 );
    empty(:) = { '' };
    spot_table.Properties.VariableUnits = empty; % TODO
    spot_table.Properties.VariableDescriptions = empty;

    
    %% Finished reading!
    
    reader.close()
    
    %% Assemble graph.
    
    edge_table = table();
    % Again, we assume that the row indices are equal to the vertex id + 1.
    edge_table.EndNodes = [ 1 + link_table.source_id, 1 + link_table.target_id ];
    empty = { '' };
    edge_table.Properties.VariableUnits = empty; % TODO
    edge_table.Properties.VariableDescriptions = empty;
    edge_table.id = link_table.id;

    
    graph = digraph( edge_table, spot_table );
    
        
    %% Functions.
    
    
    function[ spot_table, link_table ] = read_graph( reader )
        
        %
        % Read spots.
        %
        
        % Read N vertices.
        n_vertices = reader.read_int();
        
        x       = NaN( n_vertices, 1 );
        y       = NaN( n_vertices, 1 );
        z       = NaN( n_vertices, 1 );
        t       = NaN( n_vertices, 1 );
        c_11    = NaN( n_vertices, 1 );
        c_12    = NaN( n_vertices, 1 );
        c_13    = NaN( n_vertices, 1 );
        c_22    = NaN( n_vertices, 1 );
        c_23    = NaN( n_vertices, 1 );
        c_33    = NaN( n_vertices, 1 );
        bsrs    = NaN( n_vertices, 1 );
        id      = NaN( n_vertices, 1 );
        
        for i = 1 : n_vertices
            
            xyz         = reader.read_n_doubles( 3 );
            x( i )      = xyz( 1 );
            y( i )      = xyz( 2 );
            z( i )      = xyz( 3 );
            t( i )      = reader.read_int_rev();
            covs        = reader.read_n_doubles( 7 );
            c_11( i )   = covs( 1 );
            c_12( i )   = covs( 2 );
            c_13( i )   = covs( 3 );
            c_22( i )   = covs( 4 );
            c_23( i )   = covs( 5 );
            c_33( i )   = covs( 6 );
            bsrs( i )   = covs( 7 );
            id( i )     = (i - 1);
            
        end
        
        spot_table = table( ...
            id, ...
            x, ...
            y, ...
            z, ...
            t, ...
            c_11, ...
            c_12, ...
            c_13, ...
            c_22, ...
            c_23, ...
            c_33, ...
            bsrs );
        
        %
        % Read links.
        %
        
        % Read N edges.
        n_edges = reader.read_int();
        
        source_id	= NaN( n_edges, 1 );
        target_id	= NaN( n_edges, 1 );
        source_out_index	= NaN( n_edges, 1 );
        target_in_index     = NaN( n_edges, 1 );
        id          = NaN( n_edges, 1 );
        
        for i = 1 : n_edges
            
            vids = reader.read_n_ints( 4 );
            source_id( i )	= vids( 1 );
            target_id( i )	= vids( 2 );
            id( i ) = ( i - 1 );
            
        end
        
        link_table = table( ...
            id, ...
            source_id, ...
            target_id, ...
            source_out_index, ...
            target_in_index );        
    end
    
    function [ labels, vertex_ids ] = read_label_property( reader )
        % The label property is written as a string property map. In
        % Mastodon, they are saved as the concatenation of: - an int[]
        % array containing the ids of the object the labels are defined
        % for. - a byte[] array, resulting from the concatenation of the of
        % the UTF8 representation of each string.
        
        string_properties   = reader.read_string_array(); %#ok<NASGU>
        vertex_ids          = reader.read_int_array();
        n_labels = numel( vertex_ids );
        string_array_block  = reader.read_byte_array();
        block_reader = ByteBlockReader( string_array_block );
        labels = cell( n_labels, 1 );
        for i = 1 : numel( vertex_ids )
            labels{ i }= block_reader.read_utf8();
        end        
    end

end
