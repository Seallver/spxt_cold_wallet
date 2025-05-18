#include <stddef.h>
#include <string.h>
#include <stdint.h>

#include "api.h"
#include "params.h"
#include "wots.h"
#include "fors.h"
#include "hash.h"
#include "thash.h"
#include "address.h"
#include "utils.h"
#include "merkle.h"

/*
 * Returns the length of a secret key, in bytes
 */
unsigned long long crypto_sign_secretkeybytes(void)
{
    return CRYPTO_SECRETKEYBYTES;
}

/*
 * Returns the length of a public key, in bytes
 */
unsigned long long crypto_sign_publickeybytes(void)
{
    return CRYPTO_PUBLICKEYBYTES;
}

/*
 * Returns the length of a signature, in bytes
 */
unsigned long long crypto_sign_bytes(void)
{
    return CRYPTO_BYTES;
}

/*
 * Returns the length of the seed required to generate a key pair, in bytes
 */
unsigned long long crypto_sign_seedbytes(void)
{
    return CRYPTO_SEEDBYTES;
}

/**
 * Returns an array containing a detached signature.
 */
int crypto_sign_first_level_signature(uint8_t * sig, int * sm_len,
                          const uint8_t *m, int mlen, const uint8_t *fors_sk, 
                          const uint8_t *wots_sk, const uint8_t* pk, unsigned char* last_root,
                          int level_count)
{
    spx_ctx ctx;

    unsigned char optrand[SPX_N];
    unsigned char mhash[SPX_FORS_MSG_BYTES];
    unsigned char root[SPX_N];
    uint32_t i;
    uint64_t tree;
    uint32_t idx_leaf;
    uint32_t wots_addr[8] = {0};
    uint32_t tree_addr[8] = {0};

    memcpy(ctx.sk_seed, fors_sk, SPX_N);
    memcpy(ctx.pub_seed, pk, SPX_N);

    initialize_hash_function(&ctx);

    set_type(wots_addr, SPX_ADDR_TYPE_WOTS);
    set_type(tree_addr, SPX_ADDR_TYPE_HASHTREE);

    hash_message(mhash, &tree, &idx_leaf, sig, pk, m, mlen, &ctx);
    sig += SPX_N;
    *sm_len += SPX_N;

    set_tree_addr(wots_addr, tree);
    set_keypair_addr(wots_addr, idx_leaf);

    /* Sign the message hash using FORS. */
    fors_sign(sig, root, mhash, &ctx, wots_addr);
    sig += SPX_FORS_BYTES;
    *sm_len += SPX_FORS_BYTES;

    memcpy(ctx.sk_seed, wots_sk, SPX_N);

    for (i = 0; i < level_count; i++) {
        set_layer_addr(tree_addr, i);
        set_tree_addr(tree_addr, tree);

        copy_subtree_addr(wots_addr, tree_addr);
        set_keypair_addr(wots_addr, idx_leaf);

        merkle_sign(sig, root, &ctx, wots_addr, tree_addr, idx_leaf);
        sig += SPX_WOTS_BYTES + SPX_TREE_HEIGHT * SPX_N;
        *sm_len += SPX_WOTS_BYTES + SPX_TREE_HEIGHT * SPX_N;

        /* Update the indices for the next layer. */
        idx_leaf = (tree & ((1 << SPX_TREE_HEIGHT)-1));
        tree = tree >> SPX_TREE_HEIGHT;
    }

    //更新root
    memcpy(last_root, root, SPX_N);

    return 0;
}

/**
 * Returns an array containing a detached signature.
 */
int crypto_sign_signature(uint8_t *sig, int * sm_len,
                          const uint8_t *m, int mlen, const uint8_t *fors_sk, 
                          const uint8_t *wots_sk, const uint8_t* pk, unsigned char* last_root,
                          int level, int level_count)
{
    spx_ctx ctx;

    unsigned char optrand[SPX_N];
    unsigned char mhash[SPX_FORS_MSG_BYTES];
    unsigned char root[SPX_N];
    uint32_t i;
    uint64_t tree;
    uint32_t idx_leaf;
    uint32_t wots_addr[8] = {0};
    uint32_t tree_addr[8] = {0};

    memcpy(ctx.sk_seed, fors_sk, SPX_N);
    memcpy(ctx.pub_seed, pk, SPX_N);

    initialize_hash_function(&ctx);

    set_type(wots_addr, SPX_ADDR_TYPE_WOTS);
    set_type(tree_addr, SPX_ADDR_TYPE_HASHTREE);

    hash_message(mhash, &tree, &idx_leaf, sig, pk, m, mlen, &ctx);
    sig += SPX_N;
    *sm_len += SPX_N;
    
    set_tree_addr(wots_addr, tree);
    set_keypair_addr(wots_addr, idx_leaf);

    /* Sign the message hash using FORS. */
    fors_sign(sig, root, mhash, &ctx, wots_addr);
    sig += SPX_FORS_BYTES;
    *sm_len += SPX_FORS_BYTES;

    memcpy(ctx.sk_seed, wots_sk, SPX_N);

    //计算地址
    for (i = 0; i < level; i++) {
        set_layer_addr(tree_addr, i);
        set_tree_addr(tree_addr, tree);

        copy_subtree_addr(wots_addr, tree_addr);
        set_keypair_addr(wots_addr, idx_leaf);

        /* Update the indices for the next layer. */
        idx_leaf = (tree & ((1 << SPX_TREE_HEIGHT)-1));
        tree = tree >> SPX_TREE_HEIGHT;
    }

    //进行签名
    memcpy(root, last_root, SPX_N);
    for (i = 0; i < level_count; i++) {
        set_layer_addr(tree_addr, i);
        set_tree_addr(tree_addr, tree);

        copy_subtree_addr(wots_addr, tree_addr);
        set_keypair_addr(wots_addr, idx_leaf);

        merkle_sign(sig, root, &ctx, wots_addr, tree_addr, idx_leaf);
        sig += SPX_WOTS_BYTES + SPX_TREE_HEIGHT * SPX_N;
        *sm_len += SPX_WOTS_BYTES + SPX_TREE_HEIGHT * SPX_N;

        /* Update the indices for the next layer. */
        idx_leaf = (tree & ((1 << SPX_TREE_HEIGHT)-1));
        tree = tree >> SPX_TREE_HEIGHT;
    }

    //更新root
    memcpy(last_root, root, SPX_N);

    return 0;
}