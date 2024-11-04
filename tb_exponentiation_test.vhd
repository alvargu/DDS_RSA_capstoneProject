library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_exponentiation_test is
end tb_exponentiation_test;

architecture Behavioral of tb_exponentiation_test is

component exponentiation_test
    port ( clk : in std_logic;
           rst : in std_logic;
           start : in std_logic;
           msgin_data : in std_logic_vector(7 downto 0);
           key_e : in std_logic_vector(7 downto 0);
           key_n : in std_logic_vector(7 downto 0);
           msgout_data : out std_logic_vector(7 downto 0));
end component;

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal start : std_logic := '0';
signal msgin_data, key_e, key_n : std_logic_vector(7 downto 0);   
signal msgout_data : std_logic_vector(7 downto 0);        
begin
clk <= not clk after 30 ns;
msgin_data <= "01010100";
key_e <= "00101101";
key_n <= "10001101";

UUT : exponentiation_test port map ( clk => clk,
                     rst => rst,
                     start => start,
                     msgin_data => msgin_data,
                     key_e => key_e,
                     key_n => key_n,
                     msgout_data => msgout_data);

process
begin
    wait for 45ns;
    start <= '1';
    wait for 60ns;
    start <= '0';
    wait;
end process;
end Behavioral;
