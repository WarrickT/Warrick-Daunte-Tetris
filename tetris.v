module tetris(
	// Inputs
	CLOCK_50,
	KEY,
	SW,

	// Bidirectionals
	PS2_CLK,
	PS2_DAT,
	
	// Outputs
	HEX0,
	HEX1,
	LEDR
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input		[4:0] SW;

// Bidirectionals
inout				PS2_CLK;
inout				PS2_DAT;

// Outputs
output		[6:0]	HEX0;
output		[6:0]	HEX1;
output		[9:0] LEDR;

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

Hexadecimal_To_Seven_Segment Segment0 (
	// Inputs
	.hex_number			(last_data_received[3:0]),

	// Bidirectional

	// Outputs
	.seven_seg_display	(HEX0)
);

Hexadecimal_To_Seven_Segment Segment1 (
	// Inputs
	.hex_number			(last_data_received[7:4]),

	// Bidirectional

	// Outputs
	.seven_seg_display	(HEX1)
);

/*****************************************************************************
 *                         Everything for tetris below here      		        *
 *****************************************************************************/


 //reg [7:0] tetris_data;
 //always @(*)


 wire Resetn, start, gameover;
 wire Easy, Medium, Hard;
 wire left, right, down, rotate;
 wire [1:0] mode, difdisplay;
 wire [3:0] changeblock;
 wire [25:0] easyBigCount;
 wire [24:0] mediumBigCount;
 wire [23:0] hardBigCount;
 wire [21:0] adjustBigCount;
 wire easySmallCount, mediumSmallCount, hardSmallCount, adjustSmallCount;
 wire easySecEn, mediumSecEn, hardSecEn, adjustSecEn;
 reg secEn;
 
 wire enable, switchblock;
 
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
	2'b00: secEn <= easySecEn; // 
	2'b01: secEn <= mediumSecEn;
	2'b10: secEn <= hardSecEn;
	default: secEn = 1'b0;
 endcase
 
 //FSM logic
 
 FSM_screen Screen(start, gameover, Resetn, mode, CLOCK_50);
 
 FSM_Home Home(mode, Easy, Medium, Hard, Resetn, difdisplay, CLOCK_50);
 
 FSM_Gameplay Gameplay(secEn, adjustSecEn, enable, switchblock, mode, left, down, right, rotate, Resetn, changeblock, CLOCK_50);
 
 //testing
 /*assign LEDR[0] = mode[1];
 assign LEDR[1] = mode[0];
 assign LEDR[2] = ~mode[0] & ~mode[1]; */
 assign LEDR[0] = (changeblock == 4'b0000);
 assign LEDR[1] = (changeblock == 4'b0001);
 assign LEDR[2] = (changeblock == 4'b0010);
 assign LEDR[3] = (changeblock == 4'b0011);
 assign LEDR[4] = (changeblock == 4'b0100);
 assign LEDR[5] = (changeblock == 4'b0101);
 assign LEDR[6] = (changeblock == 4'b0110);
 assign LEDR[7] = (changeblock == 4'b0111);
 assign LEDR[8] = (changeblock == 4'b1000);
 assign LEDR[9] = (changeblock == 4'b1001);
 //***DO TESTING FOR GAMEPLAY STATES

endmodule