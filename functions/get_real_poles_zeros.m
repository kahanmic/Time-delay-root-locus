function rePolesZeros = get_real_poles_zeros(olPoles, olZeros)
% Find real poles/zeros among all the poles/zeros

    realPoles = olPoles(imag(olPoles) == 0);
    realZeros = olZeros(imag(olZeros) == 0);
    rePolesZeros = fliplr(sort([realPoles, realZeros]));
end