

class alu_sequence extends uvm_sequence#(alu_sequence_item);

	`uvm_object_utils(alu_sequence)
	function new(string name = "alu_sequence");
		super.new(name);
	endfunction

	task body();
		repeat(1)begin
			req = alu_sequence_item::type_id::create("req");
			wait_for_grant();
			void'(req.randomize());
			send_request(req);
			wait_for_item_done();
			$display("unblocked");
		end
	endtask
endclass

