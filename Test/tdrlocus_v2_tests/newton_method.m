function roots = newton_method(initial_guess, P, D, ds, de)
%NEWTON_METHOD is a function that makes finds quasipolynomial roots with
%desired precision
%   Detailed explanation goes here
    x0 = initial_guess;
    PD = derivate_quasipolynomial(P, D);
    
    for i = 1:10
        Pi = evaluate_poly(x0, P, D, ds, false);
        x0 = x0-(Pi)./(evaluate_poly(x0, PD, D, ds, false));
        if max( abs(zeros(size(Pi)) - Pi) < de )
            break
        end
    end
    
    roots = x0;
end

