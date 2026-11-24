// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module banco_filtros (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire signed [11:0] x,
    output reg                out_valid,
    output reg  signed [16:0] b0, b1, b2, b3
);
    reg signed [15:0] xd, lp1, lp2, lp3;
    reg signed [16:0] d1, d2, d3, e1, e2, e3;
    reg        [3:0]  v;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xd <= 16'sd0; lp1 <= 16'sd0; lp2 <= 16'sd0; lp3 <= 16'sd0;
            d1 <= 17'sd0; d2 <= 17'sd0; d3 <= 17'sd0; e1 <= 17'sd0; e2 <= 17'sd0; e3 <= 17'sd0;
            v <= 4'd0; out_valid <= 1'b0;
            b0 <= 17'sd0; b1 <= 17'sd0; b2 <= 17'sd0; b3 <= 17'sd0;
        end else begin
            v <= {v[2:0], in_valid};
            out_valid <= 1'b0;
            if (in_valid) xd <= {x, 4'b0000};
            if (v[0]) begin
                d1 <= xd - lp1;
                d2 <= xd - lp2;
                d3 <= xd - lp3;
            end
            if (v[1]) begin
                e1 <= d1 >>> 6;
                e2 <= d2 >>> 4;
                e3 <= d3 >>> 2;
            end
            if (v[2]) begin
                lp1 <= lp1 + e1;
                lp2 <= lp2 + e2;
                lp3 <= lp3 + e3;
            end
            if (v[3]) begin
                b0 <= lp1;
                b1 <= lp2 - lp1;
                b2 <= lp3 - lp2;
                b3 <= xd  - lp3;
                out_valid <= 1'b1;
            end
        end
    end
endmodule
