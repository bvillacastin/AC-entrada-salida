* Proyecto arquitectura 2024: Borja Pérez-Villacastín Palacín (190395), Fernando Luna Marcuello (190394)

* Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000             *Pila
        DC.L    INICIO            *PC

* Definicion de equivalencias
*********************************
        ORG     $400
MR1A    EQU     $effc01           *De modo A (escritura)
MR2A    EQU     $effc01           *De modo A (2� escritura)
SRA     EQU     $effc03           *De estado A (lectura)
CSRA    EQU     $effc03           *De seleccion de reloj A (escritura)
CRA     EQU     $effc05           *De control A (escritura)
TBA     EQU     $effc07           *Buffer transmision A (escritura)
RBA     EQU     $effc07           *Buffer recepcion A  (lectura)
ACR	EQU	$effc09	          *De control auxiliar
IMR     EQU     $effc0B           *De mascara de interrupcion A (escritura)
ISR     EQU     $effc0B           *De estado de interrupcion A (lectura)
MR1B    EQU     $effc11           *De modo B (escritura)
MR2B    EQU     $effc11           *De modo B (2 escritura)
CRB     EQU     $effc15	          *De control A (escritura)
TBB     EQU     $effc17           *Buffer transmision B (escritura)
RBB	EQU	$effc17           *Buffer recepcion B (lectura)
SRB     EQU     $effc13           *De estado B (lectura)
CSRB	EQU	$effc13           *De seleccion de reloj B (escritura)
IVR     EQU     $EFFC19           *Registro de vector de interrupción
CIMR 	DS.B    1                 *Copia del registro de mascara de interrupcion

*************************** INIT **************************************************************************
INIT    MOVE.B  #%00010000,CRA    *Reiniciamos puntero a Registro de Modo 1 Linea A
        MOVE.B  #%00010000,CRB    *Reiniciamos puntero a Registro de Modo 1 Linea B
        MOVE.B  #%00000011,MR1A   *Establecemos 8 bits por caracter Linea A
        MOVE.B  #%00000011,MR1B   *Establecemos 8 bits por caracter Linea A
        MOVE.B  #%00000000,MR2A   *Modo de operacion Normal Linea A (No Eco)
        MOVE.B  #%00000000,MR2B   *Modo de operacion Normal Linea B (No Eco)
        MOVE.B  #%11001100,CSRA   *Establecemos velocidades Linea A (38400bps)
        MOVE.B  #%11001100,CSRB   *Establecemos velocidades Linea B (38400bps)
        MOVE.B  #%00000000,ACR    *Establecemos Conjunto 0 para Registros de Seleccion de Reloj A y B
        MOVE.B  #%00010101,CRA    *Transmision y recepcion activados Linea A
        MOVE.B  #%00010101,CRB    *Transmision y recepcion activados Linea B
        MOVE.B  #%00100010,CIMR   *Habilitamos Recepcion Linea A y B en la copia de Mascara de Interrupcion 
        MOVE.B  CIMR,IMR          *Pasamos la copia a la propia Mascara de Interrupcion
        MOVE.B  #$40,IVR          *Establecemos el Registro de Vector de Interrupcion como 40 en hexadecimal
        MOVE.L  #RTI,$100         *Ponemos la direcion de RTI en la tabla de vectores de excepcion
        BSR     INI_BUFS          *Inicializamos bufferes
        RTS                       *Retorno de subrutina
*************************** FIN INIT **********************************************************************
*************************** SCAN(Buffer, Descriptor, Tamaño) **********************************************
SCAN  	LINK A6,#0                *Creamos el marco de pila
        MOVEM.L A0/D1-D2,-(A7)    *Guardamos en pila el contenido de los registros que vamos a utilizar
        CLR.L D0                  *Limpiamos el contenido de los registros
        MOVE.W 14(A6),D1    	  *Carga tamaNo en D1
        MOVE.W 12(A6),D2          *Carga Descriptor en D2
        MOVE.L 8(A6),A0           *Carga dir del Buffer en A0
        CMP.W #1,D2               *Comparamos para ver si descriptor incorrecto
        BGT ERRSC                 *Si Descriptor>1 saltamos a Error
        CMP.W #0,D2               *Comparamos para ver si descriptor incorrecto
        BLT ERRSC                 *Si Descriptor<0 saltamos a Error
        CMP.W #0,D1               *Comparamos para ver si tamano incorrecto
        BLT ERRSC                 *Si TamaNo<0 saltamos a Error
        BEQ FINSC                 *Si TamaNo==0 vamos al final de la subrutina
