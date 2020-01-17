classdef JavaRawReader < handle
    
    properties ( SetAccess = private )
        fid
        block
        index
        stream_magic_number
        stream_version
    end % properties
    
    methods
        
        %% Constructor.
        function obj = JavaRawReader( raw_file_path )
            obj.fid = fopen( raw_file_path, 'r', 'b' );
            obj.block = zeros( 0, 0, 'uint8' );
            obj.index = 0;
            
            obj.stream_magic_number = fread( obj.fid, 1, 'int16' );
            obj.stream_version = fread( obj.fid, 1, 'int16' );
        end        
        
        %% Destructor.
        function close( obj )
            fclose( obj.fid );
        end

        %% Get an unsigned byte.
        function val = read_uint8( obj )  
             try
                 val = obj.block( obj.index  );
                 obj.index = obj.index + 1;
             catch ME %#ok<NASGU>
                 fetch_block( obj )
                 val = read_uint8( obj );
             end            
        end
        
        %% Get an int.
        function val = read_int( obj )
            try
                val = typecast( obj.block( obj.index + 3 : -1 : obj.index ), 'int32' );
                obj.index = obj.index + 4;
            catch ME %#ok<NASGU>
                fetch_block( obj )
                val = read_int( obj );
            end
        end
        
        %% Get a short.
        function val = read_short( obj )
            try
                val = typecast( obj.block( obj.index + 1 : -1 : obj.index ), 'int16' );
                obj.index = obj.index + 2;
            catch ME %#ok<NASGU>
                fetch_block( obj )
                val = read_short( obj );
            end
        end
        
        %% Get a string.
        function str = read_utf8( obj )
            try
                
                % Serialized UTF8 string starts with a short int giving 
                % the string length.
                str_length = obj.read_short();
                % Then we just have to convert the right number of bytes to chars.
                bytes = obj.block( obj.index : obj.index + str_length - 1 );
                str = native2unicode( bytes', 'UTF-8' );
                obj.index = obj.index + str_length;
                
            catch ME %#ok<NASGU>
                fetch_block( obj )
                str = read_utf8( obj );
            end
        end
        
    end % public methods
    
    methods ( Access = private )

        %% Read a block in the Java bin file and stores it in the class.
        function fetch_block( obj )
            
            % We must re-read the block header. Make of the key and the block size.
            block_data_key = fread( obj.fid, 1, 'uint8' );
            
            % Is this a small or a long block?
            if block_data_key == 122
                % Long block.
                block_data_long = fread( obj.fid, 1, 'int' );
                
            elseif block_data_key == 119
                % Short block.
                block_data_long = fread( obj.fid, 1, 'uint8' );
                
            else
                % Unexpected.
                error( 'JavaRawReader:badBinFile', ...
                    'Could not find the key for block size in binary file.' )
            end
            
            % Now we can read the block.
            new_block = fread( obj.fid, block_data_long, '*uint8' );
            
            % Update reader object.
            if isempty( obj.block )
                obj.block = new_block;
            else
                obj.block = [
                    obj.block( obj.index : end )
                    new_block ];
            end
            
            % Reset index.
            obj.index = 1;
        end
        
    end
    
end