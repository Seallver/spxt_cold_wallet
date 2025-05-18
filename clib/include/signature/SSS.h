#ifndef SSS_H
#define SSS_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <openssl/bn.h>
#include "params.h"

// 质数相关参数
#define MIN_PRIME_BITS 3 * SPX_N * 8   // 最小质数位数

typedef struct
{
    BIGNUM* secret; // 秘密份额(0次项)
    BIGNUM** coeffs; // 多项式系数
    BIGNUM* share; // 共享份额
    BIGNUM** random_list; // 随机数列表
    BIGNUM* prime;
    BIGNUM** shares;
    BIGNUM** shards;
    int n;
    int t;
    int tid;
} SSS_ctx;

SSS_ctx* SSS_new(const char* prime_str, int n, int t, int tid);
void SSS_free(SSS_ctx* ctx);

// 调用时需要用到 ctx 的函数
int SSS_get_secret(SSS_ctx* ctx, char* out_buf, int buf_len);

// 初始化SSS上下文，独立生成秘密和多项式系数
void SSS_init(SSS_ctx* ctx,int n,int degree, int tid, BIGNUM* p);

//生成随机秘密
void generate_secret(BIGNUM* secret, BIGNUM* p);

// 初始化加密参数
void init_crypto_params(BIGNUM* PRIME);

// 生成多项式系数
void generate_coefficients(BIGNUM** coeffs, const BIGNUM *secret,int degree,  BN_CTX *ctx, BIGNUM* p);

// 多项式求值
void evaluate_poly(BIGNUM *result, BIGNUM** coeffs,const BIGNUM *x,int degree,  BN_CTX *ctx, BIGNUM* p);

// 生成共享份额，即i发送给j的份额f_i(j)
void generate_shares(BIGNUM** shares, BIGNUM** coeffs,  BN_CTX *ctx, int n, int t,BIGNUM *prime);

//聚合共享份额，计算出y_i
void aggregate_shares(BIGNUM* shares, BIGNUM** shares_shards, BN_CTX* ctx, int n, BIGNUM* p);

#endif