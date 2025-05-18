function num_roots = argp_integral(Reg, P, D, diff_s)
% Compute numerical argument principal integral

    diff_s = min([diff_s, 0.05]);
    enlarge = [-diff_s, diff_s, -diff_s, diff_s];
    
    region = Reg + enlarge;
    dsy = max([diff_s, (region(4)-region(3))/1e4]);
    dsx = max([diff_s, (region(2)-region(1))/1e4]);

    grid_x = region(1):dsx:region(2);
    grid_y = region(3):dsy:region(4);
  
    cntur = [grid_x + region(3)*1i, region(2) + grid_y*1i, ...
        grid_x(end:-1:1) + region(4)*1i, region(1) + grid_y(end:-1:1)*1i];
    dS = [ones(size(grid_x))*dsx, ones(size(grid_y))*1i*dsy, -ones(size(grid_x))*dsx, ...
        -ones(size(grid_y))*1i*dsy];

    F = evaluate_poly(cntur, P, D, NaN, false);
    dP = derivate_quasipolynomial(P, D);
    dF = evaluate_poly(cntur, dP, D, NaN, false);
    
    num_roots = round(abs(real(sum((dF./F).*dS)/(2*pi*1i))));
end