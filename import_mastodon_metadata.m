function metadata = import_mastodon_metadata( mastodon_master_file )

    READER_VERSION = '0.3';

    %% Open XML file.
    xdoc = xmlread( mastodon_master_file );
    
    mamut_project_items = xdoc.getElementsByTagName( 'MamutProject' );
    if isempty( mamut_project_items )
         error( 'MastodonImporter:incorrectXML', ...
                'Could not find "MamutProject" XML tag in Mastodon project file.' )
    end
    mamut_project_item = mamut_project_items.item( 0 );
    
    metadata.version = char(mamut_project_item.getAttribute( 'version' ) );
    if ~strcmp( metadata.version, READER_VERSION )
         error( 'MastodonImporter:incorrectMastodonFileVersion', ...
                'Incorrect mastodon file version. This importer was made for version %s, but detected version %s. Import *might* fail.', ...
                READER_VERSION, metadata.version);
    end
    
    %% SPIM data file path.
    spim_data_file_items    = mamut_project_item.getElementsByTagName( 'SpimDataFile' );
    spim_data_file_item     = spim_data_file_items.item( 0 );
    metadata.spim_data_file_path         = char( spim_data_file_item.getTextContent() );
    metadata.spim_data_file_path_type    = char( spim_data_file_item.getAttribute( 'type' ) );
    
    %% Physical units.
    space_units_items       = mamut_project_item.getElementsByTagName( 'SpaceUnits' );
    space_units_item        = space_units_items.item( 0 );
    metadata.space_units    = char( space_units_item.getTextContent() );
    
    time_units_items        = mamut_project_item.getElementsByTagName( 'TimeUnits' );
    time_units_item         = time_units_items.item( 0 );
    metadata.time_units     = char( time_units_item.getTextContent() );
    
end