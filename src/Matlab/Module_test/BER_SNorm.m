clear all;
clc;

n = 31;
th = 12;
EqnBER = 0.0609;
k = 128;

 %% calculated by equation
        % error rate
        RF = 0;
        for i=0:floor(n/2)-th
            P1 = 1 - binocdf(th+i,ceil(n/2)+th,EqnBER);
            P2 = binopdf(i,floor(n/2)-th,EqnBER);
            RF = P1*P2 + RF; % response failure rate
        end
        BER_F = RF;
pkf = 1-(1-BER_F)^k;