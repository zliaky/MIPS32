	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	nop
	li $s0, 0xbe000000
	li $a0, 0xbfd00400
	li $t0, 0x464c457f
	li $t1, 0x464c457f
	beq $t0, $t1, Label
	nop
	b Bad
	nop

_loop:
	j _loop
	nop

Label:
	li $v0, 0x0023
	sw $v0, 0($a0)
	b _loop	
	nop

Bad:
	li $v0, 0x00ee
	sw $v0, 0($a0)
	b _loop	
	nop