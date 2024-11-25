module FSM_Home(mode, Easy, Medium, Hard, Resetn, difdisplay, Clk);
	input Easy, Medium, Hard, Resetn;
	input [1:0] mode;
	input Clk;
	output [1:0] difdisplay; // difficulty display
	
	reg [2:1] y, Y;
	
	parameter Easy_ = 2'b00, Medium_ = 2'b01, Hard_ = 2'b10;
	
	always@(*)
		case(y)
			Easy_: if(mode[1] == 1)
						if(Medium == 1) Y = Medium_;
						else if(Hard == 1) Y = Hard_;
						else Y = Easy_;
					else Y = Easy_;
			Medium_: if(mode[1] == 1)
							if(Easy == 1) Y = Easy_;
							else if(Hard == 1) Y = Hard_;
							else Y = Medium_;
						else Y = Medium_;
			Hard_: if(mode[1] == 1)
						if(Easy == 1) Y = Easy_;
						else if(Medium == 1) Y = Medium_;
						else Y = Hard_;
					else Y = Hard_;

			default: Y = 2'bxx;
		endcase
	
	always@(posedge Clk)
		if(!Resetn)
			y <= Easy;
		else
			y <= Y;
	
	//These are the output statements
	assign difdisplay[0] = (y == Medium_);
	assign difdisplay[1] = (y == Hard_);
	//make sure to display backgrounds only for when gamemode is starting screen


endmodule

		
	