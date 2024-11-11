
module vga_demo(CLOCK_50, SW, KEY, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
	
   parameter A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011; 
   parameter E = 3'b100, F = 3'b101, G = 3'b110, H = 3'b111; 
	parameter XBound = 48, YupBound = 40, YdownBound = 120;
   parameter XSCREEN = 160, YSCREEN = 120;
	parameter XDIM = 16, YDIM = 16;
   parameter X0 = 8'd95, Y0 = 7'd40;
   parameter ALT = 3'b000; // alternate object color
   parameter K = 20; // animation speed: use 20 for hardware, 2 for ModelSim

	input CLOCK_50;	
	input [7:0] SW;
	input [3:0] KEY;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;	
	
	wire [7:0] VGA_X; 
	wire [6:0] VGA_Y; 
	
	//For drawing background
	reg [2:0] VGA_COLOR;
   reg plot;
    
	wire [2:0] colour;
	wire [7:0] X, Z;
	wire [6:0] Y;
	
	//For drawing tetris block
   wire [3:0] XC;
   wire [3:0] YC;
	 
	wire [2:0] tetrisBlockColour;
	wire [2:0] S2Colour;
	wire [2:0] J1Colour;
	wire [2:0] OColour;
	wire [2:0] I1Colour;
	 
   wire [K-1:0] slow;
   wire go, sync;
   reg Ly, Ey, Lxc, Lyc, Exc, Eyc;
   wire Ydir;
   reg Tdir;
   reg [2:0] y_Q, Y_D;
	 
	assign colour = SW[2:0];
	
	J1 block1({YC, XC}, CLOCK_50, J1Colour);
	S2 block2({YC, XC}, CLOCK_50, S2Colour);
	O block3( {YC, XC}, CLOCK_50, OColour);
	I1 block4( {YC, XC}, CLOCK_50, I1Colour);
	
	//Modes
	chooseBlockMux(J1Colour, S2Colour, OColour, I1Colour, SW[4:3], tetrisBlockColour);

    UpDn_count U1 (Y0, CLOCK_50, KEY[0], Ey, ~KEY[1], Ydir, Y);
        defparam U1.n = 7;

    regn U2 (X0, KEY[0], ~KEY[1], CLOCK_50, X);
        defparam U2.n = 8;

    UpDn_count U3 (4'd0, CLOCK_50, KEY[0], Exc, Lxc, 1'b1, XC);
        defparam U3.n = 4;
    UpDn_count U4 (4'd0, CLOCK_50, KEY[0], Eyc, Lyc, 1'b1, YC);
        defparam U4.n = 4;

    UpDn_count U5 ({K{1'b0}}, CLOCK_50, KEY[0], 1'b1, 1'b0, 1'b1, slow);
        defparam U5.n = K;
    assign sync = (slow == 0);

    ToggleFF U6 (Tdir, KEY[0], CLOCK_50, Ydir);

    // FSM state table
    always @ (*)
        case (y_Q)
            A:  if (!go || !sync) Y_D = A;
                else Y_D = B;
            B:  if (XC != XDIM-1) Y_D = B;    // draw
                else Y_D = C;
            C:  if (YC != YDIM-1) Y_D = B;
                else Y_D = D;
            D:  if (!sync) Y_D = D;
                else Y_D = E;
            E:  if (XC != XDIM-1) Y_D = E;    // erase
                else Y_D = F;
            F:  if (YC != YDIM-1) Y_D = E;
                else Y_D = G;
            G:  Y_D = H;
            H:  Y_D = B;
        endcase
    // FSM outputs
    always @ (*)
    begin
        // default assignments
        Lxc = 1'b0; Lyc = 1'b0; Exc = 1'b0; Eyc = 1'b0; VGA_COLOR = tetrisBlockColour; plot = 1'b0;
        Ey = 1'b0; Tdir = 1'b0;
        case (y_Q)
            A:  begin Lxc = 1'b1; Lyc = 1'b1; end
            B:  begin Exc = 1'b1; plot = 1'b1; end   // color a pixel
            C:  begin Lxc = 1'b1; Eyc = 1'b1; end
            D:  Lyc = 1'b1;
            E:  begin Exc = 1'b1; VGA_COLOR = ALT; plot = 1'b1; end   // color a pixel
            F:  begin Lxc = 1'b1; Eyc = 1'b1; end
            G:  begin Lyc = 1'b1; Tdir = (Y == YupBound) || (Y == YSCREEN-1); end
            H:  Ey = 1'b1;
        endcase
    end

    always @(posedge CLOCK_50)
        if (!KEY[0])
            y_Q <= 1'b0;
        else
            y_Q <= Y_D;

    assign go = ~KEY[3];

    assign VGA_X = X + XC;
    assign VGA_Y = Y + YC;
    // connect to VGA controller
    vga_adapter VGA (
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(VGA_COLOR),
			.x(VGA_X),
			.y(VGA_Y),
			.plot(plot),
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
		defparam VGA.BACKGROUND_IMAGE = "GameScreen.mif"; 
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

module ToggleFF(T, Resetn, Clock, Q);
    input T, Resetn, Clock;
    output reg Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (T)
            Q <= ~Q;
endmodule

module UpDn_count (R, Clock, Resetn, E, L, UpDn, Q);
    parameter n = 8;
    input [n-1:0] R;
    input Clock, Resetn, E, L, UpDn;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 0;
        else if (L == 1)
            Q <= R;
        else if (E)
            if (UpDn == 1)
                Q <= Q + 1;
            else
                Q <= Q - 1;
endmodule

