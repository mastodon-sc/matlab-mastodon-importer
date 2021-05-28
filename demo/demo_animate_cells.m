%% A Mastodon importer demo that shows how to generate a movie.
% Based on a script by Yusaku OHTA, National Institute for Basic Biology,
% Japan.

close all
clear
clc

%% Add the import files to the MATLAB path.

% This changes the path, but only for this session. It will be forgotten
% after you restart MATLAB.
addpath( '../src' )


%% Load data.

source_file = 'mamutproject.mastodon';

tic
[ G, metadata, tss ] = import_mastodon( source_file );

fprintf('Imported %d spots and %d links in %.1f seconds.\n', ...
    numnodes( G ), numedges( G ), toc )

% Create object to write video files.
vidObj = VideoWriter('MastodonAnimation','MPEG-4');
vidObj.Quality = 100;
vidObj.FrameRate = 5;

% Determine axes bounds.
minx = min( G.Nodes.x );
maxx = max( G.Nodes.x );
miny = min( G.Nodes.y );
maxy = max( G.Nodes.y );
minz = min( G.Nodes.z );
maxz = max( G.Nodes.z );
rangex = maxx - minx;
rangey = maxy - miny;
rangez = maxz - minz;

% Creating a movie from still images.
% Plot all the cells of time-point t as ellipsoids.
hf = figure;  
hold on
axis equal

borderfactor = 0.1;
xlim( [ minx - borderfactor * rangex, maxx + borderfactor * rangex ] )
ylim( [ miny - borderfactor * rangey, maxx + borderfactor * rangey ] )
zlim( [ minz - borderfactor * rangez, maxx + borderfactor * rangez ] )

hf.WindowState = 'maximized';
view( 27, 17 )

open( vidObj );
for j = min(G.Nodes.t) : max(G.Nodes.t)
    
    plot_cell_ellipsoids( G, j, hf );
    drawnow
    f = getframe( hf );
    writeVideo( vidObj, f );
    
end
close( vidObj );

function h = plot_cell_ellipsoids( G, timepoint, hf )
%% Plot all the cells of time-point t as ellipsoids.

    cla
    idx = G.Nodes.t == timepoint;

    spots = G.Nodes( idx, : );
    n_spots = size( spots, 1 ); 
    
    trackids = spots.SpotTrackID;
    uids = unique( trackids );
    ntrackids = numel( uids );
    colors = jet( ntrackids ); 
    
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
        
        colidx = find( trackids(i) == uids, 1 );
        set( h(i), ...
            'EdgeColor', 'None', ...
            'FaceColor', colors( colidx, : ), ...
            'FaceLighting', 'Flat' );
    end
    light
    
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