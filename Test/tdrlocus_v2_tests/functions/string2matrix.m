function [P, D] = string2matrix(str)
%string2matrix function converts quasipolynomial string to matrix notation
% Rules are that each part of quasipolynomial corresponding to given
% exponential must be in brackets (for example (3*s^3+s^2+4)*exp(...) +
% (...)*exp(...)) and every polynomial closed in brackets must have "+"
% sign in front of it

    str = erase(str, ' ');  % Delete white spaces
    str = regexprep(str, '\.(?=[*\^])', '');    % removes every dot before '*' and '^'
    find_exp = regexp(str, 'exp\([^)]*\)', 'match');    % find all exp(...)
    polys = split(str, find_exp);   % Splits by all exponents by "exp(...)"
    
    polys = polys(polys ~= ""); % deletes empty strings ("")
    delays = [];

    for expn = find_exp % finding delays for each polynomial
        str_delay = string(erase(expn, ["exp(", ")", "s", "*", "-"])); 
        if str_delay == ""  % case: exp(-s)
            delays(end+1) = 1;
        else
            delays(end+1) = str2double(str_delay);
        end
    end
    delays(end+1) = 0;
    
    pol_info = {};  % array of coefficients and delay for the quasipolynomial
    orders = [];
    for i = 1:length(polys)
        delay = delays(i);
        poly = polys(i);  % split by exp(...)

        % for a+b*exp() or a+exp()
        if count(poly, "(") == 0 && (count(poly, "+") > 0 || count(poly, "-") > 0) && length(delays) > 1

            ch_pol = char(poly);
            
            % Asuming there is exponent
            if ch_pol(end) ~= '*' % case ...+exp(...)
                poly = [string(ch_pol(1:end-1)); "1"];
            else % TODO: case ...-exp(...),     (-s ign)
                poly = string(ch_pol(1:end-1)); % erase "*" at the end
                poly = split(poly, "+");
            end
            
        end


        poly = split(poly, ["(", ")"]); % gets each polynomial in the bracket (...)+(...)
        poly = poly(poly ~= "+" & poly ~= "" & poly ~= "*"); % clears from "*" etc
        coefs = [];
        if length(poly) > 1 % case (...) + (...)
            const_coefs = get_poly_coefs(poly(1));
            coefs = get_poly_coefs(poly(2));
            orders(end+1) = length(const_coefs);
            pol_info{end+1} = struct('coefs', const_coefs, 'delay', 0);
            
        else % case (...)
            ch_pol = char(poly);
            if ch_pol(end) == '*' 
                poly = string(ch_pol(1:end-1));
            end
            coefs = get_poly_coefs(poly);
        end
        orders(end+1) = length(coefs);
        pol_info{end+1} = struct('coefs', coefs, 'delay', delay);
    end
    N = length(orders);
    n = max(orders);
    
    P = zeros(N, n);
    D = zeros(N, 1);
    
    for i = 1:N
        P(i, n + 1 - orders(i):end) = pol_info{i}.coefs;
        D(i) = pol_info{i}.delay;
    end

% -------------- Get coefficient vector function -----------------------
function coefs = get_poly_coefs(poly)
    poly = string(poly); % must be string
    poly = erase(poly, " ");
    max_order = 0;
    monomials = {};
    
    poly = erase(poly, ["(", ")"]); % get rid of brackets
    [new_str, match] = split(poly, ["+", "-"]); % split to monomials and get sign
    
    new_str = new_str(new_str ~= "");   % adjusting output
    num_monomes = length(new_str);
    if num_monomes > length(match)
        match = ["+"; match];
    end
    
    for i = 1:num_monomes
        cur_poly = strcat(match(i), new_str(i));
        [coef, order] = get_monomial_info(cur_poly);
        monomials{end+1} = struct('coef', coef, 'order', order);
        if order > max_order
            max_order = order;
        end
    end
    
    coefs = zeros(1, max_order+1);
    
    for info = monomials
        coefs(max_order+1 - info{1}.order) = info{1}.coef;
    end
end 
% -------------- end get_poly_coefs function -----------------------

% ------ Get coefficient and power of monomial function ------------------
function [coef, order] = get_monomial_info(poly)
    pattern = 's\^?(\d*)';
    [order_str, match] = regexp(poly, pattern, 'tokens', 'match');
    
    if isempty(match)
        order = 0;
        coef = str2double(string(poly));
    else
        if isempty(order_str{1}{1}) % get order
            order = 1;
        else
            order = str2double(string(order_str{1}));
        end
        
        cof = erase(char(poly), [match, '*']);
        coef = detect_coef(cof);

    end % constant check
end % function
% -------------- end get_monomial_info function -----------------------

% -------------- Coefficient check -----------------------
function gain = detect_coef(str_gain)
    str_gain = string(str_gain);
    if str_gain == "" | str_gain == "+"
        gain = 1;
    elseif str_gain == "-"
        gain = -1;
    else
        gain = str2double(str_gain);
    end
end 
% -------------- end detect_gain function -----------------------

end
