module gameLogicFSM(CLOCK_50, Resetn, checkBoard, canDown, currentColor, XB, YB, LXCOOR, LYCOOR, LXB, LYB, EXB, EYB, EBlock, LShift, EShift, EYPOS, YDir, EBoard, Erase);
	input CLOCK_50, checkBoard, canDown;
	input Resetn;
	input [2:0] currentColor;
	input [1:0] XB, YB;
	output reg LXCOOR, LYCOOR, LXB, LYB, EXB, EYB, EBlock, LShift, EShift, EYPOS, YDir, EBoard, Erase;
	reg [3:0] y, Y_D;
	
	parameter spawnNewBlock = 4'b0000, idle = 4'b0001, waitDown = 4'b0010, setDown = 4'b0011, clearCurrent = 4'b0100, grabData = 4'b0101, clearX = 4'b0110;
	parameter clearY = 4'b0111, updateXBYB = 4'b1000, grabData2 = 4'b1001, updateX = 4'b1010, updateY = 4'b1011, moveDown = 4'b1100, draw = 4'b1101;
	
	//State Table
	always@(*)
		case(y)
			spawnNewBlock: if(!checkBoard) Y_D = spawnNewBlock;
								else Y_D = waitDown;
			idle: if(!checkBoard) Y_D = idle;
					else Y_D = waitDown;
			waitDown: if(canDown) Y_D = setDown;
						else Y_D = spawnNewBlock;
			setDown: Y_D = clearCurrent;
			clearCurrent: Y_D = grabData;
			
			grabData: Y_D = clearX;
			
			clearX: if(XB!=3) Y_D = grabData;
					else Y_D = clearY;
			clearY: if(YB!=3) Y_D = grabData;
					else Y_D = updateXBYB;
					
			updateXBYB: Y_D = grabData2;
			grabData2: Y_D = updateX;
			updateX: if(XB != 3) Y_D = grabData2;
					 else Y_D = updateY;
			updateY: if(YB != 3) Y_D = grabData2;
					else Y_D = moveDown;
			moveDown: if(checkBoard) Y_D = moveDown;
						else Y_D = idle;
					//Store this direction
					
		endcase
	//Outputs 
	always@(*)
		begin 
			LXCOOR = 1'b0; LYCOOR = 1'b0; LXB = 1'b0; LYB = 1'b0; EXB = 1'b0; EYB = 1'b0; EBlock = 1'b0; LShift = 1'b0; EShift = 1'b0; EYPOS = 1'b0; YDir = 1'b0; EBoard = 1'b0; Erase = 1'b0;
			case(y)
				spawnNewBlock: begin LXCOOR = 1'b1; LYCOOR = 1'b1; EBlock = 1'b1;end
				idle: begin YDir = 1'b1; end
				clearCurrent: begin LXB = 1'b1; LYB = 1'b1; LShift = 1'b1; end 
				grabData: begin EBlock = 1'b1; end
				clearX: begin Erase = 1'b1; EXB = 1'b1; EShift = 1'b1; EBoard = (currentColor != 3'b000); end //must be painted black instead!
				clearY: begin EYB = 1'b1; end
				updateXBYB: begin EYPOS = 1'b1; LXB = 1'b1; LYB = 1'b1; LShift = 1'b1; end
				grabData2: begin EBlock = 1'b1; end
				updateX: begin EXB = 1'b1; EShift = 1'b1; EBoard = (currentColor != 3'b000); end
				updateY: begin EYB = 1'b1; end
				moveDown: begin YDir = 1'b1; end
			endcase	
		end
	
	
    always @(posedge CLOCK_50)
        if (!Resetn)
            y <= 4'b0;
        else
            y <= Y_D;
				
endmodule


	