function [realLim, lines] = draw_rl_lines(reg, gainLim, clZeros, clPoles, numP, denP, D, numdP, dendP, ds, minStep, maxStep)
% Computes lines of root locus

    K = 0;    
    rePolesZeros = get_real_poles_zeros(clPoles, clZeros);
    breakpoints = [sort(find_breakpoints(reg, numP, denP, D, ds, rePolesZeros)), gainLim];

    % case when poles go from infinity to open loop zeros
    if length(clZeros) > length(clPoles) 
        cnt = 0;
        dK = 1e-8;
        reg(1) = -50;
        [~, currRoots] = compute_roots(reg, denP+K*numP, D, ds);
        while length(currRoots) < (length(clZeros) - length(breakpoints) + 1) && cnt < 1e5 % not sure about < (...)
            if mod(cnt, 10) == 0
                dK = dK*10;
            end
            K = K+dK;
            [~, currRoots] = compute_roots(reg, denP+K*numP, D, ds);
            cnt = cnt+1;
        end
        poles = currRoots;
        reg(1) = min(real(poles));
    else
        poles = clPoles;
    end
  
    dK = 0.1;
    sections = cell(size(breakpoints)); % break lines into sections
    sectionHeighs = zeros(size(breakpoints));
    sectionWidths = zeros(size(breakpoints));   
    
    i = 1;
    for maxK = breakpoints
        poles = [poles; draw_rl_lines_section(poles(end,:), K, maxK, numP, denP, D, dendP, numdP, ds, minStep, maxStep)];
        K = maxK + dK;
        sections{i} = poles;
        sectionHeighs(i) = size(poles, 1);
        sectionWidths(i) = size(poles, 2);

        if K < gainLim
            [~, poles] = compute_roots(reg, denP + K*numP, D, ds);
        end
        i = i+1;
    end
    
    tmpLines = draw_spliting_rl(sections, sectionHeighs, sectionWidths);
    
    maxLim = min([50, max(real(tmpLines(imag(tmpLines) <= reg(4))))+1 ]);
    minLim = max([-50, min(real(tmpLines(imag(tmpLines) <= reg(4))))-1 ]);
    realLim = [minLim, maxLim];

    numLines = size(tmpLines, 2);
    lines = cell(numLines, 1);
    for i = 1:numLines
        lines{i} = tmpLines(:, i);
    end
    
    
end