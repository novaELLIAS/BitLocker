/* Ellias Kiri Stuart */

module debouncer (
	input        clk,
	input  [2:0] keyin,
	output [2:0] keyout);
	
	//20ms timer
	reg cntFlag;
	reg [19:0] cnt;
	
	always@(posedge clk) begin
		if (cnt >= 20'd999_999) begin
			cnt <= 20'd0; cntFlag <= 1'b1; end
		else begin
			cnt <= cnt+1'b1; cntFlag <= 1'b0;
		end
	end
	
	//pre ex now
	reg [2:0] keyPre;
	reg [2:0] keyNow;
	
	initial begin
		keyPre = 1'b0;
		keyNow = 1'b0;
	end
	
	always@(posedge cntFlag) begin
		keyNow <= keyin;
	end
	
	always@(posedge clk) begin
		keyPre <= keyNow;
	end
	
	assign keyout = keyPre & (~keyNow);
	
endmodule

module LED_SEG_OUTPUT (
	input  [3:0] num1,
	input  [3:0] num2,
	output [8:0] ledSeg1,
	output [8:0] ledSeg2);
	
	reg [8:0] seg [9:0];
	
	initial begin
			seg[0] = 9'h3f;
	      seg[1] = 9'h06;
	      seg[2] = 9'h5b;
	      seg[3] = 9'h4f;
	      seg[4] = 9'h66;
	      seg[5] = 9'h6d;
	      seg[6] = 9'h7d;
	      seg[7] = 9'h07;
	      seg[8] = 9'h7f;
	      seg[9] = 9'h6f;
	end
	
	assign ledSeg1 = seg[num1];
	assign ledSeg2 = seg[num2];
	
endmodule

module BitLocker (
	input        	  clk,
	input      [0:0] keychk,
	input		  [0:0] keyrst,
	input 	  [0:0] keyset,
	input  	  [3:0] pwswt,
	// R, G, B
	output     [2:0] RGBLED1,
	output 	  [2:0] RGBLED2,
	output 	  [3:0] pwled,
	output 	  [8:0] ledSeg1,
	output 	  [8:0] ledSeg2,
	output 	 	  	  ledset,
	output reg       ledtest);
	
	wire   	  [2:0] keyMap;
	reg        [3:0] password;
	reg        [0:0] setsta;
	reg        [4:0] chances;
	reg        [0:0] opensta;
	
	initial begin
		ledtest  <= 1'b1;
		setsta   <= 1'b0;
		chances  <= 4'b0101;
		password <= 4'b0000;
		opensta  <= 1'b0;
	end
	
	assign pwled   = ~pwswt;
	assign ledset  = setsta == 1'b0;
	assign RGBLED2 = (chances > 4'b0)? 3'b101:3'b011;
	assign RGBLED1 = opensta? 3'b101:3'b011;

	// keychk, keyrst, keyset
	
	always@(posedge keyMap[1] or posedge keyMap[2]) begin
	
		if (keyMap[1])begin
			opensta <= 1'b0;
			chances <= 4'b0101;
		end
		
		else if (keyMap[2])
		if (chances > 4'b0000 && setsta == 1'b0) begin
			if (password ^ pwswt) begin
				opensta <= 1'b0;
				chances <= chances - 1'b1;
			end else begin
				opensta <= 1'b1;
				chances <= 4'b0101;
			end
		end
	end
	
	// keychk, keyrst, keyset
	
	always@(posedge keyMap[0]) begin
		if (opensta == 1'b1) begin
			if (setsta == 1'b0) setsta <= 1'b1;
			else begin
				setsta <= 1'b0; password <= pwswt;
			end
		end
	end
	
	LED_SEG_OUTPUT o1 (
		.num1 (chances/10),
		.num2 (chances%10),
		.ledSeg1 (ledSeg1),
		.ledSeg2 (ledSeg2));
		
	debouncer k1 (
		.clk (clk),
		.keyin ({keychk, keyrst, keyset}),
		.keyout (keyMap));
		
endmodule