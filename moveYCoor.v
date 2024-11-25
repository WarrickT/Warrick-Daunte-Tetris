/*
module moveYCoor(Clock, L, E, XOut, YOut, Resetn);
	input [7:0] XCoor;
	input [6:0] YCoor;
	input L, E, Resetn;
	
	output reg [7:0] XOut;
	output reg [6:0] YOut;
	
	always@(*)
	begin
		if(Resetn == 0)
			XCoor = 79;
			YCoor = 39;
			//Placeholders
		else
			if(L == 1)
				XOut <= 79;
				YOut <= 39;
			else if(E == 1)
				XOut <= XOut;
				YOut <= YOut - 4;
	end
	
endmodule
*/



	