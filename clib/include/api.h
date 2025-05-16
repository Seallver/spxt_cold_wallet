#ifndef SPX_API_H
#define SPX_API_H

#include <stddef.h>
#include <stdint.h>

#include "params.h"

#define CRYPTO_ALGNAME "SPHINCS+"

#define CRYPTO_SECRETKEYBYTES SPX_SK_BYTES
#define CRYPTO_PUBLICKEYBYTES SPX_PK_BYTES
#define CRYPTO_BYTES SPX_BYTES
#define CRYPTO_SEEDBYTES 3*SPX_N

/*
 * Returns the length of a secret key, in bytes
 */
unsigned long long crypto_sign_secretkeybytes(void);

/*
 * Returns the length of a public key, in bytes
 */
unsigned long long crypto_sign_publickeybytes(void);

/*
 * Returns the length of a signature, in bytes
 */
unsigned long long crypto_sign_bytes(void);

/*
 * Returns the length of the seed required to generate a key pair, in bytes
 */
unsigned long long crypto_sign_seedbytes(void);

/**
 * Returns an array containing a detached signature.
 */
int crypto_sign_signature(uint8_t *sig,  int * sm_len,
                          const uint8_t *m, int mlen, const uint8_t *fors_sk, 
                          const uint8_t *wots_sk, const uint8_t* pk, unsigned char* last_root,
                          int level, int level_count);

int crypto_sign_first_level_signature(uint8_t *sig,  int * sm_len,
                          const uint8_t *m, int mlen, const uint8_t *fors_sk, 
                          const uint8_t *wots_sk, const uint8_t* pk, unsigned char* last_root,
                          int level_count);

#endif
