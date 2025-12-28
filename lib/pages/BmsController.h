#pragma once
#include <QObject>
#include <QBluetoothLocalDevice>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QStandardItemModel>
#include <QLowEnergyService>
#include <QLowEnergyController>
#include <QVector>
#include <QBluetoothUuid>
#include <QMap>
#include <QtBluetooth/QLowEnergyCharacteristic>
#include<QTextCodec>
#include "hmmodule.h"
#include<QQueue>
#include"BMSProtocol.h"
#include<QMutex>
#include<QWaitCondition>
#include "hmcommand.h"
class CHMModule;
static QString byteArrayToHexStr(const QByteArray &data)
{
    QString temp = "";
    QString hex = data.toHex();
    for (int i = 0; i < hex.length(); i = i + 2) {
        temp += hex.mid(i, 2) + " ";
    }

    return temp.trimmed().toUpper();
}
static char hexStrToChar(char data)
{
    if ((data >= '0') && (data <= '9')) {
        return data - 0x30;
    } else if ((data >= 'A') && (data <= 'F')) {
        return data - 'A' + 10;
    } else if ((data >= 'a') && (data <= 'f')) {
        return data - 'a' + 10;
    } else {
        return (-1);
    }
}
static QByteArray hexStrToByteArray(const QString &data)
{
    QByteArray senddata;
    int hexdata, lowhexdata;
    int hexdatalen = 0;
    int len = data.length();
    senddata.resize(len / 2);
    char lstr, hstr;

    for (int i = 0; i < len;) {
        hstr = data.at(i).toLatin1();
        if (hstr == ' ') {
            i++;
            continue;
        }

        i++;
        if (i >= len) {
            break;
        }

        lstr = data.at(i).toLatin1();
        hexdata = hexStrToChar(hstr);
        lowhexdata = hexStrToChar(lstr);

        if ((hexdata == 16) || (lowhexdata == 16)) {
            break;
        } else {
            hexdata = hexdata * 16 + lowhexdata;
        }

        i++;
        senddata[hexdatalen] = (char)hexdata;
        hexdatalen++;
    }

    senddata.resize(hexdatalen);
    return senddata;
}

static unsigned short crc16_ccitt(const char *buf, int len)
{
    unsigned short crc = 0;
    for (int i = 0; i < len; ++i)
    {
        crc = (crc << 8) ^ crc16tab[((crc >> 8) ^ (static_cast<quint8>(buf[i]))) & 0xFF];
    }
    return crc;
}
//public QObject
class BmsController : public CHMCommand
{
    Q_OBJECT
public:
    explicit BmsController(QObject *parent = nullptr, const QString &name = "");

    ~BmsController();

    void searchCharacteristic();

    void viewWriteMessage(const QVariantMap &op);
    void connectBlue(const QString addr);


    virtual  bool isCommand(const QString& command) override;
    virtual void processCommand(const QString &command, const QVariantMap &op, QVariant &result) override;
    virtual void initCommands() override;
    virtual void processOp(const QVariantMap &op) override;
    virtual void clearBuf() override;
    virtual void appendCommand(const QVariantMap &op) override;
    virtual void sendOp(const QVariantMap &op) override;
    virtual void onHeartbeatTimer() override;
    bool onSendCommand(const QVariantMap &op) ;
    bool onSeceiveCommand(const QVariantMap &op);


signals:
    void startBlue();
    void writeOperationCompleted(bool success, const QString &error);
    void updateCommand(QVariantMap&, QVariant&);
public slots:
    void initBle();

    void onWriteTimeout();

    void viewMessage(const int type);
    void SendMsg(const QByteArray&);
    void startSearch();
    void onDescriptorWritten(const QLowEnergyDescriptor& descriptor, const QByteArray& value);

    void findFinish();

    void addBlueToothDevicesToList(QBluetoothDeviceInfo);

    void serviceDiscovered(const QBluetoothUuid & serviceUuid);

    void serviceScanDone();

    void serviceStateChanged(QLowEnergyService::ServiceState s);

    void BleServiceCharacteristicWrite(const QLowEnergyCharacteristic &c, const QByteArray &value);

    void BleServiceCharacteristicChanged(const QLowEnergyCharacteristic &c, const QByteArray &value);

    void BleServiceCharacteristicRead(const QLowEnergyCharacteristic &c, const QByteArray &value);
    void sendMsgByQueue();
    void getProtectMsgSlot(const int type);

    void getTimerDataSignalSlot(const int type);
    QVariantMap sendSync(const QVariantMap &op, int timeout);

    void processNextWriteRequest();
    void clearAllResourcesForNextConnect();
    void connectSec(const QString newAddr);
    void initViewData();
    void actuallyStartBleScan();
public:
    bool isScanConn = false;
    QSet<QString> scanBlueList;
    bool isSearching = false;
private:
    CHMModule *selfObj;
    BMSProtocol protocal;

    QBluetoothDeviceDiscoveryAgent *Discovery;

    QStandardItemModel *item;

    QBluetoothDeviceInfo currentDevice;

    QVector<QBluetoothDeviceInfo> deviceList;


    QLowEnergyCharacteristic  mCharacteristic;
    QLowEnergyCharacteristic m_Characteristic[3];

    QLowEnergyController * mController = nullptr;

    QVector<QLowEnergyService *> serviceList;
    QLowEnergyService *currentService;

    bool isItemchoose = false;

    // 定义发送队列和定时器
    QQueue<QByteArray> commandQueue;
    QTimer sendTimer;
    QTimer connectTimer;

    QQueue<QByteArray> writeQueue;
    bool isWriting = false;

    const QBluetoothUuid SERVICE_UUID = QBluetoothUuid(QUuid("00002760-08C2-11E1-9073-0E8AC72E1001"));
    const QBluetoothUuid WRITE_UUID   = QBluetoothUuid(QUuid("00002760-08C2-11E1-9073-0E8AC72E0001"));
    const QBluetoothUuid NOTIFY_UUID  = QBluetoothUuid(QUuid("00002760-08C2-11E1-9073-0E8AC72E0002"));

    QTimer m_writeTimeoutTimer;
    bool m_waitingWriteResponse;

    int cellNums;

    bool isConnected = false;
    QVariantList cellVlist;
    QVariantMap protectMap;
    QList<int> initCmdList{24, 0, 1, 2,3,4,6,
                           8, 10, 12,14 ,15,16,
                           17,18,19,20,21,22,
                           23,26,27,1028,
                           29,30,31};
    int alarmCount = 0;
private:
    QMutex m_syncMutex;
    QWaitCondition m_syncCondition;
    QByteArray m_lastSyncResponse;
    bool m_waitingForResponse = false;
    int m_currentSyncCmd = -1;
    QElapsedTimer m_syncTimer;
    bool isFirstCells = true;


    typedef bool (BmsController::*func)(const QVariantMap &op);
    QMap<QString, BmsController::func> selfCommands;
};
