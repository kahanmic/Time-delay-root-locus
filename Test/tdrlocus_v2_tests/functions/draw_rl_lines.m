function lines = draw_rl_lines(reg, gainLim, clZeros, clPoles, numP, denP, D, numdP, dendP, ds, minStep, maxStep)
    K = 0;    
    

    % case when poles go from infinity to open loop zeros
    if length(clZeros) > length(clPoles) 
        cnt = 0;
        dK = 1e-8;
        reg(1) = -50;
        currRoots = compute_roots(reg, denP+K*numP, D, ds);
        while length(currRoots) < length(clZeros)
            if mod(cnt, 10) == 0
                dK = dK*10;
            end
            K = K+dK;
            currRoots = compute_roots(reg, denP+K*numP, D, ds);
            cnt = cnt+1;
        end
        poles = currRoots;
        reg(1) = min(real(poles));
    else
        poles = clPoles;
    end
    
    rePolesZeros = get_real_poles_zeros(clPoles, clZeros);
    breakpoints = [sort(find_breakpoints(reg, numP, denP, D, ds, rePolesZeros)), gainLim];
    dK = 0.1;
    for maxK = breakpoints
        poles = [poles; draw_rl_lines_section(poles(end,:), K, maxK, numP, denP, D, dendP, numdP, ds, minStep, maxStep)];
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