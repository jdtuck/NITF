"""
Reads metadata from NITF file

    nitfinfo(filename::AbstractString)
    :param filename: string pointing to filename

    :return nitf_meta: output metadata
"""
function nitinfo(filename::AbstractString)
    # get details about the file to read
    fileDetails = get_file_details(filename);

    # ensure the file is NITF and get its version
    valid, nitf_version = isnitf(fileDetails["filename"]);

    if (!valid)
        error("The image is not a NITF")
    elseif (!is_supported_nitf_version(nitf_version))
        error(string("This reader does not support NITF version: ", nitf_version );
    end

    # open the file
    fid = open(fileDetails["filename"], "r");

    # read the metadata
    if nitf_version == "2.1"
        nitf_meta = nitfparse21(fid);
    elseif nitf_version == "2.0"
        nitf_meta = nitfparse20(fid);
    end

    # close the file
    close(fid);

    # set up standard data elements

end


"""
Reads NITF file details to extract metadata

    get_file_details(filename::AbstractString)
    :param filename: string pointing to filename

    :return details: Dict containing details
"""
function get_file_details(filename::AbstractString)
    fid = open(filename, "r");
    info = stat(info);

    details = Dict("Filename" => filename, "FileModDate" => info.mtime,
                   "FileSize" => info.size);
    close(fid)
end


"""
Check if file is a NITF and returns the version

    isniti(filename)
    :param: filename: string pointing to filename

    :return tf: boolean if valid
    :return nitf_version: version number
"""
function isnitf(filename::AbstractString)
    fid = open(filename, "r");

    # get first conditional NITF header fields and inspect the first for the
    # NITF version
    fhdr = map(Char, readbytes(fid, 324));
    close(fid)

    if length(fhdr) == 324 && join(fhdr[1:9]) == "NITF02.10"
        tf = true;
        nitf_version = "2.1";
    elseif length(fhdr) == 324 && join(fhdr[1:9]) == "NITF02.00"
        tf = true;
        nitf_version = "2.0";
    elseif length(fhdr) == 324 && join(fhdr[1:9]) == "NITF01.10"
        tf = true;
        nitf_version = "1.1";
    elseif length(fhdr) == 324 && join(fhdr[1:9]) == "NSIF01.00"
        tf = true;
        # It's an NSIF 1.0 file which translates to NITF2.1
        nitf_version = "2.1";
    else
        nitf_version = "UNK";
        tf = false;
    end

    return tf, nitf_version
end


"""
Checks if reader supports NITF version

    is_supported_nitf_version(nitf_version);
    :param nitf_version: string
"""
function is_supported_nitf_version(nitf_version)
    tf = nitf_version == "2.1" || nitf_version == "2.0";

    return tf
end
