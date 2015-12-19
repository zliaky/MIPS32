#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string.h>
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
	ifstream fin("inst_rom.data");
	ofstream fout("input.v");

	string readLine;
	int count = 0;
	while(getline(fin, readLine))
	{
		fout << "data_mem[" << count << "]=32'h" << readLine << ";" << endl;
		count++;
	}
	for(int i = 0; i < 100; i++)
	{
		fout << "data_mem[" << count << "]=32'h00000000;" << endl;
		count++;
	}
	fin.close();
	fout.close();

	return 0;
}