BUCSC	CMP.W #0,D1               *Comparacion para fin de bucle
        BEQ FBUCSC                *Salimos del bucle si el TamaNo==0
        EOR.L D0,D0               *Limpiamos D0
        MOVE.W D2,D0              *Cargamos descriptor en D0
        BSR LEECAR                *Llamamos a LEECAR para que nos devuelva en D0 el caracter
        CMP.L #$FFFFFFFF,D0       *Vemos si LEECAR ha leido algun caracter              
        BEQ FBUCSC                *Si no ha leido caracter salimos del bucle
        SUB.W #1,D1               *Decrementamos el Tamano
        MOVE.B D0,(A0)+           *Caracter-->(Buffer), Buffer+1
        BRA BUCSC                 *Saltamos comienzo bucle
FBUCSC  EOR.L D0,D0               *Limpiamos D0. Puede que LEECAR haya devuelto 0xffffffff
        MOVE.W 14(A6),D0          *Carga tamaNo en D0
        SUB.W D1,D0               *TamanoOriginal - TamanoRestante = NumCarLeidos     
        BRA FINSC                 *Saltamos al final de la subrutina
ERRSC	MOVE.L #$FFFFFFFF,D0      *Si ha habido algun error en los parametros de entrada cargamos 0xffffffff en D0
FINSC	MOVEM.L (A7)+,A0/D1-D2    *Restauramos los valores de los registros previos a la llamada de la subrutina
        UNLK A6                   *Destruimos el marco de pila
        RTS                       *Retorno de subrutina
*************************** FIN SCAN **********************************************************************
*************************** PRINT *************************************************************************
PRINT 	LINK A6,#0                *Creamos el marco de pila
        MOVEM.L A0/D1-D3,-(A7)    *Guardamos en pila el contenido de los registros que vamos a utilizar
        CLR.L D0                  *Limpiamos el contenido de los registros
        MOVE.W 14(A6),D3          *Carga TamaNo en D3
        MOVE.W 12(A6),D2          *Carga Descriptor en D2
        MOVE.L 8(A6),A0           *Carga dir del Buffer en A0
        CMP.W #1,D2               *Comparamos para ver si descriptor incorrecto
        BGT ERRPR		  *Si Descriptor>1 saltamos a Error
        CMP.W #0,D2               *Comparamos para ver si descriptor incorrecto
        BLT ERRPR                 *Si Descriptor<0 saltamos a Error
        ADD.W #2,D2               *Anadimos 2 al descriptror para que escriba en buffer transmision de la correspondiente linea
        CMP.W #0,D3               *Comparamos para ver si Tamano incorrecto o 0
        BLT ERRPR                 *Si TamaNo<0 saltamos a Error
        BEQ FINPR                 *Si TamaNo==0 vamos al final de la subrutina
BPR	CMP.W #0,D3               *Comparacion para fin de bucle
        BEQ FBPR                  *Salimos del bucle si el TamaNo==0
        MOVE.W D2,D0              *Cargamos Descriptor en D0               
        MOVE.B (A0),D1            *(Buffer)-->D1 , llevamos el caracter a D1 para que lo utilize ESCCAR
        CMP.B #0,D1               *Comprobamos si el caracter es nulo
        BEQ FBPR                  *Si es nulo salimos del bucle
        BSR ESCCAR                *Llamamos a ESCCAR 
        CMP.L #$FFFFFFFF,D0       *Vemos si ESCCAR ha escrito algun caracter
        BEQ FBPR                  *Si no ha escrito caracter salimos del bucle
        SUB.W #1,D3               *Decrementamos el TamaNo
        ADD.W #1,A0               *Movemos puntero Buffer
        BRA BPR                   *Saltamos comienzo bucle
FBPR    EOR.L D0,D0               *Limpiamos D0. Puede que ESCCAR haya devuelto 0xffffffff
        MOVE.W 14(A6),D0   	  *Carga tamaNo en D1
        SUB.W D3,D0           	  *TamanoOriginal - TamanoRestante = NumCarEscritos 
        CMP.W #0,D0               *Vemos si hemos escrito caracteres
        BEQ FINPR                 *Si no hemos escrito caracteres salimos
        CMP.W #3,D2               *Hemos escrito caracteres. Vemos en que linea debemos activar la transmision
        BEQ TRNSB                 *Saltamos para activar la transmision de B o de lo contrario seguimos para activar A
