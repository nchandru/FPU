typedef enum {Idle = 0, Mult_Compute, Mul_ResetOutput} BoothState ;

module booth (res, m1 , m2, CLK,  BREQ, BACK, RSTn,   
	Adder_datain1 ,
	Adder_datain2 ,
	Adder_valid ,
	Adder_Exc ,
	Adder_dataout ,
	Adder_carryout ,
	Adder_ack);

output reg [47:0] res;
input [23:0] m1, m2;
input CLK, BREQ, RSTn;
reg [23:0] A, A_reg, Q, Q_reg, M, M_reg;
reg Q1, Q1_reg;
output reg BACK;
reg [4:0] count, count_reg;

//--- Adder callee module interface ---
        output reg [23:0] Adder_datain1 ;
	output reg [23:0] Adder_datain2 ;
	output reg        Adder_valid     ;
	input      [1:0]  Adder_Exc       ;
	input      [23:0] Adder_dataout   ;
	input             Adder_carryout  ;
	input             Adder_ack       ;


BoothState  BStateMC, Bnext_StateMC;



always@(posedge CLK) begin
	if(RSTn!=1) 
	begin
		 A_reg <= 0;
		 M_reg <= 0;
		 Q_reg <= 0;
		 Q1_reg <= 0;
		 count_reg <=0;
		 BStateMC <= Idle;
	end
	else begin
		A_reg <= A;
		M_reg <= M;
		Q1_reg <= Q1;
		Q_reg <= Q;
		count_reg <= count;
		BStateMC <= Bnext_StateMC ;		
	end
end

always @(*) 
begin  
   count = count_reg;  
   res =0;
   Bnext_StateMC = BStateMC ;
   Q = Q_reg ;
   Q1 = Q1_reg ;
   M = M_reg ;
   A = A_reg ;

  case(BStateMC)
		Idle: begin
				Bnext_StateMC = Idle;
				if(BREQ==1)
				begin
		 		 A= 0;
				 M= m1;
				 Q= m2;
				 Q1= 0;
				 count = 0;
				 Bnext_StateMC = Mult_Compute;
				end		


			end


                Mult_Compute :   begin
				            BACK  = 0;
					    Bnext_StateMC = Mult_Compute;
		        
					    case ({Q_reg[0], Q1_reg})
							 
						2'b01 : 
						 begin
						   if(Adder_ack == 0 && Adder_valid==0) begin
						    Adder_valid  =  1 ;
						    Adder_datain1 = A_reg ;
						    Adder_datain2 = M_reg ;
     						   end
						   if(Adder_ack == 1 && Adder_valid==1)     {A,Q,Q1} = {Adder_dataout[23],Adder_dataout,Q_reg};
						end 

						2'b10 :
						begin 
						   if(Adder_ack == 0 && Adder_valid==0) begin
						    Adder_valid  =  1 ;
						    Adder_datain1 = A_reg ;
						    Adder_datain2 = ~M_reg + 1'b1 ;
     						   end
						   if(Adder_ack == 1 && Adder_valid==1)     {A,Q,Q1} = {Adder_dataout[23],Adder_dataout,Q_reg};
						end

						default: {A,Q,Q1} = {A_reg[23],A_reg,Q_reg};
					    
					    endcase
						
						count = count_reg + 1'b1;
	           			          
						if(count_reg>24)  
						begin 
						Bnext_StateMC = Mul_ResetOutput ; BACK = 1; res = {A,Q}; 
						end
							           			          
	           		   end


                Mul_ResetOutput:   begin
			                       BACK = 1'b0 ;
			                       Bnext_StateMC = Idle;			
		                        end
  endcase

end

endmodule
