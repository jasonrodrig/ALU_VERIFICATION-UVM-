module alu_design #(parameter DW = 8, CW = 4)(INP_VALID,OPA,OPB,CIN,CLK,RST,CMD,CE,MODE,COUT,OFLOW,RES,G,E,L,ERR);
 
  input [DW-1:0] OPA,OPB;
  input CLK,RST,CE,MODE,CIN;
  input [CW-1:0] CMD;
  input [1:0] INP_VALID;
  output reg [DW+8:0] RES = 9'bz;
  output reg COUT = 1'bz;
  output reg OFLOW = 1'bz;
  output reg G = 1'bz;
  output reg E = 1'bz;
  output reg L = 1'bz;
  output reg ERR = 1'bz;

 
  reg [DW-1:0] OPA_1, OPB_1;
  reg [DW-1:0] oprd1, oprd2;
  reg [3:0] CMD_tmp;
  reg [DW-1:0] AU_out_tmp1,AU_out_tmp2 ;
  // Added timer and state tracking
  reg [4:0] wait_counter;
  reg oprd1_valid, oprd2_valid;
  
  always @ (posedge CLK) begin
      if(RST) begin
        oprd1<=0;
        oprd2<=0;
        CMD_tmp<=0;
        wait_counter<=0;
        oprd1_valid<=0;
        oprd2_valid<=0;
      end
      else if (INP_VALID==2'b01)  begin    
        oprd1<=OPA;
        CMD_tmp<=CMD;
        oprd1_valid<=1;
        wait_counter<=0;
        // Set error if second operand comes after 16 cycles
        if(oprd2_valid && wait_counter >= 16) begin
          ERR <= 1'b1;
        end
      end
      else if (INP_VALID==2'b10)  begin    
        oprd2<=OPB;
        CMD_tmp<=CMD;
        oprd2_valid<=1;
        wait_counter<=0;
        // Set error if second operand comes after 16 cycles
        if(oprd1_valid && wait_counter >= 16) begin
          ERR <= 1'b1;
        end
      end
      else if (INP_VALID==2'b11)  begin    
        oprd1<=OPA;
        oprd2<=OPB;
        CMD_tmp<=CMD;
        oprd1_valid<=1;
        oprd2_valid<=1;
        wait_counter<=0;
      end
      else begin    
        // Increment wait counter if only one operand is valid
        if((oprd1_valid && !oprd2_valid) || (!oprd1_valid && oprd2_valid)) begin
          if(wait_counter < 16) begin
            wait_counter <= wait_counter + 1;
          end else begin
            // Keep operands but stop incrementing counter after 16 cycles
            wait_counter <= 16;
          end
        end
      end
    end
 
 
    always@(posedge CLK)
      begin
       if(CE)                   
        begin
         if(RST)                
          begin
            RES=9'bzzzzzzzzz;
            COUT=1'bz;
            OFLOW=1'bz;
            G=1'bz;
            E=1'bz;
            L=1'bz;
            ERR=1'bz;
            AU_out_tmp1=0;
            AU_out_tmp2=0;
          end
         else if(MODE && oprd1_valid && oprd2_valid)          
         begin
           RES=9'b0;
           COUT=1'b0;
           OFLOW=1'b0;
           G=1'b0;
           E=1'b0;
           L=1'b0;
           ERR=1'b0;
          case(CMD_tmp)             
    4'b0000:                   begin             
              RES=oprd1+oprd2;
              COUT=RES[8]?1:0;
            end
      4'b0001 :                begin
             OFLOW=(oprd1<oprd2)?1:0;
             RES=oprd1-oprd2;
            end
           4'h2:            
            begin
             RES=oprd1+oprd2+CIN;
             COUT=RES[8]?1:0;
            end
           4'b0011:             
           begin
            OFLOW=(oprd1<oprd2)?1:0;
            RES=oprd1-oprd2-CIN;
           end
           4'b0100:RES=oprd1;    
           4'b0101:RES=oprd1-1;    
           4'b0110:RES=oprd2-1;    
           4'b0111:RES=oprd2+1;    
           4'b1000:              
           begin
            RES=9'bzzzzzzzzz;
            if(oprd1==oprd2)
             begin
               E=1'b1;
               G=1'bz;
               L=1'bz;
             end
            else if(oprd1>oprd2)
             begin
               E=1'bz;
               G=1'b1;
               L=1'bz;
             end
            else 
             begin
               E=1'bz;
               G=1'bz;
               L=1'b1;
             end
           end
     4'b1001: begin   
                    AU_out_tmp1 <= oprd1 + 1;
                    AU_out_tmp2 <= oprd2 + 1;
                    RES <=AU_out_tmp1 * AU_out_tmp2;
                  end
           4'b1010: begin   
                    AU_out_tmp1 <= oprd1 << 1;
                    AU_out_tmp2 <= oprd2;
                    RES <=AU_out_tmp1 - AU_out_tmp2; 
                  end
 
           default:   
            begin
            RES=9'bzzzzzzzzz;
            COUT=1'bz;
            OFLOW=1'bz;
            G=1'bz;
            E=1'bz;
            L=1'bz;
            ERR=1'bz;
           end
          endcase
         end
        else if(!MODE && oprd1_valid && oprd2_valid)          
        begin 
           RES=9'b0;
           COUT=1'b0;
           OFLOW=1'b0;
           G=1'b0;
           E=1'b0;
           L=1'b0;
           ERR=1'b0;
           case(CMD_tmp)    
             4'b0000:RES={1'b0,oprd1&oprd2};     
             4'b0001:RES={1'b0,~(oprd1&oprd2)};  
             4'b0010:RES={1'b0,oprd1&&oprd2};     
             4'b0011:RES={1'b0,~(oprd1|oprd2)};  
             4'b0100:RES={1'b0,oprd1^oprd2};     
             4'b0101:RES={1'b0,~(oprd1^oprd2)};  
             4'b0110:RES={1'b0,~oprd1};        
             4'b0111:RES={1'b0,~oprd2};        
             4'b1000:RES={1'b0,oprd1};      
             4'b1001:RES={1'b0,oprd1<<1};      
             4'b1010:RES={1'b0,oprd2<<1};      
             4'b1011:RES={1'b0,oprd2<<1};     
             4'b1100:                        
             begin
               if(oprd2[0])
                 OPA_1 = {oprd1[6:0], oprd1[7]};
               else
                 OPA_1 = oprd1;
               if(oprd2[1])
                 OPB_1 =  {OPA_1[5:0], OPA_1[7:6]}; 
               else
                 OPB_1= OPA_1;
               if(oprd2[2])
                 RES =  {OPB_1[3:0], OPB_1[7:4]} ;
               else
                 RES = OPB_1;
               if(oprd2[4] | oprd2[5] | oprd2[6] | oprd2[7])
                 ERR=1'b1;
             end
             4'b1101:                        
             begin
               if(oprd2[0])
                 OPA_1 = {oprd1[0], oprd1[7:1]};
               else
                 OPA_1 = oprd1;
               if(oprd2[1])
                 OPB_1 =  {OPA_1[1:0], OPA_1[7:2]}; 
               else
                 OPB_1= OPA_1;
               if(oprd2[2])
                 RES =  {OPB_1[3:0], OPB_1[7:4]} ;
               else
                 RES = OPB_1;
               if(oprd2[4] | oprd2[5] | oprd2[6] | oprd2[7])
                 ERR=1'b0;
             end
             default:   
               begin
               RES=9'bzzzzzzzzz;
               COUT=1'bz;
               OFLOW=1'bz;
               G=1'bz;
               E=1'bz;
               L=1'bz;
               ERR=1'bz;
               end
          endcase
     end
    end
   end
