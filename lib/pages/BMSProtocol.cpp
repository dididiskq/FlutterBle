#include "bmsprotocol.h"


static QMap<quint16, QString> registerMap = {
    {0x0000, "MOS温度1"},
    {0x0001, "电池温度1"},
    {0x0014, "SOC_SOH"},
};

BMSProtocol::BMSProtocol(QObject *parent) : QObject(parent)
{
    commands[0x0000] = [this](const QByteArray& data, int dataLen) { return deal_00(data, dataLen); };
    commands[0x0001] = [this](const QByteArray& data, int dataLen) { return deal_01(data, dataLen); };
    commands[0x0002] = [this](const QByteArray& data, int dataLen) { return deal_02(data, dataLen); };
    commands[0x0003] = [this](const QByteArray& data, int dataLen) { return deal_03(data, dataLen); };
    commands[0x0004] = [this](const QByteArray& data, int dataLen) { return deal_04(data, dataLen); };
    commands[0x0006] = [this](const QByteArray& data, int dataLen) { return deal_06(data, dataLen); };
    commands[0x0008] = [this](const QByteArray& data, int dataLen) { return deal_08(data, dataLen); };
    commands[0x000A] = [this](const QByteArray& data, int dataLen) { return deal_0A(data, dataLen); };
    commands[0x000C] = [this](const QByteArray& data, int dataLen) { return deal_0C(data, dataLen); };
    commands[0x000E] = [this](const QByteArray& data, int dataLen) { return deal_0E(data, dataLen); };
    commands[0x000F] = [this](const QByteArray& data, int dataLen) { return deal_0F(data, dataLen); };
    commands[0x0010] = [this](const QByteArray& data, int dataLen) { return deal_10(data, dataLen); };
    commands[0x0011] = [this](const QByteArray& data, int dataLen) { return deal_11(data, dataLen); };
    commands[0x0012] = [this](const QByteArray& data, int dataLen) { return deal_12(data, dataLen); };
    commands[0x0013] = [this](const QByteArray& data, int dataLen) { return deal_13(data, dataLen); };
    commands[0x0014] = [this](const QByteArray& data, int dataLen) { return deal_14(data, dataLen); };
    commands[0x0015] = [this](const QByteArray& data, int dataLen) { return deal_15(data, dataLen); };
    commands[0x0016] = [this](const QByteArray& data, int dataLen) { return deal_16(data, dataLen); };
    commands[0x0017] = [this](const QByteArray& data, int dataLen) { return deal_17(data, dataLen); };
    commands[0x0018] = [this](const QByteArray& data, int dataLen) { return deal_18(data, dataLen); };
    commands[0x0019] = [this](const QByteArray& data, int dataLen) { return deal_19(data, dataLen); };
    commands[0x001A] = [this](const QByteArray& data, int dataLen) { return deal_1A(data, dataLen); };
    commands[0x001B] = [this](const QByteArray& data, int dataLen) { return deal_1B(data, dataLen); };
    commands[0x001C] = [this](const QByteArray& data, int dataLen) { return deal_1C(data, dataLen); };
    commands[0x001D] = [this](const QByteArray& data, int dataLen) { return deal_1D(data, dataLen); };
    commands[0x001E] = [this](const QByteArray& data, int dataLen) { return deal_1E(data, dataLen); };
    commands[0x001F] = [this](const QByteArray& data, int dataLen) { return deal_1F(data, dataLen); };
    commands[0x206] = [this](const QByteArray& data, int dataLen) { return deal_206(data, dataLen); };
    //paseString
    commands[0x230] = [this](const QByteArray& data, int dataLen) { return paseString(data, dataLen); };
    commands[0x236] = [this](const QByteArray& data, int dataLen) { return paseString(data, dataLen); };
    commands[0x23A] = [this](const QByteArray& data, int dataLen) { return paseString(data, dataLen); };
    commands[0x246] = [this](const QByteArray& data, int dataLen) { return paseString(data, dataLen); };
    commands[0x256] = [this](const QByteArray& data, int dataLen) { return paseString(data, dataLen); };
    commands[0x408] = [this](const QByteArray& data, int dataLen) { return paseString(data, dataLen); };
    commands[0x24A] = [this](const QByteArray& data, int dataLen) { return paseString(data, dataLen); };
    //paseUn16And1
    commands[0x200] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x201] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x202] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x203] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x204] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x205] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x206] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x207] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x208] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x20A] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x20C] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x210] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x211] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x212] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x213] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x214] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x215] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x216] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x217] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x218] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x219] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x21A] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x21B] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x21C] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x21D] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x21E] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x21F] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x220] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x221] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    commands[0x400] = [this](const QByteArray& data, int dataLen) { return paseUn16And1(data, dataLen); };
    //paseInt16And1
    commands[0x209] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x20B] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x20D] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x222] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x223] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x224] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x225] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x226] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x227] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x228] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x229] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x22A] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    commands[0x22B] = [this](const QByteArray& data, int dataLen) { return paseInt16And1(data, dataLen); };
    // /paseUint32And2
    commands[0x402] = [this](const QByteArray& data, int dataLen) { return paseUint32And2(data, dataLen); };
    commands[0x404] = [this](const QByteArray& data, int dataLen) { return paseUint32And2(data, dataLen); };
    //paseFloatAnd2
    commands[0x20E] = [this](const QByteArray& data, int dataLen) { return paseFloatAnd2(data, dataLen); };


    //写组装函数
    //寄存器数量相同，数据段类型相同
    writeByteCommands[0x0000] = [this](const QVariantMap& data) { return byte_0000(data); };
    writeByteCommands[0x0001] = [this](const QVariantMap& data) { return byte_0001(data); };
    writeByteCommands[0x0002] = [this](const QVariantMap& data) { return byte_0002(data); };
    writeByteCommands[0x0003] = [this](const QVariantMap& data) { return byte_0003(data); };
    writeByteCommands[0x0004] = [this](const QVariantMap& data) { return byte_0004(data); };
    writeByteCommands[0x0006] = [this](const QVariantMap& data) { return byte_0006(data); };
    writeByteCommands[0x0007] = [this](const QVariantMap& data) { return byte_0007(data); };
    writeByteCommands[0x0101] = [this](const QVariantMap& data) { return byte_0101(data); };
    writeByteCommands[0x200] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x201] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x202] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x203] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x204] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x205] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x206] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x207] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x208] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x20A] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x20C] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x210] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x211] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x212] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x213] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x214] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x215] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x216] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x217] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x218] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x219] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x21A] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x21B] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x21C] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x21D] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x21E] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x21F] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x220] = [this](const QVariantMap& data) { return byte_200(data); };
    writeByteCommands[0x221] = [this](const QVariantMap& data) { return byte_200(data); };

    //数据段为string类型,数据长度不同
    writeByteCommands[0x230] = [this](const QVariantMap& data) { return byte_string(data); };
    writeByteCommands[0x236] = [this](const QVariantMap& data) { return byte_string(data); };
    writeByteCommands[0x23A] = [this](const QVariantMap& data) { return byte_string(data); };
    writeByteCommands[0x246] = [this](const QVariantMap& data) { return byte_string(data); };
    writeByteCommands[0x24A] = [this](const QVariantMap& data) { return byte_string(data); };
    writeByteCommands[0x256] = [this](const QVariantMap& data) { return byte_string(data); };
    writeByteCommands[0x418] = [this](const QVariantMap& data) { return byte_string(data); };
    //数据段为int16，寄存器为1
    writeByteCommands[0x209] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x20B] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x20D] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x222] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x223] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x224] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x225] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x226] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x227] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x228] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x229] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x22A] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    writeByteCommands[0x22B] = [this](const QVariantMap& data) { return byte_int16and1(data); };
    //uint32,寄存器为2
    writeByteCommands[0x402] = [this](const QVariantMap& data) { return byte_uint32and2(data); };
    writeByteCommands[0x404] = [this](const QVariantMap& data) { return byte_uint32and2(data); };
    //float 2
    writeByteCommands[0x20E] = [this](const QVariantMap& data) { return byte_floatand2(data); };
}
//封装报文
QByteArray BMSProtocol::byte(const QVariant &v)
{
    QVariantMap params = v.toMap();
    QByteArray frame;

    // 基础帧结构
    quint8 address = params.value("address", 0x16).toUInt(); // 默认地址0x16
    quint8 funcCode = params.value("funcCode").toUInt();

    frame.append(address);
    frame.append(funcCode);

    // 功能码分支处理
    if(funcCode == 0x03)// 读寄存器
    {
        quint16 startAddr = params.value("startAddr").toUInt();
        quint16 regCount = params.value("regCount").toUInt();

        startAddr &= 0xFFFF;
        regCount &= 0xFFFF;

        frame.append(static_cast<char>((startAddr >> 8) & 0xFF)); // 高字节
        frame.append(static_cast<char>(startAddr & 0xFF)); // 低字节
        frame.append(static_cast<char>((regCount >> 8) & 0xFF));
        frame.append(static_cast<char>(regCount & 0xFF));
    }
    else if(funcCode == 0x10)// 写寄存器
    {
        quint16 startAddr = params.value("startAddr").toUInt();
        frame.append(static_cast<char>((startAddr >> 8) & 0xFF)); // 高字节
        frame.append(static_cast<char>(startAddr & 0xFF)); // 低字节
        auto it = writeByteCommands.find(startAddr);
        QByteArray temp;
        if (it != writeByteCommands.end())
        {
            temp = it.value()(params); // 调用绑定的成员函数
        }
        else if(startAddr >= 0x418)
        {
            temp = byte_uint32and2(params);
        }
        frame.append(temp);
        // quint16 regCount = params.value("regCount").toUInt();
        // QByteArray data = params.value("data").toByteArray();
        // frame.append(static_cast<char>((regCount >> 8) & 0xFF));
        // frame.append(static_cast<char>(regCount & 0xFF));
        // frame.append(static_cast<char>(data.size()));
        // frame.append(data);
    }

    // 计算CRC并附加
    quint16 crc = calculateCRC(frame);
    crc &= 0xFFFF;
    frame.append(static_cast<char>(crc & 0xFF)); // 低字节在前
    frame.append(static_cast<char>((crc >> 8) & 0xFF));// 高字节在后

    return frame;
}
//解析报文
QVariantMap BMSProtocol::parse(const QByteArray& buf)
{
    QVariantMap result;
    if(buf.size() < 5)// 最小帧长度校验
    {
        result.insert("error", 1);
        return result;
    }

    // CRC校验
    QByteArray dataPart = buf.left(buf.size()-2);
    quint16 receivedCrc = static_cast<quint8>(buf.at(buf.size()-2)) |
                          (static_cast<quint8>(buf.at(buf.size()-1)) << 8);
    if(calculateCRC(dataPart) != receivedCrc)
    {
        result.insert("error", 1);
        return result;
    }

    // 基础字段解析
    quint16 address = static_cast<quint8>(buf.at(0));
    quint16 writeOrread = static_cast<quint8>(buf.at(1));
    quint16 funcCodeH = static_cast<quint8>(buf.at(2));
    quint16 funcCodeL = static_cast<quint8>(buf.at(3));
    quint16 funcCode = (static_cast<quint16>(funcCodeH) << 8) | funcCodeL;
    int dataLen = static_cast<quint8>(buf.at(4));
    result = procCommand(dataLen, funcCode, dataPart);
    result.insert("address", address);
    result.insert("funcCode", funcCode);
    result.insert("writeOrread", writeOrread);
    return result;
}
QVariantMap BMSProtocol::procCommand(int dataLen, quint16 cmd, const QByteArray &data)
{
    auto it = commands.find(cmd);
    if (it != commands.end())
    {
        return it.value()(data, dataLen); // 调用绑定的成员函数
    }
    if(cmd >= 0x0020 && cmd <= 0x003F)
    {
        return paseCellVs(cmd, data);
    }
    if(cmd >= 0x418)
    {
        return paseUint32And2(data, dataLen);
    }
    return {{"error", 2}};
}

