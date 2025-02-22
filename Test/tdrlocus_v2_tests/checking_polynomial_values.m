P=[1.5 0.2 0 20.1;1 0 -2.1 0;0 0 3.2 0;0 0 0 1.4];
D=[0;1.3;3.5;4.3];
bmin = -30; bmax = 15; wmin = -5; wmax = 30;
%ds = ((bmax-bmin)*(wmax-wmin))/2000;
ds = 0.1;
beta=bmin:ds:bmax;  
omega=wmin:ds:wmax;
%%
% original calculations
tic

[B W]=meshgrid(beta,omega);
S=B+j*W;
rad=length(P(1,:))-1;   % rad polynomu
poczp=length(D);     % pocet zpozdeni
for k1=1:rad+1    % Sp 3D, pro každý řád se mocní hodnota na meshgridu
   Sp(k1,:,:)=S.^(k1-1);
end

MM=zeros(size(S));
for k1=1:poczp    % iterace pres vsechna zpozdeni
   M=zeros(size(S));
   for m=1:rad+1    % iterace pres vsechny rady
       M=M+squeeze(Sp(m,:,:))*P(k1,rad+2-m); % squeeze udela z 3D matice 2D matici (beru m-ty rad), P jen jedna hodnota?
   end
   MM=MM+M.*exp(-D(k1)*S);
end


toc
%%
% Adjusted (3x faster)
tic

H2 = evaluate_poly([bmin bmax wmin wmax], P, D, ds, true);  % first poly evaluation 

Cr = contourc(beta,omega,real(H2),[0 0]);   % 0 level contour of real part
%Ci = contourc(beta,omega,imag(H2),[0 0]);

[lens, points_re] = extract_contours(Cr);  
%[~, points_im] = extract_contours(Ci);

cs = cumsum(lens);
Hr = evaluate_poly(points_re, P, D, ds, false);     % evaluating poly values on contours
roots = approximate_root_position(points_re, Hr, cs, ds);   % detecting roots


toc
%plot(real(points_re(a(22):a(23))), imag(points_re(a(22):a(23))))
%H3(a(22):a(23))

%%


figure
%[Ci,Hi]=contour(beta,omega,imag(MM),[0 0],'r');
grid on 
hold on;
[Cr,Hr]=contour(beta,omega,real(MM),[0 0],'r');


[Ci,Hi]=contour(beta,omega,imag(H2),[0 0],'g');
hold on;
[Cr,Hr]=contour(beta,omega,real(H2),[0 0],'b--');
plot(real(roots), imag(roots), 'rx', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'LineWidth', 1.5);
%title("Zero level values of quasipolynomial real part")
%title("Zero level values of quasipolynomial imaginary part")
%legend("Original QPmR", "Vectorization of the calculation")
xlabel("Re(s)")
ylabel("Im(s)")
% -> 5x az 8x rychlejsi vypocet hodnot
