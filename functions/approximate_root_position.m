function roots = approximate_root_position(contPointsRe, valuesRe, contPointsIm, valuesIm, breakpoints, ds)
% Find approximate position of roots based on zero level contures

    idxsRe = find(imag(valuesRe(1:end-1)).*imag(valuesRe(2:end)) < 0 | ...
        (abs(imag(contPointsRe(1:end-1))) < 1e-4) );
    idxsRe = idxsRe(~ismember(idxsRe, breakpoints));
    idxsIm = find(abs(real(valuesIm))< 1e-4);

    roots = [contPointsRe(idxsRe), contPointsIm(idxsIm)];
end