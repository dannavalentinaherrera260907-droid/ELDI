// Codigo generado con asistencia de IA (Claude, Anthropic) y revisado por el grupo. Ver "Uso de IA" en el README.

module Echospectrum #(
    parameter MAT_FLIP_X   = 0,
    parameter MAT_FLIP_Y   = 0,
    parameter DB_N         = 19,
    parameter REFRESH_BITS = 20
)(
    input  wire       clk,
    input  wire       btn_a_n,
    input  wire       btn_b_n,
    output wire [5:0] led_n,
    output wire       scki,
    output wire       bck,
    output wire       lrck,
    input  wire       dout,
    output wire       pwm_out,
    output wire       mat_din,
    output wire       mat_clk,
    output wire       mat_cs,
    output wire       mcp_cs_n,
    output wire       mcp_clk,
    output wire       mcp_din,
    input  wire       mcp_dout
);

    reg [15:0] por = 16'd0;
    wire rst_n = &por;
    always @(posedge clk) if (!rst_n) por <= por + 16'd1;

    wire [8:0] cnt;
    contador_maestro u_cnt (.clk(clk), .cnt(cnt), .scki(scki), .bck(bck), .lrck(lrck));

    wire [23:0] left, right;
    wire        tick;
    receptor_i2s u_rx (.clk(clk), .cnt(cnt), .dout(dout), .left(left), .right(right), .tick(tick));

    wire               mono_valid;
    wire signed [11:0] mono;
    mezcla u_mix (.clk(clk), .tick(tick), .left(left), .right(right), .mono_valid(mono_valid), .mono(mono));

    wire [9:0] pot_a, pot_b, pot_c, pot_d;
    lector_mcp3008 u_pots (.clk(clk), .rst_n(rst_n),
                         .cs_n(mcp_cs_n), .sclk(mcp_clk), .din(mcp_din), .dout(mcp_dout),
                         .pot0(pot_a), .pot1(pot_b), .pot2(pot_c), .pot3(pot_d), .new_sample());

    wire btn_a_pulse, btn_b_pulse;
    antirrebote #(.N(DB_N)) u_db_a (.clk(clk), .rst_n(rst_n), .btn_n(btn_a_n), .pressed(), .press_pulse(btn_a_pulse));
    antirrebote #(.N(DB_N)) u_db_b (.clk(clk), .rst_n(rst_n), .btn_n(btn_b_n), .pressed(), .press_pulse(btn_b_pulse));

    reg mode;
    reg page;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin mode <= 1'b1; page <= 1'b0; end
        else begin
            if (btn_a_pulse) mode <= ~mode;
            if (btn_b_pulse) page <= ~page;
        end
    end

    reg [9:0] p_delay, p_fb, p_mix, p_vol;
    reg [9:0] p_tone, p_drive, p_crush, p_bright;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_delay <= 10'd0;  p_fb <= 10'd0;   p_mix <= 10'd0;   p_vol <= 10'd1023;
            p_tone  <= 10'd1023; p_drive <= 10'd0; p_crush <= 10'd0; p_bright <= 10'd512;
        end else if (!page) begin
            p_delay <= pot_a;  p_fb <= pot_b;   p_mix <= pot_c;   p_vol <= pot_d;
        end else begin
            p_tone  <= pot_a;  p_drive <= pot_b; p_crush <= pot_c; p_bright <= pot_d;
        end
    end

    wire               d_valid;
    wire signed [11:0] d_x;
    distorsion u_drive (.clk(clk), .rst_n(rst_n), .in_valid(mono_valid), .x(mono), .sh(p_drive[9:8]),
                      .out_valid(d_valid), .y(d_x));

    wire               e_valid, e_clip;
    wire signed [11:0] e_y, e_dry;
    modulo_eco u_echo (.clk(clk), .rst_n(rst_n), .in_valid(d_valid), .x(d_x),
                        .delay_t({p_delay, 4'b0001}),
                        .k_fb(p_fb[9:7]), .k_mix(p_mix[9:7]),
                        .tone_s(2'd3 - p_tone[9:8]),
                        .out_valid(e_valid), .y(e_y), .dry(e_dry), .clip(e_clip));

    wire               o_valid;
    wire signed [11:0] o_y;
    modo_y_volumen u_post (.clk(clk), .rst_n(rst_n), .in_valid(e_valid), .mode(mode), .x_eco(e_y), .x_dry(e_dry),
                    .crush_n(p_crush[9:7]), .vol(p_vol[9:6]), .out_valid(o_valid), .y(o_y));

    salida_pwm u_pwm (.clk(clk), .in_valid(o_valid), .x(o_y), .cnt8(cnt[7:0]), .pwm(pwm_out));

    wire               fb_valid;
    wire signed [16:0] b0, b1, b2, b3;
    banco_filtros u_fb (.clk(clk), .rst_n(rst_n), .in_valid(mono_valid), .x(mono),
                     .out_valid(fb_valid), .b0(b0), .b1(b1), .b2(b2), .b3(b3));

    wire [3:0] lvl0, lvl1, lvl2, lvl3;
    envelope u_e0 (.clk(clk), .rst_n(rst_n), .in_valid(fb_valid), .b(b0), .level(lvl0));
    envelope u_e1 (.clk(clk), .rst_n(rst_n), .in_valid(fb_valid), .b(b1), .level(lvl1));
    envelope u_e2 (.clk(clk), .rst_n(rst_n), .in_valid(fb_valid), .b(b2), .level(lvl2));
    envelope u_e3 (.clk(clk), .rst_n(rst_n), .in_valid(fb_valid), .b(b3), .level(lvl3));

    wire [63:0] cols;
    barras_matriz #(.FLIP_X(MAT_FLIP_X), .FLIP_Y(MAT_FLIP_Y)) u_cols
        (.lvl0(lvl0), .lvl1(lvl1), .lvl2(lvl2), .lvl3(lvl3), .cols(cols));
    driver_matriz #(.REFRESH_BITS(REFRESH_BITS)) u_mat (.clk(clk), .rst_n(rst_n), .cols(cols), .bright(p_bright[9:6]),
                       .din(mat_din), .clk_o(mat_clk), .cs_n(mat_cs));

    reg [20:0] clip_cnt;
    reg [13:0] scnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin clip_cnt <= 21'd0; scnt <= 14'd0; end
        else begin
            if (e_valid && e_clip)       clip_cnt <= 21'h1FFFFF;
            else if (clip_cnt != 21'd0)  clip_cnt <= clip_cnt - 21'd1;
            if (mono_valid) scnt <= scnt + 14'd1;
        end
    end
    wire sig = |{lvl0, lvl1, lvl2, lvl3};

    assign led_n = ~{1'b0, sig, scnt[13], page, (clip_cnt != 21'd0), mode};
endmodule
