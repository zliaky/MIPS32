	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	lui $1, 0x1fd0			#$1=0x1fd00000
	ori $1, $1, 0x400		#$1=0x1fd00400
	ori $2, $0, 0x23		#$2=0x23
	sw $2 0x0($1)			#[0xfd00400]=0x23

_loop:
	j _loop
	nop
