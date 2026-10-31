%% Industrial Monitoring Project
% Main script
% Problem Solutions start further down

clear;
clc;
close all;

%% ================================================================
% Load and display the industrial environment
% ================================================================

%env = factoryEnvironment();

% robot from 2,2 to 38,18
% collision radius is 0.4 m
% speed up to 1 m/s

% q_critical_battery = 0.6
% q(t) = q(0)*e^(λ*t)
%   q(0)=1, fully charged at t=0
% q(t) = e^(-1.7*10^-3*t)
% 0.6 = e^(-1.7*10^-3*t)
% log(0.6) = -1.7*10^-3*t

% [seconds]
t_before_critical = -10^3/1.7*log(0.6)

function [value] = ramp(t)
    % matrix-compatible implementation
    value = max(0, t);

    % simple implementation
    % if t>=0
    %     value = t;
    % else
    %     value = 0;
    % end
end

% linear interpolation, from `a` to `b`, where `t ∈ [0,1]` indicates the percentage from `a` towards `b`
% function [value] = lerp(a,b,t)
%     value = a + (b-a)*t
% end

function [x,y] = position(t)
    % <60 second response time to 90%, according to SGAS707 datasheet
    % 4 stops for measurement
    % time for travel is about 52.84 seconds, leaving
    % a little over 247/4 seconds for each sensing period
    % [seconds]
    t_sensing_once = 60;

    % workflow
    % measure
    % 2,2 to 8,15
    % measure
    % 8,15 to 12,10
    % 12,10 to 20,5
    % measure
    % 20,5 to 30,15
    % 30,15 to 38,18
    % measure

    locations = [
        2,  2;
        8,  15;
        12, 10;
        20, 5;
        30, 15;
        38, 18
    ];

    % t_travel is time between each location
    % if moving in a straight line at 1 [m/s]
    t_travel = [];
    for i = 2:size(locations,1)
        vector = (locations(i,1:2) - locations(i-1,1:2));
        dist = sqrt(vector(1)^2 + vector(2)^2);
        t_seconds = dist / 1; % t = d / 1 [m/s]
        t_travel = [t_travel, t_seconds];
    end

    % round up t_travel for nice numbers
    % make sure to round UP so that speed
    % is no more than 1 [m/s]
    % t_travel = 14.3178, 6.4031, 9.4340, 14.142, 8.5440
    t_travel_rounded = [14.32, 6.41, 9.44, 14.15, 8.55]
    for i=1:size(t_travel_rounded,2)
        if t_travel_rounded(i) < t_travel(i)
            disp("ERROR: SPEED TOO FAST")
        end
    end


    % 2,8,12,20,30,38
    % x(t) = 2 + (8-2)*r((t-60)/14.32) - (8-2)*r((t-60)/14.32-1)
    fprintf("\nx(t) = 2 +\n");
    elapsed_time = t_sensing_once; % starting time; start moving after sensing once
    x = zeros(size(t)) + 2; % starting position
    for i = 2:size(locations,1)
        location_diff = locations(i,1)-locations(i-1,1);
        % ramp up to `distance` units at a speed of distance/length_of_travel [m/s] before stopping:
        %    distance * min(1, ramp((t-t0)/length_of_travel))
        x = x + location_diff*min(1,ramp((t-elapsed_time)/t_travel_rounded(i-1)));
        if i == size(locations,1)
            fprintf("    %.2f*r((t-%.2f)/%.2f)  -  %.2f*r((t-%.2f)/%.2f-1)\n", location_diff, elapsed_time, t_travel_rounded(i-1), location_diff, elapsed_time, t_travel_rounded(i-1));
        else
            fprintf("    %.2f*r((t-%.2f)/%.2f)  -  %.2f*r((t-%.2f)/%.2f-1) +\n", location_diff, elapsed_time, t_travel_rounded(i-1), location_diff, elapsed_time, t_travel_rounded(i-1));
            elapsed_time = elapsed_time + t_travel_rounded(i-1);
            % there are sensing stops after reaching (8,15) and (20,5), i=2,4
            if i==2 || i==4
                elapsed_time = elapsed_time + t_sensing_once;
            end
        end
    end

    fprintf("\ny(t) = 2 +\n");
    elapsed_time = t_sensing_once; % starting time; start moving after sensing once
    y = zeros(size(t)) + 2; % starting position
    for i = 2:size(locations,1)
        location_diff = locations(i,2)-locations(i-1,2);
        % ramp up to `distance` units at a speed of distance/length_of_travel [m/s] before stopping:
        %    distance * min(1, ramp((t-t0)/length_of_travel))
        y = y + location_diff*min(1,ramp((t-elapsed_time)/t_travel_rounded(i-1)));
        if i == size(locations,1)
            fprintf("    %.2f*r((t-%.2f)/%.2f)  -  %.2f*r((t-%.2f)/%.2f-1)\n", location_diff, elapsed_time, t_travel_rounded(i-1), location_diff, elapsed_time, t_travel_rounded(i-1));
        else
            fprintf("    %.2f*r((t-%.2f)/%.2f)  -  %.2f*r((t-%.2f)/%.2f-1) +\n", location_diff, elapsed_time, t_travel_rounded(i-1), location_diff, elapsed_time, t_travel_rounded(i-1));
            elapsed_time = elapsed_time + t_travel_rounded(i-1);
            % there are sensing stops after reaching (8,15) and (20,5), i=2,4
            if i==2 || i==4
                elapsed_time = elapsed_time + t_sensing_once;
            end
        end
    end


    % t_travel_total = sum(t_travel_rounded)
    % t_sensing_once
    % t_mission = sum(t_travel_rounded) + t_sensing_once*4
    % q_after_mission = e^(-1.7*10^-3*t_mission)
