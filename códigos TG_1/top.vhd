
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;    --Este no es recomendable usar
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;          --Este es mas pijudo

Library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use unimacro.Vcomponents.all;

use work.paquete_multiplexor.all;




entity top is
    Port ( 
	        ov7670_pclk  : in  STD_LOGIC;
           ov7670_xclk  : out STD_LOGIC;
           ov7670_vsync : in  STD_LOGIC;
           ov7670_href  : in  STD_LOGIC;
           ov7670_data  : in  STD_LOGIC_vector(7 downto 0);
           ov7670_sioc  : out STD_LOGIC;
           ov7670_siod  : inout STD_LOGIC;
           ov7670_pwdn  : out STD_LOGIC;
           ov7670_reset : out STD_LOGIC;
	 
	 
				led_1			: 	OUT	STD_LOGIC;
				led_2			: 	OUT	STD_LOGIC;
				RED 			: out  STD_LOGIC_VECTOR(3 downto 0);
           GREEN 			: out  STD_LOGIC_VECTOR(3 downto 0);
           BLUE 			: out  STD_LOGIC_VECTOR(3 downto 0);
           V_SYNC 		: out  STD_LOGIC;
           H_SYNC 		: out  STD_LOGIC;
           RESET 			: in  STD_LOGIC;
           sw3 			: in  STD_LOGIC;
           CLK_50MHZ 	: in  STD_LOGIC);
end top;

architecture Behavioral of top is

--- Arreglos declarados por Blas

type t_transform is array (0 to 191, 0 to 16) of integer; -- arreglo de 192 columnas y 17 filas (196 por ser 64 de chang�i 64 de imagen 64 de chang�i y 17 para poder discretizar de 0� a 45� con 8 angulos)



-- Procedure para modificar cosas

  procedure ImagenThreshold (
    signal r_IN  : in  std_logic_vector(15 downto 0);
    signal r_OUT : out std_logic_vector(15 downto 0)
    ) is
  begin    
	 	if((to_integer(unsigned(r_IN(14 downto 11)))+to_integer(unsigned(r_IN(9 downto 6)))+to_integer(unsigned(r_IN(4 downto 1))))/3>8) then
			r_OUT<="1"&"11111"&"11111"&"11111";
		else 
			r_OUT<="0"&"00000"&"00000"&"00000";
		end if;
  end ImagenThreshold;

