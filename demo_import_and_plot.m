%% Develop and test the feasibility of importing Mastodon files into MATLAB.

close
clear
clc

source_file = 'samples/mamutproject.mastodon';
% source_file = 'samples/datasethdf5.mastodon';
% source_file = 'samples/small2.mastodon';


% Load it.
[ G, tss ] = import_mastodon( source_file );

%% Analyze the graph a little bit.

% Split it into tracks.
[ bins, binsizes ] = conncomp( G, 'Type', 'weak' );

% Only retain long tracks and tracks that are close to coverslip.
idx = binsizes( bins ) > 30 & G.Nodes.z( bins )' < 100;
G_filt = subgraph( G, idx );


%% Plot the graph

figure 
hold on
axis equal

% Plot each track with a different color.

bins = conncomp( G_filt, 'Type', 'weak' );
track_ids = unique( bins );
n_tracks = numel(track_ids );
colors = jet( n_tracks );

for i = 1 : n_tracks
   
    track_id = track_ids( i );
    idx = bins == track_id;
    SG = subgraph( G_filt, idx );
    
    plot( SG, ...
        'XData', SG.Nodes.x, ...
        'YData', SG.Nodes.y, ...
        'ZData', SG.Nodes.z, ...
        'EdgeColor', colors( i, : ),...
        'LineWidth', 2, ...
        'NodeColor', colors( i, : ), ...
        'NodeLabel', '' )
    
end

%% Set the color by a tag-set.
% Because we store the tag but not the tag id, we have to do a small
% gymnastics to retrieve the color of each vertex.


target_ts = 2; % Take the first tag-set.

node_colors = zeros( numnodes( G_filt ), 3 );
edge_colors = zeros( numedges( G_filt ), 3 );

tag_set = tss( target_ts );
n_tags = numel( tag_set.tags );
for i = 1 : n_tags    
    tag = tag_set.tags( i );

    idx = ( G_filt.Nodes.( tag_set.name ) == tag.label );
    node_colors( idx, : ) = repmat( to_hex_color( tag.color ), [ sum(idx), 1 ] );

    idx = ( G_filt.Edges.( tag_set.name ) == tag.label );
    edge_colors( idx, : ) = repmat( to_hex_color( tag.color ), [ sum(idx), 1 ] );

end


figure
hold on

plot( G_filt, ...
    'XData', G_filt.Nodes.x, ...
    'YData', G_filt.Nodes.y, ...
    'ZData', G_filt.Nodes.z, ...
    'EdgeColor', colors( i, : ),...
    'NodeColor', node_colors, ...
    'EdgeColor', edge_colors, ...
    'MarkerSize', 10, ...
    'NodeLabel', '' )

%% Plot all the cells of time-point 1 as ellipsoids.


idx = G_filt.Nodes.t == 0;

spots = G_filt.Nodes( idx, : );
n_spots = size( spots, 1 );
colors2 = parula( n_spots );

for i = 1 : n_spots
       
    spot = spots( i, : );
    
    M = [ spot.x; spot.y; spot.z ];
    C = [
        spot.c_11, spot.c_12, spot.c_13
        spot.c_12, spot.c_22, spot.c_23
        spot.c_13, spot.c_23, spot.c_33
        ];
    
    h = plot_gaussian_ellipsoid( M, C );
    h.EdgeColor = 'None';
    s.FaceColor = colors2( i, : );
    s.FaceLighting = 'Gouraud';
end



function rgb = to_hex_color( val )

    hex_code = dec2hex( typecast( int32( val ), 'uint32'  ) );   
    rgb = reshape( sscanf( hex_code( 1 : 6 ).', '%2x' ), 3, []).' / 255;
    
end

