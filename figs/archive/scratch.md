\begin{bmatrix}
        \begin{bmatrix} \varphi_{11} \end{bmatrix} & \cdots & \bar{\varphi}_{1j} \\
        \vdots & \ddots & \vdots \\
        \bar{\varphi}_{i1} & \cdots & \begin{bmatrix} \varphi_{ii} \end{bmatrix}
\end{bmatrix}


$$
\bm{A} = \begin{bmatrix}
    \overmat{ \bm{A}_{11} }{\begin{bmatrix}
    & & \\
    & \left\{ \varphi_{ij} : \pi(i) = \pi(j) = 1 \right\} & \\
    & &
    \end{bmatrix}} & \overmat{ \bm{A}_{12} }{\begin{bmatrix}
    & & \\
    & \left\{ \varphi_{ij} : \pi(i) = 1, \pi(j) = 2 \right\} & \\
    & &
    \end{bmatrix}} \\
    0 & 0 
\end{bmatrix}
$$

$$
\bm{A}_{\rho} = \begin{bNiceArray}{CCCC}[first-row,first-col]
& & \left\{ \rho(\mathcal{J}) \right\} & & \\
    & \begin{bmatrix}
        & & \\
        & \bm{A}_{\rho, 11}^{J_1 \times J_1} & \\
        & & 
    \end{bmatrix} & \begin{bmatrix}
        & & \\
        & \bm{A}_{\rho, 12}^{J_1 \times J_2} & \\
        & & 
    \end{bmatrix} & \cdots & \bm{0}  \\
\left\{ \rho(\mathcal{J}) \right\} & 
    \begin{bmatrix}
        & & \\
        & \bm{A}_{\rho, 21}^{J_2 \times J_1} & \\
        & & 
    \end{bmatrix} & \begin{bmatrix}
        & & \\
        & \bm{A}_{\rho, 22}^{J_2 \times J_2} & \\
        & & 
    \end{bmatrix} & \vdots & \bm{0} \\
& \vdots & \vdots & \ddots & \bm{0} \\
& \bm{0} & \bm{0} & \bm{0} & \bm{0}
\end{bNiceArray}
$$