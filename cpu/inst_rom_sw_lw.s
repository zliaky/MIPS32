.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:

	#第一段：测试sb、lb、lbu指令
	ori $3, $0, 0xeeff		#$3=0x0000eeff
	sw $3, 0x4($0)			#向RAM地址0x4处存储0x0000eeff，[0x4]=0x0000eeff

	srl $3, $3, 8			#逻辑右移8位，$3=0x000000ee
	sw $3, 0x8($0)			#向RAM地址0x8处存储0xee,[0x8]=0xee

	lw $1, 0x4($0)			#加载0x4处字节并做符号扩展，$1=0x0000eeff
	lhu $1, 0x8($0)			#加载0x8处字节并做无符号扩展，$1=0x000000ee

_loop:
	j _loop
	nop

