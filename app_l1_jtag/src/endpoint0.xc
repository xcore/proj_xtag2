// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


/**
 * @file endpoint0.xc
 * @brief Implements endpoint zero for an audio 2.0 device. Includes all descriptors
 * @author Ross Owen, XMOS Semiconductor
 * @version 0.1
 */

#include <xs1.h>
#include <print.h>
#include <safestring.h>
#include "xud.h"
#include "usb.h"
//#include "USBAudioCodes.h"
//#include "dbTable.h"
#include "DescriptorRequests.h"
//#include "param.h"
//#include "mixer.h"
//#include "sof_clock.h"

#define XUD_DESC_STR_USENG     0x0409 // US English

// This devices Device Descriptor:
#define DESC_DEVICE \
{ \
  18, 				     /* 0  bLength : Size of descriptor in Bytes (18 Bytes) */ \
  DEVICE,                            /* 1  bdescriptorType */ \
  0,                                 /* 2  bcdUSB */ \
  2,                                 /* 3  bcdUSB */ \
  0xEF,                              /* 4  bDeviceClass */ \
  0x02,                              /* 5  bDeviceSubClass */ \
  0x01,                              /* 6  bDeviceProtocol */ \
  64,                                /* 7  bMaxPacketSize */ \
  0xb1,                              /* 8  idVendor */ \
  0x20,                              /* 9  idVendor */ \
  0xd2,                              /* 10 idProduct */ \
  0xf7,                              /* 11 idProduct */ \
  0x02,                              /* 12 bcdDevice : Device release number */ \
  0x10,                              /* 13 bcdDevice : Device release number */ \
  0x01,                              /* 14 iManufacturer : Index of manufacturer string */ \
  0x02,                              /* 15 iProduct : Index of product string descriptor */ \
  0x05,                              /* 16 iSerialNumber : Index of serial number decriptor */ \
  0x01                               /* 17 bNumConfigurations : Number of possible configs */ \
}

                                    
/* Device Qualifier Descriptor */
#define DESC_DEVQUAL \
{ \
    10,                              /* 0  bLength (10 Bytes) */ \
    DEVICE_QUALIFIER,                /* 1  bDescriptorType */ \
    0,                               /* 2  bcdUSB */ \
    2,                               /* 3  bcdUSB */ \
    0x02,                               /* 4  bDeviceClass */ \
    0x00,                               /* 5  bDeviceSubClass */ \
    0x00,                               /* 6  bDeviceProtocol */ \
    64,                              /* 7  bMaxPacketSize */ \
    0x01,                            /* 8  bNumConfigurations : Number of possible configs */ \
    0x00                             /* 9  bReserved (must be zero) */ \
}

#define DESC_DEBUG \
{ \
    4, \
    10, \
    0, \
    0 \
}

