	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	lui $1, 0x1e00			#$1=0x1e000000
	ori $1, $1, 0x4			#$1=0x1e000004

	lw $2, 0xc($1)			#$2=0x00000000
	lw $1, 0x4($1)			#$1=0x00000101

_loop:
	j _loop
	nop
