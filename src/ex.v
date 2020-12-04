module ex(
	input wire rst,
	
	input wire[`InstAddrBus] pc_i,
	input wire jmp_status_i,
	
	//recieve from id_ex
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	input wire[`RegBus] reg1_i,
	input wire[`RegBus] reg2_i,
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus] offset_i,
	
	//ex result
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	
	//jmp
	output reg jmp_wrong_o,
	output reg[`InstAddrBus] jmp_target_o,
	output reg opt_is_jmp,
	output wire[`InstAddrBus] ifjmp_target,
	output reg jmp_res,
	
	//load store
	output reg[`AluOpBus] aluop_o,
	output reg[`MemBus] mem_addr_o,
	output reg load_status
);
reg[`RegBus] logicout;
reg[`RegBus] shiftout;
reg[`RegBus] arithout;

//Branch Jal Jalr
wire[`InstAddrBus] tmp;
assign ifjmp_target=pc_i+offset_i;
assign tmp=reg1_i+reg2_i;
always @(*) begin
	if(rst==`RstEnable)begin
		jmp_wrong_o=`False;
		jmp_target_o=`ZeroWord;
		opt_is_jmp=`False;
		jmp_res=`False;
	end else begin
		jmp_wrong_o=`False;
		jmp_target_o=`ZeroWord;
		opt_is_jmp=`False;
		jmp_res=`False;
		case(aluop_i)
			`EX_JAL:begin
				opt_is_jmp=`True;
				jmp_wrong_o=!jmp_status_i;
				jmp_target_o=pc_i+offset_i;
				jmp_res=`True;
			end
			`EX_JALR:begin
				jmp_wrong_o=`True;
				jmp_target_o={tmp[31:1],1'b0};
			end
			`EX_BEQ:begin
				opt_is_jmp=`True;
				if(reg1_i==reg2_i)begin
					jmp_wrong_o=!jmp_status_i;
					jmp_target_o=pc_i+offset_i;
					jmp_res=`True;
				end else begin
					jmp_wrong_o=jmp_status_i;
					jmp_target_o=pc_i+4;
				end
			end
			`EX_BNE:begin
				opt_is_jmp=`True;
				if(reg1_i!=reg2_i)begin
					jmp_wrong_o=!jmp_status_i;
					jmp_target_o=pc_i+offset_i;
					jmp_res=`True;
				end else begin
					jmp_wrong_o=jmp_status_i;
					jmp_target_o=pc_i+4;
				end
			end
			`EX_BLT:begin
				opt_is_jmp=`True;
				if($signed(reg1_i)<$signed(reg2_i))begin
					jmp_wrong_o=!jmp_status_i;
					jmp_target_o=pc_i+offset_i;
					jmp_res=`True;
				end else begin
					jmp_wrong_o=jmp_status_i;
					jmp_target_o=pc_i+4;
				end
			end
			`EX_BGE:begin
				opt_is_jmp=`True;
				if($signed(reg1_i)>=$signed(reg2_i))begin
					jmp_wrong_o=!jmp_status_i;
					jmp_target_o=pc_i+offset_i;
					jmp_res=`True;
				end else begin
					jmp_wrong_o=jmp_status_i;
					jmp_target_o=pc_i+4;
				end
			end
			`EX_BLTU:begin
				opt_is_jmp=`True;
				if(reg1_i<reg2_i)begin
					jmp_wrong_o=!jmp_status_i;
					jmp_target_o=pc_i+offset_i;
					jmp_res=`True;
				end else begin
					jmp_wrong_o=jmp_status_i;
					jmp_target_o=pc_i+4;
				end
			end
			`EX_BGEU:begin
				opt_is_jmp=`True;
				if(reg1_i>=reg2_i)begin
					jmp_wrong_o=!jmp_status_i;
					jmp_target_o=pc_i+offset_i;
					jmp_res=`True;
				end else begin
					jmp_wrong_o=jmp_status_i;
					jmp_target_o=pc_i+4;
				end
			end
			default:begin
			end
		endcase
	end
end

//Logic
always @(*) begin
	if(rst==`RstEnable) begin
		logicout=`ZeroWord;
	end else begin
		case (aluop_i)
			`EX_OR:begin
				logicout=reg1_i|reg2_i;
			end
			`EX_AND:begin
				logicout=reg1_i&reg2_i;
			end
			`EX_XOR:begin
				logicout=reg1_i^reg2_i;
			end
			default:begin
				logicout=`ZeroWord;
			end
		endcase
	end
end

//Shift
always @(*) begin
	if(rst==`RstEnable) begin
		shiftout=`ZeroWord;
	end else begin
		case (aluop_i)
			`EX_SLL:begin
				shiftout=reg1_i<<(reg2_i[4:0]);
			end
			`EX_SRL:begin
				shiftout=reg1_i>>(reg2_i[4:0]);
			end
			`EX_SRA:begin
				shiftout=(reg1_i>>(reg2_i[4:0]))|
						({32{reg1_i[31]}}<<(6'd32-{1'b0,reg2_i[4:0]}));
			end
			default:begin
				shiftout=`ZeroWord;
			end
		endcase
	end
end

//Arithmetic
always @(*) begin
	if(rst==`RstEnable) begin
		arithout<=`ZeroWord;
	end else begin
		case (aluop_i)
			`EX_ADD:begin
				arithout=reg1_i+reg2_i;
			end
			`EX_SUB:begin
				arithout=reg1_i-reg2_i;
			end
			`EX_SLT:begin
				arithout=$signed(reg1_i)<$signed(reg2_i);
			end
			`EX_SLTU:begin
				arithout=reg1_i<reg2_i;
			end
			`EX_AUIPC:begin
				arithout=pc_i+offset_i;
			end
			default:begin
				arithout=`ZeroWord;
			end
		endcase
	end

end

//Lord Store
always @(*) begin
	if(rst==`RstEnable)begin
		mem_addr_o=`ZeroWord;
		load_status=`False;
	end else begin
		case(aluop_i)
			`EX_SH,`EX_SB,`EX_SW:begin
				mem_addr_o=reg1_i+offset_i;
				load_status=`False;
			end
			`EX_LW,`EX_LH,`EX_LB,`EX_LHU,`EX_LBU:begin
				mem_addr_o=reg1_i+offset_i;
				load_status=`True;
			end
			default:begin
				mem_addr_o=`ZeroWord;
				load_status=`False;
			end
		endcase
	end
end

//result
always @(*) begin
	if(rst==`RstEnable||wreg_i==`True&&wd_i==`NOPRegAddr)begin
		wd_o=`NOPRegAddr;
		wreg_o=`False;
		wdata_o=`ZeroWord;
		aluop_o=`EX_NOP;
	end else begin
		wd_o=wd_i;
		wreg_o=wreg_i;
		case(alusel_i)
			`EX_RES_LOGIC:begin
				wdata_o=logicout;
				aluop_o=`EX_NOP;
			end
			`EX_RES_SHIFT:begin
				wdata_o=shiftout;
				aluop_o=`EX_NOP;
			end
			`EX_RES_ARITH:begin
				wdata_o=arithout;
				aluop_o=`EX_NOP;
			end
			`EX_RES_JAL:begin
				wdata_o=pc_i+4;
				aluop_o=`EX_NOP;
			end
			`EX_RES_LD_ST:begin
				wdata_o=reg2_i;
				aluop_o=aluop_i;
			end
			default:begin
				wdata_o=`ZeroWord;
				aluop_o=`EX_NOP;
			end
		endcase
	end
end

endmodule