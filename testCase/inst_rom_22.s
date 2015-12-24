	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	lui $1, 0x1fd0			#$1=0x1fd00000
	ori $1, $1, 0x3f8		#$1=0x1fd003f8
	lw $2, 0x0($1)
	lw $3, 0x0($1)

_loop:
	j _loop
	nop

