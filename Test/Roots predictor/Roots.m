numerator = "1+exp(-s-4)";
denominator = "2.*s+exp(-s)";  

% Q(s) = 1+exp(-s-4)+K.*(2.*s+exp(-s))
%dQ = -exp(-s-4)+K*(2-exp(-s)

% numerator = "s.^2+4.4774.*s+675.9528";
% denominator = "s.*(s+2)";
%dnum = -exp(-s-4)
%dden = 2 - exp(-s)

Reg = [-10 5 0 50];
minLogLim = -5;
maxLogLim = 10;
samples = 400;

% Brute force
delPoles = []; % M x N matrix of M poles (rows) and N gains (columns)
delGain = logspace(minLogLim, maxLogLim, samples);

tic
for K = delGain
    funStr = strcat('@(s)(', denominator, '+', num2str(K),'.*','(' ,numerator, ')', ')');
    Fun = str2num(funStr);
    poles = QPmR(Reg, Fun);
    %[~, idxs] = sort(imag(abs(poles)));
    delPoles = [delPoles, poles];
end

for i = 1:size(delPoles, 1)
    plot(real(delPoles(i, :)), imag(delPoles(i, :)), Color="yellow", LineWidth=2); hold on;
end
toc
%% 
tic
dKs = diff(delGain);
K0 = delGain(1);
    
funStr = strcat('@(s)(', denominator, ')');
Fun = str2num(funStr);
initPoles = QPmR(Reg, Fun);
[~, idxs] = sort(imag(abs(initPoles)));

s0 = initPoles(idxs);

poles2 = [s0];
for dK = dKs

    % b0 = 1+exp(-s0-4);
    % a0 = 2.*s0-exp(-s0);
    % bdot0 = -exp(-s0-4);
    % adot0 = 2-exp(-s0);

    %------------------------------------------
    % b0 = s0.^2+4.4774.*s0+675.9528;
    % a0 = s0.*(s0+2);
    % bdot0 = 2.*s0+4.4774;
    % adot0 = 2.*s0+2;

    %-------------------------------------------
    b = 1+exp(-s0-4);
    d = 2-exp(-s0)-K0.*(exp(-s0-4));
    % b = s0.^2+4.4774.*s0+675.9528;
    % d = 2.*s0+2+K0.*(s0.^2+4.4774.*s0+675.9528);
    %ds = (K0.*b0 - (K0+dK).*b0)./(adot0+(K0+dK).*bdot0);
    C = -(b./d);
    ds = C*dK;
    s0 = s0+ ds;
    poles2 = [poles2, s0];
    
    K0 = K0 + dK;
end

for i = 1:size(poles2, 1)
    plot(real(poles2(i, :)), imag(poles2(i, :)), '-.' ,Color="red", LineWidth=2); 
    plot(real(poles2(i, :)), -imag(poles2(i, :)), '-.' ,Color="red", LineWidth=2); 
end
toc


