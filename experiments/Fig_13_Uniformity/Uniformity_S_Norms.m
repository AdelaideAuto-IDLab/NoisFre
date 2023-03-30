%Created by Yang
%Current Version 2022.1.21

clear all;
close all;
clc;

%% parameters
n_S_list = [15,31,39,47];
n_S = 31;
theta_S_list = [4,8,9,10];
theta_S = 8;

key_len = 128;

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
    end


    %% plot
    nIDs = length(n_S_list);
    alphabet = ('a':'z').';
    chars = num2cell(alphabet(1:nIDs));
    chars = chars.';
    charlbl = strcat('(',chars,')'); % {'(a)','(b)','(c)','(d)'}

    set(gcf, 'Position',  [100, 100, 800, 150]);

    subplot(1,length(n_S_list),param_idx);
    List_S_bias = List_S_bias(~isnan(List_S_bias));
    boxplot(List_S_bias);
    ylim([0,1]);
    set(gca, 'XTickLabel', []);
    set(gca,'fontsize',18);
    grid on;
    text(0.025,0.90,charlbl{param_idx},'Units','normalized','FontSize',18);
    S_iqr = iqr(List_S_bias);
    S_midian = median(List_S_bias);
    text(0.025,0.30,'Med='+string(round(S_midian,2,'significant')),'Units','normalized','FontSize',14);
    text(0.025,0.10,'IQR='+string(round(S_iqr,2,'significant')),'Units','normalized','FontSize',14);
    median(List_S_bias)
    max(List_S_bias)
    min(List_S_bias)
end
