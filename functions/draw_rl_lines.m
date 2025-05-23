function [realLim, lines] = draw_rl_lines(reg, gainLim, olZeros, olPoles, numClPoles, numP, denP, D, numdP, dendP, ds, minStep, maxStep)
% Computes lines of root locus
    maxStep = min([maxStep, 1]);
    rePolesZeros = get_real_poles_zeros(olPoles, olZeros);
    breakpoints = [sort(find_breakpoints(reg, numP, denP, D, ds, rePolesZeros)), gainLim];
    [~, K] = get_num_of_branches(reg, numP, denP, D, ds);

    % case when poles go from infinity to open loop zeros
    % if length(olZeros) > length(olPoles)
    %     cnt = 0;
    %     dK = 1e-6;
    %     %reg(1) = -50;
    %     [~, currRoots] = compute_roots(reg, denP+K*numP, D, ds, 1);
    %     while length(currRoots) < (length(olZeros) - length(breakpoints) + 1) && cnt < 1e5 % not sure about < (...)
    %         if mod(cnt, 10) == 0
    %             dK = dK*10;
    %         end
    %         K = K+dK;
    %         [~, currRoots] = compute_roots(reg, denP+K*numP, D, ds, 1);
    %         cnt = cnt+1;
    %     end
    %     poles = currRoots;
    %     %reg(1) = min(real(poles));
    % elseif length(olPoles) < numClPoles
    %     cnt = 0;
    %     dK = 1e-6;
    %     %reg(1) = -50;
    %     [~, currRoots] = compute_roots(reg, denP+K*numP, D, ds, 1);
    %     while length(currRoots) < numClPoles && cnt < 1e5 % not sure about < (...)
    %         if mod(cnt, 10) == 0
    %             dK = dK*10;
    %         end
    %         K = K+dK;
    %         [~, currRoots] = compute_roots(reg, denP+K*numP, D, ds, 1);
    %         cnt = cnt+1;
    %     end
    %     poles = currRoots;
    % else
    %     poles = olPoles;
    % end
    K
    [~, poles] = compute_roots(reg, denP+K*numP, D, ds, 1)

    dK = 0.01;
    sections = cell(size(breakpoints)); % break lines into sections
    sectionHeighs = zeros(size(breakpoints));
    sectionWidths = zeros(size(breakpoints));   
    
    i = 1;
    
    for maxK = breakpoints
        %if any(evaluate_poly(poles(end,:), dendP, D, NaN, false) == 0)
        %    newPoles = compute_roots(reg, denP + (K+0.1)* numP, D, ds, 5);
        %end
        poles = [poles; draw_rl_lines_section(poles(end,:), K, maxK, numP, denP, D, dendP, numdP, ds, minStep, maxStep)];
        K = maxK + dK;
        sections{i} = poles;
        sectionHeighs(i) = size(poles, 1);
        sectionWidths(i) = size(poles, 2);

        if K < gainLim
            [~, poles] = compute_roots(reg, denP + K*numP, D, ds, 1);
        end
        i = i+1;
    end
    tmpLines = draw_spliting_rl(sections, sectionHeighs, sectionWidths);
    
    maxLim = min([50, max(real(tmpLines(imag(tmpLines) <= reg(4)))) + 1 ]);
    minLim = max([-50, min(real(tmpLines(imag(tmpLines) <= reg(4)))) - 1 ]);
    realLim = [minLim, maxLim];

    numLines = size(tmpLines, 2);
    lines = cell(numLines, 1);
    for i = 1:numLines
        lines{i} = tmpLines(:, i);
    end
    
    
end