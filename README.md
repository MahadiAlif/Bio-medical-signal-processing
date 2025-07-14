# Pulse Oximeter Firmware & Signal Processing

This repository contains the **signal processing code** for a pulse oximeter, as well as the foundation for a complete pulse oximeter firmware implementation. The current version provides MATLAB/Octave code for processing raw photoplethysmography (PPG) signals, extracting heart rate, and estimating SpO₂ (oxygen saturation).

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Folder Structure](#folder-structure)
- [Getting Started](#getting-started)
- [Signal Processing Details](#signal-processing-details)
- [Future Work](#future-work)
- [License](#license)
- [Contributing](#contributing)
- [Contact](#contact)

## Overview

**Pulse oximetry** is a non-invasive method to monitor the oxygen saturation of a patient's blood. This repository currently focuses on the **digital signal processing (DSP) pipeline** for analyzing RED and IR LED signals, as typically acquired from a pulse oximeter sensor. The code is designed for MATLAB/Octave and can be adapted for integration with embedded firmware.

## Features

- Reads and processes PPG data from a text file (`pulse.txt`)
- Applies analog and digital filtering (low-pass, high-pass, band-pass)
- Extracts AC and DC components of RED and IR signals
- Computes pulse rate (heart rate) and SpO₂ using standard algorithms
- Visualizes raw and filtered signals, as well as frequency spectra
- Modular structure for easy integration with hardware drivers and firmware

## Folder Structure

.
├── signal_processing/
│ └── pulse_oximeter_signal_processing.m
├── firmware/
│ └── (To be added: microcontroller code, drivers, etc.)
├── data/
│ └── pulse.txt
├── README.md


- `signal_processing/`: Contains MATLAB/Octave scripts for signal analysis.
- `firmware/`: Placeholder for embedded C/C++ firmware (coming soon).
- `data/`: Example input files for testing the signal processing code.

## Getting Started

### Prerequisites

- MATLAB or GNU Octave
- Basic knowledge of digital signal processing

### Usage

1. Place your raw data file (`pulse.txt`) in the `data/` directory.
2. Run the main script in MATLAB/Octave:


3. The script will:
- Read the data
- Filter and process the signals
- Plot intermediate and final results
- Output estimated pulse rate and SpO₂

### Data Format

- The `pulse.txt` file should have two columns (RED and IR signals), with a header row.

## Signal Processing Details

- **Filtering**: Implements both IIR and FIR filters to isolate the physiological signal from noise and artifacts.
- **Peak Detection**: Identifies maxima and minima to extract AC (pulsatile) and DC (baseline) components.
- **SpO₂ Calculation**: Uses the ratio-of-ratios method:

$$
\text{SpO}_2 = 110 - 25 \times \text{mean}(R_{\text{ratio}})
$$

where $$ R_{\text{ratio}} = \frac{(AC_{RED}/DC_{RED})}{(AC_{IR}/DC_{IR})} $$

- **Pulse Rate**: Estimated from the dominant frequency in the band-pass filtered RED signal.

## Future Work

- **Firmware Implementation**: Add embedded C/C++ code for real-time signal acquisition and processing on microcontrollers.
- **Sensor Drivers**: Integrate hardware drivers for common pulse oximeter sensors (e.g., MAX30100, MAX30102).
- **User Interface**: Develop a simple display/UI for real-time feedback.
- **Calibration & Validation**: Add routines for device calibration and comparison with clinical standards.

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements, bug fixes, or new features.

## Contact

For questions, suggestions, or collaboration, please contact:

- **Maintainer:** [Your Name]
- **Location:** Torino, Piemonte

*This repository is a work in progress. Stay tuned for updates on the full firmware implementation!*
