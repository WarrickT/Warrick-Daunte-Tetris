module chooseBlockMux(A, B, C, D, S, out);
	input [3:0] A, B, C, D;
	input [1:0] S;
	output reg [3:0] out;
	
	always@(*)
		begin
			if(S == 2'b00)
				out = A;
			else if(S == 2'b01)
				out = B;
			else if (S == 2'b10)
				out = C;
			else
				out = D;
		end
endmodule

