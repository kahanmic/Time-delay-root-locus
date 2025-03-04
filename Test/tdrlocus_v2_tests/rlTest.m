numerator = "1+0.1.*exp(-s)";
denominator = "2.*s+exp(-s)";

reg = [-30 5 -350 350];
minLogLim = -5;
maxLogLim = 10;
samples = 400;
ds = 0.1;
delGain = logspace(minLogLim, maxLogLim, samples);



% Brute force calculations
tic
brutePoles = [];
for K = delGain
    funStr = strcat('@(s)(', denominator, '+', num2str(K),'.*','(' ,numerator, ')', ')');
    Fun = str2num(funStr);
    poles = QPmR(reg, Fun);
    %[~, idxs] = sort(imag(abs(poles)));
    brutePoles = [brutePoles, poles];
end

for i = 1:size(brutePoles, 1)
    plot(real(brutePoles(i, :)), imag(brutePoles(i, :)), Color="green", LineWidth=2); hold on;
end
toc
%%
% Variable step -> 180x faster than brute force!!!
numerator = "1+0.1.*exp(-s)";
denominator = "2.*s+exp(-s)";
reg = [-30 5 0 350];

ds = 0.1;
[numP, numD] = string2matrix(numerator);
[denP, denD] = string2matrix(denominator);

[numP, denP, D] = create_rl_marix(numP, numD, denP, denD);

K0 = 0;
P = denP + K0*numP;
numdP = derivate_quasipolynomial(numP, D);
dendP = derivate_quasipolynomial(denP, D);

clZeros = compute_roots(reg, numP, D, ds);
roots = compute_roots(reg, P, D, ds);
poles = roots;

plot(real(roots), imag(roots), 'rx', 'MarkerSize', 4, 'MarkerFaceColor', 'k', 'LineWidth', 1.5); hold on;
plot(real(clZeros), imag(clZeros), 'bo', 'MarkerSize', 4, 'LineWidth', 1.5);
tic
cnt = 0;
while max(abs(roots-clZeros)) > 1e-6 & cnt < 400
    b = evaluate_poly(roots, numP, D, ds, false);
    d = evaluate_poly(roots, dendP, D, ds, false) + K0.*evaluate_poly(roots, numdP, D, ds, false);

    C = -(b./d);
    dK = 0.01/min(abs(C)); % Makes sure, that the next point won't be closer then 0.01 in radius
    if dK > 1e10
        dK = 1e10;
    end

    K0 = K0 + dK;
    ds = C*dK;
    currP = denP+K0*numP;
    roots = roots+ds;
    roots = newton_method(roots, currP, D, ds, 1e-6);
    poles = [poles; roots];
    cnt = cnt+1;
end
for i = 1:size(poles, 2)
    plot(real(poles(:, i)), imag(poles(:, i)), '--', Color="red", LineWidth=1); hold on 
    plot(real(poles(:, i)), -imag(poles(:, i)), '--' , Color="red", LineWidth=1); 
    % plot(real(poles(:, i)), imag(poles(:, i)), '.', Color="red", LineWidth=2); hold on 
    % plot(real(poles(:, i)), -imag(poles(:, i)), '.', Color="red", LineWidth=2); 
end
cnt
toc
% C = -(b./d);
% min(abs(C))
% dK = ds/min(abs(C))

%%

% Approximate with Newton method precision
numerator = "1+0.1.*exp(-s)";
denominator = "2.*s+exp(-s)";

reg = [-30 5 0 350];
minLogLim = -5;
maxLogLim = 10;
samples = 400;
ds = 0.1;
[numP, numD] = string2matrix(numerator);
[denP, denD] = string2matrix(denominator);

[numP, denP, D] = create_rl_marix(numP, numD, denP, denD);
delGain = logspace(minLogLim, maxLogLim, samples);
tic
dKs = diff(delGain);
K0 = delGain(1);

P = denP + K0*numP;
numdP = derivate_quasipolynomial(numP, D);
dendP = derivate_quasipolynomial(denP, D);

roots = compute_roots(reg, P, D, ds);
poles = roots;
%plot(hAx, real(roots), imag(roots), 'rx', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'LineWidth', 1.5);
Cs = [];
for dK = dKs
    b = evaluate_poly(roots, numP, D, ds, false);
    d = evaluate_poly(roots, dendP, D, ds, false) + K0.*evaluate_poly(roots, numdP, D, ds, false);
    
    K0 = K0 + dK;
    currP = denP+K0*numP;
    C = -(b./d);
    Cs = [Cs; C];
    ds = C*dK;
    roots = roots+ ds;
    roots = newton_method(roots, currP, D, ds, 1e-6);
    poles = [poles; roots];
    
    
end

for i = 1:size(poles, 2)
    % plot(real(poles(:, i)), imag(poles(:, i)), '.' ,Color="red", LineWidth=2); hold on 
    % plot(real(poles(:, i)), -imag(poles(:, i)), '.' ,Color="red", LineWidth=2); 
    plot(real(poles(:, i)), imag(poles(:, i)), '--', Color="green", LineWidth=1); hold on 
    plot(real(poles(:, i)), -imag(poles(:, i)), '--', Color="green", LineWidth=1); 
end

toc