function rePolesZeros = get_real_poles_zeros(olPoles, olZeros)
    realPoles = olPoles(imag(olPoles) == 0);
    realZeros = olZeros(imag(olZeros) == 0);
    rePolesZeros = fliplr(sort([realPoles, realZeros]));
end