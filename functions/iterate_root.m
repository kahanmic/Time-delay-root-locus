function newRoots = iterate_root(s0, numP, denP, D, dendP, numdP, K, dK, minStep, maxStep)
% Find new root position for given gain change dK

    num = evaluate_poly(s0, numP, D, 0.1, false);
    den = evaluate_poly(s0, dendP, D, 0.1, false) + K.*evaluate_poly(s0, numdP, D, 0.1, false);
    C = -(num./den);
    %if dK > min([minStep/min(abs(C)), maxStep/max(abs(C))])
    K = K + dK;
    ds = C*dK;
    currP = denP+K*numP;
    s0 = s0+ds;
    newRoots = newton_method(s0, currP, D, 1e-6);
end