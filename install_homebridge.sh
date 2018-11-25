#!/usr/bin/env bash

start=`date +%s`

GIT=`command -v git`
NODEJS=`command -v nodejs`
WIRINGPI=`command -v gpio`
HOMEBRIDGE=`command -v homebridge`
HOMEBRIDGE_USER=`getent passwd $user  > /dev/null`

clear
echo " _____                   _         _    _           "
echo "|  |  | ___  _____  ___ | |_  ___ |_| _| | ___  ___ "
echo "|     || . ||     || -_|| . ||  _|| || . || . || -_|"
echo "|__|__||___||_|_|_||___||___||_|  |_||___||_  ||___|"
echo "Install Script | by somebodywhoisntme     |___|     "
sleep 3
echo ""
echo "Update/Upgrade System"
cd ~/
sudo apt update > /dev/null 2>&1 ; sudo apt upgrade -y > /dev/null 2>&1
echo "ready"
#check if git is installed
echo ""
echo "Check if needed software is installed"
echo ""
if [ -z $GIT ]; then
  echo "git not installed. installing now."
  sudo apt install git -y > /dev/null 2>&1
else
  echo "git is installed."
fi
#check if nodejs is installed
if [ -z $NODEJS ]; then
  echo "nodejs not installed. installing now."
  curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash - > /dev/null 2>&1
  sudo apt-get install -y nodejs > /dev/null 2>&1
else
  echo "nodejs is installed."
fi
#check if wiringPi is installed
if [ -z $WIRINGPI ]; then
  echo "wiringPi not installed. installing now."
  git clone git://git.drogon.net/wiringPi > /dev/null 2>&1
  cd wiringPi/
  ./build > /dev/null 2>&1
  cd ~/
  rm -rf wiringPi/
else
  echo "wiringPi is installed."
fi
#check if homebridge is installed
if [ -z $HOMEBRIDGE ]; then
  echo "homebridge not installed. installing now."
  sudo npm install -g --unsafe-perm homebridge > /dev/null 2>&1
  sudo npm install -g homebridge-cmdswitch2 > /dev/null 2>&1
  timeout 10 homebridge > /dev/null 2>&1
else
  echo "homebridge is installed."
fi
echo ""
echo "creating homebridge user and add autostart files"
if [ -z $HOMEBRIDGE_USER ]; then
  SUDOERS="/etc/sudoers"
  sudo useradd --system homebridge > /dev/null 2>&1
  clear
  echo " _____                   _         _    _           "
  echo "|  |  | ___  _____  ___ | |_  ___ |_| _| | ___  ___ "
  echo "|     || . ||     || -_|| . ||  _|| || . || . || -_|"
  echo "|__|__||___||_|_|_||___||___||_|  |_||___||_  ||___|"
  echo "Install Script | by somebodywhoisntme     |___|     "
  echo ""
  echo "Copy the next line and paste it at the end of the following file and save with ctrl+x, 'y' or 'j' and then 'enter':"
  echo ""
  echo -e "\033[31;7mhomebridge  ALL=(ALL) NOPASSWD: /var/homebridge/send\033[0m"
  echo ""
  read -p "Press enter to continue."
  sudo visudo
  sudo wget -O /etc/default/homebridge https://gist.githubusercontent.com/johannrichard/0ad0de1feb6adb9eb61a/raw/7defd3836f4fbe2b98ea5a9749c4413d024e9623/homebridge > /dev/null 2>&1
  sudo cat <<\EOF >> homebridge.service
[Unit]
Description=Node.js HomeKit Server
After=syslog.target network-online.target

[Service]
Type=simple
User=homebridge
EnvironmentFile=/etc/default/homebridge
ExecStart=/usr/bin/homebridge $HOMEBRIDGE_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
  sudo mv homebridge.service /etc/systemd/system/
  sudo mkdir /var/homebridge
  sudo cp -r .homebridge/persist /var/homebridge
fi

