-- Hannah Soria
-- CS232 fall 22
-- project07
-- cpu

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is 

port
(
    clk   : in  std_logic;                       -- main clock
    reset : in  std_logic;                       -- reset button

    PCview : out std_logic_vector( 7 downto 0);  -- debugging outputs
    IRview : out std_logic_vector(15 downto 0);
    RAview : out std_logic_vector(15 downto 0);
    RBview : out std_logic_vector(15 downto 0);
    RCview : out std_logic_vector(15 downto 0);
    RDview : out std_logic_vector(15 downto 0);
    REview : out std_logic_vector(15 downto 0);

    iport : in  std_logic_vector(7 downto 0);    -- input port
    oport : out std_logic_vector(15 downto 0)    -- output port
	 ); 
	 
end entity;

architecture rtl of cpu is 

	component DataRAM
		PORT
	(
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;

	component ProgramROM
		PORT
	(
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;

	component alu
		PORT
	(
	 srcA : in  unsigned(15 downto 0);         -- input A
    srcB : in  unsigned(15 downto 0);         -- input B
    op   : in  std_logic_vector(2 downto 0);  -- operation
    cr   : out std_logic_vector(3 downto 0);  -- condition outputs
    dest : out unsigned(15 downto 0)        -- output value
	);
END component;


	signal state: std_LOGIC_VECTOR(3 downto 0);
	signal count: std_LOGIC_VECTOR(2 downto 0); -- sets states
	signal ROM_output: std_LOGIC_VECTOR(15 downto 0);
	signal dest: std_LOGIC_VECTOR(15 downto 0); -- from the ALU
	signal SRCA: std_LOGIC_VECTOR(15 downto 0); -- into the ALU
	signal SRCB: std_LOGIC_VECTOR(15 downto 0); -- into the ALU
	signal op: std_LOGIC_VECTOR(2 downto 0);
	signal RA: std_LOGIC_VECTOR(15 downto 0); -- register A
	signal RB: std_LOGIC_VECTOR(15 downto 0); -- register B
	signal RC: std_LOGIC_VECTOR(15 downto 0); -- register C
	signal RD: std_LOGIC_VECTOR(15 downto 0); -- register D
	signal RE: std_LOGIC_VECTOR(15 downto 0); -- register E
	signal SP: unsigned(15 downto 0); --stack pointer
	signal IR: std_LOGIC_VECTOR(15 downto 0); -- instruction register
	signal PC: std_LOGIC_VECTOR(7 downto 0); -- program counter
	signal CR: std_LOGIC_VECTOR(3 downto 0); -- condition register, coming from ALU and others
	signal aluCR: std_LOGIC_VECTOR(3 downto 0); -- only for ALU
	signal RAM_we: std_LOGIC; -- write in RAM
	signal RAM_output: std_LOGIC_VECTOR(15 downto 0); -- output RAM
	signal MAR: std_LOGIC_VECTOR(7 downto 0); -- mem address register goes to RAM
	signal MBR: std_LOGIC_VECTOR(15 downto 0); --to the RAM
	signal input_port: std_LOGIC_VECTOR(7 downto 0);
	signal OUTREG: std_LOGIC_VECTOR(15 downto 0);-- stores popped item from stack at RAM

	begin
	
	DataRAM1: DataRAM
	port map (address => MAR, clock => clk, data => MBR, wren => RAM_we, q => RAM_output);
	
	ProgramRom1: ProgramRom
	port map (address => PC, clock => clk, q => ROM_output);
	
	alu1: alu
	port map (srcA => unsigned(SRCA), srcB=> unsigned(SRCB), op => op, cr => aluCR, std_LOGIC_VECTOR(dest) => dest);
	
	
    PCview <= PC;
    IRview <= IR;
    RAview <= RA;
    RBview <= RB;
    RCview <= RC;
    RDview <= RD;
    REview <= RE;
    oport <= OUTREG;
	
	process (clk, reset)
	begin
		if reset = '0' then
			PC <= "00000000";
			IR <= "0000000000000000";
			OUTREG <= "0000000000000000";
			MAR <= "00000000";
			MBR <= "0000000000000000";
			RA <= "0000000000000000";
			RB <= "0000000000000000";
			RC <= "0000000000000000";
			RD <= "0000000000000000";
			RE <= "0000000000000000";
			SP <= "0000000000000000";
			CR <= "0000";
			count <= "000";
			state <= "0000";
		elsif (rising_edge(clk)) then
			case state is 
				when "0000" => -- start
					count <= std_LOGIC_VECTOR(unsigned(count) + 1);
					if count = "111" then
						state <= "0001"; -- moves to fetch 
					end if;
				
				when "0001" => -- fetch
					IR <= ROM_output;
					op <= ROM_output(14 downto 12);
					PC <= std_LOGIC_VECTOR(unsigned(PC) + 1);
					state <= "0010"; -- moves to execute-setup
				
				when "0010" => -- execute-setup
					if IR(15 downto 12) = "0000" then --load
						if IR(11) = '1' then
							MAR <= std_LOGIC_VECTOR(unsigned(IR(7 downto 0))+ unsigned(RE(7 downto 0)));
						else
							MAR <= IR(7 downto 0);
						end if;
						
					elsif IR(15 downto 12) = "0001" then --store
						if IR(11) = '1' then
							MAR <= std_LOGIC_VECTOR(unsigned(IR(7 downto 0))+ unsigned(RE(7 downto 0)));
						else
							MAR <= IR(7 downto 0);
						end if;
						if IR(10 downto 8) = "000" then 
							mbr <= RA;
						elsif IR(10 downto 8) = "001" then 
							mbr <= RB;
						elsif IR(10 downto 8) = "010" then 
							mbr <= RC;
						elsif IR(10 downto 8) = "011" then 
							mbr <= RD;
						elsif IR(10 downto 8) = "100" then 
							mbr <= RE;
						elsif IR(10 downto 8) = "101" then 
							mbr <= std_LOGIC_VECTOR(SP);
						end if;
						
						
					elsif IR(15 downto 12) = "0010" then -- unconditional branch
						PC <= IR(7 downto 0);
					
					elsif IR(15 downto 12) = "0011" then 
						if IR(11 downto 10) = "00" then-- conditional branch
							if IR(9 downto 8) = "00" then
								if CR(0) = '1'then 
									PC <= IR(7 downto 0);
								end if;
							elsif IR(9 downto 8) = "01" then
								if CR(1) = '1'then 
									PC <= IR(7 downto 0);
								end if;
							elsif IR(9 downto 8) = "10" then
								if CR(2) = '1'then 
									PC <= IR(7 downto 0);
								end if;
							elsif IR(9 downto 8) = "11" then
								if CR(3) = '1'then 
									PC <= IR(7 downto 0);
								end if;
							end if;
						end if;
							
						if IR(11 downto 10) = "01" then-- call instr
							PC <= IR(7 downto 0);
							MAR <= std_LOGIC_VECTOR(SP(7 downto 0));
							MBR <= "0000" & CR & PC;
							SP <= SP + 1;
						end if;
					
						if IR(11 downto 10) = "10" then --return
							MAR <= std_LOGIC_VECTOR(unsigned(SP(7 downto 0)) - 1);
							SP <= SP - 1;
						end if;
						
					elsif IR(15 downto 12) = "0100" then -- push
						MAR(7 downto 0) <= std_LOGIC_VECTOR(SP(7 downto 0));
						SP <= SP + 1;
						if IR(11 downto 9) = "000" then 
							MBR <= RA;
						elsif IR(11 downto 9) = "001" then 
							MBR <= RB;
						elsif IR(11 downto 9) = "010" then 
							MBR <= RC;
						elsif IR(11 downto 9) = "011" then 
							MBR <= RD;
						elsif IR(11 downto 9) = "100" then 
							MBR <= RE;
						elsif IR(11 downto 9) = "101" then 
							MBR <= std_LOGIC_VECTOR(SP);
						elsif IR(11 downto 9) = "110" then 
							MBR <= '0' & '0' & '0' & '0' & '0' & '0' & '0' & PC;
						elsif IR(11 downto 9) = "111" then 
							MBR <= '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & '0' & CR;
						end if;
					
					elsif IR(15 downto 12) = "0101" then -- pop
						MAR <= std_LOGIC_VECTOR(unsigned(SP(7 downto 0)) - 1);
						SP <= SP - 1;
						
					elsif IR(15 downto 12) = "1000" then -- add
						if IR(11 downto 9) = "000" then 
							SRCA <= RA;
						elsif IR(11 downto 9) = "001" then 
							SRCA <= RB;
						elsif IR(11 downto 9) = "010" then 
							SRCA <= RC;
						elsif IR(11 downto 9) = "011" then 
							SRCA <= RD;
						elsif IR(11 downto 9) = "100" then 
							SRCA <= RE;
						elsif IR(11 downto 9) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(11 downto 9) = "110" then 
							SRCA <= "0000000000000000";
						elsif IR(11 downto 9) = "111" then 
							SRCA <= "1111111111111111";
						end if;
						
						if IR(8 downto 6) = "000" then
							SRCB <= RA;
						elsif IR(8 downto 6) = "001" then 
							SRCB <= RB;
						elsif IR(8 downto 6) = "010" then 
							SRCB <= RC;
						elsif IR(8 downto 6) = "011" then 
							SRCB <= RD;
						elsif IR(8 downto 6) = "100" then 
							SRCB <= RE;
						elsif IR(8 downto 6) = "101" then 
							SRCB <= std_LOGIC_VECTOR(SP);
						elsif IR(8 downto 6) = "110" then 
							SRCB <= "0000000000000000";
						elsif IR(8 downto 6) = "111" then 
							SRCB <= "1111111111111111";
						end if;
						
					elsif IR(15 downto 12) = "1001" then -- sub
						if IR(11 downto 9) = "000" then 
							SRCA <= RA;
						elsif IR(11 downto 9) = "001" then 
							SRCA <= RB;
						elsif IR(11 downto 9) = "010" then 
							SRCA <= RC;
						elsif IR(11 downto 9) = "011" then 
							SRCA <= RD;
						elsif IR(11 downto 9) = "100" then 
							SRCA <= RE;
						elsif IR(11 downto 9) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(11 downto 9) = "110" then 
							SRCA <= "0000000000000000";
						elsif IR(11 downto 9) = "111" then 
							SRCA <= "1111111111111111";
						end if;
						
						if IR(8 downto 6) = "000" then
							SRCB <= RA;
						elsif IR(8 downto 6) = "001" then 
							SRCB <= RB;
						elsif IR(8 downto 6) = "010" then 
							SRCB <= RC;
						elsif IR(8 downto 6) = "011" then 
							SRCB <= RD;
						elsif IR(8 downto 6) = "100" then 
							SRCB <= RE;
						elsif IR(8 downto 6) = "101" then 
							SRCB <= std_LOGIC_VECTOR(SP);
						elsif IR(8 downto 6) = "110" then 
							SRCB <= "0000000000000000";
						elsif IR(8 downto 6) = "111" then 
							SRCB <= "1111111111111111";
						end if;
						
					elsif IR(15 downto 12) = "1010" then -- and
						if IR(11 downto 9) = "000" then 
							SRCA <= RA;
						elsif IR(11 downto 9) = "001" then 
							SRCA <= RB;
						elsif IR(11 downto 9) = "010" then 
							SRCA <= RC;
						elsif IR(11 downto 9) = "011" then 
							SRCA <= RD;
						elsif IR(11 downto 9) = "100" then 
							SRCA <= RE;
						elsif IR(11 downto 9) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(11 downto 9) = "110" then 
							SRCA <= "0000000000000000";
						elsif IR(11 downto 9) = "111" then 
							SRCA <= "1111111111111111";
						end if;
						
						if IR(8 downto 6) = "000" then
							SRCB <= RA;
						elsif IR(8 downto 6) = "001" then 
							SRCB <= RB;
						elsif IR(8 downto 6) = "010" then 
							SRCB <= RC;
						elsif IR(8 downto 6) = "011" then 
							SRCB <= RD;
						elsif IR(8 downto 6) = "100" then 
							SRCB <= RE;
						elsif IR(8 downto 6) = "101" then 
							SRCB <= std_LOGIC_VECTOR(SP);
						elsif IR(8 downto 6) = "110" then 
							SRCB <= "0000000000000000";
						elsif IR(8 downto 6) = "111" then 
							SRCB <= "1111111111111111";
						end if;
						
					elsif IR(15 downto 12) = "1011" then -- or
						if IR(11 downto 9) = "000" then 
							SRCA <= RA;
						elsif IR(11 downto 9) = "001" then 
							SRCA <= RB;
						elsif IR(11 downto 9) = "010" then 
							SRCA <= RC;
						elsif IR(11 downto 9) = "011" then 
							SRCA <= RD;
						elsif IR(11 downto 9) = "100" then 
							SRCA <= RE;
						elsif IR(11 downto 9) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(11 downto 9) = "110" then 
							SRCA <= "0000000000000000";
						elsif IR(11 downto 9) = "111" then 
							SRCA <= "1111111111111111";
						end if;
						
						if IR(8 downto 6) = "000" then
							SRCB <= RA;
						elsif IR(8 downto 6) = "001" then 
							SRCB <= RB;
						elsif IR(8 downto 6) = "010" then 
							SRCB <= RC;
						elsif IR(8 downto 6) = "011" then 
							SRCB <= RD;
						elsif IR(8 downto 6) = "100" then 
							SRCB <= RE;
						elsif IR(8 downto 6) = "101" then 
							SRCB <= std_LOGIC_VECTOR(SP);
						elsif IR(8 downto 6) = "110" then 
							SRCB <= "0000000000000000";
						elsif IR(8 downto 6) = "111" then 
							SRCB <= "1111111111111111";
						end if;
						
					elsif IR(15 downto 12) = "1100" then -- xor
						if IR(11 downto 9) = "000" then 
							SRCA <= RA;
						elsif IR(11 downto 9) = "001" then 
							SRCA <= RB;
						elsif IR(11 downto 9) = "010" then 
							SRCA <= RC;
						elsif IR(11 downto 9) = "011" then 
							SRCA <= RD;
						elsif IR(11 downto 9) = "100" then 
							SRCA <= RE;
						elsif IR(11 downto 9) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(11 downto 9) = "110" then 
							SRCA <= "0000000000000000";
						elsif IR(11 downto 9) = "111" then 
							SRCA <= "1111111111111111";
						end if;
						
						if IR(8 downto 6) = "000" then
							SRCB <= RA;
						elsif IR(8 downto 6) = "001" then 
							SRCB <= RB;
						elsif IR(8 downto 6) = "010" then 
							SRCB <= RC;
						elsif IR(8 downto 6) = "011" then 
							SRCB <= RD;
						elsif IR(8 downto 6) = "100" then 
							SRCB <= RE;
						elsif IR(8 downto 6) = "101" then 
							SRCB <= std_LOGIC_VECTOR(SP);
						elsif IR(8 downto 6) = "110" then 
							SRCB <= "0000000000000000";
						elsif IR(8 downto 6) = "111" then 
							SRCB <= "1111111111111111";
						end if;
						
					elsif IR(15 downto 12) = "1101" then -- shift
						if IR(10 downto 8) = "000" then 
							SRCA <= RA;
						elsif IR(10 downto 8) = "001" then 
							SRCA <= RB;
						elsif IR(10 downto 8) = "010" then 
							SRCA <= RC;
						elsif IR(10 downto 8) = "011" then 
							SRCA <= RD;
						elsif IR(10 downto 8) = "100" then 
							SRCA <= RE;
						elsif IR(10 downto 8) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(10 downto 8) = "110" then 
							SRCA <= "0000000000000000";
						elsif IR(10 downto 8) = "111" then 
							SRCA <= "1111111111111111";
						end if;
						SRCB(0) <= IR(11);
						
					elsif IR(15 downto 12) = "1110" then -- rotate 
						if IR(10 downto 8) = "000" then 
							SRCA <= RA;
						elsif IR(10 downto 8) = "001" then 
							SRCA <= RB;
						elsif IR(10 downto 8) = "010" then 
							SRCA <= RC;
						elsif IR(10 downto 8) = "011" then 
							SRCA <= RD;
						elsif IR(10 downto 8) = "100" then 
							SRCA <= RE;
						elsif IR(10 downto 8) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(10 downto 8) = "110" then 
							SRCA <= "0000000000000000";
						elsif IR(10 downto 8) = "111" then 
							SRCA <= "1111111111111111";
						end if;
						SRCB(0) <= IR(11);
						
					elsif IR(15 downto 12) = "1111" then -- move
						if IR(11) = '1' then 
							SRCA <= (IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10) & IR(10 downto 3));
						elsif IR(10 downto 8) = "000" then 
							SRCA <= RA;
						elsif IR(10 downto 8) = "001" then 
							SRCA <= RB;
						elsif IR(10 downto 8) = "010" then 
							SRCA <= RC;
						elsif IR(10 downto 8) = "011" then 
							SRCA <= RD;
						elsif IR(10 downto 8) = "100" then 
							SRCA <= RE;
						elsif IR(10 downto 8) = "101" then 
							SRCA <= std_LOGIC_VECTOR(SP);
						elsif IR(10 downto 8) = "110" then 
							SRCA <= PC;
						elsif IR(10 downto 8) = "111" then 
							SRCA <= IR;
						end if;

				end if;
				
				if IR(15 downto 10) = "001111" then
					state <= "1000";--halt
				else
					state <= "0011"; -- moves to execute-ALU
				end if;
				
				when "0011" => -- execute-ALU
					if IR(15 downto 12) = "0001" or IR(15 downto 12) = "0100" or IR(15 downto 12) = "0011" then 
						RAM_we <= '1';
					end if;
				
					if IR(15 downto 12) = "0100" or IR(15 downto 12) = "0001" or IR(15 downto 12) = "0011" or IR(15 downto 12) = "0000" or IR(15 downto 12) = "0101" or IR(15 downto 12) = "0011" then
						state <= "0100"; -- moves to execute-MemWait if instr. is reading from or writing to mem
					else
						state <= "0101"; -- otherwise goes to execute-write
					end if;
				
				when "0100" => -- execute-MemWait
					state <= "0101"; -- moves to execute-Write
				
				when "0101" => -- Execute-Write
					RAM_we <= '0';
					
					if IR(15 downto 12) = "0000" then -- load
						if IR(10 downto 8) = "000" then 
							RA <= RAM_output;
						elsif IR(10 downto 8) = "001" then 
							RB <= RAM_output;
						elsif IR(10 downto 8) = "010" then 
							RC <= RAM_output;
						elsif IR(10 downto 8) = "011" then 
							RD <= RAM_output;
						elsif IR(10 downto 8) = "100" then 
							RE <= RAM_output;
						elsif IR(10 downto 8) = "101" then 
							SP <= unsigned(RAM_output);
						end if;
						
						
					elsif IR(15 downto 12) = "0011" then -- return
						if IR(11 downto 10) = "10" then
							PC <= std_LOGIC_VECTOR(RAM_output(7 downto 0));
							CR <= std_LOGIC_VECTOR(RAM_output(11 downto 8));
						end if;
					
					elsif IR(15 downto 12) = "0101" then -- pop
						if IR(11 downto 9) = "000" then 
							RA <= RAM_output;
						elsif IR(11 downto 9) = "001" then 
							RB <= RAM_output;
						elsif IR(11 downto 9) = "010" then 
							RC <= RAM_output;
						elsif IR(11 downto 9) = "011" then 
							RD <= RAM_output;
						elsif IR(11 downto 9) = "100" then 
							RE <= RAM_output;
						elsif IR(11 downto 9) = "101" then 
							SP <= unsigned(RAM_output);
						elsif IR(11 downto 9) = "110" then 
							PC <= RAM_output;
						elsif IR(11 downto 9) = "111" then 
							CR <= RAM_output;
						end if;
						
					elsif IR(15 downto 12) = "0110" then -- write to output port
						if IR(11 downto 9) = "000" then 
							OUTREG <= RA;
						elsif IR(11 downto 9) = "001" then 
							OUTREG <= RB;
						elsif IR(11 downto 9) = "010" then 
							OUTREG <= RC;
						elsif IR(11 downto 9) = "011" then 
							OUTREG <= RD;
						elsif IR(11 downto 9) = "100" then 
							OUTREG <= RE;
						elsif IR(11 downto 9) = "101" then 
							OUTREG <= std_LOGIC_VECTOR(SP);
						elsif IR(11 downto 9) = "110" then 
							OUTREG <= PC;
						elsif IR(11 downto 9) = "111" then 
							OUTREG <= IR;
						end if;
						
					elsif IR(15 downto 12) = "0111" then -- load from input
						if IR(11 downto 9) = "000" then 
							RA <= input_port;
						elsif IR(11 downto 9) = "001" then 
							RB <= input_port;
						elsif IR(11 downto 9) = "010" then 
							RC <= input_port;
						elsif IR(11 downto 9) = "011" then 
							RD <= input_port;
						elsif IR(11 downto 9) = "100" then 
							RE <= input_port;
						elsif IR(11 downto 9) = "101" then 
							SP <= unsigned(input_port);
						end if;
						
					elsif IR(15 downto 12) = "1000" then -- add
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
						elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(dest);
						end if;
					CR <= aluCR;
						
					elsif IR(15 downto 12) = "1001" then -- subtract
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
						elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(dest);
						end if;
					CR <= aluCR;
					
					elsif IR(15 downto 12) = "1010" then -- and
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
						elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(dest);
						end if;
					CR <= aluCR;
					
					elsif IR(15 downto 12) = "1011" then -- or
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
						elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(dest);
						end if;
					CR <= aluCR;
					
					elsif IR(15 downto 12) = "1100" then -- exclusive or
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
						elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(dest);
						end if;
					CR <= aluCR;
					
					elsif IR(15 downto 12) = "1101" then -- shift
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
									elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(dest);
						end if;
					CR <= aluCR;
					
					elsif IR(15 downto 12) = "1110" then -- rotate
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
						elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(dest);
						end if;						
						if IR(11 downto 10) = "11" then -- exit
						state <= "1000"; -- moves to halt when instruction is an exit instruction
						end if;
					CR <= aluCR;
					
					elsif IR(15 downto 12) = "1111" then --move
						if IR(2 downto 0) = "000" then 
							RA <= dest;
						elsif IR(2 downto 0) = "001" then 
							RB <= dest;
						elsif IR(2 downto 0) = "010" then 
							RC <= dest;
						elsif IR(2 downto 0) = "011" then 
							RD <= dest;
						elsif IR(2 downto 0) = "100" then 
							RE <= dest;
						elsif IR(2 downto 0) = "101" then 
							SP <= unsigned(SP);
						end if;
					CR <= aluCR;
					
				end if;
				
				if IR(15 downto 10) /= "001110" then
					state <= "0001"; -- moves to fetch
				else
					state <= "0110"; -- execute return
				end if;
				
				when "0110" => -- execute-ReturnPause1
				if IR(15 downto 12) = "0011" then
					state <= "0111"; -- moves to execute-ReturnPause2
				end if;
				
				when "0111" => -- execute-ReturnPause2
				if IR(15 downto 12) = "0011" then 
					state <= "0001"; -- move to fetch
				end if;
				
				when "1000" => -- halt
					
				
				when others =>
				
			end case;
		end if;
	end process;
	
	end rtl;

	