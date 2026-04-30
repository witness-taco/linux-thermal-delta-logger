# Linux Thermal Analytics Logger

### Comparative time-series analysis of my DIY "cardboard & tape" forced induction enclosure
Built this quick tool for **comparative A/B testing** of thermal performance between "natural convection" (baseline) and "forced induction" (variable) states

**Analytical Objectives:**
*   **Establish control baselines:** Quantify thermal variance across open/closed/active-fan states
*   **Heat soak characterisation:** Model the saturation curve of internal components
*   **Identify thermal recirculation:** Use delta-over-ambient to detect dead zones or exhaust-to-intake feedback loops

---

# How to interpret results

### Steady-state convergence & gradient analysis

| Metric | Statistical Significance | Insight |
| :--- | :--- | :--- |
| **Baseline Delta ($\Delta T_{idle}$)** | $T_{case} - T_{ambient}$ at idle | **Steady-State Offset:** Measures the "noise floor" of your cooling. Target: 3–5°C reduction |
| **Thermal Ramp Rate** | The slope of the curve ($\frac{dT}{dt}$) during load | **Thermal Inertia:** A shallower slope indicates higher heat dissipation capacity, delaying the time to reach critical thresholds |
| **Saturation Point** | Asymptotic limit after >30m of sustained load | **Thermal Ceiling:** If the curve does not plateau, the system is in a state of **thermal runaway**, indicating the enclosure's exhaust rate < heat generation rate |
