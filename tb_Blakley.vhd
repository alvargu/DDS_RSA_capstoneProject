library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_Blakley is
end tb_Blakley;

architecture Behavioral of tb_Blakley is

component Blakley
    port ( clk : in std_logic;
           rst : in std_logic;
           start : in std_logic;
           a : in std_logic_vector(7 downto 0);
           b : in std_logic_vector(7 downto 0);
           n : in std_logic_vector(7 downto 0);
           R : out std_logic_vector(7 downto 0);
           done : out std_logic);
end component;

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal start : std_logic := '0';
signal a, b, n : std_logic_vector(7 downto 0);   
signal R : std_logic_vector(7 downto 0);        
signal done : std_logic;
begin
clk <= not clk after 30 ns;
a <= "10000111";
b <= "10100101";
n <= "10101100";

UUT : Blakley port map ( clk => clk,
                         start => start,
                         rst => rst,
                         a => a,
                         b => b,
                         n => n,
                         R => R,
                         done => done);

process
begin
    wait for 45 ns;
    start <= '1';
    wait for 60 ns;
    start <= '0';
    wait;
end process;
end Behavioral;
