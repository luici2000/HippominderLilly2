//*******************************************************************************


// HIPPOMINDER

// 02.06.2006

// Erstellt von Avisaro AG im Auftrag von Roboterwerk Hubrich

// (c)2006 Roboterwerk Hubrich


//******************************************************************************

// Revision:  1.1 - normal time: wenn #define TESTZEIT auskommentiert

// Date: 23.11.2006

// Status: DRAFT

//******************************************************************************


// Revision 1.1
// neu: LED wird beim Display Test auch eingeschaltet

// Revision 1.0
// neu: Rosen fangen bei 1 Uhr an
// Test Mode (drücken aller 4 Tasten)
// Versionsnummeranzeige (drücken der oben und unten Tasten gleichzeitig)
// Batteriemessung
// Symbole blinken nicht bei Alarm (nur die Glocke)



// Known Bugs:
// * keine


// Offene Punkte:
// * keine

//#define TESTZEIT

#include  <msp430xG43x.h>


// Wartezeit, um das Display zurück zusezten
#define TIME_FOR_DISPLAY_RESET  15                  // in Sekunden

#define BLINK_ON_OFF            blink_onoff < 0x02


char* LCD = LCDMEM;			// Set LCD address to LCDMEM vector
unsigned char status = 0;
unsigned int selected = 0;              // ausgewählte Rose
unsigned long blink_onoff;

unsigned char key_pferd;
unsigned char key_up;
unsigned char key_down;
unsigned char key_enter;

const unsigned int dwm_index[] = {0, 1, 7, 30};    // zur multiplizieren

unsigned long timer;
unsigned long timer_sec = 0;
unsigned int  timer_reset_display = 0;
unsigned char led_on_off;


struct rose_t
{
  unsigned int zeit;
  unsigned int limit;
  unsigned int dwm;
  unsigned int time_over;
};

struct rose_t rose[4];


#define KEY_PFERD (P6IN & 0x01)
#define KEY_UP (P2IN & 0x01)
#define KEY_DOWN (P6IN & 0x02)
#define KEY_ENTER (P6IN & 0x04)

#define S_SELECT_ROSE 41
#define S_SELECT_DWM  42
#define S_SELECT_DIGI 43

#define HUF 1
#define IMPF 2
#define WURM 3



//                                           1     2     3     4     5     6     7     8     9   , 10  , 11  , 12
//const unsigned char rose_1_index[] = { 0,    1,    1   , 1   , 0,    0   , 0   , 2   , 2   , 2   , 1   , 1   , 1    };
//const unsigned char rose_1_oder[] =  { 0x00, 0x04, 0x02, 0x01, 0x10, 0x20, 0x40, 0x01, 0x04, 0x02, 0x40, 0x20, 0x10 };

//                                                2     3     4     5     6     7     8     9   , 10  , 11  , 12   ,1
const unsigned char rose_1_index[] = { 0,         1   , 1   , 0,    0   , 0   , 2   , 2   , 2   , 1   , 1   , 1   ,1 };
const unsigned char rose_1_oder[] =  { 0x00,       0x02, 0x01, 0x10, 0x20, 0x40, 0x01, 0x04, 0x02, 0x40, 0x20, 0x10,0x04 };


void rose_1(unsigned int segment);

void rose_1(unsigned int segment)
{

  if ((segment > 0) && (segment < 13))
    {
      LCD[rose_1_index[segment]] |= rose_1_oder[segment];
    }
  else
    switch (segment)
    {
    case 0:
      LCD[0] |= 0x02;                           // Hufeisen
      break;
    case 13:              // Mittelpunkt set
      LCD[0] |= 0x04;
      break;
    case 14:              // Mittelpunkt clear
      LCD[0] &= 0xFB;
      break;
    case 15:
      LCD[0] |= 0x02;                           // Hufeisen
    break;

    case 0xFF:            // clear

      LCD[0] = 0x01;                           // Rose A Kranz

      LCD[1] = 0;
      LCD[2] &= 0xF0;
      break;

    default:
      break;
    } // switch

}


