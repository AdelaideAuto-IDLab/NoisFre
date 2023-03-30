%Created by Yang
%Current Version 2021.1.21

clear all;
close all;
clc;

%% parameters
n_D_list = [16,16,16,32,32,32,32,32,64,64,64];
n_D = 32;
m_D_list = [64,128,256,16,32,64,128,256,32,64,128];
m_D = 16;
theta_D_list = [13,13,13,16,16,16,16,16,21,21,21];
theta_D = 16;

key_len = 128;

figure();
for param_idx = 1:length(n_D_list)
    n_D = n_D_list(param_idx);
    m_D = m_D_list(param_idx);
    theta_D = theta_D_list(param_idx);
    %% get file names
    d = dir('./nRF52');
    CHIP_NAMES = {d.name};
    CHIP_NAMES(1:2) = [];
    CHIP_NAMES(length(CHIP_NAMES)) = [];
    List_D_bias = zeros(100,1);

    for chip_idx = 1:length(CHIP_NAMES)
        path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx)));
        [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n_D,'SEQ');
        bitmap_ref_bin = cast(bitmap_ref,'logical');

        %% D_Norm
        D_Norm_mask = -1*ones([length(ChhipHW_ref),2]);
        k = 0;
        for i = 1:m_D:length(ChhipHW_ref)-(m_D-1)
            [maxHW,maxI] = max(ChhipHW_ref(i:i+m_D-1));
            [minHW,minI] = min(ChhipHW_ref(i:i+m_D-1));
            if(maxHW - minHW >= theta_D)%check against theta
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
        D_Norm_mask = D_Norm_mask(1:k,:);
        D_Norm_mask_selected_HW = ChhipHW_ref(D_Norm_mask);
        D_Norm_mask_selected_bits_first = bitmap_ref_bin(D_Norm_mask(:,1),:);
        D_Norm_mask_selected_bits_second = bitmap_ref_bin(D_Norm_mask(:,2),:);
        F_DNorm = ChhipHW_ref(D_Norm_mask(:,1))>=ChhipHW_ref(D_Norm_mask(:,2));
        D_Norm_bias = mean(F_DNorm);
        List_D_bias(chip_idx) = D_Norm_bias;
    end

    %% plot
    nIDs = length(n_D_list);
    alphabet = ('a':'z').';
    chars = num2cell(alphabet(1:nIDs));
    chars = chars.';
    charlbl = strcat('(',chars,')'); % {'(a)','(b)','(c)','(d)'}

    set(gcf, 'Position',  [100, 100, 2500, 150]);

    subplot(1,length(n_D_list),param_idx);
    boxplot(List_D_bias);
    ylim([0,1]);
    set(gca, 'XTickLabel', [])
    set(gca,'fontsize',18);
    grid on;
    text(0.025,0.90,'D('+string(n_D)+','+string(m_D)+','+string(theta_D)+')','Units','normalized','FontSize',14)
    D_iqr = iqr(List_D_bias);
    D_midian = median(List_D_bias);
    text(0.025,0.30,'Med='+string(round(D_midian,2,'significant')),'Units','normalized','FontSize',14);
    text(0.025,0.10,'IQR='+string(round(D_iqr,2,'significant')),'Units','normalized','FontSize',14);
    median(List_D_bias)
    max(List_D_bias)
    min(List_D_bias)
end