static unsigned char cfgDesc[] =
{
    /* Configuration descriptor: */ 
    0x09,                               /* 0  bLength */ 
    0x02,                               /* 1  bDescriptorType */ 
    0x81, 0x0,                         /* 2  wTotalLength */ 
    0x04,                               /* 4  bNumInterface: Number of interfaces*/ 
    0x01,                               /* 5  bConfigurationValue */ 
    0x00,                               /* 6  iConfiguration */ 
    0xC0,                               /* 7  bmAttributes */ 
    0xFA,                               /* 8  bMaxPower */  







    /* Interface Association Descriptor */

    0x08,                               /* 0  bLength: 8 */
    0x0B,                               /* 1  bDescriptorType: INTERFACEASS */
    0x00,                               /* 2  bFirstInterface */
    0x02,                               /* 4  bInterfaceCount */
    0xff,                               /* 5  bInterfaceClass: VENDOR */
    0xff,                               /* 6  bInterfaceSubClass: VENDOR */
    0xff,                               /* 7  bInterfaceProtocol: VENDOR */
    0x00,                               /* 8  iInterface */ 

    /*  Interface Descriptor (Note: Must be first with lowest interface number)r */
    0x09,                               /* 0  bLength: 9 */
    0x04,                               /* 1  bDescriptorType: INTERFACE */
    0x00,                               /* 2  bInterfaceNumber */
    0x00,                               /* 3  bAlternateSetting: Must be 0 */
    0x02,                               /* 4  bNumEndpoints (0 or 1 if optional interupt endpoint is present */
    0xff,                               /* 5  bInterfaceClass: VENDOR */
    0xff,                               /* 6  bInterfaceSubClass: VENDOR */
    0xff,                               /* 7  bInterfaceProtocol: VENDOR */
    0x03,                               /* 8  iInterface */ 

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    0x05,                               /* 1  bDescriptorType: ENDPOINT */
    0x01,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x01,                               /* 6  bInterval */

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    0x05,                               /* 1  bDescriptorType: ENDPOINT */
    0x82,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x01,                               /* 6  bInterval */

/*  Interface Descriptor (Note: Must be first with lowest interface number)r */
    0x09,                               /* 0  bLength: 9 */
    0x04,                               /* 1  bDescriptorType: INTERFACE */
    0x01,                               /* 2  bInterfaceNumber */
    0x00,                               /* 3  bAlternateSetting: Must be 0 */
    0x02,                               /* 4  bNumEndpoints (0 or 1 if optional interupt endpoint is present */
    0xff,                               /* 5  bInterfaceClass: VENDOR */
    0xff,                               /* 6  bInterfaceSubClass: VENDOR */
    0xff,                               /* 7  bInterfaceProtocol: VENDOR */
    0x03,                               /* 8  iInterface */

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    0x05,                               /* 1  bDescriptorType: ENDPOINT */
    0x02,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x01,                               /* 6  bInterval */

/* Endpoint Descriptor (4.10.1.1): */
    0x07,                               /* 0  bLength: 7 */
    0x05,                               /* 1  bDescriptorType: ENDPOINT */
    0x83,                               /* 2  bEndpointAddress (D7: 0:out, 1:in) */
    0x02,
    0x00, 0x02,                         /* 4  wMaxPacketSize */
    0x01,                               /* 6  bInterval */



    /* Interface Association Descriptor */

    0x08,                               /* 0  bLength: 8 */
    0x0B,                               /* 1  bDescriptorType: INTERFACEASS */
    0x02,                               /* 2  bFirstInterface */
    0x02,                               /* 4  bInterfaceCount */
    0x02,                               /* 5  bInterfaceClass */
    0x00,                               /* 6  bInterfaceSubClass */
    0x00,                               /* 7  bInterfaceProtocol */
    0x00,                               /* 8  iInterface */ 


  0x09,                /* 0  bLength */
  0x04,                /* 1  bDescriptorType */ 
  0x02,                /* 2  bInterfacecNumber */
  0x00,                /* 3  bAlternateSetting */
  0x01,                /* 4: bNumEndpoints */
  0x02,                /* 5: bInterfaceClass */ 
  0x02,                /* 6: bInterfaceSubClass */ 
  0x01,                /* 7: bInterfaceProtocol*/ 
  0x00,                /* 8  iInterface */ 


  0x05,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */ 
  0x00,                /* 2  bDescriptorsubtype, HEADER */ 
  0x00, 0x02,          /* 3  BCD */ 

  0x05,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */ 
  0x06,                /* 2  bDescriptorsubtype, UNION */ 
  0x02,
  0x03,

  0x05,                /* 0  bLength, Descriptor size in bytes */
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */
  0x01,                /* 2  bDescriptorsubtype, CALL MANAGEMENT */
  0x03,                /* 3  bmCapabilities, DIY */
  0x03,                /* 4  bDataInterface */

  0x04,                /* 0  bLength */ 
  0x24,                /* 1  bDescriptortype, CS_INTERFACE */ 
  0x02,                /* 2  bDescriptorsubtype, ABSTRACT CONTROL MANAGEMENT */ 
  0x00,                /* 3 bmCapabilities: none */

  0x07,                /* 0  bLength */ 
  0x05,                /* 1  bDescriptorType */ 
  0x81,                /* 2  bEndpointAddress */ 
  0x03,                /* 3  bmAttributes */ 
  0x40,                /* 4  wMaxPacketSize */ 
  0x00,                /* 5  wMaxPacketSize */ 
  0x01,                /* 6  bInterval */ 


  0x09,                /* 0  bLength */
  0x04,                /* 1  bDescriptorType */ 
  0x03,                /* 2  bInterfacecNumber */
  0x00,                /* 3  bAlternateSetting */
  0x02,                /* 4: bNumEndpoints */
  0x0A,                /* 5: bInterfaceClass */ 
  0x00,                /* 6: bInterfaceSubClass */ 
  0x00,                /* 7: bInterfaceProtocol*/ 
  0x04,                /* 8  iInterface */ 

  0x07,                /* 0  bLength */ 
  0x05,                /* 1  bDescriptorType */ 
  0x03,                /* 2  bEndpointAddress */ 
  0x02,                /* 3  bmAttributes */ 
  0x00,                /* 4  wMaxPacketSize */ 
  0x02,                /* 5  wMaxPacketSize */ 
  0x00,                /* 6  bInterval */ 
  
  0x07,                /* 0  bLength */ 
  0x05,                /* 1  bDescriptorType */ 
  0x84,                /* 2  bEndpointAddress */ 
  0x02,                /* 3  bmAttributes */ 
  0x00,                /* 4  wMaxPacketSize */ 
  0x02,                /* 5  wMaxPacketSize */ 
  0x01                 /* 6  bInterval */ 

};

