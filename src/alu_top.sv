
`include "alu_design.v"
`include "alu_interface.sv"
`include "alu_package.sv"
import uvm_pkg::*;
import alu_pkg::*;
module top;
	bit clk = 0;
//	bit rst;

	always #5 clk = ~clk;

/*	initial begin
		rst = 1;
		repeat(3)@(posedge clk);
		rst = 0;
	  end
*/
	
	alu_interface vif(clk);

	alu_design DUT(
		.CLK(vif.clk),
		.RST(vif.rst),
		.CE(vif.ce),
		.MODE(vif.mode),
		.CIN(vif.cin),
		.INP_VALID(vif.inp_valid),
		.CMD(vif.cmd),
		.OPA(vif.opa),
		.OPB(vif.opb),
		.RES(vif.res),
		.ERR(vif.err),
		.OFLOW(vif.oflow),
		.COUT(vif.cout),
		.G(vif.g),
		.L(vif.l),
		.E(vif.e)
	);

	initial begin 
		uvm_config_db#(virtual alu_interface)::set(null,"*","vif",vif);
		$dumpfile("dump.vcd");
		$dumpvars;
	end

	initial begin 
		run_test("alu_test");
		#1000 $finish;
	end
endmodule