//                                               2     3     4     5     6     7     8     9   , 10  , 11  , 12  ,1
const unsigned char rose_2_index[] = { 0,        3   , 3   , 3,    3   , 3   , 4   , 4   , 4   , 4   , 4   , 4   ,3 };
const unsigned char rose_2_oder[] =  { 0x00,     0x20, 0x10, 0x01, 0x02, 0x04, 0x10, 0x40, 0x20, 0x04, 0x02, 0x01, 0x40 };

void rose_2(unsigned int segment);

void rose_2(unsigned int segment)
{

  if ((segment > 0) && (segment < 13))
  {
    LCD[rose_2_index[segment]] |= rose_2_oder[segment];
    //LCD[2] |= 0x20;                           // Spritze
  }
  else

  switch (segment)
  {
  case 0:
    LCD[2] |= 0x20;                           // Spritze
    break;
  case 13:              // Mittelpunkt set
    LCD[2] |= 0x40;
    break;
  case 14:              // Mittelpunkt clear
    LCD[2] &= 0xBF;
    break;
  case 15:
    LCD[2] |= 0x20;                           // Spritze
    break;

  case 0xFF:            // clear

    LCD[2] &= 0x0F; // löschen und ...

    LCD[2] |= 0x10;                           // Rose B

    LCD[3] = 0;
    LCD[4] = 0;

    break;

  default:
    break;
  }

}

//                                              2     3     4     5     6     7     8     9   , 10  , 11  , 12  , 1
const unsigned char rose_3_index[] = { 0,       6   , 6   , 5,    5   , 5   , 7   , 7   , 7   , 6   , 6   , 6   , 6 };
const unsigned char rose_3_oder[] =  { 0x00,    0x02, 0x01, 0x10, 0x20, 0x40, 0x01, 0x04, 0x02, 0x40, 0x20, 0x10, 0x04 };


void rose_3(unsigned int segment);

void rose_3(unsigned int segment)
{

  if ((segment > 0) && (segment < 13))
  {
    LCD[rose_3_index[segment]] |= rose_3_oder[segment];
  }
  else

  switch (segment)
  {
  case 0:
    LCD[5] |= 0x02;                           // Wurm
    break;
  case 13:              // Mittelpunkt set
    LCD[5] |= 0x04;
    break;
  case 14:              // Mittelpunkt clear
    LCD[5] &= 0xFB;
    break;
  case 15:
    LCD[5] |= 0x02;                           // Wurm
    break;
  case 0xFF:            // clear

    LCD[5] = 0x01; // Rose C

    LCD[6] = 0;
    LCD[7] &= 0xF0;

    break;

  default:
    break;
  }

}


void number_h(unsigned int segment);      // high number

