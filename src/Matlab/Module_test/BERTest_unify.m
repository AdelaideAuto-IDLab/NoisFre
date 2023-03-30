clear all
close all
clc

chiplist = ["nrf52_296ED4","nrf52_296EFE","nrf52_296ECB","nrf52_298624","nrf52_296E98",...
            "nrf52_2985ED","nrf52_29863A","nrf52_298641","nrf52_29861C","nrf52_298608",...
            "nrf52_298619","nrf52_298644"];
folder ='../SRAM_DATA';
Nrep = 50;
% for idx_chip=1:length(chiplist)
for idx_chip=1:12
    ChipID = chiplist(idx_chip);
    IntraHD = zeros(5,Nrep);
    path=sprintf('%s/%s/80C_60M/TEST_%d.bin',folder,ChipID,0);
    ft = fopen(path,'rb');
    if (ft ~= -1)
        %% Use 80C_60M as reference test 80C_60M
        for i=1:Nrep
            path=sprintf('%s/%s/80C_60M/TEST_%d.bin',folder,ChipID,i-1);
            Res_ref =  ResRead(path);
            path=sprintf('%s/%s/80C_60M/TEST_%d.bin',folder,ChipID,i+50-1);
            Res_reg =  ResRead(path);

            IntraHD(5,i) = pdist2(Res_ref,Res_reg,'hamming');
        end
        %% Use 25C as reference test 80C_60M
        for i=1:Nrep
            path=sprintf('%s/%s/25C/TEST_%d.bin',folder,ChipID,i-1);
            Res_ref =  ResRead(path);
            path=sprintf('%s/%s/80C_60M/TEST_%d.bin',folder,ChipID,i-1);
            Res_reg =  ResRead(path);

            IntraHD(4,i) = pdist2(Res_ref,Res_reg,'hamming');
        end
    end
    %% Use 80C_15M as reference test 80C_15M
    for i=1:Nrep
        path=sprintf('%s/%s/80C_15M/TEST_%d.bin',folder,ChipID,i-1);
        Res_ref =  ResRead(path);
        path=sprintf('%s/%s/80C_15M/TEST_%d.bin',folder,ChipID,i+50-1);
        Res_reg =  ResRead(path);

        IntraHD(3,i) = pdist2(Res_ref,Res_reg,'hamming');
    end
    %% Use 20C as reference test 80C_15M
    for i=1:Nrep
        path=sprintf('%s/%s/25C/TEST_%d.bin',folder,ChipID,i-1);
        Res_ref =  ResRead(path);
        path=sprintf('%s/%s/80C_15M/TEST_%d.bin',folder,ChipID,i+50-1);
        Res_reg =  ResRead(path);

        IntraHD(2,i) = pdist2(Res_ref,Res_reg,'hamming');
    end
    %% 25C internal test
    for i=1:Nrep
        path=sprintf('%s/%s/25C/TEST_%d.bin',folder,ChipID,i-1);
        Res_ref =  ResRead(path);
        path=sprintf('%s/%s/25C/TEST_%d.bin',folder,ChipID,i+50-1);
        Res_reg =  ResRead(path);

        IntraHD(1,i) = pdist2(Res_ref,Res_reg,'hamming');
    end
    mean25C25C = mean(IntraHD(1,:))*100;
    max25C25C = max(IntraHD(1,:))*100;
    min25C25C = min(IntraHD(1,:))*100;
    mean25C80C_15M = mean(IntraHD(2,:))*100;
    max25C80C_15M = max(IntraHD(2,:))*100;
    min25C80C_15M = min(IntraHD(2,:))*100;
    mean80C_15M80C_15M = mean(IntraHD(3,:))*100;
    max80C_15M80C_15M = max(IntraHD(3,:))*100;
    min80C_15M80C_15M = min(IntraHD(3,:))*100;
    mean25C80C_60M = mean(IntraHD(4,:))*100;
    max25C80C_60M = max(IntraHD(4,:))*100;
    min25C80C_60M = min(IntraHD(4,:))*100;
    mean80C_60M80C_60M = mean(IntraHD(5,:))*100;
    max80C_60M80C_60M = max(IntraHD(5,:))*100;
    min80C_60M80C_60M = min(IntraHD(5,:))*100;
    fprintf("=====Chip %d = %s =====\n",idx_chip,ChipID);
    fprintf("[25C vs 25C]\n");
    fprintf("BER.mean = %.2f %c,BER.max = %.2f %c,BER.min = %.2f %c. \n",mean25C25C,'%',max25C25C,'%',min25C25C,'%');
    fprintf("[25C vs 80C_15M]\n");
    fprintf("BER.mean = %.2f %c,BER.max = %.2f %c,BER.min = %.2f %c. \n",mean25C80C_15M,'%',max25C80C_15M,'%',min25C80C_15M,'%');
    fprintf("[80C_15M vs 80C_15M]\n");
    fprintf("BER.mean = %.2f %c,BER.max = %.2f %c,BER.min = %.2f %c. \n",mean80C_15M80C_15M,'%',max80C_15M80C_15M,'%',min80C_15M80C_15M,'%');
    if (ft ~= -1)
        fprintf("[25C vs 80C_60M]\n");
        fprintf("BER.mean = %.2f %c,BER.max = %.2f %c,BER.min = %.2f %c. \n",mean25C80C_60M,'%',max25C80C_60M,'%',min25C80C_60M,'%');
        fprintf("[80C_60M vs 80C_60M]\n");
        fprintf("BER.mean = %.2f %c,BER.max = %.2f %c,BER.min = %.2f %c. \n",mean80C_60M80C_60M,'%',max80C_60M80C_60M,'%',min80C_60M80C_60M,'%');
    end
