clear
bmin = -10; bmax = 0; wmin = -10; wmax = 10;
ds = 0.1;
% P=[1.5 0.2 0 20.1;1 0 -2.1 0;0 0 3.2 0;0 0 0 1.4];
% D=[0;1.3;3.5;4.3];

numP = [1, 4.4774, 675.9528];
denP = [1 2 0];
K = 0.001487294491487172;
P = denP + K*numP; % 
P = [1.001 2.0045 0.6760];
D = 0;

beta = bmin:ds:bmax;
omega = wmin:ds:wmax;
reg = [bmin, bmax, wmin, wmax];
Fgrid = evaluate_poly(reg, P, D, ds, true);
dFgrid = evaluate_poly(reg, derivate_quasipolynomial(P, D), D, ds, true);

realContour = contourc(beta, omega, imag(Fgrid), [0 0]);
drealContour = contourc(beta, omega, imag(dFgrid), [0 0]);

contours = extract_contours2(realContour);
dcontours = extract_contours2(drealContour);
[x, y] = meshgrid(beta, omega);

contours
for i = 1:length(contours)
    plot(contours{i}.x, contours{i}.y, Color="yellow", LineWidth=2); hold on
end
for i = 1:length(dcontours)
    plot(dcontours{i}.x, dcontours{i}.y, "--r", LineWidth=1); hold on
end

%%
dFgrid(real(dFgrid) > 0) = NaN;
surf(x, y, imag(dFgrid), 'FaceColor', 'r', 'EdgeColor', 'none');
colormap(cool);
hold on
%%
%Freal = real(log(real(Fgrid)));
%Fgrid(real(Fgrid) > 0) = NaN;
surf(x, y, imag(Fgrid), 'FaceColor', 'b', 'EdgeColor', 'none');
colormap(hot);
%contour(beta, omega, real(Fgrid))