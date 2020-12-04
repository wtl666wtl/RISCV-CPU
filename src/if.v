module IF(
	input wire rst,
	
	input wire[`InstAddrBus] pc_i,

	output reg[`InstAddrBus] pc_o,
	output reg[`InstBus] inst_o,
	
	//recieve from icache
	input wire inst_enable_i,
	input wire[`InstBus] inst_data_i,
	
	//send to icache
	output reg[`InstAddrBus] inst_addr_o,
	
	output wire if_stall
);
assign if_stall=!inst_enable_i;

always @(*) begin
	if(rst==`RstEnable)begin
		pc_o=`ZeroWord;
		inst_addr_o=`ZeroWord;
	end else begin
		pc_o=pc_i;
		inst_addr_o=pc_i;
	end
	if(rst!=`RstEnable && inst_enable_i)begin
		inst_o=inst_data_i;
	end else begin
		inst_o=`ZeroWord;
	end
end

endmodule
