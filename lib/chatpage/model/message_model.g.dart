// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 0;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      senderHex: fields[0] as String,
      receiverHex: fields[1] as String,
      cid: fields[2] as String,
      timestamp: fields[3] as int,
      deleted: fields[4] as bool,
      plaintext: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.senderHex)
      ..writeByte(1)
      ..write(obj.receiverHex)
      ..writeByte(2)
      ..write(obj.cid)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.deleted)
      ..writeByte(5)
      ..write(obj.plaintext);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
