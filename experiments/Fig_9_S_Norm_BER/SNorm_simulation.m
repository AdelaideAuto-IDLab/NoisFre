%simulation for equation 3
clear all;
close all;
clc;

n_list=[8 16 32 64]-1;
n = n_list(4);

RawBER = 0.0609;
Key_len = 128;
Sim_chip_sz = {'64K','128K','256K','512K','1M','2M','4M','8M','16M'};
Sim_chip_dir = './Rand_CHIP/';
Mes_chip_ref_dir = '../../BIG/25C/';
Mes_chip_reg_dir = '../../BIG/80C_15M/';
Sim_chip_idx = 1;

Repeat_times = 1e6;
Chip_measurements = 99;

for n_idx = 1:length(n_list)
    n = n_list(n_idx);
    %% variable
    Bit_err_counter = zeros(Key_len,1);
    mes_Bit_err_counter = zeros(Key_len,1);
    BER = zeros((n+1)/2,3);
    SR = zeros((n+1)/2,3);
    th_vector = zeros((n+1)/2,1);


    for theta = 1:(n+1)/2
        th_vector(theta) = theta;
        while(true)
            %% read the reference chip #0
            path=sprintf('%s%s/TEST_0.bin',Sim_chip_dir,char(Sim_chip_sz(Sim_chip_idx)));
            [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n+1,'SEQ');
            bitmap_ref_bin = cast(bitmap_ref,'logical');
            S_Norm_ref = cast(ChhipHW_ref,'uint8');
            %% Selection S-Norm
            S_Norm_mask = find(abs(ChhipHW_ref - n/2) >= (theta+0.5));

            if(Sim_chip_idx > length(Sim_chip_sz))
                warning('Not enough chip size');
                return;
            else
                if(length(S_Norm_mask)<Key_len)
                    Sim_chip_idx = Sim_chip_idx+1;
                else
                    S_Norm_mask_clip_ken_leng = S_Norm_mask(1:Key_len); % calip according to the key length
                    break;
                end
            end
        end

        %% package selected mask
        S_Norm_mask_selected_HW = ChhipHW_ref(S_Norm_mask_clip_ken_leng);
        S_Norm_mask_selected_bits = bitmap_ref_bin(S_Norm_mask_clip_ken_leng,:);
        F_SNorm = S_Norm_mask_selected_HW >= n/2;
        SNorm_SR = length(S_Norm_mask)/length(ChhipHW_ref);
        SR(theta,2) = SNorm_SR;

        Bit_err_counter = zeros(Key_len,1);
        mes_Bit_err_counter = zeros(Key_len,1);
        tic;
        parfor rep_idx = 1:Repeat_times
            %% apply noise
            binoNoise_mask = binornd(1,RawBER,size(S_Norm_mask_selected_bits));
            S_Norm_reg_bits = xor(S_Norm_mask_selected_bits,binoNoise_mask);

            %% convert to HW
            HW_reg = sum(S_Norm_reg_bits,2);
            F_SNorm_reg = HW_reg >= n/2;
            F_diff = F_SNorm~=F_SNorm_reg;
            Bit_err_counter = Bit_err_counter + F_diff;

        end
        time = toc;

    %% calculate BER_F
        BER_sim = mean(Bit_err_counter)/Repeat_times;
        BER(theta,1) = BER_sim;

    %% calculated by equation
        % error rate
        RF = 0;
        for i=0:floor(n/2)-theta
            P1 = 1 - binocdf(theta+i,ceil(n/2)+theta,RawBER);
            P2 = binopdf(i,floor(n/2)-theta,RawBER);
            RF = P1*P2 + RF; % response failure rate
        end
        BER_equ = RF;
        BER(theta,2) = BER_equ;
        %selection rate
        SR(theta,1) = 1 - binocdf(theta+floor(n/2),n,0.5) + binocdf(ceil(n/2)-theta-1,n,0.5);
        if(BER_equ <= 1e-6)
            break;
        end

    %% measurement with BIG chip
    %% read the reference chip #0
        path=sprintf('%s/TEST_0.bin',Mes_chip_ref_dir);
        [mes_ChhipHW_ref,mes_bitmap_ref]=HWOnlyRead(path,n+1,'SEQ');
        mes_bitmap_ref_bin = cast(mes_bitmap_ref,'logical');
        mes_S_Norm_ref = cast(mes_ChhipHW_ref,'uint8');
        clear mes_ChhipHW_ref;
    %% Selection S-Norm
        mes_S_Norm_mask = find(abs(mes_S_Norm_ref - n/2) >= (theta+0.5));

        if(length(mes_S_Norm_mask)<Key_len)
            warning('Not enough chip size (physical chip)');
        else
