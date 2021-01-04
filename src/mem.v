module mem(
	input wire rst,
	input wire rdy,
	//recieve from ex_mem
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus] wdata_i,
	input wire[`AluOpBus] aluop_i,
	input wire[`MemBus] addr_i,

	//mem result
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	
	//recieve from mem_ctrl
	input wire mem_busy_i,
	input wire mem_enable_i,
	input wire[`RegBus] mem_data_i,
	
	//send to mem_ctrl
	output reg mem_require_o,
	output reg mem_wr_o,//write=1 read=0
	output reg[`RegBus] mem_addr_o,
	output reg[2:0] mem_length_o,
	output reg[`RegBus] mem_data_o,
		
	output reg mem_stall
);
always @(*) begin
	if(rst==`RstEnable) begin
		mem_require_o=`False;
   		mem_wr_o=`False;
  	 	mem_data_o=`ZeroWord;
   		mem_addr_o=`ZeroWord;
   		mem_length_o=0;
   		mem_stall=`False;
		wd_o=`NOPRegAddr;
		wreg_o=`WriteDisable;
		wdata_o=`ZeroWord;
	end else begin
		mem_require_o=`False;
   		mem_wr_o=`False;
  	 	mem_data_o=`ZeroWord;
   		mem_addr_o=`ZeroWord;
   		mem_length_o=0;
   		mem_stall=`False;
		wd_o=wd_i;
		wreg_o=wreg_i;
		wdata_o=`ZeroWord;
		case(aluop_i)
			`EX_NOP:begin
				wdata_o=wdata_i;
			end
			`EX_LB:begin
				if(mem_enable_i)begin
					wdata_o={{24{mem_data_i[7]}},mem_data_i[7:0]};
				end else begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_addr_o=addr_i;
						mem_length_o=3'b001;
					end
				end
			end
			`EX_LBU:begin
				if(mem_enable_i)begin
					wdata_o={24'b0,mem_data_i[7:0]};
				end else begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_addr_o=addr_i;
						mem_length_o=3'b001;
					end
				end
			end
			`EX_LH:begin
				if(mem_enable_i)begin
					wdata_o={{16{mem_data_i[15]}},mem_data_i[15:0]};
				end else begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_addr_o=addr_i;
						mem_length_o=3'b010;
					end
				end
			end
			`EX_LHU:begin
				if(mem_enable_i)begin
					wdata_o={16'b0,mem_data_i[15:0]};
				end else begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_addr_o=addr_i;
						mem_length_o=3'b010;
					end
				end
			end
			`EX_LW:begin
				if(mem_enable_i)begin
					wdata_o=mem_data_i;
				end else begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_addr_o=addr_i;
						mem_length_o=3'b100;
					end
				end
			end
			`EX_SB:begin
				if(!mem_enable_i)begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_wr_o=`True;
						mem_addr_o=addr_i;
						mem_data_o=wdata_i[7:0];
						mem_length_o=3'b001;
					end
				end
			end
			`EX_SH:begin
				if(!mem_enable_i)begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_wr_o=`True;
						mem_addr_o=addr_i;
						mem_data_o=wdata_i[15:0];
						mem_length_o=3'b010;
					end
				end
			end
			`EX_SW:begin
				if(!mem_enable_i)begin
					mem_stall=`True;
					if(!mem_busy_i)begin
						mem_require_o=`True;
						mem_wr_o=`True;
						mem_addr_o=addr_i;
						mem_data_o=wdata_i;
						mem_length_o=3'b100;
					end
				end
			end
			default:begin
			end
		endcase
	end
end

endmodule