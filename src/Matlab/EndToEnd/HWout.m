function [SUCCESS,valid_bits] = HWout(HW,RAM_BASE,RAM_SZ,RAM_RES,chipID,n,th)
% convert enrolled into microcontroller source file
%   此处显示详细说明
%constante=================================================
KEY_SZ = 128; % key size in bits
Mask_entrance = 0x20004000;% Start address of the mask tipically aligned with RAM bank
H1_challenge = uint8([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
% Matlab internal function=================================
RAM_start = RAM_BASE + RAM_RES;
word_bytes = n/8;
pivit = floor(n/2);% e = 1 if HW > pivit, otherwise e = 0
e = HW > pivit; % reformed response
e = double(e); % convert logic to number 0/1
HW_addr = [];
HW_selected = [];
for wordIdx = RAM_BASE:word_bytes:(RAM_BASE+RAM_SZ-1) % transverse all SRAM cells, the last word is not in the SRAM
    HW_addr = [HW_addr;"0x"+dec2hex(wordIdx)];
end
for HWIdx = 1:length(HW) % find valid bits agains th
    if(abs(HW(HWIdx)-pivit) >= th)
       HW_selected = [HW_selected;1];
    else
       HW_selected = [HW_selected;0];
    end 
end
%Addr_abs = RAM_BASE:word_bytes:RAM_SZ;
RAM_gebug_table = [HW_addr,HW,e,HW_selected];

valid_bits = sum(HW_selected);
RAM_selected = [];
for idx = 1:length(RAM_gebug_table(:,1))
    if(1 == str2num(RAM_gebug_table(idx,4)))
        RAM_selected = [RAM_selected; RAM_gebug_table(idx,:)];
    end
end
if(valid_bits < KEY_SZ)
    SUCCESS = false;
    warning("There are only %d selected responses (expected %d)\n",valid_bits,KEY_SZ);
    return;
end
Mask_bits = 0;
Mask = [];
% get exactly 128 bits mask
for idx = 1:length(RAM_selected(:,1)) 
    addr = hex2dec(extractAfter(RAM_selected(idx,1),"0x"));
    if(addr < Mask_entrance)
        continue;
    end
    if Mask_bits >= 128
        break;
    end
    Mask_bits = Mask_bits + 1;
    Mask = [Mask;RAM_selected(idx,:)];
end
% now Mask contains 128 bits good PUF responses and corresponding address
Mask_addr0 = Mask(1,1);%the start address od the mask
Mask_addr0N = hex2dec(extractAfter(Mask_addr0,"0x"));%numberic version
Mask_addr_prev = Mask_addr0N;
Addr_out = [];
for idx = 1:length(Mask(:,1)) 
    Mask_addr_now = hex2dec(extractAfter(Mask(idx,1),"0x"));
    Mask_diff = Mask_addr_now - Mask_addr_prev;
    Addr_out = [Addr_out,Mask_diff];
    Mask_addr_prev = Mask_addr_now;
end
%calculate u
e_bytes = [];
e_nums = [];
for idx = 1:8:KEY_SZ
    e_b = num2str([e(idx),e(idx+1),e(idx+2),e(idx+3),e(idx+4),e(idx+5),e(idx+6),e(idx+7)]);
    e_b= e_b(find(~isspace(e_b)));%remove space
    e_bytes = [e_bytes,e_b];
    e_nums = [e_nums,bin2dec(e_b)];
end

%may have problem, the mask is 32bits, but the CMAC takes 8 bits string
[u H1_status] = CMAC(e_nums,H1_challenge,Addr_out,length(Addr_out));
% implement code here=======================================================


if ~exist('./OUT', 'dir')
   mkdir('./OUT')
end
k = strfind(chipID,"nrf52");
if(isempty(k))
    error('bad chip directory');
end
Fout_mcu = fopen('./OUT/device.h','w+');
Fout_db = fopen('./OUT/db.h','w+');

% print warning message
fprintf(Fout_mcu,'// HW method For %s only\n',chipID(k:end));
fprintf(Fout_db,'// HW method For %s only\n',chipID(k:end));
% print the header of MCU source file
fprintf(Fout_mcu, '#ifndef ECCLESS_H_\n');
fprintf(Fout_mcu, '#define ECCLESS_H_\n');
fprintf(Fout_mcu, '#include <stdint.h>\n');
fprintf(Fout_mcu, '\n');
% print the header of DB source file
fprintf(Fout_db, '#ifndef DB_H_\n');
fprintf(Fout_db, '#define DB_H_\n');
fprintf(Fout_db, '#include <stdint.h>\n');
fprintf(Fout_db, '\n');
fprintf(Fout_mcu, '#define MASK_ADDR_0 %s\n',Mask_addr0);
fprintf(Fout_mcu, '#define WORD_SZ %d\n',n);
fprintf(Fout_mcu, '#define WORD_Bytes %d\n',n/8);
fprintf(Fout_mcu, 'const uint32_t Mask[%d] = {\n\t',KEY_SZ);
fprintf(Fout_db, 'const uint8_t e_bits[%d] = {\n\t',KEY_SZ);
for idx = 1:KEY_SZ
    fprintf(Fout_mcu, '0x%04X',Addr_out(idx));
    fprintf(Fout_db, '%d',e(idx));
    if(idx ~= KEY_SZ)
        fprintf(Fout_mcu, ', ');
        fprintf(Fout_db, ', ');
    else
        fprintf(Fout_mcu, '}; \n');
        fprintf(Fout_db, '}; \n');
    end
    if(0 == mod(idx,8))
       fprintf(Fout_mcu, '\n\t'); 
       fprintf(Fout_db, '\n\t');
    end
end
fprintf(Fout_mcu, '\n'); 
fprintf(Fout_db, '\n');
% print e_nums
fprintf(Fout_db, 'const uint8_t e_nums[%d] = {',KEY_SZ/8);
for idx = 1:KEY_SZ/8
    fprintf(Fout_db, '0x%02X',e_nums(idx));
    if(idx ~= KEY_SZ/8)
        fprintf(Fout_db, ', ');
    else
        fprintf(Fout_db, '}; \n');
    end
end
fprintf(Fout_db, '\n');
% print u to db
fprintf(Fout_db, 'const uint8_t u[%d] = {',16);
for idx = 1:16
    fprintf(Fout_db, '0x%02X',u(idx));
    if(idx ~= KEY_SZ/8)
        fprintf(Fout_db, ', ');
    else
        fprintf(Fout_db, '}; \n');
    end
end
fprintf(Fout_db, '\n');
% print u to mcu
fprintf(Fout_mcu, 'const uint8_t u[%d] = {',16);
for idx = 1:16
    fprintf(Fout_mcu, '0x%02X',u(idx));
    if(idx ~= KEY_SZ/8)
        fprintf(Fout_mcu, ', ');
    else
        fprintf(Fout_mcu, '}; \n');
    end
end
fprintf(Fout_mcu, '\n');


% puf function==============================================
fprintf(Fout_mcu,"/* Function to get no of set bits in binary\nrepresentation of positive integer n */\nuint8_t countSetBits(uint8_t* pn, uint8_t bytes) {\n\tuint8_t *poperate = (uint8_t*)malloc(bytes);\n\tmemcpy(poperate,pn,bytes); //make a copy, don't wanna destroy the original memory\n\tuint8_t count = 0;\n\twhile (bytes){\n\t\twhile (*poperate) {\n\t\t\tcount += *poperate & 1;\n\t\t\t*poperate >>= 1;\n\t\t}\n\t\tbytes --;\n\t\tpoperate ++;\n\t}\n\tfree(poperate);\n\treturn count;\n}\n\n");
fprintf(Fout_mcu, "int getPUF(uint8_t* e){\n\tuint8_t e_generated[16];\n\tuint8_t idx;\n\tuint8_t *paddr = MASK_ADDR_0;\n\tuint8_t hw;\n\tmemset(e,0,16);");
fprintf(Fout_mcu, " //initialize sk buffer\n\tfor(idx = 0; idx < 128; idx++){\n\t\tif((Mask(idx) > 0) || (idx == 0)){ // prevent manipulated mask, e.g. all zero offsets, idx == 0 is a special case, the offset is 0 in respect to the ·MASK_ADDR_0\n\t\t\tpaddr += Mask(idx);\n\t\t\thw = countSetBits(paddr,WORD_Bytes);\n\t\t\tif(hw >= (WORD_SZ/2)){\n\t\t\t\te_generated[idx/8] |= 1 << (idx%%8); \n\t\t\t}else{\n\t\t\t\te_generated[idx/8] |= 0 << (idx%%8); \n\t\t\t}\n\t\t}else{\n\t\t\treturn 0; // invalid mask (zero offset)\n\t\t}\n\t}\n\tmemcpy(e,e_generated,16);\n\treturn 1;\n}\n\n");
% db function===============================================
fprintf(Fout_db, 'void getPUF_DB(uint8_t* sk_out, uint8_t* u_out){\n\tmemcpy(sk_out,e_nums,16);\n\tmemcpy(u_out,u,16);\n}\n');




% H file footer
fprintf(Fout_mcu, '#endif /* ECCLESS_H_ */\n');
fprintf(Fout_db, '#endif /* DB_H_ */\n');
% Close source files
fclose(Fout_mcu);
fclose(Fout_db);
SUCCESS = true;
valid_bits = 0;
end
