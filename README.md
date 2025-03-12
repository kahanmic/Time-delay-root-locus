# Time-delay-root-locus
This is MATLAB tool for Root locus of time-delay systems.
Users may use this tool for any personal project, although the tool is still in development and may not work correctly. 
This tool works in classic MATLAB interface, no additional toolboxes are needed. 

QPmR algorithm from prof. Ing. Tomáš Vyhlídal, Ph.D. is used for root finding.

The tool was delepoed on MATLAB R2024b version, older version of MATLAB may not be compatible.

## How to work with tool

This tool is able to draw root locus of time delay systems

$$ H(s) = \frac{h_\mathrm{num}(s)}{h_\mathrm{den}(s)} $$

where $h_\mathrm{num}(s)$ and $h_\mathrm{den}(s)$ represent quasipolynomials in form of

$$ 
h(s) = \sum^{N} p_\mathrm{i} e^{-\alpha_\mathrm{i}s}
$$

The tool is callable by tdrlocus().
It can be called without any arguments, the clear workspace is then opened and region for computing open loop poles and zeroes is automatically set to Re = [-10,5] and Im = [0, 50]. If you want to draw the root locus for given system when calling the function, it must be in from of: tdrlocus(reg, numerator, denominator) or tdrlocus(reg, numP, numD, denP, denD). 

Argument region is a vector of length 4 that specifies thresholds of [minReal maxReal minImag maxImag]. Negative minImag values are unnecessary, positive half of the imaginary complex plane is mirrored to the negative on. 

Arguments numerator and denominator must be string values written in form of "(poly1)\*exp(-delay1\*s)+(poly2)\*exp(-delay2\*s)+...+(polyN)\*exp(-delayN\*s)". It is recommended to write polynomials in brackets and omit "\*exp(-0\*s)", in that case write only "(poly)". It is mandatory to use "+" outside the brackets. 

Arguments numP, numD, denP, denD must be matrix notations of quasipolynomial. \
The P matrix represents coefficients of polynomials

$$
P =
\begin{bmatrix}
\beta_\mathrm{11} & \beta_\mathrm{12} & \cdots & \beta_\mathrm{1n} \\
\beta_\mathrm{21} & \ddots & & \vdots \\
\vdots & & & \vdots \\
\beta_\mathrm{N1} & ... & ... & \beta_\mathrm{Nn}
\end{bmatrix}
$$

and D matrices represent delays of quasipolynomials

$$
D =
\begin{bmatrix}
\alpha_\mathrm{1}  \\
\alpha_\mathrm{2} \\
\vdots \\
\alpha_\mathrm{N}
\end{bmatrix}
$$

Each row in P matrix, k = 1,...,N is specific for given delay and each column l = 1,...,n specifies coefficient for given order of monomial. Coefficient l = 1 is tied to s^(n-1), ... l = n is coefficient of a constant. Values of D matrix represent delays. \
"num" and "den" specifies numerator or denominator quasipolynomial. Numerator and denominator matrices may not have same delays.


