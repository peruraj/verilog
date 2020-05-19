module wdt(pclk_i, prst_i, psel_i, penable_i, paddr_i, pwrite_i, pwdata_i, activity_i, pready_o, prdata_o, sysrst_o);

localparam WIDTH = 8;

localparam NO_ACTIVITY = 2'b00;
localparam ACTIVITY    = 2'b01;
localparam SYSRST      = 2'b10;

localparam TIMEOUT_REG_ADDR = 8'hA0;

input pclk_i, prst_i, psel_i, penable_i, pwrite_i,
input [WIDTH-1:0] paddr_i, pwdata_i; 
input activity_i;
output reg [WIDTH-1] prdata_o;
output reg pready_o,  sysrst_o;

reg [1:0] state,next_state;
reg [WIDTH-1:0] timeout_reg;
reg [WIDTH-1:0] time_count;

always @(posedge pclk_i)
begin
	if(prst_i)
	begin
		time_count  <= 0;
		pready_o    <= 0;
		sysrst_o    <= 0;
		timeout_reg <= 100;		//reset timeout value
		state       <= NO_ACTIVITY;
		next_state  <= NO_ACTIVITY;
	end
	else begin
		pready_o    <= (penable_i) ? 1: 0;
		timeout_reg <= ((penable_i) && (pwrite_i) && (paddr_i == TIMEOUT_REG_ADDR)) ? pwdata_i : timeout_reg;
		prdata_o    <= ((penable_i) && (pwrite_i == 0) && (paddr_i == TIMEOUT_REG_ADDR)) ? timeout_reg : prdata_o;
	end
end

//State Machine
always @(posedge pclk_i)
begin
	sysrst_o = 0;
	case (state) begin
	NO_ACTIVITY:		//There is no activity signal from the system
		if(activity_i) begin
			next_state <= ACTIVITY;
		end
		else begin
			time_count <= time_count + 1;
			next_state <= (time_count == timeout_reg) ? SYSRST : next_state;
		end

	ACTIVITY:		//activity signal from the system
		time_count <= 0;
		next_state <= (activity_i) ? ACTIVITY : NO_ACTIVITY;
		
	SYSRST:
		sysrst_o   <= 1;		//Issue Reset
		time_count <= 0;
		next_state <= NO_ACTIVITY;
	endcase
end


//Whenver the next_state changes, update state with next_state
always @(next_state)
begin
	state <= next_state;
end

endmodule
