import 'dart:ffi';
import 'dart:io';


// 加载 so 库
final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libsignAPI.so")
    : throw UnsupportedError("Only Android supported");

// 函数签名绑定
typedef spx_sign_c = Int32 Function(
  Pointer<Uint8> sm,
  Pointer<Int32> sm_len,
  Pointer<Uint8> input_m,
  Int32 mlen,
  Pointer<Uint8> R,
  Pointer<Uint8> input_sk,
  Pointer<Uint8> input_fors_sk,
  Pointer<Uint8> input_pk,
  Int32 t,
  Pointer<Uint8> last_root,
  Pointer<Int32> level,
);

typedef SpxSignDart = int Function(
  Pointer<Uint8> sm,
  Pointer<Int32> sm_len,
  Pointer<Uint8> input_m,
  int mlen,
  Pointer<Uint8> R,
  Pointer<Uint8> input_sk,
  Pointer<Uint8> input_fors_sk,
  Pointer<Uint8> input_pk,
  int t,
  Pointer<Uint8> last_root,
  Pointer<Int32> level,
);

final SpxSignDart spxSign = nativeLib
    .lookup<NativeFunction<spx_sign_c>>('spx_sign')
    .asFunction();

