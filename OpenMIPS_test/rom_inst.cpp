#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string.h>
#include <iomanip>
#include <stdlib.h>
using namespace std;

string dec2hex(int n, int w)
{
	if (!w) return "";
	string ans = dec2hex(n / 16, w - 1);
	if (n % 16 < 10) ans += (char) (n % 16 + 48);
	else ans += (char) (n % 16 + 87);
	return ans;
}

int main(int argc, char const *argv[])
{
	ifstream fin("loader.txt");
	if(!fin)
	{
		printf("file doesn't exist!\n");
		exit(0);
	}
	ofstream fout("rom_inst.v");

	int n1, n2;
	int count = 0;
	while(!fin.eof())
	{
		fin >> hex >> n1 >> n2;
		fout << "12'h" << dec2hex(count, 3) <<": begin ";
		fout << "inst <= 32'h";
		fout << hex << setfill('0') << setw(4) << (n2 % 256 * 256 + n2 / 256);
		fout << hex << setfill('0') << setw(4) << (n1 % 256 * 256 + n1 / 256);
		fout << "; end" << endl;
		count++;
	}
	fin.close();
	fout.close();

	return 0;
}