-- Procedure del Canny (version villera)

  procedure ImagenBorde (
    signal r_IN0  : in  std_logic_vector(15 downto 0);
    signal r_IN1  : in  std_logic_vector(15 downto 0);
    signal r_IN2  : in  std_logic_vector(15 downto 0);
    signal r_OUT : out std_logic_vector(15 downto 0)
    ) is
  begin    
	 	if(to_integer(unsigned(r_IN0)) = 0 and to_integer(unsigned(r_IN1)) > 0) then
			r_OUT<="1"&"11111"&"11111"&"11111";
		else if(to_integer(unsigned(r_IN0)) > 0 and to_integer(unsigned(r_IN1)) > 0 and to_integer(unsigned(r_IN1)) = 0) then
			r_OUT<="1"&"11111"&"11111"&"11111";
		else
			r_OUT<="0"&"00000"&"00000"&"00000";
		end if;
		end if;
  end ImagenBorde;
  
  
  -- Procedure de la Transformada
  
  
    procedure ImagenTG (
    signal r_IN  : in  std_logic_vector(15 downto 0);
    signal r_IN_ADDR  : in  std_logic_vector(12 downto 0);
    signal r_OUT : inout t_transform
    ) is
	 
	 variable pos_x0 		: integer;
	 variable pos_x45 		: integer;
	 variable pos_x45neg 	: integer;
	 
	 variable pos_y 			: integer;
	 
	 variable pos_x05 		: integer;
	 variable pos_x11 		: integer;
	 variable pos_x17 		: integer;
	 variable pos_x22 		: integer;
	 variable pos_x28 		: integer;
	 variable pos_x33 		: integer;
	 variable pos_x39 		: integer;
	 
	 variable pos_x05neg 	: integer;
	 variable pos_x11neg 	: integer;
	 variable pos_x17neg 	: integer;
	 variable pos_x22neg 	: integer;
	 variable pos_x28neg 	: integer;
	 variable pos_x33neg 	: integer;
	 variable pos_x39neg 	: integer;
	 
	 
  begin    
  
		pos_y			:=	to_integer(unsigned(r_IN_ADDR))/64;					-- La posicion en Y es la direccion divido 64 (Por ejemplo, la direccion 0 me da que la Y es 0, la direccion 63 me da que la Y es 0 y la direccion 120 me da que la Y es 1)
		pos_x0		:=	to_integer(unsigned(r_IN_ADDR))-pos_y*64 + 64;	-- La posicion en X es la direccion menos la posicion en Y multiplicado por 64 (Por ejemplo, la direccion 0 da X=0-0*64=0, la direccion 63 da X=63-0*64=63 y la direccion 120 da X=120-64=56)  Te preguntaras por que el 64 del final? bueno eso est� solo para acomodarlo dentro del arrelo que arme porque deje 64 casillas a cada costado de la imagen por las dudass que los indices se me pasaran.
		pos_x45		:=	pos_x0-pos_y;												-- La posicion en X (del angulo 45�) es la posX-posY (capaz es mas, pero es lo mismo)
		pos_x45neg	:=	pos_x0+pos_y;												-- La posicion en X (del angulo -45�) es la posX+posY (capaz es menos, pero es lo mismo)
		
		pos_x05		:= pos_x0-pos_y/8;
		pos_x11		:= pos_x0-pos_y/4;
		pos_x17		:= pos_x0-3*pos_y/8;
		pos_x22		:= pos_x0-pos_y/2;
		pos_x28		:= pos_x0-5*pos_y/8;
		pos_x33		:= pos_x0-3*pos_y/4;
		pos_x39		:= pos_x0-7*pos_y/8;		

		pos_x05neg	:= pos_x0+pos_y/8;
		pos_x11neg	:= pos_x0+pos_y/4;
		pos_x17neg	:= pos_x0+3*pos_y/8;
		pos_x22neg	:= pos_x0+pos_y/2;
		pos_x28neg	:= pos_x0+5*pos_y/8;
		pos_x33neg	:= pos_x0+3*pos_y/4;
		pos_x39neg	:= pos_x0+7*pos_y/8;
			
	 	if(r_IN>0) then
			r_OUT(pos_x45,0)		<= r_OUT(pos_x45,0)+1;
			r_OUT(pos_x39,1)		<= r_OUT(pos_x39,1)+1;
			r_OUT(pos_x33,2)		<= r_OUT(pos_x33,2)+1;
			r_OUT(pos_x28,3)		<= r_OUT(pos_x28,3)+1;
			r_OUT(pos_x22,4)		<= r_OUT(pos_x22,4)+1;
			r_OUT(pos_x17,5)		<= r_OUT(pos_x17,5)+1;
			r_OUT(pos_x11,6)		<= r_OUT(pos_x11,6)+1;
			r_OUT(pos_x05,7)		<= r_OUT(pos_x05,7)+1;
			r_OUT(pos_x0,8)		<= r_OUT(pos_x0,8)+1;
			r_OUT(pos_x05neg,9)	<= r_OUT(pos_x05neg,9)+1;
			r_OUT(pos_x11neg,10)	<= r_OUT(pos_x11neg,10)+1;
			r_OUT(pos_x17neg,11)	<= r_OUT(pos_x17neg,11)+1;
			r_OUT(pos_x22neg,12)	<= r_OUT(pos_x22neg,12)+1;
			r_OUT(pos_x28neg,13)	<= r_OUT(pos_x28neg,13)+1;
			r_OUT(pos_x33neg,14)	<= r_OUT(pos_x33neg,14)+1;
			r_OUT(pos_x39neg,15)	<= r_OUT(pos_x39neg,15)+1;
			r_OUT(pos_x45neg,16)	<= r_OUT(pos_x45neg,16)+1;
		end if;
  end ImagenTG;




