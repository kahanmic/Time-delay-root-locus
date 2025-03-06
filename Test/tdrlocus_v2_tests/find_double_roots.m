function [s_r, K_r] = find_double_roots(s0, K0, numP, denP, D)
    P = denP+K0*numP;
    dP = derivate_quasipolynomial(P, D);

    g = [evaluate_poly(s0, P, D, 0.1, false); evaluate_poly(s0, dP, D, 0.1, false)];
    cnt = 0;
    while max(abs(g)) > 1e-5 && cnt < 100
        P = denP+K0*numP;
        dP = derivate_quasipolynomial(P, D);
        ddP = derivate_quasipolynomial(dP, D);
    
        g = [evaluate_poly(s0, P, D, 0.1, false); evaluate_poly(s0, dP, D, 0.1, false)];
        dg = [evaluate_poly(s0, dP, D, 0.1, false), evaluate_poly(s0, numP, D, 0.1, false);
            evaluate_poly(s0, ddP, D, 0.1, false), evaluate_poly(s0, derivate_quasipolynomial(numP, D), D, 0.1, false)];
        next = [s0; K0] - dg\g;
        s0 = next(1);
        K0 = next(2);
        cnt = cnt+1;
    end
    s_r = s0;
    K_r = K0;
end