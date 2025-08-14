

class alu_driver extends uvm_driver #(alu_sequence_item);

	virtual alu_interface vif;

	`uvm_component_utils(alu_driver)

	uvm_analysis_port#(alu_sequence_item) driv_port; 
	function new (string name = "alu_driver", uvm_component parent);
		super.new(name, parent);
		driv_port = new("driv_port", this);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual alu_interface)::get(this,"","vif", vif))
			`uvm_fatal("NO_VIF",{"virtual interface must be set for: ALU_DRIVER ",get_full_name(),".vif"});
	endfunction

	task run_phase(uvm_phase phase);
		forever begin  
			seq_item_port.get_next_item(req);
			vif.alu_driver_cb.rst       <= req.rst;
			vif.alu_driver_cb.ce        <= req.ce;
			vif.alu_driver_cb.mode      <= req.mode;
			vif.alu_driver_cb.cin       <= req.cin;
			vif.alu_driver_cb.cmd       <= req.cmd;
			vif.alu_driver_cb.inp_valid <= req.inp_valid;
			vif.alu_driver_cb.opa       <= req.opa;
			vif.alu_driver_cb.opb       <= req.opb;
			$display("Driver @ %0t \n RST = %b | CE = %b | MODE = %b | CMD = %d | INP_VALID = %d | CIN = %b | OPA = %d | OPB = %d |", $time, req.rst , req.ce , req.mode , req.cmd , req.inp_valid , req.cin , req.opa , req.opb );

			if( ( req.mode == 1 ) && ( req.cmd == 9 || req.cmd == 10 ) )
				repeat(4) @(vif.alu_driver_cb);  
			else
				repeat(3) @(vif.alu_driver_cb);     

			driv_port.write(req);
			seq_item_port.item_done();
		end
	endtask
endclass

