#pragma once
#include <stdint.h>

// Experimental Swift C ABI. The handle is retained by Swift and must be destroyed once.
extern "C" {
void *qbloom_swift_new(void);
void qbloom_swift_destroy(void *handle);
int32_t qbloom_swift_greeting(void *handle, char *buffer, int32_t capacity);
int32_t qbloom_swift_count(void *handle);
int32_t qbloom_swift_increment(void *handle);
int32_t qbloom_swift_reset(void *handle);
}