QByteArray BMSProtocol::byte_200(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 1;

    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    int userInput = data.value("inputData", -1).toInt();

    // 转换为16位整数并处理字节序
    quint16 batteryCount = static_cast<quint16>(userInput);
    quint16 networkOrder = qToBigEndian(batteryCount); // 大端序转换

    // 构造数据段
    QByteArray data_(reinterpret_cast<const char*>(&networkOrder), sizeof(networkOrder));

    array.append(static_cast<char>(data_.size()));
    array.append(data_);
    return array;
}

QByteArray BMSProtocol::byte_string(const QVariantMap &data)
{
    QByteArray array;
    quint16 startAddr = data.value("startAddr").toUInt();
    quint16 regCount = 0;//变值
    if(startAddr == 0x23A ||startAddr == 0x24A)
    {
        regCount = 12;
    }
    else if(startAddr == 0x256 || startAddr == 0x246 || startAddr == 0x236)
    {
        regCount = 4;
    }
    else if(startAddr == 0x230)
    {
        regCount = 6;
    }


    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    // 获取用户输入的字符串（假设通过QLineEdit）
    QString userInput = data.value("inputData", "").toString();// "SN123456789AB"

    // 转换为固定长度的字节数组（根据协议要求length长度字节）
    QByteArray data_ = userInput.toUtf8(); // 先转为UTF-8编码

    // 协议要求长度regCount * 2字节，不足补0x00，超过截断
    if(data_.size() < regCount * 2)
    {
        data_.append(QByteArray(regCount * 2 - data.size(), 0x00)); // 填充空字符
    }
    else
    {
        data_ = data_.left(regCount * 2); // 截断前regCount * 2字节
    }
    array.append(static_cast<char>(data_.size()));
    array.append(data_);
    return array;
}

