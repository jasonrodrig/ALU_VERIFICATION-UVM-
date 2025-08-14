`uvm_analysis_imp_decl(_mon_scb)
`uvm_analysis_imp_decl(_driv_scb)

class alu_scoreboard extends uvm_scoreboard;

	alu_sequence_item driver_queue[$];
	alu_sequence_item monitor_queue[$];

	bit [21:0] monitor_results;
	bit [21:0] reference_results;

	reg [15:0] t_mul;

	logic [15:0] ref_res ;
	logic  ref_err , ref_oflow , ref_cout , ref_g , ref_l , ref_e;

	`uvm_component_utils(alu_scoreboard)
	uvm_analysis_imp_mon_scb#(alu_sequence_item, alu_scoreboard) mon_scb_port;
	uvm_analysis_imp_driv_scb#(alu_sequence_item, alu_scoreboard) driv_scb_port;

	function new(string name = "alu_scoreboard", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		driv_scb_port = new("driv_scb_port", this);
		mon_scb_port = new("mon_scb_port",this);
	endfunction

	function void write_mon_scb(alu_sequence_item packet_1);
		//$display("Scoreboard received monitor packet ");
		monitor_queue.push_back(packet_1);
	endfunction

	function void write_driv_scb(alu_sequence_item packet_2);
		//$display("Scoreboard received driver packet");
		driver_queue.push_back(packet_2);
	endfunction

	task run_phase(uvm_phase phase);
		forever begin
			fork
				begin
					wait(monitor_queue.size() > 0);
					extract_outputs_from_monitor();
				end
				begin
					wait(driver_queue.size() > 0);
					extract_inputs_from_driver();
				end
			join
			comparision_report();
		end
	endtask

	task extract_outputs_from_monitor();
		alu_sequence_item packet_4;
		packet_4 = monitor_queue.pop_front();
		//  $display("scoreboard : monitor");
		$display("scoreboard: Monitor @ %0t \n RES = %d | OFLOW = %b | COUT = %b | G = %b | L = %b | E = %b | ERR = %b |", $time, packet_4.res , packet_4.oflow , packet_4.cout ,  packet_4.g , packet_4.l, packet_4.e , packet_4.err );
		monitor_results = { packet_4.res, packet_4.oflow, packet_4.cout, packet_4.g, packet_4.l, packet_4.e, packet_4.err };
		$display("monitor_results_stored   = %b", monitor_results);
	endtask

	task extract_inputs_from_driver();
		alu_sequence_item packet_3;
		packet_3 = driver_queue.pop_front();
		//$display("scoreboard : driver");
		//$display("Scoreboard :Driver @ %0t \n RST = %b | CE = %b | MODE = %b | CMD = %d | INP_VALID = %d | CIN = %b | OPA = %d | OPB = %d ",$time, packet_3.rst, packet_3.ce, packet_3.mode, packet_3.cmd, packet_3.inp_valid, packet_3.cin, packet_3.opa, packet_3.opb);
		alu_reference_model(packet_3);
	endtask

	task alu_reference_model(input alu_sequence_item packet_3);
		if(packet_3.rst == 1 )begin
			ref_res ='b0 ;
			ref_oflow = 0; 
			ref_cout = 0;
			ref_g = 0 ; 
			ref_l = 0; 
			ref_e = 0; 
			ref_err = 0;
		end
		else if(packet_3.ce)begin
			ref_res ='b0 ;
			ref_oflow = 0; 
			ref_cout = 0;
			ref_g = 0 ; 
			ref_l = 0; 
			ref_e = 0; 
			ref_err = 0;
			t_mul = 'b0;
			if( packet_3.mode ) 
				arithematic_operation(packet_3);
			else
				logical_operation(packet_3);
		end
		$display("scoreboard: Reference@ %0t \n RES = %d | OFLOW = %b | COUT = %b | G = %b | L = %b | E = %b | ERR = %b |", $time, ref_res , ref_oflow , ref_cout , ref_g , ref_l , ref_e , ref_err );
		reference_results = { ref_res, ref_oflow, ref_cout, ref_g, ref_l, ref_e, ref_err };
		$display("reference_results_stored = %b", reference_results);

	endtask

	task arithematic_operation(input alu_sequence_item packet_3);
		case(packet_3.cmd)

			0:begin
				if( packet_3.inp_valid == 3) 
				begin
					ref_res = packet_3.opa + packet_3.opb;
					ref_cout = ( ref_res[8] ) ? 1 : 0;
	//				$display( "ref_res = %0d | ref_cout = %0d ", ref_res, ref_cout);
				end
				else ref_err = 1;
			end

			1:begin
				if( packet_3.inp_valid == 3) 
				begin
					ref_res = packet_3.opa - packet_3.opb;
					ref_oflow = ( packet_3.opa < packet_3.opb ) ? 1 :0;
				end
				else ref_err = 1;
			end

			2:begin
				if( packet_3.inp_valid == 3) 
				begin
					ref_res = packet_3.opa + packet_3.opb + packet_3.cin;
					ref_cout = ( ref_res[8] ) ? 1 : 0;
		//			$display( "ref_res = %0d | ref_cout = %0d ", ref_res, ref_cout);
				end
				else ref_err = 1;
			end

			3:begin
				if( packet_3.inp_valid == 3) 
				begin
					ref_res = packet_3.opa - packet_3.opb - packet_3.cin ;
					ref_oflow = ( ( packet_3.opa < packet_3.opb ) || ( ( packet_3.opa == packet_3.opb ) && ( packet_3.cin == 1 ) ) ) ? 1 :0;
				end
				else ref_err = 1;
			end

			4:begin
				if( packet_3.inp_valid == 1)
				begin
					ref_res = packet_3.opa + 1;
					ref_cout = ( ref_res[8] ) ? 1 : 0;
				end
				else ref_err = 1;
			end

			5:begin
				if( packet_3.inp_valid == 1)
				begin
					ref_res = packet_3.opa - 1;
					ref_oflow = ( packet_3.opa == 0 ) ? 1 : 0;
				end
				else ref_err = 1;
			end

			6:begin
				if( packet_3.inp_valid == 2)
				begin
					ref_res = packet_3.opb + 1;
					ref_cout = ( ref_res[8] ) ? 1 : 0;
				end
				else ref_err = 1;
			end

			7:begin
				if( packet_3.inp_valid == 2)
				begin
					ref_res = packet_3.opb - 1;
					ref_oflow = ( packet_3.opb == 0 ) ? 1 : 0;
				end
				else ref_err = 1;
			end

			8:begin
				if( packet_3.inp_valid == 3 )
				begin

					ref_res = 0;

					if (packet_3.opa == packet_3.opb )
					begin
						ref_e = 'b1;
						ref_g = 'b0;
						ref_l = 'b0;
					end

					else if( packet_3.opa > packet_3.opb )
					begin
						ref_e = 'b0;
						ref_g = 'b1;
						ref_l = 'b0;
					end		          

					else 
					begin
						ref_e = 'b0;
						ref_g = 'b0;
						ref_l = 'b1;
					end

				end
				else ref_err = 1;
			end

			9:begin
				if(packet_3.inp_valid == 3) begin
					t_mul  = ( packet_3.opa + 1 ) * ( packet_3.opb + 1 );  
					ref_res =  t_mul;
			//		$display( "ref_res = %0d ", ref_res);
				end
				else ref_err = 1;
			end

			10:begin
				if(packet_3.inp_valid == 3) begin
					bit [7:0] temp = ( packet_3.opa << 1 ); 
					t_mul  = ( temp ) * ( packet_3.opb );
					ref_res =  t_mul;
				end
				else ref_err = 1;
			end
			default:begin
				ref_err = 1;
			end
		endcase    

	endtask

	task logical_operation(input alu_sequence_item packet_3);
		case(packet_3.cmd)

			0: begin
				if(packet_3.inp_valid == 3) begin
					ref_res = ( packet_3.opa & packet_3.opb ) & ( { { 8{1'b0} } , { 8{1'b1} } } ); 
				end
				else ref_err = 1;
			end

			1: begin
				if(packet_3.inp_valid == 3) begin
					ref_res = ( ~( packet_3.opa & packet_3.opb ) ) & ( { { 8{1'b0} } , { 8{1'b1} } } ); 
				end
				else ref_err = 1;
			end

			2: begin
				if(packet_3.inp_valid == 3) begin
					ref_res = ( packet_3.opa | packet_3.opb ) & ( { { 8{1'b0} } , { 8{1'b1} } } ); 
				end
				else ref_err = 1;
			end

			3: begin
				if(packet_3.inp_valid == 3) begin
					ref_res = ( ~( packet_3.opa | packet_3.opb ) ) & ( { { 8{1'b0} } , { 8{1'b1} } } ); 
				end
				else ref_err = 1;
			end

			4: begin
				if(packet_3.inp_valid == 3) begin
					ref_res = ( packet_3.opa ^ packet_3.opb ) & ( { { 8{1'b0} } , { 8{1'b1} } } ); 
				end
				else ref_err = 1;
			end

			5: begin
				if(packet_3.inp_valid == 3) begin
					ref_res = ( ~( packet_3.opa ^ packet_3.opb ) ) & ( { { 8{1'b0} } , { 8{1'b1} } } ); 
				end
				else ref_err = 1;
			end

			6: begin
				if(packet_3.inp_valid == 1) begin
					ref_res = ( ~( packet_3.opa ) ) & ( { { 8{1'b0} } , { 8{1'b1} } } );
				end
				else ref_err = 1;
			end

			7: begin
				if(packet_3.inp_valid == 2) begin
					ref_res = ( ~( packet_3.opb ) ) & ( { { 8{1'b0} } , { 8{1'b1} } } );
				end
				else ref_err = 1;
			end

			8: begin
				if(packet_3.inp_valid == 1) begin
					ref_res = ( ( packet_3.opa ) >> 1 ) & ( { { 8{1'b0} } , { 8{1'b1} } } );
				end
				else ref_err = 1;
			end

			9: begin
				if(packet_3.inp_valid == 1) begin
					ref_res = ( ( packet_3.opa ) << 1 ) & ( { { 8{1'b0} } , { 8{1'b1} } } );
				end
				else ref_err = 1;
			end

			10: begin
				if(packet_3.inp_valid == 2) begin
					ref_res = ( ( packet_3.opb ) >> 1 ) & ( { { 8{1'b0} } , { 8{1'b1} } } );
				end
				else ref_err = 1;
			end

			11: begin
				if(packet_3.inp_valid == 2) begin
					ref_res = ( ( packet_3.opb ) << 1 ) & ( { { 8{1'b0} } , { 8{1'b1} } } );
				end
				else ref_err = 1;
			end

			12: begin
				if(packet_3.inp_valid == 3) begin
					ref_res[ 8 - 1 : 0 ] = 
						( packet_3.opa << packet_3.opb[($clog2(8) - 1):0] ) | ( packet_3.opa >> ( 8 - packet_3.opb[($clog2(8) - 1):0]) );
					if(|(packet_3.opb[ 8 - 1 : ($clog2(8) + 1)]))      
						ref_err = 1; 
					else          
						ref_err = 0;
				end
				else ref_err = 1;
			end

			13: begin
				if(packet_3.inp_valid == 3) begin
					ref_res[ 8 - 1 : 0 ] = 
						( packet_3.opa >> packet_3.opb[($clog2(8) - 1):0] ) | ( packet_3.opa << ( 8 - packet_3.opb[($clog2(8) - 1):0]) );
					if(|(packet_3.opb[ 8 - 1 : ($clog2(8) + 1)]))      
						ref_err = 1; 
					else          
						ref_err = 0;
				end
				else ref_err = 1;
			end

			default : begin
				ref_err = 1;
			end
		endcase

	endtask

	task comparision_report();
		if( monitor_results === reference_results )
			$display("<-----------------------------PASS----------------------------->" );
		  //$display("################################################################" );
		else
			$display("<-----------------------------FAIL----------------------------->" );
		  $display("########################################################################################" );
	endtask

endclass
