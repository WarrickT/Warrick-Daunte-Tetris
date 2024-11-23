module checkRight(Clock, Enable, gameBoard, currentBlock, XPOS, YPOS, canMove);
	input [2:0] gameBoard [0:19][0:15];
	input [4:0] YPOS;
	input [3:0] XPOS;
	input [3:0] currentBlock;
	input Clock, Enable;

	output reg canMove;

	always@(posedge Clock)
		if(Enable == 1)
			case(currentBlock)
				4'b0000: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 3][XPOS + 4] == 3'b000);  //I1
				4'b0001: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS][XPOS + 2] == 3'b000) && (gameBoard[YPOS + 1][XPOS + 2] == 3'b000) && (gameBoard[YPOS + 2][XPOS + 2] == 3'b000) && (gameBoard[YPOS + 3][XPOS + 2] == 3'b000);//I2
				4'b0010: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000);//O
				4'b0010: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 2] == 3'b000);// S1
				4'b0100: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 1][XPOS + 2] == 3'b000 && gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000); //S2
				4'b0101: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 2][XPOS + 1] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000); //J1
				4'b0110: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 1][XPOS + 3] == 3'b000 && gameBoard[YPOS + 2][XPOS + 2] == 3'b000 && gameBoard[YPOS + 3][XPOS + 2] == 3'b000); //J2
				4'b0111: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000); //J3
				4'b1000: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 1][XPOS + 3] == 3'b000 && gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000); //J4
				4'b1001: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 2][XPOS + 2] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000); //T1
				4'b1010: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 1][XPOS + 2] == 3'b000 && gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 2] == 3'b000);//T2
				4'b1011: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 2] == 3'b000);//T3
				4'b1100: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 1][XPOS + 3] == 3'b000 && gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000); //T4
				4'b1101: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 2][XPOS + 2] == 3'b000 && gameBoard[YPOS + 3][XPOS + 3] == 3'b000);//Z1
				4'b1110: canMove <= (XPOS >= 0) && (XPOS < 12) && (gameBoard[YPOS + 1][XPOS + 3] == 3'b000 && gameBoard[YPOS + 2][XPOS + 3] == 3'b000 && gameBoard[YPOS + 3][XPOS + 2] == 3'b000);//Z2
			endcase
		
endmodule
