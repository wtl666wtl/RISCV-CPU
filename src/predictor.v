module predictor(
	input wire clk,
	input wire rst,
	input wire rdy,
	input wire[`InstAddrBus] pc_if,
	
	output reg pre_jmp_status,
	output reg[`InstAddrBus] pre_jmp_target,
	
	input wire[`InstAddrBus] pc_ex,
	input wire opt_is_jmp,
	input wire[`InstAddrBus] ifjmp_target,
	input wire jmp_res
);
reg[`TagBus] tag[`IndexSize-1:0];
reg[`InstAddrBus] target[`IndexSize-1:0];
reg[1:0] pre[`IndexSize-1:0];
integer i;

always @(posedge clk)begin
	if(rst)begin
		for(i=0;i<`IndexSize;i=i+1)begin
			tag[i][`ValidBit]<=`InstInvalid;
			pre[i]<=2'b10;
		end
	end else if(rdy&&opt_is_jmp==`True)begin
		if(jmp_res==`True)begin
			tag[pc_ex[`IndexBus]]<=pc_ex[`TagBits];
			target[pc_ex[`IndexBus]]<=ifjmp_target;
			if(pre[pc_ex[`IndexBus]]<2'b11)begin
				pre[pc_ex[`IndexBus]]<=pre[pc_ex[`IndexBus]]+1;
			end
		end else begin
			tag[pc_ex[`IndexBus]]<=pc_ex[`TagBits];
			target[pc_ex[`IndexBus]]<=ifjmp_target;
			if(pre[pc_ex[`IndexBus]]>2'b00)begin
				pre[pc_ex[`IndexBus]]<=pre[pc_ex[`IndexBus]]-1;
			end
		end
	end
end

always @(*)begin
	if(rst==`RstEnable)begin
		pre_jmp_status=`False;
		pre_jmp_target=`ZeroWord;
	end else if(rdy)begin
		if(tag[pc_if[`IndexBus]]==pc_if[`TagBits]&&pre[pc_if[`IndexBus]][1]==`True)begin
			pre_jmp_status=`True;
			pre_jmp_target=target[pc_if[`IndexBus]];
		end else begin
			pre_jmp_status=`False;
			pre_jmp_target=`ZeroWord;
		end
	end
end
endmodule