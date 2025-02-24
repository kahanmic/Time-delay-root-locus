%syms s
clc
% Define the given polynomial expression
% only rules: Expnonetials after polynomials, "+" sign for (...) + (...)e^s
%expr = (1.5*s^3 + 0.2*s^2 + 20.1) + (s^3 - 2.1*s)*exp(-s*1.3) + 3.2*s*exp(-s*3.5) + 1.4*exp(-s*4.3);

expr = "1.5*s^3 + 0.2*s^2 + 20.1 + (s^3 - 2.1*s)*exp(-s*1.3) + 3.2*s*exp(-s*3.5) + 1.4*exp(-s*4.3)";
%expr = "1.5*s^3 + 0.2*s^2 + 20.1";
% 1. erase spaces
expr = erase(expr, ' ');

% 2. find all exp(...)
find_exp = regexp(expr, 'exp\([^)]*\)', 'match');


% 3. split string by found exponentials
polys = split(expr, find_exp);

polys = polys(polys ~= ""); % deletes empty strings ("")

delays = [];
for expn = find_exp
    str_delay = string(erase(expn, ["exp(", ")", "s", "*", "-"])); % finding delay
    if str_delay == ""
        delays(end+1) = 1;
    else
        delays(end+1) = str2double(str_delay);
    end
end
delays(end+1) = 0;

% 
% poly = split(poly, ["(", ")"]);
% poly = poly(poly ~= "+" & poly ~= "" & poly ~= "*")
pol_info = {};
orders = [];
for i = 1:length(polys)
    delay = delays(i);
    poly = polys(i);
    poly = split(poly, ["(", ")"]);
    poly = poly(poly ~= "+" & poly ~= "" & poly ~= "*");
    coefs = [];
    if length(poly) > 1
        const_coefs = get_poly_coefs(poly(1));
        coefs = get_poly_coefs(poly(2));
        orders(end+1) = length(const_coefs);
        pol_info{end+1} = struct('coefs', const_coefs, 'delay', 0);
        
    else
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

% -------------- function -----------------------
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
end % function
% -------------- end function -----------------------


% -------------- function -----------------------
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
        coef = detect_gain(cof);

    end % constant check
end % function
% -------------- end function -----------------------

% -------------- function -----------------------
function gain = detect_gain(str_gain)
    str_gain = string(str_gain);
    if str_gain == "" | str_gain == "+"
        gain = 1;
    elseif str_gain == "-"
        gain = -1;
    else
        gain = str2double(str_gain);
    end
end 
% -------------- end function -----------------------
