%% Develop and test the feasibility of importing Mastodon files into MATLAB.

close
clear
clc

source_file = 'samples/datasethdf5.mastodon';



SPOT_RECORD_SIZE = 84; % bytes. 10 doubles (8 bytes each, x, y, z, c11, c12, c13, c22, c23, c33, brq ) + 1 int (4 bytes, time-point).

%% Uncompress data file into temp dir.

filenames = unzip( source_file, tempdir );

%% Identify uncompressed files.

model_file = get_model_file( filenames );
fid = fopen( model_file, 'r', 'b' );

% Read java stream header.
stream_header.stream_magic_number = fread( fid, 1, 'int16' );
stream_header.stream_version = fread( fid, 1, 'int16' );

% Read first block.
block = read_block( fid );
index = 1;

% Read N vertices.
[ n_vertices, index ] = read_block_int_le( block, index );


for i = 1 : n_vertices
    
    
    if ( index + SPOT_RECORD_SIZE ) > numel( block )
        % We need to read another block and append the remainder.
        
        new_block = read_block( fid );
        block = [
            block( index : end )
            new_block ];
        
        % Reset index.
        index = 1;
    end
    
    [ spot, index ] = read_block_spot( block, index );
    spot.id = (i - 1);
    
    spots( i ) = spot;
    
end

fclose( fid );



%% Functions.

function block = read_block( fid )

    % We must re-read the block header. Make of the key and the block size.
    block_data_long_key = fread( fid, 1, 'int8' );
    if block_data_long_key ~= 122
        error( 'MastodonImporter:badBinFile', ...
            'Could not find the key for block size in binary file.' )
    end    
    block_data_long = fread( fid, 1, 'int' );

    % Now we can read the block.
    block = fread(fid, block_data_long, '*uint8' );
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
    % BE to LE.
    i = typecast( block( index : index + 3 ), 'int32' );
    index = index + 4;
end

function [ i, index ] = read_block_double( block, index )
    i = typecast( block( index : index + 7 ), 'double' );
    index = index + 8;
end

function model_file = get_model_file( filenames )

    id = find( ~cellfun( @isempty, regexp( filenames, '.*model.raw$') ) );
    if isempty( id )
        error( 'MastodonImporter:missingModelFile', ...
            'Could not find model file in Mastodon file.' )
    end
    
    model_file = filenames{ id };
end
