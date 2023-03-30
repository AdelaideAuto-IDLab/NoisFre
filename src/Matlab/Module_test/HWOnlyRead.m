function [HW,hdmap] = HWOnlyRead(FileName,m,Method)
fs = fopen(FileName,'rb');
chip = fread(fs,'ubit8');
fclose(fs);
PUFDataBit = de2bi(chip,8,'left-msb');
PUFDataBit = PUFDataBit';
A = PUFDataBit(:)';
% if (Method == 'ITL') %interlancing
if (strcmp(Method,'ITL')) %interlancing
    hdmap = reshape(A,m,[])';
    hdmapt = zeros(size(hdmap,1),size(hdmap,2));
    for idxL = 1:2:size(hdmap,1)
        for idxB = 1:2:size(hdmap,2)
            hdmapt(idxL,idxB) = hdmap(idxL,idxB);
            hdmapt(idxL,idxB+1) = hdmap(idxL+1,idxB);
            hdmapt(idxL+1,idxB) = hdmap(idxL,idxB+1);
            hdmapt(idxL+1,idxB+1) = hdmap(idxL+1,idxB+1);
        end
    end
    hdmap = hdmapt;
%     HW=sum(hdmap(:,1:m-1),2);
    HW=sum(hdmap(:,1:m),2);
else
    if(numel(A) > floor(numel(A)/m)*m) % to adopt A don't divide by m.
        A = A(1:floor(numel(A)/m)*m);
    end
    hdmap = reshape(A,m,[])';
%     HW=sum(hdmap(:,1:m-1),2);
    HW=sum(hdmap(:,1:m),2);
end