#define DESC_STR_LANGIDS \
{ \
  XUD_DESC_STR_USENG & 0xff,               /* 2  wLangID[0] */ \
  XUD_DESC_STR_USENG>>8,            /* 3  wLangID[0] */ \
  '\0' \
}

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
    0x80,                              /* 7  bmAttributes */
    0xFA,                              /* 8  bMaxPower */

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


//#define STRINGER(x) PRODUCT#x
/* Standard descriptors */
static unsigned char devDesc[] = DESC_DEVICE;
//static unsigned char cfgDesc[] = DESC_CONFIG;
static unsigned char devQualDesc[] = DESC_DEVQUAL;
//static unsigned char debugDesc[] = DESC_DEBUG;

/* String descriptors */
static unsigned char strDesc_langIDs[] = DESC_STR_LANGIDS;

/* Strings table for string desctiptors. Note: for usabilty unicode and datalengh are dealt with automatically */
/* therefore just the strings are required below. string[0] (langIDs) is a speacial one... */
static unsigned char strDescs[][40] = 
{
    "string0", 				                    /* 0: Place holder for string 0 (LANGIDs) */ 
    "XMOS",				                    /* 1: iManufacturer */ 
    "XMOS XTAG-2",                   		       	    /* 2: iProduct */
    "ID3",
    "ID4",
    "XTAG2L16400000000"
}; 


int ControlInterfaceClassRequests(XUD_ep c_ep0_out, XUD_ep c_ep0_in, SetupPacket sp)
{
    unsigned char buffer[64];
    // Recipient: Interface
    // NOTE: CLASS SPECIFIC REQUESTS

    switch(sp.bRequest )
    { 
        case 0x43:      
            // TODO
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;
            
        case 0x21:
            // Windows calls this - even though we say we do not support it.
            buffer[0] = 0;
            buffer[1] = 132;
            buffer[2] = 3;
            buffer[3] = 0;
            buffer[4] = 0;
            buffer[5] = 0;
            buffer[6] = 8;
            XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 7, PIDn_DATA1);
            return XUD_GetBuffer(c_ep0_out, buffer);
            break;

        case 0x22:      
            // Linux calls this - even though we say we do not support it.
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;

        case 0x20:      
            // Linux calls this - even though we say we do not support it.
            (void) XUD_GetBuffer(c_ep0_out, buffer);
            return XUD_SetBuffer_ResetPid(c_ep0_in, buffer, 0, PIDn_DATA1);
            break;
            

        default:
            /* Error case */
            printintln(sp.bRequest);
            break;
    }

    return 0;
}




