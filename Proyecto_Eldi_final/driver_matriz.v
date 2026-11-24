// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module driver_matriz #(
    parameter REFRESH_BITS = 20
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [63:0] cols,
    input  wire [3:0]  bright,
    output reg         din,
    output reg         clk_o,
    output reg         cs_n
);
    localparam HALF = 4;
    localparam ST_IDLE = 3'd0, ST_LOAD = 3'd1, ST_LO = 3'd2, ST_HI = 3'd3, ST_END = 3'd4, ST_GAP = 3'd5;

    reg [2:0]  st;
    reg [REFRESH_BITS-1:0] rcnt;
    reg [3:0]  widx;
    reg [3:0]  div;
    reg [4:0]  bitn;
    reg [15:0] sh;
    reg [15:0] word;

    always @(*) begin
        case (widx)
            4'd0:  word = 16'h0900;
            4'd1:  word = {8'h0A, 4'h0, bright};
            4'd2:  word = 16'h0B07;
            4'd3:  word = 16'h0C01;
            4'd4:  word = 16'h0F00;
            4'd5:  word = {8'h01, cols[7:0]};
            4'd6:  word = {8'h02, cols[15:8]};
            4'd7:  word = {8'h03, cols[23:16]};
            4'd8:  word = {8'h04, cols[31:24]};
            4'd9:  word = {8'h05, cols[39:32]};
            4'd10: word = {8'h06, cols[47:40]};
            4'd11: word = {8'h07, cols[55:48]};
            default: word = {8'h08, cols[63:56]};
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= ST_IDLE; rcnt <= {REFRESH_BITS{1'b1}}; widx <= 4'd0; div <= 4'd0; bitn <= 5'd0; sh <= 16'd0;
            din <= 1'b0; clk_o <= 1'b0; cs_n <= 1'b1;
        end else begin
            case (st)
                ST_IDLE: begin
                    cs_n <= 1'b1; clk_o <= 1'b0;
                    rcnt <= rcnt + 1'b1;
                    if (&rcnt) begin widx <= 4'd0; st <= ST_LOAD; end
                end
                ST_LOAD: begin
                    sh <= word; din <= word[15]; cs_n <= 1'b0; bitn <= 5'd0; div <= 4'd0; st <= ST_LO;
                end
                ST_LO: begin
                    if (div == HALF - 1) begin div <= 4'd0; clk_o <= 1'b1; st <= ST_HI; end
                    else div <= div + 1'b1;
                end
                ST_HI: begin
                    if (div == HALF - 1) begin
                        div <= 4'd0; clk_o <= 1'b0;
                        if (bitn == 5'd15) st <= ST_END;
                        else begin
                            sh <= {sh[14:0], 1'b0}; din <= sh[14]; bitn <= bitn + 1'b1; st <= ST_LO;
                        end
                    end else div <= div + 1'b1;
                end
                ST_END: begin
                    if (div == HALF - 1) begin div <= 4'd0; cs_n <= 1'b1; st <= ST_GAP; end
                    else div <= div + 1'b1;
                end
                ST_GAP: begin
                    if (div == 2*HALF - 1) begin
                        div <= 4'd0;
                        if (widx == 4'd12) st <= ST_IDLE;
                        else begin widx <= widx + 1'b1; st <= ST_LOAD; end
                    end else div <= div + 1'b1;
                end
                default: st <= ST_IDLE;
            endcase
        end
    end
endmodule
