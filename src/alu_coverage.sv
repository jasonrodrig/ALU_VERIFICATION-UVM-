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
		opa         : coverpoint driv.opa       { bins opa[] = {[0:255]} with (item / 32 ); }
		opb         : coverpoint driv.opb       { bins opb[] = {[0:255]} with (item / 32 ); }
		inp_valid   : coverpoint driv.inp_valid { bins inp_valid[]  = {0,1,2,3}; }
		cmd         : coverpoint driv.cmd       { 
			bins arithmatic_cmd[] = {[0:10]} iff (driv.mode == 1'b1);
			bins logical_cmd[]    = {[0:13]} iff (driv.mode == 1'b0);
		}
		cin         : coverpoint driv.cin       { bins cin[]        = {0,1}; }
		mode        : coverpoint driv.mode      { bins mode[]       = {0,1}; } 
		ce          : coverpoint driv.ce        { bins ce[]         = {0,1}; }
		rst         : coverpoint driv.rst       { bins rst[]        = {0,1}; }
		rstXce      : cross rst , ce ; 
		ceXmode     : cross ce , mode;
		modeXcmd    : cross mode , cmd;
		inp_validXmode: cross inp_valid , mode;
	endgroup

	covergroup monitor_coverage;
		option.per_instance = 1;
		result : coverpoint mon.res  { bins res_bins[]   = {[0:65535]} with (item / 64); }
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