end

t = 0:0.01:300;
[x,y] = position(t);

% whether to plot [factory, x(t), y(t), |v(t)|]
plots = [0 0 0 0]

if plots(1) ~= 0
    env = factoryEnvironment();

    plot(x, y, '.')
    theta = linspace(0,2*pi,10);
    radius = 0.4;
    for k = 1:floor(size(t,2)/4)
        xc = x(k*4);
        yc = y(k*4);
        xCircle = xc + radius*cos(theta);
        yCircle = yc + radius*sin(theta);
        fill(xCircle, yCircle, [0.70 0.70 0.70], 'EdgeColor','r', 'LineWidth',1.5);
    end


    circles = [
        2,2;
        8,15;
        20,5;
        38,18;
    ];
    theta = linspace(0,2*pi,10);
    radius = 0.1;
    for k = 1:size(circles,1)
        xc = circles(k,1);
        yc = circles(k,2);
        xCircle = xc + radius*cos(theta);
        yCircle = yc + radius*sin(theta);
        fill(xCircle, yCircle, [0.70 0.70 0.70], 'EdgeColor','g', 'LineWidth',1.5);
    end
end

if plots(2) ~= 0
    figure
    plot(t, x)
    title("x-axis position over time")
    xlabel("t [s]")
    ylabel("x [m]")
end

if plots(3) ~= 0
    figure
    plot(t, y)
    title("y-axis position over time")
    xlabel("t [s]")
    ylabel("y [m]")
end


if plots(4) ~= 0
    x_speed = (x(2:end) - x(1:end-1))/0.01;
    y_speed = (y(2:end) - y(1:end-1))/0.01;
    v = sqrt(x_speed.^2 + y_speed.^2);
    figure
    hold on
    plot(t(1:end-1),v)
    plot([0,300], [1,1])
    xlabel("t [s]")
    ylabel("v [m/s]")
end



% PROBLEM 1 FINAL VALUES
% x(t) = 2 +
%     6.00*r((t-60.00)/14.32)  -  6.00*r((t-60.00)/14.32-1) +
%     4.00*r((t-134.32)/6.41)  -  4.00*r((t-134.32)/6.41-1) +
%     8.00*r((t-140.73)/9.44)  -  8.00*r((t-140.73)/9.44-1) +
%     10.00*r((t-210.17)/14.15)  -  10.00*r((t-210.17)/14.15-1) +
%     8.00*r((t-224.32)/8.55)  -  8.00*r((t-224.32)/8.55-1)
%
% y(t) = 2 +
%     13.00*r((t-60.00)/14.32)  -  13.00*r((t-60.00)/14.32-1) +
%     -5.00*r((t-134.32)/6.41)  -  -5.00*r((t-134.32)/6.41-1) +
%     -5.00*r((t-140.73)/9.44)  -  -5.00*r((t-140.73)/9.44-1) +
%     10.00*r((t-210.17)/14.15)  -  10.00*r((t-210.17)/14.15-1) +
%     3.00*r((t-224.32)/8.55)  -  3.00*r((t-224.32)/8.55-1)

