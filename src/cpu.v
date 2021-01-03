// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "define.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire rst;
wire rdy;
assign rst=rst_in;
assign rdy=rdy_in;

//pc
wire[`InstAddrBus] pc;
wire[`InstAddrBus] if_pc;
wire[`InstAddrBus] id_pc_i;
wire[`InstAddrBus] id_pc_o;
wire[`InstAddrBus] ex_pc;

//if
wire[`InstBus] if_inst;

//link if_id to id
wire[`InstBus] id_inst_i;

//link id to id_ex
wire[`AluOpBus] id_aluop_o;
wire[`AluSelBus] id_alusel_o;
wire[`RegBus] id_reg1_o;
wire[`RegBus] id_reg2_o;
wire id_wreg_o;
wire[`RegAddrBus] id_wd_o;
wire[`RegBus] id_offset;

//link id_ex to ex
wire[`AluOpBus] ex_aluop_i;
wire[`AluSelBus] ex_alusel_i;
wire[`RegBus] ex_reg1_i;
wire[`RegBus] ex_reg2_i;
wire ex_wreg_i;
wire[`RegAddrBus] ex_wd_i;
wire[`RegBus] ex_offset;

//link ex to ex_mem
wire ex_wreg_o;
wire[`RegAddrBus] ex_wd_o;
wire[`RegBus] ex_wdata_o;
wire[`AluOpBus] ex_aluop_o;
wire[`RegBus] ex_mem_addr;

//ex to id
wire ex_ld_status;

//link ex_mem to mem
wire mem_wreg_i;
wire[`RegAddrBus] mem_wd_i;
wire[`RegBus] mem_wdata_i;
wire[`RegBus] mem_mem_addr;
wire[`AluOpBus] mem_aluop_i;

//link mem to mem_wb
wire mem_wreg_o;
wire[`RegAddrBus] mem_wd_o;
wire[`RegBus] mem_wdata_o;

//link mem_wb to wb
wire wb_wreg_i;
wire[`RegAddrBus] wb_wd_i;
wire[`RegBus] wb_wdata_i;

//link id to regfile
wire reg1_read;
wire reg2_read;
wire[`RegBus] reg1_data;
wire[`RegBus] reg2_data;
wire[`RegAddrBus] reg1_addr;
wire[`RegAddrBus] reg2_addr;

//ex_jmp
wire ex_jmp_wrong;
wire[`InstAddrBus] ex_jmp_target; 
wire opt_is_jmp;
wire[`InstAddrBus] ifjmp_target;
wire jmp_res;

//predict jmp
wire pre_jmp_status;
wire[`InstAddrBus] pre_jmp_target;

//jmp
wire id_jmp_status_i;
wire id_jmp_status_o;
wire ex_jmp_status;

//stall
wire[`StallBus] stall;
wire if_stall;
wire id_stall;
wire mem_stall;

//icache
wire icache_inst_enable;
wire[`InstBus] icache_inst_data;
wire[`InstAddrBus] icache_inst_addr;

//mem_ctrl
wire mc_inst_busy;
wire mc_inst_enable;
wire[`InstBus] mc_inst_data;
wire mc_inst_require;
wire[`InstAddrBus] mc_inst_addr;

wire mc_mem_busy;
wire mc_mem_enable;
wire[`RegBus] mc_mem_data_o;
wire mc_mem_require;
wire mc_mem_wr;
wire[`RegBus] mc_mem_addr;
wire[`RegBus] mc_mem_data_i;
wire[2:0] mc_mem_length;

//regfile
regfile regfile0(.clk(clk_in),.rst(rst),.rdy(rdy),
		.we(wb_wreg_i),.waddr(wb_wd_i),.wdata(wb_wdata_i),
		.re1(reg1_read),.raddr1(reg1_addr),.rdata1(reg1_data),
		.re2(reg2_read),.raddr2(reg2_addr),.rdata2(reg2_data));

//predictor
predictor predictor0(.clk(clk_in),.rst(rst),.rdy(rdy),
		.pc_if(pc),.pre_jmp_status(pre_jmp_status),
		.pre_jmp_target(pre_jmp_target),
		.pc_ex(ex_pc),.opt_is_jmp(opt_is_jmp),
		.ifjmp_target(ifjmp_target),.jmp_res(jmp_res));

//pc_reg
pc_reg pc_reg0(.clk(clk_in),.rst(rst),.stall(stall),.rdy(rdy),
		.ex_jmp_wrong_i(ex_jmp_wrong),.ex_jmp_target_i(ex_jmp_target),
		.pre_jmp_status(pre_jmp_status),.pre_jmp_target(pre_jmp_target),
		.pc(pc),.jmp_status(id_jmp_status_i));

//if
IF if0(.rst(rst),.pc_i(pc),.pc_o(if_pc),.inst_o(if_inst),.rdy(rdy),
		.inst_enable_i(icache_inst_enable),.inst_data_i(icache_inst_data),
		.inst_addr_o(icache_inst_addr),.if_stall(if_stall));
		
//icache
icache icache0(.clk(clk_in),.rst(rst),.rdy(rdy),
		.inst_busy(mc_inst_busy),.inst_enable_i(mc_inst_enable),
		.inst_data_i(mc_inst_data),
		.inst_require_o(mc_inst_require),.inst_addr_o(mc_inst_addr),
		.inst_addr_i(icache_inst_addr),.inst_enable_o(icache_inst_enable),
		.inst_data_o(icache_inst_data));

