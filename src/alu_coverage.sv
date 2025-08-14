`uvm_analysis_imp_decl(_mon_cg)
`uvm_analysis_imp_decl(_driv_cg)

class alu_coverage extends uvm_component;
	`uvm_component_utils(alu_coverage)
	virtual alu_interface vif;
	uvm_analysis_imp_mon_cg #(alu_sequence_item, alu_coverage) cov_mon_port;
	uvm_analysis_imp_driv_cg #(alu_sequence_item, alu_coverage) cov_driv_port;
	alu_sequence_item mon, driv;
	real mon_cov_results, driv_cov_results;

	covergroup driver_coverage;
		option.per_instance = 1;
		//opa         : coverpoint driv.opa       { bins opa[] = {[0:255]} with (item / 32 ); }
		//opb         : coverpoint driv.opb       { bins opb[] = {[0:255]} with (item / 32 ); }
		cmd         : coverpoint driv.cmd;      { 
		                                         	bins arithmatic_cmd[] = {[0:10]} iff (driv.mode == 1'b1);
                                        			bins logical_cmd[]    = {[0:13]} iff (driv.mode == 1'b0);
		                                        }
		inp_valid   : coverpoint driv.inp_valid { bins inp_valid[]  = {0,1,2,3}; }
		cin         : coverpoint driv.cin       { bins cin[]        = {0,1}; }
		mode        : coverpoint driv.mode      { bins mode[]       = {0,1}; } 
		ce          : coverpoint driv.ce        { bins ce[]         = {0,1}; }
		rst         : coverpoint driv.rst       { bins rst[]        = {0,1}; }
		rstXce        : cross rst , ce ; 
		ceXmode       : cross ce , mode;
		inp_validXmode: cross inp_valid , mode;
		modeXcmd      : cross mode , cmd {
			bins add              = binsof(cmd) intersect{0}  && binsof(mode) intersect{1};
			bins sub              = binsof(cmd) intersect{1}  && binsof(mode) intersect{1};
			bins add_cin          = binsof(cmd) intersect{2}  && binsof(mode) intersect{1};
			bins sub_cin          = binsof(cmd) intersect{3}  && binsof(mode) intersect{1};
			bins inc_A            = binsof(cmd) intersect{4}  && binsof(mode) intersect{1};
			bins dec_A            = binsof(cmd) intersect{5}  && binsof(mode) intersect{1};
			bins inc_B            = binsof(cmd) intersect{6}  && binsof(mode) intersect{1};
			bins dec_B            = binsof(cmd) intersect{7}  && binsof(mode) intersect{1};
			bins compare          = binsof(cmd) intersect{8}  && binsof(mode) intersect{1};
			bins inc_mul          = binsof(cmd) intersect{9}  && binsof(mode) intersect{1};
			bins shift_mul        = binsof(cmd) intersect{10} && binsof(mode) intersect{1};
			bins and_op           = binsof(cmd) intersect{0}  && binsof(mode) intersect{0};
			bins nand_op          = binsof(cmd) intersect{1}  && binsof(mode) intersect{0};
			bins or_op            = binsof(cmd) intersect{2}  && binsof(mode) intersect{0};
			bins nor_op           = binsof(cmd) intersect{3}  && binsof(mode) intersect{0};
			bins xor_op           = binsof(cmd) intersect{4}  && binsof(mode) intersect{0};
			bins xnor_op          = binsof(cmd) intersect{5}  && binsof(mode) intersect{0};
			bins notA_op          = binsof(cmd) intersect{6}  && binsof(mode) intersect{0};
			bins notB_op          = binsof(cmd) intersect{7}  && binsof(mode) intersect{0};
			bins shift_right_A_op = binsof(cmd) intersect{8}  && binsof(mode) intersect{0};
			bins shift_left_A_op  = binsof(cmd) intersect{9}  && binsof(mode) intersect{0};
			bins shift_right_B_op = binsof(cmd) intersect{10} && binsof(mode) intersect{0};
			bins shift_left_B_op  = binsof(cmd) intersect{11} && binsof(mode) intersect{0};
			bins rotate_left_op   = binsof(cmd) intersect{12} && binsof(mode) intersect{0};
			bins rotate_right_op  = binsof(cmd) intersect{13} && binsof(mode) intersect{0}; 
		}
	endgroup

	covergroup monitor_coverage;
		option.per_instance = 1;
		//	result : coverpoint mon.res  { bins res_bins[]   = {[0:65535]} with (item / 64); }
		oflow  : coverpoint mon.oflow{ bins oflow[]      = {0,1}; }
		cout   : coverpoint mon.cout { bins cout[]       = {0,1}; }
		err    : coverpoint mon.err  { bins err[]        = {0,1}; }
		g      : coverpoint mon.g    { bins g[]          = {0,1}; } 
		l      : coverpoint mon.l    { bins l[]          = {0,1}; }
		e      : coverpoint mon.e    { bins e[]          = {0,1}; } 
	endgroup

	function new(string name = "alu_coverage", uvm_component parent);
		super.new(name, parent);
		monitor_coverage = new();
		driver_coverage  = new();
		cov_driv_port    = new("cov_driv_port", this);
		cov_mon_port     = new("cov_mon_port", this);
	endfunction

	function void write_driv_cg(alu_sequence_item driv_seq);
		driv = driv_seq;
		driver_coverage.sample();
	endfunction

	function void write_mon_cg(alu_sequence_item mon_seq);
		mon = mon_seq;
		monitor_coverage.sample();
	endfunction

	function void extract_phase(uvm_phase phase);
		super.extract_phase(phase);
		driv_cov_results = driver_coverage.get_coverage();
		mon_cov_results  = monitor_coverage.get_coverage();
	endfunction

	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		`uvm_info(get_type_name, $sformatf("[DRIVER] Coverage ------> %0.2f%%,", driv_cov_results), UVM_MEDIUM);
		`uvm_info(get_type_name, $sformatf("[MONITOR] Coverage ------> %0.2f%%", mon_cov_results), UVM_MEDIUM);
	endfunction
endclass
