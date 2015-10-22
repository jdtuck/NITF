"""
Read meta data for NITF 2.1

    nitfparse21(fid::IOStream)
"""
function nitfparse21(fid::IOStream)
    nitf_meta = [];
    fields = ["FHDR"   "FileProfileNameAndVersion"          9;
              "CLEVEL"  "ComplexityLevel"                  2;
              "STYPE"   "StandardType"                     4;
              "OSTAID"  "OriginatingStationID"            10;
              "FDT"     "FileDateAndTime"                 14;
              "FTITLE"  "FileTitle"                       80;
              "FSCLAS"  "FileSecurityClassification"       1;
              "FSCLSY"  "FileSecurityClassificationSystem" 2;
              "FSCODE"  "FileCodewords"                   11;
              "FSCTLH"  "FileControlAndHandling"           2;
              "FSREL"   "FileReleasingInstructions"       20;
              "FSDCTP"  "FileDeclassificationType"         2;
              "FSDCDT"  "FileDeclassificationDate"         8;
              "FSDCXM"  "FileDeclassificationExemption"    4;
              "FSDG"    "FileDowngrade"                    1;
              "FSDGT"   "FileDowngradeDate"                8;
              "FSCLTX"  "FileClassificationText"          43;
              "FSCATP"  "FileClassificationAuthorityType"  1;
              "FSCAUT"  "FileClassificationAuthority"     40;
              "FSCRSN"  "FileClassificationReason"         1;
              "FSSRDT"  "FileSecuritySourceDate"           8;
              "FSCTLN"  "FileSecurityControlNumber"       15;
              "FSCOP"   "FileCopyNumber"                   5;
              "FSCPYS"  "FileNumberOfCopies"               5;
              "ENCRYP"  "Encryption"                       1;
              "FBKGC"   "FileBackgroundColor"              3;
              "ONAME"   "OriginatorName"                  24;
              "OPHONE"  "OriginatorPhoneNumber"           18;
              "FL"      "FileLength"                      12;
              "HL"      "NITFFileHeaderLength"             6;
              "NUMI"    "NumberOfImages"                   3];

    nitf_read_meta!(nif_meta, fields, fid);

    numi = float(join(nitf_meta[end]["value"]));
    nitf_meta, im_lengths = processtopimagesubheadermeta(numi, nitf_meta, fid);
end


"""
Read meta data for NITF 2.1

    nitfparse20(fid::IOStream)
"""
function nitfparse20(fid::IOStream)
    nitf_meta = Dict();
end


"""
Append attributes to metadata type

    nitf_read_meta!(meta::Array, fields::Array, fid)
    :param meta: Array
    :param fields:: Array
    :param fid: IOStream
"""
function nitf_read_meta!(meta::Dict, fields::Array, fid::IOStream)
    # as a an optimization, convert the lengths part of the array to a vector
    data_lengths = vec(fields[:,3]);

    # read all of teh data at once. Extract individual values in the loop.
    data = readbytes(fid, sum(data_lengths));
    data = map(Char, data);

    data_offset = 0;
    for p = 1:size(fields,1)
        start = data_offset + 1;
        stop = data_offset + data_lengths[p];
        meta = [meta; Dict("name"=>fields[p,1],"vname"=>fields[p,2],
                           "value"=>data[start:stop])];
        data_offset = stop;
    end
end


"""
Add the nth image subheader information to the nitf_meta Dict. This Dict
contains the image subheader length and image length for all the images in the
filed

    processtopimagesubheadermeta!(nitf_meta, numi, fid)
    :param numi: number of images
    :param nitf_meta: Dict
    :param fid: IOStream

    :return nitf_meta
"""
function processtopimagesubheadermeta!(nitf_meta, numi, fid)
    nitf_metaISL = [];
    if (numi > 0)
        nitf_meta[end]["vname"] = "ImageAndImageSubheaderLengths";

        fields = ['LISH%03d' 'LengthOfNthImageSubheader'   6;
                  'LI%010d'  'LengthOfNthImage'           10];

        for current = 1:numi
            # setup
            name_t = @sprintf("Image%03d", current);

            # parse the data
            temp = [];
            nitf_read_meta_multi!(temp, fields, fid, current);
            nitf_metaISL = [nitf_metaISL; Dict("name"=>name_t, "vname"=> [name_t "ImageAndSubheaderLengths", "value"=>temp])];
        end

        nitf_meta = [nitf_meta; Dict("name"=>"ImageAndSubHeaderLengths",
                                     "vname"=>fields[p,2],
                                     "value"=>nitf_metaISL)];
    end
end

"""
Append attributes to metadata array

    nitf_read_meta_multi!(meta, fields, fid, index)
"""
function nitf_read_meta_multi!(meta, fields, fid, index)
    # as a an optimization, convert the lengths part of the array to a vector
    data_lengths = vec(fields[:,3]);

    # read all of teh data at once. Extract individual values in the loop.
    data = readbytes(fid, sum(data_lengths));
    data = map(Char, data);

    data_offset = 0;
    for p = 1:size(fields,1)
        start = data_offset + 1;
        stop = data_offset + data_lengths[p];
        name_t = @sprintf(fields[p,1], index);
        name_t1 = @sprintf(fields[p,2], index);
        meta = [meta; Dict("name"=>name_t,"vname"=>name_t1,
                           "value"=>data[start:stop])];
        data_offset = stop;
    end
end