//if_id
if_id if_id0(.clk(clk_in),.rst(rst),.stall(stall),.rdy(rdy),
		.if_pc(if_pc),.if_inst(if_inst),.ex_jmp_wrong_i(ex_jmp_wrong),
		.id_pc(id_pc_i),.id_inst(id_inst_i));
		
//id
id id0(.rst(rst),.pc_i(id_pc_i),.inst_i(id_inst_i),.jmp_status_i(id_jmp_status_i),.rdy(rdy),
		.reg1_data_i(reg1_data),.reg2_data_i(reg2_data),.ex_ld_status(ex_ld_status),
		.ex_wreg_i(ex_wreg_o),.ex_wdata_i(ex_wdata_o),.ex_wd_i(ex_wd_o),
		.mem_wreg_i(mem_wreg_o),.mem_wdata_i(mem_wdata_o),.mem_wd_i(mem_wd_o),
		.reg1_read_o(reg1_read),.reg2_read_o(reg2_read),
		.reg1_addr_o(reg1_addr),.reg2_addr_o(reg2_addr),
		.pc_o(id_pc_o),.jmp_status_o(id_jmp_status_o),
		.aluop_o(id_aluop_o),.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),.wreg_o(id_wreg_o),
		.offset_o(id_offset),.id_stall(id_stall));

//id_ex
id_ex id_ex0(.clk(clk_in),.rst(rst),.rdy(rdy),
		.id_aluop(id_aluop_o),.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),.id_wreg(id_wreg_o),
		.id_pc(id_pc_o),.offset_i(id_offset),
		.jmp_status_i(id_jmp_status_o),.stall(stall),
		.ex_jmp_wrong_i(ex_jmp_wrong),
		.ex_aluop(ex_aluop_i),.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),.ex_wreg(ex_wreg_i),
		.ex_pc(ex_pc),.offset_o(ex_offset),
		.jmp_status_o(ex_jmp_status));

//ex
ex ex0(.rst(rst),.rdy(rdy),
		.pc_i(ex_pc),.jmp_status_i(ex_jmp_status),
		.aluop_i(ex_aluop_i),.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),.wreg_i(ex_wreg_i),.offset_i(ex_offset),
		.wd_o(ex_wd_o),.wreg_o(ex_wreg_o),.wdata_o(ex_wdata_o),
		.jmp_wrong_o(ex_jmp_wrong),.jmp_target_o(ex_jmp_target),
		.opt_is_jmp(opt_is_jmp),.ifjmp_target(ifjmp_target),.jmp_res(jmp_res),
		.aluop_o(ex_aluop_o),.mem_addr_o(ex_mem_addr),
		.load_status(ex_ld_status));

//ex_mem
ex_mem ex_mem0(.clk(clk_in),.rst(rst),.rdy(rdy),
		.ex_wd(ex_wd_o),.ex_wreg(ex_wreg_o),.ex_wdata(ex_wdata_o),
		.ex_mem_addr(ex_mem_addr),.ex_aluop(ex_aluop_o),
		.stall(stall),
		.mem_wd(mem_wd_i),.mem_wreg(mem_wreg_i),.mem_wdata(mem_wdata_i),
		.mem_mem_addr(mem_mem_addr),.mem_aluop(mem_aluop_i));

//mem
mem mem0(.rst(rst),.rdy(rdy),
		.wd_i(mem_wd_i),.wreg_i(mem_wreg_i),.wdata_i(mem_wdata_i),
		.aluop_i(mem_aluop_i),.addr_i(mem_mem_addr),
		.wd_o(mem_wd_o),.wreg_o(mem_wreg_o),.wdata_o(mem_wdata_o),
		.mem_busy_i(mc_mem_busy),.mem_enable_i(mc_mem_enable),
		.mem_data_i(mc_mem_data_o),.mem_require_o(mc_mem_require),
		.mem_wr_o(mc_mem_wr),.mem_addr_o(mc_mem_addr),
		.mem_length_o(mc_mem_length),.mem_data_o(mc_mem_data_i),
		.mem_stall(mem_stall));

//mem_wb
mem_wb mem_wb0(.clk(clk_in),.rst(rst),.rdy(rdy),
		.mem_wd(mem_wd_o),.mem_wreg(mem_wreg_o),.mem_wdata(mem_wdata_o),
		.stall(stall),
		.wb_wd(wb_wd_i),.wb_wreg(wb_wreg_i),.wb_wdata(wb_wdata_i));

//mem_ctrl
mem_ctrl mem_ctrl0(.clk(clk_in),.rst(rst),.rdy(rdy),
		.ex_jmp_wrong_i(ex_jmp_wrong),
		.inst_require(mc_inst_require),.inst_addr(mc_inst_addr),
		.inst_data(mc_inst_data),.inst_enable(mc_inst_enable),.inst_busy(mc_inst_busy),
		.mem_require(mc_mem_require),.mem_wr(mc_mem_wr),
		.mem_addr(mc_mem_addr),.mem_length(mc_mem_length),
		.mem_data(mc_mem_data_i),.mem_enable(mc_mem_enable),
		.mem_data_o(mc_mem_data_o),.mem_busy(mc_mem_busy),
		.ram_in(mem_din),.ram_out(mem_dout),
		.ram_addr(mem_a),.ram_wr(mem_wr),.io_buffer_full(io_buffer_full));

//stall_ctrl
ctrl ctrl0(.rst(rst),.rdy(rdy),
		.if_stall(if_stall),.id_stall(id_stall),
		.mem_stall(mem_stall),.stall(stall));

endmodule