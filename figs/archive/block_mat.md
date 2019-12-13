$$
\bm{A}_{\rho} = \begin{bNiceArray}{CCCCC}
\overmat{\pi(i) = 1}{\begin{bmatrix}
    & & \\
    & \bm{A}_{\rho, 11}^{J_1 \times J_1} & \\
    & & 
\end{bmatrix}} & \overmat{\pi(i) = 2}{\begin{bmatrix}
    & & \\
    & \bm{A}_{\rho, 12}^{J_1 \times J_2} & \\
    & & 
\end{bmatrix}} & \cdots & \overmat{\pi(i) = J}{\begin{bmatrix}
    & & \\
    & \bm{A}_{\rho, 1N}^{J_1 \times J_N} & \\
    & & 
\end{bmatrix}} & \bm{0} \\
\begin{bmatrix}
    & & \\
    & \bm{A}_{\rho, 21}^{J_2 \times J_1} & \\
    & & 
\end{bmatrix} & \begin{bmatrix}
    & & \\
    & \bm{A}_{\rho, 22}^{J_2 \times J_2} & \\
    & & 
\end{bmatrix} & \cdots & \vdots & \bm{0} \\
\vdots & \vdots & \ddots & \vdots & \bm{0} \\
\begin{bmatrix}
    & & \\
    & \bm{A}_{\rho, N1}^{J_N \times J_1} & \\
    & & 
\end{bmatrix} & \cdots & \cdots & \begin{bmatrix}
    & & \\
    & \bm{A}_{\rho, NN}^{J_N \times J_N} & \\
    & & 
\end{bmatrix} & \bm{0} \\
\bm{0} & \bm{0} & \bm{0}  & \bm{0} & \undermat{\pi(i) = \emptyset}{\begin{bmatrix}
    \varphi_{\rho_i, \rho_i} & \cdots & \bm{0} \\
    \vdots & \ddots & \vdots \\
    \bm{0} & \cdots & \varphi_{\rho_J, \rho_J} 
    \end{bmatrix}}
\end{bNiceArray}
$$