%Created by Garrison Yang
%Current Version 2019.08.14

clear all;
close all;
clc;

% n_list=[8 16 24 32 40 48 56 64];
n_list=[8 16 32 64];
% n_list=[32];
% n_list=[40 48 56 64];
idxn=0;
idxm = 4; % number of HW to get one e

Nrep = 10;

EqnBER = 0.0609;
RandBER = 0.0609;

% unified big chip over all 11 chips
folder ='../BIG/';
Rfolder = '../BIGR/';

for idxn = 1:length(n_list)
    n = n_list(idxn);
%     er_vector = zeros([floor(n/2),1]);
%     e2_vector = zeros([floor(n/2),1]);
%     ec_vector = zeros([floor(n/2),1]);
%     
%     srr_vector = zeros([floor(n/2),1]);
%     sreq_vector = zeros([floor(n/2),1]);
%     src_vector = zeros([floor(n/2),1]);
%     
%     d_vector = zeros([floor(n/2),1]);

    er_vector = zeros([n,1]);
    e2_vector = zeros([n,1]);
    ec_vector = zeros([n,1]);
    
    uni_vector = zeros([n,1]);
    
    srr_vector = zeros([n,1]);
    sreq_vector = zeros([n,1]);
    src_vector = zeros([n,1]);
    
    d_vector = zeros([n,1]);
    
    %% read the NRF chip Union 11 chips
    path=sprintf('%s25C/TEST_%d.bin',folder,7);
    [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n,'SEQ');
    path=sprintf('%s80C_15M/TEST_%d.bin',folder,8);
    [ChhipHW_reg,bitmap_reg]=HWOnlyRead(path,n,'SEQ');
    errorBit = length(find(bitmap_ref~=bitmap_reg));%number of error bits
    [k1,k2] = size(bitmap_reg);%dimention of SRAM
    totalBit = k1*k2;%total bits of SRAM
    ChipBER = errorBit/totalBit;
    
     %% simulate the reference response and regenerated response
    path=sprintf('%s25C/TEST_%d.bin',Rfolder,0); %must use 0, since 0 is reference, BER between any two regenerated respoonse may exceed the set probability
    [RandHW_ref,bitmap_ref]=HWOnlyRead(path,n,'SEQ');
    path=sprintf('%s25C/TEST_%d.bin',Rfolder,4);
    [RandHW_reg,bitmap_reg]=HWOnlyRead(path,n,'SEQ');
    errorBit = length(find(bitmap_ref~=bitmap_reg));%number of error bits
    [k1,k2] = size(bitmap_reg);%dimention of SRAM
    totalBit = k1*k2;%total bits of SRAM
    BER_raw = errorBit/totalBit;
        
        
        
    for idxd = 1:n-1
        d_vector(idxd) = idxd;
        %% Simulate the BER of the selected reliable reformed response
        HW_ref = RandHW_ref; %word HW
        HW_reg = RandHW_reg;
        e = -1*ones([length(HW_reg),1]);                                                                 % array to store reformed response e
        DHWfirst = -1*ones([length(HW_reg),1]);                                                          % array to store the first extreme value
        DHWsecond = -1*ones([length(HW_reg),1]);                                                         % array to store the second extreme value
        k = 1;
        for i = 1:idxm:length(HW_reg)-(idxm-1)
            [maxHW,maxI] = max(HW_ref(i:i+idxm-1));
            [minHW,minI] = min(HW_ref(i:i+idxm-1));
            if(maxHW - minHW >= idxd)                                           %check against delta
                if(maxI < minI) % if max has smaller index
                   e(k) = 1;
                   DHWfirst(k) = i+maxI-1;
                   DHWsecond(k) = i+minI-1;
                else
                   e(k) = 0;
                   DHWfirst(k) = i+minI-1;
                   DHWsecond(k) = i+maxI-1;
                end
                k = k + 1;
            end
        end
        e = e(e~=-1);
        DHWfirst = DHWfirst(DHWfirst~=-1);
        DHWsecond = DHWsecond(DHWsecond~=-1);
        e_ref = HW_ref(DHWfirst) - HW_ref(DHWsecond)>0;
        %% repeat Nrep-1 times  
        for rep=1:Nrep-1 %noting that the reference is 0, the rest (Nrep - 1) times are used for average
            path=sprintf('%s25C/TEST_%d.bin',Rfolder,Nrep);
            [RandHW_reg,bitmap_reg]=HWOnlyRead(path,n,'SEQ');
            
            e_reg = HW_reg(DHWfirst) - HW_reg(DHWsecond)>0;
            if isempty(e_ref)|| isempty(e_reg)
                BER_reform = -1;
            else
                BER_reform = pdist2(double(e_ref)',double(e_reg)','hamming');
            end
            if BER_reform == 0
                BER_reform = 1e-18;
            end
            
            er_vector(idxd) = BER_reform + er_vector(idxd);
            srr_vector (idxd) = length(e_reg)/totalBit*1024*8 + srr_vector(idxd);
        end
        er_vector(idxd) = er_vector(idxd)/(Nrep-1);
        srr_vector (idxd) = srr_vector(idxd)/(Nrep-1);
        %% Chip test
        HW_ref = ChhipHW_ref; %word HW
        HW_reg = ChhipHW_reg;
        e = -1*ones([length(HW_reg),1]);                                                                 % array to store reformed response e
        DHWfirst = -1*ones([length(HW_reg),1]);                                                          % array to store the first extreme value
        DHWsecond = -1*ones([length(HW_reg),1]);                                                         % array to store the second extreme value
        k = 1;
        for i = 1:idxm:length(HW_reg)-(idxm-1)
            [maxHW,maxI] = max(HW_ref(i:i+idxm-1));
            [minHW,minI] = min(HW_ref(i:i+idxm-1));
            if(maxHW - minHW >= idxd)                                           %check against delta
                if(maxI < minI) % if max has smaller index
                   e(k) = 1;
                   DHWfirst(k) = i+maxI-1;
                   DHWsecond(k) = i+minI-1;

                else
                   e(k) = 0;
                   DHWfirst(k) = i+minI-1;
                   DHWsecond(k) = i+maxI-1;
                end
                k = k + 1;
            end
        end
        e = e(e~=-1);
        DHWfirst = DHWfirst(DHWfirst~=-1);
        DHWsecond = DHWsecond(DHWsecond~=-1);
        e_ref = HW_ref(DHWfirst) - HW_ref(DHWsecond)>0;
        uni_vector(idxd) = sum(e_ref)/length(e_ref);
        for rep = 1:Nrep
            path=sprintf('%s80C_15M/TEST_%d.bin',folder,rep-1);
            [ChhipHW_reg,bitmap_reg]=HWOnlyRead(path,n,'SEQ');
            e_reg = HW_reg(DHWfirst) - HW_reg(DHWsecond)>0;
            if isempty(e_ref)|| isempty(e_reg)
                BER_reform = -1;
            else
                BER_reform = pdist2(double(e_ref)',double(e_reg)','hamming');
            end
            if BER_reform == 0
                BER_reform = 1e-18;
            end
            
            ec_vector(idxd) = BER_reform + ec_vector(idxd);
            src_vector (idxd) = length(e_reg)/totalBit*1024*8 + src_vector (idxd);
        end
        ec_vector(idxd) = ec_vector(idxd)/Nrep;
        src_vector (idxd) = src_vector (idxd)/Nrep;
    %% calculated by equation
    RF = 0;
    for i=0:n-idxd
        P1 = 1 - binocdf(idxd+i-1,n+idxd,EqnBER);
        P2 = binopdf(i,n-idxd,EqnBER);
        RF = P1*P2 + RF; % response failure rate
    end
    BER_equ = RF;
    

    e2_vector(idxd) = BER_equ;
    Nsample = 10^4; %Eq of selection rate also requires samples, increase this number can avoid variance.
    Nsel = SelRateDHW(n,idxm,idxd,Nsample);
