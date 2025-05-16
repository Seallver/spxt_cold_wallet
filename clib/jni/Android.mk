LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := signAPI
LOCAL_SRC_FILES := \
    ../src/signature/address.c \
    ../src/randombytes.c \
    ../src/signature/merkle.c \
    ../src/signature/wots.c \
    ../src/signature/wotsx1.c \
    ../src/utils/utils.c \
    ../src/utils/utilsx1.c \
    ../src/signature/fors.c \
    ../src/signature/sign.c \
    ../src/hash/SM3.c \
    ../src/hash/hash_SM3.c \
    ../src/hash/thash_SM3_simple.c \
    ../signAPI.c

LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/../include \
    $(LOCAL_PATH)/../include/hash \
    $(LOCAL_PATH)/../include/signature \
    $(LOCAL_PATH)/../include/params \
    $(LOCAL_PATH)/../include/utils

LOCAL_CFLAGS := -O3 -std=c99 -DPARAMS=sphincs-SM3-128f

include $(BUILD_SHARED_LIBRARY)
