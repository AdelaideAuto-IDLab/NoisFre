#include<iostream>
#include<fstream>
#include<cstdlib>
#include<string>
#include <stdio.h>
#include <stdlib.h>
#include "SerialPort.h"

using namespace std;

/*Portname must contain these backslashes, and remember to
replace the following com port*/
char const *port_name = "\\\\.\\COM3";

//String for incoming data
char incomingData[MAX_DATA_LENGTH];


int main(int argc, char **argv){
    int file_index;
    string file_prefix;
    switch(argc){
        case 1:
            file_prefix = "TEST_";
            file_index = 0;
            break;
        case 2:
            file_prefix = string(argv[1]);
            file_index = 0;
            break;
        case 3:
            file_prefix = string(argv[1]);
            file_index = atoi(argv[2]);
        default:
            cout<<"Usage: saveMem [file prefix] [start index]\n";
            break;
    }
	
	SerialPort arduino(port_name);
	if (arduino.isConnected()) cout << "Connection Established" << endl;
	else cout << "ERROR, check port name";

    bool exit = false;
	bool autoDo = false;
    while(!exit && arduino.isConnected()){
		
		if(autoDo){
			char *c_string = new char[1];
			c_string[0] = 'J';
			arduino.writeSerialPort(c_string, 1);
			char output[1];
			//arduino.readSerialPort(output, 1);
			while(arduino.readSerialPort(output, 1) == 0 || output[0] != 'R'){
				cout<<"= ="<<endl;
				Sleep(500);
			}
			cout <<'='<< output[0] <<'='<< endl;
			delete[] c_string;
			file_index++;
		}else{
			/*Replace this by arduino discharge*/
			cout<<"Press Enter to continue saving memory q to exit a to auto\n";
			char input = cin.get();
			if(input == '\n'){
				file_index++;
			}else if(input == 'q'){
				exit = true;
			}else if(input == 'a'){ // auto read SRAM DUMP
				autoDo = true;
			}
		}

        string mem_filename = file_prefix + to_string(file_index) + ".bin";

        ofstream newfile;
        newfile.open("readMem.jlink");
        newfile << "savebin ./"<<mem_filename<<" 0x20000000 0x10000\n";
        newfile << "exit";
        newfile.close();


        system("JLink.exe -device nRF52832_xxAA -if SWD -speed 4000 -autoconnect 1 -CommanderScript readMem.jlink");

		

    }



    return 0;
}
