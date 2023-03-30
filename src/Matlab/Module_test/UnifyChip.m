clear all;
clc;
idxC = 1;
%nRF52832
chiplist = ["nrf52_296ED4","nrf52_296EFE","nrf52_296ECB","nrf52_298624","nrf52_296E98",...
            "nrf52_2985ED","nrf52_29863A","nrf52_298641","nrf52_29861C","nrf52_298608",...
            "nrf52_298619"];
dir = char('../BIG/');% mkdir requires character vector
mkdir(dir);
    for idxA = 0:99 %repeated measurements
        chip = [];%hold the ubit8 array
        for idxc = 1:length(chiplist)
            ChipID = chiplist(idxc);
            fprintf('Test_%d,Chip_%s\n',idxA,ChipID);
            path = "../"+ChipID+"/TEST_"+idxA+".bin";
            fs = fopen(path,'rb');
            chip = [chip fread(fs,'ubit8')];
            fclose(fs);
        end

        path = "../BIG/"+"TEST_"+idxA+".bin";
        fs = fopen(path,'wb');
        fwrite(fs,chip);
        fclose(fs);
    end
