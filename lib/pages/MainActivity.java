package com.nsandroidutil;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Point;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;

import com.nsandroidutil.ble.BleDis;
import com.nsandroidutil.ble.BleManager;
import com.nsandroidutil.ble.BleOTA;
import com.nsandroidutil.event.BleMessageEvent;
import com.nsandroidutil.permission.PermissionRationaleFragment;
import com.nsandroidutil.scanner.ScannerFragment;
import com.nsandroidutil.utility.LineGraphView;
import com.nsandroidutil.utility.Logger;
import com.nsandroidutil.utility.ViewHelper;


import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.text.DecimalFormat;
import java.util.Objects;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import no.nordicsemi.android.ble.callback.FailCallback;
import no.nordicsemi.android.ble.observer.ConnectionObserver;

public class MainActivity extends AppCompatActivity implements PermissionRationaleFragment.PermissionDialogListener, ScannerFragment.OnDeviceSelectedListener {


    private static final int PERMISSION_REQ = 100;
    private static final int REQUEST_ENABLE_BT = 101;
    private static final int REQUEST_FILE_BROWSER = 102;
    @BindView(R.id.btn_device_connect)
    Button btnDeviceConnect;
    @BindView(R.id.edt_device_name_filter)
    EditText edtDeviceNameFilter;
    @BindView(R.id.tv_device_name)
    TextView tvDeviceName;
    @BindView(R.id.tv_device_mac)
    TextView tvDeviceMac;
    @BindView(R.id.tv_conn_interval)
    TextView tvConnInterval;
    @BindView(R.id.tv_conn_latency)
    TextView tvConnLatency;
    @BindView(R.id.tv_conn_timeout)
    TextView tvConnTimeout;
    @BindView(R.id.tv_mtu)
    TextView tvMtu;
    @BindView(R.id.btn_ota)
    Button btnOta;
    @BindView(R.id.btn_ota_file)
    Button btnOtaFile;
    @BindView(R.id.pb_ota)
    ProgressBar pbOta;
    @BindView(R.id.tv_ota_status)
    TextView tvOtaStatus;
    @BindView(R.id.tv_ota_file_config)
    TextView tvOtaFileConfig;
    @BindView(R.id.ll_dev_info)
    LinearLayout llDevInfo;
    @BindView(R.id.tv_ble_ota_title)
    TextView tvBleOtaTitle;
    @BindView(R.id.ll_ble_ota)
    LinearLayout llBleOta;
    @BindView(R.id.tv_ble_dis_title)
    TextView tvBleDisTitle;
    @BindView(R.id.ll_ble_diss)
    LinearLayout llBleDiss;
    @BindView(R.id.tv_ble_dis_manuf)
    TextView tvBleDisManuf;
    @BindView(R.id.tv_ble_dis_model)
    TextView tvBleDisModel;
    @BindView(R.id.tv_ble_dis_serial)
    TextView tvBleDisSerial;
    @BindView(R.id.tv_ble_dis_hw)
    TextView tvBleDisHw;
    @BindView(R.id.tv_ble_dis_fw)
    TextView tvBleDisFw;
    @BindView(R.id.tv_ble_dis_sw)
    TextView tvBleDisSw;


    private BluetoothAdapter mBleAdapter;
    private int BTN_DEVICE_CONNECT_STATE_CONNECT = 1;
    private int BTN_DEVICE_CONNECT_STATE_CONNECTING = 2;
    private int BTN_DEVICE_CONNECT_STATE_DISCONNECT = 3;
    private int btn_device_connect_state = BTN_DEVICE_CONNECT_STATE_DISCONNECT;
    private boolean ota_file_ready = false;


    private BleManager bleManager;
    private BleOTA bleOTA = null;
    private BleDis bleDis = null;



    private String app_version_string = null;

    private ProgressDialog mProgressDialog;
    private final Handler mDisReadHandler = new Handler();


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT); // 禁用横屏

        PackageManager pm = MainActivity.this.getPackageManager();
        PackageInfo pi = null;
        try {
            pi = pm.getPackageInfo(MainActivity.this.getPackageName(), 0);
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
        app_version_string = "V" + pi.versionName;
        Objects.requireNonNull(getSupportActionBar()).setTitle(getResources().getString(R.string.app_name) + " : " + app_version_string + "    " + "Disconnected");
        setContentView(R.layout.activity_main);
        ButterKnife.bind(this);
        ViewHelper.disableSubControls(llBleOta);

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            PermissionRationaleFragment dialog = PermissionRationaleFragment.getInstance(R.string.permission_external_storage, Manifest.permission.WRITE_EXTERNAL_STORAGE);
            dialog.show(getSupportFragmentManager(), null);
        }
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            PermissionRationaleFragment dialog = PermissionRationaleFragment.getInstance(R.string.permission_coarse_location, Manifest.permission.ACCESS_COARSE_LOCATION);
            dialog.show(getSupportFragmentManager(), null);
        }
