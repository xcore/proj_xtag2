// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 * @file endpoint0.xc
 * @brief Implements endpoint zero for an audio 2.0 device. Includes all descriptors
 * @author Ross Owen, XMOS Semiconductor
 * @version 0.1
 */

#include <xs1.h>
#include <print.h>
#include "xud.h"
#include "usb.h"
#include "DescriptorRequests.h"

int XUD_DoEnumReqs(chanend c, chanend c_in, unsigned char devDesc[], int devDescLength, uint8 cfgDesc[],
  int cfgDescLength, uint8 devQualDesc[], int devQualLength,  uint8 oSpeedCfgDesc[], int oSpeedCfgDescLength,
  uint8 strDescs[][18], SetupPacket &sp);


// This devices Device Descriptor:
static unsigned char devDesc[] = { 
  18,        /* 0  bLength : Size of descriptor in Bytes (18 Bytes) */ 
  DEVICE,    /* 1  bdescriptorType */ 
  0,         /* 2  bcdUSB */ 
  2,         /* 3  bcdUSB */ 
  0xff,      /* 4  bDeviceClass */ 
  0xff,      /* 5  bDeviceSubClass */ 
  0xff,      /* 6  bDeviceProtocol */ 
  64,        /* 7  bMaxPacketSize */ 
  0xB1,      /* 8  idVendor */ 
  0x20,      /* 9  idVendor */ 
  0xD1,      /* 10 idProduct */ 
  0xF7,      /* 11 idProduct */ 
  0x02,      /* 12 bcdDevice : Device release number */ 
  0x00,      /* 13 bcdDevice : Device release number */ 
  0x01,      /* 14 iManufacturer : Index of manufacturer string */ 
  0x02,      /* 15 iProduct : Index of product string descriptor */ 
  0x03,      /* 16 iSerialNumber : Index of serial number decriptor */ 
  0x01       /* 17 bNumConfigurations : Number of possible configs */ 
};

                                    
/* Device Qualifier Descriptor */
static unsigned char devQualDesc[] = { 
    10,               /* 0  bLength (10 Bytes) */ 
    DEVICE_QUALIFIER, /* 1  bDescriptorType */ 
    0,                /* 2  bcdUSB */ 
    2,                /* 3  bcdUSB */ 
    0xff,             /* 4  bDeviceClass */ 
    0xff,             /* 5  bDeviceSubClass */ 
    0xff,             /* 6  bDeviceProtocol */ 
    64,               /* 7  bMaxPacketSize */ 
    0x01,             /* 8  bNumConfigurations : Number of possible configs */ 
    0x00              /* 9  bReserved (must be zero) */ 
};

static unsigned char cfgDesc[] =
{
    /* Configuration descriptor: */ 
    0x09,                               /* 0  bLength */ 
    0x02,                               /* 1  bDescriptorType */ 
    0x20, 0x00,                         /* 2  wTotalLength */ 
    0x01,                               /* 4  bNumInterface: Number of interfaces*/ 
    0x01,                               /* 5  bConfigurationValue */ 
    0x00,                               /* 6  iConfiguration */ 
    0x80,                               /* 7  bmAttributes */ 
    0xFA,                               /* 8  bMaxPower */  

    /*  Interface Descriptor (Note: Must be first with lowest interface number)r */
    0x09,                               /* 0  bLength: 9 */
    0x04,                               /* 1  bDescriptorType: INTERFACE */
    0x00,                               /* 2  bInterfaceNumber */
    0x00,                               /* 3  bAlternateSetting: Must be 0 */
    0x02,                               /* 4  bNumEndpoints (0 or 1 if optional interupt endpoint is present */
    0xff,                               /* 5  bInterfaceClass: AUDIO */
    0xff,                               /* 6  bInterfaceSubClass: AUDIOCONTROL*/
    0xff,                               /* 7  bInterfaceProtocol: IP_VERSION_02_00 */
    0x03,                               /* 8  iInterface */ 

/* Standard Endpoint Descriptor (INPUT): */
    0x07, 			        /* 0  bLength: 7 */
    0x05, 			        /* 1  bDescriptorType: ENDPOINT */
    0x01,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x01,                               /* 6  bInterval */

/* Standard Endpoint Descriptor (OUTPUT): */
    0x07, 			        /* 0  bLength: 7 */
    0x05, 			        /* 1  bDescriptorType: ENDPOINT */
    0x82,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x01,                               /* 6  bInterval */
};

/* OtherSpeed Configuration Descriptor */
/* TODO: Move to DeviceDescriptors.h */
uint8 oSpeedCfgDesc[] =
{
    0x09,                              /* 0  bLength */
    OTHER_SPEED_CONFIGURATION,         /* 1  bDescriptorType */
    0x12,                              /* 2  wTotalLength */
    0x00,                              /* 3  wTotalLength */
    0x01,                              /* 4  bNumInterface: Number of interfaces*/
    0x00,                              /* 5  bConfigurationValue */
    0x00,                              /* 6  iConfiguration */
    0xC0,                              /* 7  bmAttributes */
    0x32,                              /* 8  bMaxPower */

    0x09,                              /* 0 bLength : Size of this descriptor, in bytes. (field size 1 bytes) */
    0x04,                              /* 1 bDescriptorType : INTERFACE descriptor. (field size 1 bytes) */
    0x00,                              /* 2 bInterfaceNumber : Index of this interface. (field size 1 bytes) */
    0x00,                              /* 3 bAlternateSetting : Index of this setting. (field size 1 bytes) */
    0x00,                              /* 4 bNumEndpoints : 0 endpoints. (field size 1 bytes) */
    0x00,                              /* 5 bInterfaceClass :  */
    0x00,                              /* 6 bInterfaceSubclass */
    0x00,                              /* 7 bInterfaceProtocol : Unused. (field size 1 bytes) */
    0x00,                              /* 8 iInterface : Unused. (field size 1 bytes) */

};

