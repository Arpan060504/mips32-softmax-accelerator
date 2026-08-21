module region_detector (
    input  wire [31:0] x,
    output reg  [2:0]  region
);

    reg [31:0] ordered_x;

    // ------------------------------------------------------------
    // Ordered representations of boundaries
    // ------------------------------------------------------------

    localparam [31:0] B_NEG4 = ~32'hC0800000;
    localparam [31:0] B_NEG3 = ~32'hC0400000;
    localparam [31:0] B_NEG2 = ~32'hC0000000;
    localparam [31:0] B_NEG1 = ~32'hBF800000;

    localparam [31:0] B_ZERO = 32'h80000000;
    localparam [31:0] B_POS1 = 32'hBF800000;
    localparam [31:0] B_POS2 = 32'hC0000000;
    localparam [31:0] B_POS3 = 32'hC0400000;
    localparam [31:0] B_POS4 = 32'hC0800000;


    // ------------------------------------------------------------
    // FP32 → sortable unsigned representation
    // ------------------------------------------------------------

    always @(*) begin

        if (x[31])
            ordered_x = ~x;
        else
            ordered_x = x ^ 32'h80000000;

    end


    // ------------------------------------------------------------
    // Region detection
    // ------------------------------------------------------------

    always @(*) begin

        if (ordered_x < B_NEG3)
            region = 3'd0;

        else if (ordered_x < B_NEG2)
            region = 3'd1;

        else if (ordered_x < B_NEG1)
            region = 3'd2;

        else if (ordered_x < B_ZERO)
            region = 3'd3;

        else if (ordered_x < B_POS1)
            region = 3'd4;

        else if (ordered_x < B_POS2)
            region = 3'd5;

        else if (ordered_x < B_POS3)
            region = 3'd6;

        else
            region = 3'd7;

    end

endmodule