function H = evaluate_poly(Reg, P, D, ds, first_run)
    N = size(P, 1);     % Number of delays
    n = size(P, 2);     % Order of the polynomial
    order = n - 1;
    
    if first_run
        bmin = Reg(1); bmax = Reg(2); wmin = Reg(3); wmax = Reg(4);
        beta=bmin:ds:bmax;  
        omega=wmin:ds:wmax;
    
        b = length(beta);
        w = length(omega);
        
        [B, W]=meshgrid(beta,omega);
        S = B+W.*1i;    % origin is on the left bottom corner
    else
        S = Reg;
    end

    S2 = S(:);
    k = order:-1:0;
    Hv = ones(1,N)*(exp(-D*S2.').*(P*(S2.^k).'));

    if first_run
        H = reshape(Hv, [w b]);
    else
        H = Hv;
    end
end