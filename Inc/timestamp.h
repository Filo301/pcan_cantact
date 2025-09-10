#pragma once
#include <stdint.h>

#define TS_PCAN42_FROM_US(_us) (((uint32_t)(_us) * 1000u) / 42666u)

void     ts_init(void);
uint32_t ts_us32(void);
uint16_t ts_pcan42_now(void);
uint16_t ts_ms16(void);