#install rc-switch and create send binary
clear
echo " _____                   _         _    _           "
echo "|  |  | ___  _____  ___ | |_  ___ |_| _| | ___  ___ "
echo "|     || . ||     || -_|| . ||  _|| || . || . || -_|"
echo "|__|__||___||_|_|_||___||___||_|  |_||___||_  ||___|"
echo "Install Script | by somebodywhoisntme     |___|     "
echo ""
echo "cloning rc-switch and compile send binary"
git clone https://github.com/sui77/rc-switch > /dev/null 2>&1
cd rc-switch
#create edited RCSwitch.cpp with protocol 8
cp RCSwitch.cpp RCSwitch.cpp.orig
cat > RCSwitch.cpp << EOF
/*
  RCSwitch - Arduino libary for remote control outlet switches
  Copyright (c) 2011 Suat Özgür.  All right reserved.

  Contributors:
  - Andre Koehler / info(at)tomate-online(dot)de
  - Gordeev Andrey Vladimirovich / gordeev(at)openpyro(dot)com
  - Skineffect / http://forum.ardumote.com/viewtopic.php?f=2&t=46
  - Dominik Fischer / dom_fischer(at)web(dot)de
  - Frank Oltmanns / <first name>.<last name>(at)gmail(dot)com
  - Andreas Steinel / A.<lastname>(at)gmail(dot)com
  - Max Horn / max(at)quendi(dot)de
  - Robert ter Vehn / <first name>.<last name>(at)gmail(dot)com
  - Johann Richard / <first name>.<last name>(at)gmail(dot)com
  - Vlad Gheorghe / <first name>.<last name>(at)gmail(dot)com https://github.com/vgheo

  Project home: https://github.com/sui77/rc-switch/

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "RCSwitch.h"

#ifdef RaspberryPi
    // PROGMEM and _P functions are for AVR based microprocessors,
    // so we must normalize these for the ARM processor:
    #define PROGMEM
    #define memcpy_P(dest, src, num) memcpy((dest), (src), (num))
#endif

#if defined(ESP8266) || defined(ESP32)
    // interrupt handler and related code must be in RAM on ESP8266,
    // according to issue #46.
    #define RECEIVE_ATTR ICACHE_RAM_ATTR
#else
    #define RECEIVE_ATTR
#endif


/* Format for protocol definitions:
 * {pulselength, Sync bit, "0" bit, "1" bit}
 *
 * pulselength: pulse length in microseconds, e.g. 350
 * Sync bit: {1, 31} means 1 high pulse and 31 low pulses
 *     (perceived as a 31*pulselength long pulse, total length of sync bit is
 *     32*pulselength microseconds), i.e:
 *      _
 *     | |_______________________________ (don't count the vertical bars)
 * "0" bit: waveform for a data bit of value "0", {1, 3} means 1 high pulse
 *     and 3 low pulses, total length (1+3)*pulselength, i.e:
 *      _
 *     | |___
 * "1" bit: waveform for a data bit of value "1", e.g. {3,1}:
 *      ___
 *     |   |_
 *
 * These are combined to form Tri-State bits when sending or receiving codes.
 */
