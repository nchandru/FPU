//Verilog Module for 24-bit Adder

typedef enum {Compute=0, ResetOutput} AddState ;

module adder_24b ( Z, COUT, ACK, A, B, REQ, CLK, RSTN);

  input [23:0] A,B;
  input REQ, CLK, RSTN;
  output reg [23:0] Z;
  output reg COUT;
  output reg ACK;
  reg [23:0] Z_val;
  reg COUT_val;

  AddState  StateMC, next_StateMC;

always@(posedge CLK or negedge RSTN) begin
	if(RSTN!=1) begin
		COUT <= 0;
		ACK  <= 0;
		Z    <= 0;
		StateMC <= Compute ;
	end
	else begin
		StateMC <= next_StateMC ;		
	end
end

always @(*) 
begin  
  {COUT,Z} = A + B;
  case(StateMC)
     Compute :   begin
			if(REQ==1 && ACK==0) begin
				{COUT, Z} = A + B ;
				next_StateMC = ResetOutput ;
				ACK = 1'b1 ;
			end
		 end
 ResetOutput:   begin
			ACK = 1'b0 ;
			next_StateMC = Compute ;			
		 end
  endcase

end

endmodule
