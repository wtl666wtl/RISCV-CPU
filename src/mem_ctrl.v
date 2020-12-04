module mem_ctrl(
	input wire clk,
	input wire rst,
	
	input ex_jmp_wrong_i,
	
	//interact with icache
	input inst_require,
	input wire[`InstAddrBus] inst_addr,
	
	output reg[`InstBus] inst_data,
	output reg inst_enable,
	output reg inst_busy,
	
	//interact with mem
	input wire mem_require,
	input wire mem_wr,
	input wire[`RegBus] mem_addr,
	input wire[2:0] mem_length,
	input wire[`RegBus] mem_data,
	
	output reg mem_enable,
	output reg[`RegBus] mem_data_o,
	output reg mem_busy,
	
	//interact with ram
	input wire [7:0]ram_in,
	
	output wire[7:0]ram_out,
	output wire[`InstAddrBus] ram_addr,
	output wire ram_wr//write=1 read=0
);
wire[31:0] addr;
reg[7:0] ldata[3:0];
wire[7:0] sdata[3:0];
reg[2:0] counter;
wire[2:0] length;

assign sdata[0]=mem_data[7:0];
assign sdata[1]=mem_data[15:8];
assign sdata[2]=mem_data[23:16];
assign sdata[3]=mem_data[31:24];

assign length=mem_require?mem_length[2:0]:(inst_require?4:0);
assign addr=mem_require?mem_addr[31:0]:inst_addr[31:0];
assign ram_wr=mem_require?(counter==length?`False:mem_wr):`False;
assign ram_addr=addr+counter;
assign ram_out=(counter==3'b100)?`ZeroWord:sdata[counter];

always @(posedge clk)begin
	if(rst==`RstEnable||(ex_jmp_wrong_i&&!mem_require))begin
		counter<=0;
		mem_busy<=`False;
		inst_busy<=`False;
		mem_enable<=`False;
		inst_enable<=`False;
		ldata[0]<=0;
		ldata[1]<=0;
		ldata[2]<=0;
		ldata[3]<=0;
	end else if(length&&!ram_wr)begin
		if(counter==0)begin
			inst_busy<=mem_require;
			mem_busy<=!mem_require;
			inst_enable<=`False;
			mem_enable<=`False;
			counter<=counter+1;
		end else if(counter<length)begin
			counter<=counter+1;
			ldata[counter-1]=ram_in;
		end else begin
			if(mem_require==`True)begin
			    mem_enable<=`True;
				if(mem_length==3'b001)begin
					mem_data_o<=ram_in;
				end else if(mem_length==3'b010)begin
					mem_data_o<={ram_in,ldata[0]};
				end else if(mem_length==3'b100)begin
					mem_data_o<={ram_in,ldata[2],ldata[1],ldata[0]};
				end
			end else begin
				inst_data<={ram_in,ldata[2],ldata[1],ldata[0]};
				inst_enable<=`True;
			end
			counter<=0;
		end
	end else if(length&&ram_wr)begin
		if(counter==0)begin
			inst_busy<=`True;
			mem_busy<=`False;
			inst_enable<=`False;
			mem_enable<=`False;
		end
		if(counter+1==length)begin
			mem_enable<=`True;
			counter<=0;
		end else begin
			counter<=counter+1;
		end
	end else begin
		mem_busy<=`False;
		inst_busy<=`False;
		mem_enable<=`False;
		inst_enable<=`False;
	end
end

endmodule