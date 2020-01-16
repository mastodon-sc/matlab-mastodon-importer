%% Develop and test the feasibility of importing Mastodon files into MATLAB.

close
clear
clc

source_file = 'samples/mamutproject.mastodon';
% source_file = 'samples/datasethdf5.mastodon';
% source_file = 'samples/small.mastodon';


% Load it.
G = import_mastodon( source_file );

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

% Plot all the cells of time-point 1 as ellipsoids.


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



