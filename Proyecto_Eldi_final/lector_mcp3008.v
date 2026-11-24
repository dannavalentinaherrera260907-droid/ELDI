// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module lector_mcp3008 (
    input  wire       clk,
    input  wire       rst_n,
    output reg        cs_n,
    output reg        sclk,
    output wire       din,
    input  wire       dout,
    output reg  [9:0] pot0, pot1, pot2, pot3,
    output reg        new_sample
);
    localparam HALF = 16;
    localparam GAP  = 32;
    localparam S_GAP = 2'd0, S_SETUP = 2'd1, S_LOW = 2'd2, S_HIGH = 2'd3;

    reg [1:0]  state;
    reg [1:0]  ch;
    reg [23:0] tx, rx;
    reg [4:0]  bitn;
    reg [5:0]  div;

    assign din = tx[23];

    wire [9:0]  raw = rx[9:0];
    reg  [9:0]  cur;
    always @(*) begin
        case (ch)
            2'd0:    cur = pot0;
            2'd1:    cur = pot1;
            2'd2:    cur = pot2;
            default: cur = pot3;
        endcase
    end
    wire [10:0] diff = {1'b0, raw} - {1'b0, cur};
    wire [10:0] ad   = diff[10] ? (11'd0 - diff) : diff;
    wire        upd  = (ad >= 11'd2);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_GAP; cs_n <= 1'b1; sclk <= 1'b0; div <= 6'd0;
            ch <= 2'd0; bitn <= 5'd0; tx <= 24'd0; rx <= 24'd0;
            pot0 <= 10'd0; pot1 <= 10'd0; pot2 <= 10'd0; pot3 <= 10'd0;
            new_sample <= 1'b0;
        end else begin
            new_sample <= 1'b0;
            case (state)
                S_GAP: begin
                    cs_n <= 1'b1; sclk <= 1'b0;
                    if (div == GAP - 1) begin
                        div   <= 6'd0;
                        tx    <= {8'h01, 1'b1, 1'b0, ch, 4'b0000, 8'h00};
                        bitn  <= 5'd0;
                        cs_n  <= 1'b0;
                        state <= S_SETUP;
                    end else div <= div + 6'd1;
                end
                S_SETUP: begin
                    if (div == HALF - 1) begin div <= 6'd0; state <= S_LOW; end
                    else div <= div + 6'd1;
                end
                S_LOW: begin
                    if (div == HALF - 1) begin
                        div   <= 6'd0;
                        sclk  <= 1'b1;
                        rx    <= {rx[22:0], dout};
                        state <= S_HIGH;
                    end else div <= div + 6'd1;
                end
                S_HIGH: begin
                    if (div == HALF - 1) begin
                        div  <= 6'd0;
                        sclk <= 1'b0;
                        if (bitn == 5'd23) begin
                            if (upd) begin
                                case (ch)
                                    2'd0:    pot0 <= raw;
                                    2'd1:    pot1 <= raw;
                                    2'd2:    pot2 <= raw;
                                    default: pot3 <= raw;
                                endcase
                            end
                            ch         <= ch + 2'd1;
                            cs_n       <= 1'b1;
                            new_sample <= 1'b1;
                            state      <= S_GAP;
                        end else begin
                            tx    <= {tx[22:0], 1'b0};
                            bitn  <= bitn + 5'd1;
                            state <= S_LOW;
                        end
                    end else div <= div + 6'd1;
                end
            endcase
        end
    end
endmodule
