package com.nsandroidutil.ble;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.nsandroidutil.event.BleMessageEvent;
import com.nsandroidutil.utility.CRC32_2;
import com.nsandroidutil.utility.Convertor;
import com.nsandroidutil.utility.FileHelper;
import com.nsandroidutil.utility.FileUtils;
import com.nsandroidutil.utility.Logger;
import com.nsandroidutil.utility.ZipHelper;

import org.greenrobot.eventbus.EventBus;

import java.io.File;
import java.util.concurrent.locks.LockSupport;

import no.nordicsemi.android.ble.ConditionalWaitRequest;
import no.nordicsemi.android.ble.RequestQueue;
import no.nordicsemi.android.ble.callback.BeforeCallback;
import no.nordicsemi.android.ble.callback.DataReceivedCallback;
import no.nordicsemi.android.ble.callback.DataSentCallback;
import no.nordicsemi.android.ble.callback.FailCallback;
import no.nordicsemi.android.ble.callback.SuccessCallback;
import no.nordicsemi.android.ble.callback.WriteProgressCallback;
import no.nordicsemi.android.ble.data.Data;
import no.nordicsemi.android.ble.data.DataSplitter;
import no.nordicsemi.android.ble.observer.ConnectionObserver;

public class BleOTA{

    private byte OTA_CMD_CONN_PARAM_UPDATE = 0x01;
    private byte OTA_CMD_MTU_UPDATE = 0x02;
    private byte OTA_CMD_VERSION = 0x03;
    private byte OTA_CMD_CREATE_OTA_SETTING = 0x04;
    private byte OTA_CMD_CREATE_OTA_IMAGE = 0x05;
    private byte OTA_CMD_VALIDATE_OTA_IMAGE = 0x06;
    private byte OTA_CMD_ACTIVATE_OTA_IMAGE = 0x07;
    private byte OTA_CMD_JUMP_IMAGE_UPDATE = 0x08;




    private byte OTA_CMD_ERROR_CODE_SUCCESS = 0x00;
    private byte OTA_CMD_ERROR_CODE_INVALID_PARAM = 0x01;
    private byte OTA_CMD_ERROR_CODE_CRC_FAIL = 0x02;
    private byte OTA_CMD_ERROR_CODE_SIGNATURE_FAIL = 0x03;

    private BleManager bleManager;
    private int ota_error = 0;
    private Thread thread;

    private BluetoothAdapter mBleAdapter;

    private int app1_bin_size = 0;
    private int app2_bin_size = 0;
    private int image_update_bin_size = 0;
    private int image_update_version = 0;
    private int dfu_setting_size = 0;
    private int ota_selection = 0;
    private String unzipFilePath = null;

    private String dfu_image_path = null;
    private int dfu_image_size = 0;
    private int dfu_image_sent = 0;

    private Context mContext;

    private int image_offset = 0;
    private int image_size = 0;
    private int image_crc = 0;

    public BleOTA(@NonNull Context context, BleManager bleManager, BluetoothAdapter bleAdapter) {
        this.bleManager = bleManager;
        this.mBleAdapter = bleAdapter;
        this.mContext = context;
    }