COMPONENT vga_controller IS
PORT(
		pixel_clk	:	IN		STD_LOGIC;	--pixel clock at frequency of VGA mode being used
		reset_n		:	IN		STD_LOGIC;	--active low asycnchronous reset
		h_sync		:	OUT	STD_LOGIC;	--horiztonal sync pulse
		v_sync		:	OUT	STD_LOGIC;	--vertical sync pulse
		disp_ena		:	OUT	STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
		column		:	OUT	INTEGER;		--horizontal pixel coordinate
		row			:	OUT	INTEGER;		--vertical pixel coordinate
		n_blank		:	OUT	STD_LOGIC;	--direct blacking output to DAC
		n_sync		:	OUT	STD_LOGIC); --sync-on-green output to DAC
END COMPONENT;


COMPONENT hw_image_generator IS
  PORT(
	 activa_imagen	:	OUT 	STD_LOGIC;
	 DO_ram_red   		:  IN   	STD_LOGIC_VECTOR (3 downto 0);
	 DO_ram_green   :  IN   STD_LOGIC_VECTOR (3 downto 0); 
	 DO_ram_blue   :  IN   STD_LOGIC_VECTOR (3 downto 0); 	 
    disp_ena 		:  IN   	STD_LOGIC;  							--display enable ('1' = display time, '0' = blanking time)
    row      		:  IN   	INTEGER;    							--row pixel coordinate
    column   		:  IN   	INTEGER;    							--column pixel coordinate
    red      		:  OUT  	STD_LOGIC_VECTOR(3 downto 0);  							--red magnitude output to DAC
    green    		:  OUT  	STD_LOGIC_VECTOR(3 downto 0);  							--green magnitude output to DAC
    blue     		:  OUT  	STD_LOGIC_VECTOR(3 downto 0)); 							--blue magnitude output to DAC
END COMPONENT;


COMPONENT memoria_16x9kbram is
    Port ( 
				CLK_25 	: in  STD_LOGIC;
				ADDR		: in	STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
				memoria_out 	: out  STD_LOGIC_VECTOR(15 downto 0);
				
				CLK_write		: in  STD_LOGIC;--debe ser flanco negativo de pclk
				wr_enable	: in  STD_LOGIC;
				enable_b		: in  STD_LOGIC;
				ADDR_write		: in	STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
				data_write	 	: in	STD_LOGIC_VECTOR(15 downto 0)
			);
end COMPONENT;

COMPONENT ov7670_controller is
    Port ( 
				clk   : in    STD_LOGIC;
			  resend :in    STD_LOGIC;
			  desactivo :in    STD_LOGIC;
			  config_finished : out std_logic;
           sioc  : out   STD_LOGIC;
           siod  : inout STD_LOGIC;
           reset : out   STD_LOGIC;
           pwdn  : out   STD_LOGIC;
			  xclk  : out   STD_LOGIC
);
end COMPONENT;

COMPONENT ov7670_capture is
    Port ( pclk  : in   STD_LOGIC;
           vsync : in   STD_LOGIC;
           href  : in   STD_LOGIC;
           d     : in   STD_LOGIC_VECTOR (7 downto 0);
           addr  : out  STD_LOGIC_VECTOR (12 downto 0);
           dout  : out  STD_LOGIC_VECTOR (15 downto 0);
           we    : out  STD_LOGIC);
end COMPONENT;


COMPONENT debounce_corto is
    Port ( clk : in  STD_LOGIC;
           i : in  STD_LOGIC;
           o : out  STD_LOGIC);
end COMPONENT;

COMPONENT debounce_corto_ns is
    Port ( clk : in  STD_LOGIC;
	 			valor : in STD_LOGIC_VECTOR(3 downto 0);
           i : in  STD_LOGIC;
           o : out  STD_LOGIC);
end COMPONENT;



SIGNAL reset_negado : STD_LOGIC;


--VGA--
SIGNAL vertical_sinc 	: STD_LOGIC;
SIGNAL horizontal_sinc 	: STD_LOGIC;
SIGNAL n_sync 				: STD_LOGIC;
SIGNAL n_blank 			: STD_LOGIC;
SIGNAL columna 			: INTEGER;								--tambien de im_generator
SIGNAL fila 				: INTEGER;								--tambien de im_generator
SIGNAL disp_ena 			: STD_LOGIC;							--tambien de im_generator



