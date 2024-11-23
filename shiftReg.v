module shiftReg(Clock, Resetn, Enable, Load, R, b);
	input [15:0] R;
	input Clock, Resetn, Enable, Load;
	
	output reg [15:0] b;
	
	always@(posedge Clock) 
		begin
			if(!Resetn)
					b <= 0;
			else if(Load == 1'b1)
					b <= R;
			else if(Enable == 1'b1)
					begin
						b[1] <= b[0];
						b[2] <= b[1];
						b[3] <= b[2];
						b[4] <= b[3];
						b[5] <= b[4];
						b[6] <= b[5];
						b[7] <= b[6];
						b[8] <= b[7];
						b[9] <= b[8];
						b[10] <= b[9];
						b[11] <= b[10];
						b[12] <= b[11];
						b[13] <= b[12];
						b[14] <= b[13];
						b[15] <= b[14];
					end
			else
				b <= b;
		end
		
	
endmodule