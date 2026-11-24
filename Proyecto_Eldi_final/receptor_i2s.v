// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module receptor_i2s (
    input  wire        clk,
    input  wire [8:0]  cnt,
    input  wire        dout,
    output reg  [23:0] left  = 24'd0,
    output reg  [23:0] right = 24'd0,
    output reg         tick  = 1'b0
);
    reg        d1 = 1'b0, d2 = 1'b0;
    reg [23:0] sh = 24'd0;

    wire fase5   = (cnt[2:0] == 3'd5);
    wire bit_ok  = (cnt[7:3] >= 5'd1) && (cnt[7:3] <= 5'd24);
    wire en_sh   = fase5 & bit_ok;
    wire fin     = (cnt[7:0] == 8'd255);
    wire load_L  = fin & ~cnt[8];
    wire load_R  = fin &  cnt[8];

    always @(posedge clk) begin
        d1 <= dout;
        d2 <= d1;
        if (en_sh)  sh    <= {sh[22:0], d2};
        if (load_L) left  <= sh;
        if (load_R) right <= sh;
        tick <= load_R;
    end
endmodule
