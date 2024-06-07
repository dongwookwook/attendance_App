library nfc_package;

import 'package:nfc_manager/nfc_manager.dart';
import 'dart:io';
import 'dart:async';

class NfcPackage {
  final List<String> validUids = [
    "0xFF",
    "0xAA",
    "0x16",
    "0x14",
  ]; // UID 목록

  /// NFC 태그를 읽고 UID가 일치하는지 확인하는 메서드
  Future<bool> startNfcSession() async {
    try {
      if (Platform.isIOS) {
        return await _startIosNfcSession();
      } else if (Platform.isAndroid) {
        return await _startAndroidNfcSession();
      } else {
        throw UnsupportedError('NFC is not supported on this platform');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _startIosNfcSession() async {
    Completer<bool> completer = Completer();

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      alertMessage: "기기를 필터 가까이에 가져다주세요.",
      onDiscovered: (NfcTag tag) async {
        try {
          bool isValid = _handleTag(tag);
          completer.complete(isValid);
        } catch (e) {
          completer.completeError("NFC 데이터를 읽을 수 없습니다.");
        } finally {
          await NfcManager.instance.stopSession(alertMessage: "완료되었습니다.");
        }
      },
    );

    return completer.future;
  }

  Future<bool> _startAndroidNfcSession() async {
    Completer<bool> completer = Completer();

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          bool isValid = _handleTag(tag);
          await NfcManager.instance.stopSession();
          completer.complete(isValid);
        } catch (e) {
          await NfcManager.instance.stopSession();
          completer.completeError("NFC 데이터를 읽을 수 없습니다.");
        }
      },
    ).catchError((e) => completer.completeError("NFC 세션을 시작할 수 없습니다: $e"));

    return completer.future;
  }

  bool _handleTag(NfcTag tag) {
    try {
      List<int> tempIntList;

      if (Platform.isIOS) {
        tempIntList = List<int>.from(tag.data["mifare"]?["identifier"] ?? []);
      } else {
        tempIntList =
            List<int>.from(Ndef.from(tag)?.additionalData["identifier"] ?? []);
      }

      String uid =
          tempIntList.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      return validUids.contains(uid);
    } catch (e) {
      throw "NFC 데이터를 읽을 수 없습니다.";
    }
  }
}