#if defined(ESP8266) || defined(ESP32)
static const RCSwitch::Protocol proto[] = {
#else
static const RCSwitch::Protocol PROGMEM proto[] = {
#endif
  { 350, {  1, 31 }, {  1,  3 }, {  3,  1 }, false },    // protocol 1
  { 650, {  1, 10 }, {  1,  2 }, {  2,  1 }, false },    // protocol 2
  { 100, { 30, 71 }, {  4, 11 }, {  9,  6 }, false },    // protocol 3
  { 380, {  1,  6 }, {  1,  3 }, {  3,  1 }, false },    // protocol 4
  { 500, {  6, 14 }, {  1,  2 }, {  2,  1 }, false },    // protocol 5
  { 450, { 23,  1 }, {  1,  2 }, {  2,  1 }, true },      // protocol 6 (HT6P20B)
  { 150, {  2, 62 }, {  1,  6 }, {  6,  1 }, false },     // protocol 7 (HS2303-PT, i. e. used in AUKEY Remote)
  { 327, { 35,  1 }, {  1,  2 }, {  2,  1 }, true }
};

enum {
   numProto = sizeof(proto) / sizeof(proto[0])
};

#if not defined( RCSwitchDisableReceiving )
volatile unsigned long RCSwitch::nReceivedValue = 0;
volatile unsigned int RCSwitch::nReceivedBitlength = 0;
volatile unsigned int RCSwitch::nReceivedDelay = 0;
volatile unsigned int RCSwitch::nReceivedProtocol = 0;
int RCSwitch::nReceiveTolerance = 60;
const unsigned int RCSwitch::nSeparationLimit = 4300;
// separationLimit: minimum microseconds between received codes, closer codes are ignored.
// according to discussion on issue #14 it might be more suitable to set the separation
// limit to the same time as the 'low' part of the sync signal for the current protocol.
unsigned int RCSwitch::timings[RCSWITCH_MAX_CHANGES];
#endif

RCSwitch::RCSwitch() {
  this->nTransmitterPin = -1;
  this->setRepeatTransmit(10);
  this->setProtocol(1);
  #if not defined( RCSwitchDisableReceiving )
  this->nReceiverInterrupt = -1;
  this->setReceiveTolerance(60);
  RCSwitch::nReceivedValue = 0;
  #endif
}

/**
  * Sets the protocol to send.
  */
void RCSwitch::setProtocol(Protocol protocol) {
  this->protocol = protocol;
}

/**
  * Sets the protocol to send, from a list of predefined protocols
  */
void RCSwitch::setProtocol(int nProtocol) {
  if (nProtocol < 1 || nProtocol > numProto) {
    nProtocol = 1;  // TODO: trigger an error, e.g. "bad protocol" ???
  }
#if defined(ESP8266) || defined(ESP32)
  this->protocol = proto[nProtocol-1];
#else
  memcpy_P(&this->protocol, &proto[nProtocol-1], sizeof(Protocol));
#endif
}

/**
  * Sets the protocol to send with pulse length in microseconds.
  */
void RCSwitch::setProtocol(int nProtocol, int nPulseLength) {
  setProtocol(nProtocol);
  this->setPulseLength(nPulseLength);
}


/**
  * Sets pulse length in microseconds
  */
void RCSwitch::setPulseLength(int nPulseLength) {
  this->protocol.pulseLength = nPulseLength;
}

/**
 * Sets Repeat Transmits
 */
void RCSwitch::setRepeatTransmit(int nRepeatTransmit) {
  this->nRepeatTransmit = nRepeatTransmit;
}

/**
 * Set Receiving Tolerance
 */
#if not defined( RCSwitchDisableReceiving )
void RCSwitch::setReceiveTolerance(int nPercent) {
  RCSwitch::nReceiveTolerance = nPercent;
}
#endif


/**
 * Enable transmissions
 *
 * @param nTransmitterPin    Arduino Pin to which the sender is connected to
 */
void RCSwitch::enableTransmit(int nTransmitterPin) {
  this->nTransmitterPin = nTransmitterPin;
  pinMode(this->nTransmitterPin, OUTPUT);
}

/**
  * Disable transmissions
  */
void RCSwitch::disableTransmit() {
  this->nTransmitterPin = -1;
}

/**
 * Switch a remote switch on (Type D REV)
 *
 * @param sGroup        Code of the switch group (A,B,C,D)
 * @param nDevice       Number of the switch itself (1..3)
 */
void RCSwitch::switchOn(char sGroup, int nDevice) {
  this->sendTriState( this->getCodeWordD(sGroup, nDevice, true) );
}

/**
 * Switch a remote switch off (Type D REV)
 *
 * @param sGroup        Code of the switch group (A,B,C,D)
 * @param nDevice       Number of the switch itself (1..3)
 */
void RCSwitch::switchOff(char sGroup, int nDevice) {
  this->sendTriState( this->getCodeWordD(sGroup, nDevice, false) );
}

/**
 * Switch a remote switch on (Type C Intertechno)
 *
 * @param sFamily  Familycode (a..f)
 * @param nGroup   Number of group (1..4)
 * @param nDevice  Number of device (1..4)
  */
void RCSwitch::switchOn(char sFamily, int nGroup, int nDevice) {
  this->sendTriState( this->getCodeWordC(sFamily, nGroup, nDevice, true) );
}

/**
 * Switch a remote switch off (Type C Intertechno)
 *
 * @param sFamily  Familycode (a..f)
 * @param nGroup   Number of group (1..4)
 * @param nDevice  Number of device (1..4)
 */
void RCSwitch::switchOff(char sFamily, int nGroup, int nDevice) {
  this->sendTriState( this->getCodeWordC(sFamily, nGroup, nDevice, false) );
}

/**
 * Switch a remote switch on (Type B with two rotary/sliding switches)
 *
 * @param nAddressCode  Number of the switch group (1..4)
 * @param nChannelCode  Number of the switch itself (1..4)
 */
void RCSwitch::switchOn(int nAddressCode, int nChannelCode) {
  this->sendTriState( this->getCodeWordB(nAddressCode, nChannelCode, true) );
}

/**
 * Switch a remote switch off (Type B with two rotary/sliding switches)
 *
 * @param nAddressCode  Number of the switch group (1..4)
 * @param nChannelCode  Number of the switch itself (1..4)
 */
void RCSwitch::switchOff(int nAddressCode, int nChannelCode) {
  this->sendTriState( this->getCodeWordB(nAddressCode, nChannelCode, false) );
}

/**
 * Deprecated, use switchOn(const char* sGroup, const char* sDevice) instead!
 * Switch a remote switch on (Type A with 10 pole DIP switches)
 *
 * @param sGroup        Code of the switch group (refers to DIP switches 1..5 where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 * @param nChannelCode  Number of the switch itself (1..5)
 */
void RCSwitch::switchOn(const char* sGroup, int nChannel) {
  const char* code[6] = { "00000", "10000", "01000", "00100", "00010", "00001" };
  this->switchOn(sGroup, code[nChannel]);
}

/**
 * Deprecated, use switchOff(const char* sGroup, const char* sDevice) instead!
 * Switch a remote switch off (Type A with 10 pole DIP switches)
 *
 * @param sGroup        Code of the switch group (refers to DIP switches 1..5 where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 * @param nChannelCode  Number of the switch itself (1..5)
 */
void RCSwitch::switchOff(const char* sGroup, int nChannel) {
  const char* code[6] = { "00000", "10000", "01000", "00100", "00010", "00001" };
  this->switchOff(sGroup, code[nChannel]);
}

/**
 * Switch a remote switch on (Type A with 10 pole DIP switches)
 *
 * @param sGroup        Code of the switch group (refers to DIP switches 1..5 where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 * @param sDevice       Code of the switch device (refers to DIP switches 6..10 (A..E) where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 */
void RCSwitch::switchOn(const char* sGroup, const char* sDevice) {
  this->sendTriState( this->getCodeWordA(sGroup, sDevice, true) );
}

/**
 * Switch a remote switch off (Type A with 10 pole DIP switches)
 *
 * @param sGroup        Code of the switch group (refers to DIP switches 1..5 where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 * @param sDevice       Code of the switch device (refers to DIP switches 6..10 (A..E) where "1" = on and "0" = off, if all DIP switches are on it's "11111")
 */
void RCSwitch::switchOff(const char* sGroup, const char* sDevice) {
  this->sendTriState( this->getCodeWordA(sGroup, sDevice, false) );
}


/**
 * Returns a char[13], representing the code word to be send.
 *
 */
char* RCSwitch::getCodeWordA(const char* sGroup, const char* sDevice, bool bStatus) {
  static char sReturn[13];
  int nReturnPos = 0;

  for (int i = 0; i < 5; i++) {
    sReturn[nReturnPos++] = (sGroup[i] == '0') ? 'F' : '0';
  }

  for (int i = 0; i < 5; i++) {
    sReturn[nReturnPos++] = (sDevice[i] == '0') ? 'F' : '0';
  }

  sReturn[nReturnPos++] = bStatus ? '0' : 'F';
  sReturn[nReturnPos++] = bStatus ? 'F' : '0';

  sReturn[nReturnPos] = '\0';
  return sReturn;
}

/**
 * Encoding for type B switches with two rotary/sliding switches.
 *
 * The code word is a tristate word and with following bit pattern:
 *
 * +-----------------------------+-----------------------------+----------+------------+
 * | 4 bits address              | 4 bits address              | 3 bits   | 1 bit      |
 * | switch group                | switch number               | not used | on / off   |
 * | 1=0FFF 2=F0FF 3=FF0F 4=FFF0 | 1=0FFF 2=F0FF 3=FF0F 4=FFF0 | FFF      | on=F off=0 |
 * +-----------------------------+-----------------------------+----------+------------+
 *
 * @param nAddressCode  Number of the switch group (1..4)
 * @param nChannelCode  Number of the switch itself (1..4)
 * @param bStatus       Whether to switch on (true) or off (false)
 *
 * @return char[13], representing a tristate code word of length 12
 */
char* RCSwitch::getCodeWordB(int nAddressCode, int nChannelCode, bool bStatus) {
  static char sReturn[13];
  int nReturnPos = 0;

  if (nAddressCode < 1 || nAddressCode > 4 || nChannelCode < 1 || nChannelCode > 4) {
    return 0;
  }

  for (int i = 1; i <= 4; i++) {
    sReturn[nReturnPos++] = (nAddressCode == i) ? '0' : 'F';
  }

  for (int i = 1; i <= 4; i++) {
    sReturn[nReturnPos++] = (nChannelCode == i) ? '0' : 'F';
  }

  sReturn[nReturnPos++] = 'F';
  sReturn[nReturnPos++] = 'F';
  sReturn[nReturnPos++] = 'F';

  sReturn[nReturnPos++] = bStatus ? 'F' : '0';

  sReturn[nReturnPos] = '\0';
  return sReturn;
}

/**
 * Like getCodeWord (Type C = Intertechno)
 */
char* RCSwitch::getCodeWordC(char sFamily, int nGroup, int nDevice, bool bStatus) {
  static char sReturn[13];
  int nReturnPos = 0;

  int nFamily = (int)sFamily - 'a';
  if ( nFamily < 0 || nFamily > 15 || nGroup < 1 || nGroup > 4 || nDevice < 1 || nDevice > 4) {
    return 0;
  }

  // encode the family into four bits
  sReturn[nReturnPos++] = (nFamily & 1) ? 'F' : '0';
  sReturn[nReturnPos++] = (nFamily & 2) ? 'F' : '0';
  sReturn[nReturnPos++] = (nFamily & 4) ? 'F' : '0';
  sReturn[nReturnPos++] = (nFamily & 8) ? 'F' : '0';

  // encode the device and group
  sReturn[nReturnPos++] = ((nDevice-1) & 1) ? 'F' : '0';
  sReturn[nReturnPos++] = ((nDevice-1) & 2) ? 'F' : '0';
  sReturn[nReturnPos++] = ((nGroup-1) & 1) ? 'F' : '0';
  sReturn[nReturnPos++] = ((nGroup-1) & 2) ? 'F' : '0';

  // encode the status code
  sReturn[nReturnPos++] = '0';
  sReturn[nReturnPos++] = 'F';
  sReturn[nReturnPos++] = 'F';
  sReturn[nReturnPos++] = bStatus ? 'F' : '0';

  sReturn[nReturnPos] = '\0';
  return sReturn;
}

/**
 * Encoding for the REV Switch Type
 *
 * The code word is a tristate word and with following bit pattern:
 *
 * +-----------------------------+-------------------+----------+--------------+
 * | 4 bits address              | 3 bits address    | 3 bits   | 2 bits       |
 * | switch group                | device number     | not used | on / off     |
 * | A=1FFF B=F1FF C=FF1F D=FFF1 | 1=0FF 2=F0F 3=FF0 | 000      | on=10 off=01 |
 * +-----------------------------+-------------------+----------+--------------+
 *
 * Source: http://www.the-intruder.net/funksteckdosen-von-rev-uber-arduino-ansteuern/
 *
 * @param sGroup        Name of the switch group (A..D, resp. a..d)
 * @param nDevice       Number of the switch itself (1..3)
 * @param bStatus       Whether to switch on (true) or off (false)
 *
 * @return char[13], representing a tristate code word of length 12
 */
char* RCSwitch::getCodeWordD(char sGroup, int nDevice, bool bStatus) {
  static char sReturn[13];
  int nReturnPos = 0;

  // sGroup must be one of the letters in "abcdABCD"
  int nGroup = (sGroup >= 'a') ? (int)sGroup - 'a' : (int)sGroup - 'A';
  if ( nGroup < 0 || nGroup > 3 || nDevice < 1 || nDevice > 3) {
    return 0;
  }

  for (int i = 0; i < 4; i++) {
    sReturn[nReturnPos++] = (nGroup == i) ? '1' : 'F';
  }

  for (int i = 1; i <= 3; i++) {
    sReturn[nReturnPos++] = (nDevice == i) ? '1' : 'F';
  }

  sReturn[nReturnPos++] = '0';
  sReturn[nReturnPos++] = '0';
  sReturn[nReturnPos++] = '0';

  sReturn[nReturnPos++] = bStatus ? '1' : '0';
  sReturn[nReturnPos++] = bStatus ? '0' : '1';

  sReturn[nReturnPos] = '\0';
  return sReturn;
}

/**
 * @param sCodeWord   a tristate code word consisting of the letter 0, 1, F
 */
void RCSwitch::sendTriState(const char* sCodeWord) {
  // turn the tristate code word into the corresponding bit pattern, then send it
  unsigned long code = 0;
  unsigned int length = 0;
  for (const char* p = sCodeWord; *p; p++) {
    code <<= 2L;
    switch (*p) {
      case '0':
        // bit pattern 00
        break;
      case 'F':
        // bit pattern 01
        code |= 1L;
        break;
      case '1':
        // bit pattern 11
        code |= 3L;
        break;
    }
    length += 2;
  }
  this->send(code, length);
}

/**
 * @param sCodeWord   a binary code word consisting of the letter 0, 1
 */
void RCSwitch::send(const char* sCodeWord) {
  // turn the tristate code word into the corresponding bit pattern, then send it
  unsigned long code = 0;
  unsigned int length = 0;
  for (const char* p = sCodeWord; *p; p++) {
    code <<= 1L;
    if (*p != '0')
      code |= 1L;
    length++;
  }
  this->send(code, length);
}

/**
 * Transmit the first 'length' bits of the integer 'code'. The
 * bits are sent from MSB to LSB, i.e., first the bit at position length-1,
 * then the bit at position length-2, and so on, till finally the bit at position 0.
 */
void RCSwitch::send(unsigned long code, unsigned int length) {
  if (this->nTransmitterPin == -1)
    return;

#if not defined( RCSwitchDisableReceiving )
  // make sure the receiver is disabled while we transmit
  int nReceiverInterrupt_backup = nReceiverInterrupt;
  if (nReceiverInterrupt_backup != -1) {
    this->disableReceive();
  }
#endif

  for (int nRepeat = 0; nRepeat < nRepeatTransmit; nRepeat++) {
    for (int i = length-1; i >= 0; i--) {
      if (code & (1L << i))
        this->transmit(protocol.one);
      else
        this->transmit(protocol.zero);
    }
    this->transmit(protocol.syncFactor);
  }

  // Disable transmit after sending (i.e., for inverted protocols)
  digitalWrite(this->nTransmitterPin, LOW);

#if not defined( RCSwitchDisableReceiving )
  // enable receiver again if we just disabled it
  if (nReceiverInterrupt_backup != -1) {
    this->enableReceive(nReceiverInterrupt_backup);
  }
#endif
}

/**
 * Transmit a single high-low pulse.
 */
void RCSwitch::transmit(HighLow pulses) {
  uint8_t firstLogicLevel = (this->protocol.invertedSignal) ? LOW : HIGH;
  uint8_t secondLogicLevel = (this->protocol.invertedSignal) ? HIGH : LOW;

  digitalWrite(this->nTransmitterPin, firstLogicLevel);
  delayMicroseconds( this->protocol.pulseLength * pulses.high);
  digitalWrite(this->nTransmitterPin, secondLogicLevel);
  delayMicroseconds( this->protocol.pulseLength * pulses.low);
}


#if not defined( RCSwitchDisableReceiving )
/**
 * Enable receiving data
 */
void RCSwitch::enableReceive(int interrupt) {
  this->nReceiverInterrupt = interrupt;
  this->enableReceive();
}

void RCSwitch::enableReceive() {
  if (this->nReceiverInterrupt != -1) {
    RCSwitch::nReceivedValue = 0;
    RCSwitch::nReceivedBitlength = 0;
#if defined(RaspberryPi) // Raspberry Pi
    wiringPiISR(this->nReceiverInterrupt, INT_EDGE_BOTH, &handleInterrupt);
#else // Arduino
    attachInterrupt(this->nReceiverInterrupt, handleInterrupt, CHANGE);
#endif
  }
}

/**
 * Disable receiving data
 */
void RCSwitch::disableReceive() {
#if not defined(RaspberryPi) // Arduino
  detachInterrupt(this->nReceiverInterrupt);
#endif // For Raspberry Pi (wiringPi) you can't unregister the ISR
  this->nReceiverInterrupt = -1;
}

bool RCSwitch::available() {
  return RCSwitch::nReceivedValue != 0;
}

void RCSwitch::resetAvailable() {
  RCSwitch::nReceivedValue = 0;
}

unsigned long RCSwitch::getReceivedValue() {
  return RCSwitch::nReceivedValue;
}

unsigned int RCSwitch::getReceivedBitlength() {
  return RCSwitch::nReceivedBitlength;
}

unsigned int RCSwitch::getReceivedDelay() {
  return RCSwitch::nReceivedDelay;
}

unsigned int RCSwitch::getReceivedProtocol() {
  return RCSwitch::nReceivedProtocol;
}

unsigned int* RCSwitch::getReceivedRawdata() {
  return RCSwitch::timings;
}

/* helper function for the receiveProtocol method */
static inline unsigned int diff(int A, int B) {
  return abs(A - B);
}

/**
 *
 */
bool RECEIVE_ATTR RCSwitch::receiveProtocol(const int p, unsigned int changeCount) {
#if defined(ESP8266) || defined(ESP32)
    const Protocol &pro = proto[p-1];
#else
    Protocol pro;
    memcpy_P(&pro, &proto[p-1], sizeof(Protocol));
#endif

    unsigned long code = 0;
    //Assuming the longer pulse length is the pulse captured in timings[0]
    const unsigned int syncLengthInPulses =  ((pro.syncFactor.low) > (pro.syncFactor.high)) ? (pro.syncFactor.low) : (pro.syncFactor.high);
    const unsigned int delay = RCSwitch::timings[0] / syncLengthInPulses;
    const unsigned int delayTolerance = delay * RCSwitch::nReceiveTolerance / 100;

    /* For protocols that start low, the sync period looks like
     *               _________
     * _____________|         |XXXXXXXXXXXX|
     *
     * |--1st dur--|-2nd dur-|-Start data-|
     *
     * The 3rd saved duration starts the data.
     *
     * For protocols that start high, the sync period looks like
     *
     *  ______________
     * |              |____________|XXXXXXXXXXXXX|
     *
     * |-filtered out-|--1st dur--|--Start data--|
     *
     * The 2nd saved duration starts the data
     */
    const unsigned int firstDataTiming = (pro.invertedSignal) ? (2) : (1);

    for (unsigned int i = firstDataTiming; i < changeCount - 1; i += 2) {
        code <<= 1;
        if (diff(RCSwitch::timings[i], delay * pro.zero.high) < delayTolerance &&
            diff(RCSwitch::timings[i + 1], delay * pro.zero.low) < delayTolerance) {
            // zero
        } else if (diff(RCSwitch::timings[i], delay * pro.one.high) < delayTolerance &&
                   diff(RCSwitch::timings[i + 1], delay * pro.one.low) < delayTolerance) {
            // one
            code |= 1;
        } else {
            // Failed
            return false;
        }
    }

    if (changeCount > 7) {    // ignore very short transmissions: no device sends them, so this must be noise
        RCSwitch::nReceivedValue = code;
        RCSwitch::nReceivedBitlength = (changeCount - 1) / 2;
        RCSwitch::nReceivedDelay = delay;
        RCSwitch::nReceivedProtocol = p;
        return true;
    }

    return false;
}

void RECEIVE_ATTR RCSwitch::handleInterrupt() {

  static unsigned int changeCount = 0;
  static unsigned long lastTime = 0;
  static unsigned int repeatCount = 0;

  const long time = micros();
  const unsigned int duration = time - lastTime;

  if (duration > RCSwitch::nSeparationLimit) {
    // A long stretch without signal level change occurred. This could
    // be the gap between two transmission.
    if (diff(duration, RCSwitch::timings[0]) < 200) {
      // This long signal is close in length to the long signal which
      // started the previously recorded timings; this suggests that
      // it may indeed by a a gap between two transmissions (we assume
      // here that a sender will send the signal multiple times,
      // with roughly the same gap between them).
      repeatCount++;
      if (repeatCount == 2) {
        for(unsigned int i = 1; i <= numProto; i++) {
          if (receiveProtocol(i, changeCount)) {
            // receive succeeded for protocol i
            break;
          }
        }
        repeatCount = 0;
      }
    }
    changeCount = 0;
  }

  // detect overflow
  if (changeCount >= RCSWITCH_MAX_CHANGES) {
    changeCount = 0;
    repeatCount = 0;
  }

  RCSwitch::timings[changeCount++] = duration;
  lastTime = time;
}
#endif
EOF
#create send.cpp
cat > send.cpp << EOF
#include "RCSwitch.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    int PIN           = 0;
    int protocol      = atoi(argv[1]);
    char* systemCode  = argv[2];
    int unitCode      = atoi(argv[3]);
    int command       = atoi(argv[4]);

    if (wiringPiSetup () == -1) {
      return 1;
    }
    RCSwitch mySwitch = RCSwitch();
    mySwitch.enableTransmit(PIN);
    if(protocol == 8) {
      mySwitch.setProtocol(protocol);
      mySwitch.send(systemCode, 12);
    } else {
      mySwitch.setProtocol(protocol);
      switch(command) {
          case 1:
              mySwitch.switchOn(systemCode, unitCode);
              break;
          case 0:
              mySwitch.switchOff(systemCode, unitCode);
              break;
          default:
              return -1;
      }
    }
return 0;
}
EOF
#compile send binary
g++ -DRPI -c -o RCSwitch.o RCSwitch.cpp > /dev/null 2>&1
g++ -DRPI -c -o send.o send.cpp > /dev/null 2>&1
g++ -DRPI RCSwitch.o send.o -o send -lwiringPi > /dev/null 2>&1
#copy send binary in homebridge user folder
sudo cp send /var/homebridge/
#leave rc-switch directory
cd ~/
#create config.json in /var/homebridge
echo ""
echo "create homebridge config"
if [ ! -e ~/.homebridge ]; then
  timeout 20 homebridge > /dev/null 2>&1
