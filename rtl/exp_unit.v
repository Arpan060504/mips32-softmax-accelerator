module exp_unit (
    input  wire [31:0] x,
    output wire [31:0] exp_out
);

    // ------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------

    wire [2:0]  region;
    wire [31:0] a;
    wire [31:0] b;

    wire [31:0] ax;


    // ------------------------------------------------------------
    // 1. Region Detector
    //
    // Determines which piecewise-linear region contains x.
    //
    // region 0 : [-4,-3]
    // region 1 : [-3,-2]
    // region 2 : [-2,-1]
    // region 3 : [-1, 0]
    // region 4 : [ 0, 1]
    // region 5 : [ 1, 2]
    // region 6 : [ 2, 3]
    // region 7 : [ 3, 4]
    // ------------------------------------------------------------

    region_detector u_region_detector (.x(x), .region (region) );


    // ------------------------------------------------------------
    // 2. Exponential LUT
    //
    // Gives coefficients:
    //
    // exp(x) ≈ a*x + b
    // ------------------------------------------------------------

    exp_lut u_exp_lut (.region (region),.a(a),.b   (b));
    // 3. FP32 Multiplication
    //
    // ax = a * x
    fp32_multiplier u_fp32_multiplier (.a (a),.b (x),.result (ax));


    // ------------------------------------------------------------
    // 4. FP32 Addition
    //
    // exp(x) ≈ a*x + b
    // ------------------------------------------------------------

    fp32_adder u_fp32_adder (.a (ax),.b (b),.result (exp_out));
endmodule