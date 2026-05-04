# ====================
# Linux Thermal Logger
# ====================

set -uo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CSV_LOG="${SCRIPT_DIR}/thermal_log.csv"
readonly SPIKE_LOG="${SCRIPT_DIR}/thermal_spike_profile.log"

readonly INTERVAL_SEC=10
readonly TRIGGER_TEMP_C=65
readonly COOLDOWN_SEC=300

declare CPU_PATH=""
declare NVME_PATH=""
declare -i LAST_LOG_TS=0

trap 'printf "\nLogging terminated by user.\n"; exit 0' SIGINT SIGTERM

initialize_sensors() {
    CPU_PATH=$(grep -l "k10temp" /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs -I{} dirname {} | head -n 1)
    NVME_PATH=$(grep -l "nvme" /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs -I{} dirname {} | head -n 1)

    if [[ ! -f "$CSV_LOG" ]]; then
        echo "Timestamp,CPU_Temp,NVMe_Controller,NVIDIA_GPU" > "$CSV_LOG"
    fi
}

profile_processes() {
    local timestamp="$1"
    local cpu_temp="$2"

    echo "========================================================================" >> "$SPIKE_LOG"
    echo "THERMAL EVENT DETECTED: ${timestamp} | CPU: ${cpu_temp}°C" >> "$SPIKE_LOG"
    echo "Top 5 CPU-consuming processes:" >> "$SPIKE_LOG"
    ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 6 >> "$SPIKE_LOG"
    echo "========================================================================" >> "$SPIKE_LOG"
}

main() {
    initialize_sensors

    echo "--- Thermal logging started ---"
    echo "CSV Log     : $CSV_LOG"
    echo "Spike Log   : $SPIKE_LOG"
    echo "Threshold   : ${TRIGGER_TEMP_C}°C"
    echo "Cooldown    : ${COOLDOWN_SEC}s"
    echo "Interval    : ${INTERVAL_SEC}s"

    while true; do
        local current_ts
        local timestamp
        local cpu_t=0
        local nvme_t=0
        local nv_t=0

        current_ts=$(date +%s)
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        if [[ -n "$CPU_PATH" && -f "$CPU_PATH/temp1_input" ]]; then
            cpu_t=$(($(cat "$CPU_PATH/temp1_input") / 1000))
        fi

        if [[ -n "$NVME_PATH" && -f "$NVME_PATH/temp2_input" ]]; then
            nvme_t=$(($(cat "$NVME_PATH/temp2_input") / 1000))
        fi

        nv_t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0)
        
        # CSV telemetry
        echo "$timestamp,$cpu_t,$nvme_t,$nv_t" >> "$CSV_LOG"
        printf "\r[%s] CPU: %s°C | NVMe: %s°C | NVIDIA: %s°C   " "$timestamp" "$cpu_t" "$nvme_t" "$nv_t"

        # Spike profiling logic
        if (( cpu_t >= TRIGGER_TEMP_C )); then
            if (( current_ts - LAST_LOG_TS >= COOLDOWN_SEC )); then
                profile_processes "$timestamp" "$cpu_t"
                LAST_LOG_TS=$current_ts
            fi
        fi

        sleep "$INTERVAL_SEC"
    done
}

main "$@"