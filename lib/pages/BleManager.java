package com.nsandroidutil.ble;

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.content.Context;

import androidx.annotation.NonNull;

import com.nsandroidutil.utility.Logger;

import java.util.UUID;


import no.nordicsemi.android.ble.MtuRequest;
import no.nordicsemi.android.ble.callback.MtuCallback;


public class BleManager extends no.nordicsemi.android.ble.BleManager {

    private final static UUID IUS_SERVICE_UUID = UUID.fromString("11110001-1111-1111-1111-111111111111");
    private final static UUID IUS_RC_UUID = UUID.fromString("11110002-1111-1111-1111-111111111111");
    private final static UUID IUS_CC_UUID = UUID.fromString("11110003-1111-1111-1111-111111111111");

//    private final static UUID IUS_SERVICE_UUID = UUID.fromString("0000fd00-0000-1000-8000-00805f9b34fb");
//    private final static UUID IUS_RC_UUID = UUID.fromString("0000fd01-0000-1000-8000-00805f9b34fb");
//    private final static UUID IUS_CC_UUID = UUID.fromString("0000fd02-0000-1000-8000-00805f9b34fb");


    final static UUID DIS_SERVICE = UUID.fromString("0000180A-0000-1000-8000-00805f9b34fb");
    final static UUID DIS_MANUF = UUID.fromString("00002A29-0000-1000-8000-00805f9b34fb");
    final static UUID DIS_MODEL = UUID.fromString("00002A24-0000-1000-8000-00805f9b34fb");
    final static UUID DIS_SERIAL = UUID.fromString("00002A25-0000-1000-8000-00805f9b34fb");
    final static UUID DIS_HW = UUID.fromString("00002A27-0000-1000-8000-00805f9b34fb");
    final static UUID DIS_FW = UUID.fromString("00002A26-0000-1000-8000-00805f9b34fb");
    final static UUID DIS_SW = UUID.fromString("00002A28-0000-1000-8000-00805f9b34fb");


    private final static UUID ATM_SERVICE_UUID = UUID.fromString("04831523-6c9d-6ca9-5d41-03ad4fff4abb");
    private final static UUID ATM_CHAR_UUID = UUID.fromString("04831524-6c9d-6ca9-5d41-03ad4fff4abb");



    public BluetoothGattCharacteristic ius_rc = null;
    public BluetoothGattCharacteristic ius_cc = null;


    public BluetoothGattCharacteristic dis_manuf = null;
    public BluetoothGattCharacteristic dis_model = null;
    public BluetoothGattCharacteristic dis_serial = null;
    public BluetoothGattCharacteristic dis_hw = null;
    public BluetoothGattCharacteristic dis_fw = null;
    public BluetoothGattCharacteristic dis_sw = null;

    public BluetoothGattCharacteristic atm_char = null;

    public byte[] address = new byte[6];

    public BleManager(@NonNull Context context) {
        super(context);
    }

    private int mtu = 23;


    @NonNull
    @Override
    protected BleManagerGattCallback getGattCallback() {
        return new gattCallback();
    }

    public int getMTU(){
        return mtu - 3;
    }

    public void setMTU(int mtu){this.mtu = mtu;}

    private byte hexStringToByte(String hex) {
        char[] achar = hex.toCharArray();
        return (byte) (toByte(achar[0]) << 4 | toByte(achar[1]));
    }

    private byte toByte(char c) {
        byte b = (byte) "0123456789ABCDEF".indexOf(c);
        return b;
    }


    public void setDeviceMac(String address) {
        String[] mac = address.split(":");
        Logger.i(Logger.BLE_TAG,"mac address --> " + address);
        for(int i = 0; i<6;i++){
            this.address[i] = hexStringToByte(mac[i]);
        }

    }
    public byte[] getDeviceMac() {
        return address;
    }





    private class gattCallback extends BleManagerGattCallback {

        @Override
        protected void onServicesInvalidated() {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onServicesInvalidated------------");

        }

        @Override
        protected void initialize() {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : initialize");
            if(ius_cc != null) {
                enableNotifications(ius_cc).enqueue();
            }

        }

        @Override
        public boolean isRequiredServiceSupported(@NonNull final BluetoothGatt gatt) {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : isRequiredServiceSupported");
            final BluetoothGattService ius = gatt.getService(IUS_SERVICE_UUID);
            if (ius != null) {
                Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : service found");
                ius_rc = ius.getCharacteristic(IUS_RC_UUID);
                ius_cc = ius.getCharacteristic(IUS_CC_UUID);
                if (ius_rc != null && ius_cc != null) {
                    Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : ius char found");
                }
            }
            final BluetoothGattService dis = gatt.getService(DIS_SERVICE);
            if (dis != null) {
                dis_manuf = dis.getCharacteristic(DIS_MANUF);
                dis_model = dis.getCharacteristic(DIS_MODEL);
                dis_serial = dis.getCharacteristic(DIS_SERIAL);
                dis_hw = dis.getCharacteristic(DIS_HW);
                dis_fw = dis.getCharacteristic(DIS_FW);
                dis_sw = dis.getCharacteristic(DIS_SW);
                if (dis_manuf != null && dis_model != null && dis_serial != null && dis_hw != null && dis_fw != null && dis_sw != null) {
                    Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : dis char found");
                }
            }
//            final BluetoothGattService atms = gatt.getService(ATM_SERVICE_UUID);
//            if (atms != null) {
//                atm_char = atms.getCharacteristic(ATM_CHAR_UUID);
//                if (atm_char != null) {
//                    Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : atm char found");
//                }
//            }


            return true;
        }

        @Override
        protected void onDeviceDisconnected() {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceDisconnected");
            ius_rc = null;
            ius_cc = null;
            dis_manuf = null;
            dis_model = null;
            dis_serial = null;
            dis_hw = null;
            dis_fw = null;
            dis_sw = null;
            atm_char = null;
        }


    }




}


