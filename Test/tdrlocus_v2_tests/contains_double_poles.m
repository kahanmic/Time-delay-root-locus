function hasDoublePoles = contains_double_poles(Reg, numP, denP, D, ds)
    gains = [0, logspace(1, 5, 5)];
    numRoots = [];
    for K = gains
        P = denP + K*numP;
        numRoots = [numRoots, argp_integral(Reg, P, D, ds)];
    end
    hasDoublePoles = (prod(numRoots) == 0) && (sum(numRoots) > 0);
end