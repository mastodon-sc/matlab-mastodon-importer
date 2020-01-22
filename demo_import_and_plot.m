%% Develop and test the feasibility of importing Mastodon files into MATLAB.

close
clear
clc

% source_file = 'samples/mamutproject.mastodon';
% source_file = 'samples/datasethdf5.mastodon';
% source_file = 'samples/small2.mastodon';
source_file = '/Users/tinevez/Projects/JYTinevez/MaMuT/Mastodon-dataset/MaMuT_Parhyale_demo-mamut.mastodon';

%% Load data.

tic
[ G, metadata, tss ] = import_mastodon( source_file );

fprintf('Imported %d spots and %d links in %.1f seconds.\n', ...
    numnodes( G ), numedges( G ), toc )

%% Demos.

% Only retain long tracks and tracks that are close to coverslip.
% G = filter_tracks( G );

% Plot each track separately (slow) with a different color.
h_tracks = plot_individual_tracks( G );

% Plot objects according to a tag.
target_ts = 2; % Take the second tag-set.
% plot_colored_by_tag( G, tss, target_ts );

% Plot all the cells of time-point 1 as ellipsoids.
% h_ell = plot_cell_ellipsoids( G, 1 );



%% Demo functions.

function h = plot_cell_ellipsoids( G, timepoint )
%% Plot all the cells of time-point 1 as ellipsoids.

    idx = G.Nodes.t == timepoint;

    spots = G.Nodes( idx, : );
    n_spots = size( spots, 1 );
    colors2 = jet( n_spots );
    color_shuffle = randperm( n_spots );
    
    figure 
    hold on
    axis equal

    h = NaN( n_spots, 1 );
    for i = 1 : n_spots

        spot = spots( i, : );

        M = [ spot.x; spot.y; spot.z ];
        C = [
            spot.c_11, spot.c_12, spot.c_13
            spot.c_12, spot.c_22, spot.c_23
            spot.c_13, spot.c_23, spot.c_33
            ];

        h(i) = plot_ellipsoid( M, C );
        set( h(i), ...
            'EdgeColor', 'None', ...
            'FaceColor', colors2( color_shuffle(i), : ), ...
            'FaceLighting', 'Flat' );
    end
    light
end

%% Set the color by a tag-set.
function plot_colored_by_tag( G, tss, target_ts )

    % Because we store the tag but not the tag id, we have to do a small
    % gymnastics to retrieve the color of each vertex.

    node_colors = zeros( numnodes( G ), 3 );
    edge_colors = zeros( numedges( G ), 3 );

    tag_set = tss( target_ts );
    n_tags = numel( tag_set.tags );
    for i = 1 : n_tags    
        tag = tag_set.tags( i );

        idx = ( G.Nodes.( tag_set.name ) == tag.label );
        node_colors( idx, : ) = repmat( to_hex_color( tag.color ), [ sum(idx), 1 ] );

        idx = ( G.Edges.( tag_set.name ) == tag.label );
        edge_colors( idx, : ) = repmat( to_hex_color( tag.color ), [ sum(idx), 1 ] );

    end

    figure
    hold on
    axis equal

    plot( G, ...
        'ArrowSize', 0, ...
        'XData', G_filt.Nodes.x, ...
        'YData', G_filt.Nodes.y, ...
        'ZData', G_filt.Nodes.z, ...
        'NodeColor', node_colors, ...
        'EdgeColor', edge_colors, ...
        'MarkerSize', 10, ...
        'NodeLabel', '' )
    
end

%% Plot each track separately (slow) with a different color.
function h = plot_individual_tracks( G )

    figure
    hold on
    axis equal

    bins = conncomp( G, 'Type', 'weak' );
    track_ids = unique( bins );
    n_tracks = numel(track_ids );
    colors = jet( n_tracks );
    shuffle = randperm( n_tracks );
    colors = colors( shuffle, : );
    cmap = colors( bins, : );

    h = plot( G, ...            
        'ArrowSize', 0, ...
        'XData', G.Nodes.x, ...
        'YData', G.Nodes.y, ...
        'ZData', G.Nodes.z, ...        
        'EdgeColor', [ 0.3 0.3 0.3 ],...
        'NodeColor', cmap, ...
        'MarkerSize', 8, ...
        'NodeLabel', '' );

end

%% Only retain long tracks and tracks that are close to coverslip.
function G = filter_tracks( G )
    % Split it into tracks.
    [ bins, binsizes ] = conncomp( G, 'Type', 'weak' );

    idx = binsizes( bins ) > 30 & G.Nodes.z( bins )' < 100;
    G = subgraph( G, idx );

end



%% Utility functions.

function h = plot_ellipsoid( M, C )
    sdwidth = 1;
    npts    = 10;

    [ x, y, z ] = sphere( npts );
    ap = [ x(:) y(:) z(:) ]';
    [ v, d ] = eig( C );   
    d  = sdwidth * sqrt(d); % convert variance to sdwidth*sd
    bp = ( v * d * ap ) + repmat( M, 1, size( ap, 2 ) );
    xp = reshape( bp( 1, : ), size( x ) );
    yp = reshape( bp( 2, : ), size( y ) );
    zp = reshape( bp( 3, : ), size( z ) );
    h  = surf( xp, yp, zp );
end

function rgb = to_hex_color( val )

    hex_code = dec2hex( typecast( int32( val ), 'uint32'  ) );   
    rgb = reshape( sscanf( hex_code( 1 : 6 ).', '%2x' ), 3, []).' / 255;
    
end

