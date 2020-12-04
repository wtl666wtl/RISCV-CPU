module if_id(
	input wire clk,
	input wire rst,
	input wire[`StallBus] stall,
	input wire[`InstAddrBus] if_pc,
	input wire[`InstBus] if_inst,
	
	input wire ex_jmp_wrong_i,
	
	output reg[`InstAddrBus] id_pc,
	output reg[`InstBus] id_inst
);
	always @ (posedge clk)begin
		if(rst==`RstEnable)begin
			id_pc<=`ZeroWord;
			id_inst<=`ZeroWord;
		end else if(stall[2]==`NoStop)begin
			if(ex_jmp_wrong_i)begin
				id_pc<=`ZeroWord;
				id_inst<=`ZeroWord;
			end else if(stall[1]==`NoStop)begin
				id_pc<=if_pc;
				id_inst<=if_inst;
			end else begin
				id_pc<=`ZeroWord;
				id_inst<=`ZeroWord;
			end
		end else begin
		end
	end
endmodule