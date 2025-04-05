function [P, D] = string2matrix(str)
%string2matrix function converts quasipolynomial string to matrix notation
    
    s = sym('s');
    polyInfo = {};
    poly = str2sym(str);
    polyExpanded = expand(poly);

    % find unique exponentials
    exps = str2sym(regexp(string(polyExpanded), 'exp\([^)]*\)', 'match'));
    unique_exps = unique(exps);

    polyCollected = collect(polyExpanded, unique_exps);
    qpolys = children(polyCollected);
    [qpolys, expDel] = testConversion(polyCollected);
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
                strDel = erase(string(unique_matches),  ["exp(", ")", "s", "*"]);
                if strDel == "-"
                    del = 1;
                elseif strDel == ""
                    del = -1;
                elseif ~isempty(strDel)
                    del = -double(strDel);
                else
                    del = 0;
                end
                expDels(end+1) = del;
                k = k+1;
            end 
        end
    end
end
