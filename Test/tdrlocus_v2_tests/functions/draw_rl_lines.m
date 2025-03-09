function lines = draw_rl_lines(reg, gainLim, clZeros, clPoles, numP, denP, D, numdP, dendP, ds, minStep, maxStep)
    K = 0;
    dK = 0.1;
    poles = clPoles;

    rePolesZeros = get_real_poles_zeros(clPoles, clZeros);
    breakpoints = [sort(find_breakpoints(reg, numP, denP, D, ds, rePolesZeros)), gainLim];
    for maxK = breakpoints
        poles = [poles; draw_rl_lines_section(poles(end,:), K, maxK, reg, numP, denP, D, dendP, numdP, ds, minStep, maxStep)];
        K = maxK + dK;
        if K < gainLim
            poles = [poles; compute_roots(reg, denP + K*numP, D, ds)];
        end
    end
    
    numLines = size(poles, 2);
    lines = cell(numLines, 1);
    for i = 1:numLines
        lines{i} = poles(:, i);
    end
    
end