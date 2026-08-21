module exp_lut (
    input  wire [2:0]  region,
    output reg  [31:0] a,
    output reg  [31:0] b
);

    // ------------------------------------------------------------
    // Piecewise-linear approximation
    //
    // exp(x) ≈ a*x + b
    //
    // region 0 : [-4, -3]
    // region 1 : [-3, -2]
    // region 2 : [-2, -1]
    // region 3 : [-1,  0]
    // region 4 : [ 0,  1]
    // region 5 : [ 1,  2]
    // region 6 : [ 2,  3]
    // region 7 : [ 3,  4]
    //
    // a and b are IEEE-754 single-precision values.
    // ------------------------------------------------------------

    always @(*) begin

        case (region)

            3'd0: begin
                a = 32'h3D00E830;
                b = 32'h3E13A985;
            end

            3'd1: begin
                a = 32'h3DAF33E7;
                b = 32'h3E9CE49E;
            end

            3'd2: begin
                a = 32'h3E6E200E;
                b = 32'h3F19B55C;
            end

            3'd3: begin
                a = 32'h3F21D2A7;
                b = 32'h3F800000;
            end

            3'd4: begin
                a = 32'h3FDBF0A9;
                b = 32'h3F800000;
            end

            3'd5: begin
                a = 32'h409576FC;
                b = 32'hBFF9EB46;
            end

            3'd6: begin
                a = 32'h414B24C9;
                b = 32'hC1900800;
            end

            3'd7: begin
                a = 32'h420A0CEA;
                b = 32'hC2A6E794;
            end

            // Invalid region
            default: begin
                a = 32'h00000000;
                b = 32'h00000000;
            end

        endcase

    end

endmodule