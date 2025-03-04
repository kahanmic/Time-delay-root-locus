clear
bmin = -10; bmax = 0; wmin = -10; wmax = 10;
ds = 0.1;
dk = 10;
kmin = 0; kmax = 1000;

numP = [1, 4.4774, 675.9528];
denP = [1 2 0];
denP = [1, 4.4774, 675.9528];
numP = [1 2 0];
D = 0;

beta = bmin:ds:bmax;
omega = wmin:ds:wmax;
reg = [bmin, bmax, wmin, wmax];

gains = kmin:dk:kmax;
colPal = linspace(0.1, 1, length(gains));

for i = 1:length(gains)
    K = gains(i);
    P = denP + K*numP;
    dP = derivate_quasipolynomial(P, D);
    dFgrid = evaluate_poly(reg, dP, D, ds, true);
    clPoles = compute_roots(reg, P, D, ds);

    realdContour = contourc(beta, omega, real(dFgrid), [0 0]);
    imagdContour = contourc(beta, omega, imag(dFgrid), [0 0]);
    dcontours = extract_contours2(imagdContour);

    for i = 1:length(dcontours)
        plot(dcontours{i}.x, dcontours{i}.y, Color=[colPal(i) 0 0], LineWidth=1); hold on
        plot(real(clPoles), imag(clPoles), ...
                'x' ,Tag='clpole', MarkerSize=10, LineWidth=1.5, ...
                MarkerFaceColor='red', MarkerEdgeColor='red'); hold off

        pause(0.05);
    end
end