    public void fileOpen(Context context, final Uri uri){
        String configStr = null;
        //String zipFilePath = FileHelper.getFilePathByUri(context,uri);
        //unzipFilePath = new File(FileHelper.getFilePathByUri(context,uri)).getParent() + "/OTA";

        FileUtils fileUtils = new FileUtils(context);
        String zipFilePath = fileUtils.getPath(uri);
        unzipFilePath = Environment.getExternalStorageDirectory() + "/OTA";
        File file = new File(unzipFilePath);
        if (file.exists()) {
            FileHelper.deleteRecursive(file);
        }
        if (file.mkdir()){
            try{
                new ZipHelper().UnZipFolder(zipFilePath, unzipFilePath);
                File configFile = new File(unzipFilePath + "/config.txt");
                if(!configFile.exists()){
                    EventBus.getDefault().postSticky(new BleMessageEvent(BleMessageEvent.TYPE_OTA_CONFIG_FILE_ERROR, "升级包错误"));
                    return;
                }
                configStr = FileHelper.readFile(configFile.getPath());
            }catch (Exception e) {
                e.printStackTrace();
                EventBus.getDefault().postSticky(new BleMessageEvent(BleMessageEvent.TYPE_OTA_CONFIG_FILE_ERROR, "升级包错误"));
                return;
            }

            File APP1BIN = new File(unzipFilePath + "/APP1.bin");
            File APP2BIN = new File(unzipFilePath + "/APP2.bin");
            File IMAGEUPDATEBIN = new File(unzipFilePath + "/ImageUpdate.bin");
            File DFU_SETTING = new File(unzipFilePath + "/dfu_setting.dat");

            if(APP1BIN.exists()) app1_bin_size = (int) APP1BIN.length();
            if(APP2BIN.exists()) app2_bin_size = (int) APP2BIN.length();
            if(IMAGEUPDATEBIN.exists()) {
                String[] confStrs = configStr.split(System.lineSeparator());
                int index = 0;
                for(index = 0; index<confStrs.length;index++){
                    if(confStrs[index].contains("IMAGE_UPDATE_VERSION")){
                        break;
                    }
                }
                String versionStr = confStrs[index].split(":")[1].substring(3,11);
                image_update_version = Integer.valueOf(versionStr, 16);
                image_update_bin_size = (int) IMAGEUPDATEBIN.length();
            }
            if(DFU_SETTING.exists()) dfu_setting_size = (int) DFU_SETTING.length();



            EventBus.getDefault().postSticky(new BleMessageEvent(BleMessageEvent.TYPE_OTA_CONFIG_FILE, configStr));



        }else
            Toast.makeText(context, " failed to create DFU_file folder", Toast.LENGTH_SHORT).show();
    }




