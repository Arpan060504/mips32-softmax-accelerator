module exp_lut (
    input  wire [3:0]  region,
    output reg  [31:0] a,
    output reg  [31:0] b
);

    // ------------------------------------------------------------
    // Piecewise Linear Approximation
    //
    //          exp(x) ≈ a*x + b
    //
    // 16 regions, each 0.5 wide
    //
    // Region 0  : [-4.0, -3.5)
    // Region 1  : [-3.5, -3.0)
    // Region 2  : [-3.0, -2.5)
    // Region 3  : [-2.5, -2.0)
    // Region 4  : [-2.0, -1.5)
    // Region 5  : [-1.5, -1.0)
    // Region 6  : [-1.0, -0.5)
    // Region 7  : [-0.5,  0.0)
    // Region 8  : [ 0.0,  0.5)
    // Region 9  : [ 0.5,  1.0)
    // Region 10 : [ 1.0,  1.5)
    // Region 11 : [ 1.5,  2.0)
    // Region 12 : [ 2.0,  2.5)
    // Region 13 : [ 2.5,  3.0)
    // Region 14 : [ 3.0,  3.5)
    // Region 15 : [ 3.5,  4.0]
    //
    // a and b are IEEE-754 single precision (FP32).
    // ------------------------------------------------------------

    always @(*) begin

        case (region)

            // ----------------------------------------------------
            // Negative regions
            // ----------------------------------------------------

            4'd0: begin
                a = 32'h3CC2ABA6;
                b = 32'h3DE82E51;
            end

            4'd1: begin
                a = 32'h3D207A8C;
                b = 32'h3E2B574B;
            end

            4'd2: begin
                a = 32'h3D844AD6;
                b = 32'h3E796BA2;
            end

            4'd3: begin
                a = 32'h3DDA1CF8;
                b = 32'h3EB25927;
            end

            4'd4: begin
                a = 32'h3E33CDCD;
                b = 32'h3EF91877;
            end

            4'd5: begin
                a = 32'h3E943928;
                b = 32'h3F2849ED;
            end

            4'd6: begin
                a = 32'h3EF460FC;
                b = 32'h3F585DD7;
            end

            4'd7: begin
                a = 32'h3F4974D0;
                b = 32'h3F800000;
            end


            // ----------------------------------------------------
            // Positive regions
            // ----------------------------------------------------

            4'd8: begin
                a = 32'h3FA61299;
                b = 32'h3F800000;
            end

            4'd9: begin
                a = 32'h4008E75C;
                b = 32'h3F1443E0;
            end

            4'd10: begin
                a = 32'h4061B754;
                b = 32'hBF4EFBFF;
            end

            4'd11: begin
                a = 32'h40BA124D;
                b = 32'hC087B175;
            end

            4'd12: begin
                a = 32'h411963D8;
                b = 32'hC13C8E1D;
            end

            4'd13: begin
                a = 32'h417CE5BA;
                b = 32'hC1DAA96A;
            end

            4'd14: begin
                a = 32'h41D07A88;
                b = 32'hC2686035;
            end

            4'd15: begin
                a = 32'h422BDC91;
                b = 32'hC2EA86E1;
            end


            // ----------------------------------------------------
            // Safety default
            // ----------------------------------------------------

            default: begin
                a = 32'h00000000;
                b = 32'h00000000;
            end

        endcase

    end

endmodule