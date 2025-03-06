function dK =  get_dk(s0, K0, numP, numdP, dendP, D, ds)
    den = evaluate_poly(s0, numP, D, 0.1, false);
    num = evaluate_poly(s0, dendP, D, 0.1, false) + K0.*evaluate_poly(s0, numdP, D, ds, false);
    C = -(num./den);
    dK = real(C*ds); % Should be real by default by sometimes it returns 0i
end