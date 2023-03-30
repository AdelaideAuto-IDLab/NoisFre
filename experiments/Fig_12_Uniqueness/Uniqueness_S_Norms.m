%Created by Yang
%Current Version 2021.12.28

clear all;
close all;
clc;

%% parameters
n_S_list = [15,31,39,47];
n_S = 31;
theta_S_list = [7,12,13,14];
theta_S = 8;

key_len = 1;
chipNum = 100;

figure();
for param_idx = 1:length(n_S_list)
    n_S = n_S_list(param_idx);
    theta_S = theta_S_list(param_idx);
    %% get file names
    d = dir('./nRF52');
    CHIP_NAMES = {d.name};
    CHIP_NAMES(1:2) = [];
    CHIP_NAMES(length(CHIP_NAMES)) = [];
    List_S_uniq = zeros(chipNum*(chipNum+1)/2,1);
    List_S_size = zeros(chipNum*(chipNum+1)/2,1);
    List_S_uniq_short = zeros(chipNum*(chipNum+1)/2,1);
    List_S_size_short = zeros(chipNum*(chipNum+1)/2,1);
    test_idx = 1;
    for chip_idx_A = 1:length(CHIP_NAMES)-1
        path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx_A)));
        [ChhipHW_ref_A,bitmap_ref_A]=HWOnlyRead(path,n_S,'SEQ');
        bitmap_ref_A_bin = cast(bitmap_ref_A,'logical');
        for chip_idx_B = chip_idx_A+1:length(CHIP_NAMES)
            path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx_B)));
            [ChhipHW_ref_B,bitmap_ref_B]=HWOnlyRead(path,n_S,'SEQ');
            bitmap_ref_B_bin = cast(bitmap_ref_B,'logical');

            %% S_Norm
            S_Norm_mask_A = find(abs(ChhipHW_ref_A - n_S/2) >= (theta_S+0.5));
            S_Norm_mask_selected_HW_A = ChhipHW_ref_A(S_Norm_mask_A);
            F_SNorm_A = S_Norm_mask_selected_HW_A >= n_S/2;

            S_Norm_mask_B = find(abs(ChhipHW_ref_B - n_S/2) >= (theta_S+0.5));
            S_Norm_mask_selected_HW_B = ChhipHW_ref_B(S_Norm_mask_B);
            F_SNorm_B = S_Norm_mask_selected_HW_B >= n_S/2;

            if(length(F_SNorm_A)<=1 || length(F_SNorm_B)<=1)
               continue; 
            end
            F_SNorm_A = reshape(F_SNorm_A,1,[]);
            F_SNorm_B = reshape(F_SNorm_B,1,[]);
            F_SNorm_A = F_SNorm_A(1:min(length(F_SNorm_A),length(F_SNorm_B))); % match the length of $F$, to the smaller from both chip.
            F_SNorm_B = F_SNorm_B(1:min(length(F_SNorm_A),length(F_SNorm_B)));
            List_S_uniq(test_idx) = pdist2(double(F_SNorm_A), double(F_SNorm_B),'hamming');
            test_idx = test_idx + 1;
            List_S_size(test_idx) = length(F_SNorm_A);
            
            %% exclude short F
            if(length(F_SNorm_A) >= key_len)
                List_S_uniq_short(test_idx) = pdist2(double(F_SNorm_A), double(F_SNorm_B),'hamming');
                List_S_size_short(test_idx) = length(F_SNorm_A);
            end
        end
    end
    List_S_uniq = List_S_uniq(1:test_idx);
    % remove zero terms in exc_short F lists
    List_S_uniq_short = nonzeros(List_S_uniq_short);
    List_S_size_short = nonzeros(List_S_size_short);

    %% plot
    nIDs = length(n_S_list);
    alphabet = ('a':'z').';
    chars = num2cell(alphabet(1:nIDs));
    chars = chars.';
    charlbl = strcat('(',chars,')'); % {'(a)','(b)','(c)','(d)'}
    
    set(gcf, 'Position',  [100, 100, 800, 180]);
    
    subplot(1,length(n_S_list),param_idx);
    histfit(List_S_uniq_short);
    xlim([0,1]);
    ylim([0,1000]);
%     xlabel('Uniqueness','FontSize',18);
    set(gca,'fontsize',18);
    grid on;
    text(0.025,0.90,'S('+string(n_S)+','+string(theta_S)+')','Units','normalized','FontSize',14)
    S_mean = mean(List_S_uniq_short);
    S_std = std(List_S_uniq_short);
    text(0.025,0.75,'¦Ì='+string(round(S_mean,2,'significant')),'Units','normalized','FontSize',14);
    text(0.025,0.60,'¦Ò='+string(round(S_std,2,'significant')),'Units','normalized','FontSize',14);
    List_S_size_short = List_S_size_short(List_S_size_short ~= 0);
    text(0.025,0.45,'|F1¡ÉF2|='+string(round(mean(List_S_size_short))),'Units','normalized','FontSize',14);
    mean(List_S_uniq_short)
    std(List_S_uniq_short)
end

