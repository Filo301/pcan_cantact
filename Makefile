# ------------------------------------------------
# Generic Makefile (based on gcc)
#
# ChangeLog :
#   2017-02-10 - Several enhancements + project update mode
#   2015-07-22 - first version
# ------------------------------------------------

######################################
# target / profile selection
######################################
# Usage:
#   make f042
#   make f072

MCU ?= F042
BOARD ?= cantact_16

BUILD_DIR := build/$(shell echo $(MCU) | tr A-Z a-z)
OUT_TAG   := $(shell echo $(MCU) | tr A-Z a-z)

TARGET = pcan_cantact_$(OUT_TAG)
TARGET_VARIANT = $(shell echo $(BOARD) | tr '[:lower:]' '[:upper:]')

$(shell mkdir -p $(BUILD_DIR))

# ================= PER-MCU SETTINGS ==================
ifeq ($(MCU),F042)
  MCU_DEFS  += -DSTM32F042x6 -DMCU_STM32F042
  LDSCRIPT  = STM32F042C6Tx_FLASH.ld
  MCU_DEFS  += -DRXQ_LEN=64 -DTXQ_LEN=32 -DUSB_IN_STAGING=1
  HEAP_SIZE = 0x000
  STACK_SIZE= 0x400
else ifeq ($(MCU),F072)
  MCU_DEFS  += -DSTM32F072xB -DMCU_STM32F072
  LDSCRIPT  = STM32F072C8Tx_FLASH.ld
  MCU_DEFS  += -DRXQ_LEN=256 -DTXQ_LEN=128 -DUSB_IN_STAGING=2
  HEAP_SIZE = 0x200
  STACK_SIZE= 0x800
else
  $(error Unknown MCU=$(MCU). Use F042 or F072)
endif

# ================= COMMON FLAGS ======================


######################################
# source
######################################
# C sources
C_SOURCES =  \
Src/main.c \
Src/usbd_conf.c \
Src/usbd_desc.c \
Src/pcan_usb.c \
Src/pcan_can.c \
Src/pcan_led.c \
Src/pcan_protocol.c \
Src/timestamp.c \
Src/system_stm32f0xx.c \
Src/syscalls_min.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_ll_usb.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_pcd.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_pcd_ex.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_rcc.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_rcc_ex.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_gpio.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_cortex.c \
Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_can.c \
Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_core.c \
Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ctlreq.c \
Middlewares/ST/STM32_USB_Device_Library/Core/Src/usbd_ioreq.c \

# ASM sources
ASM_SOURCES =  \
startup_stm32f042x6.s


#######################################
# binaries
#######################################
PREFIX = arm-none-eabi-
# The gcc compiler bin path can be either defined in make command via GCC_PATH variable (> make GCC_PATH=xxx)
# either it can be added to the PATH environment variable.
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)gcc
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

#######################################
# CFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m0

# fpu
# NONE for Cortex-M0/M0+/M3

# float-abi


# mcu flags
MCFLAGS = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)

# macros for gcc
# AS defines
AS_DEFS =

# C defines
C_DEFS =  \
-DUSE_HAL_DRIVER \
-DNDEBUG \
$(BOARD_DEFS) \
$(MCU_DEFS)


# AS includes
AS_INCLUDES =

# C includes
C_INCLUDES =  \
-ISrc \
-IInc \
-IDrivers/STM32F0xx_HAL_Driver/Inc \
-IMiddlewares/ST/STM32_USB_Device_Library/Core/Inc \
-IDrivers/CMSIS/Device/ST/STM32F0xx/Include \
-IDrivers/CMSIS/Include


# compile gcc flags
ASFLAGS = $(MCFLAGS) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fno-common -fdata-sections -ffunction-sections

CFLAGS = $(MCFLAGS) $(C_DEFS) $(C_INCLUDES) $(OPT) -std=c99 \
$(BOARD_FLAGS) \
-D$(TARGET_VARIANT)

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT ?=

# libraries
LIBS = -lc -lm -lnosys
LIBDIR =
LDFLAGS = $(MCFLAGS) -specs=nano.specs $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref

# ================= COMMON FLAGS ======================
CFLAGS  += -Os -flto -ffunction-sections -fdata-sections -fno-common
CFLAGS  += -Wall -Wextra -Wshadow -Wconversion -Wformat=2 -Wundef \
           -Wno-missing-field-initializers
LDFLAGS += -Wl,--gc-sections -Wl,-T$(LDSCRIPT) \
           -Wl,--defsym,_Min_Heap_Size=$(HEAP_SIZE) \
           -Wl,--defsym,_Min_Stack_Size=$(STACK_SIZE)

# ======== convenience phony targets =========
.PHONY: f042 f072
f042: clean
	$(MAKE) MCU=F042 BOARD=$(BOARD) $(BOARD)

f072: clean
	$(MAKE) MCU=F072 BOARD=$(BOARD) $(BOARD)

.PHONY : all

# default action: build all
all: cantact_16 cantact_8 entree canable ollie sh_c30a

cantact_16:
	$(MAKE) MCU=$(MCU) BOARD=cantact_16 DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=16000000' elf hex bin

cantact_8:
	$(MAKE) MCU=$(MCU) BOARD=cantact_8 DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=8000000' elf hex bin

entree:
	$(MAKE) MCU=$(MCU) BOARD=entree DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=0' elf hex bin

canable:
	$(MAKE) MCU=$(MCU) BOARD=canable DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=0' elf hex bin

ollie:
	$(MAKE) MCU=$(MCU) BOARD=ollie DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=0' elf hex bin

sh_c30a:
	$(MAKE) MCU=$(MCU) BOARD=sh_c30a DEBUG=0 OPT=-Os BOARD_FLAGS='-DHSE_VALUE=24000000' elf hex bin

#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

ELF_TARGET = $(BUILD_DIR)/$(TARGET).elf
BIN_TARGET = $(BUILD_DIR)/$(TARGET).bin
HEX_TARGET = $(BUILD_DIR)/$(TARGET).hex

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@

$(BUILD_DIR):
	mkdir $@

bin: $(BIN_TARGET)

elf: $(ELF_TARGET)

hex: $(HEX_TARGET)

#######################################
# clean up
#######################################
clean:
	-rm -fR $(BUILD_DIR)*

clean_obj:
	-rm -f $(BUILD_DIR)*/*.o $(BUILD_DIR)*/*.d $(BUILD_DIR)*/*.lst

#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)

# *** EOF ***
