#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

const char *ecies_generate_secret_key(void);

const char *ecies_public_key_from(const char *secret_key_ptr);

const char *ecies_encrypt(const char *public_key_ptr, const char *message_ptr);

const char *ecies_decrypt(const char *secret_key_ptr, const char *message_ptr);
