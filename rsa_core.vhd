library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rsa_core is
     generic(
        -- Sizes of: Data packet, status register and count of cores
        C_BLOCK_SIZE            : integer := 256;
        C_STATUS_SIZE           : integer := 32;
        C_CORE_CNT              : integer := 12
     );
     port(
		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- msgin_valid          - Message that will be sent out is valid
		-- msgin_ready          - Slave ready to accept a new message
		-- msgin_data           - Message that will be sent out of the rsa_msgin module
		-- msgin_last           - Indicates boundary of last packet
		
		msgin_valid             :   in  std_logic;
		msgin_ready             :   out std_logic;
		msgin_data              :   in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		msgin_last              :   in  std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- msgout_valid         - Message that will be sent out is valid
		-- msgout_ready         - Slave ready to accept a new message
		-- msgout_data          - Message that will be sent out of the rsa_msgin module
		-- msgout_last          - Indicates boundary of last packet
		
		msgout_valid            :   out std_logic;
		msgout_ready            :   in  std_logic;
		msgout_data             :   out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		msgout_last             :   out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		-- key_e_d              - Decription/encription Key for the RSA
		-- key_n                - Modulus Key for the RSA
		-- rsa_status           - Status register of the RSA core
		
		key_e_d                 :   in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :   in  std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              :   out std_logic_vector(31 downto 0);
     
        -----------------------------------------------------------------------------
		-- Misc.
		-----------------------------------------------------------------------------
		-- clk                  - Clock signal of the system
		-- reset_n              - Reset of the system, active low
		
		clk                     :   in  std_logic;
		reset_n                 :   in  std_logic
     );
end entity;

architecture rtl of rsa_core is

    -- il - Internal line
    -- Used to transfer and connect register with the cores
    signal il_core_busy         : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_done         : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_start        : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_last_msg     : std_logic_vector(C_CORE_CNT-1     downto 0);
    signal il_core_reset        : std_logic_vector(C_CORE_CNT-1     downto 0);
    
    
    -- Definitions of both (O)utput and (I)nput processing FSM
    type O_FSM is (READ_CORE,
                   SEND_DATA);
    
    type I_FSM is (IDLE, 
                   CORE_RDY,
                   LOAD_CORE);
    
    -- Signals created for the FSM
    -- Both have a current and next state
    signal output_c_state, 
           nx_output_state      : O_FSM;
           
    signal input_c_state,
           nx_input_state       : I_FSM;
    
    --Signals Created in order to select/point to different cores
    -- Allow the sending of data to/from cores without the need for complicated implementation
    signal output_cursor, 
           nx_cursor            : integer range 0 to C_CORE_CNT-1;
    
    signal input_cursor,  
           nx_i_cursor          : integer range 0 to C_CORE_CNT-1;
    
    -- Technically a large OR gate, uses one of the cursors to decide which data to get from with core
    type core_handler is array (C_CORE_CNT-1 downto 0) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal core_out : core_handler;
begin

    CORE_GENERATE: for core_nr in 0 to C_CORE_CNT-1 generate
        EXPONENTIATION: entity work.exponentiation
            generic map (
                C_BLOCK_SIZE            => C_BLOCK_SIZE
            )
            port map (
                --
                message                 => msgin_data,
                key                     => key_e_d,
                modulus                 => key_n,
                
                --
                c_core_start            => il_core_start(core_nr),
                c_core_reset            => il_core_reset(core_nr),
                c_core_done             => il_core_done(core_nr),
                c_core_is_busy          => il_core_busy(core_nr),
                
                --
                result                  => core_out(core_nr),
                
                -- Misc.
                clk                     => clk,
                reset_n                 => reset_n
            );
    end generate;

    -----------------------------------------------------------------------------
    -- msgout_x Control
	-----------------------------------------------------------------------------

    FSM_OUTPUT_CLK: process(clk, reset_n)
    begin
        if reset_n = '0' then
            output_c_state     <= READ_CORE;
            output_cursor      <= 0;
        elsif rising_edge(clk) then
            output_c_state     <= nx_output_state;
            output_cursor      <= nx_cursor;
        end if;
    end process;
    
    FSM_OUTPUT_LOGIC: process(all)
    begin
        --Default Values for those signals
        msgout_valid           <= '0';
        msgout_last            <= '0';
        msgout_data            <= (others => '0');
        il_core_reset          <= (others => '0');
        
        -- If the nx was not updated with the case keep old value
        nx_output_state        <= output_c_state;
        nx_cursor              <= output_cursor;
    
        -- Logic for each of the states in the FSM
        case output_c_state is
            when READ_CORE     =>   if(il_core_done(output_cursor)) then
                                        nx_output_state <= SEND_DATA;
                                    end if;
            
            when SEND_DATA     =>   if(msgout_ready = '1') then
                                        -- Get output data from the core
                                        msgout_data     <= core_out(output_cursor);
                                        msgout_last     <= il_core_last_msg(output_cursor);
                                        msgout_valid    <= '1'; 
            
                                        -- Handle the cursor
                                        if(output_cursor >= (C_CORE_CNT-1)) then
                                            nx_cursor   <= 0;
                                        else
                                            nx_cursor   <= output_cursor + 1;
                                        end if;
                                
                                        -- Reset the Core
                                        il_core_reset(output_cursor) <= '1'; 
                                    
                                        -- Move to default state
                                        nx_output_state <= READ_CORE;
                                    end if;
                                
            when OTHERS        =>   nx_output_state     <= READ_CORE;
        end case;
    end process;

    -----------------------------------------------------------------------------
    -- msgin_x Control
	-----------------------------------------------------------------------------

    --TODO: Fix names on states so they make sense
    --TODO: Comment rest of code

    INPUT_STATE: process(clk, reset_n)
    begin
        if reset_n = '0' then
            input_c_state   <= IDLE;
            input_cursor    <= 0;
        elsif rising_edge(clk) then
            input_cursor    <= nx_i_cursor;
            input_c_state   <= nx_input_state;
        end if;
    end process;


    INPUT_LOGIC: process(all)
    begin
        nx_input_state      <= input_c_state;
        msgin_ready         <= '0';
        il_core_start       <= (others => '0');
        
        
        case input_c_state is
            when IDLE       =>  if (msgin_valid = '1') then
                                    nx_input_state  <= CORE_RDY;
                                end if;
                                
            
            when CORE_RDY   =>  if (il_core_busy(input_cursor) = '0') then
                                    il_core_start(input_cursor) <= '1';
                                end if;
                                
                                il_core_last_msg(input_cursor) <= msgin_last;
                                
                                nx_input_state      <= LOAD_CORE;
                                
                                --Deal with core cursor
                                if(input_cursor >= (C_CORE_CNT-1)) then
                                    nx_i_cursor     <= 0;
                                else
                                    nx_i_cursor     <= input_cursor + 1;
                                end if;
            
            when LOAD_CORE  =>  if(il_core_busy(input_cursor) = '0') then
                                    msgin_ready     <= '1';
                                    nx_input_state  <= IDLE;
                                end if;
                                
            when OTHERS     =>  nx_input_state      <= IDLE;
        end case;
    end process;
end;
