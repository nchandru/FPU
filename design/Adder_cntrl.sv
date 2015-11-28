typedef enum { Idle=0 , AdderState, EvaluateRes, RoundOff, ExceptionChecker, SetOutput} Adder_cntrl_state ;

module Adder_cntrl (
  //--- Default interface ---
    CLK ,
	RSTn ,
  //--- Caller interface ---
	Datain1 ,
	Datain2 ,
	Data_valid ,
	Dataout ,
	Dataout_valid ,
	Exc ,
	Mode ,
	Debug ,
  //--- Adder callee module interface ---
    Adder_datain1 ,
	Adder_datain2 ,
	Adder_valid ,
	Adder_Exc ,
	Adder_dataout ,
	Adder_carryout ,
	Adder_ack  ,
  //---- ExceptionChecker callee module interface ---
    ExcCheck_valid ,
	ExcCheck_Datain,
	Exc_value,
	Exc_Ack
 ) ;

  //--- Default interface ---
    input             CLK           ;
	input             RSTn          ;
  //--- Caller interface ---
	input      [31:0] Datain1       ;
	input      [31:0] Datain2       ;
	input             Data_valid    ;
	output reg [31:0] Dataout       ;
	output reg        Dataout_valid ;
	output reg [2:0]  Exc           ;
	input      [2:0]  Mode          ;
	output reg [4:0]  Debug         ;
  //--- Adder callee module interface ---
    output reg [23:0] Adder_datain1 ;
	output reg [23:0] Adder_datain2 ;
	output reg        Adder_valid     ;
	input      [1:0]  Adder_Exc       ;
	input      [23:0] Adder_dataout   ;
	input             Adder_carryout  ;
	input             Adder_ack       ;
  //---- ExceptionChecker callee module interface ---
    output reg ExcCheck_valid ;
	output reg[31:0] ExcCheck_Datain;
	input [2:0] Exc_value;
	input Exc_Ack;



Adder_cntrl_state StateMC, next_StateMC ;

reg        Op1_Sign, Op1_Sign_reg, Op2_Sign, Op2_Sign_reg ;
reg [7:0]  Final_Exponent, Final_Exponent_reg ;
reg [23:0] Op1_Mantissa, Op1_Mantissa_reg, Op2_Mantissa, Op2_Mantissa_reg ;
reg [5:0]  diff, diff_reg ;
reg [2:0]  exc_val, exc_reg ;
reg [26:0] Final_Mantissa, Final_Mantissa_reg ;
reg Final_Sign, Final_Sign_reg ;
reg carry, carry_reg ;
reg G_val, G_reg, R_val, R_reg, S_val, S_reg ;