void number_h(unsigned int segment)
{
  switch (segment)
  {
      // führende nullen werden nicht dargestellt .. doch
    case 0:
    LCD[8] |= 0x10; // | 0x40 | 0x04 | 0x02;  // 1A
    LCD[9] |= 0x02; // | 0x04;  // 1B
    LCD[9] |= 0x04;  // 1C
    LCD[8] |= 0x40;  // 1D
    LCD[8] |= 0x04;  // 1E
    LCD[8] |= 0x02;  // 1F

    break;

  case 1:
    LCD[9] |= 0x02;  // 1B
    LCD[9] |= 0x04;  // 1C
    break;
  case 2:
    LCD[8] |= 0x10;  // 1A
    LCD[9] |= 0x02;  // 1B
    LCD[8] |= 0x20;  // 1G
    LCD[8] |= 0x04;  // 1E
    LCD[8] |= 0x40;  // 1D
    break;
  case 3:
    LCD[8] |= 0x10;  // 1A
    LCD[9] |= 0x02;  // 1B
    LCD[9] |= 0x04;  // 1C
    LCD[8] |= 0x40;  // 1D
    LCD[8] |= 0x20;  // 1G

    break;
  case 4:
    LCD[9] |= 0x02;  // 1B
    LCD[9] |= 0x04;  // 1C
    LCD[8] |= 0x02;  // 1F
    LCD[8] |= 0x20;  // 1G

    break;
  case 5:
    LCD[8] |= 0x10;  // 1A
    LCD[9] |= 0x04;  // 1C
    LCD[8] |= 0x40;  // 1D
    LCD[8] |= 0x02;  // 1F
    LCD[8] |= 0x20;  // 1G

    break;
  case 6:
    LCD[8] |= 0x10;  // 1A
    LCD[9] |= 0x04;  // 1C
    LCD[8] |= 0x40;  // 1D
    LCD[8] |= 0x04;  // 1E
    LCD[8] |= 0x02;  // 1F
    LCD[8] |= 0x20;  // 1G

    break;
  case 7:
    LCD[8] |= 0x10;  // 1A
    LCD[9] |= 0x02;  // 1B
    LCD[9] |= 0x04;  // 1C

    break;
  case 8:
    LCD[8] |= 0x10;  // 1A
    LCD[9] |= 0x02;  // 1B
    LCD[9] |= 0x04;  // 1C
    LCD[8] |= 0x40;  // 1D
    LCD[8] |= 0x04;  // 1E
    LCD[8] |= 0x02;  // 1F
    LCD[8] |= 0x20;  // 1G
    break;
  case 9:
    LCD[8] |= 0x10;  // 1A
    LCD[9] |= 0x02;  // 1B
    LCD[9] |= 0x04;  // 1C
    LCD[8] |= 0x40;  // 1D
    LCD[8] |= 0x02;  // 1F
    LCD[8] |= 0x20;  // 1G

    break;

  case 0xFF:            // clear
  default:

    LCD[8] &= 0x01;
    LCD[9] &= 0xF1;

    break;
  }

}

void number_l(unsigned int segment);      // high number

void number_l(unsigned int segment)
{
  switch (segment)
  {
  case 0:
    LCD[10] |= 0x01 ;  // 2A
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x40;  // 2C
    LCD[10] |= 0x04;  // 2D
    LCD[9] |= 0x40;  // 2E
    LCD[9] |= 0x20;  // 2F

    break;
  case 1:
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x40;  // 2C

    break;
  case 2:
    LCD[10] |= 0x01;  // 2A
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x04;  // 2D
    LCD[9] |= 0x40;  // 2E
    LCD[10] |= 0x02;  // 2G
    break;
  case 3:
    LCD[10] |= 0x01;  // 2A
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x40;  // 2C
    LCD[10] |= 0x04;  // 2D
    LCD[10] |= 0x02;  // 2G

    break;
  case 4:
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x40;  // 2C
    LCD[9] |= 0x20;  // 2F
    LCD[10] |= 0x02;  // 2G

    break;
  case 5:
    LCD[10] |= 0x01;  // 2A
    LCD[10] |= 0x40;  // 2C
    LCD[10] |= 0x04;  // 2D
    LCD[9] |= 0x20;  // 2F
    LCD[10] |= 0x02;  // 2G

    break;
  case 6:
    LCD[10] |= 0x01;  // 2A
    LCD[10] |= 0x40;  // 2C
    LCD[10] |= 0x04;  // 2D
    LCD[9] |= 0x40;  // 2E
    LCD[9] |= 0x20;  // 2F
    LCD[10] |= 0x02;  // 2G
    break;
  case 7:
    LCD[10] |= 0x01;  // 2A
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x40;  // 2C
    break;
  case 8:
    LCD[10] |= 0x01;  // 2A
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x40;  // 2C
    LCD[10] |= 0x04;  // 2D
    LCD[9] |= 0x40;  // 2E
    LCD[9] |= 0x20;  // 2F
    LCD[10] |= 0x02;  // 2G
    break;
  case 9:
    LCD[10] |= 0x01;  // 2A
    LCD[10] |= 0x20;  // 2B
    LCD[10] |= 0x40;  // 2C
    LCD[10] |= 0x04;  // 2D
    LCD[9] |= 0x20;  // 2F
    LCD[10] |= 0x02;  // 2G

    break;
  case 0xFF:            // clear
  default:

    LCD[9] &= 0x01F;
    LCD[10] &= 0x10;

    break;
  }

}

