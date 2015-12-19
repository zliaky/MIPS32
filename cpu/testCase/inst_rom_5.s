.org 0x0
.global _start
.set noat
_start:
	nop
	lui $1, 0x0000	# $1 = 0x00000000
	lui $2, 0xffff	# $2 = 0xffff0000
	mthi $0		# hi = 0x00000000
	mthi $1		# hi = 0x00000000
	mthi $2		# hi = 0xffff0000
	mfhi $4		# $4 = 0xffff0000

