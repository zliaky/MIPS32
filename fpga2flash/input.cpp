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
	ifstream fin;
	ofstream fout;
	fin.open("ucore-kernel-initrd"); 
	fout.open("input.v");

	int n;
	int count = 0;
	while(!fin.eof())
	{
		fin >> hex >> n;
		fout << "32'h" << dec2hex(count, 8) << ": begin ";
		fout << "data_i <= 16'h";
		fout << hex << setfill('0') << setw(4) << (n % 256 * 256 + n / 256);
		fout << "; addr_i <= pc[`FlashAddrBusWord]; pc <= pc + 1'b1; end" << endl;
		count++;
	}
	fin.close();
	fout.close();

	return 0;
}