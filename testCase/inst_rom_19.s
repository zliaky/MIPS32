	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	lui $1, 0x1fc0			#$1=0x1fc00000
	ori $1, $1, 0x4			#$1=0x1fc00004
	lw $2 0x0($1)			#$2=[0x1fc00004]=0x3c011fd0
	lw $3 0x4($1)			#$3=[0x1fc00008]=0x34210400
	lw $4 0x8($1)			#$4=[0x1fc0000c]=0x34020023
	lw $5 0xc($1)			#$5=[0x1fc00010]=0xac220000
	lw $6 0x10($1)			#$6=[0x1fc00014]=0x08000005
	lw $7 0x14($1)			#$7=[0x1fc00018]=0x00000000
	lw $8 0x18($1)			#$8=[0x1fc0001c]=0x00000000

_loop:
	j _loop
	nop
