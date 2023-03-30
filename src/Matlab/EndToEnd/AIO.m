clear all;
close all;
clc;
%% Constants
RAM_BASE = 0x20000000;
RAM_SZ =   0x00010000;
SYS_RESV = 0x00002300 + 0x00001000; %memory reserved for BLE protocol stack and user code

T_NAME = ["N15","25C","80C_15M"];

refN = 0;%there are 10 repeated measurements, the first measurement is treated as reference

% PUFID = [0,1,2];
PUFID = [0];
CHIPNUM=size(PUFID,2);
FTotalNum = 99;


%% Chip selection
dirvalid = false;
while(~dirvalid)
    dirname = uigetdir("../../SRAM_DATA","Select one chip, don't go into it");
    k = strfind(dirname,"nrf52");
    if(isempty(k)||(length(dirname)-k > 12)) % wrong path is selected, try again
        if(dirname == 0) %terminate execution if cancel is pressed
            return;
        end
        uiwait(warndlg("Please select the correct chip folder.","Warning"));
    else % correct path is selected
        dirvalid = true;
    end
end

%% Enrollment parameter selection
parvalid = false;
while(~parvalid)
    selw = input("Which method to execute? [1 = HW, 2 = DHW]\n");
    seln = input("Input word width <n>\n");
    switch(selw)
        case 1
            selth = input("Input threshold <¦È>\n");
            parvalid = true;
        case 2
            selm = input("Input group size <m>\n");
            seld = input("Input distance <¦Ä>\n");
            parvalid = true;
        otherwise
    end
    selEnro = input("Select a enrollment strategy? [0 = specify a range,1 = singleReadout, 2~100 = majority voting]\n");
    if(selEnro<0 || selEnro > FTotalNum)
        warning("enrollment strategy con't be smaller than 1 or greater than %d\n", FTotalNum);
        parvalid = false;
        continue;
    end
    selEnroRang = [0, selEnro-1];
    if(selEnro == 0)
        selEnroRang = input("specify range of file to be used for enrollment, e.g. 1 10\n",'s');
        selEnroRang = sscanf(selEnroRang,"%d",[1 2]);
    end
    
    Tstart = 2;
    Tend = 2;
    Tskip = [];
    selv = input("Which temperature to use? [1 = N15, 2 = 25C, 3 = 80C, 12 = N15+25C, 23 = 25C+80C, 13 = N15+80C, 123 = N15~80C]\n");
    switch(selv)
        case 1
            Tstart = 1;
            Tend = 1;
            Tskip = [];
            parvalid = true;
        case 2
            Tstart = 2;
            Tend = 2;
            Tskip = [];
            parvalid = true;
        case 3
            Tstart = 3;
            Tend = 3;
            Tskip = [];
            parvalid = true;
        case 12
            Tstart = 3;
            Tend = 3;
            Tskip = [];
            parvalid = true;
        case 13
            Tstart = 3;
            Tend = 3;
            Tskip = [Tskip,2];
            parvalid = true;
        case 23
            Tstart = 3;
            Tend = 3;
            Tskip = [];
            parvalid = true;
        case 123
            Tstart = 3;
            Tend = 3;
            Tskip = [];
            parvalid = true;
        otherwise
    end
end

%% create output file
% single readout
Fout_mask = fopen('./OUT/device.h','wt');%header file to be implemented on device
Fout_db = fopen('./OUT/db.h','wt');%database of enrolled data.

%% calculate HW, single or majority volting
PUF_start = SYS_RESV/(seln/8); %starting address of PUF
for Tidx = Tstart:Tend
   if(ismember(Tidx,Tskip)) % skip undesired temperature
      continue; 
   end
   HW = [];
   for Fidx = selEnroRang(1):selEnroRang(2)
       path = sprintf("%s\\%s\\TEST_%d.bin",dirname,T_NAME(Tidx),Fidx);
       HW = [HW,HWreadFull(path,seln)];
   end
   HW_MajVote = mean(HW,2);
end

switch(selw)
        case 1 %HW
            HWout(HW_MajVote,RAM_BASE,RAM_SZ,SYS_RESV,dirname,seln,selth);
        case 2 %DHW
            DHWout(HW_MajVote,RAM_BASE,RAM_SZ,SYS_RESV,dirname,seln,selm,seld);
        otherwise
end