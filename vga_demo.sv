/*
*   This code draws a horizontal line on the screen and then moves the line up and down. The
*   line "bounces" off the top and bottom of the screen and reverses directions. To run the demo
*   first press/release KEY[0] to reset the circuit. Then, press/release KEY[1] to initialize
*   the (x,y) location of the line. The line color is determined by SW[2:0]. Finally, press 
*   KEY[3] to start the animation. 
*/
module vga_demo(CLOCK_50, SW, KEY, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, LEDR);
	 //Parameters for drawing FSM
    parameter A = 4'b0000, GETDATA = 4'b1000, GETDATA2 = 4'b1001, B = 4'b0001, C = 4'b0010, D = 4'b0011, CHECKDROP = 4'b1010;
    parameter E = 4'b0100, F = 4'b0101, G = 4'b0110, H = 4'b0111; 
    parameter XSCREEN = 160, YSCREEN = 120;
	 parameter YSTOP = 104;
    parameter XDIM = 16, YDIM = 16;
    parameter X0 = 8'd39, Y0 = 7'd40;
    parameter ALT = 3'b000; // alternate object color
    parameter K = 20; // animation speed: use 20 for hardware, 2 for ModelSim

	input CLOCK_50;	
	input [9:0] SW;
	input [3:0] KEY;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output [9:0] LEDR;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;	

	
	//Drawing FSM Inputs
	wire [7:0] VGA_X; 
	wire [6:0] VGA_Y;  
	reg [2:0] VGA_COLOR;
    reg plot;
    
	wire [2:0] colour;
	wire [7:0] X, Z;
	wire [6:0] Y;
    wire [3:0] XC;
    wire [3:0] YC;
    wire [K-1:0] slow;
    wire go, sync;
    reg Ly, Ex, Ey, Lxc, Lyc, Exc, Eyc, LCounter, ECounter, ResetXDir;
	 wire Done;

	 reg [3:0] y_Q, Y_D;
	
	wire [2:0] J2_COLOR; 
	wire [2:0] S2_COLOR;
	wire [2:0] O_COLOR;
	wire [2:0] I1_COLOR;
	
		//Declare colors for blocks
	J2 J2Block ({YC,XC}, CLOCK_50, J2_COLOR);
	S2 S2Block({YC,XC}, CLOCK_50, S2_COLOR);
	O OBlock({YC,XC}, CLOCK_50, O_COLOR);
	I1 I1Block({YC, XC}, CLOCK_50, I1_COLOR);
	
	 wire left;
	 assign left = ~KEY[2];
	 wire XMove;
	 Xregn XReg(1'b1, KEY[0], ResetXDir, left, CLOCK_50, XMove);
	 defparam XReg.n = 1;

	 
	 				
    //Backend FSM
	 wire [3:0] currentBlock;
	 wire [2:0] gameBoard [0:19][0:15];
	 wire [4:0] YCOOR; 
	 wire [3:0] XCOOR;
	 
	 wire [1:0] YB;
	 wire [1:0] XB;
	 	 	 
	 wire LXCOOR, LYCOOR, EYCOOR, LXB, LYB, EXB, EYB, EBlock, LShift, EShift, EBoard, YDir, Erase;
	 reg checkBoard;
	 wire [2:0] blockColor;
	 
	 wire canDown;
	 //Configurations of each tetris block
	 parameter cI1 = 16'b0000000000001111, cI2 = 16'b0100010001000100, cO = 16'b0000000001100110;
	 parameter cS1 = 16'b0000000001101100, cS2 = 16'b0000010001100010, cJ1 = 16'b0000000010001110, cJ2 = 16'b0000011001000100;
	 parameter cJ3 = 16'b0000000011100010, cJ4 = 16'b0000001000100110;
	 parameter cT1 = 16'b0000000001001110, cT2 = 16'b0000010001100100, cT3 = 16'b0000000011100100, cT4 = 16'b0000001001100010;
	 parameter cZ1 = 16'b0000000011000110, cZ2 = 16'b0000001001100100;
	 
	 UpDn_count XBCount (2'b0, CLOCK_50, KEY[0], EXB, LXB, 1'b1, XB);
       defparam XBCount.n = 2;
    UpDn_count YBCount (2'b0, CLOCK_50, KEY[0], EYB, LYB, 1'b1, YB);
       defparam YBCount.n = 2;
	 
	 wire [15:0] shiftConfig;
	 wire [15:0] currentConfig;
	 gameBoardToggle gameToggle(CLOCK_50, KEY[0], EBoard, gameBoard, XCOOR + XB, YCOOR + YB, Erase);
	 chooseConfigurationMux choose(cI1, cI2, cO, cS1, cS2, cJ1, cJ2, cJ3, cJ4, cT1, cT2, cT3, cT4, cZ1, cZ2, SW[9:8], currentConfig);
	 shiftReg s1(CLOCK_50, KEY[0], EShift, LShift, currentConfig, shiftConfig);
	  
	UpDn_count XCOORReg(4'b1001, CLOCK_50, KEY[0], 0, LXCOOR, 1'b1, XCOOR);
		defparam XCOORReg.n = 4;

//direction is subject to change!
	UpDn_count YCOORReg(5'b00000, CLOCK_50, KEY[0], EYCOOR, LYCOOR, 1'b1, YCOOR);
		defparam YCOORReg.n = 5;

	 getColor getColor1(CLOCK_50, EBlock, 4'b0110, shiftConfig[15], blockColor);
	 checkDown CD(CLOCK_50, EBlock, gameBoard, 4'b0110, XCOOR, YCOOR, canDown);
	
	 gameLogicFSM GLF(CLOCK_50, KEY[0], checkBoard, canDown, blockColor, XB, YB, LXCOOR, LYCOOR, LXB, LYB, EXB, EYB, EBlock, LShift, EShift, EYCOOR, YDir, EBoard, Erase);
	  
	 
	 wire [23:0] Counter;
	 //wire [9:0] Counter;
	 oneSecondCounter C1(CLOCK_50, KEY[0], LCounter, ECounter, Counter);
	 assign Done = (Counter == 24'b11111111111111111111111);
	 //assign Done = (Counter == 10'b1111111111);
	 coor_count U1(Y0, CLOCK_50, KEY[0], Ey, ~KEY[1], 1'b1, Y);
		  defparam U1.n = 7;

	 coor_count U2(X0, CLOCK_50, KEY[0], Ex, ~KEY[1], 1'b1, X);
        defparam U2.n = 8;

    UpDn_count U3 (4'd0, CLOCK_50, KEY[0], Exc, Lxc, 1'b1, XC);
        defparam U3.n = 4;
    UpDn_count U4 (4'd0, CLOCK_50, KEY[0], Eyc, Lyc, 1'b1, YC);
        defparam U4.n = 4;

    UpDn_count U5 ({K{1'b0}}, CLOCK_50, KEY[0], 1'b1, 1'b0, 1'b1, slow);
        defparam U5.n = K;
    assign sync = (slow == 0);


    // FSM state table

    always @ (*)
        case (y_Q)
            A:  if (!go || !sync) Y_D = A;
                else Y_D = GETDATA;
				GETDATA: Y_D = B;
            B:  if (XC != XDIM-1) Y_D = GETDATA;    // draw
                else Y_D = C;
            C:  if (YC != YDIM-1) Y_D = GETDATA;
                else Y_D = D;
            D:	begin  
						if(Y == YSTOP) Y_D = A;
						else 
							if(!Done) Y_D = D;
							else Y_D = CHECKDROP;
					end
				CHECKDROP:
					if(!canDown)
								Y_D = A;
					else Y_D = GETDATA2;
				GETDATA2: Y_D = E;
            E:  if (XC != XDIM-1) Y_D = GETDATA2;    // erase
                else Y_D = F;
            F:  if (YC != YDIM-1) Y_D = GETDATA2;
                else Y_D = G;
            G:  Y_D = H;
            H:  Y_D = B;
        endcase
    // FSM outputs
    always @ (*)
		 begin
			  // default assignments
			  Lxc = 1'b0; Lyc = 1'b0; Exc = 1'b0; Eyc = 1'b0; VGA_COLOR = colour; plot = 1'b0;
			  Ex = 1'b0; Ey = 1'b0; LCounter = 1'b1; ECounter = 1'b0; ResetXDir = 0; checkBoard = 1'b0;
			  case (y_Q)
					A:  begin Lxc = 1'b1; Lyc = 1'b1; end
					B:  begin Exc = 1'b1; plot = (colour != 3'b000); ResetXDir = 1'b1; end   // color a pixel
					C:  begin Lxc = 1'b1; Eyc = 1'b1; end
					D:  begin Lyc = 1'b1; LCounter = 1'b0; ECounter = 1'b1; checkBoard = 1'b1; end//checkBoard = 1'b1; end
					E:  begin Exc = 1'b1; VGA_COLOR = ALT; plot = (colour != 3'b000); end   // color a pixel Thisz
					F:  begin Lxc = 1'b1; Eyc = 1'b1; end
					G:  begin Lyc = 1'b1; end
					H:  begin Ey = (YDir == 1); end
			  endcase
		 end

    always @(posedge CLOCK_50)
        if (!KEY[0])
            y_Q <= 1'b0;
        else
            y_Q <= Y_D;

	chooseBlockMux M1(J2_COLOR, S2_COLOR, O_COLOR, I1_COLOR, SW[9:8], colour);

    assign go = ~KEY[3];

    assign VGA_X = X + XC;
    assign VGA_Y = Y + YC;
	 
	 assign LEDR[0] = !canDown; 
	 assign LEDR[1] = (Y == YSTOP);
	 assign LEDR[9:2] = 0;
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

module Xregn(R, Resetn, ResetDir, E, Clock, Q);
    parameter n = 8;
    input [n-1:0] R;
    input Resetn, E, Clock, ResetDir;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
			else if (ResetDir)
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


module coor_count (R, Clock, Resetn, E, L, UpDn, Q);
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
                Q <= Q + 4;
            else
                Q <= Q - 4;
endmodule

module oneSecondCounter(Clock, Resetn, L, E, Counter);
    input Clock, Resetn, L, E;
	 output reg [23:0] Counter;
	 //output reg [23:0] Counter;
	 	 
	 always @(posedge Clock)
		 begin
				if(Resetn == 0)
					Counter <= 24'b0;
					//Counter <= 24'b0;
				else if(L == 1)
					Counter <= 24'b0;
					//Counter <= 24'b0;
				else if(E == 1)
					Counter <= Counter + 1;
		 end
endmodule

module chooseBlockMux (A, B, C, D, S, Out);
	input [2:0] A, B, C, D;
	input [1:0] S;
	output reg [2:0] Out;
	
	always@(*)
		begin
		if(S == 2'b00)
			Out = A;
		else if(S == 2'b01)
			Out <= B;
		else if(S == 2'b10)
			Out = C;
		else
			Out = D;
		end
endmodule



module hex7seg (hex, display);
    input [3:0] hex;
    output [6:0] display;

    reg [6:0] display;

    /*
     *       0  
     *      ---  
     *     |   |
     *    5|   |1
     *     | 6 |
     *      ---  
     *     |   |
     *    4|   |2
     *     |   |
     *      ---  
     *       3  
     */
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
