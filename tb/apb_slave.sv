module apb_slave (
  input  logic        pclk,
  input  logic        rst_n,
  input  logic [31:0] paddr,
  input  logic        psel,
  input  logic        penable,
  input  logic        pwrite,
  input  logic [31:0] pwdata,
  output logic        pready,
  output logic [31:0] prdata
);

  logic [31:0] mem [0:255];
  logic [1:0]  apb_st;

  localparam logic [1:0] SETUP    = 2'd0;
  localparam logic [1:0] W_ENABLE = 2'd1;
  localparam logic [1:0] R_ENABLE = 2'd2;

  always @(posedge pclk or negedge rst_n) begin
    if (rst_n == 0) begin
      apb_st <= SETUP;
      prdata <= 0;
      pready <= 1;
      for (int i = 0; i < 256; i++) mem[i] <= i;
    end
    else begin
      case (apb_st)
        SETUP: begin
          prdata <= 0;
          if (psel && !penable) begin
            if (pwrite) begin
              apb_st <= W_ENABLE;
            end
            else begin
              apb_st <= R_ENABLE;
              prdata <= mem[paddr[7:0]];
            end
          end
        end
        W_ENABLE: begin
          if (psel && penable && pwrite) begin
            mem[paddr[7:0]] <= pwdata;
          end
          apb_st <= SETUP;
        end
        R_ENABLE: begin
          apb_st <= SETUP;
        end
        default: apb_st <= SETUP;
      endcase
    end
  end

endmodule : apb_slave