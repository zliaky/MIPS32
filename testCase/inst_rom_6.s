.org 0x0
.global _start
.set noat
_start:
	nop
	# 给寄存器$1、$2、$3、$4赋初值
	lui $1, 0x0000	# $1 = 0x00000000
	lui $2, 0xffff	# $2 = 0xffff0000
	lui $3, 0x0505	# $3 = 0x05050000
	lui $4, 0x0000	# $4 = 0x00000000

	# 对于movz指令而言，由于寄存器$1为0，所以将$2的值赋给$4
	movz $4, $2, $1	# $4 = 0xffff0000
	
	# 对于movn指令而言，由于寄存器$1为0，所以不赋值，$4保持不变
	movn $4, $3, $1	# $4 = 0xffff0000

	# 对于movn指令而言，由于寄存器$2不为0，所以将$3的值赋给$4
	movn $4, $3, $2	# $4 = 0x05050000

	# 对于movz指令而言，由于寄存器$3不为0，所以不赋值，$4的值保持不变
	movz $4, $2, $3	# $4 = 0x05050000

	# 连续三条mthi指令，分别将寄存器$0, $2, $3的值保存到HI寄存器
	mthi $0		# hi = 0x00000000
	mthi $2		# hi = 0xffff0000
	mthi $3		# hi = 0x05050000

	# 读取HI寄存器的值到$4，同时可验证HI、LO寄存器带来的数据相关问题是否处理正确
	mfhi $4		# $4 = 0x05050000

	# 连续三条mtlo，分别将寄存器$3、$2、$1的值保存到LO寄存器
	mtlo $3		# lo = 0x05050000
	mtlo $2		# lo = 0xffff0000
	mtlo $1		# lo = 0x00000000

	# 读取LO寄存器的值到$4，同时可验证HI、LO寄存器带来的数据相关问题是否处理正确
	mflo $4		# $4 = 0x00000000
