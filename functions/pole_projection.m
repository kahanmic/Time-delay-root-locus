function rootPos = pole_projection(s0, K0, numP, denP, numdP, dendP, D, sVec)
% Vector projection of approximate ds

    num = evaluate_poly(s0, numP, D, 0.1, false);
    den = evaluate_poly(s0, dendP, D, 0.1, false) + K0.*evaluate_poly(s0, numdP, D, 0.1,  false);
    C = -(num./den);
    v1 = [real(C); imag(C)];
    v2 = [real(sVec), imag(sVec)];
    
    rootPos = dot(v1, v2)/dot(v1, v1)*C;
    %rootPos = s0 + rProj;   
end