TRNSA 	BSET #0,CIMR              *Activamos bit de transmision de A en la copia de la Mascara de Interrupcion
        BRA TINT                  *Saltamos para no activar B tambien
TRNSB	BSET #4,CIMR              *Activamos bit de transmision de B en la copia de la Mascara de Interrupcion
TINT	MOVE.W  SR,D1             *Guardamos el Registro de Estado actual     
        MOVE.W  #$2700,SR         *Deshabilitamos las interrupciones
        MOVE.B  CIMR,IMR          *Pasamos la copia de la macara que hemos editado a la Mascara de Interrupcion
        MOVE.W  D1,SR             *Restauramos el Registro de Estado
        BRA     FINPR             *Saltamos al final de la subrutina
ERRPR	MOVE.L #$FFFFFFFF,D0      *Si ha habido algun error en los parametros de entrada cargamos 0xffffffff en D0
FINPR	MOVEM.L (A7)+,A0/D1-D3    *Restauramos los valores de los registros previos a la llamada de la subrutina
        UNLK A6                   *Destruimos el marco de pila
        RTS                       *Retorno de subrutina
*************************** FIN PRINT ********************************************************
*************************** RTI **************************************************************
RTI	MOVE.L D0,-(A7)           *Guardamos registros D0 y D1 en pila para poder alterar su contenido
        MOVE.L D1,-(A7)
BUCRTI	MOVE.B ISR,D0             *Cargamos ISR en D0
        AND.B  CIMR,D0            *Lo unimos con la Mascara de Interrupcion para ver que que interrupciones tenemos que tratar
TRDYA	BTST #0,D0                *Si bit de TxREADY A a 0 salta a comprobar bit RxREADY A0
        BEQ RRDYA                 *Si no salta, comenzamos a tratar la interrupcion de transmision por la linea A
        MOVE.L  #2,D0             *Cargamos un dos como descriptor en D0 (Buffer de transmision de A)
        BSR     LEECAR            *LLamamos a LEECAR
        CMP.L   #$FFFFFFFF,D0     *Vemos si ha leido caracter
        BNE     NOULTA            *Si ha leido caracter salta
        BCLR    #0,CIMR           *Desactivamos bit de transmision de A en la copia de la Mascara de Interrupcion
        MOVE.B  CIMR,IMR          *Pasamos la copia de la macara que hemos editado a la Mascara de Interrupcion
        BRA     BUCRTI            *Saltamos al bucle de RTI para comprobar si hay interrupciones activas
NOULTA  MOVE.B  D0,TBA            *Si ha leido caracter lo movemos al Registro de Transmision de A
        BRA     BUCRTI            *Saltamos al bucle de RTI para comprobar si hay interrupciones activas
                
RRDYA	BTST #1,D0                *Si bit de RxREADY A a 0 salta a comprobar bit TxREADY B
        BEQ TRDYB                 *Si no salta, comenzamos a tratar la interrupcion de recepcion por la linea A
        MOVE.B  RBA,D1            *Cargamos en D1 un caracter del Registro de Recepcion de A
        MOVE.L  #0,D0             *Cargamos en D0 un 0 como descrriptor
        BSR     ESCCAR            *LLamamos a ESCCAR
        BRA     BUCRTI            *Saltamos al bucle de RTI para comprobar si hay interrupciones activas
                
TRDYB	BTST #4,D0                *Si bit de TxREADY B a 0 salta a comprobar bit RxREADY B
        BEQ RRDYB                 *Si no salta, comenzamos a tratar la interrupcion de transmision por la linea B
        MOVE.L  #3,D0             *Cargamos un dos como descriptor en D0 (Buffer de transmision de B)
        BSR     LEECAR            *LLamamos a LEECAR
        CMP.L   #$FFFFFFFF,D0     *Vemos si ha leido caracter
        BNE     NOULTB            *Si ha leido caracter salta
        BCLR    #4,CIMR           *Desactivamos bit de transmision de B en la copia de la Mascara de Interrupcion
        MOVE.B  CIMR,IMR          *Pasamos la copia de la macara que hemos editado a la Mascara de Interrupcion
        BRA     BUCRTI            *Saltamos al bucle de RTI para comprobar si hay interrupciones activas
NOULTB  MOVE.B  D0,TBB            *Si ha leido caracter lo movemos al Registro de Transmision de B
        BRA     BUCRTI            *Saltamos al bucle de RTI para comprobar si hay interrupciones activas
                