endmodule

/*
  module alu_design #(parameter OPERAND_WIDTH = 8, parameter CMD_WIDTH = 4)(
	// INPUTS
	input CLK, RST, MODE, CE, CIN,
	input [CMD_WIDTH-1:0] CMD,
	input [1:0] INP_VALID,
	input [OPERAND_WIDTH-1:0] OPA, OPB,
	// OUTPUTS
	output reg ERR, OFLOW, E, G, L,
	output COUT,
	output reg [(2*OPERAND_WIDTH)-1:0] RES
);

	// Registers for Pipeling
	reg [3:0] t_CMD;
	reg [OPERAND_WIDTH-1:0] t_OPA, t_OPB;
	reg t_CIN, temp_ovr_cin;
	reg t_MODE;
	reg TEMP_MODE;
	reg [3:0]TEMP_CMD;
	reg [1:0] t_INP_VALID;
	reg [OPERAND_WIDTH-1:0] shf_MUL;
	reg [(2*OPERAND_WIDTH)-1:0] t_MUL;
	reg [OPERAND_WIDTH-1:0] temp_ovr_a, temp_ovr_b;

	// Always Block for Initializing and Pipeling the Inputs
	always @ (posedge CLK or posedge RST) begin
		if(RST) begin
			t_OPA <= 0;
			t_OPB <= 0;
			t_CMD <= 0;
			temp_ovr_a <= 0;
			temp_ovr_b <= 0;
			TEMP_MODE <= 0;
			TEMP_CMD <= 0;
			temp_ovr_cin <= 0;
			t_MODE <= 0;
			t_INP_VALID <=0;
			t_CIN <= 0;
		end
		else if(CE) begin
			t_OPA <= OPA;
			t_OPB <= OPB;
			temp_ovr_a <= t_OPA;
			temp_ovr_b <= t_OPB;
			TEMP_MODE <= t_MODE;
			TEMP_CMD <= t_CMD;
			temp_ovr_cin <= t_CIN;
			t_CMD <= CMD;
			t_MODE <= MODE;
			t_INP_VALID <= INP_VALID;
			t_CIN <= CIN;       
		end
		else begin
			t_OPA <= 0;
			t_OPB <= 0;
			t_CMD <= 0;
			temp_ovr_a <= 0;
			temp_ovr_b <= 0;
			t_MODE <= 0;
			t_INP_VALID <= 0;
			t_CIN <= 0;
		end  
	end

	// Always block for ALU Computations
	always @ (posedge CLK or posedge RST) begin
		if(RST) begin           // Reset will result is ZERO
			RES <= 0;
			ERR <= 1'b0;
			t_MUL <= 0;
			E <= 1'b0;
			G <= 1'b0;
			L <= 1'b0;
		end
		else begin
			if(CE) begin
				if(t_MODE) begin                // MODE = 1 (ARITHMETIC)
					if(t_CMD != 4'd9 && t_CMD != 4'd10)     // If Command is not multiplication make res = 0
						RES <= 0;
					ERR <= 1'b0;
					E <= 1'b0;
					G <= 1'b0;
					L <= 1'b0;
					t_MUL <= 0;
					case(t_INP_VALID)
						2'b00 : begin                   // Both Operands are Invalid
							RES <= 0;
							ERR <= 1'b1;
							E <= 1'b0;
							G <= 1'b0;
							L <= 1'b0;
						end
						2'b01 : begin                   // Only OPA is VALID
							case(t_CMD)     
								4'b0100 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA + 1;      // Increment OPA    
								end
								4'b0101 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA - 1;      // Decrement OPB
								end
								default : begin                                     // Invalid CMD for Single Input (OPA)
									RES <= 0;
									ERR <= 1'b1;
									E <= 1'b0;
									G <= 1'b0;
									L <= 1'b0;
								end
							endcase
						end
						2'b10 : begin                   // Only OPB is VALID
							case(t_CMD)
								4'b0110 : begin
									RES[OPERAND_WIDTH:0] <= t_OPB + 1;      // Increment OPB
								end
								4'b0111 : begin
									RES[OPERAND_WIDTH:0] <= t_OPB - 1;      // Decrement OPB
								end
								default : begin                                     // Invalid CMD for Single Input (OPB)
									RES <= 0;   
									ERR <= 1'b1;
									E <= 1'b0;
									G <= 1'b0;
									L <= 1'b0;
								end
							endcase
						end
						default : begin                                                     // When Both Operands are VALID
							case(t_CMD)
								4'b0000 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA + t_OPB;          // ADDITION
								end
								4'b0001 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA - t_OPB;          // SUBTRACTION
								end
								4'b0010 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA + t_OPB + t_CIN;  // ADDITION WITH CARRY
								end
								4'b0011 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA - t_OPB - t_CIN;  // SUBTRACTION WITH BORROW
								end
								4'b0100 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA + 1;              // INCREMENT OPA 
								end
								4'b0101 : begin
									RES[OPERAND_WIDTH:0] <= t_OPA - 1;              // DECREMENT OPA
								end
								4'b0110 : begin
									RES[OPERAND_WIDTH:0] <= t_OPB + 1;              // INCREMENT OPB 
								end
								4'b0111 : begin
									RES[OPERAND_WIDTH:0] <= t_OPB - 1;              // DECREMENT OPB
								end
								4'b1000 : begin                                             // UNSIGNED COMPARISON
									RES <= 0;
									if(t_OPA == t_OPB) begin
										E <= 1;
										G <= 0;
										L <= 0;
									end
									else if(t_OPA > t_OPB) begin
										E <= 0;
										G <= 1;
										L <= 0;
									end
									else begin
										E <= 0;
										G <= 0;
										L <= 1;
									end
								end
								4'b1001 : begin
									t_MUL <= (t_OPA + 1) * (t_OPB + 1);             // MULTIPLICATION (OPA+1) x (OPB+1)
									RES <= t_MUL;
								end
								4'b1010 : begin
									t_MUL <= (shf_MUL) * (t_OPB);                   // MULTIPLICATION (OPA << 1) x (OPB)
									RES <= t_MUL;
								end
								4'b1011 : begin                                             // Signed ADDITION and COMPARISON
									RES[OPERAND_WIDTH:0] <= ($signed(t_OPA)) + ($signed(t_OPB));
									if(t_OPA == t_OPB) begin
										E <= 1;
										G <= 0;
										L <= 0;
									end
									else if(($signed(t_OPA)) > ($signed(t_OPB))) begin
										E <= 0;
										G <= 1;
										L <= 0;
									end
									else begin
										E <= 0;
										G <= 0;
										L <= 1;
									end
								end
								4'b1100 : begin                                             // Signed SUBTRACTION and COMPARISON                  
									RES[OPERAND_WIDTH:0] <= ($signed(t_OPA)) - ($signed(t_OPB));
									if(t_OPA == t_OPB) begin
										E <= 1;
										G <= 0;
										L <= 0;
									end
									else if(($signed(t_OPA)) > ($signed(t_OPB))) begin
										E <= 0;
										G <= 1;
										L <= 0;
									end
									else begin
										E <= 0;
										G <= 0;
										L <= 1;
									end
								end
								default :  begin                                            // Invalid CMD for Both Inputs
									RES <= 0;
									ERR <= 1'b1;
									E <= 1'b0;
									G <= 1'b0;
									L <= 1'b0;
								end
							endcase
						end
					endcase
				end
				else begin                  // MODE = 0 (LOGICAL OPERATION)
					RES <= 0;
					ERR <= 1'b0;
					E <= 1'b0;
					G <= 1'b0;
					L <= 1'b0;
					case(t_INP_VALID)           
						2'b00 : begin                   // Both Inputs are INVALID
							RES <= 0;
							ERR <= 1'b1;
							E <= 1'b0;
							G <= 1'b0;
							L <= 1'b0;
						end
						2'b01 : begin                   // Only OPA is VALID
							case(t_CMD)
								4'b0110 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA)};         // NOT ~OPA
								4'b1000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA >> 1)};     // Right Shift OPA
								4'b1001 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA << 1)};     // Left Shift OPA
								default : begin                                             // Invalid CMD for Single Input (OPA)
									RES <= 0;
									ERR <= 1'b1;
									E <= 1'b0;
									G <= 1'b0;
									L <= 1'b0;
								end
							endcase
						end
						2'b10 : begin                   // Only OPA is VALID
							case(t_CMD)
								4'b0111 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPB)};         // NOT ~OPA
								4'b1010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB >> 1)};     // Right Shift OPB
								4'b1011 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB << 1)};     // Left Shift OPA
								default : begin                                             // Invalid CMD for Single Input (OPB)
									RES <= 0;
									ERR <= 1'b1;
									E <= 1'b0;
									G <= 1'b0;
									L <= 1'b0;
								end
							endcase
						end
						default : begin
							case(t_CMD)
								4'b0000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA & t_OPB)};  // Bitwise AND
								4'b0001 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA & t_OPB)}; // Bitwise NAND
								4'b0010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA | t_OPB)};  // Bitwise OR
								4'b0011 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA | t_OPB)}; // Bitwise NOR
								4'b0100 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA ^ t_OPB)};  // Bitwise XOR
								4'b0101 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA ^ t_OPB)}; // Bitwise XNOR
								4'b0110 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA)};         // Bitwise NOT - OPA
								4'b0111 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPB)};         // Bitwise NOT - OPB
								4'b1000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA >> 1)};     // Shift Right OPA
								4'b1001 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA << 1)};     // Shift Left OPA
								4'b1010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB >> 1)};     // Shift Right OPB
								4'b1011 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB << 1)};     // Shift Left OPB
								4'b1100 :   begin                                           // Rotate LEFT
									RES[OPERAND_WIDTH-1:0] <= (t_OPA << t_OPB[($clog2(OPERAND_WIDTH) - 1):0]) | (t_OPA >> (OPERAND_WIDTH - t_OPB[($clog2(OPERAND_WIDTH) - 1):0]));
									if(|(t_OPB[OPERAND_WIDTH-1 : ($clog2(OPERAND_WIDTH) + 1)]))
										ERR <= 1;
									else
										ERR <= 0;
								end
								4'b1101 :   begin                                           // Rotate RIGHT
									RES[OPERAND_WIDTH-1:0] <= (t_OPA >> t_OPB[($clog2(OPERAND_WIDTH) - 1):0]) | (t_OPA << (OPERAND_WIDTH - t_OPB[($clog2(OPERAND_WIDTH) - 1):0]));
									if(|(t_OPB[OPERAND_WIDTH-1 : ($clog2(OPERAND_WIDTH) + 1)]))
										ERR <= 1;
									else
										ERR <= 0;
								end


								default :  begin                                            // Invalid CMD for Both Inputs
									RES <= 0;
									ERR <= 1'b1;
									E <= 1'b0;
									G <= 1'b0;
									L <= 1'b0;
								end
							endcase
						end
					endcase
				end
			end
			else begin   // When CE = 0
				RES <= RES;
				ERR <= 1'b0;
				E <= 1'b0;
				G <= 1'b0;
				L <= 1'b0;
			end
		end   
	end

	// For Multiplication CMD = 4'b1010
	always @ (*) begin  
		if(t_CMD == 4'hA)
			shf_MUL = t_OPA << 1;
		else
			shf_MUL = 0;
	end

	// Overflow Calculation
	always @ (*) begin
		if(TEMP_MODE) begin
			case(TEMP_CMD)
				4'd1 : OFLOW = (temp_ovr_a < temp_ovr_b);
				4'd3 : OFLOW = ((temp_ovr_a < temp_ovr_b) || (temp_ovr_a == temp_ovr_b && temp_ovr_cin == 1));
				4'd5 : OFLOW = (temp_ovr_a < 1);
				4'd7 : OFLOW = (temp_ovr_b < 1);
				4'd11 : OFLOW = (temp_ovr_a[OPERAND_WIDTH-1] & temp_ovr_b[OPERAND_WIDTH-1] & (~RES[OPERAND_WIDTH-1])) | ((~temp_ovr_a[OPERAND_WIDTH-1]) & (~temp_ovr_b[OPERAND_WIDTH-1]) & RES[OPERAND_WIDTH-1]);
				4'd12 : OFLOW = ((~temp_ovr_a[OPERAND_WIDTH-1]) & temp_ovr_b[OPERAND_WIDTH-1] & RES[OPERAND_WIDTH-1]) | (temp_ovr_a[OPERAND_WIDTH-1] & (~temp_ovr_b[OPERAND_WIDTH-1]) & (~RES[OPERAND_WIDTH-1]));
				default : OFLOW = 0;
			endcase
		end
		else
			OFLOW = 0;
	end

	// Carry Out Calculation
	assign COUT = ((TEMP_MODE) && (TEMP_CMD == 4'd0 || TEMP_CMD == 4'd2 || TEMP_CMD == 4'd4 || TEMP_CMD == 4'd6 || TEMP_CMD == 4'd11)) ? RES[8] : 0;


endmodule

*/
