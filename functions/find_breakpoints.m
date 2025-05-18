function breakpoints = find_breakpoints(Reg, numP, denP, D, ds, rePolesZeros, maxGainLim)
% Finds gain and location if there are any double poles on real axis
% Returns these gains in form of breakpoints

    numPolesZeros = length(rePolesZeros);
    breakpoints = [];
    
    for i =  1:2:numPolesZeros
        maxLim = rePolesZeros(i);
        if i+1 <= numPolesZeros
            minLim = rePolesZeros(i+1);
        else
            minLim = Reg(1);
        end

        [K0, isDoublePoles] =  contains_double_poles([minLim maxLim -0.01 0.01], numP, denP, D, ds, maxGainLim);
        if isDoublePoles
            s0 = (minLim + maxLim)/2;
            [s_r, K_r] = find_double_roots(s0, K0, numP, denP, D);

            cnt = 1;

            iter = isnan(K_r) | K_r < 0 | s_r < minLim | s_r > maxLim;

            while iter && cnt < 10
                K0 = K0 + K0/2;
                [s_r, K_r] = find_double_roots(s0, K0, numP, denP, D);
                iter = isnan(K_r) | K_r < 0 | s_r < minLim | s_r > maxLim;
                cnt = cnt+1;
            end
            if ~iter
                breakpoints = [breakpoints, K_r];
            end
        end
    end
    
end