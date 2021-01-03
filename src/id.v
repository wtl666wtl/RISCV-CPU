module id(
	input wire rst,
	input wire[`InstAddrBus] pc_i,
	input wire[`InstBus] inst_i,
	input wire jmp_status_i,
	input wire rdy,
	//recieve from Regfile
	input wire[`RegBus] reg1_data_i,
	input wire[`RegBus] reg2_data_i,
	
	//result from ex
	input wire ex_ld_status,
    input wire ex_wreg_i,
    input wire[`RegBus] ex_wdata_i,
   	input wire[`RegAddrBus] ex_wd_i,

	//result from mem
   	input wire mem_wreg_i,
   	input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_wd_i,

	//send to Regfile
	output reg reg1_read_o,
	output reg reg2_read_o,
	output reg[`RegAddrBus] reg1_addr_o,
	output reg[`RegAddrBus] reg2_addr_o,
	
	//send to id_ex
	output reg[`InstAddrBus] pc_o,
	output reg jmp_status_o,
	output reg[`AluOpBus] aluop_o,
	output reg[`AluSelBus] alusel_o,
	output reg[`RegBus] reg1_o,
	output reg[`RegBus] reg2_o,
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	
	output wire[`RegBus] offset_o,
	
	//id_stall
	output wire id_stall
);
wire[6:0] op=inst_i[6:0];
wire[4:0] rd=inst_i[11:7];
wire[2:0] funct3=inst_i[14:12];
wire[4:0] rs1=inst_i[19:15];
wire[4:0] rs2=inst_i[24:20];
wire[6:0] funct7=inst_i[31:25];

