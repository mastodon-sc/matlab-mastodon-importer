function str = to_hex_str( bytes )
%% User-friendly representation of bytes.
    d = dec2hex( bytes )';
    str = d(:)';
    str = strtrim( regexprep( str, '.{40}', '$0\n' ) );
    str = strtrim( regexprep( str, '[^\n]{8}', '$0  ' ) );
    str = strtrim( regexprep( str, '[^\n]{2}', '$0 ' ) );

end
