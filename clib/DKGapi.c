#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "api.h"
#include "params.h"
#include "SSS.h"

//ndk-build

//test p:37569050840555812858808529259147178277672403889196246504085638510597234100206666892230387825378571439462937676394327

SSS_ctx* SSS_new(const char* prime_str, int n, int t, int tid) {
    BIGNUM* bn_prime = NULL;
    if (!BN_dec2bn(&bn_prime, prime_str)) return NULL;

    SSS_ctx* ctx = (SSS_ctx*)malloc(sizeof(SSS_ctx));
    SSS_init(ctx, n, t - 1, tid, bn_prime); 

    BN_CTX* BNctx = BN_CTX_new();
    generate_shares(ctx->shares, ctx->coeffs, BNctx, ctx->n, ctx->t, ctx->prime);

    BN_free(bn_prime);
    BN_CTX_free(BNctx);
    return ctx;
}



int access_j_shares(SSS_ctx* ctx, int j, char* r, char* s) {
    if (!ctx || j <= 0 || j > ctx->n || !r || !s) {
        return -1;  // 参数错误
    }

    char* tmp_r = BN_bn2dec(ctx->random_list[j]);
    char* tmp_s = BN_bn2dec(ctx->shares[j]);

    if (!tmp_r || !tmp_s) {
        if (tmp_r) OPENSSL_free(tmp_r);
        if (tmp_s) OPENSSL_free(tmp_s);
        return -2; // 转换失败
    }

    // 复制字符串到调用者传入的缓冲区
    strcpy(r, tmp_r);
    strcpy(s, tmp_s);

    // 释放 BN_bn2dec 返回的内存
    OPENSSL_free(tmp_r);
    OPENSSL_free(tmp_s);

    return 0;
}

int aggregate_j_shares(SSS_ctx* ctx, int j, const char* r, const char* s) {
    if (!ctx || j <= 0 || j > ctx->n || !r || !s) {
        return -1;  // 参数错误
    }

    // 将 r 转成 BIGNUM
    BIGNUM* r_bn = BN_new();
    BN_dec2bn(&r_bn, r);

    if (!r_bn) return -2;

    // 将 s 转成 BIGNUM
    BIGNUM* s_bn = BN_new();
    BN_dec2bn(&s_bn, s);
    if (!s_bn) {
        BN_free(r_bn);
        return -3;
    }

    // 更新 ctx 中的值
    BN_CTX* BNctx = BN_CTX_new();
    BN_mod_add(ctx->random_list[j], ctx->random_list[j], r_bn, ctx->prime, BNctx);

    BN_copy(ctx->shards[j - 1], s_bn);

    BN_CTX_free(BNctx);
    BN_free(s_bn);
    BN_free(r_bn);

    return 0;
}

int gen_shards(SSS_ctx* ctx, char* blind_sk) {
    if (!ctx || !blind_sk) {
        return -1;
    }

    BN_CTX* BNctx = BN_CTX_new();
    if (!BNctx) return -2;

    BIGNUM* blinding_shard = BN_new();
    if (!blinding_shard) {
        BN_CTX_free(BNctx);
        return -3;
    }

    BN_copy(blinding_shard, ctx->secret);

    for (int i = 1; i <= ctx->n; i++) {
        if (i < ctx->tid) {
            BN_mod_add(blinding_shard, blinding_shard, ctx->random_list[i], ctx->prime, BNctx);
        }
        if (i > ctx->tid) {
            BN_mod_sub(blinding_shard, blinding_shard, ctx->random_list[i], ctx->prime, BNctx);
        }
    }

    char* tmp = BN_bn2dec(blinding_shard);
    if (!tmp) {
        BN_free(blinding_shard);
        BN_CTX_free(BNctx);
        return -4;
    }

    // 把结果复制到调用者缓冲区
    strcpy(blind_sk, tmp);

    OPENSSL_free(tmp);
    BN_free(blinding_shard);
    BN_CTX_free(BNctx);

    return 0;
}










void SSS_free(SSS_ctx* ctx) {
    if (!ctx) return;

    // 释放 secret、share、prime
    if(ctx->secret)
        BN_free(ctx->secret);
    if(ctx->share)
        BN_free(ctx->share);
    if(ctx->prime)
        BN_free(ctx->prime);

    // 释放 coeffs：共 t 项（t = degree + 1）
    if (ctx->coeffs) {
        for (int i = 0; i < ctx->t; ++i) {
            if(ctx->coeffs[i])
                BN_free(ctx->coeffs[i]);
        }
        free(ctx->coeffs);
    }

    // 释放 random_list：0 ~ n
    if (ctx->random_list) {
        for (int i = 0; i <= ctx->n; ++i) {
            if(ctx->random_list[i])
                BN_free(ctx->random_list[i]);
        }
        free(ctx->random_list);
    }

    // 释放 shares：从 1 到 n（shares[0] 没初始化）
    if (ctx->shares) {
        for (int i = 1; i <= ctx->n; ++i) {
            if(ctx->shares[i])
                BN_free(ctx->shares[i]);
        }
        free(ctx->shares);
    }

    // 释放 shards：0 到 n-1
    if (ctx->shards) {
        for (int i = 0; i < ctx->n; ++i) {
            if(ctx->shards[i])
                BN_free(ctx->shards[i]);
        }
        free(ctx->shards);
    }

}



int SSS_get_params(SSS_ctx* ctx, char* sk_buf, char* share_buf) {
    if (!ctx || !sk_buf || !share_buf) {
        return -1;
    }

    BN_CTX* BNctx = BN_CTX_new();
    if (!BNctx) return -2;

    BN_copy(ctx->shards[ctx->tid - 1], ctx->shares[ctx->tid]);

    aggregate_shares(ctx->share, ctx->shards, BNctx, ctx->n, ctx->prime);

    char* tmp_sk = BN_bn2dec(ctx->secret);
    char* tmp_share = BN_bn2dec(ctx->share);

    if (!tmp_sk || !tmp_share) {
        if (tmp_sk) OPENSSL_free(tmp_sk);
        if (tmp_share) OPENSSL_free(tmp_share);
        BN_CTX_free(BNctx);
        return -3;
    }

    strcpy(sk_buf, tmp_sk);
    strcpy(share_buf, tmp_share);

    OPENSSL_free(tmp_sk);
    OPENSSL_free(tmp_share);

    BN_CTX_free(BNctx);

    return 0;
}