clear all;

close all;

clc;

RAND = 0.5;

delta0 = 1;
delta = 16; %16

n = 32;
SRAM_byte = 128*1024;
nbyte = n/8;
SRAM_word = SRAM_byte/nbyte;

m = 32;
vector_m = 2:m;
vector_5 = zeros(delta,m-1);
vector_5_BKB = zeros(delta,m-1);
vector_rand_BKB = zeros(delta,m-1);

%SRAM = randi([0 1], SRAM_sz/n,n); % randommly generate 64K data
SRAM = binornd(1,RAND,[SRAM_word,n]);
for idxd = delta0:delta
    for idxm = 2:m
        fprintf('\n===== m = %d =====\n',idxm);
        
        SR_DHW = Pa(idxd,n,idxm);
        fprintf('DHW selection rate estimation using Equaiton. (5)= ');
        disp(SR_DHW);
        vector_5(idxd,idxm-1) = SR_DHW;
        vector_5_BKB(idxd,idxm-1) = SR_DHW*(1/(idxm*n))*1024*8;
        
        %% validate the formula with random data
        HW = sum(SRAM,2);
        e = [];
        DHWfirst = [];
        DHWsecond = [];
        k = 0; 
        b = 0;%k is the number of m*n blocks
        for i = 1:idxm:length(HW)-(idxm-1)
            [maxHW maxI] = max(HW(i:i+idxm-1));
            [minHW minI] = min(HW(i:i+idxm-1));
            b = b + 1;
            if(maxHW - minHW >= idxd) 
                if(maxI < minI) % if max has smaller index
                   e = [e 1];
                   DHWfirst = [DHWfirst i+maxI];
                   DHWsecond = [DHWsecond i+minI];

                else
                   e = [e 0];
                   DHWfirst = [DHWfirst i+minI];
                   DHWsecond = [DHWsecond i+maxI];
                end
                k = k + 1;
            end
        end
        rand_SR = (length(e)/b);
        fprintf('DHW wining rate Random test = %d/%d = %f\n',length(e),b,rand_SR);
        vector_rand(idxd,idxm-1) = rand_SR;
        vector_rand_BKB(idxd,idxm-1) = rand_SR*(1/(idxm*n))*1024*8;
    end
    figure(1);
    subplot(ceil(delta/4),4,idxd);
    plot(vector_m,vector_5(idxd,:),vector_m,vector_rand(idxd,:),'--');
    sttr = '';
    sttr = sprintf('d = %d',idxd);
    title(sttr);
    legend('Eqn (5)','Rand test');
    ylim([0 1]);
    ylabel('Pa probability group is selected');
    xlabel('m trails');
    
    figure(2);
    subplot(ceil(delta/4),4,idxd);
    plot(vector_m,vector_5_BKB(idxd,:),vector_m,vector_rand_BKB(idxd,:),'--');
    sttr = '';
    sttr = sprintf('delta = %d',idxd);
    title(sttr);
    legend('Eqn (5)','Rand test');
    ylabel('SR_{DHW} (bit/KiB)');
    xlabel('m words per group');
end
figure();
mesh(vector_5_BKB,'EdgeColor', 'b');
hold on
mesh(vector_rand_BKB,'EdgeColor', 'r');
ylabel('Selection condition $\theta$','interpreter','latex','FontSize',18);
xlabel('Words per block $m$','interpreter','latex','FontSize',18);
zlabel('Selection efficiency $\eta_{DNorm}$','interpreter','latex','FontSize',18);
legend('Predition','Simulation');