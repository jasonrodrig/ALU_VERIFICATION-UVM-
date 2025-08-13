

class alu_monitor extends uvm_monitor;

	virtual alu_interface vif;

	uvm_analysis_port #(alu_sequence_item) mon_port;

	alu_sequence_item seq;

	`uvm_component_utils(alu_monitor)

	function new (string name = "alu_monitor", uvm_component parent);
		super.new(name, parent);
		mon_port = new("mon_port", this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seq = alu_sequence_item::type_id::create("alu_seq");
		if(!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", vif))
			`uvm_fatal("NOVIF",{"virtual interface must be set for:MONITOR INTERFACE ",get_full_name(),".vif"});
	endfunction

	task run_phase(uvm_phase phase);
		forever begin
			repeat(3) @(vif.alu_monitor_cb);

			if( (vif.alu_monitor_cb.cmd == 9 || vif.alu_monitor_cb.cmd == 10) && (vif.alu_monitor_cb.mode == 1) )
			begin
				repeat(1)@(vif.alu_monitor_cb);
			end

			seq.ce        = vif.alu_monitor_cb.ce;
			seq.mode      = vif.alu_monitor_cb.mode;
			seq.cin       = vif.alu_monitor_cb.cin;
			seq.cmd       = vif.alu_monitor_cb.cmd;
			seq.inp_valid = vif.alu_monitor_cb.inp_valid;
			seq.opa       = vif.alu_monitor_cb.opa;
			seq.opb       = vif.alu_monitor_cb.opb;
			seq.res       = vif.alu_monitor_cb.res;
			seq.err       = vif.alu_monitor_cb.err;
			seq.oflow     = vif.alu_monitor_cb.oflow;
			seq.cout      = vif.alu_monitor_cb.cout;
			seq.g         = vif.alu_monitor_cb.g;
			seq.l         = vif.alu_monitor_cb.l;
			seq.e         = vif.alu_monitor_cb.e;
			$display("Monitor @ %0t \n RST = %b | CE = %b | MODE = %b | CMD = %d | INP_VALID = %d | CIN = %b | OPA = %d | OPB = %d |",
				$time, vif.alu_monitor_cb.rst , vif.alu_monitor_cb.ce , vif.alu_monitor_cb.mode , vif.alu_monitor_cb.cmd , vif.alu_monitor_cb.inp_valid , 								  vif.alu_monitor_cb.cin , vif.alu_monitor_cb.opa , vif.alu_monitor_cb.opb );
			$display("Monitor @ %0t \n RES = %d | OFLOW = %b | COUT = %b | G = %b | L = %b | E = %b | ERR = %b |",
				$time, vif.alu_monitor_cb.res , vif.alu_monitor_cb.oflow , vif.alu_monitor_cb.cout , vif.alu_monitor_cb.g , vif.alu_monitor_cb.l , 									  	  vif.alu_monitor_cb.e , vif.alu_monitor_cb.err );
			mon_port.write(seq); 
		end
	endtask

endclass