xor u_xor_1( EOP, Op1_Sign_reg, Op2_Sign_reg) ;

  //--- Synchronous Block ---
   always @(posedge CLK) begin
   	if(RSTn!=1) begin
   		StateMC <= Idle ;
		//---- Reset All -----
		Op1_Sign_reg         <=     Op1_Sign       ;
		Final_Exponent_reg   <=     Final_Exponent ;
		Op1_Mantissa_reg     <=     Op1_Mantissa   ;
		Op2_Sign_reg         <=     Op2_Sign       ;
		Op2_Mantissa_reg     <=     Op2_Mantissa   ;
		diff_reg             <=     diff           ;
		exc_reg              <=     exc_val        ;
		Final_Mantissa_reg   <=     Final_Mantissa ;
		Final_Sign_reg       <=     Final_Sign     ;
		carry_reg            <=     carry          ;
		G_reg                <=     G_val          ;
		R_reg                <=     R_val          ;
		S_reg                <=     S_val          ;

   	end
   	else begin
   		StateMC              <=     next_StateMC   ;
		Op1_Sign_reg         <=     Op1_Sign       ;
		Final_Exponent_reg   <=     Final_Exponent ;
		Op1_Mantissa_reg     <=     Op1_Mantissa   ;
		Op2_Sign_reg         <=     Op2_Sign       ;
		Op2_Mantissa_reg     <=     Op2_Mantissa   ;
		diff_reg             <=     diff           ;
		exc_reg              <=     exc_val        ;
		Final_Mantissa_reg   <=     Final_Mantissa ;
		Final_Sign_reg       <=     Final_Sign     ;
		carry_reg            <=     carry          ;
		G_reg                <=     G_val          ;
		R_reg                <=     R_val          ;
		S_reg                <=     S_val          ;
   	end
   end


  //--- Combinational Block ---
   always@(*) begin
    //---- Remove Latches -----
	    next_StateMC    =   StateMC            ;
		Op1_Sign        =   Op1_Sign_reg       ;
		Final_Exponent  =   Final_Exponent_reg ;
		Op1_Mantissa    =   Op1_Mantissa_reg   ;
		Op2_Sign        =   Op2_Sign_reg       ;
		Op2_Mantissa    =   Op2_Mantissa_reg   ;
		diff            =   diff_reg           ;
		exc_val         =   exc_reg            ;
		Final_Mantissa  =   Final_Mantissa_reg ;
		Final_Sign      =   Final_Sign_reg     ;
		carry           =   carry_reg          ;
		G_val           =   G_reg              ;
		R_val           =   R_reg              ;
		S_val           =   S_reg              ;
		ExcCheck_Datain =   0                  ;
		ExcCheck_valid  =   0                  ;
		Dataout         =   0                  ;
		Dataout_valid   =   0                  ;
		Adder_datain1   =   0                  ;
		Adder_datain2   =   0                  ;
		Adder_valid     =   0                  ;
		Exc             =   0                  ;
	//-------------------------
   	case(StateMC)
		Idle     :   begin
						exc_val  =  0 ;
						G_val    =  0 ;
						R_val    =  0 ;
						S_val    =  0 ;
						Dataout_valid = 0 ;
						if(Data_valid==1) begin // new data available for addition
							//---- Compare the Exponent.  Op1(higher exponent)
							if(Datain1[30:23] >= Datain2[30:23]) begin
								diff           =   Datain1 - Datain2  ;
								Op1_Sign       =   Datain1[31] ;
								Final_Exponent =   Datain1[30:23] ;
								Op1_Mantissa   =   {1'b1, Datain1[22:0]} ;
								Op2_Sign       =   Datain2[31] ;
								G_val          =   Datain2[diff-1];
								if(diff > 1)	R_val          =   Datain2[diff-2] ;
								//for(int i=0; i<= diff-3; i++)  S_val = S_val | Datain2[i] ;
								if(diff > 2)    S_val          =   Datain2[diff-3] ;
								Op2_Mantissa   =   {1'b1, Datain2[22:0]} >> diff ;
							end
							else begin
								diff           =   Datain2 - Datain1 ;
								Final_Exponent =   Datain2[30:23] ;
								Op1_Sign       =   Datain2[31] ;
								Op1_Mantissa   =   {1'b1, Datain2[22:0]} ;
								Op2_Sign       =   Datain1[31] ;
								G_val          =   Datain1[diff-1];
								if(diff != 1)	R_val          =   Datain1[diff-2] ;
								//for(int i=0; i<= diff-3; i++)  S_val = S_val | Datain1[i] ;
								if(diff > 2)    S_val          =   Datain1[diff-3] ;
								Op2_Mantissa   =   {1'b1, Datain1[22:0]} >> diff ;
							end
							next_StateMC = AdderState ; // Go to AdderState to drive the adderunit
						end
						else next_StateMC = Idle ;
					 end
	AdderState   :	begin
						Adder_valid  =  1 ;
						Adder_datain1 = Op1_Mantissa_reg ;
						if(EOP == 1)	{Adder_datain2,G_val,R_val,S_val} = (~{Op2_Mantissa_reg,G_reg,R_reg,S_reg}) + 1'b1 ;
						else            Adder_datain2 =  Op2_Mantissa_reg ;
						if(Adder_ack == 1) begin
							//---- Receive the data sent by the adder circuit ----
							exc_val = Adder_Exc ;
							Final_Mantissa = {Adder_dataout[23:0],G_val, R_val, S_val} ;
							carry          = Adder_carryout ;
							//---- Disable the adder call and reset the drive lines ----
							Adder_valid    = 0 ;
							if ( exc_val != 0 ) next_StateMC = SetOutput ;
							else                next_StateMC = EvaluateRes ;
						end
						else                    next_StateMC = AdderState ;
					end
  EvaluateRes    :  begin
  					   //--- Find out the cases ---
					   case({EOP,carry_reg,Final_Mantissa_reg[23]})
					   		3'b101   :   begin
											//--- Different signs, noCarry, MSB 1 --> Sum is negative
											Final_Sign = 1'b1 ;
											Final_Mantissa = ~(Final_Mantissa_reg) + 1'b1 ;
										 end
							3'b01X   :   begin
											//-- Same sign, carry generated
											Final_Sign     = Op1_Sign_reg ;
											Final_Mantissa = {carry_reg, Final_Mantissa_reg[26:1]} ;
											if(Final_Exponent_reg == 8'hFF) exc_val = 3'b010 ;
											else Final_Exponent = Final_Exponent_reg + 1'b1 ;
										 end
							3'b00X   :   begin
											Final_Sign     = Op1_Sign_reg ;
											Final_Mantissa = normalize(Final_Mantissa_reg);
										 end
							3'b11X   :   begin //--- Ignore carry if generated for different sign ----
											Final_Sign     = Op1_Sign_reg ;
											Final_Mantissa = normalize(Final_Mantissa_reg) ;
										 end
					   endcase
					   if(exc_val != 0) next_StateMC = SetOutput ;
					   else             next_StateMC = RoundOff  ;
                    end
	RoundOff    :  begin
						carry = 0 ;
						case({Final_Mantissa_reg[2:0]})
							3'b11X   :  {carry,Final_Mantissa[26:3]} = Final_Mantissa_reg[26:3] + 1'b1 ;
							3'b101   :  {carry,Final_Mantissa[26:3]} = Final_Mantissa_reg[26:3] + 1'b1 ;
							3'b100   :  begin
											if(Final_Mantissa_reg[3]==1) {carry,Final_Mantissa[26:3]} = Final_Mantissa_reg[26:3] + 1'b1 ;
										end
						endcase
						if(carry == 1) next_StateMC = EvaluateRes ;
						else next_StateMC = ExceptionChecker ;
				   end
   ExceptionChecker : begin
   						ExcCheck_valid = 1'b1 ;
						ExcCheck_Datain = {Final_Sign_reg, Final_Exponent_reg, Final_Mantissa_reg[26:3]};
						if(Exc_Ack == 1) begin
							ExcCheck_valid = 0 ;
							exc_val = Exc_value ;
						end
						next_StateMC = SetOutput ;   						
   					  end
	SetOutput   :  begin
						if(exc_reg != 0)	Exc  =  exc_reg ;
						Dataout = {Final_Sign_reg, Final_Exponent_reg, Final_Mantissa_reg[26:3]} ;
						Dataout_valid = 1'b1 ;
						next_StateMC = Idle ;
				   end
	//EndState    :  begin
	//					Dataout_valid = 1'b0 ;
	//					next_StateMC  = Idle ;
	//			   end
		
	endcase
   end



function automatic bit[26:0] normalize( bit[26:0] data);
bit[26:0] temp = data ;
  for( int i=0; i<27; i++) begin
  	if(temp[26]==1) begin
	    if(i > Final_Exponent_reg) begin 
			exc_val = 3'b001 ;
			return temp[26:0] ;
		end
		else begin
			Final_Exponent = Final_Exponent_reg - i ;
			return temp[26:0] ;
		end
	end
	else  temp[26:0] = {temp[26:1],1'b0};
  end
  return temp ;
endfunction

endmodule
