clc

filename = 'pulse.txt';
data = readmatrix('pulse.txt', 'HeaderLines', 1);
Led_R = data(:,1);
Led_IR = data(:,2);
fs = 100;                         

start_idx = fs * 10 + 1;
end_idx = start_idx + fs * 60 - 1;
R = Led_R(start_idx:end_idx);
IR = Led_IR(start_idx:end_idx);
t = (0:length(R)-1) / fs;  % Time vector in seconds

figure(1);
plot(t, R, 'r', 'DisplayName', 'RED');
xlabel('Time (s)');
ylabel('Amplitude');
title('RED signals (60 seconds, after 10s skip)');
legend;
figure(2)
plot(t, IR, 'b', 'DisplayName', 'IR');
xlabel('Time (s)');
ylabel('Amplitude');
title('IR signals (60 seconds, after 10s skip)');
legend;



pass_freq = 3;
stop_freq = 6;
Rp = 1;
As = 60;
w_hp = 18;

pf_w = pass_freq*2*pi;
sf_w = stop_freq*2*pi;

% %filter order
N = ceil(log10((10.^(Rp/10)-1)/(10.^(As/10)-1))/(2*log10(pf_w/sf_w)));
 
omega_c1 = pf_w/(nthroot((10.^(Rp/10)-1),2*N));
omega_c2 = sf_w/(nthroot((10.^(As/10)-1),2*N));
 
omega_c = (omega_c1+omega_c2)/2;

f_a = linspace(0,2*pi*40,100001);
h_analog = 1./(1+(f_a/omega_c).^(2*N));
 
 
%plotting the filter
figure(3)
plot(f_a, 10*log10(h_analog), LineWidth=2);
grid on; zoom on;
xlabel("f '[Hz]")
ylim([-100 10])

 
%poles
k = 0:2*N-1;
pk_all = omega_c*exp(1j*k*pi/N)*exp((1j*pi*(N+1)/2)/N);

figure(4)
plot(pk_all, 'o'); axis square;
pk = pk_all(real(pk_all)<0);

%computing transfer function
%we need to put empty vector in place of zeros as there are no zeros

[ba,aa] = zp2tf([], pk, omega_c^N);
figure(5)
zplane(ba,aa)

[bi, ai] = impinvar(ba,aa,fs);
figure(6)
freqz(bi,ai,1024,fs);

% Apply filtering
R_lp = filtfilt(bi, ai, R);
IR_lp = filtfilt(bi, ai, IR);

% Plot results
figure(7)
subplot(2,1,1)
plot(t, R, 'r:', t, R_lp, 'k', 'LineWidth', 1.5)
legend('Original RED','Filtered RED')
title('RED Signal Comparison')

subplot(2,1,2)
plot(t, IR, 'b:', t, IR_lp, 'k', 'LineWidth', 1.5)
legend('Original IR','Filtered IR')
xlabel('Time (s)')

% high pass filter design
whp_s = 0.05;
whp_p = 0.75;
B_T = whp_p - whp_s;
B_T_pulse = B_T*2*pi/fs;     %normalised also
N_hamming = ceil((6.6*pi)/B_T_pulse);

f_c = (whp_p+whp_s)/(2*fs);
M = ceil((N_hamming-1)/2);
n = 0:N_hamming-1;
w_n = 0.54-0.46*cos((2*pi*n)/(N_hamming-1));

% Ideal low-pass filter impulse response
hlp = 2 * f_c * sinc(2 * f_c * (n - M));

% Ideal high-pass filter impulse response using spectral inversion
hhp = -hlp;
hhp(M+1) = 1 - hlp(M+1);

hhp = hhp.*w_n;
figure(8)
freqz(hhp,1,1024,fs)

%applying high pass
% Apply FIR high-pass filter using zero-phase filtering
R_bp = filtfilt(hhp, 1, R_lp);
IR_bp = filtfilt(hhp, 1, IR_lp);

