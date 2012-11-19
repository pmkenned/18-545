

// Demos scene_int, camera, prg, vga, and ps2

module ryan_demo(
    // LEDS/SWITCHES
    output logic [17:0] LEDR,
    output logic [8:0] LEDG,
    input logic [17:0] switches,
    input logic [3:0] btns,

    // VGA
    output logic HS, VS,
    output logic [23:0] VGA_RGB,
    output logic VGA_clk,
    output logic VGA_blank,

    // SRAM
    output logic sram_oe_b,
    output logic sram_we_b,
    output logic sram_ce_b,
    output logic [19:0] sram_addr,
    inout wire [15:0] sram_io,
    output logic sram_ub_b, sram_lb_b,

    // PS2
    inout PS2_CLK,
    inout PS2_DAT,

    // test input to start prg automatically (no ps2 input required)
    input logic start,
     
    input logic clk);

	logic rst;
	assign rst = ~btns[3];
	logic v0, v1, v2;
	/*logic start;
	assign start = ~btns[0];*/

	logic stripes_sel;

	pixel_buffer_entry_t pb_data_in, pb_data_out;
	logic pb_re;
	assign stripes_sel = switches[0];	

	frame_buffer_handler fbh(.pb_data(pb_data_out),.*);

	keys_t keys;
	logic rendering_done, render_frame;
	vector_t E, U, V, W;
	camera_controller cc(.clk,.rst,.v0,.v1,.v2,
			     .keys(keys),.rendering_done,.render_frame,
			     .E,.U,.V,.W);


	logic [32:0] shift_data;
	logic ps2_clk, ps2_data;
	logic ps2_data_out, ps2_clk_out;
	logic clk_en, data_en, pkt_rec;
	logic[7:0] data_pkt_HD;
	assign data_pkt_HD = 8'hFF;
	assign ps2_clk = clk_en ? 1'b1 : PS2_CLK;
	assign ps2_data = data_en ? 1'b1 : PS2_DAT;
	assign PS2_CLK = clk_en ? ps2_clk_out : 1'bz;
	assign PS2_DAT = data_en ? ps2_data_out : 1'bz;
	ps2		  mouse(.iSTART(start),.iRST_n(~rst),.iCLK_50(clk),
				.ps2_clk(ps2_clk),.ps2_data(ps2_data),
				.ps2_clk_out(ps2_clk_out),.ps2_dat_out(ps2_data_out),
				.ce(clk_en),.de(data_en),.shift_reg(shift_data),
				.pkt_rec(pkt_rec),.cnt11());

	ps2_parse	  parse(.clk,.rst_b(~rst),
				.ps2_pkt_DH(shift_data[7:0]),
				.rec_ps2_pkt(pkt_rec),.keys(keys));

	logic[31:0] pw;
	`ifdef SYNTH
	assign pw = 32'h3C4CCCCD;
	`else
	assign pw = `FP_1;
	`endif

	logic prg_ready;
	prg_ray_t prg_data;
	prg_top		  prg(.clk,.rst,.v0,.v1,.v2,.start(start),
			      .E,.U,.V,.W,.pw,.int_to_prg_stall(1'b0),.ready(prg_ready),.done(),.prg_data);	  

	shader_to_sint_t ray_in;
	assign ray_in.rayID= prg_data.pixelID;
	assign ray_in.is_shadow = 0;
	assign ray_in.ray_vec.origin = prg_data.origin;
	assign ray_in.ray_vec.dir = prg_data.dir;
	logic[31:0] xmin, xmax, ymin, ymax, zmin, zmax;

	assign xmin = `FP_0;
	assign xmax = `FP_1;
	assign ymin = `FP_0;
	assign ymax = `FP_1;
	assign zmin = `FP_0;
	assign zmax = `FP_1;

	logic pb_full;

	tarb_t tf_ray_out;
	sint_to_ss_t ssf_ray_out;
	sint_to_shader_t ssh_ray_out;
	logic us_stall, tf_ds_valid, ssf_ds_valid, ssh_ds_valid;
	scene_int	  si(.ray_in(ray_in),.v0(v1),.v1(v2),.v2(v0),
			     .xmin,.xmax,.ymin,.ymax,.zmin,.zmax,
			     .tf_ds_stall(pb_full),.ssf_ds_stall(pb_full),.ssh_ds_stall(pb_full),
			     .us_valid(prg_ready),.clk,.rst,.tf_ray_out,.ssf_ray_out,
			     .ssh_ray_out,.us_stall,.tf_ds_valid,.ssf_ds_valid,.ssh_ds_valid);


	logic pb_we, pb_empty;
	// TODO: pb_we enabled correctly?
	assign pb_we = ssh_ds_valid || tf_ds_valid;
	assign pb_data_in.pixelID = ssh_ds_valid ? ssh_ray_out.rayID : (tf_ds_valid ? ssf_ray_out.rayID : 'h0);
	assign pb_data_in.color = ssh_ds_valid ? 24'h00_00_00 : (tf_ds_valid ? 24'hFF_FF_FF : 'h0);
	

	fifo #(.WIDTH($bits(pixel_buffer_entry_t)),.DEPTH(200)) 
			  pb(.clk,.rst,.data_in(pb_data_in),
			     .we(pb_we),.re(pb_re),.full(pb_full),
			     .empty(pb_empty),.data_out(pb_data_out),
			     .num_left_in_fifo(),.exists_in_fifo());



	logic[1:0] cnt, cnt_n;
	assign cnt_n = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(cnt_n),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

endmodule: ryan_demo