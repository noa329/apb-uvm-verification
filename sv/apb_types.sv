`ifndef APB_TYPES_SV
`define APB_TYPES_SV

// Transfer direction (PWRITE)
typedef enum bit {APB_READ = 1'b0, APB_WRITE = 1'b1} apb_direction_e;

// Role of the agent on the bus
typedef enum bit {APB_MASTER = 1'b0, APB_SLAVE = 1'b1} apb_role_e;

`endif // APB_TYPES_SV