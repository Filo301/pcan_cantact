#include <stm32f0xx_hal.h>
#include "timestamp.h"

static volatile uint32_t g_ts_us32_high = 0;

void ts_init(void)
{
    /* TIM14: 1 MHz microsecond counter */
    __HAL_RCC_TIM14_CLK_ENABLE();
    TIM14->PSC = (48 - 1); /* 48 MHz / 48 = 1 MHz */
    TIM14->ARR = 0xFFFF;
    TIM14->EGR = TIM_EGR_UG;
    TIM14->DIER |= TIM_DIER_UIE;
    TIM14->CR1 |= TIM_CR1_CEN;
    HAL_NVIC_SetPriority(TIM14_IRQn, 0, 0);
    HAL_NVIC_EnableIRQ(TIM14_IRQn);

    /* TIM3: ~42 us tick for PCAN timestamps */
    __HAL_RCC_TIM3_CLK_ENABLE();
    TIM3->PSC = (2048 - 1); /* 42.666 us per tick */
    TIM3->CR1 &= (uint16_t)(~TIM_CR1_CKD);
    TIM3->CR1 |= TIM_CLOCKDIVISION_DIV1;
    TIM3->CR1 |= TIM_CR1_CEN;
}

uint32_t ts_us32(void)
{
    uint32_t base;
    uint16_t cnt;
    do
    {
        base = g_ts_us32_high;
        cnt  = TIM14->CNT;
    } while (base != g_ts_us32_high); /* handle overflow during read */
    return base | cnt;
}

uint16_t ts_pcan42_now(void)
{
    return TIM3->CNT;
}

uint16_t ts_ms16(void)
{
    return HAL_GetTick() & 0xFFFFu;
}

void TIM14_IRQHandler(void)
{
    if (TIM14->SR & TIM_SR_UIF)
    {
        TIM14->SR = (uint16_t)~TIM_SR_UIF;
        g_ts_us32_high += 0x10000u;
    }
}
