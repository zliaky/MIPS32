//*****************			全局的宏定义						*****************
`define RstEnable			1'b1				//复位信号有效
`define RstDisable			1'b0				//复位信号无效
`define ZeroWord			32'h00000000		//32位的数值0
`define WriteEnable			1'b1				//使能写
`define WriteDisable		1'b0				//禁止写
`define ReadEnable			1'b1				//使能读
`define ReadDisable			1'b0				//禁止读
`define AluOpBus			7:0					//译码阶段的输出aluop_o的宽度
`define AluSelBus			2:0					//译码阶段的输出alusel_o的宽度
`define InstValid			1'b0				//指令有效
`define InstInvalid			1'b1				//指令无效
`define Stop				1'b1				//流水线暂停
`define NoStop				1'b0				//流水线继续
`define InDelaySlot			1'b1				//在延迟槽中
`define NotInDelaySlot		1'b0				//不在延迟槽中
`define Branch				1'b1				//转移
`define NotBranch			1'b0				//不转移
`define InterruptAssert		1'b1
`define InterruptNotAssert	1'b0
`define TrapAssert			1'b1
`define TrapNotAssert		1'b0
`define True_v				1'b1				//逻辑“真”
`define False_v				1'b0				//逻辑“假”
`define ChipEnable			1'b1				//芯片使能
`define ChipDisable			1'b0				//芯片禁止

//*****************			与指令有关的宏定义					*****************
`define EXE_AND				6'b100100			//and指令的功能码
`define EXE_OR				6'b100101			//or指令的功能码
`define EXE_XOR				6'b100110			//xor指令的功能码
`define EXE_NOR				6'b100111			//nor指令的功能码
`define EXE_ANDI			6'b001100			//andi指令的指令码
`define EXE_ORI				6'b001101			//ori指令的指令码
`define EXE_XORI			6'b001110			//xori指令的指令码
`define EXE_LUI				6'b001111			//lui指令的指令码

`define EXE_SLL				6'b000000			//sll指令的功能码
`define EXE_SLLV			6'b000100			//sllv指令的功能码
`define EXE_SRL				6'b000010			//srl指令的功能码
`define EXE_SRLV			6'b000110			//srlv指令的功能码
`define EXE_SRA				6'b000011			//sra指令的功能码
`define EXE_SRAV			6'b000111			//srav指令的功能码

`define EXE_MOVZ			6'b001010
`define EXE_MOVN			6'b001011
`define EXE_MFHI			6'b010000
`define EXE_MTHI			6'b010001
`define EXE_MFLO			6'b010010
`define EXE_MTLO			6'b010011

`define EXE_SLT				6'b101010
`define EXE_SLTU			6'b101011
`define EXE_SLTI			6'b001010
`define EXE_SLTIU			6'b001011
`define EXE_ADD				6'b100000
`define EXE_ADDU			6'b100001
`define EXE_SUB				6'b100010
`define EXE_SUBU			6'b100011
`define EXE_ADDI			6'b001000
`define EXE_ADDIU			6'b001001
`define EXE_CLZ				6'b100000
`define EXE_CLO				6'b100001
`define EXE_MULT			6'b011000

`define EXE_MULTU			6'b011001
`define EXE_MUL				6'b000010

`define EXE_J				6'b000010
`define EXE_JAL				6'b000011
`define EXE_JALR			6'b001001
`define EXE_JR				6'b001000
`define EXE_BEQ				6'b000100
`define EXE_BGEZ			5'b00001
`define EXE_BGEZAL			5'b10001
`define EXE_BGTZ			6'b000111
`define EXE_BLEZ			6'b000110
`define EXE_BLTZ			5'b00000
`define EXE_BLTZAL			5'b10000
`define EXE_BNE				6'b000101

`define EXE_LB				6'b100000
`define EXE_LBU				6'b100100
`define EXE_LH				6'b100001
`define EXE_LHU				6'b100101
`define EXE_LW				6'b100011
`define EXE_LWL				6'b100010
`define EXE_LWR				6'b100110
`define EXE_SB				6'b101000
`define EXE_SH				6'b101001
`define EXE_SW				6'b101011
`define EXE_SWL				6'b101010
`define EXE_SWR				6'b101110

`define EXE_SYSCALL			6'b001100
`define EXE_ERET			32'b01000010000000000000000000011000

`define EXE_CACHE			6'b101111			//cache指令的指令码
`define EXE_SPECIAL_INST	6'b000000			//SPECIAL类指令的指令码
`define EXE_REGIMM_INST		6'b000001
`define EXE_SPECIAL2_INST	6'b011100