static unsigned char strDescs[4][40];

extern void fillFromOTP(unsigned char x[40]);

#pragma unsafe arrays
static void myStrcpy(unsigned char x[], unsigned char strDesc[40], int n) {
    while(n >= 0) {
        strDesc[n] = x[n];
        --n;
    }
}

#pragma unsafe arrays
static void setupStrDescs() {
    myStrcpy("\011\004\000\000", strDescs[0], 4);
    myStrcpy("XMOS", strDescs[1], 5);
    myStrcpy("XMOS XTAG-2", strDescs[2], 11);

    fillFromOTP(strDescs[3]);
}


extern void share_serial_number(unsigned char &serial_number, unsigned int length);

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in)
{
    unsigned char buffer[1024];
    SetupPacket sp;
    unsigned int current_config = 0;
    unsigned int halted = 0;

    XUD_ep ep0_out = XUD_Init_Ep(c_ep0_out);
    XUD_ep ep0_in  = XUD_Init_Ep(c_ep0_in);

    setupStrDescs();
    
    while(1)
    {
        /* Do standard enumeration requests */ 
        int retVal = DescriptorRequests(ep0_out, ep0_in, devDesc, sizeof(devDesc), cfgDesc, sizeof(cfgDesc), devQualDesc, sizeof(devQualDesc), oSpeedCfgDesc, sizeof(oSpeedCfgDesc), strDescs, sp);
        
        if (retVal == 1)
        {
            /* Request not covered by XUD_DoEnumReqs() so decode ourselves */
            switch(sp.bmRequestType.Type)
            {
                case BM_REQTYPE_TYPE_STANDARD:
                { 
                    switch(sp.bmRequestType.Recipient)
                    {
                        case BM_REQTYPE_RECIP_INTER:
             
                            switch(sp.bRequest)
                            {
                                /* Set Interface */
                                case SET_INTERFACE:

                                    /* TODO: Set the interface */

                                    /* No data stage for this request, just do data stage */
                                    retVal = XUD_DoSetRequestStatus(ep0_in, 0);
                                    break;
           
                                case GET_INTERFACE:
                                    buffer[0] = 0;
                                    retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 1, sp.wLength);
                                    break;

                                case GET_STATUS:
                                    buffer[0] = 0;
                                    buffer[1] = 0;
                                    retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 2, sp.wLength);
                                    break; 
            
                            }
                            break;
            
                        /* Recipient: Device */
                        case BM_REQTYPE_RECIP_DEV:
                  
                            /* Standard Device requests (8) */
                            switch( sp.bRequest )
                            {      
                                /* TODO Check direction */
                                /* Standard request: SetConfiguration */
                                case SET_CONFIGURATION:
                
                                    /* TODO: Set the config */
                                    current_config = sp.wValue;
                                     
                                    /* No data stage for this request, just do status stage */
                                    retVal = XUD_DoSetRequestStatus(ep0_in,  0);
                                    break;

                                case GET_CONFIGURATION:
                                    buffer[0] = (char)current_config;
                                    retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 1, sp.wLength);
                                    break; 

                                case GET_STATUS:
                                    buffer[0] = 0;
                                    buffer[1] = 0;
                                    if (cfgDesc[7] & 0x40)
                                      buffer[0] = 0x1;
                                    retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 2, sp.wLength);
                                    break; 
                            case SET_ADDRESS:
                                /* Status stage: Send a zero length packet */
                                retVal = XUD_SetBuffer_ResetPid(ep0_in,  buffer, 0, PIDn_DATA1);
                                /* TODO We should wait until ACK is received for status stage before changing address */
                                {
                                    timer t;
                                    unsigned time;
                                    t :> time;
                                    t when timerafter(time+50000) :> void;
                                }
                                /* Set device address in XUD */
                                XUD_SetDevAddr(sp.wValue);
                                break;

                                default:
                                    //XUD_Error("Unknown device request");
                                    break;
          
                            }  
                            break;

                        case BM_REQTYPE_RECIP_EP:

                           /* Standard Device requests (8) */
                           switch( sp.bRequest )
                           {
                               case GET_STATUS:
                                   buffer[0] = 0;
                                   buffer[1] = 0;
                                   if (halted)
                                     buffer[0] = 0x1;
                                   retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 2, sp.wLength);
                                   break;
                               case SET_FEATURE:
                                   if (sp.wValue == 0) { // HALT
                                     halted = 1;
                                   }
                                   retVal = XUD_DoSetRequestStatus(ep0_in,  0);
                                   break;
                               case CLEAR_FEATURE:
                                   if (sp.wValue == 0) { // HALT
                                     halted = 0;
                                   }
                                   retVal = XUD_DoSetRequestStatus(ep0_in,  0);
                                   break;

                               default:
                                   //XUD_Error("Unknown device request");
                                   break;

                           }
                           break;

                        default: 
                            /* Got a request to a recipient we didn't recognise... */ 
                            //XUD_Error("Unknown Recipient"); 
                            break;
                    }
                    break;
                }

            default:
            {
                //printstr("ERR: Unknown request: ");
                //XUD_PrintSetupPacket(sp);
                break;
            }
    
        }

        } /* if XUD_DoEnumReqs() */
        
        /* If retVal STILL 1 then STALL */
        if (retVal == 1)
        {
            XUD_SetStall_Out(0);
            XUD_SetStall_In(0);
        }

        if (retVal == -1) 
        {
           XUD_ResetEndpoint(ep0_out, ep0_in);
           share_serial_number(strDescs[3][0], 17);
           return;
        }


    } // while(1)
}
