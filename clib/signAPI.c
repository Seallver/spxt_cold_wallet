#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "api.h"
#include "params.h"

//ndk-build

int spx_sign(unsigned char * sm, int *sm_len,
             const unsigned char *input_m, const int mlen, const unsigned char *R,
             const unsigned char *input_wots_sk, const unsigned char *input_fors_sk, const uint8_t* input_pk, int t , unsigned char* last_root, int *level)
{
    int ret = 0;

    int spx_wots_avg = (SPX_D - 1) / t;
    int spx_wots_last = spx_wots_avg + (SPX_D - 1) % t;

    // 本地拷贝缓冲区
    unsigned char m[mlen];
    unsigned char wots_sk[SPX_SK_BYTES];
    unsigned char fors_sk[SPX_SK_BYTES];
    unsigned char pk[SPX_PK_BYTES];
    unsigned char *sm_tmp = malloc(SPX_BYTES + mlen);

    int level_count = 0;

    // 参数校验
    if (!input_m || !input_wots_sk || !input_fors_sk || !sm_tmp || !input_pk) {
        ret = -1;
        goto cleanup;
    }

    // 拷贝输入到本地缓冲区
    memcpy(m, input_m, mlen);
    memcpy(fors_sk, input_fors_sk, SPX_SK_BYTES);
    memcpy(wots_sk, input_wots_sk, SPX_SK_BYTES);
    memcpy(pk, input_pk, SPX_PK_BYTES);
    memcpy(sm_tmp, R, SPX_N);

    // 签名
    if(*level != 0){
        if(*level + 2 * spx_wots_avg > SPX_D) level_count = spx_wots_last;
        else level_count = spx_wots_avg;
        if (crypto_sign_signature(sm_tmp, sm_len , m, mlen, fors_sk, wots_sk, pk, last_root, *level, level_count)) {
            ret = -1;
            goto cleanup;
        }
        *level += level_count;
    }
    else{
        level_count = spx_wots_avg;
        if (crypto_sign_first_level_signature(sm_tmp, sm_len , m, mlen, fors_sk, wots_sk, pk, last_root, level_count)) {
            ret = -1;
            goto cleanup;
        }
    }

    memcpy(sm, sm_tmp, *sm_len);

cleanup:
    free(sm_tmp);
    
    return ret;
}
        