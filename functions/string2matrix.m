function [P, D] = string2matrix(str)
%string2matrix function converts quasipolynomial string to matrix notation
    
    s = sym('s');
    polyInfo = {};
    poly = str2sym(str);
    polyExpanded = expand(poly);

    % find unique exponentials
    exps = str2sym(regexp(string(polyExpanded), 'exp\([^)]*\)', 'match'));
    unique_exps = unique(exps);
    
    if isempty(unique_exps) % if classic polynomial
        qpolys = {polyExpanded};
        expDel = 0;
    elseif length(unique_exps) == 1 % if poly*exp(...) vs poly+exp(...)
        delTest = getDelay(unique_exps);
        isSimpleQpoly = isempty(regexp(string(simplify(polyExpanded/exp(-delTest*s))), 'exp\([^)]*\)', 'match'));
        if isSimpleQpoly
            qpolys = {polyExpanded};
            expDel = delTest;
        else
            polyCollected = collect(polyExpanded, unique_exps);
            [qpolys, expDel] = testConversion(polyCollected);
        end
    else
        polyCollected = collect(polyExpanded, unique_exps);
        [qpolys, expDel] = testConversion(polyCollected);
    end
    
    numDelays = length(qpolys);
    
    % delay values
    widthP = 0;
    for i = 1:numDelays
        currDel = expDel(i);
        polyInfo(i).delay = currDel;
        currCoef = double(coeffs(simplify(qpolys{i}/exp(-currDel*s)), 'All'));
        if length(currCoef) > widthP
            widthP = length(currCoef);
        end
        polyInfo(i).coef = currCoef;
    end


    P = zeros(numDelays, widthP);
    D = zeros(numDelays, 1);
    
    for i = 1:numDelays
        P(i, widthP-length(polyInfo(i).coef)+1:end) = polyInfo(i).coef;
        D(i) = polyInfo(i).delay;
    end


    function [terms, expDels] = testConversion(polyCollected)
        terms = children(polyCollected);
        expDels = [];
        k = 1;
        for i = 1:length(terms)
            term = terms(i);
            strTerm = string(term);
            matches = str2sym(regexp(string(term), 'exp\([^)]*\)', 'match'));
            unique_matches = unique(matches);
            if length(unique_matches) > 1
                delSum = 0;
                for match = unique_matches
                    strDel  = erase(string(match),  ["exp(", ")", "s", "*"]);
                    if strDel == "-"
                        del = 1;
                    elseif strDel == ""
                        del = -1;
                    else
                        del = -double(strDel);
                    end
                    delSum = delSum + del;
                    strTerm = erase(strTerm, "*"+string(match));
                end
                strTerm = strcat(strTerm, "*exp(-", num2str(delSum),"*s)");
                terms{i} = str2sym(strTerm);
                expDels(end+1) = delSum;
            else
                del = getDelay(unique_matches);
                expDels(end+1) = del;
                k = k+1;
            end 
        end
    end

    function del = getDelay(expTerm)
        strDel = erase(string(expTerm),  ["exp(", ")", "s", "*"]);
        if strDel == "-"
            del = 1;
        elseif strDel == ""
            del = -1;
        elseif ~isempty(strDel)
            del = -double(strDel);
        else
            del = 0;
        end
    end
end