//        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH) != PackageManager.PERMISSION_GRANTED) {
//            PermissionRationaleFragment dialog = PermissionRationaleFragment.getInstance(R.string.permission_bluetooth_scan, Manifest.permission.BLUETOOTH);
//            dialog.show(getSupportFragmentManager(), null);
//        }

        final BluetoothManager manager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        if (manager != null) {
            mBleAdapter = manager.getAdapter();
            if (!mBleAdapter.isEnabled()) {
                Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
            }
        }


        bleManager = new BleManager(this);
        bleManager.setConnectionObserver(new connectionObserver());
        bleOTA = new BleOTA(this, bleManager, mBleAdapter);
        bleDis = new BleDis(this, bleManager);



    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (bleManager.isConnected()) {
            bleManager.disconnect().enqueue();
        }
        bleManager.close();
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (!EventBus.getDefault().isRegistered(this)) EventBus.getDefault().register(this);
    }

    @Override
    protected void onStop() {
        super.onStop();
        EventBus.getDefault().unregister(this);

    }

    private static int MSG_DISMISS_DIALOG = 0;
    @SuppressLint("HandlerLeak")
    private Handler mHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            // TODO Auto-generated method stub
            super.handleMessage(msg);
            if (MSG_DISMISS_DIALOG == msg.what) {
                if (null != mProgressDialog) {
                    if (mProgressDialog.isShowing()) {
                        mProgressDialog.dismiss();
                    }
                }
            }
        }
    };



    @Subscribe(sticky = true, threadMode = ThreadMode.MAIN)
    public void onBleMessageEvent(BleMessageEvent event) {
        switch (event.type) {
            case BleMessageEvent.TYPE_MTU_UPDATE: {
                tvMtu.setText(String.valueOf(event.number));
            }
            break;
            case BleMessageEvent.TYPE_OTA_ERROR_MESSAGE: {
                tvOtaStatus.setTextColor(Color.RED);
                tvOtaStatus.setText("Error : " + event.errorMessage + ", " + String.valueOf(event.errorCode));
                btnOta.setEnabled(true);
                btnOtaFile.setEnabled(true);
            }
            break;
            case BleMessageEvent.TYPE_OTA_MESSAGE: {
                tvOtaStatus.setTextColor(Color.GRAY);
                tvOtaStatus.setText(event.message);
            }
            break;
            case BleMessageEvent.TYPE_OTA_FINISH: {
                btnOta.setEnabled(true);
                btnOtaFile.setEnabled(true);
            }
            break;
            case BleMessageEvent.TYPE_OTA_CONFIG_FILE: {
                tvOtaFileConfig.setText(event.message);
                ota_file_ready = true;
            }
            break;
            case BleMessageEvent.TYPE_OTA_CONFIG_FILE_ERROR: {
                tvOtaFileConfig.setText(event.message);
                ota_file_ready = false;
            }
            break;

            case BleMessageEvent.TYPE_DIS_INFO: {
                if (bleManager.dis_manuf == event.chara) {
                    tvBleDisManuf.setText(event.deviceInfoVaule);
                }
                if (bleManager.dis_model == event.chara) {
                    tvBleDisModel.setText(event.deviceInfoVaule);
                }
                if (bleManager.dis_serial == event.chara) {
                    tvBleDisSerial.setText(event.deviceInfoVaule);
                }
                if (bleManager.dis_hw == event.chara) {
                    tvBleDisHw.setText(event.deviceInfoVaule);
                }
                if (bleManager.dis_fw == event.chara) {
                    tvBleDisFw.setText(event.deviceInfoVaule);
                }
                if (bleManager.dis_sw == event.chara) {
                    tvBleDisSw.setText(event.deviceInfoVaule);
                }
            }
            break;
            case BleMessageEvent.TYPE_OTA_PROGRESS: {
                pbOta.setProgress(event.number);
            }
            break;
            case BleMessageEvent.TYPE_OTA_ALERT_NOTIFY: {
                mProgressDialog = new ProgressDialog(this);
                mProgressDialog.setMessage("等待蓝牙自动重连");
                mProgressDialog.show();
                mHandler.sendEmptyMessageDelayed(MSG_DISMISS_DIALOG, 5000);
            }
            break;


        }


    }


    @Override
    public void onRequestPermissionsResult(final int requestCode, @NonNull final String[] permissions, @NonNull final int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        switch (requestCode) {
            case PERMISSION_REQ: {
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {

                } else {
                    finish();
                }
                break;
            }
        }
    }

    @Override
    public void onRequestPermissionGranted(String permission) {
        ActivityCompat.requestPermissions(this, new String[]{permission}, PERMISSION_REQ);
    }

    @Override
    public void onRequestPermissionDenied(String permission) {
        finish();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == REQUEST_FILE_BROWSER && resultCode == RESULT_OK) {
            final Uri uri = data.getData();
            Logger.i(Logger.BLE_TAG, "dfu file : " + uri.toString());
            try{
                bleOTA.fileOpen(this, uri);
            }catch (Exception ex){

                Logger.i(Logger.BLE_TAG, "dfu file message : " + ex.getMessage());
            }

        }
    }

    @Override
    public void onDeviceSelected(BluetoothDevice device, String name) {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceSelected " + name + "      " + device.getAddress());
        btnDeviceConnect.setEnabled(false);
        bleManager.connect(device)
                .retry(3, 1000)
                .timeout(5000)
                .fail(new FailCallback() {
                    @Override
                    public void onRequestFailed(BluetoothDevice device, int status) {
                        //失败回调
                    }
                })
                .useAutoConnect(false)
                .enqueue();

    }

    @Override
    public void onDialogCanceled() {
        Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDialogCanceled");
    }


    public class connectionObserver implements ConnectionObserver {


        @Override
        public void onDeviceConnecting(@NonNull BluetoothDevice device) {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceConnecting");
            btnDeviceConnect.setText(R.string.btn_device_connecting);
            btn_device_connect_state = BTN_DEVICE_CONNECT_STATE_CONNECTING;
            getSupportActionBar().setTitle(getResources().getString(R.string.app_name) + " : " + app_version_string + "    " + "Connecting");
        }

        @Override
        public void onDeviceConnected(@NonNull BluetoothDevice device) {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceConnected");
            tvDeviceName.setText(device.getName());
            tvDeviceMac.setText(device.getAddress());
            btnDeviceConnect.setText(R.string.btn_device_disconnect);
            btn_device_connect_state = BTN_DEVICE_CONNECT_STATE_CONNECT;

        }

        @Override
        public void onDeviceFailedToConnect(@NonNull BluetoothDevice device, int reason) {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceFailedToConnect");

            tvDeviceName.setText("");
            tvDeviceMac.setText("");
            tvConnInterval.setText("");
            tvConnLatency.setText("");
            tvConnTimeout.setText("");
            tvMtu.setText("");
            btnDeviceConnect.setText(R.string.btn_device_connect);
            btn_device_connect_state = BTN_DEVICE_CONNECT_STATE_DISCONNECT;
            btnDeviceConnect.setEnabled(true);
            tvBleOtaTitle.setTextColor(Color.GRAY);
            pbOta.setProgress(0);
            ViewHelper.disableSubControls(llBleOta);
            tvBleDisTitle.setTextColor(Color.GRAY);
            tvBleDisManuf.setText("");
            tvBleDisModel.setText("");
            tvBleDisSerial.setText("");
            tvBleDisHw.setText("");
            tvBleDisFw.setText("");
            tvBleDisSw.setText("");
            getSupportActionBar().setTitle(getResources().getString(R.string.app_name) + " : " + app_version_string + "    " + "Disconnected");
        }


        @SuppressLint("ResourceAsColor")
        @Override
        public void onDeviceReady(@NonNull BluetoothDevice device) {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceReady");
            btnDeviceConnect.setEnabled(true);
            bleManager.setMTU(23);
            tvMtu.setText(String.valueOf(bleManager.getMTU()));
            if (bleManager.ius_cc != null && bleManager.ius_rc != null) {
                tvBleOtaTitle.setTextColor(R.color.lightblue);
                ViewHelper.enableSubControls(llBleOta);
            }
            if (bleManager.dis_manuf != null && bleManager.dis_model != null && bleManager.dis_serial != null && bleManager.dis_hw != null && bleManager.dis_fw != null && bleManager.dis_sw != null) {
                tvBleDisTitle.setTextColor(R.color.lightblue);
                mDisReadHandler.postDelayed(() -> {
                    if (bleManager.dis_manuf != null && bleManager.dis_model != null && bleManager.dis_serial != null && bleManager.dis_hw != null && bleManager.dis_fw != null && bleManager.dis_sw != null)
                    {
                        tvBleDisManuf.setText("");
                        tvBleDisModel.setText("");
                        tvBleDisSerial.setText("");
                        tvBleDisHw.setText("");
                        tvBleDisFw.setText("");
                        tvBleDisSw.setText("");
                        bleDis.readDeviceInformation();

                    }
                }, 1000);
            }
            getSupportActionBar().setTitle(getResources().getString(R.string.app_name) + " : " + app_version_string + "    " + "Connected");
            bleManager.setDeviceMac(device.getAddress());
        }

        @Override
        public void onDeviceDisconnecting(@NonNull BluetoothDevice device) {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceDisconnecting");

        }

        @Override
        public void onDeviceDisconnected(@NonNull BluetoothDevice device, int reason) {
            Logger.i(Logger.BLE_TAG, this.getClass().getName() + " : onDeviceDisconnected");
            tvDeviceName.setText("");
            tvDeviceMac.setText("");
            tvConnInterval.setText("");
            tvConnLatency.setText("");
            tvConnTimeout.setText("");
            tvMtu.setText("");
            btnDeviceConnect.setText(R.string.btn_device_connect);
            btn_device_connect_state = BTN_DEVICE_CONNECT_STATE_DISCONNECT;
            btnDeviceConnect.setEnabled(true);
            tvBleOtaTitle.setTextColor(Color.GRAY);
            pbOta.setProgress(0);
            ViewHelper.disableSubControls(llBleOta);
            tvBleDisTitle.setTextColor(Color.GRAY);
            tvBleDisManuf.setText("");
            tvBleDisModel.setText("");
            tvBleDisSerial.setText("");
            tvBleDisHw.setText("");
            tvBleDisFw.setText("");
            tvBleDisSw.setText("");
            getSupportActionBar().setTitle(getResources().getString(R.string.app_name) + " : " + app_version_string + "    " + "Disconnected");

        }

        @Override
        public void onDeviceConnectionUpdated(int interval, int latency, int timeout) {
            tvConnInterval.setText(String.valueOf(interval) + "ms");
            tvConnLatency.setText(String.valueOf(latency));
            tvConnTimeout.setText(String.valueOf(timeout) + "0ms");

        }
    }


    @SuppressLint("ResourceAsColor")
    @OnClick({R.id.btn_device_connect, R.id.btn_ota, R.id.btn_ota_file, R.id.tv_ble_dis_title})
    public void onViewClicked(View view) {
        switch (view.getId()) {
            case R.id.btn_device_connect:
                if (btn_device_connect_state == BTN_DEVICE_CONNECT_STATE_DISCONNECT) {
                    final ScannerFragment dialog = ScannerFragment.getInstance(edtDeviceNameFilter.getText().toString());
                    dialog.show(getSupportFragmentManager(), "scan_fragment");
                } else if (btn_device_connect_state == BTN_DEVICE_CONNECT_STATE_CONNECT) {
                    btnDeviceConnect.setEnabled(false);
                    bleManager.disconnect().enqueue();
                }
                break;
            case R.id.btn_ota:

                if (ota_file_ready) {
                    bleOTA.start();
                    btnOta.setEnabled(false);
                    btnOtaFile.setEnabled(false);
                }


                break;
            case R.id.btn_ota_file:
                ota_file_ready = false;
                final Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
                intent.setType("*/*");
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                if (intent.resolveActivity(getPackageManager()) != null) {
                    startActivityForResult(intent, REQUEST_FILE_BROWSER);
                } else {
                    Toast.makeText(this, "no file browser", Toast.LENGTH_SHORT).show();
                }

                break;

            case R.id.tv_ble_dis_title:

                if (tvBleDisTitle.getCurrentTextColor() == R.color.lightblue) {
                    tvBleDisManuf.setText("");
                    tvBleDisModel.setText("");
                    tvBleDisSerial.setText("");
                    tvBleDisHw.setText("");
                    tvBleDisFw.setText("");
                    tvBleDisSw.setText("");
                    bleDis.readDeviceInformation();
                }

                break;


        }
    }


}
