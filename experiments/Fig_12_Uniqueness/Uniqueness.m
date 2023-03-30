%Created by Yang
%Current Version 2021.12.28

clear all;
close all;
clc;

%% parameters
n_S = 31;
theta_S = 8;

n_D = 32;
m_D = 16;
theta_D = 16;

key_len = 128;
chipNum = 100;

%% get file names
d = dir('./nRF52');
CHIP_NAMES = {d.name};
CHIP_NAMES(1:2) = [];
CHIP_NAMES(length(CHIP_NAMES)) = [];
List_raw_uniq = zeros(chipNum*(chipNum+1)/2,1);
List_S_uniq = zeros(chipNum*(chipNum+1)/2,1);
List_D_uniq = zeros(chipNum*(chipNum+1)/2,1);
test_idx = 1;

for chip_idx_A = 1:length(CHIP_NAMES)-1
    path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx_A)));
    [ChhipHW_ref_A,bitmap_ref_A]=HWOnlyRead(path,8,'SEQ');
    bitmap_ref_A_bin = cast(bitmap_ref_A,'logical');
    for chip_idx_B = chip_idx_A+1:length(CHIP_NAMES)
        path = sprintf('./nRF52/%s/25C/TEST_0.bin',char(CHIP_NAMES(chip_idx_B)));
        [ChhipHW_ref_B,bitmap_ref_B]=HWOnlyRead(path,8,'SEQ');
        bitmap_ref_B_bin = cast(bitmap_ref_B,'logical');
       
       %% Raw uniqueness
        raw_f_A = reshape(bitmap_ref_A_bin,1,[]);
        raw_f_B = reshape(bitmap_ref_B_bin,1,[]);
        raw_uniq = pdist2(double(raw_f_A),double(raw_f_B),'hamming');
        List_raw_uniq(test_idx) = raw_uniq;
        test_idx = test_idx + 1;
    end
end
List_raw_uniq = List_raw_uniq(1:test_idx);

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
    end
end
List_S_uniq = List_S_uniq(1:test_idx);

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
    end
end
List_D_uniq = List_D_uniq(1:test_idx);

%% plot
nIDs = 4;
alphabet = ('a':'z').';
chars = num2cell(alphabet(1:nIDs));
chars = chars.';
charlbl = strcat('(',chars,')'); % {'(a)','(b)','(c)','(d)'}

figure();
set(gcf, 'Position',  [100, 100, 600, 250]);
subplot(1,3,1);
histfit(List_raw_uniq);
xlim([0,1]);
ylim([0,1000]);
xlabel('Uniqueness','FontSize',18);
set(gca,'fontsize',18);
grid on;
text(0.025,0.90,charlbl{1},'Units','normalized','FontSize',18)
mean(List_raw_uniq)
std(List_raw_uniq)

subplot(1,3,2);
histfit(List_S_uniq);
xlim([0,1]);
ylim([0,1000]);
xlabel('Uniqueness','FontSize',18);
set(gca,'fontsize',18);
grid on;
text(0.025,0.90,charlbl{2},'Units','normalized','FontSize',18)
mean(List_S_uniq)
std(List_S_uniq)

subplot(1,3,3);
histfit(List_D_uniq);
xlim([0,1]);
ylim([0,1000]);
xlabel('Uniqueness','FontSize',18);
set(gca,'fontsize',18);
grid on;
text(0.025,0.90,charlbl{3},'Units','normalized','FontSize',18)
mean(List_D_uniq)
std(List_D_uniq)

