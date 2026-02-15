---  В этом файле приводится описание центрального устройства управления ЦУУ.
-- Оно должно формировать управляющие сигналы для ОП, РП и спроектированного ранее арифметического устройства
-- Внешними сигналами для ЦУУ являются сигналы set, по которому ЦУУ, устанавливается в исходное состояние и тактовый сигнал clk
-- Для арифметического устройства оно готовит операнды А и В, задает сор и подает сигнал начала операции sno, после их подготовки
-- Из арифметического устройства оно забирает результат,
-- для умножения это 2n-разрядное произведение, для сложения -n-разрядная сумма и двухразрядный признак результата.
-- Сигналом, подтверждающим выполнение операции в арифметическом устройстве, является сигнал конца операции sko
-- Для оперативной памяти оно формирует следующие сигналы:
-- data_in_OP [7:0] - данные для записи в ОП
-- address_OP [7:0] - адрес, для обращения к ОП
-- wr_en_OP - сигнал записи в ОП, если этот сигнал не активен ОП выполняет чтение
-- Из ОП в ЦУУ поступает сигнал 
-- data_out_OP [7:0] - данные, считанные из ОП
-- Для регистровой памяти РП ЦУУ формирует следующие сигналы 
-- data_a_RP - данные для записи в РП, через порт а
-- address_a_RP [2:0] - адрес, для обращения к RП, через порт a
-- wren_a_RP - сигнал записи через порт а в РП, если этот сигнал не активен PП выполняет чтение
-- data_b_RP - данные для записи в РП, через порт b
-- address_b_RP [2:0] - адрес, для обращения к RП, через порт b
-- wren_b_RP - сигнал записи через порт b в РП, если этот сигнал не активен PП выполняет чтение
-- q_a - данные, считываемые из РП, через порт а
-- q_b - данные, считываемые из РП, через порт b



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.numeric_std.all; -- добавляем библиотеку
LIBRARY work;

--LIBRARY altera_mf;

--USE altera_mf.altera_mf_components.all;

entity CYY_AU_OP_RP_F is
generic (n:integer:=8);     -- n параметр, задает разрядность операндов
	port
	(	
		clk		 : in	std_logic; -- тактовый сигнал
		set 		 : in	std_logic; --  сигнал начальной установки
		f_com     : buffer std_logic_vector(1 downto 0); -- пока задает формат команды: 2 - УП; 1 - РР; 0 - ПР
-- Для взаимодействия с АУ
		a 			 : buffer  STD_LOGIC_VECTOR (n-1 downto 0);-- первый операнд для АУ		
		b 			 : buffer  STD_LOGIC_VECTOR (n-1 downto 0);-- второй операнд для АУ		

		cop		 : buffer	std_logic; --  код операции 1-умножение,0 - сложение для АУ
		sno		 : buffer	std_logic; -- сигнал начала операции для АУ
		
		rr 		 : buffer  STD_LOGIC_VECTOR (2*n-1 downto 0);-- результат из АУ
      priznak 	 : buffer  STD_LOGIC_VECTOR (1 downto 0); -- признак результата из АУ
		sko	 	 : buffer	std_logic; -- сигнал конца операции из АУ
-- Для наблюдения внутренних сигналов во время отладки проекта
		signal RB : buffer STD_LOGIC_VECTOR (7 downto 0);-- регистр адреса, для адресации операнда в ОП
		signal CK : buffer STD_LOGIC_VECTOR (7 downto 0);-- счетчик команд, для адресации текущей команды в ОП
		signal RK : buffer STD_LOGIC_VECTOR (7 downto 0);-- регистр команд, для хранения адреса
		signal RI : buffer STD_LOGIC_VECTOR (7 downto 0);-- регистр команд, для хранения операнда
		s_out		 : out STD_LOGIC_VECTOR(3 downto 0);    -- отладочный выход для наблюдения состояний БМК
-- Для взаимодействия с ОП		
		data_in_OP : buffer STD_LOGIC_VECTOR (7 downto 0); -- данные для записи в ОП
		address_OP : buffer STD_LOGIC_VECTOR (7 downto 0); -- адрес, для обращения к ОП
		wr_en_OP   : buffer std_logic; -- сигнал записи в ОП, если этот сигнал не активен, ОП выполняет чтение
		data_out_OP: buffer STD_LOGIC_VECTOR (7 downto 0); -- данные, считанные из ОП
--		address_b_OP : buffer STD_LOGIC_VECTOR (7 downto 0); -- адрес, для обращения к ОП
-- Для взаимодействия с РП
--		data_a_RP    : buffer STD_LOGIC_VECTOR (7 downto 0); -- данные для записи в РП, через порт а
		address_a_RP : buffer STD_LOGIC_VECTOR (2 downto 0); -- адрес, для обращения к RП, через порт a
		wr_en_a_RP 	 : buffer std_logic; 						  -- сигнал записи через порт а в РП, если этот сигнал не активен PП выполняет чтение
--		data_b_RP 	 : buffer STD_LOGIC_VECTOR (7 downto 0); -- данные для записи в РП, через порт b
		address_b_RP : buffer STD_LOGIC_VECTOR (2 downto 0); -- адрес, для обращения к RП, через порт b
		wr_en_b_RP 	 : buffer std_logic;							  -- сигнал записи через порт b в РП, если этот сигнал не активен PП выполняет чтение
		q_a 		 	 : buffer STD_LOGIC_VECTOR (7 downto 0);-- данные из РП с порта а	
		q_b 		 	 : buffer STD_LOGIC_VECTOR (7 downto 0) -- данные из РП с порта b
	);