signal contador : STD_LOGIC_VECTOR(27 downto 0) := (others => '0');
signal contador2 : integer range 0 to 50000000  := 0;
signal contador3 : integer range 0 to 50000000  := 0;


--clk signals
signal CLK_50 : STD_LOGIC;
signal CLK_50_nobuff : STD_LOGIC;
signal CLK_25 : STD_LOGIC;
signal CLK_25_nobuff : STD_LOGIC;


--RAM--
SIGNAL DO_ram 				: STD_LOGIC_VECTOR(3 downto 0) := "0000";
SIGNAL DO_ram_red			: STD_LOGIC_VECTOR(3 downto 0) := "1111";
SIGNAL DO_ram_green		: STD_LOGIC_VECTOR(3 downto 0) := "1111";
SIGNAL DO_ram_blue		: STD_LOGIC_VECTOR(3 downto 0) := "1111";
SIGNAL ADDR 				: STD_LOGIC_VECTOR(12 downto 0) := (others => '0');

SIGNAL ram_out_16bit		: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

--SIGNAL enablers		: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

--signal salidas_rams : vector16x16bits;


	
--IMAGEN GENERATOR--
SIGNAL activa_imagen 	: STD_LOGIC;


--Se�ales para que la imagen se vea grande--
signal contador_pixeles : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
signal contador_lineas 	: STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
	
--se�ales para probar el write de memoria
--signal contador_tiempo	: integer range 0 to 26000000 := 0;
--signal clk_mem_b			: std_logic := '0';
SIGNAL ADDR_b 				: STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
signal bus_datos_b		: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal signal_we_b		: std_logic := '0';
	
	
--mas pavadas	
signal config_terminada		: std_logic := '0';
signal ov7670_pclk_neg		: std_logic := '0';

signal ov7670_pclk_buf		: std_logic := '0';
signal sw3_pulsado		: std_logic := '0';


signal ov7670_vsync_debounced : std_logic := '0';
signal ov7670_href_debounced	: std_logic := '0';


signal reset_debounce	: std_logic := '0';	
signal valor_debounce : STD_LOGIC_VECTOR(3 downto 0);


signal pwdn_camara	: std_logic := '0';	
signal sw3_debounce	: std_logic := '0';	

--debug
signal led_debug		: std_logic := '0';


-- Signals que invento Blas

signal imagen_threshold : std_logic_vector(15 downto 0); -- Esta signal, es la salida del procedure.
signal imagen_borde : std_logic_vector(15 downto 0); -- Esta signal, es la salida del procedure.

signal p0 : std_logic_vector(15 downto 0);
signal p1 : std_logic_vector(15 downto 0);
signal p2 : std_logic_vector(15 downto 0) := (others => '1');


signal TG : t_transform;
	
begin

sw3_pulsado  <= NOT sw3;
reset_negado <= NOT RESET;

-- Pedazo de codigo puesto por Blas 

ImagenThreshold(bus_datos_b,imagen_threshold);

process(ADDR_b)


	begin

		if(ADDR_b = 0) then
			imagen_borde <= imagen_threshold;
			p0<= imagen_threshold;
			elsif(ADDR_b = 1) then
				p1<= imagen_threshold;
				ImagenBorde(p0,p1,p2,imagen_borde);
			else
				p2<=imagen_threshold;
				ImagenBorde(p0,p1,p2,imagen_borde);
				p0<=p1;
				p1<=p2;
			end if;
		--end if;
	end process;

 ImagenTG(imagen_borde,ADDR_b,TG);










