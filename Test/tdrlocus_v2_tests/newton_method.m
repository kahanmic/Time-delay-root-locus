function roots = newton_method(initial_guess, P, D, de)
%NEWTON_METHOD is a function that makes finds quasipolynomial roots with
%desired precision

    x0 = initial_guess;
    PD = derivate_quasipolynomial(P, D);
    
    for i = 1:100
        Pi = evaluate_poly(x0, P, D, 0.1, false);
        x0 = x0-(Pi)./(evaluate_poly(x0, PD, D, 0.1, false));
        if max( abs(zeros(size(Pi)) - Pi) < de )
            break
        end
    end
    
    roots = x0;
end

