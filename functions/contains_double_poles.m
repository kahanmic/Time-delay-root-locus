function [K0, hasDoublePoles] = contains_double_poles(Reg, numP, denP, D, ds, maxGainLim)
% Find out if there are any poles splits
    mG = log10(maxGainLim);
    gains = [0, 1, logspace(1, round(mG), round(mG))];
    %gains = [linspace(0, 9.9, 1000), linspace(10, 99, 90), logspace(2, 8, 7)];
    numRoots = zeros(size(gains));
    for i = 1:length(gains)
        K = gains(i);
        P = denP + K*numP;
        numRoots(i) = argp_integral(Reg, P, D, ds);
    end
    changeIdx = find(diff(numRoots) ~= 0, 1, 'first');
    
    if isempty(changeIdx)
        K0 = 0;
        hasDoublePoles = false;
    else
%        diffs = diff(numRoots);
%        if abs(diffs(changeIdx)) < 2 % needs to fix when pole comes from infinity
%            K0 = 0;
%            hasDoublePoles = false;
%        else
            K0 = gains(changeIdx);
            hasDoublePoles = true;
%        end
    end
end