%             mes_S_Norm_mask_clip_ken_leng = mes_S_Norm_mask(1:Key_len); % calip according to the key length
            mes_S_Norm_mask_clip_ken_leng = mes_S_Norm_mask(:);
         %% package selected mask
            mes_S_Norm_mask_selected_HW = mes_S_Norm_ref(mes_S_Norm_mask_clip_ken_leng);
            mes_F_SNorm = mes_S_Norm_mask_selected_HW >= n/2;
            mes_SNorm_SR = length(mes_S_Norm_mask)/length(mes_S_Norm_ref);
            SR(theta,3) = mes_SNorm_SR;

%             mes_Bit_err_counter = zeros(Key_len,1);
            mes_Bit_err_counter = zeros(length(mes_S_Norm_mask_clip_ken_leng),1);
            for rep_idx = 1:Chip_measurements
              %% read the regenerate chip #1~99
                path=sprintf('%s/TEST_%d.bin',Mes_chip_reg_dir,rep_idx);
                [mes_ChhipHW_reg,mes_bitmap_reg]=HWOnlyRead(path,n+1,'SEQ');
                mes_bitmap_reg_bin = cast(mes_bitmap_reg,'logical');
                mes_S_Norm_reg = cast(mes_ChhipHW_reg,'uint8');
                clear mes_ChhipHW_reg;
                mes_S_Norm_reg_bits = mes_bitmap_reg_bin(mes_S_Norm_mask_clip_ken_leng,:);
                mes_HW_reg_selected = mes_S_Norm_reg(mes_S_Norm_mask_clip_ken_leng);

                %% convert to HW
                mes_HW_reg = sum(mes_S_Norm_reg_bits,2);
                mes_F_SNorm_reg = mes_HW_reg >= n/2;
                mes_F_diff = mes_F_SNorm~=mes_F_SNorm_reg;
                mes_Bit_err_counter = mes_Bit_err_counter + mes_F_diff;
            end
        %% calculate BER_F
            mes_BER_sim = mean(mes_Bit_err_counter)/(Chip_measurements);
            BER(theta,3) = mes_BER_sim;
        end
    end

    %% plot BER
    figure(1);
    subplot(ceil(length(n_list)/2),2,n_idx);
    plot(BER(:,2),'b-');
    hold on;
    plot(BER(:,1),'r--');
    hold on;
    plot(BER(:,3),'o-.');
    set(gca, 'YScale', 'log');
    xlim([1,theta]);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('BER_{F}','FontSize',18);
    legend('Prediction','Simulation','Measurement','FontSize',18);
    s = sprintf('n = %d',n);
    title(s,'FontSize',14);
    xlim([1, min(max(th_vector),n/2)]);
    ylim([1e-7,1]);
    grid on;

    %% plot SR
    figure(2);
    subplot(ceil(length(n_list)/2),2,n_idx);
    th_vector = th_vector(1:theta);
    SR = SR(1:theta,:)./(n/(8*1024));
    bar(th_vector,SR,'group');
    legend('Prediction','Simulation','Measurement','FontSize',18);
    s = sprintf('n = %d',n);
    title(s,'FontSize',14);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('\eta_{SNorm} (bit/Kbyte)','FontSize',18);
    ytickformat('%1.0f')
    xlim([1-0.5, max(th_vector)+0.5]);
    ylim ([0,1.2*max(SR(:))]);
    grid on;

end