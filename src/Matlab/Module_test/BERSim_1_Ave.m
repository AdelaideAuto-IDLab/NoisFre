clear all;
close all;
clc;

% n = 31;
% n_list=[8 16 24 32 40 48 56 64]-1;
% n_list=[8 16 24 32]-1;
% n_list=[8 16 32 64]-1;
n_list=[40 48 56 64]-1;
% n_list=[48]-1;

EqnBER = 0.0609;
RandBER = 0.0609;

Nrep = 10;

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
    
    bias_chip_vector = zeros([floor(n/2),1]);   
    bias_random_vector = zeros([floor(n/2),1]);
    bias_eq_vector = zeros([floor(n/2),1]);
    %% read the NRF chip Union 11 chips
    path=sprintf('%s/25C/TEST_%d.bin',folder,6);
    [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n+1,'SEQ');
    [k1,k2] = size(bitmap_ref);%dimention of SRAM
    totalBit = k1*k2;%total bits of SRAM
    
    path=sprintf('%s/80C_15M/TEST_%d.bin',folder,6);
    [ChhipHW_reg,bitmap_reg]=HWOnlyRead(path,n+1,'SEQ');
    errorBit = length(find(bitmap_ref~=bitmap_reg));%number of error bits
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

        %% Repeat Nrep times and take the average
        for rep = 1:Nrep
            path=sprintf('%s25C/TEST_%d.bin',folder,rep-1);
            [ChhipHW_ref,bitmap_ref]=HWOnlyRead(path,n+1,'SEQ');
            ChipregRes_reform = ChhipHW_reg(ChipHWSel) >= n/2;
            bias_chip_vector(idxth)=sum(ChipregRes_reform)/length(ChipregRes_reform) + bias_chip_vector(idxth);
            if isempty(ChiprefRes_reform)|| isempty(ChipregRes_reform)
                BER_reform_chip = -1;
            else
                BER_reform_chip = pdist2(double(ChiprefRes_reform)',double(ChipregRes_reform)','hamming');
            end
            if BER_reform_chip == 0
                BER_reform_chip = 1e-18;
            end
            
            ec_vector(idxth) = BER_reform_chip + ec_vector(idxth);
%             src_vector(idxth) = (length(ChipregRes_reform)/length(ChhipHW_reg)*(1/idxn)) + src_vector(idxth); %selection rate
            src_vector(idxth) = (length(ChipregRes_reform)/totalBit*1024*8) + src_vector(idxth); %selection rate
        end
        ec_vector(idxth) = ec_vector(idxth)/Nrep
        src_vector(idxth) = src_vector(idxth)/Nrep
        bias_chip_vector(idxth) = bias_chip_vector(idxth)/Nrep;
        %% Simulate the BER of the selected reliable reformed response
        HW_ref = RandHW_ref; %word HW
        HWSel = find(abs(HW_ref - n/2) >= (idxth+0.5));
        refRes_reform = HW_ref(HWSel) >= n/2;
        
        
        for rep = 1:Nrep-1 %noting that the reference is 0, the rest (Nrep - 1) times are used for average
            path=sprintf('%s25C/TEST_%d.bin',Rfolder,rep);
            [RandHW_reg,bitmap_reg]=HWOnlyRead(path,n+1,'SEQ');
            HW_reg = RandHW_reg;
            regRes_reform = HW_reg(HWSel) >= n/2;
            bias_random_vector(idxth)=sum(regRes_reform)/length(regRes_reform) + bias_random_vector(idxth);
            
            if isempty(refRes_reform)|| isempty(regRes_reform)
                BER_reform = -1;
            else
                BER_reform = pdist2(double(refRes_reform)',double(regRes_reform)','hamming');
            end
            if BER_reform == 0
                BER_reform = 1e-18;
            end
            
            er_vector(idxth) = BER_reform + er_vector(idxth);
            srr_vector(idxth) = length(regRes_reform)/totalBit*1024*8 + srr_vector(idxth);%selection rate
        end
        er_vector(idxth) = er_vector(idxth)/(Nrep - 1);
        srr_vector(idxth) = srr_vector(idxth)/(Nrep - 1);%selection rate
        bias_random_vector(idxth) = bias_random_vector(idxth)/(Nrep - 1);
        
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
        sr1_vector(idxth) = SelRate/(n+1)*1024*8; %every n bits generate one bit e
        bias_eq_vector(idxth)=0.5;
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
    legend('Predition','Simulation','Measurement','FontSize',18);
    s = sprintf('n = %d',n);
    title(s);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('BER_{F}','FontSize',18);
    xlim([1, max(th_vector)]);
    ylim ([1e-19,1]);
    txt = '0';
    text(0.5,1e-18,txt);
    
%     figure(2);
    subplot(ceil(length(n_list)/4)*2,4,idxn+4);
    bar_y = [sr1_vector';srr_vector';src_vector']';
    bar(th_vector,bar_y,'group');
%     set(gca,'YScale','log');
%     ytickformat('percentage');
    legend('Predition','Simulation','Measurement','FontSize',18);
    s = sprintf('n = %d',n);
    title(s);
    xlabel('Theshold \theta','FontSize',18);
    ylabel('\eta_{single} _{(bit/Kbyte)}','FontSize',18);
    xlim([1-0.5, max(th_vector)+0.5]);
%     ylim ([0,1024]);

%     subplot(ceil(length(n_list)/4)*3,4,idxn+8);
%     bar_y = [bias_eq_vector';bias_random_vector';bias_chip_vector']';
%     bar(th_vector,bar_y,'group');
% %     set(gca,'YScale','log');
% %     ytickformat('percentage');
%     legend('Ideal','Random test','Chip test');
%     s = sprintf('n = %d',n);
%     title(s);
%     xlabel('Theshold \theta');
%     ylabel('Bias');
%     xlim([1-0.5, max(th_vector)+0.5]);
%     ylim ([0,1]);
end

%%
Pkey_eq = 1 - (1-e1_vector).^128;
Index_eq = find(Pkey_eq < 1e-6);

FirstIndex_eq = Index_eq(1)
BERe_eq = e1_vector(FirstIndex_eq)
SRe_eq = sr1_vector(FirstIndex_eq)

% Pkey_c = 1 - (1-ec_vector).^128;
% Index_c = find(Pkey_c < 1e-3);
% 
% FirstIndex_c = Index_c(1)
% BERe_c = ec_vector(FirstIndex_c)
SRe_c = src_vector(FirstIndex_eq)