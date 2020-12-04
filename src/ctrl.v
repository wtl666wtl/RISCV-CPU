module ctrl(
	input wire rst,
	input wire if_stall,
	input wire id_stall,
	input wire mem_stall,
	output reg[`StallBus] stall
);

always @(*) begin
	if(rst==`RstEnable) begin
		stall=`AllStall;
	end else if(mem_stall==`Stop)begin
		stall=`MemStall;
	end else if(id_stall==`Stop)begin
		stall=`IdStall;
	end else if(if_stall==`Stop)begin
		stall=`IfStall;	
	end else begin
		stall=`NoStall;
	end
end
endmodule