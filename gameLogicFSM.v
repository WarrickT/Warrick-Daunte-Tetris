module gameLogicFSM(finishedDrawing, CLOCK_50, Resetn, checkBoard, canDown, currentColor, XB, YB, LXCOOR, LYCOOR, LXB, LYB, EXB, EYB, EBlock, LShift, EShift, EXCOOR, EYCOOR, 
	RMoveX, EMoveX, RMoveY, EMoveY, ELeftX, ERightX, EBoard, Erase, /*new stuff*/ donePlotting,
	DropBlock, DownBlock, LeftBlock, RightBlock, doneLogic);
	//output reg completeBackend 
	//input leftClicked, rightClicked, downClicked, rotateClicked
	//output EXCOOR, XDIR, buttonClicked/ 
	
	input CLOCK_50, checkBoard, canDown;
	input Resetn;
	input [2:0] currentColor;
	input [1:0] XB, YB;
	input finishedDrawing;
	input DropBlock, DownBlock, LeftBlock, RightBlock;
	input donePlotting;
	
	
	output reg LXCOOR, LYCOOR;
	output reg LXB, LYB, EXB, EYB;
	output reg EBlock, LShift, EShift;
	output reg EXCOOR, EYCOOR;
	output reg RMoveX, EMoveX;
	output reg RMoveY, EMoveY;
	output reg ELeftX, ERightX; 
	output reg EBoard, Erase;
	
	output reg doneLogic;
	

	reg [4:0] y, Y_D;
	
	//parameter spawnNewBlock = 4'b0000, idle = 4'b0001, waitDown = 4'b0010, setDown = 4'b0011, clearCurrent = 4'b0100, grabData = 4'b0101, clearX = 4'b0110;
	//parameter clearY = 4'b0111, updateXDirection = 4'b1000, updateXBYB = 4'b1001, grabData2 = 4'b1010, updateX = 4'b1011, updateY = 4'b1100, moveDown = 4'b1101, draw = 4'b1110;
	
	parameter spawnNewBlock = 5'b00000, idle = 5'b00001, waitDown = 5'b00010, setDown = 5'b00011, clearCurrent = 5'b00100, grabData = 5'b00101, clearX = 5'b00110;
	parameter clearY = 5'b00111, /*New change*/ updateXDirection = 5'b10000, updateDrop = 5'b01000, updateLeft = 5'b01001, updateRight = 5'b01010, updateDown = 5'b01011, grabData2 = 5'b01100;
	parameter updateX = 5'b01101, updateY = 5'b01110, moveDown = 5'b01111;

	//State Table
	always@(*)
		case(y)
			spawnNewBlock: if(!checkBoard) Y_D = spawnNewBlock;
								else Y_D = waitDown;
			idle: if(!canDown)
						if(donePlotting)
							Y_D  = waitDown;
						else
							Y_D = idle;
					else
						if(!checkBoard) Y_D = idle;
						else Y_D = waitDown;
					
					/*
				if(!checkBoard) Y_D = idle;
					else Y_D = waitDown; *///it's gonna sit here! 
					
			waitDown: if(canDown) Y_D = setDown;
						else Y_D = spawnNewBlock;
						
			setDown: Y_D = clearCurrent;
			
			clearCurrent: Y_D = grabData;
			
			grabData: Y_D = clearX;
			
			clearX: if(XB!=3) Y_D = grabData;
					else Y_D = clearY;
					
			clearY: if(YB!=3) Y_D = grabData;
						else Y_D = updateXDirection; 
						
			updateXDirection: 
					if(DropBlock) 
						Y_D = updateDrop;
					else if(LeftBlock)
						Y_D = updateLeft;
					else if(RightBlock)
						Y_D = updateRight;
					else if(DownBlock)
						Y_D = updateDown;
			
			
			updateDrop: Y_D = grabData2;
			
			updateLeft: Y_D = grabData2;
			
			updateRight: Y_D = grabData2;
			
			updateDown: Y_D = grabData2;
											
			grabData2: Y_D = updateX;
			
			updateX: if(XB != 3) Y_D = grabData2;
					 else Y_D = updateY;
					 
			updateY: if(YB != 3) Y_D = grabData2;
					else Y_D = moveDown;
					
			moveDown: if(checkBoard) Y_D = moveDown;
						else Y_D = idle;
					
		endcase
	//Outputs 
	always@(*)
		begin 
			LXCOOR = 1'b0; LYCOOR = 1'b0; LXB = 1'b0; LYB = 1'b0; EXB = 1'b0; EYB = 1'b0; EBlock = 1'b0; LShift = 1'b0; EShift = 1'b0; 
			EXCOOR = 1'b0; EYCOOR = 1'b0; 
			EBoard = 1'b0; Erase = 1'b0; ;
			RMoveX = 1'b0; EMoveX = 1'b0; RMoveY = 1'b0; EMoveY = 1'b0; ELeftX = 1'b0; ERightX = 1'b0;
			doneLogic = 1'b0;
			
			case(y)
				spawnNewBlock: begin LXCOOR = 1'b1; LYCOOR = 1'b1; EBlock = 1'b1; end
				
				idle: begin LXCOOR = (finishedDrawing == 1); LYCOOR = (finishedDrawing == 1); EBlock = (finishedDrawing == 1); end
				
				waitDown: begin RMoveY = 1'b1; RMoveX = 1'b1; end
			
				clearCurrent: begin LXB = 1'b1; LYB = 1'b1; LShift = 1'b1; end 
				
				grabData: begin EBlock = 1'b1; end
				
				clearX: begin Erase = 1'b1; EXB = 1'b1; EShift = 1'b1; EBoard = (currentColor != 3'b000); end //must be painted black instead!
				
				clearY: begin EYB = 1'b1; end
								
				updateXDirection: begin ELeftX = (LeftBlock == 1); ERightX = (RightBlock == 1); end
				
				updateDrop: begin EYCOOR = 1'b1; LXB = 1'b1; LYB = 1'b1; LShift = 1'b1; end
				
				updateLeft: begin EXCOOR = 1'b1; LXB = 1'b1; LYB = 1'b1; LShift = 1'b1; end
				
				updateRight: begin EXCOOR = 1'b1; LXB = 1'b1; LYB = 1'b1; LShift = 1'b1; end 
				
				updateDown: begin EYCOOR = 1'b1; LXB = 1'b1; LYB = 1'b1; LShift = 1'b1; end
				
				grabData2: begin EBlock = 1'b1; end
				
				updateX: begin EXB = 1'b1; EShift = 1'b1; EBoard = (currentColor != 3'b000); end
				
				updateY: begin EYB = 1'b1; end
				
				moveDown: begin EMoveY = (DropBlock == 1'b1 | DownBlock ==  1'b1); EMoveX = (LeftBlock == 1 | RightBlock == 1); doneLogic = 1'b1; end
			endcase	
		end
	
	
    always @(posedge CLOCK_50)
        if (!Resetn)
            y <= 4'b0;
        else
            y <= Y_D;
				
endmodule

