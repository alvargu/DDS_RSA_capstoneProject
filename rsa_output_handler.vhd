library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity rsa_output_handler is
    generic(
        C_BLOCK_SIZE            :   integer := 256;
        C_STATUS_SIZE           :   integer := 32;
        C_CORE_ID_SIZE          :   integer := 4;
        C_CORE_CNT              :   integer := 15;
        C_CORE_REG_SIZE         :   integer := 60
    );

    port(
        -------------------------------------------
        -- INPUT CORE COMMS.                     --
        -------------------------------------------
        
        h_core_addr                 : in    std_logic_vector(C_CORE_ID_SIZE-1 downto 0);
        h_input_handler_ready       : in    std_logic;
        h_last_bit                  : in    std_logic;
        h_input_ready               : out   std_logic;
        -------------------------------------------
        -- CORE CTRL                             --
        -------------------------------------------
        
        c_core_ready                : in    std_logic_vector(C_CORE_CNT-1 downto 0);
        c_core_data                 : in    std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        c_core_enable               : out   std_logic_vector(C_CORE_CNT-1 downto 0);
        
        -------------------------------------------
        -- HANDLER OUTPUT                        --
        -------------------------------------------
        
        h_msgout_ready              : in    std_logic;
        h_msgout_data               : out   std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        h_msgout_last               : out   std_logic;
        h_msgout_valid              : out   std_logic;
        
        -------------------------------------------
        -- MISC.                                 --
        -------------------------------------------
        
        h_output_rsa_status         : out   std_logic_vector(C_STATUS_SIZE/2-1 downto 0);
        clk                         : in    std_logic;
        reset_n                     : in    std_logic
    );
end rsa_output_handler;

architecture rtl of rsa_output_handler is
    signal ir_recieve_register: std_logic_vector(4*C_CORE_CNT-1 downto 0);
    
    --For now limited to 4 cells, will expand, they should be put into the status register later on
    -- [0:3]    - Current Core to be read
    -- [4:5]    - Current State
    -- 6        - 
    -- 7        - Core Addr being added
    -- 8        - Data Ready To Sent
    -- 9        - 
    -- 10       - 
    -- 11       - Return to IDLE
    -- 12       - 
    -- 13       - 
    -- 14       - Last Bit sent
    -- 15       - FSM is on
    signal ir_output_ctrl : std_logic_vector(C_STATUS_SIZE/2-1 downto 0);
    
    signal temp_core_addr : std_logic_vector(C_CORE_ID_SIZE-1 downto 0);
    
    -- Setting up basic state machine.
    type state is (IDLE, DATA_WRITE, DATA_READ, DATA_SEND);
    signal c_state, nx_state: state;
begin

    h_output_rsa_status <= ir_output_ctrl;

    --This process handles updates of c_state and it is responsible for reseting the FSM
    State_Transfer: process(clk, reset_n)
    begin
        if(reset_n = '1') then
            --Reset current state to idle
            c_state <= IDLE;
            
            -- Reset Internal Registers
            ir_recieve_register <= (others => '0');
            ir_output_ctrl <= (others => '0');
        
        elsif rising_edge(clk) then
            --Move the FSM to next state
            c_state <= nx_state;
        end if;
    end process;
    
    --This process controls how the states are supposed to transfer between each other
    State_Logic: process(clk)
    begin
        --Since reset is being handled in State_Transfer
        --there is no need to update it here as well
        
        -- If none of the state transitions trigger, stay in the same state
        nx_state <= c_state;
        if rising_edge(clk) then        
            case c_state is
                -- Wait for one of the cores to finish processing data
                -- otherwise periodically check if the current core is done with data
                -- lastly check is the output is ready to recieve data
                
                -- If will be executed in order meaning that the priority of the states is listed bottom down
                when IDLE       =>  ir_output_ctrl(5 downto 4) <= "00";                                                     -- Update current State in status register
                
                                    if      (h_input_handler_ready = '1') then
                                        ir_output_ctrl(7) <= '1';
                                        nx_state <= DATA_WRITE;
                                        
                                    elsif   (
                                            to_integer(unsigned(ir_recieve_register(59 downto 56))) /= 0                    -- Check if the current core id is not 0
                                            and
                                            c_core_ready(to_integer(unsigned(ir_recieve_register(59 downto 56)))) = '1'     -- Check if the data is ready in the core
                                            ) then                                                                           
                                        nx_state <= DATA_READ;
                                        
                                    elsif   (h_msgout_ready = '1' and ir_output_ctrl(8) = '1') then
                                        nx_state <= DATA_SEND;
                                        
                                    end if;
                                    
                                    -- Separate If for controlling read from input ctrl
                                    if      (h_last_bit = '1') then
                                        ir_output_ctrl(14) <= '1';
                                    end if;
                
                -- Write to the shift register the ID of the core passed by input handler
                -- Controls the logic responsible for safekeeping of data aka not overwriting alread existing data
                when DATA_WRITE =>  ir_output_ctrl(5 downto 4) <= "01";                                                     -- Update current State in status register
                                    if (ir_output_ctrl(7) = '0') then                                                       -- Lock the system untill the core is done with writing
                                        nx_state <= IDLE;                                                                   -- Unlock the system and move back to IDLE
                                    end if;
                
                -- Check if data is avaible in the core if so read it and store it temporarly here
                -- if not return to IDLE state
                -- if it is go to data send and wait for transfer window
                when DATA_READ  =>  ir_output_ctrl(5 downto 4) <= "10";             -- Update current State in status register
                                    if (ir_output_ctrl(8) = '1') then               -- 
                                        nx_state <= DATA_SEND;
                                    elsif (ir_output_ctrl(11) = '1') then           -- SOMEHOW return to IDLE
                                        nx_state <= IDLE;
                                    end if;
                                    
                
                -- transfer the data
                -- lock the system untill data has been transfered
                when DATA_SEND  =>  ir_output_ctrl(5 downto 4) <= "11";             -- Update current State in status register
                                    if (ir_output_ctrl(8) = '0') then
                                        nx_state <= IDLE;
                                    elsif (ir_output_ctrl(11) = '1') then
                                        nx_state <= IDLE;
                                    end if;
                
                -- in case of error return to IDLE/Default State
                when others     => c_state <= IDLE;
            end case;  
        end if;
    end process;
    
    State_Code: process(c_state) --add inputs to the sensitivity list later on
    begin
        h_input_ready <= '0';
        case c_state is
            -- Do nothing
            when IDLE       => null;    
            
            -- Logic for data writing
            -- Check if the register is free
            when DATA_WRITE =>  if(to_integer(unsigned(ir_recieve_register(C_CORE_REG_SIZE-1 downto C_CORE_REG_SIZE-5))) = 0) then
                                    ir_recieve_register(C_CORE_REG_SIZE-1 downto 4) <= ir_recieve_register(C_CORE_REG_SIZE-5 downto 0);
                                    ir_recieve_register(3 downto 0) <= h_core_addr;
                                    h_input_ready <= '1';
                                -- If the register is not free return to idle
                                else null;
                                    
                                end if;
                                
            
            -- Logic for data reading
            when DATA_READ  => null;    
            
            -- Logic for data sending
            when DATA_SEND  => null;    
            
            -- Do nothing
            when others     => null;
        end case;
    end process;
end rtl;
