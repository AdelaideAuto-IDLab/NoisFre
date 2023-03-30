%Created by Yang
%Current Version 2022.1.21

clear all;
% close all;
clc;

%% parameters
n_S_list = [15,31,39,47];
n_S = 31;
theta_S_list = [7,12,13,14];
theta_S = 8;

key_len = 1;

figure();
for param_idx = 1:length(n_S_list)
    n_S = n_S_list(param_idx);
    theta_S = theta_S_list(param_idx);
    %% get file names
    d = dir('./nRF52');
    CHIP_NAMES = {d.name};
    CHIP_NAMES(1:2) = [];
    CHIP_NAMES(length(CHIP_NAMES)) = [];
    List_S_bias = zeros(100,1);
    List_S_bias_exc_short = zeros(100,1);
    List_S_F_size = zeros(100,1);
    List_S_F_size_exc_short = zeros(100,1);

    for chip_idx = 1:length(CHIP_NAMES)
        path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx)));
        [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n_S,'SEQ');
        bitmap_ref_bin = cast(bitmap_ref,'logical');

        %% S_Norm
        S_Norm_mask = find(abs(ChhipHW_ref - n_S/2) >= (theta_S+0.5));
        S_Norm_mask_selected_HW = ChhipHW_ref(S_Norm_mask);
        F_SNorm = S_Norm_mask_selected_HW >= n_S/2;
        S_Norm_bias = mean(F_SNorm);
        List_S_bias(chip_idx) = S_Norm_bias;
        List_S_F_size(chip_idx) = length(F_SNorm);
        
        %% exclude short F
        if(length(F_SNorm) >= key_len)
            List_S_bias_exc_short(chip_idx) = S_Norm_bias;
            List_S_F_size_exc_short(chip_idx) = length(F_SNorm);
        end
    end
    
    % remove zero terms in exc_short F lists
    List_S_bias_exc_short = nonzeros(List_S_bias_exc_short);
    List_S_F_size_exc_short = nonzeros(List_S_F_size_exc_short);

    %% plot
    nIDs = length(n_S_list);
    alphabet = ('a':'z').';
    chars = num2cell(alphabet(1:nIDs));
    chars = chars.';
    charlbl = strcat('(',chars,')'); % {'(a)','(b)','(c)','(d)'}

    set(gcf, 'Position',  [100, 100, 800, 150]);

    subplot(1,length(n_S_list),param_idx);
    List_S_bias_exc_short = List_S_bias_exc_short(~isnan(List_S_bias_exc_short));
    histfit(List_S_bias_exc_short);
    ylim([0,100]);
    xlim([0,1]);
%     set(gca, 'XTickLabel', []);
    set(gca,'fontsize',18);
    grid on;
    text(0.025,0.9,'S('+string(n_S)+','+string(theta_S)+')','Units','normalized','FontSize',14)
    S_mean = mean(List_S_bias_exc_short);
    S_std = std(List_S_bias_exc_short);
    S_size = mean(List_S_F_size_exc_short);
    text(0.025,0.7,'¦Ì='+string(round(S_mean,2,'significant')),'Units','normalized','FontSize',14);
    text(0.025,0.5,'¦Ò='+string(round(S_std,2,'significant')),'Units','normalized','FontSize',14);
    text(0.025,0.3,'|F|='+string(round(S_size)),'Units','normalized','FontSize',14);
    median(List_S_bias_exc_short)
    max(List_S_bias_exc_short)
    min(List_S_bias_exc_short)
end
