#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string.h>
#include <iomanip>
#include <stdlib.h>
using namespace std;


int main(int argc, char const *argv[])
{
	ifstream fin("rom_inst.v");
	if(!fin)
	{
		printf("file doesn't exist!\n");
		exit(0);
	}
	ofstream fout("rom_inst_2.v");

	string readline;
	getline(fin, readline);
	cout << readline << endl;
	fout << readline << endl;
	string s1, s2, s3, s4;
	int n = 0;
	while(n < 361)
	{
		fin >> n >> s1 >> s2 >> s3 >> s4;
		cout << n/4 << s1 << " " << s2 << " " << s3 << " " << s4 << endl;
		fout << n/4 << s1 << " " << s2 << " " << s3 << " " << s4 << endl;
		n++;
	}
	cout << "default: inst <= 0;" << endl;
	fout << "default: inst <= 0;" << endl;
	fout << "endcase" << endl;
	cout << "endcase" << endl;
	fin.close();
	fout.close();

	return 0;
}