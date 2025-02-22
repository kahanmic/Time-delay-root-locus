function roots = approximate_root_position(cont_points, values, breakpoints, ds)

    idxs = find(imag(values(1:end-1)).*imag(values(2:end)) < 0 | (abs(imag(cont_points(1:end-1))) < 1e-4) );
    idxs = idxs(~ismember(idxs, breakpoints))
    cont_points(idxs)
    %idxs = idxs(abs( imag(cont_points(idxs(1:end-1)) - cont_points(idxs(2:end)) ) )> ds);
    roots = cont_points(idxs);
end