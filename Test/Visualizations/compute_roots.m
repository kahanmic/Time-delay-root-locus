function polyRoots = compute_roots(reg, P, D, ds)
% P
    if D == 0
        polyRoots = roots(P).';
    else
    if nargin < 4
        ds = 0.1;
    end

    bmin = reg(1); bmax = reg(2); wmin = reg(3); wmax = reg(4);
    beta = bmin:ds:bmax;
    omega = wmin:ds:wmax;

    Fgrid = evaluate_poly(reg, P, D, ds, true);
    realContour = contourc(beta, omega, real(Fgrid), [0 0]);
    [contLens, pointsReal] = extract_contours(realContour);

    inedxCS = cumsum(contLens);
    Freal = evaluate_poly(pointsReal, P, D, ds, false);
    rootsApprox = approximate_root_position(pointsReal, Freal, inedxCS, ds);

    polyRoots = newton_method(rootsApprox, P, D, ds, 1e-6);
    numRoots = argp_integral(reg, P, D, ds);

    if length(polyRoots) ~= numRoots
        polyRoots = compute_roots(reg, P, D, ds/2);
    end
    end
end