%figure for R
figure;
subplot(3,1,1);
plot(t, R, 'r', 'LineWidth', 1.2);
title('Original RED Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(t, R_lp, 'g', 'LineWidth', 1.2);
title('RED after Low-pass Filter');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(t, R_bp, 'k', 'LineWidth', 1.2);
title('RED after Band-pass Filter');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;


%Figure for IR
figure;
subplot(3,1,1);
plot(t, IR, 'b', 'LineWidth', 1.2);
title('Original IR Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(t, IR_lp, 'g', 'LineWidth', 1.2);
title('IR after Low-pass Filter');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(t, IR_bp, 'k', 'LineWidth', 1.2);
title('IR after Band-pass Filter');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

% pulse rate computation
N    = length(R_bp);
Nfft = 2^nextpow2(N);
Y    = fft(R_bp, Nfft);
P2 = abs(Y)/Nfft;            
P1 = P2(1:Nfft/2+1);         
P1(2:end-1) = 2*P1(2:end-1); 
f  = fs*(0:(Nfft/2)) / Nfft; 

% 3) Zero‐centered amplitude A0
Y0   = fftshift(Y);                  
A0   = abs(Y0)/Nfft;                 
f0   = (-Nfft/2 : Nfft/2-1)*(fs/Nfft);

% 4) Plot 
figure;
plot(f0, 20*log10(A0), 'LineWidth',1.5);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Zero-centered Spectrum');
grid on;

[~, idx] = max(P1);
peakFreq = f(idx);
pulseRate_bpm = peakFreq * 60; 

fprintf('Estimated pulse rate: %.1f bpm\n', pulseRate_bpm);

% AC extremes
[pkR_max, locR_max] = findpeaks(R_bp, t, 'MinPeakDistance',0.5);
[pkR_min, locR_min] = findpeaks(-R_bp, t, 'MinPeakDistance',0.5);
pkR_min = -pkR_min;

[pkIR_max, locIR_max] = findpeaks(IR_bp, t, 'MinPeakDistance',0.5);
[pkIR_min, locIR_min] = findpeaks(-IR_bp, t, 'MinPeakDistance',0.5);
pkIR_min = -pkIR_min;

% DC minima
[blR_min, locR_bl]   = findpeaks(-R_lp, t, 'MinPeakDistance',0.5);
blR_min = -blR_min;
[blIR_min, locIR_bl] = findpeaks(-IR_lp, t, 'MinPeakDistance',0.5);
blIR_min = -blIR_min;

% Interpolation
R_ac_max  = interp1(locR_max,  pkR_max,  t, 'spline');
R_ac_min  = interp1(locR_min,  pkR_min,  t, 'spline');
R_dc_base = interp1(locR_bl,   blR_min,  t, 'spline');

IR_ac_max  = interp1(locIR_max,  pkIR_max,  t, 'spline');
IR_ac_min  = interp1(locIR_min,  pkIR_min,  t, 'spline');
IR_dc_base = interp1(locIR_bl,   blIR_min,  t, 'spline');


R_AC = R_ac_max - R_ac_min;
R_DC = R_dc_base;
IR_AC = IR_ac_max - IR_ac_min;
IR_DC = IR_dc_base;

R_ratio = (R_AC ./ R_DC) ./ (IR_AC ./ IR_DC);

%  Sampling R_ratio once per second
seconds = 0:floor(t(end));
R_sec   = interp1(t, R_ratio, seconds);

R_mean  = mean(R_sec,'omitnan');
SaO2    = 110 - 25 * R_mean;

% plotting
figure;

% RED AC (band-pass)
subplot(2,2,1);
plot(t, R_bp, 'k', 'LineWidth',1); hold on;
plot(locR_max, pkR_max, 'ro', 'MarkerSize',4);
plot(locR_min, pkR_min, 'ro', 'MarkerSize',4);
title('RED – AC component');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% RED DC (low-pass)
subplot(2,2,2);
plot(t, R_lp, 'k', 'LineWidth',1); hold on;
plot(locR_bl, blR_min, 'ro', 'MarkerSize',4);
title('RED – DC baseline');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% IR AC (band-pass)
subplot(2,2,3);
plot(t, IR_bp, 'k', 'LineWidth',1); hold on;
plot(locIR_max, pkIR_max, 'ro', 'MarkerSize',4);
plot(locIR_min, pkIR_min, 'ro', 'MarkerSize',4);
title('IR – AC component');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% IR DC (low-pass)
subplot(2,2,4);
plot(t, IR_lp, 'k', 'LineWidth',1); hold on;
plot(locIR_bl, blIR_min, 'ro', 'MarkerSize',4);
title('IR – DC baseline');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% Super-title with SpO2
sgtitle(sprintf('Interpolating curves – SpO_2 = %.2f%%', SaO2));