`define EXE_NOP				6'b000000			//nop指令的指令码

//AluOp
`define EXE_AND_OP			8'b00100100
`define EXE_OR_OP			8'b00100101
`define EXE_XOR_OP			8'b00100110
`define EXE_NOR_OP			8'b00100111
`define EXE_ANDI_OP			8'b01011001
`define EXE_ORI_OP			8'b01011010
`define EXE_XORI_OP			8'b01011011
`define EXE_LUI_OP			8'b01011100

`define EXE_SLL_OP			8'b01111100
`define EXE_SLLV_OP			8'b00000100
`define EXE_SRL_OP			8'b00000010
`define EXE_SRLV_OP			8'b00000110
`define EXE_SRA_OP			8'b00000011
`define EXE_SRAV_OP			8'b00000111

`define EXE_MOVZ_OP			8'b00001010
`define EXE_MOVN_OP			8'b00001011
`define EXE_MFHI_OP			8'b00010000
`define EXE_MTHI_OP			8'b00010001
`define EXE_MFLO_OP			8'b00010010
`define EXE_MTLO_OP			8'b00010011

`define EXE_SLT_OP			8'b00101010
`define EXE_SLTU_OP			8'b00101011
`define EXE_SLTI_OP			8'b01010111
`define EXE_SLTIU_OP		8'b01011000
`define EXE_ADD_OP			8'b00100000
`define EXE_ADDU_OP			8'b00100001
`define EXE_SUB_OP			8'b00100010
`define EXE_SUBU_OP			8'b00100011
`define EXE_ADDI_OP			8'b01010101
`define EXE_ADDIU_OP		8'b01010110
`define EXE_CLZ_OP			8'b10110000
`define EXE_CLO_OP			8'b10110001

`define EXE_MULT_OP			8'b00011000
`define EXE_MULTU_OP		8'b00011001
`define EXE_MUL_OP			8'b10101001

`define EXE_J_OP			8'b01001111
`define EXE_JAL_OP			8'b01010000
`define EXE_JALR_OP			8'b00001001
`define EXE_JR_OP			8'b00001000
`define EXE_BEQ_OP			8'b01010001
`define EXE_BGEZ_OP			8'b01000001
`define EXE_BGEZAL_OP		8'b01001011
`define EXE_BGTZ_OP			8'b01010100
`define EXE_BLEZ_OP			8'b01010011
`define EXE_BLTZ_OP			8'b01000000
`define EXE_BLTZAL_OP		8'b01001010
`define EXE_BNE_OP			8'b01010010

`define EXE_LB_OP			8'b11100000
`define EXE_LBU_OP			8'b11100100
`define EXE_LH_OP			8'b11100001
`define EXE_LHU_OP			8'b11100101
`define EXE_LL_OP			8'b11110000
`define EXE_LW_OP			8'b11100011
`define EXE_LWL_OP			8'b11100010
`define EXE_LWR_OP			8'b11100110
`define EXE_PREF_OP			8'b11110011
`define EXE_SB_OP			8'b11101000
`define EXE_SC_OP			8'b11111000
`define EXE_SH_OP			8'b11101001
`define EXE_SW_OP			8'b11101011
`define EXE_SWL_OP			8'b11101010
`define EXE_SWR_OP			8'b11101110
`define EXE_SYNC_OP			8'b00001111

`define EXE_MFC0_OP			8'b01011101
`define EXE_MTC0_OP			8'b01100000

`define EXE_TLBWI_OP		8'b01100001

`define EXE_SYSCALL_OP		8'b00001100
`define EXE_ERET_OP			8'b01101011
`define EXE_NOP_OP			8'b00000000

//AluSel
`define EXE_RES_LOGIC		3'b001
`define EXE_RES_SHIFT		3'b010
`define EXE_RES_MOVE		3'b011

`define EXE_RES_ARITHMETIC	3'b100	
`define EXE_RES_MUL			3'b101
`define EXE_RES_JUMP_BRANCH	3'b110
`define EXE_RES_LOAD_STORE	3'b111

`define EXE_RES_NOP			3'b000

//*****************			与通用寄存器Regfile有关的宏定义		*****************
`define RegAddrBus			4:0					//Regfile模块的地址线宽度
`define RegBus				31:0				//Regfile模块的数据线宽度
`define RegWidth			32					//通用寄存器的宽度
`define DoubleRegWidth		64					//两倍的通用寄存器的宽度
`define DoubleRegBus		63:0				//两倍的通用寄存器的数据线宽度
`define RegNum				32					//通用寄存器的数量
`define RegNumLog2			5					//寻址通用寄存器使用的地址位数
`define NOPRegAddr			5'b00000

