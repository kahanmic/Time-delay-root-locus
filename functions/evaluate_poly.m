function H = evaluate_poly(Reg, P, D, ds, is_region)
% Evaluate quasipolynomial values for given points/meshgrid (bool is_region)

    N = size(P, 1);     % Number of delays
    n = size(P, 2);     % Order of the polynomial
    order = n - 1;
    
    if is_region    % evaluate over region or vector of points
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

    Sv = S(:);
    k = order:-1:0;
    Hv = ones(1,N)*(exp(-D*Sv.').*(P*(Sv.^k).'));

    if is_region
        H = reshape(Hv, [w b]);
    else
        H = Hv;
    end
end