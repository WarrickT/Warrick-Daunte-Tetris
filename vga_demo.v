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
	
	//Input parameters
	input CLOCK_50;	
	input [9:0] SW;
	input [3:0] KEY;
    output [6:0] HEX3, HEX2, HEX1, HEX0;
	 output[9:0] LEDR;
	 
	 parameter X_MAX = 8'b10011111;
	 parameter Y_MAX = 7'b1110111;
	 
	 parameter X_START = 79;
	 parameter Y_START = 39;
	 //Placeholder
	
	//Adapter Parameters
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;
	
	//DAUNTE added
	// Bidirectionals
	inout				PS2_CLK;
	inout				PS2_DAT;

	//Drawing any pixel
	wire [7:0] VGA_X;       // x location of each object pixel
	wire [6:0] VGA_Y;       // y location of each object pixel
	
	//Spawning Tetris Blocks
	wire [7:0] X;           // starting x location of object
	wire [6:0] Y;           // starting y location of object
	
	//Tetris Block Sprite
   wire [3:0] XC, YC;      // used to access obj
   wire Ex, Ey;
	
	wire [2:0] VGA_COLOR;   // color of each object pixel
	wire [2:0] J2_COLOR; 
	wire [2:0] S2_COLOR;
	wire [2:0] O_COLOR;
	wire [2:0] I1_COLOR;
	
	//FSM Outputs
	wire [7:0] XCoor;
	wire [6:0] YCoor;
	//wire LYDown, EYDown, 
	
	
	
	
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
 //wire left, right, down, rotate;
 wire [1:0] mode, difdisplay;
 /*wire [3:0] changeblock;
 wire [25:0] easyBigCount;
 wire [24:0] mediumBigCount;
 wire [23:0] hardBigCount;
 wire [21:0] adjustBigCount;
 wire easySmallCount, mediumSmallCount, hardSmallCount, adjustSmallCount;
 wire easySecEn, mediumSecEn, hardSecEn, adjustSecEn;
 reg secEn;
 
 wire enable, switchblock; */
 
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
 /*
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
 */
 //FSM logic
 
 FSM_screen Screen(start, gameover, Resetn, mode, CLOCK_50);
 
 FSM_Home Home(mode, Easy, Medium, Hard, Resetn, difdisplay, CLOCK_50);
 
 //mode 2'b10 = homescreen
 //mode 2'b01 = gameplay
 //mode 2'b00 = endscreen
 //difdisplay 2'b00 = easy
 //difdisplay 2'b01 = medium
 //difdisplay 2'b10 = hard
 wire [1:0] screenDisplay;
 //slow = 00
 //normal = 01
 //fast == 10
 //gamescreen == 11
 assign screenDisplay[0] = ((mode == 2'b10) & (difdisplay == 2'b01))|(mode == 2'b01);
 assign screenDisplay[1] = ((mode == 2'b10) & (difdisplay == 2'b10))|(mode == 2'b01);
 
 assign LEDR[0] = (mode == 2'b10);
 assign LEDR[1] = (mode == 2'b01);
 assign LEDR[2] = (mode == 2'b00);
 assign LEDR[3] = (difdisplay == 2'b00);
 assign LEDR[4] = (difdisplay == 2'b01);
 assign LEDR[5] = (difdisplay == 2'b10);


//end of Daunte code
	
	
	 //tetris block sprites
	 /*
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
	 
    J2 J2Block ({YC,XC}, CLOCK_50, J2_COLOR);
	 S2 S2Block({YC,XC}, CLOCK_50, S2_COLOR);
	 O OBlock({YC,XC}, CLOCK_50, O_COLOR);
	 I1 I1Block({YC, XC}, CLOCK_50, I1_COLOR);
	 
	 chooseBlockMux M2(J2_COLOR, S2_COLOR, O_COLOR, I1_COLOR, SW[9:8], VGA_COLOR);
	 
    // the object memory takes one clock cycle to provide data, so store
    // the current values of (x,y) addresses to remain synchronized
    regn U7 (X + XC, KEY[0], 1'b1, CLOCK_50, VGA_X);
        defparam U7.n = 8;
    regn U8 (Y + YC, KEY[0], 1'b1, CLOCK_50, VGA_Y);
        defparam U8.n = 7;	 
		  
		 */
		  
		  
	 //Background screen Sprite
	 
	 
	 wire [7:0] XB;
	 wire [6:0] YB;
	 wire EBackgroundx, EBackgroundy;
	 
	 wire [2:0] SLOW_COLOR;
	 wire [2:0] NORMAL_COLOR;
	 wire [2:0] HARD_COLOR;
	 wire [2:0] GAME_COLOR;
	 
	 
	 SlowSelected slowScreen(160*YB + XB, CLOCK_50, SLOW_COLOR);
	 NormalSelected normalScreen(160*YB + XB, CLOCK_50, NORMAL_COLOR);
	 FastSelected fastScreen(160*YB + XB, CLOCK_50, HARD_COLOR);
	 GameScreen gameScreen(160*YB + XB, CLOCK_50, GAME_COLOR);
	 
	 
	 regn U1 (7'b0000000, KEY[0], ~KEY[1], CLOCK_50, Y);
        defparam U1.n = 7;
    regn U2 (8'b00000000, KEY[0], ~KEY[2], CLOCK_50, X);
        defparam U2.n = 8;
		
	 backgroundCount U3 (CLOCK_50, KEY[0], EBackgroundx, X_MAX, XB);    // column counter
        defparam U3.n = 8;
    // enable XC when VGA plotting starts
	regn U5 (1'b1, KEY[0], KES, CLOCK_50, EBackgroundx); //change KES back to ~KEY[3]
        defparam U5.n = 1;
    backgroundCount U4 (CLOCK_50, KEY[0], EBackgroundy, Y_MAX, YB);    // row counter
        defparam U4.n = 7;
    // enable YC at the end of each object row
    assign EBackgroundy = (XB == 8'b10011111);
	 
	 
	 chooseBackgroundMux M1(SLOW_COLOR, NORMAL_COLOR, HARD_COLOR, GAME_COLOR, screenDisplay, VGA_COLOR); //FROM DAUNTE, change SW[9:8] to screenDisplay
	 
	  regn U7 (XB, KEY[0], 1'b1, CLOCK_50, VGA_X);
        defparam U7.n = 8;
    regn U8 (YB, KEY[0], 1'b1, CLOCK_50, VGA_Y);
        defparam U8.n = 7;	 
	 

	//DAUNTE TESTING
    //assign plot = ~KEY[3];
	 wire KES = ((mode == 2'b10) & (Easy | Medium | Hard))|((mode == 2'b01) & start);
	 assign plot = KES;

    // connect to VGA controller
    vga_adapter VGA (
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(VGA_COLOR),
			.x(VGA_X),
			.y(VGA_Y),
	   		.plot(KES),//change back to ~KEY[3]
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

module chooseBackgroundMux(A, B, C, D, S, Out);
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

	
	


	
	
