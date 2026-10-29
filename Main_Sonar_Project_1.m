clear; clc; close all;

% Obtain transmitted and measured sonar signals
[s,r,fs] = sonarMeasurement();

% Time vectors
ts = (0:length(s)-1)/fs;
tr = (0:length(r)-1)/fs;

% Plot transmitted signal
figure;
plot(ts*1e3,s,'LineWidth',1.2)
grid on
xlabel('Time [ms]')
ylabel('Amplitude')
title('Transmitted Signal $s[n]$','Interpreter','latex')

% Plot received signal
figure;
plot(tr*1e3,r,'LineWidth',1.0)
grid on
xlabel('Time [ms]')
ylabel('Amplitude')
title('Measured Received Signal $r[n]$','Interpreter','latex')


[corr, lag] = xcorr(r, s);
figure;
plot(lag, abs(corr))
xlabel('Lag (s)')
ylabel('Absolute Correlation')

% from the peaks on the plot
N1 = 641;
N2 = 1401;

% speed of sound (m/s)
c = 343;

% distances
d1 = c * N1 / (2 * fs)
d2 = c * N2 / (2 * fs)