QByteArray BMSProtocol::byte_int16and1(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 1;//变值
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    int userInput = data.value("inputData", -1).toInt();

    // 转换为16位整数并处理字节序
    qint16 batteryCount = static_cast<qint16>(userInput);
    qint16 networkOrder = qToBigEndian(batteryCount); // 大端序转换

    // 构造数据段
    QByteArray data_(reinterpret_cast<const char*>(&networkOrder), sizeof(networkOrder));

    array.append(static_cast<char>(data_.size()));
    array.append(data_);
    return array;
}

QByteArray BMSProtocol::byte_uint32and2(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 2;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    // 从输入获取用户数据并转换为 quint32
    bool ok;
    quint32 userInput = data.value("inputData", 0).toUInt(&ok);
    userInput *= 1000;
    if (!ok) {
        qWarning() << "Invalid uint32 input";
        return {};
    }

    // 转换为大端序字节流
    quint32 beValue = qToBigEndian(userInput);
    QByteArray data_(reinterpret_cast<const char*>(&beValue), sizeof(beValue));


    // 添加数据长度和数据内容
    array.append(static_cast<char>(data_.size())); // 数据长度固定为4字节
    array.append(data_);
    return array;
}
QByteArray BMSProtocol::byte_floatand2(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 2;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    // 从输入获取用户数据并转换为 float
    bool ok;
    float userInput = data.value("inputData", 0.0f).toFloat(&ok);
    if (!ok)
    {
        qWarning() << "Invalid float input";
        return {};
    }
    quint32 rawValue;
    memcpy(&rawValue, &userInput, sizeof(float));  // 安全转换
    rawValue = qToBigEndian(rawValue);  // 转为网络字节序（大端）
    QByteArray data_;
    data_.append(reinterpret_cast<const char*>(&rawValue), sizeof(float));

    // 添加数据长度和数据内容
    array.append(static_cast<char>(data_.size()));
    array.append(data_);
    return array;
}

QByteArray BMSProtocol::byte_0000(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    quint32 rawValue;
    int userInput = 0;
    memcpy(&rawValue, &userInput, sizeof(float));  // 安全转换
    rawValue = qToBigEndian(rawValue);  // 转为网络字节序（大端）
    QByteArray data_;
    data_.append(reinterpret_cast<const char*>(&rawValue), sizeof(float));

    // 添加数据长度和数据内容
    array.append(static_cast<char>(data_.size()));
    array.append(data_);

    return array;
}

QByteArray BMSProtocol::byte_0001(const QVariantMap &data)
{
    QByteArray array;

    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    quint32 rawValue;
    int userInput = 0;
    memcpy(&rawValue, &userInput, sizeof(float));  // 安全转换
    rawValue = qToBigEndian(rawValue);  // 转为网络字节序（大端）
    QByteArray data_;
    data_.append(reinterpret_cast<const char*>(&rawValue), sizeof(float));

    // 添加数据长度和数据内容
    array.append(static_cast<char>(data_.size()));
    array.append(data_);

    return array;
}

QByteArray BMSProtocol::byte_0002(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    quint32 rawValue;
    int userInput = 0;
    memcpy(&rawValue, &userInput, sizeof(float));  // 安全转换
    rawValue = qToBigEndian(rawValue);  // 转为网络字节序（大端）
    QByteArray data_;
    data_.append(reinterpret_cast<const char*>(&rawValue), sizeof(float));

    // 添加数据长度和数据内容
    array.append(static_cast<char>(data_.size()));
    array.append(data_);
    return array;
}

QByteArray BMSProtocol::byte_0003(const QVariantMap &data)
{
    QByteArray array;

    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    // 构造标志位字段
    quint16 flags = 0;
    flags |= (1 << 2);   // 强制开启放电：bit2 = 1
    flags &= ~(1 << 3);  // 强制关闭放电：bit3 = 0

    // 将 flags 转换为大端字节序（网络字节序）
    quint16 bigEndianFlags = qToBigEndian(flags);

    // 将两个字节写入数组
    array.append(static_cast<char>(0));
    // array.append(static_cast<char>((bigEndianFlags >> 8) & 0xFF));
    // array.append(static_cast<char>(bigEndianFlags & 0xFF));

    return array;
}

QByteArray BMSProtocol::byte_0004(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    // 构造标志位字段
    quint16 flags = 0;
    flags |= (1 << 3);   // bit3 = 1
    flags &= ~(1 << 2);  // bit2 = 0

    // 将 flags 转换为大端字节序（网络字节序）
    quint16 bigEndianFlags = qToBigEndian(flags);

    // 将两个字节写入数组
    array.append(static_cast<char>(0));
    // array.append(static_cast<char>((bigEndianFlags >> 8) & 0xFF));
    // array.append(static_cast<char>(bigEndianFlags & 0xFF));

    return array;
}

