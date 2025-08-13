

class alu_agent extends uvm_agent;
	alu_driver    alu_driv;
	alu_sequencer alu_seqr;
	alu_monitor   alu_mon;

	`uvm_component_utils(alu_agent)

	function new (string name = "alu_agent", uvm_component parent);
		super.new(name, parent);
	endfunction 

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(get_is_active() == UVM_ACTIVE) begin
			alu_driv = alu_driver::type_id::create("alu_driv", this);
			alu_seqr = alu_sequencer::type_id::create("alu_seqr", this);
		end
		alu_mon = alu_monitor::type_id::create("alu_mon", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		if(get_is_active() == UVM_ACTIVE) begin
			alu_driv.seq_item_port.connect(alu_seqr.seq_item_export);
		end
	endfunction

endclass  
