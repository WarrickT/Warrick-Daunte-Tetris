module bigCounterAdjust(D, Clock, Clear, Q);
	input D, Clock, Clear;
	output reg [22:0] Q;
	

	always@(posedge Clock)
		begin
			if(!Clear)
				Q <= 23'b0;
			else
				if(D == 1)
					Q <= Q + 1;
		end
endmodule
