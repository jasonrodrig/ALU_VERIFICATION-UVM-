  
class alu_test extends uvm_test;
	`uvm_component_utils(alu_test)
	alu_environment alu_env;
	alu_sequence seq;

	function new(string name = "alu_test", uvm_component parent);
		super.new(name,parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		alu_env = alu_environment::type_id::create("alu_environment", this);
		seq = alu_sequence::type_id::create("alu_seq");
	endfunction : build_phase

	function void end_of_elaboration();
		uvm_top.print_topology();
	endfunction

	task run_phase(uvm_phase phase);
		repeat(6) begin
			phase.raise_objection(this);
			seq.start(alu_env.alu_agt.alu_seqr);
			phase.drop_objection(this);
		end
	endtask

endclass