end entity CYY_AU_OP_RP_F;

architecture arch of CYY_AU_OP_RP_F is

-----------------------------Декларация компонента ОП на 256 байт --------------------------------------------------------------------

component memory
	PORT
	(
		address	: IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- адресный вход
		clock		: IN STD_LOGIC ;				  			 -- тактовый вход
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- вход данных
		wren		: IN STD_LOGIC ;						   -- разрешение записи
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)	   -- выход данных 
	);
end component;
---------------------------------------------------------------------------------------------------------------------------------------
-- Следующим компонентом является память регистровая RP 
-- Декларация компонента регистровой памяти на 8 байт
-- Содержит два порта a и b
-- Создан в QII версии 13.1 Как его создать, есть в методичке
COMPONENT Ram_2port_11
	PORT
	(
		address_a		:	 IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- адресный вход порта а
		address_b		:	 IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- адресный вход порта b
		clock		:	 IN STD_LOGIC;									 -- тактовый сигнал
		data_a		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);	 -- вход данных для записи через порт а
		data_b		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);	 -- вход данных для записи через порт b
		wren_a		:	 IN STD_LOGIC;								 -- разрешение записи через порт а
		wren_b		:	 IN STD_LOGIC;								 -- разрешение записи через порт b
		q_a		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);		 -- выходная шина порта a
		q_b		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0)		 -- выходная шина порта b
	);
END COMPONENT;

----------------------------------------------------------------------------------------------------------------------------------------------------
---- Компонент Арифметическое устройство, спроектированное ранее
-- Взят из седьмого проекта

COMPONENT ctrl_un_BO
	GENERIC ( n : INTEGER );
	PORT
	(
		a		:	 IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- вход первого операнда
		b		:	 IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- вход второго операнда
		clk		:	 IN STD_LOGIC; -- синхросигнал
		set		:	 IN STD_LOGIC; -- сигнал начальной установки
		cop		:	 IN STD_LOGIC; -- код операции 
		sno		:	 IN STD_LOGIC; -- сигнал начала операции
		rr			:	 OUT STD_LOGIC_VECTOR(2*n-1 DOWNTO 0); -- результат
		priznak	:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- признак результата
		sko		:	 OUT STD_LOGIC -- сигнал конца операции
	);
END COMPONENT;
------------------------------------------------------------------------------------------------------------------------------------------------
-- Декларация сигналов, используемых в проекте 
type state_type is (s0, s1, s2, s3, s4, s5, s6, s7, s8); -- определяем состояния БМК
	signal next_state, state : state_type; -- следующее состояние, текущее состояние
	