end %chip transverse

% Nrep = 100;
% Res_reg = zeros(Nrep,64*1024*8*12);
% for i=1:Nrep
%     path=sprintf('%s/80C_15M/TEST_%d.bin',folder,i-1);
%     [ChhipHW_ref,bitmap]=HWOnlyRead(path,n+1,'SEQ');
%     Res_reg(i+1,:) =  bitmap(:)';
% end
% 
% for i = 1:Nrep
%     IntraHD(i)=pdist2(Res_ref(i,:),Res_reg(i,:),'hamming');
% end

% % 
% % IntraHD = pdist(res,'hamming');

%IntraHD = [0.0764519373575846,0.0751086870829264,0.0750656127929688,0.0750699043273926,0.0750420888264974,0.0751530329386393,0.0750454266866048,0.0750867525736491,0.0751088460286458,0.0752129554748535,0.0750578244527181,0.0751086870829264,0.0751032829284668,0.0750697453816732,0.0752271016438802,0.0751209259033203,0.0750931104024251,0.0752046902974447,0.0751516024271647,0.0752499898274740,0.0751550992329915,0.0752681096394857,0.0751182238260905,0.0750875473022461,0.0751177469889323,0.0751825968424479,0.0752512613932292,0.0751630465189616,0.0752415657043457,0.0752080281575521,0.0751668612162272,0.0751852989196777,0.0752795537312826,0.0751825968424479,0.0752420425415039,0.0751913388570150,0.0751841862996419,0.0752058029174805,0.0752056439717611,0.0751948356628418,0.0750614802042643,0.0752725601196289,0.0751736958821615,0.0751751263936361,0.0751843452453613,0.0751824378967285,0.0751535097757975,0.0752051671346029,0.0751883188883464,0.0751461982727051,0.0752828915913900,0.0752668380737305,0.0751902262369792,0.0752159754435221,0.0752555529276530,0.0752372741699219,0.0753118197123210,0.0751500129699707,0.0752471288045247,0.0753359794616699,0.0753305753072103,0.0752801895141602,0.0752061208089193,0.0752236048380534,0.0751342773437500,0.0751851399739583,0.0752544403076172,0.0753650665283203,0.0751943588256836,0.0753199259440104,0.0753056208292643,0.0763640403747559,0.0752396583557129,0.0753030776977539,0.0754073460896810,0.0752760569254557,0.0751523971557617,0.0752668380737305,0.0752218564351400,0.0752363204956055,0.0752936999003093,0.0751910209655762,0.0752585728963216,0.0752758979797363,0.0752681096394857,0.0752765337626139,0.0752560297648112,0.0753305753072103,0.0751819610595703,0.0753165880839030,0.0752550760904948,0.0752466519673665,0.0753006935119629,0.0751682917277018,0.0751441319783529,0.0751932462056478,0.0751830736796061,0.0752387046813965,0.0751579602559408,0.0752116839090983]

% nrf52_296EFE 16.8%
% nrf52_2985ED 14.5%
% nrf52_29861C 4.6%
% nrf52_29863A 4.9%
% nrf52_298608 4.7%
% nrf52_298619 4.7%
% nRF52_298624 4.5%
% nrf52_298641 10%
% nrf52_298644 5.4%

function data = ResRead(FileName)
    fs = fopen(FileName,'rb');
    chip = fread(fs,'ubit8');
    fclose(fs);
    PUFDataBit = de2bi(chip,8,'left-msb');
    PUFDataBit = PUFDataBit';
    data = PUFDataBit(:)';
end