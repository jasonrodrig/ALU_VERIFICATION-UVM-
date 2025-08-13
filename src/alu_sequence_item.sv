

class alu_sequence_item extends uvm_sequence_item;
	logic rst;
	rand logic ce, mode , cin;
	rand logic [7:0] opa , opb;
	rand logic [4:0] cmd;
	rand logic [1:0] inp_valid;
	logic [15:0] res ;
	logic  err , oflow , cout , g , l , e;

	`uvm_object_utils_begin(alu_sequence_item)

	`uvm_field_int(rst,UVM_ALL_ON)
	`uvm_field_int(ce,UVM_ALL_ON)
	`uvm_field_int(mode,UVM_ALL_ON)
	`uvm_field_int(cin,UVM_ALL_ON)
	`uvm_field_int(cmd,UVM_ALL_ON)
	`uvm_field_int(inp_valid,UVM_ALL_ON)
	`uvm_field_int(opa,UVM_ALL_ON)
	`uvm_field_int(opb,UVM_ALL_ON)
	`uvm_field_int(res,UVM_ALL_ON)
	`uvm_field_int(err,UVM_ALL_ON)
	`uvm_field_int(oflow,UVM_ALL_ON)
	`uvm_field_int(cout,UVM_ALL_ON)
	`uvm_field_int(g,UVM_ALL_ON)
	`uvm_field_int(l,UVM_ALL_ON)
	`uvm_field_int(e,UVM_ALL_ON)

	`uvm_object_utils_end

	function new(string name = "alu_sequence_item");
		super.new(name);
	endfunction

	constraint ce_distribution {  ce == 1;
		//ce dist{ 1:=10 , 0:=2};
		cmd dist{ 0:=2 , 9:=1 , 2:=2};
	};
	//constraint input_range { inp_valid inside {[ 1 : 3]};};
	constraint cmd_range { mode == 1; inp_valid == 3;
		//                           if (mode)
		//                             cmd inside {[0:10]};
		//                           else
		//                             cmd inside {[0:13]}; 
	};

endclass
