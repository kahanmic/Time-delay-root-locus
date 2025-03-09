function poly = matrix2string(P, D)
    [numDelays, maxOrder] = size(P);
    poly = '';
    for i = 1:numDelays
        if any(P(i,:))
            poly = strcat(poly, '(');
            for j = 1:maxOrder
                
                if P(i,j) ~= 0
                    if poly(end) ~= '(' && P(i,j) > 0
                        poly = strcat(poly, '+');
                    end
                    poly = strcat(poly, num2str(P(i,j)), '*s^', num2str(maxOrder-j));
    
        
                    % "s^1" -> "s" and "s^0" -> ""
                    if j == maxOrder-1
                        poly = poly(1:end-2);
                    elseif j == maxOrder
                        poly = poly(1:end-4);
                    end
                end
            end
            poly = strcat(poly, ')');
    
            if D(i) ~= 0
                poly = strcat(poly, '*exp(-', num2str(D(i)), '*s)');
            end
    
            if i < numDelays && any(any(P(i+1:end,:)))
                poly = strcat(poly, '+');
            end
        end
    end
end