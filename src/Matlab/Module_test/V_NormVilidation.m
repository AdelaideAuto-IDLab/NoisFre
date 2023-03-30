%simulation for equation 3
clear all;
close all;
clc;

% n = 31;
% n_list=[8 16 24 32 40 48 56 64]-1;
 n_list=[8 16 32 64]-1;
% n_list=[40 48 56 64]-1;
% n_list=[15]-1;

EqnBER = 0.0609;

% unified big chip over all 12 chips
folder ='../BIG/';
Rfolder = '../BIGR/';


for idxn = 1:length(n_list)
    n = n_list(idxn);
    er_vector = zeros([floor(n/2),1]);
    e1_vector = zeros([floor(n/2),1]);
    ec_vector = zeros([floor(n/2),1]);
    
    th_vector = zeros([floor(n/2),1]);
    
    srr_vector = zeros([floor(n/2),1]);
    sr1_vector = zeros([floor(n/2),1]);
    src_vector = zeros([floor(n/2),1]);
    %% read the NRF chip Union 11 chips
    path=sprintf('%s25C/TEST_%d.bin',folder,6);
    [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n+1,'SEQ');
    path=sprintf('%s80C_15M/TEST_%d.bin',folder,6);
    [ChhipHW_reg,bitmap_reg]=HWOnlyRead(path,n+1,'SEQ');
    errorBit = length(find(bitmap_ref~=bitmap_reg));%number of error bits
    [k1,k2] = size(bitmap_reg);%dimention of SRAM
    totalBit = k1*k2;%total bits of SRAM
    ChipBER = errorBit/totalBit;
    
    %% simulate the reference response and regenerated response
    path=sprintf('%s25C/TEST_%d.bin',Rfolder,0); %must use 0, since 0 is reference, BER between any two regenerated respoonse may exceed 0.0443
    [RandHW_ref,bitmap_ref]=HWOnlyRead(path,n+1,'SEQ');
    path=sprintf('%s25C/TEST_%d.bin',Rfolder,4);
    [RandHW_reg,bitmap_reg]=HWOnlyRead(path,n+1,'SEQ');
    errorBit = length(find(bitmap_ref~=bitmap_reg));%number of error bits
    [k1,k2] = size(bitmap_reg);%dimention of SRAM
    totalBit = k1*k2;%total bits of SRAM
    BER_raw = errorBit/totalBit;
    
    
    
    
    
    for idxth = 1:floor(n/2)
    th_vector(idxth) = idxth;
        %% Selection from NRF chip
        ChipHWSel = find(abs(ChhipHW_ref - n/2) >= (idxth+0.5));
        ChiprefRes_reform = ChhipHW_ref(ChipHWSel) >= n/2;
        % sum(refRes_reform)

        ChipregRes_reform = ChhipHW_reg(ChipHWSel) >= n/2;
        sum(ChipregRes_reform)
        

        if isempty(ChiprefRes_reform)|| isempty(ChipregRes_reform)
            BER_reform_chip = -1;
        else
            BER_reform_chip = pdist2(double(ChiprefRes_reform)',double(ChipregRes_reform)','hamming');
        end
        if BER_reform_chip == 0
            BER_reform_chip = 1e-18;
        end
        
        ec_vector(idxth) = BER_reform_chip;
        src_vector(idxth) = (length(ChipregRes_reform)/length(ChhipHW_reg)*(1/idxn));%selection rate
        
        
        %% Simulate the BER of the selected reliable reformed response
        HW_ref = RandHW_ref; %word HW
        HWSel = find(abs(HW_ref - n/2) >= (idxth+0.5));
        refRes_reform = HW_ref(HWSel) >= n/2;
         sum(refRes_reform)

        HW_reg = RandHW_reg;
        regRes_reform = HW_reg(HWSel) >= n/2;

        if isempty(refRes_reform)|| isempty(regRes_reform)
            BER_reform = -1;
        else
            BER_reform = pdist2(double(refRes_reform)',double(regRes_reform)','hamming');
        end
        if BER_reform == 0
            BER_reform = 1e-18;
        end
        
        er_vector(idxth) = BER_reform;
        srr_vector(idxth) = (length(regRes_reform)/length(HW_reg))*(1/idxn);%selection rate

        %% calculated by equation
        % error rate
        RF = 0;
        for i=0:floor(n/2)-idxth
            P1 = 1 - binocdf(idxth+i,ceil(n/2)+idxth,EqnBER);
            P2 = binopdf(i,floor(n/2)-idxth,EqnBER);
            RF = P1*P2 + RF; % response failure rate
        end
        BER_equ = RF;
        e1_vector(idxth) = BER_equ;
        
        %selection rate
        SelRate = 1 - binocdf(idxth+floor(n/2),n,0.5) + binocdf(ceil(n/2)-idxth-1,n,0.5);
        sr1_vector(idxth) = SelRate*(1/idxn); %every n bits generate one bit e
        
        %% display whether the random test meet the equation theory
        expected = 'No';
%         if BER_reform <= BER_equ
%             expected = 'Yes';
%         end
        if BER_reform_chip <= BER_equ
            expected = 'Yes';
        end
        fprintf('For n = %d, theta = %d: ',n,idxth);
        fprintf('Reformed e fail = %f,Eqn.(1) e fail= %f, Expected = %s.\n',BER_reform_chip,BER_equ,expected);
    end
    figure(1);
    subplot(ceil(length(n_list)/4)*2,4,idxn);
    semilogy(th_vector,e1_vector,th_vector,er_vector,'-.',th_vector,ec_vector,'--');
    if(idxn == 1)
        legend('Prediction','Simulation','Measurement','FontSize',18);
    end
    s = sprintf('n = %d',n);
    title(s,'FontSize',14);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('BER_{F}','FontSize',18);
    xlim([1, max(th_vector)]);
    ylim ([1e-19,1]);
    txt = '0';
    text(0.5,1e-18,txt);
    
    subplot(ceil(length(n_list)/4)*2,4,idxn+4);
    bar_y = 1024*[sr1_vector';srr_vector';src_vector']';
    bar(th_vector,bar_y,'group');
    if(idxn == 1)
        legend('Prediction','Simulation','Measurement','FontSize',18);
    end
    s = sprintf('n = %d',n);
    title(s,'FontSize',14);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('\eta_{SNorm} (bit/Kbyte)','FontSize',18);
    ytickformat('%1.0f')
    xlim([1-0.5, max(th_vector)+0.5]);
    ylim ([0,1.2*max(bar_y(:))]);
end