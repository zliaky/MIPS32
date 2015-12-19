	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	ori $1, $0, 0xf			#$1=0xf
	mtc0 $1, $12, 0x0 		#将0xf写入CP0中的Compare寄存器

	lui $1, 0x1000
	ori $1, $1, 0x401 		#$1=0x10000401
	mtc0 $1, $13, 0x0 		#将0x10000401写入CP0中的Status寄存器
	mfc0 $2, $13, 0x0 		#读Status寄存器，保存到寄存器$2,$2=0x10000401

_loop:
	j _loop
	nop