QByteArray BMSProtocol::byte_0006(const QVariantMap &data)
{
    QByteArray array;

    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    // 构造标志位字段
    quint16 flags = 0;
    flags |= (1 << 4);   // bit4 = 1: 强制开启充电
    flags &= ~(1 << 5);  // bit5 = 0: 清除强制关闭

    // 将 flags 转换为大端字节序（网络字节序）
    quint16 bigEndianFlags = qToBigEndian(flags);

    // 将两个字节写入数组
    array.append(static_cast<char>(0));
    // array.append(static_cast<char>((bigEndianFlags >> 8) & 0xFF));
    // array.append(static_cast<char>(bigEndianFlags & 0xFF));

    return array;
}
QByteArray BMSProtocol::byte_0007(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    // 构造标志位字段
    quint16 flags = 0;
    flags |= (1 << 5);   // bit5 = 1: 强制关闭充电
    flags &= ~(1 << 4);  // bit4 = 0: 清除强制开启

    // 将 flags 转换为大端字节序（网络字节序）
    quint16 bigEndianFlags = qToBigEndian(flags);

    // 将两个字节写入数组
    array.append(static_cast<char>(0));
    // array.append(static_cast<char>((bigEndianFlags >> 8) & 0xFF));
    // array.append(static_cast<char>(bigEndianFlags & 0xFF));

    return array;
}
QByteArray BMSProtocol::byte_0101(const QVariantMap &data)
{
    QByteArray array;
    quint16 regCount = 1;
    array.append(static_cast<char>((regCount >> 8) & 0xFF));
    array.append(static_cast<char>(regCount & 0xFF));

    quint32 rawValue;
    int userInput = 0;
    memcpy(&rawValue, &userInput, sizeof(float));  // 安全转换
    rawValue = qToBigEndian(rawValue);  // 转为网络字节序（大端）
    QByteArray data_;
    data_.append(reinterpret_cast<const char*>(&rawValue), sizeof(float));

    // 添加数据长度和数据内容
    array.append(static_cast<char>(data_.size()));
    array.append(data_);
    return array;
}


QVariantMap BMSProtocol::paseCellVs(quint16 cmd, const QByteArray &data)
{
    QVariantMap response;
    // 组合数据（大端序）
    quint16 raw = (static_cast<quint8>(data[5]) << 8) | static_cast<quint8>(data[6]);
    double value = raw * 0.0010;
    // value = std::round(value * 1000.0) / 1000.0;
    response["cellV"] = value;
    return response;
}

QVariantMap BMSProtocol::paseString(const QByteArray& buf, int dataLen)
{
    QVariantMap response;
    quint16 writeOrread = static_cast<quint8>(buf.at(1));
    if(writeOrread == 0x10)
    {
        return response;
    }
    quint16 funcCodeH = static_cast<quint8>(buf.at(2));
    quint16 funcCodeL = static_cast<quint8>(buf.at(3));
    quint16 funcCode = (static_cast<quint16>(funcCodeH) << 8) | funcCodeL;
    QString value;
    // 检查数据长度是否合法
    int dataLength = static_cast<quint8>(buf.at(4));
    if (buf.size() < 5 + dataLength)
    {
        response["error"] = "Data length exceeds buffer";
        return response;
    }


    for(int i = 5; i < buf.at(4) + 5; i++)
    {
        quint8 byte = static_cast<quint8>(buf.at(i));
        value.append(QChar(byte)); // 转为ASCII字符
    }
    if(funcCode == 0x230)//SN
    {
        response["sn"] = value;
        response["viewValue"] = "sn";
    }
    else if(funcCode == 0x236)//Manufacturer
    {
        response["manufacturer"] = value;
        response["viewValue"] = "manufacturer";
    }
    else if(funcCode == 0x23A)//ManufacturerMode
    {
        response["manufacturerMode"] = value;
        response["viewValue"] = "manufacturerMode";
    }
    else if(funcCode == 0x246)//CustomerName
    {
        response["customerName"] = value;
        response["viewValue"] = "customerName";
    }
    else if(funcCode == 0x24A)//CustomerMode
    {
        response["customerMode"] = value;
        response["viewValue"] = "customerMode";
    }
    else if(funcCode == 0x256)//MNFDate
    {
        response["mnfDate"] = value;
        response["viewValue"] = "mnfDate";
    }
    else if(funcCode == 0x408)//BT
    {
        response["bt"] = value;
        response["viewValue"] = "bt";
    }
    qDebug()<<response;
    return response;
}