void alarm(unsigned int segment);      // high number

void alarm(unsigned int segment)
{
  if (segment == 0)
  {
    LCD[11] &=  0xFE;

  }
  else
  {
    LCD[11] |= 0x01;
  }
}

void dwm(unsigned int segment);      // high number

void dwm(unsigned int segment)
{
  if (segment == 0)     // clear
  {
    LCD[9] &=  0xEE;
    LCD[10] &=  0xEF;
    //LCD[8] &= 0xFE;
  }
  if (segment == 1)     // d
  {
    LCD[9] |= 0x01;
  }
  if (segment == 2)     // w
  {
    LCD[9] |= 0x10;
  }
  if (segment == 3)     // m
  {
    LCD[10] |= 0x10;
  }
  /*
  if (segment == 4)     // Batterie
  {
    LCD[8] |= 0x01;

  }
  */
}

void plusminus(unsigned int segment);      // high number

void plusminus(unsigned int segment)
{
  if (segment == 0)
  {
    LCD[7] &=  0x0F;
  }
  if (segment == 1)     // +
  {
    LCD[7] |= 0x10;
    LCD[7] |= 0x20;
    LCD[7] |= 0x40;
  }
  if (segment == 2)      // -
  {
    LCD[7] |= 0x20;
  }


}

void display_rose(void (*rose_123)(unsigned int), unsigned int *zeit, unsigned int *over, unsigned int limit, unsigned int dwm, unsigned int this_rose);

void display_rose(void (*rose_123)(unsigned int), unsigned int *zeit, unsigned int *over, unsigned int limit, unsigned int dwm, unsigned int this_rose)
{
  unsigned int n;
  unsigned int limit_new;

  rose_123(0xFF);   // clear

  if (! ((limit == 99) && (dwm == 3)))
  {
  if (status == 0)    // normaler Modus
  {
    if ((selected == this_rose) && (status == 0))
    {
      rose_123(13);      // if selected set Mittelpunkt
      rose_123(15);      // ... und Symbol
    }
    if (timer_sec == 0)     // ein Zählimpuls (ein Tag ist um)
    {
      if ((*zeit) > 0)
        *zeit = (*zeit) - 1;
      else if ((*over) < 0xFFF)
        *over = (*over) +1;
    }

    limit_new = ((limit * dwm_index[dwm]) - (*zeit)) * 12;

    limit_new = (limit_new / (limit * dwm_index[dwm]) ) ;

// Symbol immer an    if ( ((*zeit) > 0) ||
// Symbol immer an         ( ((*zeit) == 0) && (BLINK_ON_OFF) ))
  //         ( ((*zeit) == 0) && (BLINK_ON_OFF) && (selected == 0)) ||
  //         ( (selected > 0) && (selected == this_rose) && (BLINK_ON_OFF) )  )

      {
          rose_123(0);   // Symbol blinken lassen
      }

      for (n = 1; n <= (limit_new ) ; n++)
      {
          rose_123(n);
      }

  }
  else            // Einstellungsmodus
  {
    if (selected == this_rose)      // die selectierte Rose ausmalen
    {
      rose_123(13); // or blink
      rose_123(15); // entsprechendes Symbol malen
      for (n = 0; n <= 12 ; n++)
      {
          rose_123(n);
      }
    }


  }
} // 99
}


void select_dwm (unsigned int *dwm_select);

void select_dwm (unsigned int *dwm_select)
{
  if (key_up == 0x01)
    *dwm_select = *dwm_select + 1;
  else
    *dwm_select = *dwm_select - 1;

  if (*dwm_select > 3) *dwm_select = 1;
  if (*dwm_select == 0) *dwm_select = 3;
  dwm( (*dwm_select) );

}

