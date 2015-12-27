	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	li $1, 0xbe000000
	li $6, 0xbfd00400
	lw $2, 0x0($1)
	lw $3, 0x4($1)
	sll $3, $3, 0x10
	or $4, $2, $3
	lui $5, 0x464c
	ori $5, 0x007f
	beq $4, $5, Label
	nop
	b bad
	nop

_loop:
	j _loop
	nop

Label:
	li $7, 0x0023
	sw $7, 0($6)
	j _loop
	nop

bad:
	li $7, 0x00ee
	sw $7, 0($6)
	j bad
	nop
