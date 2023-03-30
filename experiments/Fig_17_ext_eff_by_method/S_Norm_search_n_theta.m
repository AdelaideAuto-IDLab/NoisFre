% this script is the first step of "What is the lowest key failure rate achievable for a 128
% z bit key from each memory technology and manufac-
% turer?"

clear;
clc;
n_max = 128;
BER_f = 0.0609;
C_SZ = 64;
PKF_Table = NaN(n_max,1);
theta_Table = NaN(n_max,1);
NRF_n_theta_PKF = NaN(n_max,4);

for n = 1:2:n_max
        [theta_Table(n), PKF_Table(n)] = binSearch10e_6(BER_f,n);
        [mt,sz] = meet128b(C_SZ,n,theta_Table(n));
        NRF_n_theta_PKF(n,:) = [n,theta_Table(n),PKF_Table(n),sz];
end
NRF_n_theta_PKF = NRF_n_theta_PKF(~any(ismissing(NRF_n_theta_PKF),2),:);

EXT_S = NRF_n_theta_PKF(:,4);
EXT_S = EXT_S(EXT_S~=0)./C_SZ;
histfit(EXT_S);

save("./PKF_Table_S_norm.mat")
return;

%% search for 10e-6 corssing point
function [theta_cross, pkf] = binSearch10e_6(BER_f,n) 
    theta_start = 1;
    theta_end = n;
    pkf = 1;
    theta_cross = 0;
    theta_mid = 0;
    while (theta_end - theta_start > 2)
        theta_mid = round((theta_start + theta_end)/2);
        pkf = compPkf128(BER_f,n,theta_mid);
        if(pkf > 1e-6)
            theta_start = theta_mid;
        else
            theta_end = theta_mid;
        end
    end
    while(pkf > 1e-6)
        theta_mid = theta_mid + 1;
        pkf = compPkf128(BER_f,n,theta_mid);
    end
    theta_cross = theta_mid;
end

%% this fucntion determines whetehr a given chip under such given parameter
% could provide more than 128 bit key
function [mt,key_SZ] = meet128b(C_SZ_f,n_f,theta_f)
    bit_per_kbyte = (1/n_f)*(1 - binocdf(theta_f+floor(n_f/2),n_f,0.5) + binocdf(ceil(n_f/2)-theta_f-1,n_f,0.5))*(1024*8);
    key_SZ = C_SZ_f * bit_per_kbyte;
    if(key_SZ>=128)
        mt = true;
    else
        mt = false;
    end
end

%% this function calculates the 128-bit key failure rate of a giver chip 
% under such gicen parameter
function pkf128 = compPkf128(BER_f_f,n_f_f,theta_f)
    RF = 0;
    for i=0:floor(n_f_f/2)-theta_f
        P1 = 1 - binocdf(theta_f+i,ceil(n_f_f/2)+theta_f,BER_f_f);
        P2 = binopdf(i,floor(n_f_f/2)-theta_f,BER_f_f);
        RF = P1*P2 + RF; % response failure rate
    end
    pkf128 = 1-(1-RF)^128;
end