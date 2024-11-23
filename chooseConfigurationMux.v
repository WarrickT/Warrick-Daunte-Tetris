module chooseConfigurationMux(I1, I2, O, S1, S2, J1, J2, J3, J4, T1, T2, T3, T4, Z1, Z2, Switch, currentConfig);
	input [15:0] I1, I2, O, S1, S2, J1, J2, J3, J4, T1, T2, T3, T4, Z1, Z2;
	//input [3:0] Switch;
	input [1:0] Switch;
	output reg [15:0] currentConfig;
	
	always@(*)
		case(Switch)
		/*
			4'b0000: currentConfig = I1;
			4'b0001: currentConfig = I2;
			4'b0010: currentConfig = O;
			4'b0011: currentConfig = S1;
			4'b0100: currentConfig = S2;
			4'b0101: currentConfig = J1;
			4'b0110: currentConfig = J2;
			4'b0111: currentConfig = J3;
			4'b1000: currentConfig = J4;
			4'b1001: currentConfig = T1;
			4'b1010: currentConfig = T2;
			4'b1011: currentConfig = T3;
			4'b1100: currentConfig = T4;
			4'b1101: currentConfig = Z1;
			4'b1110: currentConfig = Z2;
			default: currentConfig = J2;
			*/
			2'b00: currentConfig = J2;
			2'b01: currentConfig = S2;
			2'b10: currentConfig = O;
			2'b11: currentConfig = I1;
		endcase
		
endmodule
	