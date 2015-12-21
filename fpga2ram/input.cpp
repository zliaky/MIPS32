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
		fout << "32'h" << dec2hex(count,8) <<": begin ";
		fout << "bus_data_i <= 32'h" << readLine;
		fout << "; bus_addr_i <= {12'b0, pc[19:0]}; pc <= pc + 1'b1; end" << endl;
		count++;
	}
	fin.close();
	fout.close();

	return 0;
}