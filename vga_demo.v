/*
*   Displays a pattern, which is read from a small memory, at (x,y) on the VGA output.
*   To set coordinates, first place the desired value of y onto SW[6:0] and press KEY[1].
*   Next, place the desired value of x onto SW[7:0] and then press KEY[2]. The (x,y)
*   coordinates are displayed (in hexadecimal) on (HEX3-2,HEX1-0). Finally, press KEY[3]
*   to draw the pattern at location (x,y).
*/
module vga_demo(CLOCK_50, SW, KEY, HEX3, HEX2, HEX1, HEX0,
				VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
	
	input CLOCK_50;	
	input [9:0] SW;
	input [3:0] KEY;
    output [6:0] HEX3, HEX2, HEX1, HEX0;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;	
	
	wire [7:0] X;           // starting x location of object
	wire [6:0] Y;           // starting y location of object
    wire [3:0] XC, YC;      // used to access object memory
    wire Ex, Ey;
	wire [7:0] VGA_X;       // x location of each object pixel
	wire [6:0] VGA_Y;       // y location of each object pixel
	
	wire [2:0] VGA_COLOR;   // color of each object pixel
	wire [2:0] J2_COLOR; 
	wire [2:0] S2_COLOR;
	wire [2:0] O_COLOR;
	wire [2:0] I1_COLOR;

    // store (x,y) starting location
    regn U1 (SW[6:0], KEY[0], ~KEY[1], CLOCK_50, Y);
        defparam U1.n = 7;
    regn U2 (SW[7:0], KEY[0], ~KEY[2], CLOCK_50, X);
        defparam U2.n = 8;

    count U3 (CLOCK_50, KEY[0], Ex, XC);    // column counter
        defparam U3.n = 4;
    // enable XC when VGA plotting starts
    regn U5 (1'b1, KEY[0], ~KEY[3], CLOCK_50, Ex);
        defparam U5.n = 1;
    count U4 (CLOCK_50, KEY[0], Ey, YC);    // row counter
        defparam U4.n = 4;
    // enable YC at the end of each object row
    assign Ey = (XC == 4'b111);

    hex7seg H3 (X[7:4], HEX3);
    hex7seg H2 (X[3:0], HEX2);
    hex7seg H1 ({1'b0, Y[6:4]}, HEX1);
    hex7seg H0 (Y[3:0], HEX0);

    // read a pixel color from object memory
    J2 J2Block ({YC,XC}, CLOCK_50, J2_COLOR);
	 S2 S2Block({YC,XC}, CLOCK_50, S2_COLOR);
	 O OBlock({YC,XC}, CLOCK_50, O_COLOR);
	 I1 I1Block({YC, XC}, CLOCK_50, I1_COLOR);
	 
	 chooseBlockMux(J2_COLOR, S2_COLOR, O_COLOR, I1_COLOR, SW[9:8], VGA_COLOR);
	 
	 
	 
    // the object memory takes one clock cycle to provide data, so store
    // the current values of (x,y) addresses to remain synchronized
    regn U7 (X + XC, KEY[0], 1'b1, CLOCK_50, VGA_X);
        defparam U7.n = 8;
    regn U8 (Y + YC, KEY[0], 1'b1, CLOCK_50, VGA_Y);
        defparam U8.n = 7;

    assign plot = ~KEY[3];

    // connect to VGA controller
    vga_adapter VGA (
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(VGA_COLOR),
			.x(VGA_X),
			.y(VGA_Y),
			.plot(~KEY[3]),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK_N(VGA_BLANK_N),
			.VGA_SYNC_N(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
endmodule

module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;
    input [n-1:0] R;
    input Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule

module count (Clock, Resetn, E, Q);
    parameter n = 8;
    input Clock, Resetn, E;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 0;
        else if (E)
                Q <= Q + 1;
endmodule

module hex7seg (hex, display);
    input [3:0] hex;
    output [6:0] display;

    reg [6:0] display;

    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule

//This will become a 16 to 1 mux
module chooseBlockMux (A, B, C, D, S, Out);
	input [2:0] A, B, C, D;
	input [1:0] S;
	output reg [2:0] Out;
	
	always@(*)
		begin
		if(S == 2'b00)
			Out = A;
		else if(S == 2'b01)
			Out = B;
		else if(S == 2'b10)
			Out = C;
		else
			Out = D;
		end
endmodule


	
	
