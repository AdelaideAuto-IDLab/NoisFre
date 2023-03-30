function [SUCCESS,valid_bits] = DHWout(HW,RAM_BASE,RAM_SZ,RAM_RES,chipID,n,m,d)
% convert enrolled into microcontroller source file
%   此处显示详细说明
%constante=================================================
KEY_SZ = 128; % key size in bits
Mask_entrance = 0x20004000;% Start address of the mask tipically aligned with RAM bank
H1_challenge = uint8([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
Allign_offset = 8; % allignment offset to remove wordline correlation in bytes
% Matlab internal function=================================
RAM_start = RAM_BASE + RAM_RES;
word_bytes = n/8;
pivit = floor(n/2);% e = 1 if HW > pivit, otherwise e = 0

HW_addr = [];
for wordIdx = RAM_BASE:word_bytes:(RAM_BASE+RAM_SZ-2) % transverse all SRAM cells, the last word is not in the SRAM
    HW_addr = [HW_addr;"0x"+dec2hex(wordIdx)];
end

HW = HW(Allign_offset+1:end);
HW_addr = HW_addr(Allign_offset+1:end);
e = HW > pivit; % reformed response
e = double(e); % convert logic to number 0/1

HW_selected = zeros(length(HW),1);

mIdx = 1;
gIdx = [];
group_num = 1;
HW_max_val = 0;
HW_max_addr = 0;
HW_min_val = n;
HW_min_addr = 0;
First_array = [];
Second_array = [];

SelNum = 0; % number of selected group
for HWIdx = 1:length(HW) % find valid bits agains th
    gIdx = [gIdx; group_num];
    % search for max and min in a group
    if(mIdx >= m) % reached group size
        if(HW_max_val - HW_min_val >= d)
            if(hex2dec(extractAfter(HW_min_addr,"0x")) - hex2dec(extractAfter(HW_max_addr,"0x")) >= 0)
               HW_selected(HWIdx) = 1;
               First_array = [First_array; HW_max_addr];
               Second_array = [Second_array; HW_min_addr];
            else
               HW_selected(HWIdx) = -1;
               First_array = [First_array; HW_min_addr];
               Second_array = [Second_array; HW_max_addr];
            end
            SelNum = SelNum + 1;
        else
            First_array = [First_array; "N/A"];
            Second_array = [Second_array; "N/A"];
            HW_selected(HWIdx) = 0;
        end
        mIdx = 1;
        group_num = group_num+1;
        % reset stack-up temp values
        HW_max_val = 0;
        HW_max_addr = 0;
        HW_min_val = n;
        HW_min_addr = 0;
    else
            First_array = [First_array; "N/A"];
            Second_array = [Second_array; "N/A"];
        if (HW(HWIdx) >= HW_max_val)% update the maxium HW in a group
            HW_max_val = HW(HWIdx);
            HW_max_addr = HW_addr(HWIdx);
        end
        if (HW(HWIdx) <= HW_min_val)% update the maxium HW in a group
            HW_min_val = HW(HWIdx);
            HW_min_addr = HW_addr(HWIdx);
        end
        HW_selected(HWIdx) = 0;
        mIdx = mIdx + 1;
    end
end

RAM_gebug_table = [HW_addr,gIdx,HW,e,HW_selected,First_array,Second_array];

valid_bits = SelNum;
RAM_selected = [];
for idx = 1:length(RAM_gebug_table(:,1))
    if(0 ~= str2num(RAM_gebug_table(idx,5)))
        RAM_selected = [RAM_selected; RAM_gebug_table(idx,:)];
    end
end
Mask_bits = 0;
Mask = [];
% get exactly 128 bits mask
for idx = 1:length(RAM_selected(:,1)) 
    addr = hex2dec(extractAfter(RAM_selected(idx,6),"0x"));
    if(addr < Mask_entrance)
        continue;
    end
    if Mask_bits >= 128
        break;
    end
    Mask_bits = Mask_bits + 1;
    Mask = [Mask;RAM_selected(idx,:)];
end

if(Mask_bits < KEY_SZ) % can't find enough keys xxxxx TRAP xxxxxxxxxxxxxxx
    SUCCESS = false;
    warning("There are only %d selected responses (expected %d)\n",Mask_bits,KEY_SZ);
    return;
end%xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

% replace -1 with 0 in e
Mask(Mask(:,5) == '-1',5) = '0';

% now Mask contains 128 bits good PUF responses and corresponding address
Mask_addr0 = Mask(1,6);%the start address of the mask
Mask_addr0N = hex2dec(extractAfter(Mask_addr0,"0x"));%numberic version
Mask_addr_prev = Mask_addr0N;
Addr_out_first = [];
for idx = 1:length(Mask(:,1)) 
    Mask_addr_now = hex2dec(extractAfter(Mask(idx,6),"0x"));
    Mask_diff = Mask_addr_now - Mask_addr_prev;
    Addr_out_first = [Addr_out_first,Mask_diff];
    Mask_addr_prev = Mask_addr_now;
end

Mask_addr_prev = Mask_addr0N; % reset to reference address
Addr_out_second = [];
for idx = 1:length(Mask(:,1)) 
    Mask_addr_now = hex2dec(extractAfter(Mask(idx,7),"0x"));
    Mask_diff = Mask_addr_now - Mask_addr_prev;
    Addr_out_second = [Addr_out_second,Mask_diff];
    Mask_addr_prev = Mask_addr_now;
end

e_bytes = [];
e_nums = [];
e_DHW = Mask(:,5);
for idx = 1:8:KEY_SZ
    e_b = strcat(e_DHW(idx+7),e_DHW(idx+6),e_DHW(idx+5),e_DHW(idx+4),e_DHW(idx+3),e_DHW(idx+2),e_DHW(idx+1),e_DHW(idx+0));

   e_bytes = [e_bytes,e_b];
    e_nums = [e_nums,bin2dec(e_b)];
end

%calculate u
%may have problem, the mask is 32bits, but the CMAC takes 8 bits string
[u H1_status] = CMAC(e_nums,H1_challenge,Addr_out_first,length(Addr_out_first));
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
fprintf(Fout_mcu,'// DHW method For %s only\n',chipID(k:end));
fprintf(Fout_db,'// DHW method For %s only\n',chipID(k:end));
% print the header of MCU source file
fprintf(Fout_mcu, '#ifndef ECCLESS_H_\n');
fprintf(Fout_mcu, '#define ECCLESS_H_\n');
fprintf(Fout_mcu, '#include <stdint.h>\n');
fprintf(Fout_mcu, '#include <string.h>\n');
fprintf(Fout_mcu, '#include <stdlib.h>\n');
fprintf(Fout_mcu, '\n');
% print the header of DB source file
fprintf(Fout_db, '#ifndef DB_H_\n');
fprintf(Fout_db, '#define DB_H_\n');
fprintf(Fout_db, '#include <stdint.h>\n');
fprintf(Fout_db, '#include <string.h>\n');
fprintf(Fout_db, '\n');
fprintf(Fout_mcu, '#define MASK_ADDR_0 %s\n',Mask_addr0);
fprintf(Fout_mcu, '#define WORD_SZ %d\n',n);
fprintf(Fout_mcu, '#define WORD_Bytes %d\n',n/8);
fprintf(Fout_mcu, '#define GROUP_SZ %d\n',m);
fprintf(Fout_mcu, '#define DELTA %d\n',d);
fprintf(Fout_mcu, 'const uint32_t Mask_first[%d] = {\n\t',KEY_SZ);
fprintf(Fout_db, 'const uint8_t e_bits[%d] = {\n\t',KEY_SZ);
for idx = 1:KEY_SZ
    fprintf(Fout_mcu, '0x%04X',Addr_out_first(idx));
    fprintf(Fout_db, '%s',Mask(idx,5));
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

fprintf(Fout_mcu, 'const uint32_t Mask_second[%d] = {\n\t',KEY_SZ);
for idx = 1:KEY_SZ
    fprintf(Fout_mcu, '0x%04X',Addr_out_second(idx));
    if(idx ~= KEY_SZ)
        fprintf(Fout_mcu, ', ');
    else
        fprintf(Fout_mcu, '}; \n');
    end
    if(0 == mod(idx,8))
       fprintf(Fout_mcu, '\n\t'); 
    end
end
fprintf(Fout_mcu, '\n'); 

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
fprintf(Fout_mcu,"/* Function to get no of set bits in binary\nrepresentation of positive integer n */\nuint8_t countSetBits(uint8_t* pn, uint8_t bytes) {\n\tuint8_t *poperate_0 = (uint8_t*)malloc(bytes);\n\tuint8_t *poperate = poperate_0;\n\tmemcpy(poperate,pn,bytes); //make a copy, don't wanna destroy the original memory\n\tuint8_t count = 0;\n\twhile (bytes){\n\t\twhile (*poperate) {\n\t\t\tcount += *poperate & 1;\n\t\t\t*poperate >>= 1;\n\t\t}\n\t\tbytes --;\n\t\tpoperate ++;\n\t}\n\tfree(poperate_0);\n\treturn count;\n}\n\n");
fprintf(Fout_mcu, "/*\n* get reformmed PUF key form the SRAM\n* Para@0 e (uint8_t*), pointer to receive key, at least 16 bytes long\n* Rtn@0 Valid_bits int, number of valid key bits\n*/\nint getPUF(uint8_t* e){\n\tuint8_t e_generated[16]; // buffer for e while generating\n\tmemset(e_generated,0,16); //initialize e buffer\n\tuint8_t idx; // index for the i^th e bit\n\tuint8_t *paddrFirst = (uint8_t *)MASK_ADDR_0; // pointer to the -first- memory location in a group\n\tuint8_t *paddrSecond = (uint8_t *)MASK_ADDR_0; // ..to the second\n\tint8_t dhw; // differential hamming weight in this group notice negative\n\tfor(idx = 0; idx < 128; idx++){\n\t\tif((Mask_first[idx] > 0 && Mask_second[idx] > 0) || (idx == 0)){ // prevent manipulated mask, e.g. all zero offsets, idx == 0 is a special case, the offset is 0 in respect to the ·MASK_ADDR_0\n\t\t\tpaddrFirst += Mask_first[idx];\n\t\t\tpaddrSecond += Mask_second[idx];\n\t\t\tdhw = countSetBits(paddrFirst,WORD_Bytes) - countSetBits(paddrSecond,WORD_Bytes);\n\t\t\tif(dhw >= 0){ // Max is at the lower address\n\t\t\t\te_generated[idx/8] |= 1 << (idx%%8); \n\t\t\t}else{\n\t\t\t\te_generated[idx/8] |= 0 << (idx%%8); \n\t\t\t}\n\t\t}else{\n\t\t\treturn idx; // invalid mask (zero offset)\n\t\t}\n\t}\n\tmemcpy(e,e_generated,16);\n\treturn 128;\n}\n");
% db function===============================================
fprintf(Fout_db, 'void getPUF_DB(uint8_t* sk_out, uint8_t* u_out){\n\tmemcpy(sk_out,e_nums,16);\n\tmemcpy(u_out,u,16);\n}\n');




% H file footer
fprintf(Fout_mcu, '#endif /* ECCLESS_H_ */\n');
fprintf(Fout_db, '#endif /* DB_H_ */\n');
% Close source files
fclose(Fout_mcu);
fclose(Fout_db);
SUCCESS = true;
valid_bits = KEY_SZ;
end