QVariantMap BMSProtocol::paseUn16And1(const QByteArray &buf, int dataLen)
{
    QVariantMap response;
    quint16 writeOrread = static_cast<quint8>(buf.at(1));
    if(writeOrread == 0x10)
    {
        return response;
    }
    quint16 funcCodeH = static_cast<quint8>(buf.at(2));
    quint16 funcCodeL = static_cast<quint8>(buf.at(3));
    quint16 funcCode = (static_cast<quint16>(funcCodeH) << 8) | funcCodeL;
    quint16 raw_ = (static_cast<quint8>(buf[5]) << 8) | static_cast<quint8>(buf[6]);
    QString raw = QString::number(static_cast<int>(raw_));

    if (funcCode == 0x200) {
        response["cellNum"] = raw;
        response["viewValue"] = "cellNum";
    }
    else if (funcCode == 0x201) {
        response["cellType"] = raw;
        response["viewValue"] = "cellType";
    }
    else if (funcCode == 0x202) {
        response["afeNumber"] = raw;
        response["viewValue"] = "afeNumber";
    }
    else if (funcCode == 0x203) {
        response["customNumber"] = raw;
        response["viewValue"] = "customNumber";
    }
    else if (funcCode == 0x204) {
        response[""] = raw;  // ⚠️ 注意：此处键名为空，需确认是否需要有效键名
        response["viewValue"] = "";
    }
    else if (funcCode == 0x205) {
        response["functionConfig"] = raw;
        response["viewValue"] = "functionConfig";
    }
    else if (funcCode == 0x206) {
        response["SleepDelay"] = raw;
        response["viewValue"] = "SleepDelay";
    }
    else if (funcCode == 0x207) {
        response["ShutDownDelay"] = raw;
        response["viewValue"] = "ShutDownDelay";
    }
    else if (funcCode == 0x208) {
        response["eYa"] = raw;
        response["viewValue"] = "eYa";
    }
    else if (funcCode == 0x20A) {
        response["mYa"] = raw;
        response["viewValue"] = "mYa";
    }
    else if (funcCode == 0x20C) {
        response["manYshi"] = raw;
        response["viewValue"] = "manYshi";
    }
    else if (funcCode == 0x210) {
        response["OV"] = raw;
        response["viewValue"] = "OV";
    }
    else if (funcCode == 0x211) {
        response["OVR"] = raw;
        response["viewValue"] = "OVR";
    }
    else if (funcCode == 0x212) {
        response["ovt"] = raw;
        response["viewValue"] = "ovt";
    }
    else if (funcCode == 0x213) {
        response["VL0V"] = raw;
        response["viewValue"] = "VL0V";
    }
    else if (funcCode == 0x214) {
        response["VOB"] = raw;
        response["viewValue"] = "VOB";
    }
    else if (funcCode == 0x215) {
        response["BALD"] = raw;
        response["viewValue"] = "BALD";
    }
    else if (funcCode == 0x216) {
        response["BALT"] = raw;
        response["viewValue"] = "BALT";
    }
    else if (funcCode == 0x217) {
        response["UV"] = raw;
        response["viewValue"] = "UV";
    }
    else if (funcCode == 0x218) {
        response["UVR"] = raw;
        response["viewValue"] = "UVR";
    }
    else if (funcCode == 0x219) {
        response["UVT"] = raw;
        response["viewValue"] = "UVT";
    }
    else if (funcCode == 0x21A) {
        response["OCD1"] = raw;
        response["viewValue"] = "OCD1";
    }
    else if (funcCode == 0x21B) {
        response["OCD1T"] = raw;
        response["viewValue"] = "OCD1T";
    }
    else if (funcCode == 0x21C) {
        response["OCD2"] = raw;
        response["viewValue"] = "OCD2";
    }
    else if (funcCode == 0x21D) {
        response["OCD2T"] = raw;
        response["viewValue"] = "OCD2T";
    }
    else if (funcCode == 0x21E) {
        response["dbYa"] = raw;
        response["viewValue"] = "dbYa";
    }
    else if (funcCode == 0x21F) {
        response["SCT"] = raw;
        response["viewValue"] = "SCT";
    }
    else if (funcCode == 0x220) {
        response["OCC"] = raw;
        response["viewValue"] = "OCC";
    }
    else if (funcCode == 0x221) {
        response["OCCT"] = raw;
        response["viewValue"] = "OCCT";
    }
    else if (funcCode == 0x400) {
        response["sjCirCount"] = raw;
        response["viewValue"] = "sjCirCount";
    }
    else if (funcCode == 0x401) {
        response["Cyclecount"] = raw;
        response["viewValue"] = "Cyclecount";
    }
    else if(funcCode == 0x406)
    {
        response["zdjg"] = raw;
        response["viewValue"] = "zdjg";
    }
    else if(funcCode == 0x407)
    {
        response["zjjg"] = raw;
        response["viewValue"] = "zjjg";
    }
    // qDebug()<<response;
    return response;
}

QVariantMap BMSProtocol::paseInt16And1(const QByteArray &buf, int dataLen)
{
    QVariantMap response;
    quint16 writeOrread = static_cast<quint8>(buf.at(1));
    if(writeOrread == 0x10)
    {
        return response;
    }
    quint16 funcCodeH = static_cast<quint8>(buf.at(2));
    quint16 funcCodeL = static_cast<quint8>(buf.at(3));
    quint16 funcCode = (static_cast<quint16>(funcCodeH << 8) | funcCodeL);
    qint16 raw_ = (static_cast<quint8>(buf[5]) << 8) | static_cast<quint8>(buf[6]);
    QString raw = QString::number(static_cast<qint16>(raw_));
    if (funcCode == 0x222)
    {
        response["OTC"] = raw;
        response["viewValue"] = "OTC";
    }
    else if(funcCode == 0x223)
    {
        response["OTCR"] = raw;
        response["viewValue"] = "OTCR";
    }
    else if(funcCode == 0x224)
    {
        response["UTC"] = raw;
        response["viewValue"] = "UTC";
    }
    else if(funcCode == 0x225)
    {
        response["UTCR"] = raw;
        response["viewValue"] = "UTCR";
    }
    else if(funcCode == 0x226)
    {
        response["OTD"] = raw;
        response["viewValue"] = "OTD";
    }
    else if(funcCode == 0x227)
    {
        response["OTDR"] = raw;
        response["viewValue"] = "OTDR";
    }
    else if(funcCode == 0x228)
    {
        response["UTD"] = raw;
        response["viewValue"] = "UTD";
    }
    else if(funcCode == 0x229)
    {
        response["UTDR"] = raw;
        response["viewValue"] = "UTDR";
    }
    else if(funcCode == 0x22A)
    {
        response["MOTD"] = raw;
        response["viewValue"] = "MOTD";
    }
    else if(funcCode == 0x22B)
    {
        response["MOTDR"] = raw;
        response["viewValue"] = "MOTDR";
    }
    else if(funcCode == 0x209)
    {
        response["eLiu"] = raw;
        response["viewValue"] = "eLiu";
    }
    else if(funcCode == 0x20B)
    {
        response["mcLiu"] = raw;
        response["viewValue"] = "mcLiu";
    }
    else if(funcCode == 0x20D)
    {
        response["lingYuzhi"] = raw;
        response["viewValue"] = "lingYuzhi";
    }

    return response;
}

QVariantMap BMSProtocol::paseUint32And2(const QByteArray &buf, int dataLen)
{

    QVariantMap response;
    quint16 writeOrread = static_cast<quint8>(buf.at(1));
    if(writeOrread == 0x10)
    {
        return response;
    }
    quint16 funcCodeH = static_cast<quint8>(buf.at(2));
    quint16 funcCodeL = static_cast<quint8>(buf.at(3));
    quint16 funcCode = (static_cast<quint16>(funcCodeH) << 8) | funcCodeL;
    // 将4字节数据转换为uint32（大端序）
    quint32 a = (static_cast<quint32>(static_cast<quint8>(buf[5])) << 24) |
                (static_cast<quint32>(static_cast<quint8>(buf[6])) << 16) |
                (static_cast<quint32>(static_cast<quint8>(buf[7])) << 8) |
                static_cast<quint32>(static_cast<quint8>(buf[8]));

    // 提取时间字段
    int year = ((a & 0xFC000000) >> 26) + 2022;  // 年 = 高6位 + 2000
    int month = (a & 0x03C00000) >> 22;          // 月 = 4位
    int day = (a & 0x003E0000) >> 17;            // 日 = 5位
    int hour = (a & 0x0001F000) >> 12;           // 时 = 5位
    int minute = (a & 0x00000FC0) >> 6;          // 分 = 6位
    int second = (a & 0x0000003F) >> 0;          // 秒 = 6位

    // 格式化为字符串
    QString timeStr = QString("%1-%2-%3 %4:%5:%6")
                          .arg(year, 4)  // 4位年份
                          .arg(month, 2, 10, QLatin1Char('0'))  // 2位月，补零
                          .arg(day, 2, 10, QLatin1Char('0'))     // 2位日，补零
                          .arg(hour, 2, 10, QLatin1Char('0'))    // 2位时，补零
                          .arg(minute, 2, 10, QLatin1Char('0'))  // 2位分，补零
                          .arg(second, 2, 10, QLatin1Char('0')); // 2位秒，补零
    if (funcCode >= 0x418 && funcCode <= 0x446)
    {
        response["protectTime"] = timeStr;
        response["viewValue"] = "protectTime";
    }
    else if(funcCode >= 0x448 && funcCode <= 0x476)
    {
        QString hexString = QString("0x%1").arg(a, 8, 16, QChar('0')).toUpper();
        response["protectEvent"] = hexString;
        response["viewValue"] = "protectEvent";
    }
    else if(funcCode == 0x402)
    {
        float fcc_Ah = a / 1000.0f;
        response["FCC"] = fcc_Ah;
        response["viewValue"] = "FCC";
    }
    else if(funcCode == 0x404)
    {
        float dc_Ah = a / 1000.0f;
        response["DC"] = dc_Ah;
        response["viewValue"] = "DC";
    }
    return response;
}

