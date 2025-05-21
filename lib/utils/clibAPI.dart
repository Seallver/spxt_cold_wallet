import 'dart:ffi';
import 'package:ffi/ffi.dart';

base class SSS_ctx extends Opaque {} // 不关心结构体内容，只关心指针

typedef SSSNewC = Pointer<SSS_ctx> Function(Pointer<Utf8>, Int32, Int32, Int32);
typedef SSSNewDart = Pointer<SSS_ctx> Function(Pointer<Utf8>, int, int, int);

typedef SSSFreeC = Void Function(Pointer<SSS_ctx>);
typedef SSSFreeDart = void Function(Pointer<SSS_ctx>);

typedef GenShardsC = Int32 Function(Pointer<SSS_ctx>, Pointer<Utf8>);
typedef GenShardsDart = int Function(Pointer<SSS_ctx>, Pointer<Utf8>);

typedef access_share_native =
    Int32 Function(Pointer<SSS_ctx>, Int32, Pointer<Utf8>, Pointer<Utf8>);

typedef aggregate_share_native =
    Int32 Function(Pointer<SSS_ctx>, Int32, Pointer<Utf8>, Pointer<Utf8>);

typedef AggregateShare =
    int Function(Pointer<SSS_ctx>, int, Pointer<Utf8>, Pointer<Utf8>);

typedef AccessShare =
    int Function(Pointer<SSS_ctx>, int, Pointer<Utf8>, Pointer<Utf8>);

final dylib = DynamicLibrary.open('libDKGapi.so');

final accessShare = dylib.lookupFunction<access_share_native, AccessShare>(
  'access_j_shares',
);

final SSSNewDart sssNew =
    dylib.lookup<NativeFunction<SSSNewC>>('SSS_new').asFunction();

final SSSFreeDart sssFree =
    dylib.lookup<NativeFunction<SSSFreeC>>('SSS_free').asFunction();

final AggregateShare aggregateShare = dylib
    .lookupFunction<aggregate_share_native, AggregateShare>(
      'aggregate_j_shares',
    );

final GenShardsDart genShards =
    dylib.lookup<NativeFunction<GenShardsC>>('gen_shards').asFunction();

typedef SSSGetParamsC =
    Int32 Function(
      Pointer<SSS_ctx>,
      Pointer<Utf8>, // sk_buf
      Pointer<Utf8>, // share_buf
    );

typedef SSSGetParamsDart =
    int Function(Pointer<SSS_ctx>, Pointer<Utf8>, Pointer<Utf8>);

final SSSGetParamsDart sssGetParams =
    dylib.lookup<NativeFunction<SSSGetParamsC>>('SSS_get_params').asFunction();
