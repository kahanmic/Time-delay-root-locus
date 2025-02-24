function num_zeros = argp_integral(Reg, P, D, ds)
    region = Reg + [-ds, ds, -ds, ds];
    grid_x = region(1):ds:region(2);
    grid_y = region(3):ds:region(4);
  
    cntur = [grid_x + region(3)*1i, region(2) + grid_y*1i, ...
        grid_x(end:-1:1) + region(4)*1i, region(1) + grid_y(end:-1:1)*1i];
    dS = [ones(size(grid_x)), ones(size(grid_y))*1i, -ones(size(grid_x)), ...
        -ones(size(grid_y))*1i]*ds;

    F = evaluate_poly(cntur, P, D, ds, false);
    dP = derivate_quasipolynomial(P, D);
    dF = evaluate_poly(cntur, dP, D, ds, false);

    num_zeros = round(abs(real(sum((dF./F).*dS)/(2*pi*1i))));
end