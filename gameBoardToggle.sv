module gameBoardToggle(Clock, Resetn, Enable, gameBoard, XCOOR, YCOOR, Erase);
	input Clock, Resetn, Enable, Erase;
	//input currentColor
	input [3:0] XCOOR;
	input [4:0] YCOOR;
	
	output reg [2:0] gameBoard[0:19][0:15];
	
	always@(posedge Clock)
			begin
				if(!Resetn)
					begin
					integer i;
					integer j;
						for(i = 0; i < 20; i = i + 1)
							for(j = 0; j < 16; j = j + 1)
								gameBoard[i][j] <= 3'b000;
					end
				else if(Enable)
					if(Erase)
						gameBoard[YCOOR][XCOOR] <= 3'b000;
					else gameBoard[YCOOR][XCOOR] <= 3'b001;
			end
			
endmodule


					
		
		
			