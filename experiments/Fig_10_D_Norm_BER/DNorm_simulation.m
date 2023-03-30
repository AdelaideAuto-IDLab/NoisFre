%simulation for equation 4
clear all;
close all;
clc;

n_list=[8 16 32 64];
n = n_list(4);
m = 4;

RawBER = 0.0609;
Key_len = 128;
Sim_chip_sz = {'64K','128K','256K','512K','1M','2M','4M','8M','16M'};
Sim_chip_dir = './Rand_CHIP/';
Sim_chip_idx = 1;

Repeat_times = 1e6;

for n_idx = 1:length(n_list)
    fprintf('n=%d\n',n_list(n_idx));
    n = n_list(n_idx);
    %% variable initialization
    Bit_err_counter = zeros(Key_len,1);
    BER = zeros(n,2);
    SR = zeros(n,2);
    th_vector = zeros(n,1);


    for theta = 1:n
        th_vector(theta) = theta;
        fprintf('\ttheta=%d\n',theta);
    while(true)
        %% read the reference chip #0
        path=sprintf('%s%s/TEST_0.bin',Sim_chip_dir,char(Sim_chip_sz(Sim_chip_idx)));
        [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n,'SEQ');
        bitmap_ref_bin = cast(bitmap_ref,'logical');
        clear bitmap_ref;
        S_Norm_ref = cast(ChhipHW_ref,'uint8');
        %% Selection D-Norm generate mask
        
        D_Norm_mask = -1*ones([length(ChhipHW_ref),2]);
        k = 0;
        for i = 1:m:length(ChhipHW_ref)-(m-1)
            [maxHW,maxI] = max(ChhipHW_ref(i:i+m-1));
            [minHW,minI] = min(ChhipHW_ref(i:i+m-1));
            if(maxHW - minHW >= theta)%check against theta
                k = k + 1;
                if(maxI < minI) % if max has smaller index
                   D_Norm_mask(k,1) = i+maxI-1;
                   D_Norm_mask(k,2) = i+minI-1;
                else
                   D_Norm_mask(k,1) = i+minI-1;
                   D_Norm_mask(k,2) = i+maxI-1;
                end
            end
        end

        
        %% check key length
        D_Norm_mask = D_Norm_mask(1:k,:);
        if(Sim_chip_idx+1 > length(Sim_chip_sz))
            warning('Not enough chip size');
            return;
        else
            if(length(D_Norm_mask)<Key_len)
                Sim_chip_idx = Sim_chip_idx+1;
            else
                D_Norm_mask_clip_ken_leng = D_Norm_mask(1:Key_len,:); % calip according to the key length
                break;
            end
        end
    end

    %% package selected mask
    D_Norm_mask_selected_HW = ChhipHW_ref(D_Norm_mask_clip_ken_leng);
    D_Norm_mask_selected_bits_first = bitmap_ref_bin(D_Norm_mask_clip_ken_leng(:,1),:);
    D_Norm_mask_selected_bits_second = bitmap_ref_bin(D_Norm_mask_clip_ken_leng(:,2),:);
    F_DNorm = ChhipHW_ref(D_Norm_mask_clip_ken_leng(:,1))>=ChhipHW_ref(D_Norm_mask_clip_ken_leng(:,2));
    DNorm_SR = (length(D_Norm_mask)*m)/length(ChhipHW_ref);
    SR(theta,2) = DNorm_SR;

    Bit_err_counter = zeros(Key_len,1);
    tic;
    parfor rep_idx = 1:Repeat_times
        %% apply noise
        binoNoise_mask_first = binornd(1,RawBER,size(D_Norm_mask_selected_bits_first));
        D_Norm_reg_bits_first = xor(D_Norm_mask_selected_bits_first,binoNoise_mask_first);
        binoNoise_mask_second = binornd(1,RawBER,size(D_Norm_mask_selected_bits_second));
        D_Norm_reg_bits_second = xor(D_Norm_mask_selected_bits_second,binoNoise_mask_second);

        %% convert to HW
        HW_reg_first = sum(D_Norm_reg_bits_first,2);
        HW_reg_second = sum(D_Norm_reg_bits_second,2);
        F_SNorm_reg = HW_reg_first >= HW_reg_second;
        F_diff = F_DNorm~=F_SNorm_reg;
        Bit_err_counter = Bit_err_counter + F_diff;

    end
    time = toc;

        %% calculate BER_F
        BER_sim = mean(Bit_err_counter)/Repeat_times;
        BER(theta,1) = BER_sim;

    %% calculated by equation
        % error rate
        RF = 0;
        for i=0:n-theta
            P1 = 1 - binocdf(theta+i-1,n+theta,RawBER);
            P2 = binopdf(i,n-theta,RawBER);
            RF = P1*P2 + RF; % response failure rate
        end
        BER_equ = RF;
        BER(theta,2) = BER_equ;
        %selection rate
        SR(theta,1) = 1 - binocdf(theta+floor(n/2),n,0.5) + binocdf(ceil(n/2)-theta-1,n,0.5);
        
        Nsample = 10^4; %Eq of selection rate also requires samples, increase this number can avoid variance.
        Nsel = SelRateDHW(n,m,theta,Nsample);
        SR(theta,1) = (Nsel/Nsample);
        if(BER_equ <= 1e-6)
            break;
        end
    end

    %% plot BER
    figure(1);
    subplot(ceil(length(n_list)/2),2,n_idx);
    plot(BER(:,2),'b-');
    hold on;
    plot(BER(:,1),'r--');
    set(gca, 'YScale', 'log');
    xlim([1,theta]);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('BER_{F}','FontSize',18);
    legend('Prediction','Simulation','FontSize',18);
    s = sprintf('n = %d',n);
    title(s,'FontSize',14);
    xlim([1, min(max(th_vector),n)]);
    ylim([1e-7,1]);
    grid on;

    %% plot SR
    figure(2)
    subplot(ceil(length(n_list)/2),2,n_idx);
    th_vector = th_vector(1:theta);
    SR = SR(1:theta,:)./((n*m)/(8*1024));
    bar(th_vector,SR,'group');
    legend('Simulation','Prediction','FontSize',18);
    s = sprintf('n = %d',n);
    title(s,'FontSize',14);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('\eta_{SNorm} (bit/KiB)','FontSize',18);
    ytickformat('%1.0f')
    legend('Prediction','Simulation','FontSize',18);
    xlim([1-0.5, max(th_vector)+0.5]);
    ylim ([0,1.2*max(SR(:))]);
    grid on;
end

function Nsel = SelRateDHW(n,m,threshold,Nsample)
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