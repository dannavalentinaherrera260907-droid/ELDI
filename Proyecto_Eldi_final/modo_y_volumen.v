// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module modo_y_volumen (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire               mode,
    input  wire signed [11:0] x_eco,
    input  wire signed [11:0] x_dry,
    input  wire        [2:0]  crush_n,
    input  wire        [3:0]  vol,
    output reg                out_valid,
    output reg  signed [11:0] y
);
    wire signed [11:0] x = mode ? x_eco : x_dry;
    wire        [11:0] mask = 12'hFFF << crush_n;
    reg  signed [11:0] c, t3, t2, t1, t0, u1, u0;
    reg         [2:0]  v;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0; y <= 12'sd0; c <= 12'sd0;
            t3 <= 12'sd0; t2 <= 12'sd0; t1 <= 12'sd0; t0 <= 12'sd0; u1 <= 12'sd0; u0 <= 12'sd0; v <= 3'd0;
        end else begin
            v <= {v[1:0], in_valid};
            out_valid <= 1'b0;
            if (in_valid) c <= x & mask;
            if (v[0]) begin
                t3 <= vol[3] ? (c >>> 1) : 12'sd0;
                t2 <= vol[2] ? (c >>> 2) : 12'sd0;
                t1 <= vol[1] ? (c >>> 3) : 12'sd0;
                t0 <= vol[0] ? (c >>> 4) : 12'sd0;
            end
            if (v[1]) begin
                u1 <= t3 + t2;
                u0 <= t1 + t0;
            end
            if (v[2]) begin
                y <= u1 + u0;
                out_valid <= 1'b1;
            end
        end
    end
endmodule