void select_digit (unsigned int *limit);
void select_digit (unsigned int *limit)
{

  if (key_up == 0x01)
    *limit = *limit + 1;
  else
    *limit = *limit - 1;

  if (*limit > 99) *limit = 1;
  if (*limit == 0) *limit = 99;
  number_h((*limit) / 10);
  number_l((*limit) % 10);

}


// Interrupt Routinen


// WDT Interrupt Service Routine
// WDT_ISR(isrWDT)
#pragma vector=WDT_VECTOR
__interrupt void isrWDT(void)
{
  LPM3_EXIT;                                    // Exit out of LPM0
}

// PORT2 Interrupt Service Routine
#pragma vector=PORT2_VECTOR
__interrupt void isrPORT2(void)
{
  LPM3_EXIT;
}


#pragma dataseg = INFOA                         // Info Flash Memory Block A
__no_init static int flash_valid;
__no_init static struct rose_t f_rose[4];          // Dauerspeicher für Limits
#pragma dataseg = default

void StoreInFlash(void);

void StoreInFlash(void)
{
  unsigned int i;
  FCTL2 = FWKEY + FSSEL1 + FN1;                 // SMCLK/3 = ~333kHz
  FCTL3 = FWKEY;                                // Clear LOCK
  FCTL1 = FWKEY + ERASE;                        // Enable segment erase
  *(unsigned int *)0x1080 = 0;                  // Dummy write, erase info A
  FCTL1 = FWKEY + WRT;                          // Enable write
  flash_valid = 0xAA;                           // Flag, dass Flash Variablen valide sind
  for (i=0; i<4;i++)
  {
    f_rose[i].zeit = rose[i].zeit;
    f_rose[i].limit = rose[i].limit;
    f_rose[i].dwm = rose[i].dwm;
    f_rose[i].time_over = rose[i].time_over;
  }

  FCTL1 = FWKEY;                                // Done. Clear WRT
  FCTL3 = FWKEY + LOCK;                         // Done. Set LOCK
}





/*************************************************************************************************/

