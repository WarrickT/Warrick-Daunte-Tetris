/*
*   Displays a pattern, which is read from a small memory, at (x,y) on the VGA output.
*   To set coordinates, first place the desired value of y onto SW[6:0] and press KEY[1].
*   Next, place the desired value of x onto SW[7:0] and then press KEY[2]. The (x,y)
*   coordinates are displayed (in hexadecimal) on (HEX3-2,HEX1-0). Finally, press KEY[3]
*   to draw the pattern at location (x,y).
*/
module vga_demo(CLOCK_50, SW, KEY, HEX3, HEX2, HEX1, HEX0,
				VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK,
				PS2_CLK, PS2_DAT, LEDR);
	
	//Board Input parameters
	input CLOCK_50;	
	input [9:0] SW;
	input [3:0] KEY;
    output [6:0] HEX3, HEX2, HEX1, HEX0;
	 output[9:0] LEDR;	
	 inout PS2_CLK;
	inout	PS2_DAT;
	wire KES;
	 
	 //VGA Adapter Parameters
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
	
	wire [7:0] blockVGA_X;       // x location of each object pixel
	wire [6:0] blockVGA_Y;       // y location of each object pixel
	
	wire [2:0] VGA_COLOR;
	wire plot;
	

	wire chooseColour;
	
	  parameter XSCREEN = 160, YSCREEN = 120;
	 parameter YSTOP = 104;
    parameter XDIM = 16, YDIM = 16;
    parameter X0 = 8'd80, Y0 = 7'd40;
    parameter ALT = 3'b000; // alternate object color
    parameter K = 2; // animation speed: use 20 for hardware, 2 for ModelSim
	
	//Background Drawing parameters
	wire [7:0] backgroundVGA_X;
	wire [6:0] backgroundVGA_Y;
	parameter X_MAX = 8'b10011111;
	parameter Y_MAX = 7'b1110111;
	 
	 /********
	 Drawing FSM Inputs
	 *******/

	wire [2:0] colour;
	wire [7:0] X, Z;
	wire [6:0] Y;
   wire [3:0] XC;
   wire [3:0] YC;
   wire [K-1:0] slow;
   wire go, sync;
	//changeBlock (already implemented by Daunte)
	
	/********
	 Drawing FSM Outputs
	 *******/
	wire [2:0] plotBlockColor;
	wire plotBlock;
	wire Ly, Ex, Ey, Lxc, Lyc, Exc, Eyc, LCounter, ECounter, ResetXDir, finishedDrawing, TDrop, newBlock;
	wire Done;
	wire checkBoard;
	wire DropBlock, DownBlock, LeftBlock, RightBlock;
	
	wire moveX, EMoveX, RMoveX;
	wire moveY, EMoveY, RMoveY;
	wire XDir, ELeftX, ERightX;
	

	/*****
	Modules of different blocks
	*****/
	wire [2:0] J2_COLOR; 
	wire [2:0] S2_COLOR;
	wire [2:0] O_COLOR;
	wire [2:0] I1_COLOR;
	
	//FSM Outputs
	J2 J2Block ({YC,XC}, CLOCK_50, J2_COLOR);
	S2 S2Block({YC,XC}, CLOCK_50, S2_COLOR);
	O OBlock({YC,XC}, CLOCK_50, O_COLOR);
	I1 I1Block({YC, XC}, CLOCK_50, I1_COLOR);
	
	//Drawing FSM Modules
	 wire [23:0] Counter;
	 //wire [9:0] Counter;
	 
	 manageMove XDirReg(KEY[0], ELeftX, ERightX, CLOCK_50, XDir);
	 
	 manageMove moveXReg(KEY[0], RMoveX, EMoveX, CLOCK_50, moveX);
	
	 manageMove moveYReg(KEY[0], RMoveY, EMoveY, CLOCK_50, moveY);
	 
	 oneSecondCounter C1(CLOCK_50, KEY[0], LCounter, ECounter, Counter);
	 assign Done = (Counter == 24'b11111111111111111111111);
	 //assign Done = (Counter == 10'b1111111111);
	 coor_count countY(Y0, CLOCK_50, KEY[0], Ey, newBlock, 1'b1, Y);
		  defparam countY.n = 7;

	//WATCH OUT!
	 coor_count countX(X0, CLOCK_50, KEY[0], Ex, newBlock, XDir /*1'b0*/, X);
		//Replace with XDir
        defparam countX.n = 8;

    UpDn_count countXC (4'd0, CLOCK_50, KEY[0], Exc, Lxc, 1'b1, XC);
        defparam countXC.n = 4;
    UpDn_count countYC (4'd0, CLOCK_50, KEY[0], Eyc, Lyc, 1'b1, YC);
        defparam countYC.n = 4;

    UpDn_count slowCounter ({K{1'b0}}, CLOCK_50, KEY[0], 1'b1, 1'b0, 1'b1, slow);
        defparam slowCounter.n = K;
    assign sync = (slow == 0);
	 


	/***********
	 
	 BACKEND FSM additional parameters
	
	 ***********/
	 
	 wire [3:0] currentBlock;
	 wire [2:0] gameBoard [0:19][0:15];
	 wire [4:0] YCOOR; 
	 wire [3:0] XCOOR;
	 
	 wire [1:0] YB;
	 wire [1:0] XB;
	 
	 
	/***********
	 
	 BACKEND FSM Outputs
	
	 ***********/
	 	 	 
	 wire LXCOOR, LYCOOR, EXCOOR, EYCOOR;
	 wire LXB, LYB, EXB, EYB;
	 wire EBlock, LShift, EShift, EBoard;
	
	 wire Erase, backendComplete;
	 wire [2:0] blockColor;
	 wire canDown, canLeft, canRight;
	 
	 wire doneLogic;
	 
	 //Configurations of each tetris block
	 
	 parameter cI1 = 16'b0000000000001111, cI2 = 16'b0100010001000100, cO = 16'b0000000001100110;
	 parameter cS1 = 16'b0000000001101100, cS2 = 16'b0000010001100010, cJ1 = 16'b0000000010001110, cJ2 = 16'b0000011001000100;
	 parameter cJ3 = 16'b0000000011100010, cJ4 = 16'b0000001000100110;
	 parameter cT1 = 16'b0000000001001110, cT2 = 16'b0000010001100100, cT3 = 16'b0000000011100100, cT4 = 16'b0000001001100010;
	 parameter cZ1 = 16'b0000000011000110, cZ2 = 16'b0000001001100100;

	 
	 //gameplay FSM modules
	 UpDn_count XBCount (2'b0, CLOCK_50, KEY[0], EXB, LXB, 1'b1, XB);
       defparam XBCount.n = 2;
    UpDn_count YBCount (2'b0, CLOCK_50, KEY[0], EYB, LYB, 1'b1, YB);
       defparam YBCount.n = 2;
	 
	 wire [15:0] shiftConfig;
	 wire [15:0] currentConfig;
	 gameBoardToggle gameToggle(CLOCK_50, KEY[0], EBoard, gameBoard, XCOOR + XB, YCOOR + YB, Erase);
	 
	 chooseConfigurationMux choose(cI1, cI2, cO, cS1, cS2, cJ1, cJ2, cJ3, cJ4, cT1, cT2, cT3, cT4, cZ1, cZ2, SW[9:8], currentConfig);
	 //replace the SW with some counter 
	 shiftReg s1(CLOCK_50, KEY[0], EShift, LShift, currentConfig, shiftConfig);
	  
	UpDn_count XCOORReg(4'b1001, CLOCK_50, KEY[0], EXCOOR, LXCOOR, XDir /*1'b0*/, XCOOR);
	//replace with XDir
	//UpDn_count XCOORReg(4'b1001, CLOCK_50, KEY[0], EXCOOR, LXCOOR, XDir, XCOOR);
		defparam XCOORReg.n = 4;

	//direction is subject to change!
	UpDn_count YCOORReg(5'b00000, CLOCK_50, KEY[0], EYCOOR, LYCOOR, 1'b1, YCOOR);
		defparam YCOORReg.n = 5;

	 getColor getColor1(CLOCK_50, EBlock, 4'b0110, shiftConfig[15], blockColor);
	 checkDown CD(CLOCK_50, EBlock, gameBoard, 4'b0110, XCOOR, YCOOR, canDown);
	 checkLeft CL(CLOCK_50, EBlock, gameBoard, 4'b0110, XCOOR, YCOOR, canLeft);
	 checkRight CR(CLOCK_50, EBlock, gameBoard, 4'b0110, XCOOR, YCOOR, canRight);
	 
	 
	 //need to automate go
	 
	chooseBlockMux chooseBlockM(J2_COLOR, S2_COLOR, O_COLOR, I1_COLOR, SW[9:8], colour);

    assign go = ~KEY[3];

    assign blockVGA_X = X + XC;
    assign blockVGA_Y = Y + YC;
	 
	 assign LEDR[0] = !canDown; 
	 assign LEDR[1] = (Y == YSTOP);
	
	
//DAUNTE code here

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire		[7:0]	ps2_key_data;
wire				ps2_key_pressed;

// Internal Registers
reg			[7:0]	last_data_received;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin
	if (KEY[0] == 1'b0)
		last_data_received <= 8'h00;
	else if (ps2_key_pressed == 1'b1)
		if(last_data_received == 8'hF0)
			last_data_received <= 8'h00;
		else
			last_data_received <= ps2_key_data;
end

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

PS2_Controller PS2 (
	// Inputs
	.CLOCK_50				(CLOCK_50),
	.reset				(~KEY[0]),

	// Bidirectionals
	.PS2_CLK			(PS2_CLK),
 	.PS2_DAT			(PS2_DAT),

	// Outputs
	.received_data		(ps2_key_data),
	.received_data_en	(ps2_key_pressed)
);

wire Resetn, start, gameover;
 wire Easy, Medium, Hard;
 wire left, right, down, rotate;
 wire [1:0] mode, difdisplay;
 wire [3:0] changeblock;
 wire [25:0] easyBigCount;
 wire [24:0] mediumBigCount;
 wire [23:0] hardBigCount;
 wire [22:0] adjustBigCount;
 wire easySmallCount, mediumSmallCount, hardSmallCount, adjustSmallCount;
 wire easySecEn, mediumSecEn, hardSecEn, adjustSecEn;
 reg secEn, smallCount;
 

 
 //assignments
 assign Resetn = KEY[0];
 
 //assigning values through keyboard for Quartus
 
 
 assign start = (last_data_received == 8'b01011010);//enter
 assign gameover = (last_data_received == 8'b01100110); //backspace
 assign Easy = (last_data_received == 8'b00010110); //1
 assign Medium = (last_data_received == 8'b00011110); //2
 assign Hard = (last_data_received == 8'b00100110); //3
 assign left = (last_data_received == 8'b00011100); //A
 assign right = (last_data_received == 8'b00100011); //D
 assign down = (last_data_received == 8'b00011011); // S
 assign rotate = (last_data_received == 8'b00011101); //W
 
 
 //assigning values through switches for modelsim
 /*
 assign start = SW[0];
 assign gameover = SW[1];
 assign Easy = SW[2];
 assign Medium = SW[3];
 assign Hard = SW[4];
 assign left = SW[5];
 assign right = SW[6];
 assign down = SW[7]; 
 assign rotate = SW[8];
 */
 
 //counters 
 
 bigCounterEasy bigeasy(1, CLOCK_50, Resetn, easyBigCount);
 bigCounterMedium bigmedium(1, CLOCK_50, Resetn, mediumBigCount);
 bigCounterHard bighard(1, CLOCK_50, Resetn, hardBigCount);
 bigCounterAdjust bigAdjust(1, CLOCK_50, Resetn, adjustBigCount);
 
 assign easySmallCount = &easyBigCount;
 assign mediumSmallCount = &mediumBigCount;
 assign hardSmallCount = &hardBigCount;
 assign adjustSmallCount = &adjustBigCount;
 
 smallCounter smalleasy(easySmallCount, CLOCK_50, Resetn, easySecEn);
 smallCounter smallmedium(mediumSmallCount, CLOCK_50, Resetn, mediumSecEn);
 smallCounter smallhard(hardSmallCount, CLOCK_50, Resetn, hardSecEn);
 smallCounter smallAdjust(adjustSmallCount, CLOCK_50, Resetn, adjustSecEn);
 
 always @(posedge CLOCK_50)
 case(difdisplay)
	2'b00: secEn <= easySecEn;
	2'b01: secEn <= mediumSecEn;
	2'b10: secEn <= hardSecEn;
	default: secEn = 1'b0;
 endcase
 
 always @(posedge CLOCK_50)
 case(difdisplay)
	2'b00: smallCount <= easySmallCount;
	2'b01: smallCount <= mediumSmallCount;
	2'b10: smallCount <= hardSmallCount;
	default: smallCount = 1'b0;
 endcase
 
 //FSM logic
 
 FSM_screen Screen(start, gameover, Resetn, mode, CLOCK_50);
 
 FSM_Home Home(mode, Easy, Medium, Hard, Resetn, difdisplay, CLOCK_50);
 
 FSM_Gameplay Gameplay(smallCount, adjustSmallCount, mode, left, down, right, rotate, Resetn, changeblock, CLOCK_50); // replaced secEn with smallCount, replaced adjustSecEn with adjustSmallCount
 
 //mode 2'b10 = homescreen
 //mode 2'b01 = gameplay
 //mode 2'b00 = endscreen
 //difdisplay 2'b00 = easy
 //difdisplay 2'b01 = medium
 //difdisplay 2'b10 = hard
 wire [2:0] screenDisplay;
 //slow = 000
 //normal = 001
 //fast == 010
 //gamescreen == 011

 assign screenDisplay[0] = ((mode == 2'b10) & (difdisplay == 2'b01))|(mode == 2'b01);
 assign screenDisplay[1] = ((mode == 2'b10) & (difdisplay == 2'b10))|(mode == 2'b01);
 assign screenDisplay[2] = (mode == 2'b00); 
 
 assign LEDR[3] = (mode == 2'b10);
 assign LEDR[4] = (mode == 2'b01);
 assign LEDR[5] = (mode == 2'b00);
 assign LEDR[6] = (difdisplay == 2'b00);
 assign LEDR[7] = (difdisplay == 2'b01);
 assign LEDR[8] = (difdisplay == 2'b10);
 assign LEDR[9] = KES;


//end of Daunte code
	

	 //Background screen Sprite
	 
	 
	 wire [7:0] XBackground;
	 wire [6:0] YBackground;
	 wire EBackgroundx, EBackgroundy;
	 
	 wire [2:0] BACKGROUND_COLOR;
	 wire [2:0] SLOW_COLOR;
	 wire [2:0] NORMAL_COLOR;
	 wire [2:0] HARD_COLOR;
	 wire [2:0] GAME_COLOR;
	 wire [2:0] OVER_COLOUR;
	 
	 SlowSelected slowScreen(160*YBackground + XBackground, CLOCK_50, SLOW_COLOR);
	 NormalSelected normalScreen(160*YBackground + XBackground, CLOCK_50, NORMAL_COLOR);
	 FastSelected fastScreen(160*YBackground + XBackground, CLOCK_50, HARD_COLOR);
	 GameScreen gameScreen(160*YBackground + XBackground, CLOCK_50, GAME_COLOR);
	 GameOver gameOverScreen(160*YBackground + XBackground, CLOCK_50, OVER_COLOUR);
	 

	 backgroundCount U3 (CLOCK_50, KEY[0], EBackgroundx, X_MAX, XBackground);    // column counter
        defparam U3.n = 8;
    // enable XC when VGA plotting starts
    regn U5 (1'b1, KEY[0], KES, CLOCK_50, EBackgroundx); //change KES back to ~KEY[3]
        defparam U5.n = 1;
    backgroundCount U4 (CLOCK_50, KEY[0], EBackgroundy, Y_MAX, YBackground);    // row counter
        defparam U4.n = 7;
    // enable YC at the end of each object row
    assign EBackgroundy = (XBackground == 8'b10011111);
	 
	 regn U7 (XBackground, KEY[0], 1'b1, CLOCK_50, backgroundVGA_X);
        defparam U7.n = 8;
    regn U8 (YBackground, KEY[0], 1'b1, CLOCK_50, backgroundVGA_Y);
        defparam U8.n = 7;
	 
	 	assign KES = ((mode == 2'b10) & (Easy | Medium | Hard))|((mode == 2'b01) & start)|((mode == 2'b00) & gameover);

	 chooseBackgroundMux chooseBackgroundM(SLOW_COLOR, NORMAL_COLOR, HARD_COLOR, GAME_COLOR, OVER_COLOUR, screenDisplay, BACKGROUND_COLOR); //FROM DAUNTE, change SW[9:8] to screenDisplay
	 choosePlotMux choosePlotM(BACKGROUND_COLOR, plotBlockColor, SW[7], VGA_COLOR);
	 chooseCoordinateX choosePlotX(backgroundVGA_X, blockVGA_X, SW[7], VGA_X);
	 chooseCoordinateY choosePlotY(backgroundVGA_Y, blockVGA_Y, SW[7], VGA_Y);
	   
	//DAUNTE 
    //assign plot = ~KEY[3];
	 //&& 
	 //Must change this
	 assign plot = KES | (!KES & plotBlock);
	 
	 	 gameLogicFSM GLF
	 (finishedDrawing, CLOCK_50, KEY[0], checkBoard, canDown, blockColor, 
	 XB, YB, LXCOOR, LYCOOR, LXB, LYB, EXB, EYB, 
	 EBlock, LShift, EShift, EXCOOR, EYCOOR, RMoveX, EMoveX, RMoveY, EMoveY, ELeftX, ERightX,
	 EBoard, Erase, 
	 DropBlock, DownBlock, LeftBlock, RightBlock, doneLogic);
	
	drawBlockFSM dBF
	(CLOCK_50, KEY[0], ~KEY[2],  doneLogic, 
	mode, /*sync, */colour, X, Y, XC, YC, slow, Done, changeblock, 
	canDown, canLeft, canRight, 
	moveX, moveY, Ex, Ey, Lxc, Lyc, Exc, Eyc, LCounter, ECounter, ResetXDir, 
	 finishedDrawing, newBlock, checkBoard, plotBlockColor, 
	 plotBlock, DropBlock, DownBlock, LeftBlock, RightBlock);
	 
	 

    // connect to VGA controller
    vga_adapter VGA (
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(VGA_COLOR),
			.x(VGA_X), //change to mux
			.y(VGA_Y),
			.plot(plot),//change back to ~KEY[3]
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

module manageMove(Resetn, Zero, One, Clock, Q);
	input Resetn, Zero, One, Clock;
	output reg Q;
	
	always @(posedge Clock)
		if(!Resetn)
			Q <= 1'b0;
		else if(Zero)
			Q <= 1'b0;
		else if(One)
			Q <= 1'b1; 
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

//Implement reset counter
module backgroundCount(Clock, Resetn, E, MaxCoor, Q);
	parameter n = 8;
	input Clock, Resetn, E;
	input [n-1:0] MaxCoor;
	output reg [n-1:0] Q;
	
	always @(posedge Clock)
		begin
		
		if(Resetn == 0)
			Q <= 0;
		else if(E)
			if(Q == MaxCoor)
				Q <= 0;
			else
				Q <= Q + 1;
				
		end
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

module choosePlotMux(A, B, S, Out);
	input [2:0] A, B;
	input S;
	output reg [2:0] Out;
	always@(*)
		begin
			if(S == 0)
				Out = A;
			else
				Out = B;
		end
	endmodule

module chooseCoordinateX(A, B, S, Out);
	input [7:0] A, B;
	input S;
	output reg [7:0] Out;
	always@(*)
		begin
			if (S == 0)
				Out = A;
			else 
				Out = B;
		end
endmodule
	

module chooseCoordinateY(A, B, S, Out);
	input [6:0] A, B;
	input S;
	output reg [6:0] Out;
	always@(*)
		begin
			if (S == 0)
				Out = A;
			else 
				Out = B;
		end
endmodule
	

module chooseBackgroundMux(A, B, C, D, E, S, Out); //CHANGING HERE (added E, S is 3b)
	input [2:0] A, B, C, D, E;
	input [2:0] S;
	output reg [2:0] Out;
	
	always@(*)
		begin
			if(S == 3'b000)
				Out = A;
			else if(S == 3'b001)
				Out = B;
			else if(S == 3'b010)
				Out = C;
			else if (S == 3'b011)
				Out = D;
			else if (S == 3'b100)
				Out = E;
			else 
				Out = 3'bxxx;
		end
endmodule
	

module chooseSprite(TetrisColor, BackgroundColor, S, Out);
	input [2:0] TetrisColor, BackgroundColor;
	input S;
	output reg[2:0] Out;
	
	always@(*)
		begin
			if(S == 1'b1)
				Out = BackgroundColor;
			else
				Out = TetrisColor;
	end
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
	 //output reg [9:0] Counter;
	 output reg [23:0] Counter;
	 	 
	 always @(posedge Clock)
		 begin
				if(Resetn == 0)
					Counter <= 24'b0;
					//Counter <= 10'b0;
				else if(L == 1)
					Counter <= 24'b0;
					//Counter <= 10'b0;
				else if(E == 1)
					Counter <= Counter + 1;
		 end
endmodule





	


	
