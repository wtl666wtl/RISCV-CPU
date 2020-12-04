module pc_reg(
	input wire clk,
	input wire rst,
	
	input wire[`StallBus] stall,
	
	input wire ex_jmp_wrong_i,
	input wire[`InstAddrBus] ex_jmp_target_i,
	
	input wire pre_jmp_status,
	input wire[`InstAddrBus] pre_jmp_target,
	
	output reg[`InstAddrBus] pc,
	output reg jmp_status
);
always @ (posedge clk)begin
	if(rst==`RstEnable)begin
		pc<=`ZeroWord;
		jmp_status<=`False;
	end else if(stall[2]==`NoStop)begin
		if(ex_jmp_wrong_i==`True)begin
			pc<=ex_jmp_target_i;
			jmp_status=`False;
		end else if(stall[0]==`NoStop)begin
			if(pre_jmp_status==`True)begin
				pc<=pre_jmp_target;
				jmp_status<=`True;
			end else begin
				pc<=pc+4;
				jmp_status<=`False;
			end
		end
	end
end
endmodule