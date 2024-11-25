module FSM_screen(start, gameover, Resetn, mode, Clk);
//Warrick Changes
	input start, gameover, Resetn;
	input Clk;
	output [1:0] mode;
	
	reg [2:1] y, Y;
	
	parameter Home = 2'b00, Game = 2'b01, End = 2'b10;
	
	always@(*)
		case(y)
			Home: if(start) Y = Game;
					else Y = Home;	
			Game: if(gameover) Y = End;
					else Y = Game;
			End: Y = End;// might have to change later

			default: Y = 2'bxx;
		endcase
	
	always@(posedge Clk)
		if(!Resetn)
			y <= Home;
		else
			y <= Y;
	
	//These are the output statements
	assign mode[0] = (y == Game);
	assign mode[1] = (y == Home);
	//assign Load = (y == B);
	//assign Enable = (y == E);

endmodule

		
	