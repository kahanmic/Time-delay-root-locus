function [K0, hasDoublePoles] = contains_double_poles(Reg, numP, denP, D, ds)
% Find out if there are any poles splits

    gains = [0, 1, logspace(1, 8, 8)];
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
        K0 = gains(changeIdx);
        hasDoublePoles = true;
    end
end