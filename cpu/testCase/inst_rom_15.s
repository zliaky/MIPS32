	.org 0x0
	.set noat
	.set noreorder
	.set nomacro
	.global _start
_start:
	#因为低地址有异常处理例程，所以处理器启动后，就立即转移到0x100处
	nop
	ori $1, $0, 0x100 			#（1）设置寄存器$1=0x100
	jr $1 						#转移到地址0x100处
	nop

	#系统调用异常处理例程
	.org 0x40
	ori $1, $0, 0x8000 			#（3）设置寄存器$1=0x00008000
	mfc0 $1, $16, 0x0 			#（4）获取EPC寄存器的值保存到寄存器$1，$1=0x00000104,
	addi $1, $1, 0x4 			#（5）寄存器$1加4，$1=0x00000108
	mtc0 $1, $16, 0x0 			#将EPC+4的结果保存回EPC寄存器
	eret
	nop

	#主程序，在其中调用syscall指令，从而引起系统调用异常
	.org 0x100
	ori $1, $0, 0x1000 			#（2）设置寄存器$1=0x1000

	nop 						#指令不存在

	ori $1, $0, 0x1001			#（6）设置寄存器$1=0x1001

_loop:
	j _loop
	nop