%     sreq_vector (idxd) = Nsel/Nsample/totalBit*1024*8;
    sreq_vector (idxd) = Nsel/Nsample/n/idxm*1024*8;
        
    %% compre rand test and the equaiton    
    expected = 'No';
    if BER_reform <= BER_equ
        expected = 'Yes';
    end
    fprintf('For n = %d, theta = %d: ',n,idxd);
    fprintf('Reformed e fail = %f,Eqn.(2) e fail= %f, Expected = %s.\n',BER_reform,BER_equ,expected);
    end
    
    %% plot
    figure(1)
    subplot(ceil(length(n_list)/4)*2,4,idxn);
    semilogy(d_vector,e2_vector,d_vector,er_vector,'-.',d_vector,ec_vector,'--');
    legend('Prediction','Simulation','Measurement','FontSize',18);
    s = sprintf('n = %d',n);
    xlabel('Distance \theta','FontSize',18);
    ylabel('BER_{F}','FontSize',18);
    title(s,'FontSize',14);
    xlim([1, max(d_vector)]);
    ylim ([1e-19,1]);
    txt = '0';
    text(0.5,1e-18,txt);
    
    subplot(ceil(length(n_list)/4)*2,4,idxn+4);
    bar_y = [sreq_vector';srr_vector';src_vector']';
    bar(d_vector,bar_y,'group');
%     set(gca,'YScale','log');
%     ytickformat('percentage');
    legend('Prediction','Simulation','Measurement','FontSize',18);
    s = sprintf('n = %d',n);
    title(s,'FontSize',14);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('\eta_{diff} (bit/Kbyte)','FontSize',18);
    xlim([1-0.5, max(d_vector)+0.5]);
end

function Nsel = SelRateDHW(n,m,threshold,Nsample)
    % n = 16;
    % m = 6;
    % threshold = 6;

    bias = 0.5;
    P_HW = zeros(n+1,1);
    population = zeros(n+1,1);
    for i = 0:n
        P_HW(i+1)=binopdf(i,n,bias);
        population(i+1)=i;
    end

    % Nsample = 10^2;
    k = 0;
    for j=1:Nsample
        mHW = randsample(population,m,true,P_HW);

        if max(mHW)-min(mHW)>=threshold
            k=k+1;
        end
    end
    Nsel = k;
end