QVariantMap BMSProtocol::paseFloatAnd2(const QByteArray &buf, int dataLen)
{
    QVariantMap response;
    quint16 writeOrread = static_cast<quint8>(buf.at(1));
    if(writeOrread == 0x10)
    {
        return response;
    }
    quint16 funcCodeH = static_cast<quint8>(buf.at(2));
    quint16 funcCodeL = static_cast<quint8>(buf.at(3));
    quint16 funcCode = (static_cast<quint16>(funcCodeH) << 8) | funcCodeL;

    quint8 b0 = static_cast<quint8>(buf.at(5));  // 高字节
    quint8 b1 = static_cast<quint8>(buf.at(6));
    quint8 b2 = static_cast<quint8>(buf.at(7));
    quint8 b3 = static_cast<quint8>(buf.at(8));  // 低字节
    // 组合为 32 位整数（大端序）
    quint32 rawValue = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;

    // 转换为 float
    float floatValue;
    memcpy(&floatValue, &rawValue, sizeof(float));  // 安全转换

    // 保留3位小数
    QString formattedValue = QString::number(static_cast<double>(floatValue), 'f', 3);
    if (funcCode == 0x20E)
    {
        response["SampleRValue"] = formattedValue;
        response["viewValue"] = "SampleRValue";
    }
    return response;
}

QVariantMap BMSProtocol::parse(const QByteArray &buf, int &size, int &result)
{
    QVariantMap mp = {};
    return mp;
}

QVariantMap BMSProtocol::deal_14(const QByteArray &data, int dataLen)
{
    QVariantMap response;
    // 解析 data 并处理...
    quint8 SOH = static_cast<quint8>(data[5]);
    quint8 SOC = static_cast<quint8>(data[6]);
    // QString msg1 = QString("%1%").arg(SOH );
    // QString msg2 = QString("%1%").arg(SOC );
    response["SOH"] = SOH;
    response["SOC"] = SOC;
    return response;
}

QVariantMap BMSProtocol::deal_04(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    // 数据完整性校验
    if (dataLen != 4 || v.size() < 9)// v至少需要包含：地址(1)+功能码(1)+地址（2）+长度(1)+数据(4)
    {
        response["error"] = "Invalid data length";
        return response;
    }
    // 提取数据部分的4字节（大端序）
    quint32 rawValue = (static_cast<quint8>(v[5]) << 24) |  // 00
                       (static_cast<quint8>(v[6]) << 16) |  // 01
                       (static_cast<quint8>(v[7]) << 8)  |  // 37
                       static_cast<quint8>(v[8]);          // 20

    // 计算电呀值（假设单位为mV，需根据设备协议调整比例）
    double current_V = rawValue / 1000.0;

    response["electYa"] = QString::number(current_V, 'f', 3);
    return response;
}

QVariantMap BMSProtocol::deal_06(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    // 数据完整性校验
    if (dataLen != 4 || v.size() < 9)// v至少需要包含：地址(1)+功能码(1)+地址（2）+长度(1)+数据(4)
    {
        response["error"] = "Invalid data length";
        return response;
    }
    // // 提取数据部分的4字节（大端序）
    // quint32 rawValue = (static_cast<quint8>(v[5]) << 24) |  // 00
    //                    (static_cast<quint8>(v[6]) << 16) |  // 01
    //                    (static_cast<quint8>(v[7]) << 8)  |  // 37
    //                    static_cast<quint8>(v[8]);          // 20

    // // 计算电流值（假设单位为mA，需根据设备协议调整比例）
    // double current_A = rawValue / 1000.0;  // 转换为安培
    // 正确提取有符号32位整数（大端序）
    qint32 rawValue;
    const char* dataPtr = v.constData() + 5;  // 数据起始位置
    rawValue = qFromBigEndian<qint32>(dataPtr);  // Qt内置大端序转换

    // 处理单位转换（mA -> A），保留符号
    double current_A = rawValue / 1000.0;
    response["electLiu"] = QString::number(current_A, 'f', 3);
    return response;
}

QVariantMap BMSProtocol::deal_08(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 4 || v.size() < 9)
    {
        response["error"] = "Invalid data length";
        return response;
    }
    quint32 rawValue = (static_cast<quint8>(v[5]) << 24) |  // 00
                       (static_cast<quint8>(v[6]) << 16) |  // 01
                       (static_cast<quint8>(v[7]) << 8)  |  // 37
                       static_cast<quint8>(v[8]);          // 20
    response["capacity"] = rawValue;
    return response;
}

QVariantMap BMSProtocol::deal_0A(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    quint32 balStatus = (static_cast<quint8>(v[5]) << 24) |  // 00
                        (static_cast<quint8>(v[6]) << 16) |  // 01
                        (static_cast<quint8>(v[7]) << 8)  |  // 37
                        static_cast<quint8>(v[8]);          // 20
    response["balStatus"] = balStatus;
    return response;
}

