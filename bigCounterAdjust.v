module bigCounterAdjust(D, Clock, Clear, Q);
	input D, Clock, Clear;
	output reg [21:0] Q;
	

	always@(posedge Clock)
		begin
			if(!Clear)
				Q <= 22'b0;
			else
				if(D == 1)
					Q <= Q + 1;
		end
endmodule
