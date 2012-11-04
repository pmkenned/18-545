// qsys_sdram_mem_model.v

// Generated using ACDS version 12.0 178 at 2012.11.03.16:50:30

`timescale 1 ps / 1 ps
module qsys_sdram_mem_model (
		input  wire  reset_reset_n, // reset.reset_n
		input  wire  clk_clk        //   clk.clk
	);

	qsys_sdram_mem_model_sdram_partner_module_0 sdram_partner_module_0 (
		.clk      (clk_clk), //     clk.clk
		.zs_dq    (),        // conduit.dq
		.zs_addr  (),        //        .addr
		.zs_ba    (),        //        .ba
		.zs_cas_n (),        //        .cas_n
		.zs_cke   (),        //        .cke
		.zs_cs_n  (),        //        .cs_n
		.zs_dqm   (),        //        .dqm
		.zs_ras_n (),        //        .ras_n
		.zs_we_n  ()         //        .we_n
	);

endmodule
