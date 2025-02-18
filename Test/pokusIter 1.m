b = [0 1 2];
a = [3 4 5];

bdot = [0 1];
adot = [6 4];

K0 = 2;
x0 = roots(a + K0*b)

polyval(a,x0) + K0*polyval(b,x0);

dK = 0.1;
for i=1:10
    b0 = polyval(b,x0);
    a0 = polyval(a,x0);
    adot0 = polyval(adot,x0);
    bdot0 = polyval(bdot,x0);
    %dx = -b0.*dK ./ (adot0+bdot0);
    dx = (K0.*b0 - (K0+dK).*b0)./(adot0+(K0+dK).*bdot0);
    x0 = x0+dx;
    plot(roots(a + (K0+dK)*b), 'bo'); hold on;
    %x0 = x0+2*dx
    K0 = K0+dK;
    plot(x0,'rx'); 
    
    
end

K0 = 4;
x0 = roots(a + K0*b);

polyval(a,x0) + K0*polyval(b,x0);

dK = -0.1;
%%
for i=1:10,
   
    K0 = K0+dK; 
    figure(1); hold on; plot(roots(a + K0*b), 'bo');

    b0 = polyval(b,x0); a0 = polyval(a,x0); adot0 = polyval(adot,x0); bdot0 = polyval(bdot,x0);
    dx = -b0.*dK ./ (adot0+bdot0);
    %x0 = x0+dx;
    x0 = x0+2*dx;

    figure(1); hold on; plot(x0,'rx'); hold on; 
    
    
end