QVariantMap BMSProtocol::deal_0C(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    int fangStatus = static_cast<quint8>(v[6]) & 1;
    int chongStatus = static_cast<quint8>(v[6]) & 2;
    int junhengStatus = static_cast<quint8>(v[6]) & 0x80;
    int b11 = static_cast<quint8>(v[7]) & 8;
    int b10 = static_cast<quint8>(v[7]) & 4;
    int b9 = static_cast<quint8>(v[7]) & 2;
    int b8 = static_cast<quint8>(v[7]) & 1;
    int b7 = static_cast<quint8>(v[8]) & 0x80;
    int b6 = static_cast<quint8>(v[8]) & 0x40;
    int b5 = static_cast<quint8>(v[8]) & 0x20;
    int b4 = static_cast<quint8>(v[8]) & 0x10;
    int b3 = static_cast<quint8>(v[8]) & 8;
    int b2 = static_cast<quint8>(v[8]) & 4;
    int b1 = static_cast<quint8>(v[8]) & 2;
    int b0 = static_cast<quint8>(v[8]) & 1;


    response["fMos"] = fangStatus;
    response["cMos"] = chongStatus;
    response["junhengStatus"] = junhengStatus;

    QVector<QString> errMsgArray;
    QString res = "normal";
    int alarmCount = 0;
    if(b11)
    {
        res = tr("放电高温标志");
        errMsgArray.push_back(res);
        alarmCount++;

    }
    if(b10)
    {
        res = tr("放电低温标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b9)
    {
        res = tr("充电高温标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b8)
    {
        res = tr("充电低温标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b7)
    {
        res = tr("低压禁充标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b6)
    {
        res = tr("断线标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b5)
    {
        res = tr("短路标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b4)
    {
        res = tr("充电过流标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b3)
    {
        res = tr("放电过流2标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b2)
    {
        res = tr("放电过流1标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b1)
    {
        res = tr("欠压标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    if(b0)
    {
        res = tr("过压标志");
        errMsgArray.push_back(res);
alarmCount++;
    }
    response["afeList"] = errMsgArray;
    response["alarmCount"] = alarmCount;
    return response;
}



QVariantMap BMSProtocol::deal_19(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    quint8 afeNum = static_cast<quint8>(v[5]);
    quint8 cusNum = static_cast<quint8>(v[6]);
    response["afeNum"] = afeNum;
    response["cusNum"] = cusNum;
    return response;
}

QVariantMap BMSProtocol::deal_1A(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    // 组合数据（大端序）
    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double value = raw ;
    response["cycles_number"] = value;
    return response;
}

QVariantMap BMSProtocol::deal_1B(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    // 组合数据（大端序）
    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double value = raw  ;
    response["full_charge_capacity"] = value ;
    return response;
}
// 寄存器地址0x0000 - MOS温度1 (Uint16, 单位: 开尔文)
QVariantMap BMSProtocol::deal_00(const QByteArray &v, int dataLen)
{
    QVariantMap response;

    if (dataLen != 2 || v.size() < 5)
    {
        response["error"] = "数据长度错误";
        return response;
    }
    quint16 temp = (static_cast<quint8>(v[5]) << 8 | static_cast<quint8>(v[6]));
    response["mosTemp"] = QString::number(static_cast<double> (temp) * 0.1 - 273.15, 'f', 3);
    return response;
}

// 寄存器地址0x0001 - 电池温度1 (Uint16, 单位: 开尔文)
QVariantMap BMSProtocol::deal_01(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 5) {
        response["error"] = "Invalid data length";
        return response;
    }
    quint16 temp = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    response["cell_temp1"] = QString::number(static_cast<double> (temp) * 0.1 - 273.15, 'f', 3);
    return response;
}
QVariantMap BMSProtocol::deal_02(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 5) {
        response["error"] = "Invalid data length";
        return response;
    }
    quint16 temp = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    response["cell_temp2"] = QString::number(static_cast<double> (temp) * 0.1 - 273.15, 'f', 3);
    return response;
}
QVariantMap BMSProtocol::deal_03(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 5) {
        response["error"] = "Invalid data length";
        return response;
    }
    quint16 temp = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    if(temp == 0)
    {
        response["cell_temp3"] = "--";
    }
    else
    {
        response["cell_temp3"] = QString::number(static_cast<double> (temp) * 0.1 - 273.15, 'f', 3);
    }
    response["cell_temp3"] = "-- --";
    return response;
}

QVariantMap BMSProtocol::deal_0E(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 5) {
        response["error"] = "Invalid data length";
        return response;
    }
    quint16 status = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);

    // 按位解析报警状态
    QVariantMap alarm;
    QVector<QString> errMsgArray;
    QString res = "normal";
    int alarmCount = 0;
    if(status & 0x0001)
    {
        res = tr("超高压报警");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(status & 0x0002)
    {
        res = tr("超低压报警");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(status & 0x0004)
    {
        res = tr("防拆卸报警");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(status & 0x0008)
    {
        res = tr("电压采集断线报警");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(status & 0x0010)
    {
        res = tr("温度采集断线报警");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(status & 0x0020)
    {
        res = tr("AFE通讯失效报警");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(status & 0x0040)
    {
        res = tr("电池组压差大报警");
        errMsgArray.push_back(res);
        alarmCount++;
    }

    response["alarmCount"] = alarmCount;
    response["alarm_msg_array"] = errMsgArray;
    return response;
}

// 寄存器地址0x000F - 电池状态 (Uint16, 按位解析)
QVariantMap BMSProtocol::deal_0F(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 5)
    {
        response["error"] = "Invalid data length";
        return response;
    }
    quint16 status = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    int b15 = static_cast<quint8>(v[5]) & 0x80;
    int b14 = static_cast<quint8>(v[5]) & 0x40;
    int b13 = static_cast<quint8>(v[5]) & 0x20;
    int b12 = static_cast<quint8>(v[5]) & 0x10;
    int b11 = static_cast<quint8>(v[5]) & 8;
    int b10 = static_cast<quint8>(v[5]) & 4;
    int b8 = static_cast<quint8>(v[5]) & 1;

    int b5 = static_cast<quint8>(v[6]) & 0x20;
    int b4 = static_cast<quint8>(v[6]) & 0x10;
    int b3 = static_cast<quint8>(v[6]) & 8;
    int b2 = static_cast<quint8>(v[6]) & 4;
    int b1 = static_cast<quint8>(v[6]) & 2;
    int b0 = static_cast<quint8>(v[6]) & 1;
    QVector<QString> errMsgArray;
    QString res = "normal";
    int alarmCount = 0;
    if(b15)
    {
        res = tr("正版固件标志");
        errMsgArray.push_back(res);
        alarmCount++;

    }
    if(b14)
    {
        res = tr("允许放电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(b13)
    {
        res = tr("AFE配置失败标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(b12)
    {
        res = tr("充电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(b11)
    {
        res = tr("放电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(b10)
    {
        res = tr("允许容量更新标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }

    if(b8)
    {
        res = tr("满充电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(b5)
    {
        res = tr("强制关闭充电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    response["fCloseC"] = b5;
    if(b4)
    {
        res = tr("强制开启充电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    response["fOpenC"] = b4;
    if(b3)
    {
        res = tr("强制关闭放电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    response["fCloseF"] = b3;
    if(b2)
    {
        res = tr("强制开启放电标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    response["fOpenF"] = b2;
    if(!b1)
    {
        res = tr("电流校准标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    if(!b0)
    {
        res = tr("零电流未校准标志");
        errMsgArray.push_back(res);
        alarmCount++;
    }
    response["pack_status"] = errMsgArray;
    response["alarmCount"] = alarmCount;
    return response;
}


QVariantMap BMSProtocol::deal_206(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    // 组合数据（大端序）
    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double sleepDelay = raw ;
    response["sleepDelay"] = sleepDelay;
    return response;
}

// 0x0010 - 二次电压（单位：10mV）
QVariantMap BMSProtocol::deal_10(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    // 校验：1个寄存器返回2字节数据（v[4]=02 表示后续数据长度）
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    // 组合数据（大端序）
    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double voltage = raw * 10.0;  // 转换为mV
    response["secondary_voltage"] = QString::number(voltage / 1000, 'f', 2) + " V";
    return response;
}

QVariantMap BMSProtocol::deal_11(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    // 组合数据（大端序）
    qint16 raw = (static_cast<qint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double voltage = raw * 10.0;  // 转换为mA
    response["secondary_current"] = QString::number(voltage / 1000, 'f', 2) + " A";
    return response;
}

QVariantMap BMSProtocol::deal_12(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    // 组合数据（大端序）
    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double temperature = raw;
    response["secondary_temperature"] = temperature;
    return response;
}

QVariantMap BMSProtocol::deal_13(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7)
    {
        response["error"] = "数据长度错误";
        return response;
    }
    // 组合数据（大端序）
    quint8 mainVer = static_cast<quint8>(v[5]);
    quint8 subVer = static_cast<quint8>(v[6]);
    response["mainVer"] = mainVer;
    response["subVer"] = subVer;
    return response;
}

// 0x0011 - 二次电流（单位：10mA，有符号）


// 0x0015 - RTC年份和月份（年份=值+2022）
QVariantMap BMSProtocol::deal_15(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    quint16 year = static_cast<quint8>(v[5]);  // 高字节：年份偏移
    quint8 month = static_cast<quint8>(v[6]);        // 低字节：月份
    response["rtc_year"] = QString::number(year);
    response["rtc_month"] = QString::number(month);
    return response;
}

QVariantMap BMSProtocol::deal_16(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }

    quint16 day = static_cast<quint8>(v[5]);// 高字节：天
    quint16 hour = static_cast<quint8>(v[6]); // 低字节：小时
    response["rtc_day"] = QString::number(day);
    response["rtc_hour"] = QString::number(hour);
    return response;
}

QVariantMap BMSProtocol::deal_17(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }
    quint16 minute = static_cast<quint8>(v[5]);  // 高字节：minute
    quint8 second = static_cast<quint8>(v[6]);        // 低字节：second
    response["rtc_minute"] = QString::number(minute);
    response["rtc_second"] = QString::number(second);
    return response;
}

QVariantMap BMSProtocol::deal_18(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7)
    {
        response["error"] = "数据长度错误";
        return response;
    }
    // 组合数据（大端序）
    quint8 cellNum = static_cast<quint8>(v[5]);
    quint8 celllType = static_cast<quint8>(v[6]);
    response["celllType"] = celllType;
    response["cellNum"] = cellNum;
    return response;
}

// 0x001B - 满充容量（单位：10mAh，32位组合）


QVariantMap BMSProtocol::deal_1C(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }


    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double sjrl = raw;
    response["dc"] = sjrl;
    return response;
}

QVariantMap BMSProtocol::deal_1D(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }


    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double maxNoElect = raw;
    response["maxNoElect"] = maxNoElect;
    return response;
}

QVariantMap BMSProtocol::deal_1E(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    if (dataLen != 2 || v.size() < 7) {
        response["error"] = "数据长度错误";
        return response;
    }


    quint16 raw = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    double majNoElect = raw;
    response["majNoElect"] = majNoElect;
    return response;
}

QVariantMap BMSProtocol::deal_1F(const QByteArray &v, int dataLen)
{
    QVariantMap response;
    quint16 status = (static_cast<quint8>(v[5]) << 8) | static_cast<quint8>(v[6]);
    QVariantMap alarm;
    //1开， 0关
    alarm["b0"] = (status & 0x0001);
    alarm["b1"] = (status & 0x0002);
    alarm["b2"] = (status & 0x0004);
    alarm["b3"] = (status & 0x0008);
    alarm["b4"] = (status & 0x0010);
    alarm["b5"] = (status & 0x0020);
    response["functionConfig"] = alarm["b0"];
    return response;
}

// CRC16计算实现
quint16 BMSProtocol::calculateCRC(const QByteArray &data)
{
    quint16 crc = 0;
    for (char c : data)
    {
        crc = (crc << 8) ^ crc16tab[((crc >> 8) ^ (static_cast<quint8>(c))) & 0xFF];
    }
    return crc;
}

QVariant BMSProtocol::parseRegisterData(quint16 address, const QByteArray &data) const
{
    // 根据寄存器地址解析数据类型
    if(address >= 0x0000 && address <= 0x003F)
    { // 电压值
        quint16 value = static_cast<quint8>(data[0]) << 8 |
                        static_cast<quint8>(data[1]);
        return value; // 单位mV
    }
    else if(address == 0x0014) { // SOC/SOH
        QVariantMap socSoh;
        socSoh.insert("SOH", static_cast<quint8>(data[0]));
        socSoh.insert("SOC", static_cast<quint8>(data[1]));
        return socSoh;
    }
    // 添加其他数据类型解析...

    return QVariant();
}