    private boolean threadBlock(long milliSecond, String errorMessage){
        long startNanos = System.nanoTime();
        LockSupport.parkNanos(thread, milliSecond*1000*1000);
        long durationNanos = System.nanoTime() - startNanos;
        if(durationNanos>milliSecond*1000*1000) {
            bleManager.setNotificationCallback(bleManager.ius_cc).with(null);
            EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, errorMessage+" timeout", ota_error));
            return false;
        }
        else return true;
    }

    private void threadBlock(long milliSecond){
        LockSupport.parkNanos(thread, milliSecond*1000*1000);
    }


    private boolean update_images(int prn, int interval_max){

        int mtu = 247;//max 247 min 23
        image_offset = 0;
        image_size = 0;
        image_crc = 0;
        dfu_image_sent = 0;

        //更新连接间隙
        connection_update(15,interval_max,0,500);
        if(!threadBlock(10000, "connection_update")){return false;}
        if(ota_error>0){return false;}
        EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "connection update..."));
        //更新MTU大小
        if(bleManager.getMTU() < (mtu-3)) {
            mtu_update(mtu);
            if(!threadBlock(1000, "mtu_update")){return false;}
            if(ota_error>0){return false;}
            bleManager.overrideMtu(mtu);
            bleManager.setMTU(mtu);
        }
        EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_MTU_UPDATE, (mtu-3)));
        EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "mtu update..."));
        //获取版本号和升级方式
        version_request(app1_bin_size,app2_bin_size,image_update_bin_size,image_update_version);
        if(!threadBlock(10000, "version_request")){return false;}
        if(ota_error>0){return false;}
        EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "version request..."));
        if(ota_selection == 4){
            //直接跳入Image Update程序
            jump_to_image_update();
            if(!threadBlock(5000, "jump_to_image_update")){return false;}
            if(ota_error>0){return false;}
            EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "jump_to_image_update..."));
        }else{
            //创建setting文件流
            create_ota_setting_transfer(dfu_setting_size);
            if(!threadBlock(2000, "create_ota_setting_transfer")){return false;}
            if(ota_error>0){return false;}
            EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "create_ota_setting_transfer..."));
            //发送setting文件，通过RC特性发送，CC特征接收结果
            byte[] setting_data = FileHelper.readFile(unzipFilePath + "/dfu_setting.dat",0, dfu_setting_size);
            send_setting_data(setting_data);
            if(!threadBlock(30000, "send_setting_data")){return false;}
            if(ota_error>0){return false;}
            EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "send_setting_data..."));

            while(image_offset < dfu_image_size){
                image_size = Math.min(dfu_image_size - image_offset, prn);
                byte[] image_data = FileHelper.readFile(dfu_image_path,image_offset, image_size);
                image_crc = CRC32_2.fast(image_data);
                //创建image文件流
                create_ota_image_transfer(image_offset,image_size,image_crc);
                if(!threadBlock(5000, "create_ota_image_transfer")){return false;}
                if(ota_error>0){return false;}
                EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "create_ota_image_transfer..."));
                //发送image文件
                send_image_data(image_data);
                if(!threadBlock(20000, "send_image_data")){return false;}
                if(ota_error>0){return false;}
                EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "send_image_data..."));
                image_offset += image_size;
            }

            //校验整个新固件
            validate_new_image();
            if(!threadBlock(10000, "validate_new_image")){return false;}
            if(ota_error>0){return false;}
            EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "validate_new_image request..."));
            //激活新固件
            activate_new_image();
            if(!threadBlock(1000, "activate_new_image")){return false;}
            if(ota_error>0){return false;}
            EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "activate_new_image request..."));

        }

        return true;
    }


    public void start(){


        thread = new Thread(new Runnable() {
            @Override
            public void run() {
                long startTime = System.currentTimeMillis();

                //升级固件
                if(!update_images(2048, 50))return;

                //如果是单Bank升级
                if(ota_selection == 3 || ota_selection == 4){
                    EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ALERT_NOTIFY));
                    //等待蓝牙断开
                    bleManager.disconnect().enqueue();
                    for(int i=0;i<5;i++){
                        threadBlock(1000);
                        if(!bleManager.isConnected())break;
                    }
                    //等待嵌入端重启
                    threadBlock(3000);
                    byte[] address = bleManager.getDeviceMac();
                    address[5] += 1;
                    //蓝牙重连Image Update程序
                    reconnect_to_image_update(address);
                    if(!threadBlock(10000, "reconnect_to_image_update")){return;}
                    EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "reconnect_to_image_update..."));

                    //升级固件Bank 1
                    if(!update_images(2048, 50))return;

                }


                long durationTime = System.currentTimeMillis() - startTime;

                EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_MESSAGE, "OTA Finish in " + String.valueOf(durationTime/1000.0)+ "s" + ", PRN : " + String.valueOf(2048)));
                EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_FINISH));


                bleManager.disconnect().enqueue();

            }
        });
        thread.start();
    }
    private void reconnect_to_image_update(final byte[] address) {
        Logger.i(Logger.BLE_TAG, "reconnect_to_image_update");
        final BluetoothDevice device = mBleAdapter.getRemoteDevice(address);
        if(device != null){
            bleManager.connect(device)
                    .retry(50, 100)
                    .useAutoConnect(false)
                    .before(new BeforeCallback() {
                        @Override
                        public void onRequestStarted(@NonNull BluetoothDevice device) {
                            Logger.i(Logger.BLE_TAG, "start connect to image update device --> " + device.getAddress());
                        }
                    })
                    .done(new SuccessCallback() {
                        @Override
                        public void onRequestCompleted(@NonNull BluetoothDevice device) {
                            Logger.i(Logger.BLE_TAG, "connect to image update device --> " + device.getAddress());
                            LockSupport.unpark(thread);
                        }
                    })
                    .fail(new FailCallback() {
                        @Override
                        public void onRequestFailed(@NonNull BluetoothDevice device, int status) {
                            EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "reconnect_to_image_update", 1));
                        }
                    })
                    .enqueue();

        }

    }

    private void jump_to_image_update() {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : jump_to_image_update");
        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : jump_to_image_update response");
            Logger.i(Logger.BLE_TAG, data.getValue());
            byte[] response = data.getValue();
            ota_error = response[1];
            if(ota_error>0)EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "jump_to_image_update", ota_error));
            if(data.getValue()[0] == OTA_CMD_JUMP_IMAGE_UPDATE) LockSupport.unpark(thread);
        });
        byte[] data = new byte[1];
        data[0] = OTA_CMD_JUMP_IMAGE_UPDATE;
        bleManager.writeCharacteristic(bleManager.ius_cc, data).enqueue();
    }

    private void activate_new_image() {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : activate_new_image");
        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : activate_new_image response");
            Logger.i(Logger.BLE_TAG, data.getValue());
            byte[] response = data.getValue();
            ota_error = response[1];
            if(ota_error>0)EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "activate_new_image", ota_error));
            if(data.getValue()[0] == OTA_CMD_ACTIVATE_OTA_IMAGE) LockSupport.unpark(thread);
        });
        byte[] data = new byte[1];
        data[0] = OTA_CMD_ACTIVATE_OTA_IMAGE;
        bleManager.writeCharacteristic(bleManager.ius_cc, data).enqueue();
    }

    private void validate_new_image() {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : validate_new_image");
        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : validate_new_image response");
            Logger.i(Logger.BLE_TAG, data.getValue());
            byte[] response = data.getValue();
            ota_error = response[1];
            if(ota_error>0)EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "validate_new_image", ota_error));
            if(data.getValue()[0] == OTA_CMD_VALIDATE_OTA_IMAGE) LockSupport.unpark(thread);
        });
        byte[] data = new byte[1];
        data[0] = OTA_CMD_VALIDATE_OTA_IMAGE;
        bleManager.writeCharacteristic(bleManager.ius_cc, data).enqueue();
    }


    private void send_image_data(byte[] image_data) {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : send_image_data");
        Logger.i(Logger.BLE_TAG, image_data);
        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : send_image_data response");
            byte[] response = data.getValue();
            ota_error = response[1];
            if(ota_error>0)EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "send_image_data", ota_error));
            if(data.getValue()[0] == OTA_CMD_CREATE_OTA_IMAGE) LockSupport.unpark(thread);
        });
        bleManager.writeCharacteristic(bleManager.ius_rc, image_data).split(new WriteProgressCallback() {
            @Override
            public void onPacketSent(@NonNull BluetoothDevice device, @Nullable byte[] data, int index) {
                dfu_image_sent += data.length;
                int progress = dfu_image_sent*100/dfu_image_size;
                EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_PROGRESS, progress));
            }
        }).done(new SuccessCallback() {
            @Override
            public void onRequestCompleted(@NonNull BluetoothDevice device) {
                Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : send_image_data onRequestCompleted");
            }
        }).enqueue();
    }

    private void create_ota_image_transfer(int image_offset, int image_size, int image_crc) {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : create_ota_image_transfer");
        byte[] data = new byte[13];
        data[0] = OTA_CMD_CREATE_OTA_IMAGE;
        data[1] = (byte)(image_offset>>24);
        data[2] = (byte)(image_offset>>16);
        data[3] = (byte)(image_offset>>8);
        data[4] = (byte)(image_offset);
        data[5] = (byte)(image_size>>24);
        data[6] = (byte)(image_size>>16);
        data[7] = (byte)(image_size>>8);
        data[8] = (byte)(image_size);
        data[9] = (byte)(image_crc>>24);
        data[10] = (byte)(image_crc>>16);
        data[11] = (byte)(image_crc>>8);
        data[12] = (byte)(image_crc);
        bleManager.writeCharacteristic(bleManager.ius_cc, data).done(new SuccessCallback() {
            @Override
            public void onRequestCompleted(@NonNull BluetoothDevice device) {
                LockSupport.unpark(thread);
            }
        }).enqueue();
    }

    private void send_setting_data(byte[] setting_data) {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : send_setting_data");
        Logger.i(Logger.BLE_TAG, setting_data);

        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : send_setting_data response");
            Logger.i(Logger.BLE_TAG, data.getValue());
            byte[] response = data.getValue();
            ota_error = response[1];
            if(ota_error>0)EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "send_setting_data", ota_error));
            if(data.getValue()[0] == OTA_CMD_CREATE_OTA_SETTING) LockSupport.unpark(thread);
        });
        bleManager.writeCharacteristic(bleManager.ius_rc, setting_data).split(new WriteProgressCallback() {
            @Override
            public void onPacketSent(@NonNull BluetoothDevice device, @Nullable byte[] data, int index) {

            }
        }).done(new SuccessCallback() {
            @Override
            public void onRequestCompleted(@NonNull BluetoothDevice device) {

            }
        }).enqueue();
    }

    private void create_ota_setting_transfer(int dfu_setting_size) {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : ota_setting_transfer");
        byte[] data = new byte[5];
        data[0] = OTA_CMD_CREATE_OTA_SETTING;
        data[1] = (byte)(dfu_setting_size>>24);
        data[2] = (byte)(dfu_setting_size>>16);
        data[3] = (byte)(dfu_setting_size>>8);
        data[4] = (byte)(dfu_setting_size);
        bleManager.writeCharacteristic(bleManager.ius_cc, data).done(new SuccessCallback() {
            @Override
            public void onRequestCompleted(@NonNull BluetoothDevice device) {
                LockSupport.unpark(thread);
            }
        }).enqueue();
    }

    private void version_request(int app1_bin_size, int app2_bin_size, int image_update_bin_size, int image_update_version) {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : version_request");
        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : version_request response");
            Logger.i(Logger.BLE_TAG, data.getValue());
            ota_error = 0;
            byte[] app1_version_b = new byte[4];
            System.arraycopy(data.getValue(), 1, app1_version_b, 0, 4);
            int app1_version_i = Convertor.bytesToInt(app1_version_b);
            byte[] app2_version_b = new byte[4];
            System.arraycopy(data.getValue(), 5, app2_version_b, 0, 4);
            int app2_version_i = Convertor.bytesToInt(app2_version_b);
            byte[] image_update_version_b = new byte[4];
            System.arraycopy(data.getValue(), 9, image_update_version_b, 0, 4);
            int image_update_version_i = Convertor.bytesToInt(image_update_version_b);
            ota_selection = data.getValue()[13];
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : app1_version_i --> 0x" + Integer.toHexString(app1_version_i));
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : app2_version_i --> 0x" + Integer.toHexString(app2_version_i));
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : image_update_version_i --> 0x" + Integer.toHexString(image_update_version_i));
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : ota_selection --> " + String.valueOf(ota_selection));

            if(ota_selection == 1){
                dfu_image_path = unzipFilePath + "/APP1.bin";
                dfu_image_size = app1_bin_size;
            }else if(ota_selection == 2){
                dfu_image_path = unzipFilePath + "/APP2.bin";
                dfu_image_size = app2_bin_size;
            }else if(ota_selection == 3){
                dfu_image_path = unzipFilePath + "/ImageUpdate.bin";
                dfu_image_size = image_update_bin_size;
            }

            if(ota_selection>=1 && ota_selection <= 4){
                if(data.getValue()[0] == OTA_CMD_VERSION) LockSupport.unpark(thread);
            }else{
                ota_error = 1;
                EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "version_request", 1));
            }
        });
        byte[] data = new byte[17];
        data[0] = OTA_CMD_VERSION;
        data[1] = (byte)(app1_bin_size>>24);
        data[2] = (byte)(app1_bin_size>>16);
        data[3] = (byte)(app1_bin_size>>8);
        data[4] = (byte)(app1_bin_size);
        data[5] = (byte)(app2_bin_size>>24);
        data[6] = (byte)(app2_bin_size>>16);
        data[7] = (byte)(app2_bin_size>>8);
        data[8] = (byte)(app2_bin_size);
        data[9] = (byte)(image_update_bin_size>>24);
        data[10] = (byte)(image_update_bin_size>>16);
        data[11] = (byte)(image_update_bin_size>>8);
        data[12] = (byte)(image_update_bin_size);
        data[13] = (byte)(image_update_version>>24);
        data[14] = (byte)(image_update_version>>16);
        data[15] = (byte)(image_update_version>>8);
        data[16] = (byte)(image_update_version);
        bleManager.writeCharacteristic(bleManager.ius_cc, data).enqueue();

    }


    private void connection_update(int interval_min, int interval_max, int latency, int timeout)  {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : connection_update");
        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : connection_update response");
            Logger.i(Logger.BLE_TAG, data.getValue());
            byte[] response = data.getValue();
            ota_error = response[1];
            if(ota_error>0)EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "connection_update", ota_error));
            if(data.getValue()[0] == OTA_CMD_CONN_PARAM_UPDATE) LockSupport.unpark(thread);
        });
        byte[] data = new byte[9];
        data[0] = OTA_CMD_CONN_PARAM_UPDATE;
        data[1] = (byte)(interval_min>>8);
        data[2] = (byte)(interval_min);
        data[3] = (byte)(interval_max>>8);
        data[4] = (byte)(interval_max);
        data[5] = (byte)(latency>>8);
        data[6] = (byte)(latency);
        data[7] = (byte)(timeout>>8);
        data[8] = (byte)(timeout);
        bleManager.writeCharacteristic(bleManager.ius_cc, data).enqueue();
    }

    private void mtu_update(int mtu){
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : mtu_update");
        bleManager.setNotificationCallback(bleManager.ius_cc).with((device, data) -> {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : mtu_update response");
            Logger.i(Logger.BLE_TAG, data.getValue());
            byte[] response = data.getValue();
            ota_error = response[1];
            if(ota_error>0)EventBus.getDefault().post(new BleMessageEvent(BleMessageEvent.TYPE_OTA_ERROR_MESSAGE, "mtu_update", ota_error));
            if(data.getValue()[0] == OTA_CMD_MTU_UPDATE) LockSupport.unpark(thread);
        });
        byte[] data = new byte[3];
        data[0] = OTA_CMD_MTU_UPDATE;
        data[1] = (byte)(mtu>>8);
        data[2] = (byte)(mtu);
        bleManager.writeCharacteristic(bleManager.ius_cc, data).enqueue();
    }


}
