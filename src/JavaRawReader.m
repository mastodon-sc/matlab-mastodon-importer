classdef JavaRawReader < ByteBlockReader
    
    properties ( SetAccess = private )
        fid
    end % properties
    
    methods
        
        %% Constructor.
        function obj = JavaRawReader( raw_file_path )
            obj@ByteBlockReader( zeros( 0, 0, 'uint8' ) );
            
            EXPECTED_STREAM_MAGIC_NUMBER    = -21267;
            EXPECTED_STREAM_VERSION         = 5;
            
            obj.fid = fopen( raw_file_path, 'r', 'b' );
            if obj.fid < 0
                error( 'JavaRawReader:cannotOpenFile', ...
                    'Could not open file %s for reading.', raw_file_path )
            end
            
            stream_magic_number = fread( obj.fid, 1, 'int16' );
            if stream_magic_number ~= EXPECTED_STREAM_MAGIC_NUMBER
                 error( 'JavaRawReader:badBinFile', ...
                    'Unexpected magic number for file %s. Expected %d, got %d. Not a Java raw file?', ...
                    raw_file_path, EXPECTED_STREAM_MAGIC_NUMBER, stream_magic_number )
            end
            
            stream_version = fread( obj.fid, 1, 'int16' );
            if stream_version ~= EXPECTED_STREAM_VERSION
                 error( 'JavaRawReader:badBinFile', ...
                    'Unexpected stream version for file %s. Expected %d, got %d. Not a Java raw file?', ...
                    raw_file_path, EXPECTED_STREAM_VERSION, stream_version )
            end
            
        end        
        
        %% Destructor.
        function close( obj )
            fclose( obj.fid );
        end
                
        %% Read a string array.
        function arr = read_string_array( obj )
           obj.read_file_array_header();
           array_size = obj.read_file_uint();
           arr = cell( array_size, 1 );
           for i = 1 : array_size
               arr{ i } = obj.read_file_string();
           end           
        end
        
        %% Read an int array.
        function arr = read_int_array( obj )
           obj.read_file_array_header();
           array_size = obj.read_file_uint();
           arr = NaN( array_size, 1 );
           for i = 1 : array_size
               arr(i) = obj.read_file_int();
           end           
        end
        
        %% Read a byte array.
        function arr = read_byte_array( obj )
           obj.read_file_array_header();
           array_size = obj.read_file_uint();
           arr = fread( obj.fid, array_size, '*uint8' );
        end
        
        %% Read an enum value.
        function [ enum, enum_class ]  = read_enum( obj )
            
            enum_struct = read_file_enum_header( obj );
            enum = obj.read_file_string();
            enum_class = enum_struct.class_desc.class_name;
            
        end
        
    end % public methods
    
    methods ( Access = private )
        
        function enum_struct = read_file_enum_header( obj )
            
            enum_struct.tc_enum = fread( obj.fid, 1, '*uint8' );
            if ( enum_struct.tc_enum ~= 126 )
                error( 'JavaRawReader:notAnEnum', ...
                    'Could not find the key for enum in binary file.' )
            end
           
            enum_struct.class_desc          = obj.read_file_class_desc();
            enum_struct.enum_class_desc     = obj.read_file_class_desc();
            enum_struct.null                = obj.read_file_byte(); % 112 -> #70
        end
        
        %% Read a class_desc block.
        function class_desc = read_file_class_desc( obj )
            
            class_desc.class_desc = fread( obj.fid, 1, '*uint8' );
            % Check we have the right TC key:
            if class_desc.class_desc ~= 114
                error( 'JavaRawReader:notAClassDesc', ...
                    'Could not find the key for class_desc in binary file.' )
            end
            
            class_desc.class_name          = obj.read_file_utf8();
            class_desc.serial_version_UID  = obj.read_file_long();
            class_desc.n_handle_bytes      = obj.read_file_byte(); % should be 2?
            class_desc.n_handle            = obj.read_file_short();
            class_desc.end_block           = obj.read_file_byte(); % 120 -> #78
            
        end
        
        %% Read the array header.
        % Only works for string arrays, int arrays and byte arrays.
        function arr_struct = read_file_array_header( obj )
            arr_struct.tc_array = fread( obj.fid, 1, '*uint8' );
            % Check we have the right TC:
            if arr_struct.tc_array ~= 117
                error( 'JavaRawReader:notAnArrayAtIndex', ...
                    'Could not find the key for array tag in binary file.' )
            end            
            arr_struct.class_desc   = obj.read_file_class_desc();
            arr_struct.null         = obj.read_file_byte(); % 112 -> #70
        end
        
        %% Read a long directly from the file (not the block).
        function val = read_file_short( obj )           
            bytes = fread( obj.fid, 2, '*uint8' );
            val = typecast( bytes, 'int16' );
        end
        
        %% Read a long directly from the file (not the block).
        function val = read_file_long( obj )           
            bytes = fread( obj.fid, 8, '*uint8' );
            val = typecast( bytes, 'int64' );
        end
        
        %% Read an int directly from the file (not the block).
        function val = read_file_int( obj )           
            bytes = fread( obj.fid, 4, '*uint8' );
            val = typecast( bytes( end : -1 : 1 ), 'int32' );
        end
        
        %% Read an int directly from the file (not the block).
        function val = read_file_uint( obj )           
            bytes = fread( obj.fid, 4, '*uint8' );
            val = typecast(  bytes( end : -1 : 1 ), 'uint32' );
        end
        
        %% Read a byte directly from the file (not the block).
        function val = read_file_byte( obj )           
            val = fread( obj.fid, 1, '*uint8' );
        end
        
        %% Read a UTF8 directly from the file (not the block).
        function str = read_file_utf8( obj )
            % Serialized UTF8 string starts with a short int giving 
            % the string length.
            str_length = fread( obj.fid, 1, 'uint16' );
            % Then we just have to convert the right number of bytes to chars.
            bytes = fread( obj.fid, str_length, '*uint8' );
            str = native2unicode( bytes', 'UTF-8' );
        end
        
        %% Read a string directly from the file (not the block).
        function str = read_file_string( obj )
            % String = TC_STRING + UTF8.
            fread( obj.fid, 1, '*uint8' ); % should be #74 - >116
            str = obj.read_file_utf8(); 
        end
    end
    
    methods ( Access = protected )
        
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