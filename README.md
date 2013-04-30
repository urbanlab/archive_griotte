Raspberry Media Player
======================

Raspberry+Faye multimedia player

# Using

Start server with :

    rackup -s thin -E production server/config.ru

# Architecture

AP on Raspberry

# Channels

Channels are prefixed with device ID
Device id is built from ethernet MAC address, e.g. b8:27:eb:4a:2c:0f => b827eb4a2c0f

## System (/<deviceid>/system/)

- get status
- send system events

Commands

- mute/set master volume

## GPIO (/<deviceid>/gpio/<gpioX>)

Interface to GPIO pins.

Messages

- set pin direction
- get pin status
- set pin status
- enable/disable pull-up/pull-down

## I2C

Interface to I2C bus.

## VideoPlayer

Plays videos. Required to listen to sound message.

Events

- media started
- media paused
- media finished

Commands

- play media
- pause media
- rewind media
- change video output
- quit

## SoundPlayer

Plays sound.

## Sequencer

Orders media playlist and drives SoungPlayer & VideoPlayer.

## Storage

Stores settings :

- current video output
- volume setting (0-100, mute)
- system nickname (user-friendly name, used for access and SSID)
- language preference

## Volume

Dispatch volume settings to clients (System, VideoPlayer which volume control is
not affected by ALSA master settings).

## Sensors

Uses I2C or GPIO channel to communicate with hardware interfaces.

## KJing

KJing client interface.