void get_serial_number(unsigned char &serial_number, unsigned int length);

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in)
{
    unsigned char buffer[1024];
    SetupPacket sp;

    XUD_ep ep0_out = XUD_Init_Ep(c_ep0_out);
    XUD_ep ep0_in  = XUD_Init_Ep(c_ep0_in);

    get_serial_number(strDescs[5][0], safestrlen(strDescs[5]));

    /* Copy langIDs string desc into string[0] */
    /* TODO: Macro? */
    safememcpy(strDescs[0], strDesc_langIDs, sizeof(strDesc_langIDs));
 
    /* Compute initial channel volume factors */ 
    //updateMasterVol(0xa);
    //updateMasterVol(0xb);
    
    while(1)
    {
        /* Do standard enumeration requests */ 

        int retVal = DescriptorRequests(ep0_out, ep0_in, devDesc, sizeof(devDesc), cfgDesc, sizeof(cfgDesc), devQualDesc, sizeof(devQualDesc), oSpeedCfgDesc, sizeof(oSpeedCfgDesc), strDescs, sp);
        if (retVal == 1) {
            /* Request not covered by XUD_DoEnumReqs() so decode ourselves */
            switch(sp.bmRequestType.Type) {
            case BM_REQTYPE_TYPE_CLASS:
                switch(sp.bmRequestType.Recipient)
                {
                case BM_REQTYPE_RECIP_INTER:
                    /* Inspect for Control interface num */
                    if(sp.wIndex == 0)
                    {
                        ControlInterfaceClassRequests(ep0_out, ep0_in, sp);
                    }
                    break;
                    
                }
                break;

            case BM_REQTYPE_TYPE_STANDARD:
                switch(sp.bmRequestType.Recipient) {
                case BM_REQTYPE_RECIP_INTER:
                    switch(sp.bRequest) {
                        /* Set Interface */
                    case SET_INTERFACE:
                        /* TODO: Set the interface */
                        /* No data stage for this request, just do data stage */
                        retVal = XUD_DoSetRequestStatus(ep0_in, 0);
                        break;
                        /* Get descriptor */ 
                    case GET_DESCRIPTOR:
                        /* Inspect which descriptor require (high byte of wValue) */ 
                        switch( sp.wValue & 0xff00 ) {
                            /* HID Report Descriptor */
                        ///case  WVALUE_GETDESC_HID_REPORT:
                            /* Go Get Request protocol */
                           // retVal = XUD_DoGetRequest( ep0_out, ep0_in, hidReportDesc, sizeof( hidReportDesc ));
                            //break;
                        default:
                            XUD_Error( "Unknown descriptor request\n" );
                            break;
                        }
                        break;
                    }
                    break;
                    /* Recipient: Device */
                case BM_REQTYPE_RECIP_DEV:
                    /* Standard Device requests (8) */
                    switch( sp.bRequest ) {      
                        /* TODO Check direction */
                        /* Standard request: SetConfiguration */
                    case SET_CONFIGURATION:
                        /* TODO: Set the config */
                        /* No data stage for this request, just do status stage */
                        retVal = XUD_DoSetRequestStatus(ep0_in,  0);
                        break;
                    case GET_CONFIGURATION:
                        buffer[0] = 1;
                        retVal = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 1, sp.wLength);
                        break; 
                        
                        /* Set Device Address: This is a unique set request. */
                    case SET_ADDRESS:
                        /* Status stage: Send a zero length packet */
                        retVal = XUD_SetBuffer_ResetPid(ep0_in,  buffer, 0, PIDn_DATA1);
                        /* TODO We should wait until ACK is received for status stage before changing address */
                        //XUD_Sup_Delay(50000);
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
                        XUD_Error("Unknown device request");
                        break;
                    }  
                    break;
                default: 
                    /* Got a request to a recipient we didn't recognise... */ 
                    //XUD_Error("Unknown Recipient"); 
                    break;
                }
                break;
            default:
                //printstr("ERR: Unknown request: ");
                break;
            }
        } /* if XUD_DoEnumReqs() */
        if (retVal < 0) {
            XUD_ResetEndpoint(ep0_in, ep0_out);
        }
  }

  // END control tokens.
  //inct(ep0);
  //inct(ep0_con);
  
  //endpoint1dead();
 //stop_streaming_slave(ep0);
 //stop_streaming_slave(ep0_con);

  //printstrln("ep thread exit");
}
