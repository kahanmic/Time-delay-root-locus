function roots = approximate_root_position(cont_points, values, breakpoints, ds)
% Find approximate position of roots based on zero level contures

    idxs = find(imag(values(1:end-1)).*imag(values(2:end)) < 0 | ...
        (abs(imag(cont_points(1:end-1))) < 1e-4) );
    idxs = idxs(~ismember(idxs, breakpoints));
    roots = cont_points(idxs);
end