	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop						#0
	lui $1, 0x1fd0			#$1=0x1fd00000 4
	ori $1, $1, 0x3f8		#$1=0x1fd003f8 8
	ori $2, $0, 0x0 		#$2=0x0 c
	ori $3, $0, 0xff 		#$3=0xff 10

_loop:
	sw $2, 0x0($1)			#[0x1fd003f8]=$2
	addiu $2, $2, 0x1 		#$2=$2+0x1
	beq $2, $3, 0x10 		#if($2==$3==0xff) pc=pc+0x10
	nop
	j _loop
	nop

_reset:
	ori $2, $0, 0x0 		#$2=0x0
	j _loop
	nop

