module id_ex(
	input wire clk,
	input wire rst,
	input wire rdy,
	//recieve from id
	input wire[`AluOpBus] id_aluop,
	input wire[`AluSelBus] id_alusel,
	input wire[`RegBus] id_reg1,
	inout wire[`RegBus] id_reg2,
	input wire[`RegAddrBus] id_wd,
	input wire id_wreg,
	input wire[`InstAddrBus] id_pc,
	input wire[`InstAddrBus] offset_i,
	input wire jmp_status_i,
	
	input wire[`StallBus] stall,
	
	input wire ex_jmp_wrong_i,
	
	//send to ex
	output reg[`AluOpBus] ex_aluop,
	output reg[`AluSelBus] ex_alusel,
	output reg[`RegBus] ex_reg1,
	output reg[`RegBus] ex_reg2,
	output reg[`RegAddrBus] ex_wd,
	output reg ex_wreg,
	output reg[`InstAddrBus] ex_pc,
	output reg[`InstAddrBus] offset_o,
	output reg jmp_status_o

);
always @(posedge clk)begin
	if(rst==`RstEnable)begin
		ex_aluop<=`EX_NOP;
		ex_alusel<=`EX_RES_NOP;
		ex_reg1<=`ZeroWord;
		ex_reg2<=`ZeroWord;
		ex_wd<=`NOPRegAddr;
		ex_wreg<=`WriteDisable;
		ex_pc<=`ZeroWord;
		offset_o<=`ZeroWord;
		jmp_status_o<=`False;
	end else if(rdy&&stall[3]==`NoStop)begin
		if(ex_jmp_wrong_i==`True)begin
			ex_aluop<=`EX_NOP;
			ex_alusel<=`EX_RES_NOP;
			ex_reg1<=`ZeroWord;
			ex_reg2<=`ZeroWord;
			ex_wd<=`NOPRegAddr;
			ex_wreg<=`WriteDisable;
			ex_pc<=`ZeroWord;
			offset_o<=`ZeroWord;
			jmp_status_o<=`False;
		end else if(stall[2]==`NoStop)begin
			ex_aluop<=id_aluop;
			ex_alusel<=id_alusel;
			ex_reg1<=id_reg1;
			ex_reg2<=id_reg2;
			ex_wd<=id_wd;
			ex_wreg<=id_wreg;
			ex_pc<=id_pc;
			offset_o<=offset_i;
			jmp_status_o<=jmp_status_i;
		end else begin
			ex_aluop<=`EX_NOP;
			ex_alusel<=`EX_RES_NOP;
			ex_reg1<=`ZeroWord;
			ex_reg2<=`ZeroWord;
			ex_wd<=`NOPRegAddr;
			ex_wreg<=`WriteDisable;
			ex_pc<=`ZeroWord;
			offset_o<=`ZeroWord;
			jmp_status_o<=`False;
		end
	end
end
endmodule