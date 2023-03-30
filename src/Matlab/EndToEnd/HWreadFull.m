function HW = HWreadFull(FileName,n)
    %read hamming weight form file 
    %@IN str FileName = path to bin file
    %@IN int n = word width
    fs = fopen(FileName,'rb');
    chip = fread(fs,'ubit8');
    fclose(fs);
    PUFDataBit = de2bi(chip,8,'left-msb');
    PUFDataBit = PUFDataBit';
    A = PUFDataBit(:)';
    hdmap = reshape(A,n,[])';
    HW=sum(hdmap(:,1:n),2);
end