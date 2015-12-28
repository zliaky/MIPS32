	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	li $1, 0xbe000000		#flash起始地址
	li $2, 0x80000100 		#ram起始地址
	li $5, 0xbe001000 		#flash终止地址
	j _begin
	nop

_begin:
	lw $3, 0x0($1) 			#$3=flash[0x0]
	sw $3, 0x0($2) 			#ram[0x0]=$3
	lw $4, 0x0($2)			#$4=ram[0x0]
	addiu $1, $1, 0x4 		#$1=$1+0x4
	addiu $2, $2, 0x4 		#$2=$2+0x4
	beq $1, $5, _loop
	nop
	j _begin
	nop

_loop:
	j _loop
	nop