//*****************			与CP0有关的宏定义		*****************
`define CP0_REG_INDEX		5'b00000
`define CP0_REG_ENTRYLO0	5'b00010
`define CP0_REG_ENTRYLO1	5'b00011
`define CP0_REG_BADVADDR	5'b01001
`define CP0_REG_COUNT		5'b01010
`define CP0_REG_ENTRYHI		5'b01011
`define CP0_REG_COMPARE		5'b01100
`define CP0_REG_STATUS		5'b01101
`define CP0_REG_CAUSE		5'b01111
`define CP0_REG_EPC			5'b10000
`define CP0_REG_EBASE		5'b10010

//*****************			与异常中断有关的宏定义		*****************
`define EXCEPTION_INTERRUPT	32'h0000000f
`define EXCEPTION_TLBM		32'h00000001
`define EXCEPTION_TLBL		32'h00000002
`define EXCEPTION_TLBS		32'h00000003
`define EXCEPTION_ADEL		32'h00000004
`define EXCEPTION_ADES		32'h00000005
`define EXCEPTION_SYSCALL	32'h00000008
`define EXCEPTION_RI		32'h0000000a
`define EXCEPTION_CPU		32'h0000000b
`define EXCEPTION_WATCH		32'h00000017
`define EXCEPTION_ERET		32'h0000000e

//*****************			与Wishbone总线有关的宏定义		*****************
`define WB_IDLE				2'b00				//空闲状态
`define WB_BUSY				2'b01				//忙状态
`define WB_WAIT_FOR_STALL	2'b11				//等待暂停结束状态

//*****************			与MMU有关的宏定义		******************
`define WISHBONE_MEMW0_MEMR0_IF0	3'b000		//写访存未完成，读访存未完成，取指未完成
`define WISHBONE_MEMW0_MEMR0_IF1	3'b001		//写访存未完成，读访存未完成，取指已完成
`define WISHBONE_MEMW0_MEMR1_IF0	3'b010		//写访存未完成，读访存已完成，取指未完成
`define WISHBONE_MEMW0_MEMR1_IF1	3'b011		//写访存未完成，读访存已完成，取指已完成
`define WISHBONE_MEMW1_MEMR1_IF1	3'b111		//写访存已完成，读访存已完成，取指已完成

//*****************			与TLB有关的宏定义		******************
`define TLBIndexWidth		4					//TLB索引宽度
`define TLBIndexNum			16					//TLB索引项数
`define TLBIndexBus			3:0					//TLB索引总线
`define TLBDataWidth		64					//TLB数据宽度
`define TLBDataBus			63:0				//TLB数据总线

//*****************			与外设有关的宏定义		******************
`define WB_SELECT_ZERO		16'b0000000000000000
`define WB_SELECT_RAM		16'b0000000000000001
`define WB_SELECT_ROM		16'b0000000000000010
`define WB_SELECT_FLASH		16'b0000000000000100
`define WB_SELECT_VGA		16'b0000000000001000
`define WB_SELECT_UART		16'b0000000000010000
`define WB_SELECT_UART_STAT	16'b0000000000100000
`define WB_SELECT_DIGSEG	16'b0000000001000000
`define WB_SELECT_PS2		16'b0000000010000000

`define WB_DataBus			31:0
`define WB_AddrBus			31:0
`define WB_SelectBus		15:0

//*****************			与数据存储器RAM有关的宏定义			*****************
`define DataAddrBus			31:0				//地址总线宽度
`define DataBus				31:0				//数据总线宽度
`define DataMemNum			2097151				//RAM大小，单位是字，此处是2M word = 8MB
`define DataMemNumLog2		21					//实际使用的地址宽度
`define ByteWidth			7:0					//一个字节的宽度，是8bit

//*****************			与指令存储器ROM有关的宏定义			*****************
`define InstAddrBus			31:0				//指令的地址总线宽度
`define InstBus				31:0				//指令的数据总线宽度

`define InstMemNum			1024				//ROM的实际大小为4MB
`define InstMemNumLog2		10					//ROM实际使用的地址线

`define RomAddrBus			11:0				//ROM的地址总线宽度

//*****************			与FLASH有关的宏定义			*****************
`define FlashAddrBus		22:0				//FLASH的地址总线宽度
`define FlashAddrBusWord	21:0				//FLASH的字模式下地址总线宽度
`define FlashDataBus		15:0				//FLASH的数据总线宽度
`define FlashCtrlBus		7:0					//FLASH的控制总线宽度

//*****************			与UArt有关的宏定义			*****************
`define UartDataBus			7:0					//Uart的数据总线宽度

//*****************			与DigSeg有关的宏定义			*****************
`define DigSegAddrBus		3:0					//DigSeg的地址总线宽度
`define DigSegDataBus		0:6					//DigSeg的数据总线宽度
