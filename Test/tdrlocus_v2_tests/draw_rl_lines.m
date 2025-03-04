function lines = draw_rl_lines(gainLim, clZeros, clPoles, numP, denP, D, numdP, dendP, ds, minStep, maxStep, numRealPoles, numRealzeros)
    K = 0;
    roots = clPoles;
    poles = roots;
    lines = {};
    
    cnt = 0;
    maxCnt = round(100/maxStep);

    while K < gainLim && cnt < maxCnt
        num = evaluate_poly(roots, numP, D, ds, false);
        den = evaluate_poly(roots, dendP, D, ds, false) + K.*evaluate_poly(roots, numdP, D, ds, false);
        C = -(num./den);

        dK = max([minStep/min(abs(C)), maxStep/max(abs(C))]); % needs to be checked

        K = K + dK;
        ds = C*dK;
        currP = denP+K*numP;
        roots = roots+ds;
        roots = newton_method(roots, currP, D, ds, 1e-6);
        poles = [poles; roots];
        cnt = cnt + 1;
    end
    
    numLines = size(poles, 2);
    lines = cell(numLines, 1);
    for i = 1:numLines
        lines{i} = poles(:, i);
    end
    
end