fi
cat > config.json << EOF
{
    "bridge": {
        "name": "Homebridge",
        "username": "CC:22:3D:E3:CE:31",
        "port": 51826,
        "pin": "016-05-447"
    },

    "description": "Configuration file",

    "accessories": [
    ],

    "platforms": [
        {
            "platform" : "cmdSwitch2",
            "name": "CMD Switch",
            "switches": [{
                "name" : "Ventilator",
                "on_cmd": "sudo /var/homebridge/send 8 119",
                "off_cmd": "sudo /var/homebridge/send 8 125"
              }, {
                "name" : "Strom",
                "on_cmd": "sudo /var/homebridge/send 2 1 1 1",
                "off_cmd": "sudo /var/homebridge/send 2 1 1 0"
             }]
        }
    ]
}
EOF
#change owner of content of /var/homebridge to user homebridge
sudo mv config.json /var/homebridge
sudo chown -R homebridge:homebridge /var/homebridge
sudo systemctl daemon-reload > /dev/null 2>&1
sudo systemctl enable homebridge > /dev/null 2>&1
sudo systemctl start homebridge > /dev/null 2>&1
end=`date +%s`
runtime=$(((end-start)/60))
echo ""
echo "Displaying Homebridge QR Code. After taking a foto press 'q'"
read -p "Press enter to continue"
sudo journalctl -au homebridge
echo " _____                   _         _    _           "
echo "|  |  | ___  _____  ___ | |_  ___ |_| _| | ___  ___ "
echo "|     || . ||     || -_|| . ||  _|| || . || . || -_|"
echo "|__|__||___||_|_|_||___||___||_|  |_||___||_  ||___|"
echo "Install Script | by somebodywhoisntme     |___|     "
echo ""
echo "Installation Duration:  $runtime min"
echo ""
echo DONE! reboot system!
read -p "Press enter to continue."
sudo reboot
