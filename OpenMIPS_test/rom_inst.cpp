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
	ifstream fin("rom_inst.data");
	ofstream fout("rom_inst.v");

	string readLine;
	int count = 0;
	while(getline(fin, readLine))
	{
		fout << "12'h" << dec2hex(count, 3) <<": begin ";
		fout << "inst <= 32'h" << readLine;
		fout << "; end" << endl;
		count++;
	}
	fin.close();
	fout.close();

	return 0;
}