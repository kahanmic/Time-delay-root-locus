function [newDs, polyRoots] = compute_roots(reg, P, D, ds, iteration)
% Compute roots of quasipolynomial on given region
    if D == 0
        polyRoots = roots(P).';
        polyRoots = polyRoots(imag(polyRoots) >= 0);
        newDs = ds;
    else
        reg = reg + [-3*ds 3*ds 0 3*ds];
        bmin = reg(1); bmax = reg(2); wmin = reg(3); wmax = reg(4);
        beta = bmin:ds:bmax;
        omega = wmin:ds:wmax;
        
        Fgrid = evaluate_poly(reg, P, D, ds, true);
        realContour = contourc(beta, omega, real(Fgrid), [0 0]);
        [contLensRe, pointsReal, ~] = extract_contours(realContour);
    
        imagContour = contourc(beta, omega, imag(Fgrid), [0 0]);
        [~, pointsImag, ~] = extract_contours(imagContour);
    
    
        inedxCS = cumsum(contLensRe);
        Freal = evaluate_poly(pointsReal, P, D, ds, false);
        Fimag = evaluate_poly(pointsImag, P, D, ds, false);
        rootsApprox = approximate_root_position(pointsReal, Freal, pointsImag, Fimag, inedxCS, ds);
    
        polyRootsInit = newton_method(rootsApprox, P, D, 1e-4);
        polyRoots = findDuplicates(polyRootsInit, P, D); % detects double roots
        argpShift = min(abs(imag(polyRoots(imag(polyRoots) ~= 0))));
        
        numRoots = argp_integral(reg, P, D, argpShift/2);
    
        if length(polyRoots) ~= numRoots && iteration < 6
           

            [newDs, polyRoots] = compute_roots(reg - [-3*ds 3*ds 0 3*ds], P, D, ds/2, iteration+1);
      
        else
            newDs = ds;
        end
        
        if length(polyRoots) ~= numRoots 
            polyRoots = NaN;
        end
    
    end

    if ~isempty(polyRoots)
        sortedRoots = sortrows([imag(polyRoots).' real(polyRoots).'], [1 2]);
        polyRoots = sortedRoots(:,2).' + sortedRoots(:,1).'*1i;
    end
end