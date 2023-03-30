%Created by Yang
%Current Version 2021.12.28

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

key_len = 0;
chipNum = 100;

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
    List_D_uniq = zeros(chipNum*(chipNum+1)/2,1);
    List_D_size = zeros(chipNum*(chipNum+1)/2,1);
    List_D_uniq_short = zeros(chipNum*(chipNum+1)/2,1);
    List_D_size_short = zeros(chipNum*(chipNum+1)/2,1);
    test_idx = 1;
for chip_idx_A = 1:length(CHIP_NAMES)-1
    path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx_A)));
    [ChhipHW_ref_A,bitmap_ref_A]=HWOnlyRead(path,n_D,'SEQ');
    bitmap_ref_A_bin = cast(bitmap_ref_A,'logical');
    for chip_idx_B = chip_idx_A+1:length(CHIP_NAMES)
        path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx_B)));
        [ChhipHW_ref_B,bitmap_ref_B]=HWOnlyRead(path,n_D,'SEQ');
        bitmap_ref_B_bin = cast(bitmap_ref_B,'logical');
       
       %% D_Norm
        D_Norm_mask_A = -1*ones([length(ChhipHW_ref_A),2]);
        k = 0;
        for i = 1:m_D:length(ChhipHW_ref_A)-(m_D-1)
            [maxHW,maxI] = max(ChhipHW_ref_A(i:i+m_D-1));
            [minHW,minI] = min(ChhipHW_ref_A(i:i+m_D-1));
            if(maxHW - minHW >= theta_D)%check against theta
                k = k + 1;
                if(maxI < minI) % if max has smaller index
                   D_Norm_mask_A(k,1) = i+maxI-1;
                   D_Norm_mask_A(k,2) = i+minI-1;
                else
                   D_Norm_mask_A(k,1) = i+minI-1;
                   D_Norm_mask_A(k,2) = i+maxI-1;
                end
            end
        end
        D_Norm_mask_A = D_Norm_mask_A(1:k,:);
        D_Norm_mask_selected_HW_A = ChhipHW_ref_A(D_Norm_mask_A);
        D_Norm_mask_selected_bits_first_A = bitmap_ref_A_bin(D_Norm_mask_A(:,1),:);
        D_Norm_mask_selected_bits_second_A = bitmap_ref_A_bin(D_Norm_mask_A(:,2),:);
        F_DNorm_A = ChhipHW_ref_A(D_Norm_mask_A(:,1))>=ChhipHW_ref_A(D_Norm_mask_A(:,2));
        
        D_Norm_mask_B = -1*ones([length(ChhipHW_ref_B),2]);
        k = 0;
        for i = 1:m_D:length(ChhipHW_ref_B)-(m_D-1)
            [maxHW,maxI] = max(ChhipHW_ref_B(i:i+m_D-1));
            [minHW,minI] = min(ChhipHW_ref_B(i:i+m_D-1));
            if(maxHW - minHW >= theta_D)%check against theta
                k = k + 1;
                if(maxI < minI) % if max has smaller index
                   D_Norm_mask_B(k,1) = i+maxI-1;
                   D_Norm_mask_B(k,2) = i+minI-1;
                else
                   D_Norm_mask_B(k,1) = i+minI-1;
                   D_Norm_mask_B(k,2) = i+maxI-1;
                end
            end
        end
        D_Norm_mask_B = D_Norm_mask_B(1:k,:);
        D_Norm_mask_selected_HW_B = ChhipHW_ref_B(D_Norm_mask_B);
        D_Norm_mask_selected_bits_first_B = bitmap_ref_B_bin(D_Norm_mask_B(:,1),:);
        D_Norm_mask_selected_bits_second_B = bitmap_ref_B_bin(D_Norm_mask_B(:,2),:);
        F_DNorm_B = ChhipHW_ref_B(D_Norm_mask_B(:,1))>=ChhipHW_ref_B(D_Norm_mask_B(:,2));
      
        if(length(F_DNorm_A)<=1 || length(F_DNorm_B)<=1)
           continue; 
        end
        F_DNorm_A = reshape(F_DNorm_A,1,[]);
        F_DNorm_B = reshape(F_DNorm_B,1,[]);
        F_DNorm_A = F_DNorm_A(1:min(length(F_DNorm_A),length(F_DNorm_B))); % match the length of $F$, to the smaller from both chip.
        F_DNorm_B = F_DNorm_B(1:min(length(F_DNorm_A),length(F_DNorm_B)));
        List_D_uniq(test_idx) = pdist2(double(F_DNorm_A), double(F_DNorm_B),'hamming');
        test_idx = test_idx + 1;
        List_D_size(test_idx) = length(F_DNorm_A);
        
         %% exclude short F
        if(length(F_DNorm_A) >= key_len)
            List_D_uniq_short(test_idx) = pdist2(double(F_DNorm_A), double(F_DNorm_B),'hamming');
            List_D_size_short(test_idx) = length(F_DNorm_A);
        end
    end
end
List_D_uniq = List_D_uniq(1:test_idx-1);
    % remove zero terms in exc_short F lists
    List_D_uniq_short = nonzeros(List_D_uniq_short);
    List_D_size_short = nonzeros(List_D_size_short);

    %% plot
    nIDs = length(n_D_list);
    alphabet = ('a':'z').';
    chars = num2cell(alphabet(1:nIDs));
    chars = chars.';
    charlbl = strcat('(',chars,')'); % {'(a)','(b)','(c)','(d)'}
    
    set(gcf, 'Position',  [100, 100, 2000, 180]);
    
    subplot(1,length(n_D_list),param_idx);
    histfit(List_D_uniq_short);
    xlim([0,1]);
    ylim([0,1000]);
%     xlabel('Uniqueness','FontSize',18);
    set(gca,'fontsize',18);
    grid on;
    text(0.025,0.90,'D('+string(n_D)+','+string(m_D)+','+string(theta_D)+')','Units','normalized','FontSize',14)
    D_mean = mean(List_D_uniq_short);
    D_std = std(List_D_uniq_short);
    text(0.025,0.75,'¦Ì='+string(round(D_mean,2,'significant')),'Units','normalized','FontSize',14);
    text(0.025,0.60,'¦Ò='+string(round(D_std,2,'significant')),'Units','normalized','FontSize',14);
    List_D_size_short = List_D_size_short(List_D_size_short ~= 0);
    text(0.025,0.45,'|F1¡ÉF2|='+string(round(mean(List_D_size_short))),'Units','normalized','FontSize',14);
end

