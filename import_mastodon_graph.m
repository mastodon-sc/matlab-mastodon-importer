function graph = import_mastodon_graph( mastodon_model_file )

    % Constants.
    SPOT_RECORD_SIZE    = 84; % bytes. 10 doubles 
    % (8 bytes each, x, y, z, c11, c12, c13, c22, c23, c33, brq ) + 1 int (4 bytes, time-point).
    LINK_RECORD_SIZE    = 4 * 4; % 4 ints
    
    fid = fopen( mastodon_model_file, 'r', 'b' );
    
    % Read java stream header.
    stream_header.stream_magic_number = fread( fid, 1, 'int16' );
    stream_header.stream_version = fread( fid, 1, 'int16' ); %#ok<STRNU>
    
    %% Read the graph.
    
    [ spot_table, link_table ] = read_graph( fid );
    
    %% Read the label property.
    % The label property is written as a string property map. In Mastodon, they
    % are saved as the concatenation of:
    % - an int[] array containing the ids of the object the labels are defined
    % for.
    % - a byte[] array, resulting from the concatenation of the of the UTF8
    % representation of each string.
    
    [ labels, idx ] = read_label_property( fid );
    
    % Put labels as row names in the spot table.
    row_names =  cell( size( spot_table, 1), 1 );
    row_names(:) = { '' };
    % We assume that the row indices are equal to the vertex id + 1.
    row_names( idx + 1 ) = labels;
    
    spot_table.label = row_names;
    
    %% Finished reading!
    
    fclose( fid );
    
    %% Assemble graph.
    
    edge_table = table();
    % Again, we assume that the row indices are equal to the vertex id + 1.
    edge_table.EndNodes = [ 1 + link_table.source_id, 1 + link_table.target_id ];
    
    graph = digraph( edge_table, spot_table );
    
    
    
    
    %% Functions.
    
    
    function[ spot_table, link_table ] = read_graph( fid )
        
        %
        % Read spots.
        %
        
        % Read first block.
        block = read_graph_block( fid );
        index = 1;
        
        % Read N vertices.
        [ n_vertices, index ] = read_block_int_le( block, index );
        
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
            
            if ( index + SPOT_RECORD_SIZE - 1 ) > numel( block )
                % We need to read another block and append the remainder.
                
                new_block = read_graph_block( fid );
                block = [
                    block( index : end )
                    new_block ];
                
                % Reset index.
                index = 1;
            end
            
            [ spot, index ] = read_block_spot( block, index );
            
            x( i )      = spot.x;
            y( i )      = spot.y;
            z( i )      = spot.z;
            t( i )      = spot.t;
            c_11( i )   = spot.cov_11;
            c_12( i )   = spot.cov_12;
            c_13( i )   = spot.cov_13;
            c_22( i )   = spot.cov_22;
            c_23( i )   = spot.cov_23;
            c_33( i )   = spot.cov_33;
            bsrs( i )   = spot.bsrs;
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
        
        if ( index + 4 - 1 ) > numel( block )
            % We need to read another block and append the remainder.
            
            new_block = read_graph_block( fid );
            block = [
                block( index : end )
                new_block ];
            
            % Reset index.
            index = 1;
        end
        
        
        % Read N edges.
        [ n_edges, index ] = read_block_int_le( block, index );
        
        source_id	= NaN( n_edges, 1 );
        target_id	= NaN( n_edges, 1 );
        source_out_index	= NaN( n_edges, 1 );
        target_in_index     = NaN( n_edges, 1 );
        id          = NaN( n_edges, 1 );
        
        for i = 1 : n_edges
            
            if ( index + LINK_RECORD_SIZE - 1 ) > numel( block )
                % We need to read another block and append the remainder.
                
                new_block = read_graph_block( fid );
                block = [
                    block( index : end )
                    new_block ];
                
                % Reset index.
                index = 1;
            end
            
            [ link, index ] = read_block_link( block, index );
            
            source_id( i )	= link.source_id;
            target_id( i )	= link.target_id;
            source_out_index( i )	= link.source_out_index;
            target_in_index( i )	= link.target_in_index;
            id( i ) = ( i - 1 );
            
        end
        
        link_table = table( ...
            id, ...
            source_id, ...
            target_id, ...
            source_out_index, ...
            target_in_index );
    end
    
    function [ labels, idx ] = read_label_property( fid )
        
        EXPECTED_LABEL_HEADER = [ ...
            117   114     0    19    91    76   106    97   118    97    ...
            46   108    97   110   103    46    83   116   114   105   110 ...
            103    59   173   210    86   231   233    29   123    71     2  ...
            0     0   120   112     0     0     0     1   116     0 ...
            5   108    97    98   101   108   117   114     0     2    91  ...
            73    77   186    96    38   118   234   178   165     2 ...
            0     0   120   112 ]' ;
        
        EXPECTED_STRING_ARRAY_HEADER = [ ...
            117   114     0     2    91    66   172   243    23   248   ...
            6     8    84   224     2     0     0   120   112 ]' ;
        
        % Read and check the label property header. It should be the same for
        % all files.
        label_header = fread( fid, 67, '*uint8' );
        if ~all( label_header == EXPECTED_LABEL_HEADER )
            error( 'MastodonImporter:badBinFile', ...
                'Unexpected header for the serialized label property.' )
        end
        
        % Read number of labels.
        n_labels = fread( fid, 1, 'int' );
        
        % Read the index of each label -> map to vertex id.
        idx = NaN( n_labels, 1 );
        for i = 1 : n_labels
            idx( i ) = fread( fid, 1, 'int' );
        end
        
        % Read and check the string array header. It should be the same for
        % all files.
        string_array_header = fread( fid, 19, '*uint8' );
        if ~all( string_array_header == EXPECTED_STRING_ARRAY_HEADER )
            error( 'MastodonImporter:badBinFile', ...
                'Unexpected header for the serialized label string arrays.' )
        end
        
        % Read the total length of the byte array that builds the string array.
        string_array_block_size = fread( fid, 1, 'int' );
        
        % Read the byte block.
        string_array_block = fread( fid, string_array_block_size, '*uint8' );
        
        % Read each label from the byte block.
        labels = cell( n_labels, 1 );
        index = 1;
        for i = 1 : n_labels
            [ labels{ i }, index ] = read_block_utf8( string_array_block, index );
        end
        
    end

    function [ str, index ] = read_block_utf8( block, index )
        % Serialized UTF8 string starts with a short int giving the string
        % length.
        [ str_length, index ] = read_block_short_le( block, index );
        % Then we just have to convert the right number of bytes to chars.
        bytes = block( index : index + str_length - 1 );
        str = native2unicode( bytes', 'UTF-8' );
        index  = index + str_length;
    end

    function block = read_graph_block( fid )
        % Read a block in the graph section of the model.raw file.
        
        % We must re-read the block header. Make of the key and the block size.
        block_data_long_key = fread( fid, 1, 'uint8' );
        if block_data_long_key ~= 122
            error( 'MastodonImporter:badBinFile', ...
                'Could not find the key for block size in binary file.' )
        end
        block_data_long = fread( fid, 1, 'int' );
        
        % Now we can read the block.
        block = fread(fid, block_data_long, '*uint8' );
    end

    function [ link, index ] = read_block_link( block, index )
        
        [ link.source_id, index ]	= read_block_int_le( block, index );
        [ link.target_id, index ]	= read_block_int_le( block, index );
        [ link.source_out_index, index ]	= read_block_int_le( block, index );
        [ link.target_in_index, index ]     = read_block_int_le( block, index );
        
    end

    function [ spot, index ] = read_block_spot( block, index )
        
        [ spot.x, index ]       = read_block_double( block, index );
        [ spot.y, index ]       = read_block_double( block, index );
        [ spot.z, index ]       = read_block_double( block, index );
        [ spot.t, index ]       = read_block_int( block, index );
        [ spot.cov_11, index ]   = read_block_double( block, index );
        [ spot.cov_12, index ]   = read_block_double( block, index );
        [ spot.cov_13, index ]   = read_block_double( block, index );
        [ spot.cov_22, index ]   = read_block_double( block, index );
        [ spot.cov_23, index ]   = read_block_double( block, index );
        [ spot.cov_33, index ]   = read_block_double( block, index );
        [ spot.bsrs, index ]    = read_block_double( block, index );
    end

    function [ i, index ] = read_block_int_le( block, index )
        % BE to LE.
        i = typecast( block( index + 3 : -1 : index ), 'int32' );
        index = index + 4;
    end

    function [ i, index ] = read_block_int( block, index )
        i = typecast( block( index : index + 3 ), 'int32' );
        index = index + 4;
    end

    function [ i, index ] = read_block_short_le( block, index )
        i = typecast( block( index + 1 : -1  : index  ), 'uint16' );
        index = index + 2;
    end

    function [ i, index ] = read_block_double( block, index )
        i = typecast( block( index : index + 7 ), 'double' );
        index = index + 8;
    end

end