signal incr_CK	: STD_LOGIC:='0';-- разрешение инкремента СК
signal summ_CK	: STD_LOGIC:='0';-- вычисление адреса перехода
signal load_RK	: STD_LOGIC:='0';-- загрузка команды
signal load_RB	: STD_LOGIC:='0';-- загрузка адреса
signal load_RI	: STD_LOGIC:='0';-- загрузка адреса
signal IA		: STD_LOGIC_VECTOR (7 downto 0);-- исполнительный адрес операнда в ОП 
signal incr_RA	: STD_LOGIC:='0';-- разрешение инкремента РА
signal incr_RI	: STD_LOGIC:='0';-- разрешение инкремента РА
-----------------------------------------------------------------------------------

begin
-- устанавливаются экземпляры компонентов OP,RP,AU
Comp_OP: memory
port map ( address_OP, clk, data_in_OP, wr_en_OP, data_out_OP);

----------------------------------------------------------------------------------------------------------------

Comp_RP: Ram_2port_11 PORT MAP (
		address_a	 => address_a_RP, -- RK(5 downto 3), -- адрес R1
	   address_b	 => address_b_RP, -- RK(2 downto 0), -- адрес R2
		clock	 => clk,
		data_a	 => rr(7 downto 0),  -- младшую часть результата для записи суммы
		data_b	 => rr(15 downto 8),   -- записывать через второй порт пока не надо
		wren_a	 => wr_en_a_RP,		-- разрешение записи в РП 
		wren_b	 => wr_en_b_RP,					-- через порт b запись не выполняем
		q_a	 => q_a,						-- для наблюдения на вд
		q_b	 => q_b						-- для наблюдения на вд
	);

-----------------------------------------------------------------------------------------------------------------------------
Comp_AY: ctrl_un_BO
generic map
	(n => 8)
port map ( a,b,clk,set,cop,sno,rr,priznak,sko);

-------------------------------------------------------------------------------------------
pr_CK:   process (set, clk) -- этот процесс определяет поведение счетчика команд СК
	
	begin
		if (set='1') then CK<=(others=>'0'); --устанавливаем в начальное состояние
		elsif clk'event and clk='1' then 
		  if (incr_CK='1') then CK<=CK+"00000001"; -- инкремент счетчика
			elsif (summ_CK='1' and (priznak = "00" or priznak = "01")) then CK<=RI ; -- вычисление адреса перехода
		   end if;
		 end if;
	end process pr_CK;
---------------------------------------------------------------------------------------	 
pr_RK: process (clk) -- этот процесс определяет поведение регистра команд
	begin
		if clk'event and clk='1' then -- по положительному фронту clk
			if load_RK='1' then -- если есть разрешение на прием команды
			RK<=data_out_OP; -- выполняется прием команды с выхода ОП
			end if;
		end if;
	end process pr_RK;
---------------------------------------------------------------------------------------------
pr_RB: process (clk)-- этот процесс описывает логику работы регистра адреса RA
	begin
		if clk'event and clk='1' then -- по положительному фронту 
		 if load_RB='1' then  RB<= data_out_OP; -- если есть разрешение, то загружаем исполнительный адрес первого операнда		
				--elsif incr_RA='1' then RA<=RA-1; --инкремент адреса"00000001"
		 end if;
		end if;
end process pr_RB;
------------------------------------------------------------------------------------------------
pr_RI: process (clk)-- запоминает значение операнда
	begin
		if clk'event and clk='1' then -- по положительному фронту 
		 if load_RI='1' then  RI<=data_out_OP; -- если есть разрешение, то загружаем исполнительный адрес первого операнда		
			 elsif incr_RI='1' then RI<=RI+1;
			 end if;
		end if;
end process pr_RI;
------------------------------------------------------------------------------------------------
-- Ниже приводится описание устройства управления для ЦУУ.Реализованы три формата команд ПР,РР и УП
TS: process (clk,set) -- этот процесс определяет текущее состояние МУУ
	 begin
		if set = '1' then
			state <= s0;
		elsif (rising_edge(clk)) then -- по положительному фронту переключаются состояния
			state <= next_state;			
		end if;
	 end process TS;
	 
