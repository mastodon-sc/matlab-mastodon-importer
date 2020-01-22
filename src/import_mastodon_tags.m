function [ spot_table, link_table, tss ]  = import_mastodon_tags( mastodon_tag_file, spot_table, link_table )
%% Deserialize a Mastodon tag file.


    %% Open file.

    reader = JavaRawReader( mastodon_tag_file );
    
    %% Read tag-set structure.
    
    tss = read_tag_set_structure( reader );
    
    %% Read vertices tags.
    
    [ map_vertices, label_sets_vertices ]   = read_label_set_property_map( reader );
    [ map_edges,    label_sets_edges ]      = read_label_set_property_map( reader );
    
    reader.close();
    
    %% Create tag tables.
    
    spot_table = append_tags_to_table( map_vertices,    label_sets_vertices,    tss, spot_table );
    link_table = append_tags_to_table( map_edges,       label_sets_edges,       tss, link_table );
    
    % Finished!
    
    
    %% Functions.
    
    function T = append_tags_to_table( map, label_sets, tss, T )
        
        % Prepare columns.
        n_tag_set = numel( tss );
        columns = cell( 1, n_tag_set );
        for i = 1 : n_tag_set
            columns{ i } = NaN( height( T ), 1 );
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
        
        % Process label-set by label-set.
        for i = 1 : n_label_sets
            
            label_set = label_sets{ i };
            n_labels = numel( label_set );
            
            for j = 1 : n_labels
                
                % What is the tag-id of this element in the label set?
                tag_id = label_set( j );
                
                % What tag-set column are we editing for this tag_id?
                tag_set = tag_set_map( 1 + tag_id ); 
                
                % What rows, in the map, have this label-set?
                idx2 = ( map( : , 2 ) == ( i - 1  ) ); % 1 -> 0
                
                % What object ids correspond to these rows?
                object_ids = map( idx2, 1 );
                
                % What are the rows, in the table, that have these ids?
                [ ~, idx1 ] = ismember( object_ids, T.id );

                % Fill these rows with the tag_id
                columns{ tag_set }( idx1 ) = tag_id;
                
            end
        end
        
        for i = 1 : n_tag_set
            T.( tss( i ).name ) = categorical( ...
                columns{ i }, ...
                [ tss(i).tags.id], ...
                { tss(i).tags.label } );
            
            T.Properties.VariableUnits = [ T.Properties.VariableUnits, '' ];
            T.Properties.VariableDescriptions = [ T.Properties.VariableDescriptions, '' ];
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