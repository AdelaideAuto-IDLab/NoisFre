%Unify 12 random chips
clear all;
clc;
idxC = 1;
%nRF52832
chiplist = ["rand_296ED4","rand_296EFE","rand_296ECB","rand_298624","rand_296E98",...
            "rand_2985ED","rand_29863A","rand_298641","rand_29861C","rand_298608",...
            "rand_298619"];
dir = char('../BIGR/25C');% mkdir requires character vector
mkdir(dir);
dir = char('../BIGR/80C_15M');% mkdir requires character vector
mkdir(dir);
    for idxA = 0:99 %repeated measurements
        chip = [];%hold the ubit8 array
        for idxc = 1:length(chiplist)
            ChipID = chiplist(idxc);
            fprintf('Test_%d,Chip_%s\n',idxA,ChipID);
            path = "../RAND/"+ChipID+"/25C/TEST_"+idxA+".bin";
            fs = fopen(path,'rb');
            chip = [chip fread(fs,'ubit8')];
            fclose(fs);
        end

        path = "../BIGR/"+"25C/TEST_"+idxA+".bin";
        fs = fopen(path,'wb');
        fwrite(fs,chip);
        fclose(fs);
    end
%% 80C    
dir = char('../BIG/80C_15M');% mkdir requires character vector
mkdir(dir);
    for idxA = 0:99 %repeated measurements
        chip = [];%hold the ubit8 array
        for idxc = 1:length(chiplist)
            ChipID = chiplist(idxc);
            fprintf('Test_%d,Chip_%s\n',idxA,ChipID);
            path = "../RAND/"+ChipID+"/80C_15M/TEST_"+idxA+".bin";
            fs = fopen(path,'rb');
            chip = [chip fread(fs,'ubit8')];
            fclose(fs);
        end

        path = "../BIGR/"+"80C_15M/TEST_"+idxA+".bin";
        fs = fopen(path,'wb');
        fwrite(fs,chip);
        fclose(fs);
    end