void main(void)
{
  volatile unsigned int i;                  // Use volatile to prevent removal
  unsigned char key_pressed =0;
  unsigned char led_off =0;
  unsigned int temp;

  if (flash_valid != 0xaa)          // das Information-Flash wurde noch nicht gültig beschrieben
                                    // bzw. es wurde geflashed
  {

    // Hufe: 7 Wochen
    // Wurm 6 Monte
    // Impfl 6 Monate
    // 99 mit DWM verknüpfen

    // preload variables
    rose[HUF].zeit = 7*7-1;
    rose[HUF].limit = 7;
    rose[HUF].dwm = 2;
    rose[IMPF].zeit = 6*30-1;
    rose[IMPF].limit = 6;
    rose[IMPF].dwm = 3;
    rose[WURM].zeit = 6*30-1;
    rose[WURM].limit = 6;
    rose[WURM].dwm = 3;
  } else {
    for (i=0; i<4;i++)
    {
      rose[i].zeit = f_rose[i].zeit;
      rose[i].limit = f_rose[i].limit;
      rose[i].dwm = f_rose[i].dwm;
      rose[i].time_over = f_rose[i].time_over;
    }
  }

  WDTCTL = WDTPW + WDTHOLD;                 // Stop watchdog timer
  //P5DIR |= 0x02;                          // Set P6.2 to output // Set P5.1 to output direction
  WDTCTL = WDT_ADLY_250;                    // Set Watchdog to interval and 250 ms
  IE1 |= WDTIE;                             // Enable Watchdog intterupt


  FLL_CTL0 |= XCAP14PF;                     // Configure load caps
  for (i = 0; i < 10000; i++);              // Delay for 32 kHz crystal to
                                            // stabilize

  LCDCTL = 0x75;                            // 3-Mux LCD, segments S0-S23
  BTCTL  = BT_fLCD_DIV128;                  // LCD clock freq is ACLK/128
  // BTCTL  = BT_fLCD_DIV256;                  // LCD clock freq is ACLK/256
  P5SEL  = 0xFC;                            // Select P5.2-7 as Com and Rxx

  P6DIR = 0x00;                             // Eingang
  P1DIR = 0x20;                             // alles bis auf "OPTION" Eingang
  //P6DIR = 0xFF;


  // Clear LCD memory to clear display
  for (i=0; i<23; i++)
  {
    LCD[i] = 0x00;
  }


  LCD[11] |= 0x04;                          // Hippominder
  LCD[11] |= 0x02;                          // Pferd

  _EINT();                                  // enable global interrupts

while(1)
{

if (status == 0)
  {
    WDTCTL = WDT_ADLY_250;                    // Set Watchdog to interval and 250 ms
    //WDTCTL = WDT_ADLY_1000;                    // Set Watchdog to interval and 1000 ms
    LPM3;                                   // Switch to Low Power Mode
    // Sekunden erzeugen ...
    if (timer < 0x03)
      timer++;
    else
      timer = 0;

    led_on_off++;
    if (led_on_off > 12) led_on_off = 0;

  }
else
  {
    WDTCTL = WDT_ADLY_16;                    // Set Watchdog to interval and 16 ms
    LPM3;                                     // sleep
    // for (temp=0;temp<0xFFF; temp++){}               // so warten (besser auf Tasten reagieren
    // Sekunden erzeugen ...
    if (timer < 0x3E)                         // 1/0,016
      timer++;
    else
      timer = 0;

  }


// Blinkbasis
if (blink_onoff < 0x04)
   blink_onoff++;
else
   blink_onoff = 0;



// alarm LED
if ( ((rose[HUF].zeit == 0) || (rose[IMPF].zeit == 0) || (rose[WURM].zeit == 0)) && ((led_on_off ==0)) && (status == 0) && (led_off != 2))
{
  P1OUT |= 0x20;                    // Set P1.5 LED on
  if (led_off == 0) led_off = 1;
}
else
{
  P1OUT &= ~0x20;                   // Clear P1.5 LED off
}

// alarm
if ( ((rose[HUF].zeit == 0) || (rose[IMPF].zeit == 0) || (rose[WURM].zeit == 0)) && (BLINK_ON_OFF) && (status == 0))
{
  alarm(1);
}
else
  alarm(0);



if (timer == 0)   // zeitimpuls (= 1 Sekunde)
{

#ifdef TESTZEIT
  if (timer_sec < 1)  // hier 'demo modus = 1' oder 'normal = 86400' einstellen
#else
  if (timer_sec < 86400)  // hier 'demo modus = 1' oder 'normal = 86400' einstellen
#endif

  //if (timer_sec < 10)  // hier 'demo modus = 1' oder 'normal = 86400' einstellen
    timer_sec++;          // Anzahl Sekunden
  else
  {
    timer_sec = 0;        // ein Tag is um
    StoreInFlash();

    // Testweise Batteriemessung

    CACTL2 = P2CA1 ; //+ CAF;
    //CAPD = CAPD4;        // Input Buffer disable to conserve power
    temp = 0;     // Zeit messen bis comparator zuschlägt.
    P1DIR |= 0x10;                          // Set P1.4 to output for measurement
    P1OUT |= 0x10;                             // Port einschalten
    //CACTL1 = CARSEL  + CAREF_2 + CAON; // Comparator config und einschalten
    CACTL1 =   CAREF_3 + CAON; // Comparator config und einschalten

    while (((CACTL2 & 0x01) == 1) && (temp < 0xFFFF)) temp++;
    //while ( (temp < 0xFF)) temp++;

    CACTL1 = 0; // alles ausschalten
    P1OUT &= 0xEF; // Port wieder löschen = kondensator entladen

    // ** end Batteriemessung

    if (temp > 68)          // 74 = 2,2V  //    // 55 = 3 V  // 66 = 2,5 V
    {
      LCD[8] |= 0x01;                 // Battsymbol einschalten
    }
    else
    {
      LCD[8] &= 0xFE;         // löschen
    }

    /*
    // Testzwecke den Wert darstellen lassen
    number_h(0xFF);   // clear
    number_l(0xFF);    // clear

    number_h(temp / 10);
    number_l(temp % 10);
    */

  }



  if (timer_reset_display > 0)
  {
    if (timer_reset_display == 1)
    {
      selected = 0;
      status = 0;       // zurück in Leerlauf
      number_h(0xFF);   // clear
      number_l(0xFF);    // clear
      dwm(0);
      plusminus(0);

    }
    timer_reset_display-- ;
  }



  // rose 1, 2, 3
  display_rose(rose_1, &rose[HUF].zeit, &rose[HUF].time_over, rose[HUF].limit, rose[HUF].dwm, HUF);
  display_rose(rose_2, &rose[IMPF].zeit,&rose[IMPF].time_over, rose[IMPF].limit, rose[IMPF].dwm, IMPF);
  display_rose(rose_3, &rose[WURM].zeit,&rose[WURM].time_over, rose[WURM].limit, rose[WURM].dwm, WURM);

}  // zeitimpuls



// Tasteninput  - enprellen
key_pferd =  (KEY_PFERD == 0) ; // wenn 0xFF, dann Taste gedrückt
key_up =  (KEY_UP == 0);
key_down =  (KEY_DOWN == 0);
if (KEY_ENTER != 0)             // clear wenn Taste losgelassen
{
  key_enter = 0;

}
else
{
  if (led_off == 1) led_off = 2;
  key_enter =  (key_enter <<1) | (KEY_ENTER == 0);

}

switch(status)
{

case 0:             // Leerlauf


  if ((key_pferd == 0) && (key_up == 0) && (key_down == 0) && (key_enter == 0))
  {
    key_pressed = 0;
  }
  else  // es wurde eine Taste gedrückt
  {

      timer_reset_display = TIME_FOR_DISPLAY_RESET;     // display timeout hochsetzen

      if ( (key_up != 0) && (key_down != 0) )  // SW Version
      {
        number_h(1);
        number_l(1);
      }

      if ((key_pferd != 0) && (key_up != 0) && (key_down != 0) && (key_enter != 0))  // TESTMODE
      {
        number_l(8);
        number_h(8);

        for (temp = 0; temp <=13; temp++)
        {
        rose_1(temp);
        rose_2(temp);
        rose_3(temp);
        }

        LCD[8] |= 0x01;                 // Battsymbol einschalten

        P1OUT |= 0x20;                    // Set P1.5 LED on

        plusminus(1);

        dwm(1); dwm(2); dwm(3);

        break;

      }

      if ((key_pferd == 0x01) && (key_enter == 0x00) && (key_pressed == 0))
      {

        key_pressed = 1; // damit nicht Taste mehrfach ausgeführt wird

        if (selected < 3)
          selected++  ;
        else
          selected = 0;

        // Digitalanzeige setzen
        number_h(0xFF);   // clear
        number_l(0xFF);    // clear
        plusminus(0);
        dwm(0);

        if (selected == 0)
        {
        }
        else
        {

          if (rose[selected].zeit == 0)         // wenn Zeit up, dann negative Zeit
          {
            //dwm(1);           // Tage
            plusminus(2);     // minus an
            // temp = rose[selected].time_over / dwm_index[rose[selected].dwm];

            // Zeit darstellen
            if (rose[selected].time_over > 60)
             {
              temp = rose[selected].time_over / 30;
              dwm(3);    // month
             }
            else if (rose[selected].time_over > 14)
            {
              temp = rose[selected].time_over / 7;
              dwm(2);
            }
            else
            {
              temp = rose[selected].time_over;
              dwm(1);
            }


          } else
          {
            // Zeit darstellen
            if (rose[selected].zeit > 60)
             {
              temp = rose[selected].zeit / 30;
              dwm(3);    // month
             }
            else if (rose[selected].zeit > 14)
            {
              temp = rose[selected].zeit / 7;
              dwm(2);
            }
            else
            {
              temp = rose[selected].zeit;
              dwm(1);
            }

          }

          number_h(temp / 10);
          number_l(temp % 10);


        }
      }  // key = pferd

      if ((key_enter == 0xFF) && (key_pressed == 0))
      {
        led_off = 0;              // ausschalten der LED zurücksetzen
        key_pressed = 1;
        status = S_SELECT_ROSE;
        if (selected == 0) selected = 1; // wenn noch nichts ausgewählt ...
        number_h(0xFF);   // clear
        number_l(0xFF);    // clear
        dwm(0);
        plusminus(0);
       } // key = pferd und enter

        switch (selected)
        {
          case 0:
            rose_1(14);
            rose_2(14);
            rose_3(14);
            break;
          case 1:
             rose_1(13);
            break;
          case 2:
             rose_2(13);
            rose_1(14);
            break;
          case 3:
             rose_3(13);
            rose_2(14);
            break;
          case 4:
            rose_1(13);
            rose_2(13);
            rose_3(13);
            break;
          default:
            break;
        } // switch selected


  } // key pressed


  break;


case S_SELECT_ROSE:

  if ((key_pferd == 0) && (key_up == 0) && (key_down == 0) && (key_enter == 0))
  {
    key_pressed = 0;
  }
  else   // es wurde eine Taste gedrückt
  {
      timer_reset_display = TIME_FOR_DISPLAY_RESET;     // display timeout hochsetzen

      if ((key_up == 0x01) && (key_pressed == 0))
      {
        key_pressed = 1;
        selected++;
        if (selected ==4) selected = 1;
      }

      if ((key_down == 0x01) && (key_pressed == 0))
      {
        key_pressed = 1;
        selected--;
        if (selected ==0) selected = 3;
      }

      if ((key_enter == 0x01) && (key_pressed == 0))        // zur Auswahl von DWM schalten
      {
        key_pressed = 1;
        status = S_SELECT_DWM;
        dwm(rose[selected].dwm);
      } // key enter
  }


  break;


case S_SELECT_DWM:

  if ((key_pferd == 0) && (key_up == 0) && (key_down == 0) && (key_enter == 0))
  {
    key_pressed = 0;
  }
  else   // es wurde eine Taste gedrückt
  {

    timer_reset_display = TIME_FOR_DISPLAY_RESET;     // display timeout hochsetzen


    if (((key_up == 0x01) || (key_down == 0x01)) && (key_pressed == 0))
    {
      key_pressed = 1;
      dwm(0);     // clear
      select_dwm(&rose[selected].dwm);

   } // key pressed

      if ((key_enter == 0x01) && (key_pressed == 0))
      {
          temp = rose[selected].limit ;

          number_h(0xFF);         // clear
          number_l(0xFF);         // clear
          number_h(temp / 10);
          number_l(temp % 10);

        status = S_SELECT_DIGI;
        key_pressed = 1;
      }

  }
  break;

case S_SELECT_DIGI:

  if ((key_pferd == 0) && (key_up == 0) && (key_down == 0) && (key_enter == 0))
  {
    key_pressed = 0;
  }
  else   // es wurde eine Taste gedrückt
  {
    timer_reset_display = TIME_FOR_DISPLAY_RESET;     // display timeout hochsetzen

    if (((key_up == 0x01) || (key_down == 0x01)) && (key_pressed == 0))
    {
      key_pressed = 1;
      number_l(0xFF);     // clear
      number_h(0xFF);
      select_digit(&rose[selected].limit);
      StoreInFlash();
     } // key pressed

      if ((key_enter == 0x01) && (key_pressed == 0))
      {
        rose[selected].zeit = (rose[selected].limit) * dwm_index[rose[selected].dwm];  // preset
        rose[selected].time_over = 0;   // clear
        number_h(0xFF);         // clear
        number_l(0xFF);         // clear
        dwm(0);
        status = 0;
        key_pressed = 1;
        selected = 0;
        plusminus(0);
      }



  }
  break;


default:
        status = 0;
break;
} // switch
} // while

} // main