% measurement coordinates at (2,2), (8,15), (20,5), (38,18)
% t_travel_total = 52.870
% t_sensing_once = 60
% t_mission = 292.87
% q_after_mission = 0.6078









% PROBLEM 2.
% R_inf = A*C^(-alpha)
% alpha = 0.602
% A = 8.0*10^4
% R_inf = 8.0*10^4*C^(-0.602)

C = 1:0.1:100;
R_inf = 8.0*10^4*C.^(-0.602);

% whether to plot [linear, logarithmic]
plots_2 = [0 0]

if plots_2(1) ~= 0
    figure
    plot(C,R_inf)
    xlabel("C [ppm]")
    ylabel("R_{∞} [Ω]")
end
if plots_2(2) ~= 0
    figure
    loglog(C,R_inf)
    xlabel("C [ppm]")
    ylabel("R_{∞} [Ω]")
end


% 2.iii DISCUSSION
% The sensitivity is lower with high VOC concentrations
% compared to low VOC concentrations; when C changes
% from 1 to 20, R_inf drops by a factor of about 6.07
% i.e., it drops by about 66821 [Ω]
% and when C changes from 81 to 100, R_inf drops by
% a factor of about 1.13 (a drop of about 676.44 [Ω])







% Problem 3
% Eq 1. Vout(T) = Vc * RL / (Rs(t)) + RL)
% Eq 2. Rs = Rinf(c). We assume we have reached a steady state solution
% Knowns Vc = 5, Rl = 10,000 Ohms

% 3.i Expression derived in writeup
Vc = 5;
Rl = 10000;
Vout = Vc * Rl ./ (R_inf + Rl);

% 3.ii
plots_3 = [0]

if plots_3(1) ~= 0
    figure
    plot(C,Vout);
    xlabel("C [ppm]");
    ylabel("Vout [V]");
end

% 3.iii Discussion
    %The transformation from the VOC concentration to output voltage is
    %not linear. As the concentration increases the VOut detection
    %increases logarythmically. 

% 3.iv Expression derived in the writeup
    %  Rs(t) = -10000 + 50000 / Vout(T)

% 3.v Expression derived in the writeup
    % C(t) = ( ( 80000 * Vout(t) ) / (-10000 * Vout(t) + 50000))^(1/0.602)









% Problem 4

% tau * r'(t) + r(t) = r_inf
% All initial conditions assumed 0 for initial steps
tau = 22;
plots_4 = [0, 0, 0, 0];

% 4.i derived in writeup
    % System is time invarient, causual, stable, and linear
    
%4.ii Unit Step Response, Equation Derived in Writeup
t = 0:0.01:100;
R_Step = 1 - exp(-t/22);

if plots_4(1) ~= 0
    figure;
    plot(t, R_Step);
    xlabel("Time [s]");
    ylabel("Resistance [ohm]");
end

%4.iii Impulse Response, Equation Derived in Writeup
R_Impulse = exp(-t/22) / 22

if plots_4(2) ~= 0
    figure;
    plot(t, R_Impulse);
    xlabel("Time [s]");
    ylabel("Resistance [ohm]");
end

%4.iv discusion in writeup, checked and their the same

%4.v derivation and discussion in writeup
rs_t90 = -22 * log(1/10)

%4.vi, rinf at a steady state solution for c = 5, 50
rinf_1_vi = 8.0*10^4 * 5^(-0.602)
rinf_2_vi = 8.0*10^4 * 50^(-0.602)

%RS Derived in writeup
rs_actual = 7591.2 + exp(-t/22) * 22769.8

if plots_4(3) ~= 0
    figure;
    plot(t, rs_actual);
    xlabel("Time [s]");
    ylabel("Resistance [ohm]");
end

%Vout derived in writeup
vout_realistic = 5 * 10^4 ./ ((rs_actual) + 10^4)

if plots_4(4) ~= 0
    figure;
    plot(t, vout_realistic);
    xlabel("Time [s]");
    ylabel("Voltage [v]");
end










% Problem 5

%5.i For each ADC resolution with N bits there are 2^N levels and the voltage resolution is V_REF/(2^N).
    
N8 = 8
L8 =256 
DV8= 5/(256) % 0.0195

N10=10 
L10=1024 
DV10=5/(1024) % 0.0049

N12=12
L12=4096
DV12=5/(4096) % 0.0012

