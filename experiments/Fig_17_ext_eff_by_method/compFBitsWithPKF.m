% this script computs the key bits extracted with given n, theta
% try different m

clear;
clc;

load("./PKF_Table.mat");
C_SZ = 64;
m_min = 2;
m_max = 256;
mt_sz = zeros(m_max,2);

% slice the searching space into x points
x = 10;

%NRF_n_theta_PKF_m_kbt = NRF_n_theta_PKF;
load("FindKbitsBy_m.mat");
for nidx = 256:size(NRF_n_theta_PKF,1)
    if(0 == NRF_n_theta_PKF(nidx,3))
        continue;
    end
    n = NRF_n_theta_PKF(nidx,1);
    theta = NRF_n_theta_PKF(nidx,2);
    m_min = 2;
    m_max = 256;
    while(true)
        Key_bits = NaN(x,2);
        GS_points = round(linspace(m_min,m_max,x));
        parfor midx = 1:length(GS_points)
            [mt,ksz] = meet128b(C_SZ,n,GS_points(midx),theta);
            Key_bits(midx,:) = [GS_points(midx),ksz];
        end
        sort_m_by_key_bits = sortrows(Key_bits,2,'descend');
        if(all(diff(sort_m_by_key_bits(1:3,1))<0)||all(diff(sort_m_by_key_bits(1:3,1))>0))
        % monotornic
            m_min = min(sort_m_by_key_bits(1,1),sort_m_by_key_bits(2,1));
            m_max = max(sort_m_by_key_bits(1,1),sort_m_by_key_bits(2,1));
        else
        % bell shape
            m_min = min(sort_m_by_key_bits(2,1),sort_m_by_key_bits(3,1));
            m_max = max(sort_m_by_key_bits(2,1),sort_m_by_key_bits(3,1));
        end
        if(m_max - m_min <= x)
            m = sort_m_by_key_bits(1,1);
            kb = sort_m_by_key_bits(1,2);
            NRF_n_theta_PKF_m_kbt(nidx,4) = m;
            NRF_n_theta_PKF_m_kbt(nidx,5) = kb;
            break;
        end
    end
end


EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,80);
histfit(EXT_S,6);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);

save("./For_ext_hist.mat");
return;

%% this fucntion determines whetehr a given chip under such given parameter
% could provide more than 128 bit key
function [mt,key_SZ] = meet128b(C_SZ_f,n_f,m_f,theta_f)
    SR_DHW = Pa(theta_f,n_f,m_f);
    bit_per_kbyte = SR_DHW*(1/(m_f*n_f))*1024*8;
    key_SZ = C_SZ_f * bit_per_kbyte;
    if(key_SZ>=128)
        mt = true;
    else
        mt = false;
    end
end