NS: process (state,set,f_com,sko,priznak) -- этот процесс определяет следующее состояние МУУ, управляющие сигналы
	 begin
-- 

			case state is
				when s0=> -- переходы из s0
				 
					if (set = '0') then
						next_state <= s1;  
					else
						next_state <= s0; 
					end if;
				when s1=> 
				if f_com = "01" then 
						next_state <= s4;
					else 
						next_state <= s2;
						end if;
				
				when s2=>
				if f_com = "11" then 
						next_state <= s7;
					else
						next_state <= s3;
						end if;
						
				when s3=>
						next_state <= s4; 
					
				when s4=>
						next_state <= s5; 
						
				
				when s5 =>
						if (sko='1') then
							next_state <= s6;   
						else 
							next_state <= s5;	
						
					end if;
						
				when s6 =>
							next_state <= s7;  
				when s7 =>
						next_state <= s8; 
					
				when s8 =>
						next_state <= s0; 
				
			end case;			
	end process NS;
---------------------------------------------------------------------------------------------------------
-- ниже приводится описание управляющих сигналов для БМК

incr_CK<='1' when ( state=s0 or (state = s2 and (f_com = "00" or f_com = "11")) ) else 
			'0';
summ_CK<='1' when (state=s7 and ( f_com = "11") ) else 
			'0';
load_RK<='1' when (state=s0) else -- загрузка команды в RK всегда в s0 для любой операции
			'0';
load_RB<='1' when (state=s3) else -- загрузка значения операнда В 
			'0';
incr_RI <='1' when (state = s6 and f_com = "00") else -- инкремент RA для записи старшей части результата в ОП, только для умножения
			'0';
			
load_RI<='1' when (state = s2) else -- загрузка ИА в RA в s2 для операции умножения
			'0';

sno <='1' when (state=s4) else -- когда извлекли операнды на шину А и В 
			'0';			
data_in_OP<= rr(2*n-1 downto n) when (state= s7 and f_com = "00") else
				 rr(n-1 downto 0) when (state = s6 and f_com = "00");
				 
				 
-- адреса 
address_OP <= IA when (state = s2 and f_com = "00") else
				  RI when ((state = s3 or (state = s6 or state=s7)) and f_com = "00") else
				  CK;
	 
IA<= q_b ; -- исполнительный адрес для 2 операнда


wr_en_a_RP<='1' when (sko = '1' and f_com = "01") else '0'; -- запись в РП, если формат Р-Р, инвертирование
wr_en_OP<='1' when (cop = '0' and (state = s6 or state = s7)) and f_com = "00" else '0'; -- запись в рп при умножение


				
a<= data_out_OP when (state = s4 and f_com = "00") else 
	 q_a when (state = s4 and f_com = "01") else 
	 (others=>'0') ;
	 
b<= RB when (state = s4 and f_com = "00") else 
	 q_b when (state = s4 and f_com = "01") else 
	 (others=>'0'); 



f_com<="00" when RK(7 downto 6)="00" else -- если умн
		 "01" when RK(7 downto 6)="01" else -- если инвертирование, то РР
		 "11";		 -- если переход
		 
cop<=RK(6); -- этот разряд определяет операцию в арифметическом устройстве
---------------------------------------------------------------------------------------------------

address_a_RP<= RK(5 downto 3)  ; -- поле R1  в команде
address_b_RP<= RK (2 downto 0); -- поле R2  в команде


---------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
	--  отладочный выход для наблюдения текущего состояния
		s_out<="0000" when state=s0 else
				  "0001" when state=s1 else					
				  "0010" when state=s2 else
				  "0011" when state=s3 else
				  "0100" when state=s4 else
				  "0101" when state=s5 else
				  "0110" when state=s6 else
				  "0111" when state=s7 else
				  "1000" when state=s8; --else
--				  "1001" when state=s9 else
--				  "1010";
end arch;

