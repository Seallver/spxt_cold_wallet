LOCAL_PATH := $(call my-dir)

# 预编译 OpenSSL 库（libcrypto.so）
include $(CLEAR_VARS)
LOCAL_MODULE := crypto                  # 模块名（必须和 .so 文件名匹配，去掉前缀 'lib' 和后缀 '.so'）
LOCAL_SRC_FILES := ./$(TARGET_ARCH_ABI)/libcrypto.so  # 路径根据实际情况调整
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/../include/openssl  # OpenSSL 头文件路径
include $(PREBUILT_SHARED_LIBRARY)  


include $(CLEAR_VARS)
LOCAL_MODULE    := DKGapi
LOCAL_SRC_FILES := \
    ../src/signature/address.c \
    ../src/signature/merkle.c \
    ../src/signature/wots.c \
    ../src/signature/wotsx1.c \
    ../src/signature/SSS.c\
    ../src/utils/utils.c \
    ../src/utils/utilsx1.c \
    ../src/signature/fors.c \
    ../src/signature/sign.c \
    ../src/hash/SM3.c \
    ../src/hash/hash_SM3.c \
    ../src/hash/thash_SM3_simple.c \
    ../DKGapi.c

LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/../include \
    $(LOCAL_PATH)/../include/hash \
    $(LOCAL_PATH)/../include/signature \
    $(LOCAL_PATH)/../include/params \
    $(LOCAL_PATH)/../include/utils \
    $(LOCAL_PATH)/../include/openssl

LOCAL_CFLAGS := -O3 -std=c99 -DPARAMS=sphincs-SM3-128s
LOCAL_SHARED_LIBRARIES := crypto

include $(BUILD_SHARED_LIBRARY)