DO_ram_red		<= ram_out_16bit(14 downto 11);
DO_ram_green	<=	ram_out_16bit(9 downto 6);
DO_ram_blue		<= ram_out_16bit(4 downto 1);


	debounce_corto_vsync : debounce_corto
	port map(
	
		clk => CLK_25,
		i	=> ov7670_vsync,
		o	=>	ov7670_vsync_debounced
	
	);

	debounce_corto_reset : debounce_corto
	port map(
	
		clk => CLK_25,
		i	=> reset_negado,
		o	=>	reset_debounce
	
	);

	debounce_corto_sw3 : debounce_corto
	port map(
	
		clk => CLK_25,
		i	=> sw3_pulsado,
		o	=>	sw3_debounce
	
	);

	
	debounce_corto_href : debounce_corto_ns
	port map(
		valor => valor_debounce,
		clk => CLK_25,
		i	=> ov7670_href,
		o	=>	ov7670_href_debounced
	
	);






   BUFG_inst_CLK_50 : BUFG
   port map (
      O => CLK_50, -- 1-bit output: Clock buffer output
      I => CLK_50_nobuff -- 1-bit input: Clock buffer input
   );


   BUFG_inst_CLK_25 : BUFG
   port map (
      O => CLK_25, -- 1-bit output: Clock buffer output
      I => CLK_25_nobuff -- 1-bit input: Clock buffer input
   );
