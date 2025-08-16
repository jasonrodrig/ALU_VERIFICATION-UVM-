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
			if( req.inp_valid == 1 || req.inp_valid == 2 )
			begin
				if( req.mode == 1 && req.cmd inside{4,5,6,7} )
					drive_signals();
				else if( req.mode == 0 && req.cmd inside{6,7,8,9,10,11} )
					drive_signals();
				else 
				begin
					for( int i = 0; i < 16; i++ ) 
					begin
						req.rst.rand_mode(0);
						req.ce.rand_mode(0);       
						req.mode.rand_mode(0);
						req.cmd.rand_mode(0);
						void'(req.randomize());
						$display(" count = %d ", i + 1); 
						if( i == 15 )
						begin
							req.mode.rand_mode(1);
							req.cmd.rand_mode(1);
							drive_signals();
						end
						else 
						begin
							if( req.inp_valid == 3 )
							begin
								i = 0 ;
								drive_signals();
								break;
							end
							else
							begin
								drive_signals(); 
								if( ( req.mode == 1 ) && ( req.cmd == 9 || req.cmd == 10 ) )
									repeat(4) @(vif.alu_driver_cb);  
								else
									repeat(3) @(vif.alu_driver_cb);
								driv_port.write(req);
							end
						end
					end
				end
				if( ( req.mode == 1 ) && ( req.cmd == 9 || req.cmd == 10 ) )
					repeat(4) @(vif.alu_driver_cb);  
				else
					repeat(3) @(vif.alu_driver_cb);     
			end
			else
			begin
				if( req.inp_valid == 0 || req.inp_valid == 3 )
					drive_signals();
				if( ( req.mode == 1 ) && ( req.cmd == 9 || req.cmd == 10 ) )
					repeat(4) @(vif.alu_driver_cb);  
				else
					repeat(3) @(vif.alu_driver_cb); 
			end
			$display("SENDING RESPONSE ");
			driv_port.write(req);
			seq_item_port.item_done();
		end
	endtask
	task drive_signals();
		vif.alu_driver_cb.rst       <= req.rst;
		vif.alu_driver_cb.ce        <= req.ce;
		vif.alu_driver_cb.mode      <= req.mode;
		vif.alu_driver_cb.cin       <= req.cin;
		vif.alu_driver_cb.cmd       <= req.cmd;
		vif.alu_driver_cb.inp_valid <= req.inp_valid;
		vif.alu_driver_cb.opa       <= req.opa;
		vif.alu_driver_cb.opb       <= req.opb;
		$display("Driver @ %0t \n RST = %b | CE = %b | MODE = %b | CMD = %d | INP_VALID = %d | CIN = %b | OPA = %d | OPB = %d ", $time, req.rst , req.ce , req.mode , req.cmd , req.inp_valid , req.cin , req.opa , req.opb );
	endtask
endclass

