clear;
close;
clc;
%% constants
N = 20; % a n-sided die
M = N;
D = N;
%% variables
Pwin = NaN(D,M);
%% calculation
for idxd = 1:N % a judgement number n to shout out
    for idxm = 2:N % trail number m up to n 
        Pwin(idxd,idxm) = Pa(idxd,N,idxm);
   end
end

%% random test
poll = 10000; % repeat 10000 round of game
dice = randi(N,[1,poll]);

Prand = NaN(D,M);
for idxd = 1:N
    for idxm = 2:M
        k = 0; %k is the round wining
        b = 0; %b is the number of round played
        for i = 1:idxm:length(dice)-(idxm-1)
            [maxHW maxI] = max(dice(i:i+idxm-1));
            [minHW minI] = min(dice(i:i+idxm-1));
            b = b + 1;
            if(maxHW - minHW >= idxd) 
                k = k + 1;
            end
        end
        Prand(idxd,idxm) = (k/b);
    end
end

%% plot the Pwin
figure(1);
vector_m = 2:M;
for idxd = 1:N
    subplot(ceil(D/4),4,idxd);
    plot(vector_m,Pwin(idxd,2:M),vector_m,Prand(idxd,2:M));
    sttr = '';
    sttr = sprintf('d = %d',idxd);
    title(sttr);
    legend('Eqn.','Rand test');
    ylim([0 1]);
    ylabel('Pwin');
    xlabel('m trails');
end

%%plot the Pwin*d
% if you play many times, average money win 
figure(2);
vector_m = 2:M;
for idxd = 1:N
    subplot(ceil(D/4),4,idxd);
    plot(vector_m,Pwin(idxd,2:M)*idxd,vector_m,Prand(idxd,2:M)*idxd);
    sttr = '';
    sttr = sprintf('d = %d',idxd);
    title(sttr);
    legend('Eqn.','Rand test');
    ylabel('Pwin*d');
    xlabel('m trails');
end

%%plot the (Pwin*d) - (m-1) 
% net wining, money win deduct you spent
figure(3);
vector_m = 2:M;
for idxd = 1:N
    subplot(ceil(D/4),4,idxd);
    plot(vector_m,(Pwin(idxd,2:M)*idxd - (vector_m-1)),vector_m,(Prand(idxd,2:M)*idxd) - (vector_m-1));
    sttr = '';
    sttr = sprintf('d = %d',idxd);
    title(sttr);
    legend('Eqn.','Rand test');
    ylabel('(Pwin*d)-(m-1)');
    xlabel('m trails');
end