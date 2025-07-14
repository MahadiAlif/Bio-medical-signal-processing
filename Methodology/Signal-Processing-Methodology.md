## Expanded Methodology & Signal-Processing Rationale  

This section explains the physical principles and engineering choices that shape the pulse-oximeter pipeline, going deeper into **why** red and infrared light are used, **what** information sits in the AC and DC parts of the photoplethysmography (PPG) signal, and **how** each filter stage cleans the data before heart-rate and SpO₂ extraction.

---

### 1&nbsp;·&nbsp;Photoplethysmography (PPG) Fundamentals  

| Component | What it represents | Physiological origin |
|-----------|-------------------|----------------------|
| **DC level** | Slowly varying, large-amplitude baseline | Static absorption by skin, bone, venous blood, and the *non-pulsatile* arterial volume |
| **AC component** | Small, periodic fluctuations (≈ 0.5–3 Hz) | *Pulsatile* expansion/contraction of arteries with each heartbeat |

PPG sensors illuminate a vascular bed and record the fraction of light that survives the trip through (transmission mode) or back from (reflectance mode) the tissue. Because only the arterial bed changes its size with each heartbeat, isolating the AC component yields cardiovascular information, while the DC component normalises out constant optical losses[1].

---

### 2&nbsp;·&nbsp;Why Red (≈ 660 nm) and Infrared (≈ 880–940 nm)?  

1. **Spectral “optical window” of tissue**  
   Between ~600 nm and ~1 µm, biological tissues absorb/scatter light *least*. Using wavelengths inside this window permits centimetre-scale penetration needed to reach the arterial bed[1].

2. **Differential absorption of haemoglobin species**  
   Oxygenated haemoglobin (HbO₂) and deoxygenated haemoglobin (Hb) have distinct molar‐extinction coefficients:  
   - At **660 nm (red)**: Hb absorbs far more strongly than HbO₂ ⇒ AC/ DC ratio rises when the blood is *less* oxygenated.  
   - At **940 nm (IR)**: HbO₂ absorbs slightly more than Hb ⇒ ratio rises when the blood is *more* oxygenated[1].  

   Measuring the AC/DC ratio at both wavelengths and forming the “ratio-of-ratios”

   \[
     R=\frac{\tfrac{AC_{RED}}{DC_{RED}}}{\tfrac{AC_{IR}}{DC_{IR}}}
   \]

   produces a variable that declutters device-specific offsets (LED intensity, path length, photodiode gain) and correlates monotonically with arterial oxygen saturation, allowing a simple linear calibration  

   \[
      \text{SpO}_2 \approx 110 - 25\,R[1].
   \]

3. **Hardware practicality**  
   High-efficiency LEDs and photodiodes are inexpensive and well characterised at 660 nm and 940 nm, which keeps power budgets and bill-of-materials low for wearables.

---

### 3&nbsp;·&nbsp;Noise Sources & Their Spectral Footprint  

| Frequency band | Dominant artefacts | Mitigation strategy |
|----------------|--------------------|---------------------|
| **< 0.5 Hz** | Baseline wander from slow finger movement, respiration, vasomotor tone | High-pass FIR (cut-on ≈ 0.75 Hz) |
| **0.75–3 Hz** | Desired cardiac pulsations | Preserved by band-pass window |
| **> 3 Hz** | Muscle tremor, ambient-light flicker (100 / 120 Hz), quantisation noise | Butterworth low-pass (cut-off ≈ 3 Hz) |

---

### 4&nbsp;·&nbsp;Filtering Strategy in Detail  

1. **Low-Pass IIR (Butterworth) — 3 Hz**  
   *Goal:* Suppress high-frequency artefacts while retaining the entire physiological heart-rate range (rest up to ≈ 180 bpm → 3 Hz).  
   *Design choices*  
   - Maximally flat pass-band (Butterworth) avoids ripple that would distort pulse amplitude.  
   - Order **N = 4** satisfies 1 dB ripple / 60 dB stopband (calculated analytically, then converted to digital via impulse-invariance).  
   - Zero-phase `filtfilt` prevents group-delay distortion that would offset peak positions.

2. **High-Pass FIR (Hamming window) — 0.75 Hz**  
   *Goal:* Remove baseline drift while guaranteeing linear phase (critical for accurate peak timing).  
   *Design choices*  
   - Stop-band edge at 0.05 Hz (static offsets), pass-band edge at 0.75 Hz (above respiration).  
   - Hamming window offers ≥ 53 dB sidelobe rejection with a moderate tap count, balancing real-time footprint and stop-band attenuation.  
   - Zero-phase application again via `filtfilt`.

3. **Effective Band-Pass (0.75–3 Hz)**  
   The cascade of the two stages isolates the narrow band where cardiac pulsations live, boosting SNR and easing subsequent peak detection.

---

### 5&nbsp;·&nbsp;Feature Extraction Pipeline  

1. **Heart-Rate (Pulse Rate)**  
   - Compute FFT of band-pass RED channel.  
   - Locate dominant spectral peak \(f_{peak}\) and convert to bpm: \(HR = 60\,f_{peak}\).

2. **AC & DC Envelope Estimation**  
   - Detect local maxima/minima (AC) and baseline minima (DC) with a minimum 0.5 s peak-to-peak spacing to avoid false detections.  
   - Spline-interpolate these sparse points to produce smooth envelopes that match the sampling grid; this attenuates noise without blurring physiological variation.

3. **SpO₂ Calculation**  
   - Evaluate \(R(t)\) continuously, down-sample to 1 Hz to align with typical clinical display rates, take the mean, then apply the empirical calibration above.

---

### 6&nbsp;·&nbsp;Why a High-Pass Stage is Essential  

*Even after low-pass filtering, two obstacles remain:*

1. **Baseline wander (0.1–0.3 Hz):**  
   Slow vasomotor changes, finger temperature shifts, and subject motion alter the DC level, masking the comparatively tiny AC component. A high-pass cut-on just above that band restores a clean pulsatile waveform.

2. **Venous & Tissue Light Paths:**  
   Venous blood and non-vascular tissue do not pulsate, so their contribution lives almost entirely in the DC/very-low-frequency region. High-pass removal therefore isolates the arterial signal.

By eliminating these components before AC/DC ratio calculation we prevent denominator blow-ups and improve the linearity of the R→SpO₂ curve[1].

---

### 7&nbsp;·&nbsp;Implementation Notes  

- **Sampling @ 100 Hz** ensures > 30 samples/cardiac cycle even at high heart rates (180 bpm), satisfying Nyquist by a comfortable margin.  
- **Impulse-invariance mapping** preserves the Butterworth analogue magnitude shape while avoiding bilinear warping at these low cut-off frequencies.  
- **Fixed-point suitability:** Both filter coefficient sets have limited dynamic range and can be quantised for microcontroller implementation without overflow.  
- **Zero-phase filtering** doubles the filter cost but eliminates group delay, crucial when peak-to-peak times are used for heart-rate variability studies.

---

### 8&nbsp;·&nbsp;Summary  

By leveraging the physics of haemoglobin spectroscopy, a carefully tuned band-pass around 0.75–3 Hz, and envelope-based feature extraction, the pipeline transforms noisy raw ADC readings into clinically interpretable **heart rate** and **oxygen saturation** in real time. The modular MATLAB/Octave code can be ported straight into embedded C for an end-to-end wearable pulse-oximeter firmware.

---

[1]
