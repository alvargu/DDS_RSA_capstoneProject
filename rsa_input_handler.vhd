library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--#############################################################################
-- Entity I/O Definition
--#############################################################################
entity rsa_input_handler is
     generic(
          -- #############################################################################
		-- This line might be necessary (if so uncomment il_msgout_data and msgin_data_register)
		--C_BLOCK_SIZE : integer := 256;
		-- #############################################################################
		-- Not using status register ATM
          --C_STATUS_SIZE : integer := 32;
          C_CORE_CNT : integer := 15
     );
     port(
        	-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- 
		msgin_last			: in std_logic;
		-- #############################################################################
		-- This line might be necessary (if so uncomment il_msgout_data and msgin_data_register)
		-- Message that will be sent out of the rsa_msgin module
		--msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- #############################################################################

		-----------------------------------------------------------------------------
		-- Core interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid 
		il_core_start           	: 	out std_logic_vector(C_CORE_CNT-1 downto 0); -- valid_in
		-- Slave ready to accept a new message
		il_core_busy           	:  	in std_logic_vector(C_CORE_CNT-1 downto 0); -- ready_in
		--
		h_core_last_msg		:	out std_logic_vector(C_CORE_CNT-1 downto 0)
		-- Message that will be sent out of the rsa_msgin module
		--il_msgout_data           : out std_logic_vector(C_BLOCK_SIZE-1 downto 0) -- message

		-----------------------------------------------------------------------------
		-- Interface to the status register block
		-----------------------------------------------------------------------------
          -- status register for input handler (if commented out it is not used) 
		-- Description...
		--input_handler_rsa_status : out std_logic_vector((C_status_size/2)-1 downto 0)
     );
end entity;

-- Functional code (not tested) (without com to out handler)
-- ######################################
architecture rtl of rsa_input_handler is
    	--########################################################################
    	-- Internal signal declaration
    	--########################################################################
	-- Signals for internal core logic:
	-- #############################################################################
	-- This line might be necessary (if so uncomment il_msgout_data and msgin_data_register)
	--signal msgin_data_register : std_logic_vector(C_BLOCK_SIZE-1 downto 0) := (others => '0');
	-- #############################################################################

	-- Initialization of state machine for input handler
	type state is (IDLE, CORE_RDY, LOAD_CORE);
	signal fsm_state : state;

--#############################################################################
-- Begin architecture
--#############################################################################
begin

--#############################################################################
-- State machine for core handling states
--#############################################################################
sm_core_handler : process 	(clk,
						reset_n,
						fsm_state,
						msgin_valid,
						il_core_busy,
						msgin_last)
	variable addr : integer range 0 to C_CORE_CNT-1 := 0;
	variable msgin_last_reg : std_logic := '0';
begin
     if (reset_n = '0') then
        	fsm_state <= IDLE;
		addr := 0;
		msgin_ready <= '0';
		il_core_start <= (others => '0');
    	else
		if (clk'event and clk = '1') then
			-- Set default values
			fsm_state <= fsm_state;
			addr := addr;
			msgin_ready <= '0';
			il_core_start <= (others => '0');
			h_core_last_msg(addr) <= msgin_last_reg;
			case (fsm_state) is
				--###################################################################
				when IDLE =>
					-- Wait for current core to be done
     		          if (il_core_busy(addr) = '0') then
						-- 
					    	fsm_state <= CORE_RDY;
     		          end if;
     		     --###################################################################
				when CORE_RDY =>
					-- 
					msgin_ready <= '1';
     		          if (msgin_valid = '1') then
						msgin_last_reg := msgin_last;
     		              	fsm_state <= LOAD_CORE;
						il_core_start(addr) <= '1';
						-- msgin_data_register <= msgin_data;
     		          end if;
				--###################################################################
				when LOAD_CORE =>
					-- If address within amount of cores check if current core is done loading in data
					if (il_core_busy(addr) = '1') then
     		             	-- Go to IDLE state next and increase
					    	fsm_state <= IDLE;
						-- Check if address has reached last core and loop back to start if true
					    	if (addr >= C_CORE_CNT-1) then
							addr := 0; -- Reset address to zero
					    	else
							addr := addr + 1; -- go to next core address
					    	end if;
					else
						il_core_start(addr) <= '1';
     		          end if;
				--###################################################################
				when others =>
     		          fsm_state <= IDLE;
     		end case;
		end if;
	end if;
end process;
end architecture;
