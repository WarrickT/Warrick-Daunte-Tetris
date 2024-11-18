module FSM_Gameplay(SecEn, adjustSecEn, mode, left, down, right, rotate, Resetn, changeblock, Clk);
	input SecEn, adjustSecEn, left, down, right, rotate, Resetn;
	input [1:0] mode;
	input Clk;
	//output enable, switchblock; //enable and load
	output [3:0] changeblock;
	
	reg [4:1] y, Y;
	
	parameter NotPlay = 4'b0000, Nothing = 4'b0001, Drop = 4'b0010, Left_ = 4'b0011, Right_ = 4'b0100, Down_ = 4'b0101, Rotate_ = 4'b0110, Leftwait = 4'b0111, Rightwait = 4'b1000, Downwait = 4'b1001, Rotatewait = 4'b1010;
	
	always@(*)
		case(y)
		
			NotPlay: if(mode[0] == 1 & mode[1] == 0) Y = Nothing;
						else Y = NotPlay;
			Nothing: if(mode[0] == 1 & mode[1] == 0)
						begin
							if(SecEn == 1) Y = Drop;
							else if(left) Y = Left_;
							else if(right) Y = Right_;
							else if(down) Y = Down_;
							else if(rotate) Y = Rotate_;
							else Y = Nothing;
						end
						else Y = NotPlay;
			Drop: 	if(mode[0] == 1)
						begin
							if(SecEn == 1) Y = Drop;
							else if(left) Y = Left_;
							else if(right) Y = Right_;
							else if(down) Y = Down_;
							else if(rotate) Y = Rotate_;
							else Y = Nothing;
						end
						else Y = NotPlay;
		
			Left_: 	if(mode[0] == 1) 
						begin
							if(SecEn == 1) Y = Drop;
							else if(left & adjustSecEn) Y = Left_;
							else if(left & ~adjustSecEn) Y = Leftwait;
							else if(right) Y = Right_;
							else if(down) Y = Down_;
							else if(rotate) Y = Rotate_;
							else Y = Nothing;
						end
						else Y = NotPlay;
						
			Leftwait: 	if(mode[0] == 1)
							begin
								if(SecEn == 1) Y = Drop;
								else if(left & !adjustSecEn) Y = Leftwait;
								else if(left) Y = Left_;
								else if(right) Y = Right_;
								else if(down) Y = Down_;
								else if(rotate) Y = Rotate_;
								else Y = Nothing;
							end
							else Y = NotPlay;
							
			
			Right_: 	if(mode[0] == 1) 
						begin
							if(SecEn == 1) Y = Drop;
							else if(right & adjustSecEn) Y = Right_;
							else if(right) Y = Rightwait;
							else if(left) Y = Left_;
							else if(down) Y = Down_;
							else if(rotate) Y = Rotate_;
							else Y = Nothing;
						end
						else Y = NotPlay;
						
			Rightwait: 	if(mode[0] == 1)
							begin
								if(SecEn == 1) Y = Drop;
								else if(right & !adjustSecEn) Y = Rightwait;
								else if(right) Y = Right_;
								else if(left) Y = Left_;
								else if(down) Y = Down_;
								else if(rotate) Y = Rotate_;
								else Y = Nothing;
							end
							else Y = NotPlay;
			
			Down_: 	if(mode[0] == 1) 
						begin
							if(SecEn == 1) Y = Drop;
							else if(down & adjustSecEn) Y = Down_;
							else if(down) Y = Downwait;
							else if(left) Y = Left_;
							else if(right) Y = Right_;
							else if(rotate) Y = Rotate_;
							else Y = Nothing;
						end
						else Y = NotPlay;
						
			Downwait:	if(mode[0] == 1) 
							begin
								if(SecEn == 1) Y = Drop;
								else if(down & !adjustSecEn) Y = Downwait;
								else if(down) Y = Down_;
								else if(left) Y = Left_;
								else if(right) Y = Right_;
								else if(rotate) Y = Rotate_;
								else Y = Nothing;
							end
							else Y = NotPlay;
			
			Rotate_: if(mode[0] == 1) 
						begin
							if(SecEn == 1) Y = Drop;
							else if(rotate & adjustSecEn) Y = Rotate_;
							else if(rotate) Y = Rotatewait;
							else if(left) Y = Left_;
							else if(right) Y = Right_;
							else if(down) Y = Down_;
							else Y = Nothing;
						end
						else Y = NotPlay;
						
			Rotatewait: if(mode[0] == 1) 
							begin
								if(SecEn == 1) Y = Drop;
								else if(rotate & !adjustSecEn) Y = Rotatewait;
								else if(rotate) Y = Rotate_;
								else if(left) Y = Left_;
								else if(right) Y = Right_;
								else if(down) Y = Down_;
								else Y = Nothing;
							end
							else Y = NotPlay;

			default: Y = 3'bxxx;
		endcase
	
	always@(posedge Clk)
		if(!Resetn)
			y <= NotPlay;
		else
			y <= Y;
	
	//These are the output statements
	//NotPlay = 0000, Nothing = 0001, Drop = 0010, Left = 0011, Right = 0100, Down = 0101, Rotate(CW) = 0110
	assign changeblock[0] = (y == Nothing)|(y == Left_)|(y == Down_)|(y == Leftwait)|(y == Downwait);
	assign changeblock[1] = (y == Drop)|(y == Left_)|(y == Rotate_)|(y == Leftwait)|(y == Rotatewait);
	assign changeblock[2] = (y == Right_)|(y == Down_)|(y == Rotate_)|(y == Leftwait);
	assign changeblock[3] = (y == Rightwait)|(y == Downwait)|(y == Rotatewait);
	//make sure to display backgrounds only for when gamemode is starting screen


endmodule

		
	