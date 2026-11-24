// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module modulo_eco (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire signed [11:0] x,
    input  wire        [13:0] delay_t,
    input  wire        [2:0]  k_fb,
    input  wire        [2:0]  k_mix,
    input  wire        [1:0]  tone_s,
    output reg                out_valid,
    output reg  signed [11:0] y,
    output reg  signed [11:0] dry,
    output reg                clip
);

    reg signed [11:0] mem [0:16383];
    integer i, j;
    initial begin
        for (j = 0; j < 16; j = j + 1)
            for (i = 0; i < 1024; i = i + 1)
                mem[j * 1024 + i] = 12'sd0;
    end

    reg  [13:0]        wr, ds, ra, wa;
    reg  signed [11:0] wd;
    reg                we;
    reg  signed [11:0] q;
    always @(posedge clk) begin
        if (we) mem[wa] <= wd;
        q <= mem[ra];
    end

    reg  [7:0]         p;
    reg  signed [11:0] x_r, lp, df;
    reg  signed [12:0] diffr;
    reg  signed [11:0] a2, a1, a0, m2, m1, m0, sfb, smix;
    reg  signed [12:0] w13, o13;
    reg  signed [11:0] w_s, o_s;
    reg                clip_f;

    function signed [11:0] clamp;
        input signed [12:0] v;
        begin
            if (v > 13'sd2047)        clamp = 12'sh7FF;
            else if (v < -13'sd2048)  clamp = 12'sh800;
            else                      clamp = v[11:0];
        end
    endfunction

    function over;
        input signed [12:0] v;
        begin
            over = (v > 13'sd2047) || (v < -13'sd2048);
        end
    endfunction

    wire signed [12:0] lp_next = lp + (diffr >>> tone_s);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr <= 14'd0; ds <= 14'd1; ra <= 14'd0; wa <= 14'd0; wd <= 12'sd0; we <= 1'b0;
            p <= 8'd0; x_r <= 12'sd0; lp <= 12'sd0; df <= 12'sd0; diffr <= 13'sd0;
            a2 <= 12'sd0; a1 <= 12'sd0; a0 <= 12'sd0; m2 <= 12'sd0; m1 <= 12'sd0; m0 <= 12'sd0;
            sfb <= 12'sd0; smix <= 12'sd0; w13 <= 13'sd0; o13 <= 13'sd0; w_s <= 12'sd0; o_s <= 12'sd0;
            clip_f <= 1'b0; out_valid <= 1'b0; y <= 12'sd0; dry <= 12'sd0; clip <= 1'b0;
        end else begin
            p         <= {p[6:0], in_valid};
            we        <= 1'b0;
            out_valid <= 1'b0;

            if (in_valid) begin
                x_r <= x;
                ra  <= wr - ds;
                if (ds < delay_t)      ds <= ds + 14'd1;
                else if (ds > delay_t) ds <= ds - 14'd1;
            end
            if (p[1]) begin
                diffr <= q - lp;
            end
            if (p[2]) begin
                lp <= lp_next[11:0];
                df <= lp_next[11:0];
            end
            if (p[3]) begin
                a2 <= k_fb[2]  ? (df >>> 1) : 12'sd0;
                a1 <= k_fb[1]  ? (df >>> 2) : 12'sd0;
                a0 <= k_fb[0]  ? (df >>> 3) : 12'sd0;
                m2 <= k_mix[2] ? (df >>> 1) : 12'sd0;
                m1 <= k_mix[1] ? (df >>> 2) : 12'sd0;
                m0 <= k_mix[0] ? (df >>> 3) : 12'sd0;
            end
            if (p[4]) begin
                sfb  <= a2 + a1 + a0;
                smix <= m2 + m1 + m0;
            end
            if (p[5]) begin
                w13 <= x_r + sfb;
                o13 <= x_r + smix;
            end
            if (p[6]) begin
                w_s    <= clamp(w13);
                o_s    <= clamp(o13);
                clip_f <= over(w13) | over(o13);
            end
            if (p[7]) begin
                wd <= w_s; wa <= wr; we <= 1'b1;
                wr <= wr + 14'd1;
                y   <= o_s; dry <= x_r; clip <= clip_f;
                out_valid <= 1'b1;
            end
        end
    end
endmodule
