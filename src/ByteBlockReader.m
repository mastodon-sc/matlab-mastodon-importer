classdef ByteBlockReader < handle
    
    properties ( SetAccess = protected )
        block
        index
    end % properties
    
    methods
        %% Constructor.
        function obj = ByteBlockReader( block )
            obj.block = block;
            obj.index = 1;
        end
        
        %% Get an unsigned byte.
        function val = read_uint8( obj )
            try
                val = obj.block( obj.index );
                obj.index = obj.index + 1;
            catch ME %#ok<NASGU>
                fetch_block( obj )
                val = read_uint8( obj );
            end
        end
        
        %% Get a double.
        function val = read_double( obj )
            try
                val = typecast( obj.block( obj.index : obj.index + 7 ), 'double' );
                obj.index = obj.index + 8;
            catch ME %#ok<NASGU>
                fetch_block( obj )
                val = read_double( obj );
            end
        end
        
        %% Get a double.
        function val = read_double_rev( obj )
            try
                val = typecast( obj.block( obj.index + 7 : -1 : obj.index ), 'double' );
                obj.index = obj.index + 8;
            catch ME %#ok<NASGU>
                fetch_block( obj )
                val = read_double_rev( obj );
            end
        end
        
        %% Get N doubles.
        function vals = read_n_doubles( obj, n )
            try
                vals = typecast( obj.block( obj.index : obj.index + ( n * 8 - 1 ) ), 'double' );
                obj.index = obj.index + n * 8;
            catch ME %#ok<NASGU>
                fetch_block( obj )
                vals = read_n_doubles( obj, n );
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
        
         %% Get N ints.
        function vals = read_n_ints( obj, n )
            if ( obj.index + ( 4*n - 1 ) > numel( obj.block ) )
                fetch_block( obj )
            end
            vals = typecast( obj.block( obj.index + ( 4*n - 1 ) : -1 : obj.index ), 'int32' );
            obj.index = obj.index + 4*n;
            vals = flip( vals );
        end
        
         %% Skip an int.
        function skip_int( obj )
            if ( obj.index + 3 > numel( obj.block ) )
                fetch_block( obj );
            end
            obj.index = obj.index + 4;
        end
        
        %% Get an int, reveresed order.
        function val = read_int_rev( obj )
            try
                val = typecast( obj.block( obj.index : obj.index + 3 ), 'int32' );
                obj.index = obj.index + 4;
            catch ME %#ok<NASGU>
                fetch_block( obj )
                val = read_int_rev( obj );
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
        
        %% Get a utf8 string.

        
        function str = read_utf8( obj, str_length )
            if nargin < 2
                str_length = -1;
            end
            try
                % Serialized UTF8 string starts with a short int giving
                % the string length.
                % Read it only if we have not read it yet
                if str_length < 0
                    str_length = obj.read_short();
                end
                % Then we just have to convert the right number of bytes to chars.
                bytes = obj.block( obj.index : obj.index + str_length - 1 );
                str = native2unicode( bytes', 'UTF-8' );
                obj.index = obj.index + str_length;
                
            catch ME %#ok<NASGU>
                fetch_block( obj )
                str = read_utf8( obj, str_length );
            end
        end
        
    end
    
    methods (Access = protected)
        function fetch_block( obj )
            % Just return an error.
            error( 'ByteBlockReader:endOfBlockReached', ...
                    'Reached the end of the block. Block size = %d, index = %d.', ...
                    numel( obj.block ), obj.index )
        end
    end    
end