RRDYB	BTST #5,D0                *Si bit de RxREADY B a 0 salta al final de RTI
        BEQ FINRTI                *Si no salta, comenzamos a tratar la interrupcion de recepcion por la linea B
        MOVE.B  RBB,D1            *Cargamos en D1 un caracter del Registro de Recepcion de B
        MOVE.L  #1,D0             *Cargamos en D0 un 1 como descrriptor
        BSR     ESCCAR            *LLamamos a ESCCAR
        BRA     BUCRTI            *Saltamos al bucle de RTI para comprobar si hay interrupciones activas
                
FINRTI	MOVE.L (A7)+,D1           *Recuperamos el valor de los registros que habiamos guardado en pila
        MOVE.L (A7)+,D0
        RTE                       *Fin rutina de tratamiento de excepcion 
**************************** FIN RTI ***************************************************
**************************** PROGRAMA PRINCIPAL **********************************************
BUFFER: DS.B 2100 * Buffer para lectura y escritura de caracteres
PARDIR: DC.L 0 * Direccion que se pasa como parametro
PARTAM: DC.W 0 * Tama~no que se pasa como parametro
CONTC: DC.W 0 * Contador de caracteres a imprimir
DESA: EQU 0 * Descriptor lınea A
DESB: EQU 1 * Descriptor lınea B
TAMBS: EQU 30 * Tama~no de bloque para SCAN
TAMBP: EQU 7 * Tama~no de bloque para PRINT

* Manejadores de excepciones
INICIO: MOVE.L #BUS_ERROR,8 * Bus error handler
        MOVE.L #ADDRESS_ER,12 * Address error handler
        MOVE.L #ILLEGAL_IN,16 * Illegal instruction handler
        MOVE.L #PRIV_VIOLT,32 * Privilege violation handler
        MOVE.L #ILLEGAL_IN,40 * Illegal instruction handler
        MOVE.L #ILLEGAL_IN,44 * Illegal instruction handler
        BSR INIT
        MOVE.W #$2000,SR * Permite interrupciones
BUCPR: MOVE.W #TAMBS,PARTAM * Inicializa parametro de tama~no
        MOVE.L #BUFFER,PARDIR * Parametro BUFFER = comienzo del buffer
OTRAL: MOVE.W PARTAM,-(A7) * Tama~no de bloque
        MOVE.W #DESA,-(A7) * Puerto A
        MOVE.L PARDIR,-(A7) * Direccion de lectura
ESPL: BSR SCAN
        ADD.L #8,A7 * Restablece la pila
        ADD.L D0,PARDIR * Calcula la nueva direccion de lectura
        SUB.W D0,PARTAM * Actualiza el numero de caracteres leıdos
        BNE OTRAL * Si no se han leıdo todas los caracteres del bloque se vuelve a leer
        MOVE.W #TAMBS,CONTC * Inicializa contador de caracteres a imprimir
        MOVE.L #BUFFER,PARDIR * Parametro BUFFER = comienzo del buffer
OTRAE: MOVE.W #TAMBP,PARTAM * Tama~no de escritura = Tama~no de bloque
ESPE:  MOVE.W PARTAM,-(A7) * Tama~no de escritura
        MOVE.W #DESB,-(A7) * Puerto B
        MOVE.L PARDIR,-(A7) * Direccion de escritura
        BSR PRINT
        ADD.L #8,A7 * Restablece la pila
        ADD.L D0,PARDIR * Calcula la nueva direccion del buffer
        SUB.W D0,CONTC * Actualiza el contador de caracteres
        BEQ SALIR * Si no quedan caracteres se acaba
        SUB.W D0,PARTAM * Actualiza el tama~no de escritura
        BNE ESPE * Si no se ha escrito todo el bloque se insiste
        CMP.W #TAMBP,CONTC * Si el no de caracteres que quedan es menor que el tama~no establecido se imprime ese numero
        BHI OTRAE * Siguiente bloque
        MOVE.W CONTC,PARTAM
        BRA ESPE * Siguiente bloque
SALIR:  BRA BUCPR
BUS_ERROR: 
        BREAK * Bus error handler
        NOP
ADDRESS_ER: 
        BREAK * Address error handler
        NOP
ILLEGAL_IN: 
        BREAK * Illegal instruction handler
        NOP
PRIV_VIOLT: 
        BREAK * Privilege violation handler
        NOP

**************************** FIN PROGRAMA PRINCIPAL ******************************************
INCLUDE bib_aux.s

