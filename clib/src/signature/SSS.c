#include "SSS.h"



void SSS_init(SSS_ctx* ctx, int n, int degree,int tid, BIGNUM* p) {
    BN_CTX *BNctx = BN_CTX_new();
    ctx->secret = BN_new();
    ctx->share = BN_new();
    ctx->prime = BN_new();
    BN_copy(ctx->prime, p);

    ctx->coeffs = (BIGNUM**)malloc((degree + 1) * sizeof(BIGNUM*));
    for (int i = 0; i <= degree; i++) {
        ctx->coeffs[i] = BN_new();
    }

    ctx->shares = (BIGNUM**)malloc((n + 1) * sizeof(BIGNUM*));
    for(int i = 1; i <= n; i++) {
        ctx->shares[i] = BN_new();
    }

    ctx->shards = (BIGNUM**)malloc(n * sizeof(BIGNUM*));
    for(int i = 0; i < n; i++) {
        ctx->shards[i] = BN_new();
    }
  
    if (!ctx->coeffs || !ctx->secret || !ctx->share || !ctx->shares || !ctx->shards) {
        fprintf(stderr, "SSS_init: Memory allocation failed\n");
        exit(1);
    }

    ctx->random_list = (BIGNUM**)malloc((n + 1) *sizeof(BIGNUM*));
    for (int i = 0; i <= n; i++) {
        ctx->random_list[i] = BN_new();
        BN_rand_range(ctx->random_list[i], ctx->prime);
    }

    ctx->n = n;
    ctx->t = degree + 1;
    ctx->tid = tid;

    //生成秘密多项式
    generate_secret(ctx->secret,ctx->prime);

    generate_coefficients(ctx->coeffs, ctx->secret, degree, BNctx,ctx->prime);

    BN_CTX_free(BNctx);
}


void generate_secret(BIGNUM* secret,BIGNUM *prime) {
    // 生成随机数
    if (!BN_rand_range(secret, prime)) {
        fprintf(stderr, "Failed to generate random number\n");
        exit(1);
    }
}

void init_crypto_params(BIGNUM* PRIME) {
    BN_CTX *ctx = BN_CTX_new();
    BIGNUM* p = BN_new();
    
    // 生成安全素数
    BN_generate_prime_ex(p, MIN_PRIME_BITS, 1, NULL, NULL, NULL);
    BN_copy(PRIME, p);

    // 释放内存
    BN_free(p);
    BN_CTX_free(ctx);
}

void generate_coefficients(BIGNUM** coeffs, const BIGNUM* secret,int degree, BN_CTX* ctx,BIGNUM *prime) {
    for (int i = 1; i <= degree; i++) {
        BN_rand_range(coeffs[i], prime);
    }
    BN_copy(coeffs[0], secret);
}


void evaluate_poly(BIGNUM* result, BIGNUM** coeffs, const BIGNUM* x,int degree , BN_CTX* ctx,BIGNUM *prime) {
    BIGNUM *term = BN_new();
    BIGNUM *x_pow = BN_new();
    BN_one(x_pow);  // x_pow = 1

    for (int i = 0; i <= degree; i++) {
        // term = coeffs[i] * x^i
        BN_mod_mul(term, coeffs[i], x_pow, prime, ctx);
        //result += term
        BN_mod_add(result, result, term, prime, ctx);

        //x_pow *= x
        BN_mod_mul(x_pow, x_pow, x, prime, ctx);
        
    }

    BN_free(term);
    BN_free(x_pow);
}

void generate_shares(BIGNUM** shares, BIGNUM** coeffs, BN_CTX* ctx, int n,int t,BIGNUM *prime) {
    BIGNUM* index = BN_new();
    for (int i = 1; i <= n; i++) {
        BN_set_word(index, (unsigned long)i);
        evaluate_poly(shares[i], coeffs, index, t - 1, ctx,prime);
    }
    BN_free(index);
}

void aggregate_shares(BIGNUM* shares, BIGNUM** shares_shards, BN_CTX* ctx, int n,BIGNUM *prime) {
    BIGNUM* tmp = BN_new();
    BN_zero(tmp);
    //累加f_i(j)得到y_j
    for (int i = 0; i < n; i++) {
        BN_mod_add(tmp, tmp, shares_shards[i], prime, ctx);
    }
    BN_copy(shares, tmp);
    BN_free(tmp);
}



