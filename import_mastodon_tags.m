function [ tag_table_vertices, tag_table_edges, tss ]  = import_mastodon_tags( mastodon_tag_file )
%% Deserialize a Mastodon tag file.


    %% Open file.

    reader = JavaRawReader( mastodon_tag_file );
    
    %% Read tag-set structure.
    
    tss = read_tag_set_structure( reader );
    
    %% Read vertices tags.
    
    [ map_vertices, label_sets_vertices ] = read_label_set_property_map( reader );
    
    [ map_edges, label_sets_edges ] = read_label_set_property_map( reader );
    
    reader.close();
    
    %% Create tag tables.
    
    tag_table_vertices = create_tag_table( map_vertices, label_sets_vertices, tss );
    tag_table_edges = create_tag_table( map_edges, label_sets_edges, tss );    
    
    %% Functions.
    
    function tag_table = create_tag_table( map, label_sets, tss )
        
        % Prepare columns.
        n_tag_set = numel( tss );
        columns = cell( 1, n_tag_set );
        for i = 1 : n_tag_set
            
            columns{ i } =  cell( size( map, 1 ), 1 );
            columns{ i }(:) = { '' };
            
        end
        
        % Map tag ids to tag_set.
        n_total_tags = 0;
        for i = 1 : numel( tss )
            for j = 1 : numel( tss(i).tags )
                n_total_tags = n_total_tags + 1;
            end
            
        end
        
        tag_map         = cell( n_total_tags, 1 );
        tag_set_map     = NaN( n_total_tags, 1 );
        
        for i = 1 : numel( tss )
            for j = 1 : numel( tss(i).tags )
                tag_map{ 1 + tss(i).tags(j).id } = tss(i).tags(j).label; % 0 -> 1
                tag_set_map( 1 + tss(i).tags(j).id ) = i; % 0 -> 1
            end
        end
        
        n_label_sets = numel( label_sets );
        
        for i = 1 : n_label_sets
            label_set = label_sets{ i };
            n_labels = numel( label_set );
            
            for j = 1 : n_labels
                tag_id = label_set( j );
                tag_name = tag_map{ 1 + tag_id };
                tag_set = tag_set_map( 1 + tag_id );
                
                idx = ( map( : , 2 ) == ( i - 1  ) ); % 1 -> 0
                columns{ tag_set }( idx ) = { tag_name };
            end
        end
        
        tag_table = table();
        tag_table.id = map( :, 1 );
        for i = 1 : n_tag_set
            tag_table.( tss( i ).name ) = categorical( columns{ i } );
        end
        
        
    end


    function tss = read_tag_set_structure( reader )
        
        
        % Read N Tag-sets.
        n_tag_sets = reader.read_int();
        
        tag_set_ids     = NaN( n_tag_sets, 1 );
        tag_set_names   = cell( n_tag_sets, 1 );
        tags            = cell( n_tag_sets, 1 );
        
        for i = 1 : n_tag_sets
            
            % Read tag-set id and name.
            tag_set_ids( i )= reader.read_int();
            tag_set_names{ i } = reader.read_utf8();
            
            % Read tags.
            n_tags = reader.read_int();
            
            tag_ids         = NaN( n_tags, 1 );
            tag_labels      = cell( n_tags, 1 );
            tag_colors      = NaN( n_tags, 1 );
            
            for j = 1 : n_tags
                
                tag_ids( j ) = reader.read_int();
                tag_labels{ j } = reader.read_utf8();
                tag_colors( j ) = reader.read_int();
                
            end
            
            tags{ i } = struct( ...
                'label', tag_labels, ...
                'id', num2cell( tag_ids ), ...
                'color', num2cell( tag_colors ) );
            
        end
        
        tss = struct( ...
            'id', num2cell( tag_set_ids ), ...
            'name', tag_set_names, ...
            'tags', tags );
        
    end


    function [ map, label_sets ] = read_label_set_property_map( reader )
        
        % Read the label set.
        num_sets = reader.read_int();
        label_sets = cell( num_sets, 1 );
        
        for i = 1 : num_sets
            
            num_labels = reader.read_int();
            labels = NaN( num_labels, 1 );
            
            for j = 1 : num_labels
                % The labels are ints in Mastodon -> tag linear index
                labels( j ) = reader.read_int();
            end
            label_sets{ i } = labels;
        end
        
        % Read entries.
        size = reader.read_int();
        keys = NaN( size, 1 );
        values = NaN( size, 1 );
        
        for i = 1 : size
            keys( i ) = reader.read_int(); % object id
            values(i ) = reader.read_int(); % set id
        end
        map = [ keys, values ];
        
    end


end