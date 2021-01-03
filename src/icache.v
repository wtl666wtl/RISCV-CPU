module icache(
	input wire rst,
	input wire clk,
	input wire rdy,
	//recieve from mem_ctrl
	input wire inst_busy,
	input wire inst_enable_i,
	input wire[`InstBus] inst_data_i,
	
	//send to mem_ctrl
	output reg inst_require_o,
	output wire[`InstAddrBus] inst_addr_o,
	
	input wire[`InstAddrBus] inst_addr_i,
	
	//send to if
	output reg inst_enable_o,
	output reg[`InstBus] inst_data_o
);
assign inst_addr_o=inst_addr_i;

reg[`TagBus] tag[`IndexSize-1:0];
reg[`InstBus] data[`IndexSize-1:0];

integer i;

always @(posedge clk)begin
	if(rst==`RstEnable)begin
		for(i=0;i<`IndexSize;i=i+1)begin
			tag[i][`ValidBit]<=`InstInvalid;
		end
	end else if(rdy&&inst_enable_i==`True) begin
		tag[inst_addr_i[`IndexBus]]<=inst_addr_i[`TagBits];
		data[inst_addr_i[`IndexBus]]<=inst_data_i;
	end
end

always @(*) begin
	if(rst==`RstEnable)begin
		inst_require_o=`False;
		inst_enable_o=`False;
		inst_data_o=`ZeroWord;
	end else if(rdy)begin
		if(tag[inst_addr_i[`IndexBus]]==inst_addr_i[`TagBits])begin
			inst_enable_o=`True;
			inst_data_o=data[inst_addr_i[`IndexBus]];
			inst_require_o=`False;
		end else if(inst_enable_i==`True)begin
			inst_enable_o=`True;
			inst_data_o=inst_data_i;
			inst_require_o=`False;
		end else if(!inst_busy)begin
			inst_enable_o=`False;
			inst_data_o=`ZeroWord;
			inst_require_o=`True;
		end else begin
			inst_require_o=`False;
			inst_enable_o=`False;
			inst_data_o=`ZeroWord;
		end
	end
end

endmodule