	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	lui $1, 0x1fd0			#$1=0x1fd00000
	ori $1, $1, 0x03fc		#$1=0x1fd003fc
	ori $2, $0, 0x80		#$2=0x80
	sw $2, 0x0($1)			#向0x1fd003fc写入0x80

	ori $3, $0, 0x0

_loop1:
	addi $3, $3, 0x1
	sb $3, 0x0($1)			#向0x1fd003fc写入$3

_loop2:
	lb $4, 0x0($1)			#获取0x1fd003fc的值

	andi $4, $4, 0x20
	beq $2, $0, _loop2

	nop
	j _loop1
	nop