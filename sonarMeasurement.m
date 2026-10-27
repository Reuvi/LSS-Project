function [s,r,fs] = sonarMeasurement()
    fs = 100e3;
    M = 151;
    n = 0:M-1;
    t = n / fs;

    f0 = 15e3;
    f1 = 30e3;
    T = (M - 1) / fs;

    phase = 2 * pi * (f0*t + 0.5*((f1 - f0)/T).*t.^2);

    win = sin(pi * n / (M-1)) .^ 2;

    s = win .* sin(phase);
    s = s ./ max(abs(s));

    c = 343;

    d1 = 1.10;
    d2 = 2.40;

    N1 = round ((2*d1/c)*fs);
    N2 = round ((2*d2/c)*fs);

    a1 = 0.70;
    a2 = 0.35;

    dMax = 3.5;
    Nmax = ceil((2*dMax/c)*fs);

    h = zeros(1, Nmax+1);
    h(N1+1) = a1;
    h(N2+1) = a2;

    rClean = conv(s,h);

    rng (27, 'twister');

    sigmaW = 0.25;
    w = sigmaW * randn(size(rClean));

    r = rClean + w;

    s = s(:);
    r = r(:);
end
