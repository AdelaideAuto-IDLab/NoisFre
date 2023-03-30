%Created by Garrison Yang
%Current Version 2019.08.14

clear all;
close all;
clc;

% n_list=[8 16 24 32 40 48 56 64];
% n_list=[8 16 32 64];
n_list=[32];
% n_list=[40 48 56 64];
idxn=0;
idxm = 16; % number of HW to get one e

Nrep = 10;

EqnBER = 0.0609;
RandBER = 0.0609;

% unified big chip over all 11 chips
folder ='../BIG/';
Rfolder = '../RAND/';

for idxn = 1:length(n_list)
    n = n_list(idxn);

    er_vector = zeros([n,1]);
    e2_vector = zeros([n,1]);
    ec_vector = zeros([n,1]);
    
    srr_vector = zeros([n,1]);
    sreq_vector = zeros([n,1]);
    src_vector = zeros([n,1]);
    
    d_vector = zeros([n,1]);
    
    %% read the NRF chip Union 11 chips
    path=sprintf('%s/25C/TEST_%d.bin',folder,99);
    [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n,'SEQ');
    path=sprintf('%s/80C_15M/TEST_%d.bin',folder,99);
    [ChhipHW_reg,bitmap_reg]=HWOnlyRead(path,n,'SEQ');
    errorBit = length(find(bitmap_ref~=bitmap_reg));%number of error bits
    [k1,k2] = size(bitmap_reg);%dimention of SRAM
    totalBit = k1*k2;%total bits of SRAM
    ChipBER = errorBit/totalBit;
    
        %% calculated by equation
    for idxd = 1:n-1
        RF = 0;
        for i=0:n-idxd
            P1 = 1 - binocdf(idxd+i-1,n+idxd,EqnBER);
            P2 = binopdf(i,n-idxd,EqnBER);
            RF = P1*P2 + RF; % response failure rate
        end
        BER_equ = RF;
       
        Pkey_eq = 1 - (1-BER_equ).^128
        if Pkey_eq < 1e-6
            IndexFirst = idxd
            Nsample = 10^5; %Eq of selection rate also requires samples, increase this number can avoid variance.
            Nsel = SelRateDHW(n,idxm,idxd,Nsample);
            %     sreq_vector (idxd) = Nsel/Nsample/totalBit*1024*8;
            SRe_eq = Nsel/Nsample/n/idxm*1024*8
            break;
        end
        
    end      
       
%     for idxd = 1:IndexFirst-1
    for idxd = 1:IndexFirst
        d_vector(idxd) = idxd;
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
        for rep = 1:Nrep
            path=sprintf('%s/80C_15M/TEST_%d.bin',folder,rep-1);
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

    end

end

%%
% Pkey_eq = 1 - (1-e2_vector).^128;
% Index_eq = find(Pkey_eq < 1e-6);
% 
% FirstIndex_eq = Index_eq(1)
% BERe_eq = e2_vector(FirstIndex_eq)
% SRe_eq = sreq_vector(FirstIndex_eq)

Pkey_c = 1 - (1-ec_vector).^128;
Index_c = find(Pkey_c < 1e-3);

FirstIndex_c = Index_c(1)
BERe_c = ec_vector(FirstIndex_c)
SRe_c = src_vector(FirstIndex_c)

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