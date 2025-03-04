numP = [1, 4.4774, 675.9528];
denP = [1 2 0];
D = 0;
dk = 0.0001;
kmin = 0; kmax = 1;
smin = -2; smax = 0;
ds = 0.1;
points = smin:ds:smax;
Ks = kmin:dk:kmax;

[x, y] = meshgrid(points, Ks);
F = zeros(size(x));
dF = zeros(size(x));
for i = 1:length(Ks)
    P = denP + Ks(i)*numP;
    dP = derivate_quasipolynomial(P, D);
    F(i,:) = evaluate_poly(points, P, D, ds, false);
    dF(i,:) = evaluate_poly(points, dP, D, ds, false);
end

cntF = contourc(points, Ks, F, [0 0]);
cntdF = contourc(points, Ks, dF, [0 0]);

contours = extract_contours2(cntF);
dcontours = extract_contours2(cntdF);
for i = 1:length(contours)
    plot(contours{i}.x, contours{i}.y, Color="yellow", LineWidth=2); hold on
end
for i = 1:length(dcontours)
    plot(dcontours{i}.x, dcontours{i}.y, "--r", LineWidth=1); hold on
end
%%
numP = [1, 4.4774, 675.9528];
denP = [1 2 0];
D = 0;
dk = 0.0001;
kmin = 0; kmax = 1;
smin = -2; smax = 0;
ds = 0.1;
points = smin:ds:smax;
Ks = kmin:dk:kmax;

s0 = (smax-smin)/2;
s0= -50
K0 = 10000;

P = denP+K0*numP;
dP = derivate_quasipolynomial(P, D);
ddP = derivate_quasipolynomial(dP, D);
g = [evaluate_poly(s0, P, D, ds, false); evaluate_poly(s0, dP, D, ds, false)];

cnt = 1;
while max(abs(g)) > 1e-5
    P = denP+K0*numP;
    dP = derivate_quasipolynomial(P, D);
    ddP = derivate_quasipolynomial(dP, D);

    g = [evaluate_poly(s0, P, D, ds, false); evaluate_poly(s0, dP, D, ds, false)];
    dg = [evaluate_poly(s0, dP, D, ds, false), evaluate_poly(s0, numP, D, ds, false);
        evaluate_poly(s0, ddP, D, ds, false), evaluate_poly(s0, derivate_quasipolynomial(numP, D), D, 0.1, false)];
    next = [s0; K0] - dg\g;
    s0 = next(1);
    K0 = next(2);
end
P = denP+K0*numP;
dP = derivate_quasipolynomial(P, D);
g = [evaluate_poly(s0, P, D, ds, false); evaluate_poly(s0, dP, D, ds, false)]
s0
K0



%%
F(F> 0) = NaN;
surf(x, y, F, 'EdgeColor', 'none')
xlabel("s")
ylabel("K")