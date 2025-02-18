numerator = "1+exp(-s-4)";
denominator = "2.*s+exp(-s)";  
%dnum = -exp(-s-4)
%dden = 2 - exp(-s)
Reg = [-10 5 0 50];
minLogLim = -5;
maxLogLim = 10;
samples = 400;

% Brute force
delPoles = []; % M x N matrix of M poles (rows) and N gains (columns)
delGain = logspace(minLogLim, maxLogLim, samples);

for K = delGain
    funStr = strcat('@(s)(', denominator, '+', num2str(K),'.*','(' ,numerator, ')', ')');
    Fun = str2num(funStr);
    poles = QPmR(Reg, Fun);
    [~, idxs] = sort(imag(abs(poles)));
    idx = idxs(1);
    delPoles = [delPoles, poles(idx)];
end

plot(real(delPoles), imag(delPoles)); hold on;

%% 
dKs = diff(delGain)
K0 = delGain(1)

funStr = strcat('@(s)(', denominator, ')');
Fun = str2num(funStr);
initPoles = QPmR(Reg, Fun);
[~, idxs] = sort(imag(abs(initPoles)));
idx = idxs(1);
s0 = initPoles(idx)

poles2 = [s0];
for dK = dKs

    b0 = 1+exp(-s0-4);
    a0 = 2*s0-exp(-s0);
    bdot0 = -exp(-s0-4);
    adot0 = 2-exp(-s0);
    
    ds = (K0.*b0 - (K0+dK).*b0)./(adot0+(K0+dK).*bdot0);
    
    s0 = s0+ ds;
    poles2 = [poles2, s0];
    K0 = K0 + dK;
end
poles2;
plot(poles2)