--	
--   BUFG_inst_ov7670_pclk_buf : BUFG
--   port map (
--      O => ov7670_pclk_buf, -- 1-bit output: Clock buffer output
--      I => ov7670_pclk -- 1-bit input: Clock buffer input
--   );
--


   IBUFG_inst : IBUFG
   generic map (
      IBUF_LOW_PWR => FALSE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "DEFAULT")
   port map (
      O => ov7670_pclk_buf, -- Clock buffer output
      I => ov7670_pclk  -- Clock buffer input (connect directly to top-level port)
   );



	memoria_imagen : memoria_16x9kbram
	port map(
		ADDR => ADDR,
		CLK_25 => CLK_25,
		memoria_out => ram_out_16bit,		
		CLK_write	=> ov7670_pclk_buf,--signal_we_b,--ov7670_pclk_neg,
		wr_enable	=> signal_we_b,--'1',--signal_we_b,
		enable_b		=> '1',
		ADDR_write	=> ADDR_b,	
		data_write	=> imagen_borde--imagen_threshold--bus_datos_b	
	);

	ov7670_pclk_neg <= NOT ov7670_pclk_buf;

   -- DCM_SP: Digital Clock Manager
   --         Spartan-6
   -- Xilinx HDL Language Template, version 14.7

   DCM_SP_inst : DCM_SP
   generic map (
      CLKDV_DIVIDE => 2.0,                   -- CLKDV divide value
                                             -- (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
      CLKFX_DIVIDE => 1,                     -- Divide value on CLKFX outputs - D - (1-32)
      CLKFX_MULTIPLY => 4,                   -- Multiply value on CLKFX outputs - M - (2-32)
      CLKIN_DIVIDE_BY_2 => FALSE,            -- CLKIN divide by two (TRUE/FALSE)
      CLKIN_PERIOD => 10.0,                  -- Input clock period specified in nS
      CLKOUT_PHASE_SHIFT => "NONE",          -- Output phase shift (NONE, FIXED, VARIABLE)
      CLK_FEEDBACK => "1X",                  -- Feedback source (NONE, 1X, 2X)
      DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SYSTEM_SYNCHRNOUS or SOURCE_SYNCHRONOUS
      DFS_FREQUENCY_MODE => "LOW",           -- Unsupported - Do not change value
      DLL_FREQUENCY_MODE => "LOW",           -- Unsupported - Do not change value
      DSS_MODE => "NONE",                    -- Unsupported - Do not change value
      DUTY_CYCLE_CORRECTION => TRUE,         -- Unsupported - Do not change value
      FACTORY_JF => X"c080",                 -- Unsupported - Do not change value
      PHASE_SHIFT => 0,                      -- Amount of fixed phase shift (-255 to 255)
      STARTUP_WAIT => FALSE                  -- Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
   )
   port map (
      CLK0 => CLK_50_nobuff,         -- 1-bit output: 0 degree clock output
      CLK180 => open,     -- 1-bit output: 180 degree clock output
      CLK270 => open,     -- 1-bit output: 270 degree clock output
      CLK2X => open,       -- 1-bit output: 2X clock frequency clock output
      CLK2X180 => open, -- 1-bit output: 2X clock frequency, 180 degree clock output
      CLK90 => open,       -- 1-bit output: 90 degree clock output
      CLKDV => CLK_25_nobuff,       -- 1-bit output: Divided clock output
      CLKFX => open,       -- 1-bit output: Digital Frequency Synthesizer output (DFS)
      CLKFX180 => open, -- 1-bit output: 180 degree CLKFX output
      LOCKED => open,     -- 1-bit output: DCM_SP Lock Output
      PSDONE => open,     -- 1-bit output: Phase shift done output
      STATUS => open,     -- 8-bit output: DCM_SP status output
      CLKFB => CLK_50,       -- 1-bit input: Clock feedback input
      CLKIN => CLK_50MHZ,       -- 1-bit input: Clock input
      DSSEN => '0',       -- 1-bit input: Unsupported, specify to GND.
      PSCLK => '0',       -- 1-bit input: Phase shift clock input
      PSEN => '0',         -- 1-bit input: Phase shift enable
      PSINCDEC => '0', -- 1-bit input: Phase shift increment/decrement input
      RST => '0'            -- 1-bit input: Active high reset input
   );

   -- End of DCM_SP_inst instantiation
				





--Conexiones de se�ales VGA  !!! SI NO SE USA METERLO EN EL PORT MAP!!!
v_sync <=  vertical_sinc;
h_sync <=  horizontal_sinc;
led_1 <=  led_debug;
led_2 <=  not pwdn_camara;--NOT config_terminada;



--- Mapeo el controlador VGA
VGA_cont : vga_controller PORT MAP(
		
		--pixel_clk	=> PX_clk,	--pixel clock at frequency of VGA mode being used
		pixel_clk 	=> CLK_25, --- (Debo revisar si funciona el VGA a 50 MHz)
		reset_n		=> '0',--reset_negado,
		h_sync		=> horizontal_sinc,
		v_sync		=> vertical_sinc,
		disp_ena		=> disp_ena,
		column		=> columna,
		row			=> fila,
		n_blank		=> n_blank,
		n_sync		=> n_sync
		); --sync-on-green output to DAC
--END COMPONENT;

IMAGEN_cont : hw_image_generator PORT MAP(
		
		activa_imagen => activa_imagen,
		DO_ram_red		=> DO_ram_red,
		DO_ram_green		=> DO_ram_green,
		DO_ram_blue	=> DO_ram_blue,
		disp_ena		=> disp_ena,
		column		=> columna,
		row			=> fila,
		red      	=> RED,
		green    	=> GREEN,
		blue    		=> BLUE); 
--END COMPONENT;


Inst_ov7670_controller : ov7670_controller
port map(
				clk   => CLK_25,
				resend => sw3_pulsado,
				config_finished => config_terminada,
				sioc	=> ov7670_sioc,
				siod  => ov7670_siod,
				reset => ov7670_reset,
				pwdn  => ov7670_pwdn,
				desactivo => pwdn_camara,
				xclk  => ov7670_xclk
);



Inst_ov7670_capture :ov7670_capture
port map(
				pclk	=> ov7670_pclk_buf,--ov7670_pclk,
				vsync => ov7670_vsync_debounced,
				href  => ov7670_href_debounced,
				d		=> ov7670_data,
				addr	=> ADDR_b,
				dout	=> bus_datos_b,
				we		=> signal_we_b
);




--Cambio de direccion (nuevo pixel)
process( CLK_25 )--La ram se encarga de sincronizar con el clock

begin



	if rising_edge(CLK_25) then 
			if activa_imagen='1' then
				ADDR <= ADDR +1;
			
			elsif(vertical_sinc = '0') then
			
			ADDR <= (others => '0');
			end if;
			
	end if;


end process;


process (ADDR_b)

begin
		
		if (ADDR_b = 7000) then
				
			led_debug <= NOT led_debug;
			
		end if;
		


end process;

process (reset_debounce)

begin
		
		if (rising_edge(reset_debounce) ) then
				
			valor_debounce <= valor_debounce +1;
			
		end if;
		


end process;

process (sw3_debounce)

begin
		
		if (rising_edge(sw3_debounce) ) then
				
			pwdn_camara <= not pwdn_camara;
			
		end if;
		


end process;	
	
	
end Behavioral;