%5.ii vout[n] = vout(nTs), where the original function domain from 0 -> 100 so max value n1/10 = 100, n = 1000
n = 0:1:1000;
tS = 0.1;
sampled_vout = 5 * 10^4 ./ ((7591.2 + exp(-(n * tS)/22) * 22769.8) + 10^4); % as derived before replace t with n*Ts 

%5.iii
% from class Vq[n] = Δ * (⌊(x[n]) / Δ⌋ + 1/2), where this is K in their formula and delta chances for each


k8 = min(floor(sampled_vout ./ DV8), L8 - 1);
ADC8 = (k8 + 0.5) * DV8;

k10 = min(floor(sampled_vout ./ DV10), L10 - 1);
ADC10 = (k10 + 0.5) * DV10;

k12 = min(floor(sampled_vout ./ DV12), L12 - 1);
ADC12 = (k12 + 0.5) * DV12;

%5.iv, graphs in graph section
plots_5 = [0, 0, 0, 1];

if plots_5(1) ~= 0
    figure;
    plot(t, vout_realistic, 'w-', 'LineWidth', 6);
    xlabel("Time [s]");
    ylabel("Voltage [v]");
    title("ADC 8")

    hold on;

    plot(n*tS, sampled_vout, 'r-', 'LineWidth', 4);
    plot(n*tS, ADC8, 'g-', 'LineWidth', 2);

    hold off;
end

if plots_5(2) ~= 0
    figure;
    plot(t, vout_realistic, 'w-', 'LineWidth', 6);
    xlabel("Time [s]");
    ylabel("Voltage [v]");
    title("ADC 10")

    hold on;

    plot(n*tS, sampled_vout, 'r-', 'LineWidth', 4);
    plot(n*tS, ADC10, 'g-', 'LineWidth', 2);

    hold off;
end

if plots_5(3) ~= 0
    figure;
    plot(t, vout_realistic, 'w-', 'LineWidth', 6);
    xlabel("Time [s]");
    ylabel("Voltage [v]");
    title("ADC 12")

    hold on;

    plot(n*tS, sampled_vout, 'r-', 'LineWidth', 4);
    plot(n*tS, ADC12, 'g-', 'LineWidth', 2);

    hold off;
end

%5.v Quantize the steady-state voltage from Problem 3

VQ8_C = (min(floor(Vout ./ DV8), L8 - 1) + 0.5) .* DV8;
VQ10_C = (min(floor(Vout ./ DV10), L10 - 1) + 0.5) .* DV10;
VQ12_C = (min(floor(Vout ./ DV12), L12 - 1) + 0.5) .* DV12;

%Reconstruct concentration from each quantized voltage

C_hat8 = ((80000 .* VQ8_C) ./ (50000 - 10000 .* VQ8_C)).^(1 / 0.602);

C_hat10 = ((80000 .* VQ10_C) ./ (50000 - 10000 .* VQ10_C)).^(1 / 0.602);

C_hat12 = ((80000 .* VQ12_C) ./ (50000 - 10000 .* VQ12_C)).^(1 / 0.602);

%5.vi Absolute relative concentration error, in percent

eC8 = 100 .* abs(C_hat8 - C) ./ C;
eC10 = 100 .* abs(C_hat10 - C) ./ C;
eC12 = 100 .* abs(C_hat12 - C) ./ C;

if plots_5(4) ~= 0
    figure;

    plot(C, eC8, 'r-', 'LineWidth', 1.2);
    hold on;

    plot(C, eC10, 'g-', 'LineWidth', 1.2);

    plot(C, eC12, 'y-', 'LineWidth', 1.2);

    hold off;
    grid on;

    xlabel('C [ppm]');
    ylabel('Relative concentration error [%]');
    title('Concentration error after ADC quantization');
    legend('8-bit ADC', '10-bit ADC', '12-bit ADC', 'Location', 'best');
end


[max_eC8, index_eC8] = max(eC8);
[max_eC10, index_eC10] = max(eC10);
[max_eC12, index_eC12] = max(eC12);


%5.vii and 5.viii in the writeup

% Statistics used for comparing them
fprintf('8-bit: max = %.4f%% at %.1f ppm; mean = %.4f%%\n', max_eC8, C(index_eC8), mean(eC8));

fprintf('10-bit: max = %.4f%% at %.1f ppm; mean = %.4f%%\n', max_eC10, C(index_eC10), mean(eC10));

fprintf('12-bit: max = %.4f%% at %.1f ppm; mean = %.4f%%\n', max_eC12, C(index_eC12), mean(eC12));