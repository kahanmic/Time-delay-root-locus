function poles = draw_rl_lines_section(s0, K0, gainLim, reg, numP, denP, D, dendP, numdP, ds, minStep, maxStep)
    poles = s0;
    cnt = 0;
    maxCnt = round(100/minStep);
    K = K0;

    while K < gainLim && cnt < maxCnt
        
        num = evaluate_poly(s0, numP, D, ds, false);
        den = evaluate_poly(s0, dendP, D, ds, false) + K.*evaluate_poly(s0, numdP, D, ds, false);
        C = -(num./den);

        dK = min([minStep/min(abs(C)), maxStep/max(abs(C))]); % needs to be checked
        % if mod(cnt, 5) == 0
        %     K = K + dK;
        %     bmin = min(real(s0)) - 2*ds; bmax = max(real(s0)) + 2*ds;
        %     nreg = [bmin bmax reg(3)-ds reg(4)+ds];
        %     s0 = compute_roots(nreg, denP + K*numP, D, ds);
        % else
        
            if dK > (gainLim-K0)/10 % at least 10 points
                dK = (gainLim-K0)/10;
            end
    
            K = K + dK;
            
            ds = C*dK;
            currP = denP+K*numP;
            s0 = s0+ds;
            s0 = newton_method(s0, currP, D, 1e-6);
        % end

        poles = [poles; s0];
        if gainLim >= 1e10 
            cnt = cnt + 1;
        end
    end
end