function PD = derivate_quasipolynomial(P, D)
    n = size(P, 2);
    N = size(P, 1);
    PD = [zeros(N, 1), P(:, 1:end-1).*(n-1:-1:1)] - P.*D;
end
