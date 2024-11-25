module getColor(Clock, Enable, Shape, MSB, Color);
	input [3:0] Shape;
	input Clock, Enable, MSB;
	output reg [3:0] Color;
	
	
	always @(posedge Clock)
		if(Enable == 1)
			case(Shape)
				4'b0000: Color <= (MSB == 1) ? 3'b011 : 3'b000; //I1
				4'b0001: Color <= (MSB == 1) ? 3'b011 : 3'b000; //I2
				4'b0010: Color <= (MSB == 1) ? 3'b110 : 3'b000 ; //O
				4'b0011: Color <= (MSB == 1) ? 3'b010 : 3'b000 ; //S1
				4'b0100: Color <= (MSB == 1) ? 3'b010 : 3'b000 ; //S2
				4'b0101: Color <= (MSB == 1) ? 3'b001 : 3'b000 ; //J1
				4'b0110: Color <= (MSB == 1) ? 3'b001 : 3'b000 ; //J2
				4'b0111: Color <= (MSB == 1) ? 3'b001 : 3'b000 ; //J3
				4'b1000: Color <= (MSB == 1) ? 3'b001 : 3'b000 ; //J4
				4'b1001: Color <= (MSB == 1) ? 3'b101 : 3'b000 ; //T1
				4'b1010: Color <= (MSB == 1) ? 3'b101 : 3'b000 ; //T2
				4'b1011: Color <= (MSB == 1) ? 3'b101 : 3'b000 ; //T3
				4'b1100: Color <= (MSB == 1) ? 3'b101 : 3'b000 ; //T4
				4'b1101: Color <= (MSB == 1) ? 3'b100 : 3'b000 ; //Z1
				4'b1110: Color <= (MSB == 1) ? 3'b100 : 3'b000 ; //Z2
			endcase

endmodule

