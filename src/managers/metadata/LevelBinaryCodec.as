package managers.metadata {
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    /**
     * 关卡数据二进制编解码器（优化版）
     * - 预定义字符串来自 TypeConstants（键名、枚举值、难度后缀及组合键）
     * - 动态字符串表仅存储未预定义的字符串（如颜色值、自定义名称等）
     * - 类型标记：
     *   0x00 null
     *   0x01 boolean
     *   0x02 有符号整数（变长）
     *   0x03 浮点数（4字节）
     *   0x04 动态字符串ID（指向动态表）
     *   0x05 预定义字符串ID（指向内置表）
     *   0x10 数组
     *   0x20 对象
     */
    public class LevelBinaryCodec {

        //--------------------------------------------------------------------------
        // 预定义字符串表（内置，从 TypeConstants 生成）
        //--------------------------------------------------------------------------
        private static var PREDEFINED_STRINGS:Array;
        private static var PREDEFINED_MAP:Object;

        // 静态初始化：构建预定义表
        {
            buildPredefinedStrings();
        }

        private static function buildPredefinedStrings():void {
            var set:Object = {};

            // 添加 LEVEL_KEYS 的键名
            for (var key:String in TypeConstants.LEVEL_KEYS) {
                set[key] = true;
            }

            // 添加所有枚举值
            addArrayToSet(TypeConstants.NODE_TYPES, set);
            addArrayToSet(TypeConstants.SPECIAL_EVENT_TYPES, set);
            addArrayToSet(TypeConstants.VICTORY_CONDITION_TYPES, set);
            addArrayToSet(TypeConstants.AI_TYPES, set);
            addArrayToSet(TypeConstants.BGM_NAMES, set);
            addArrayToSet(TypeConstants.ATTACK_TYPES, set);
            addArrayToSet(TypeConstants.DIFFICULTY_SUFFIXES, set);

            // 添加组合键：baseKey/suffix
            var baseKeys:Array = [];
            for (key in TypeConstants.LEVEL_KEYS) {
                baseKeys.push(key);
            }
            for each (var base:String in baseKeys) {
                for each (var suffix:String in TypeConstants.DIFFICULTY_SUFFIXES) {
                    set[base + "/" + suffix] = true;
                }
            }

            // 转换为数组和映射
            PREDEFINED_STRINGS = [];
            PREDEFINED_MAP = {};
            for (var str:String in set) {
                PREDEFINED_MAP[str] = PREDEFINED_STRINGS.length;
                PREDEFINED_STRINGS.push(str);
            }
        }

        private static function addArrayToSet(arr:Array, set:Object):void {
            for each (var s:String in arr) {
                set[s] = true;
            }
        }

        //--------------------------------------------------------------------------
        // 公共接口
        //--------------------------------------------------------------------------
        public static function compress(data:Object):ByteArray {
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            // 收集动态字符串（不在预定义表中）
            var dynamicStrings:Array = [];
            var dynamicMap:Object = {};
            collectDynamicStrings(data, dynamicStrings, dynamicMap);

            // 写入动态字符串表
            writeVarInt(dynamicStrings.length, bytes);
            for each (var dynStr:String in dynamicStrings) {
                writeUTF8Var(dynStr, bytes);
            }

            // 写入数据
            writeValue(data, bytes, dynamicMap);
            bytes.position = 0;
            return bytes;
        }

        public static function decompress(bytes:ByteArray):Object {
            bytes.endian = Endian.LITTLE_ENDIAN;
            // 读取动态字符串表
            var dynCount:int = readVarInt(bytes);
            var dynamicStrings:Array = [];
            for (var i:int = 0; i < dynCount; i++) {
                dynamicStrings.push(readUTF8Var(bytes));
            }
            // 读取数据
            return readValue(bytes, dynamicStrings);
        }

        //--------------------------------------------------------------------------
        // 动态字符串收集
        //--------------------------------------------------------------------------
        private static function collectDynamicStrings(obj:*, dynamicStrings:Array, dynamicMap:Object):void {
            if (obj == null) return;
            var type:String = typeof obj;
            if (type == "string") {
                var str:String = obj as String;
                if (!PREDEFINED_MAP.hasOwnProperty(str) && !dynamicMap.hasOwnProperty(str)) {
                    dynamicMap[str] = dynamicStrings.length;
                    dynamicStrings.push(str);
                }
            } else if (type == "object") {
                if (obj is Array) {
                    var arr:Array = obj as Array;
                    for each (var item:* in arr) {
                        collectDynamicStrings(item, dynamicStrings, dynamicMap);
                    }
                } else {
                    for (var key:String in obj) {
                        // 处理键名
                        if (!PREDEFINED_MAP.hasOwnProperty(key) && !dynamicMap.hasOwnProperty(key)) {
                            dynamicMap[key] = dynamicStrings.length;
                            dynamicStrings.push(key);
                        }
                        // 处理值
                        collectDynamicStrings(obj[key], dynamicStrings, dynamicMap);
                    }
                }
            }
        }

        //--------------------------------------------------------------------------
        // 值序列化（递归）
        //--------------------------------------------------------------------------
        private static function writeValue(value:*, output:ByteArray, dynamicMap:Object):void {
            if (value == null) {
                output.writeByte(0x00);
                return;
            }
            var type:String = typeof value;
            if (type == "boolean") {
                output.writeByte(0x01);
                output.writeByte(value ? 1 : 0);
            } else if (type == "number") {
                if (value == int(value) && !isNaN(value)) {
                    output.writeByte(0x02);
                    writeSignedVarInt(value, output);
                } else {
                    output.writeByte(0x03);
                    output.writeFloat(value);
                }
            } else if (type == "string") {
                var str:String = value as String;
                if (PREDEFINED_MAP.hasOwnProperty(str)) {
                    output.writeByte(0x05);
                    writeVarInt(PREDEFINED_MAP[str], output);
                } else {
                    output.writeByte(0x04);
                    writeVarInt(dynamicMap[str], output);
                }
            } else if (type == "object") {
                if (value is Array) {
                    output.writeByte(0x10);
                    var arr:Array = value as Array;
                    writeVarInt(arr.length, output);
                    for each (var elem:* in arr) {
                        writeValue(elem, output, dynamicMap);
                    }
                } else {
                    output.writeByte(0x20);
                    var count:int = 0;
                    for (var key:String in value) count++;
                    writeVarInt(count, output);
                    for (key in value) {
                        // 写入键（可能预定义或动态）
                        if (PREDEFINED_MAP.hasOwnProperty(key)) {
                            output.writeByte(0x05);
                            writeVarInt(PREDEFINED_MAP[key], output);
                        } else {
                            output.writeByte(0x04);
                            writeVarInt(dynamicMap[key], output);
                        }
                        // 写入值
                        writeValue(value[key], output, dynamicMap);
                    }
                }
            } else {
                output.writeByte(0x00);
            }
        }

        //--------------------------------------------------------------------------
        // 值反序列化（递归）
        //--------------------------------------------------------------------------
        private static function readValue(input:ByteArray, dynamicStrings:Array):* {
            var type:int = input.readUnsignedByte();
            switch (type) {
                case 0x00: return null;
                case 0x01: return input.readByte() != 0;
                case 0x02: return readSignedVarInt(input);
                case 0x03: return input.readFloat();
                case 0x04: {
                    var dynId:int = readVarInt(input);
                    return dynamicStrings[dynId];
                }
                case 0x05: {
                    var predefId:int = readVarInt(input);
                    return PREDEFINED_STRINGS[predefId];
                }
                case 0x10: {
                    var len:int = readVarInt(input);
                    var arr:Array = [];
                    for (var i:int = 0; i < len; i++) {
                        arr.push(readValue(input, dynamicStrings));
                    }
                    return arr;
                }
                case 0x20: {
                    var count:int = readVarInt(input);
                    var obj:Object = {};
                    for (var j:int = 0; j < count; j++) {
                        // 读取键类型
                        var keyType:int = input.readUnsignedByte();
                        var key:String;
                        if (keyType == 0x04) {
                            key = dynamicStrings[readVarInt(input)];
                        } else if (keyType == 0x05) {
                            key = PREDEFINED_STRINGS[readVarInt(input)];
                        } else {
                            throw new Error("无效的键类型标记: " + keyType);
                        }
                        // 读取值
                        obj[key] = readValue(input, dynamicStrings);
                    }
                    return obj;
                }
                default:
                    throw new Error("未知类型标记: " + type);
            }
        }

        //--------------------------------------------------------------------------
        // 变长整数辅助函数（LEB128）
        //--------------------------------------------------------------------------
        private static function writeVarInt(value:int, output:ByteArray):void {
            var v:uint = value;
            do {
                var b:uint = v & 0x7F;
                v >>= 7;
                if (v != 0) b |= 0x80;
                output.writeByte(b);
            } while (v != 0);
        }

        private static function readVarInt(input:ByteArray):int {
            var result:uint = 0;
            var shift:uint = 0;
            var b:uint;
            do {
                b = input.readUnsignedByte();
                result |= (b & 0x7F) << shift;
                shift += 7;
                if (shift > 28) throw new Error("VarInt 过大");
            } while (b & 0x80);
            return result;
        }

        private static function writeSignedVarInt(value:int, output:ByteArray):void {
            var zigzag:uint = (value << 1) ^ (value >> 31);
            writeVarInt(zigzag, output);
        }

        private static function readSignedVarInt(input:ByteArray):int {
            var zigzag:uint = readVarInt(input);
            return (zigzag >> 1) ^ -(int(zigzag & 1));
        }

        private static function writeUTF8Var(str:String, output:ByteArray):void {
            var temp:ByteArray = new ByteArray();
            temp.writeUTFBytes(str);
            var len:int = temp.length;
            writeVarInt(len, output);
            output.writeBytes(temp, 0, len);
        }

        private static function readUTF8Var(input:ByteArray):String {
            var len:int = readVarInt(input);
            return input.readUTFBytes(len);
        }
    }
}