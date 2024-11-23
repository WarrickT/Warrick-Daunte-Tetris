module drawBlockFSM(CLOCK_50, Resetn, leftKey, doneLogic, mode,/* sync,*/ colour, X, Y, XC, YC, slow, Done, changeblock, canDown, canLeft, canRight
	,moveX, moveY, Ex, Ey, Lxc, Lyc, Exc, Eyc, LCounter, ECounter, ResetXDir, finishedDrawing, newBlock, checkBoard
	, plotBlockColor, plotBlock, DropBlock, DownBlock, LeftBlock, RightBlock
);

	 parameter NotPlayButton = 4'b0000, NothingButton = 4'b0001, Drop_ = 4'b0010, Left_ = 4'b0011, Right_ = 4'b0100, Down_ = 4'b0101, Rotate_ = 4'b0110, Leftwait = 4'b0111, Rightwait = 4'b1000, Downwait = 4'b1001, Rotatewait = 4'b1010;
	 
	 
	 parameter Start = 5'b00000, getData = 5'b00001, paintX = 5'b00010, paintY = 5'b00011, waitInput = 5'b00100, checkDrop = 5'b11111; 
	 parameter Drop = 5'b00101, Down = 5'b00110, Left = 5'b00111, Right = 5'b01000, Rotate = 5'b01001;
	 parameter getData2 = 5'b01010, eraseX = 5'b01011, eraseY = 5'b01100, resetXCYC = 5'b01101, enableCoordinate = 5'b01110;
	 
	
	parameter XSCREEN = 160, YSCREEN = 120;
	 parameter YSTOP = 104;
    parameter XDIM = 16, YDIM = 16;
    parameter X0 = 8'd39, Y0 = 7'd40;
    parameter ALT = 3'b000; // alternate object color
    parameter K = 2; // animation speed: use 20 for hardware, 2 for ModelSim

	input CLOCK_50;
	input [1:0] mode/*, sync*/;
	input Resetn;
	input [2:0] colour;
	input [7:0] X;
	input [6:0] Y;
    input [3:0] XC;
    input [3:0] YC;
    input [K-1:0] slow;
	input Done;
	input [3:0] changeblock;
	
	input canDown;
	input canLeft;
	input canRight;
	
	input doneLogic;
	input leftKey;
	//input rightKey;
	//these will be replaced with Daunte's outputs. 
	
	
	//input canRotate;
	input moveX;
	input moveY;
	
	
	output reg Ex, Ey, Lxc, Lyc, Exc, Eyc;
	output reg LCounter, ECounter, ResetXDir, finishedDrawing;
	output reg newBlock;
	output reg checkBoard;
	output reg [2:0] plotBlockColor;
	output reg plotBlock;
	
	output reg DropBlock, DownBlock, LeftBlock, RightBlock;
	
	reg [4:0] y_Q, Y_D;


	 always @ (*)
	  case (y_Q)
			Start:  if (mode != 2'b01) Y_D = Start;
					 else Y_D = getData;
			getData: Y_D = paintX;
			paintX:  if (XC != XDIM-1) Y_D = getData;    // draw
				 else Y_D = paintY;
			paintY:  if (YC != YDIM-1) Y_D = getData;
				 else 
					if(!canDown)
						Y_D = Start;
					else
						Y_D = waitInput;
						/*
			waitInput:	begin  
					if(Y == YSTOP) Y_D = Start;
					else 
						if(!Done) Y_D = waitInput; //accounts for delay AND completion of backend. Need some kind of variable to account for delay!
						else Y_D = checkDrop;
				end *///might be excessive
			
			waitInput: 
				begin
					/*
					if(Y == YSTOP) Y_D = Start;
					else 
						if(!Done) 
							if(leftKey && canLeft)
								//Y_D = Drop;
								Y_D = Left;
							else
								Y_D = waitInput;
						else
							Y_D = Drop; 
							*/
							
					if(changeblock == Drop_)
						Y_D = Drop;
					else if((changeblock == Left_) & (canLeft) ) //Just added stuff here from the drop. 
						Y_D = Left;
					else if((changeblock == Right_) & (canRight))
						Y_D = Right;
					else if((changeblock == Down_) & (canDown))
						Y_D = Down;
					else
						Y_D = waitInput;
						
				end	
				
			//All from the same branch
			Drop: if(!doneLogic) Y_D = Drop;
					else Y_D = checkDrop;
			Left: if(!doneLogic) Y_D = Left;
					else Y_D = checkDrop;
					
			Right: if(!doneLogic) Y_D = Right;
						else Y_D = checkDrop;	
			Down: if(!doneLogic) Y_D = Down;
						else Y_D = checkDrop;
						
			checkDrop: 
				Y_D = getData2;
			getData2: Y_D = eraseX;
			eraseX:  if (XC != XDIM-1) Y_D = getData2;    // erase
				 else Y_D = eraseY;
			eraseY:  if (YC != YDIM-1) Y_D = getData2;
				 else Y_D = resetXCYC;
			resetXCYC:  Y_D = enableCoordinate;
			enableCoordinate:  Y_D = paintX;
	  endcase
		 
		 always @ (*)
		 begin
			  //Pixel Drawing
			  Lxc = 1'b0; Lyc = 1'b0; Exc = 1'b0; Eyc = 1'b0; plotBlockColor = colour; plotBlock = 1'b0;
			  //Position of Tetris Block
			  Ex = 1'b0; Ey = 1'b0; ResetXDir = 0; 
			  //Delay
			  LCounter = 1'b1; ECounter = 1'b0; 
			  //Command Checking
			  DropBlock = 1'b0; DownBlock = 1'b0; LeftBlock = 1'b0; RightBlock = 1'b0;  
			  //Backend checking 
			  checkBoard = 1'b0; finishedDrawing = 1'b0;
			  newBlock = 1'b0;
			  case (y_Q)
					Start:  begin Lxc = 1'b1; Lyc = 1'b1; finishedDrawing = (canDown == 0); newBlock = 1'b1; end
					paintX:  begin Exc = 1'b1; plotBlock = (colour != 3'b000); ResetXDir = 1'b1; end   // color a pixel
					paintY:  begin Lxc = 1'b1; Eyc = 1'b1; end 
					//waitInput:  begin Lyc = 1'b1; LCounter = 1'b0; ECounter = 1'b1; checkBoard = 1'b1; end//checkBoard = 1'b1; end
					waitInput: begin Lyc = 1'b1; LCounter = 1'b0; ECounter = 1'b1; end
					Drop: begin checkBoard = 1'b1; DropBlock = 1'b1; end
					Left: begin checkBoard = 1'b1; LeftBlock = 1'b1; end
					Right: begin checkBoard = 1'b1; RightBlock = 1'b1; end 
					Down: begin checkBoard = 1'b1; DownBlock = 1'b1; end
					
					eraseX:  begin Exc = 1'b1; plotBlockColor = ALT; plotBlock = (colour != 3'b000); end   // color a pixel Thi
					eraseY:  begin Lxc = 1'b1; Eyc = 1'b1; end
					resetXCYC:  begin Lyc = 1'b1; end
					enableCoordinate:  begin Ey = (moveY == 1); Ex = (moveX == 1); end
			  endcase
		 end

    always @(posedge CLOCK_50)
        if (!Resetn)
            y_Q <= 1'b0;
        else
            y_Q <= Y_D;



	endmodule
	
	