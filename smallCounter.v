module smallCounter(E, Clock, Clear, Q);
	input E;
	input Clock, Clear;
	output reg [1:0] Q;
	
	always@(posedge Clock)
		begin
			if(!Clear)
				Q <= 2'b00;
			else
				if(Q == 2'b10)
					Q <= 2'b00;
				else
					if(E == 1)
						Q <= Q + 1;
		end
endmodule

