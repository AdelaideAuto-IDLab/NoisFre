clear all;
close all;
clc;
load("./For_ext_hist.mat");
figure(1)
subplot(3,2,1);
EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,80*8);
histfit(EXT_S,6*8);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);

subplot(3,2,2);
EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,80*4);
histfit(EXT_S,6*4);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);

subplot(3,2,3);
EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,80*2);
histfit(EXT_S,6*2);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);

subplot(3,2,4);
EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,80);
histfit(EXT_S,6);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);

subplot(3,2,5);
EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,64);
histfit(EXT_S,6);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);

subplot(3,2,6);
EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,40);
histfit(EXT_S,3);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);

figure(2)
EXT_D = NRF_n_theta_PKF_m_kbt(:,5);
EXT_D = EXT_D(EXT_D~=0)./C_SZ;
hold on;
histfit(EXT_D,40);
histfit(EXT_S,3);
xlabel("Extraction efficiency bit/KiByte","FontSize",18);
ylabel("Occurrance","FontSize",18);
legend("D-Norm","","S-Norm","","FontSize",18);
xlim([0,.7]);