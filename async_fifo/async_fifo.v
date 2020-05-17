module async_fifo(wr_clk_i, rd_clk_i, rst_i, wr_en_i, wr_data_i, rd_en_i, rd_data_o, full_o, empty_o, error_o);

localparam WIDTH = 8;
localparam DEPTH = 32;
localparam PTR_WIDTH = 5; //2^5 = 32

input wr_clk_i, rd_clk_i, rst_i, wr_en_i, rd_en_i,
input [WIDTH-1:0] wr_data_i;
output reg empty_o,error_o,full_o;
output [WIDTH-1:0] rd_data_o;


reg wr_toggle_f, rd_toggle_f;
reg wr_toggle_f_rd_clk, rd_toggle_f_wr_clk;
reg [WIDTH-1:0] mem [DEPTH-1:0]; 

reg [PTR_WIDTH-1:0] wr_ptr; rd_ptr;
reg [PTR_WIDTH-1:0] wr_ptr_rd_clk; rd_ptr_wr_clk;

integer i;

always @(posedge wr_clk_i)
begin
	if(rst_i == 1) //asssumption that rst will happen wrt wr clk
	begin
		wr_ptr = 0;
		wr_ptr_rd_clk = 0;
		rd_ptr = 0;
		rd_ptr_wr_clk = 0;
		full_o = 0;
		empty_o = 1;
		wr_toggle_f = 0;
		rd_toggle_f = 0;
		wr_toggle_f_rd_clk = 0;
		rd_toggle_f_wr_clk = 0;
		for(i=0; i< DEPTH; i++)
		begin
			mem[i]=0;
		end
	end
	else
	begin
		error_o = 0;
		if(wr_en_i == 1)
		begin
			if(full_o == 1)
			begin
				error_o = 1;
			end
			else begin
				mem[wr_ptr] = wr_data;
				if(wr_ptr == DEPTH -1) begin
					wr_toggle_f = ~wr_toggle_f;
				end
				wr_ptr = wr_ptr + 1;
			end
		end	
	end

end

always @(posedge rd_clk_i)
begin
	if(rst_i == 0) //assumed that rst will happen wrt wr clk.
	begin
		error_o = 0;
		if(rd_en_i == 1)
		begin
			if(empty_o == 1)
			begin
				error_o = 1;
			end
			else begin
				rd_data = mem[rd_ptr];
				if(rd_ptr == DEPTH -1) begin
					rd_toggle_f = ~rd_toggle_f;
				end
				rd_ptr = wr_ptr + 1;
			end
		end	
	end

end

always @(posedge wr_clk)
begin
	rd_ptr_wr_clk <= rd_ptr;
	rd_toggle_f_wr_clk <= rd_toggle_f;
end

always @(posedge rd_clk)
begin
	wr_ptr_rd_clk <= wr_ptr;
	wr_toggle_f_rd_clk <= wr_toggle_f;
end


//check for Full Conditon
always @(*)
begin
	full_o =0;
	else if ((wr_ptr == rd_ptr_wr_clk) && (wr_toggle_f != rd_toggle_f_wr_clk))
	begin
		full_o = 1;
	end
end
//check for Empty Conditon
always @(*)
begin
	error_o=0;
	if ((wr_ptr_rd_clk == rd_ptr) && (wr_toggle_f_rd_clk == rd_toggle_f))
	begin
		empty_o = 1;
	end
end
endmodule
