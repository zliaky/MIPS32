	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	ori $1, $0, 0x1234			#$1=0x00001234
	sw $1, 0x0($0)				#向数据存储器的地址0x0处存储0x00001234,[0x0]=0x00001234

	ori $2, $0, 0x1234			#设置寄存器$2=0x00001234
	ori $1, $0, 0x0 			#设置寄存器$1=0x00000000

	lw $1, 0x0($0) 				#从RAM的地址0x0将数据加载到寄存器$1,$1=0x00001234

	beq $1, $2, Label 			#比较寄存器$1与$2，相等，转移到Label处
	nop

	ori $1, $0, 0x4567
	nop

Label:
	ori $1, $0, 0x89ab 			#设置寄存器$1=0x000089ab
	nop

_loop:
	j _loop
	nop