reg[`RegBus] imm;
reg instvalid;
reg reg1_stall;
reg reg2_stall;

//translate
always @(*) begin
	if(rst==`RstEnable) begin
		aluop_o=`EX_NOP;
		alusel_o=`EX_RES_NOP;
		wd_o=`NOPRegAddr;
		wreg_o=`WriteDisable;
		instvalid=`InstValid;
		reg1_read_o=1'b0;
		reg2_read_o=1'b0;
		reg1_addr_o=`NOPRegAddr;
		reg2_addr_o=`NOPRegAddr;
		imm=`ZeroWord;
		//offset_o=`ZeroWord;
		pc_o=`ZeroWord;
		jmp_status_o=`False;
	end else if(rdy) begin
		aluop_o=`EX_NOP;
		alusel_o=`EX_RES_NOP;
		wd_o=rd;
		wreg_o=`WriteDisable;
		instvalid=`InstInvalid;
		reg1_read_o=1'b0;
		reg2_read_o=1'b0;
		reg1_addr_o=rs1;
		reg2_addr_o=rs2;
		imm=`ZeroWord;
		//offset_o=`ZeroWord;
		pc_o=pc_i;
		jmp_status_o=jmp_status_i;
		case(op)
			`OPI:begin
				case(funct3)
					`F3_ADDI:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_ADD;
						alusel_o=`EX_RES_ARITH;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						instvalid=`InstValid;
					end
					`F3_SLTI:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_SLT;
						alusel_o=`EX_RES_ARITH;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						instvalid=`InstValid;
					end
					`F3_SLTIU:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_SLTU;
						alusel_o=`EX_RES_ARITH;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						instvalid=`InstValid;
					end
					`F3_XORI:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_XOR;
						alusel_o=`EX_RES_LOGIC;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						instvalid=`InstValid;
					end
					`F3_ORI:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_OR;
						alusel_o=`EX_RES_LOGIC;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						instvalid=`InstValid;
					end
					`F3_ANDI:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_AND;
						alusel_o=`EX_RES_LOGIC;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						instvalid=`InstValid;
					end
					`F3_SLLI:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_SLL;
						alusel_o=`EX_RES_SHIFT;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={27'h0,inst_i[24:20]};
						instvalid=`InstValid;
					end
					`F3_SRLI:begin
						if(funct7==`F7_SRLI)begin
							wreg_o=`WriteEnable;
							aluop_o=`EX_SRL;
							alusel_o=`EX_RES_SHIFT;
							reg1_read_o=1'b1;
							reg2_read_o=1'b0;
							imm={27'h0,inst_i[24:20]};
							instvalid=`InstValid;
						end
						else if(funct7==`F7_SRAI) begin
							wreg_o=`WriteEnable;
							aluop_o=`EX_SRA;
							alusel_o=`EX_RES_SHIFT;
							reg1_read_o=1'b1;
							reg2_read_o=1'b0;
							imm={27'h0,inst_i[24:20]};
							instvalid=`InstValid;
						end
					end
					default:begin
					end
				endcase
			end
			`OP:begin
				case(funct3)
					`F3_ADD:begin
						if(funct7==`F7_ADD) begin
							wreg_o=`WriteEnable;
							aluop_o=`EX_ADD;
							alusel_o=`EX_RES_ARITH;
							reg1_read_o=1'b1;
							reg2_read_o=1'b1;
							instvalid=`InstValid;
						end else if(funct7==`F7_SUB) begin
							wreg_o=`WriteEnable;
							aluop_o=`EX_SUB;
							alusel_o=`EX_RES_ARITH;
							reg1_read_o=1'b1;
							reg2_read_o=1'b1;
							instvalid=`InstValid;
						end
					end
					`F3_SLT:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_SLT;
						alusel_o=`EX_RES_ARITH;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						instvalid=`InstValid;
					end
					`F3_SLTU:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_SLTU;
						alusel_o=`EX_RES_ARITH;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						instvalid=`InstValid;
					end
					`F3_XOR:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_XOR;
						alusel_o=`EX_RES_LOGIC;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						instvalid=`InstValid;
					end
					`F3_OR:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_OR;
						alusel_o=`EX_RES_LOGIC;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						instvalid=`InstValid;
					end
					`F3_AND:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_AND;
						alusel_o=`EX_RES_LOGIC;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						instvalid=`InstValid;
					end
					`F3_SLL:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_SLL;
						alusel_o=`EX_RES_SHIFT;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						instvalid=`InstValid;
					end
					`F3_SRL:begin
						if(funct7==`F7_SRL)begin
							wreg_o=`WriteEnable;
							aluop_o=`EX_SRL;
							alusel_o=`EX_RES_SHIFT;
							reg1_read_o=1'b1;
							reg2_read_o=1'b1;
							instvalid=`InstValid;
						end
						else if(funct7==`F7_SRA) begin
							wreg_o=`WriteEnable;
							aluop_o=`EX_SRA;
							alusel_o=`EX_RES_SHIFT;
							reg1_read_o=1'b1;
							reg2_read_o=1'b1;
							instvalid=`InstValid;
						end
					end
					default:begin
					end
				endcase
			end
			`LUI:begin
				wreg_o=`WriteEnable;
				aluop_o=`EX_OR;
				alusel_o=`EX_RES_LOGIC;
				reg1_read_o=1'b0;
				reg2_read_o=1'b0;
				imm={inst_i[31:12],12'h0};
				instvalid=`InstValid;
			end
			`AUIPC:begin
				wreg_o=`WriteEnable;
				aluop_o=`EX_AUIPC;
				alusel_o=`EX_RES_ARITH;
				reg1_read_o=1'b0;
				reg2_read_o=1'b0;
				imm={inst_i[31:12],12'h0};
				//offset_o=imm;
				instvalid=`InstValid;
			end
			`BRANCH:begin
				case(funct3)
					`F3_BEQ:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_BEQ;
						alusel_o=`EX_RES_NOP;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_BNE:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_BNE;
						alusel_o=`EX_RES_NOP;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_BLT:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_BLT;
						alusel_o=`EX_RES_NOP;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_BGE:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_BGE;
						alusel_o=`EX_RES_NOP;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_BLTU:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_BLTU;
						alusel_o=`EX_RES_NOP;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_BGEU:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_BGEU;
						alusel_o=`EX_RES_NOP;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					default:begin
					end
				endcase
			end
			`JAL:begin
				wreg_o=`WriteEnable;
				aluop_o=`EX_JAL;
				alusel_o=`EX_RES_JAL;
				reg1_read_o=1'b0;
				reg2_read_o=1'b0;
				imm={{12{inst_i[31]}},inst_i[19:12],inst_i[20],inst_i[30:21],1'h0};
				//offset_o=imm;
				instvalid=`InstValid;
			end
			`JALR:begin
				wreg_o=`WriteEnable;
				aluop_o=`EX_JALR;
				alusel_o=`EX_RES_JAL;
				reg1_read_o=1'b1;
				reg2_read_o=1'b0;
				imm={{20{inst_i[31]}},inst_i[31:20]};
				//offset_o=imm;
				instvalid=`InstValid;
			end
			`LOAD:begin
				case(funct3)
					`F3_LB:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_LB;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_LH:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_LH;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_LW:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_LW;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_LBU:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_LBU;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_LHU:begin
						wreg_o=`WriteEnable;
						aluop_o=`EX_LHU;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b0;
						imm={{20{inst_i[31]}},inst_i[31:20]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					default:begin
					end
				endcase
			end
			`STORE:begin
				case(funct3)
					`F3_SB:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_SB;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[31:25],inst_i[11:7]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_SH:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_SH;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[31:25],inst_i[11:7]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					`F3_SW:begin
						wreg_o=`WriteDisable;
						aluop_o=`EX_SW;
						alusel_o=`EX_RES_LD_ST;
						reg1_read_o=1'b1;
						reg2_read_o=1'b1;
						imm={{20{inst_i[31]}},inst_i[31:25],inst_i[11:7]};
						//offset_o=imm;
						instvalid=`InstValid;
					end
					default:begin
					end
				endcase
			end
			default:begin
			end
		endcase
	end
end

//reg1
always @(*) begin
    reg1_stall=1'b0;
	if(rst==`RstEnable) begin
		reg1_o=`ZeroWord;
	end if(rdy) begin
		if((reg1_read_o==1'b1)&&(ex_ld_status==1'b1)&&(ex_wd_i==reg1_addr_o)) begin
			reg1_o=`ZeroWord;
			reg1_stall=1'b1;
		end else if((reg1_read_o==1'b1)&&(ex_wreg_i==1'b1)&&(ex_wd_i==reg1_addr_o)) begin
			reg1_o=ex_wdata_i;
		end else if((reg1_read_o==1'b1)&&(mem_wreg_i==1'b1)&&(mem_wd_i==reg1_addr_o)) begin
			reg1_o=mem_wdata_i;
		end else if(reg1_read_o==1'b1) begin
			reg1_o=reg1_data_i;
		end else if(reg1_read_o==1'b0) begin
			reg1_o=imm;
		end else begin
			reg1_o=`ZeroWord;
		end
	end
end

//reg2
always @(*) begin
    reg2_stall=1'b0;
	if(rst==`RstEnable) begin
		reg2_o=`ZeroWord;
	end if(rdy) begin
		if((reg2_read_o==1'b1)&&(ex_ld_status==1'b1)&&(ex_wd_i==reg2_addr_o)) begin
			reg2_o=`ZeroWord;
			reg2_stall=1'b1;
		end else if((reg2_read_o==1'b1)&&(ex_wreg_i==1'b1)&&(ex_wd_i==reg2_addr_o)) begin
			reg2_o=ex_wdata_i;
		end else if((reg2_read_o==1'b1)&&(mem_wreg_i==1'b1)&&(mem_wd_i==reg2_addr_o)) begin
			reg2_o=mem_wdata_i;
		end else if(reg2_read_o==1'b1) begin
			reg2_o=reg2_data_i;
		end else if(reg2_read_o==1'b0) begin
			reg2_o=imm;
		end else begin
			reg2_o=`ZeroWord;
		end
	end
end

assign id_stall=reg1_stall|reg2_stall;

assign offset_o=rst?`ZeroWord:imm;

endmodule