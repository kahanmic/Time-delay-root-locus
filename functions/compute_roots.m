function [newDs, polyRoots] = compute_roots(reg, P, D, ds, iteration)
% Compute roots of quasipolynomial on given region
    if D == 0
        polyRoots = roots(P).';
        newDs = ds;
    else

    bmin = reg(1); bmax = reg(2); wmin = reg(3); wmax = reg(4);
    beta = bmin:ds:bmax;
    omega = wmin:ds:wmax;

    Fgrid = evaluate_poly(reg, P, D, ds, true);
    realContour = contourc(beta, omega, real(Fgrid), [0 0]);
    [contLens, pointsReal] = extract_contours(realContour);

    inedxCS = cumsum(contLens);
    Freal = evaluate_poly(pointsReal, P, D, ds, false);
    rootsApprox = approximate_root_position(pointsReal, Freal, inedxCS, ds);

    polyRoots = newton_method(rootsApprox, P, D, 1e-6);

    argpShift = min(abs(imag(polyRoots(imag(polyRoots) ~= 0))));
    numRoots = argp_integral(reg, P, D, argpShift/2);

    if length(polyRoots) ~= numRoots && iteration < 5
       
        if ds/2 > 1e-3
            [newDs, polyRoots] = compute_roots(reg, P, D, ds/2, iteration+1);
        end
    else
        newDs = ds;
    end

    if length(polyRoots) ~= numRoots 
        polyRoots = NaN;
    end

    % Sort firstly by imaginary part, then by real part
    sortedRoots = sortrows([imag(polyRoots).' real(polyRoots).'], [1 2]);
    polyRoots = sortedRoots(:,2).' + sortedRoots(:,1).'*1i;
    
    end
end