
We seek an estimate for $\Theta$ that minimizes the proportion of misclassified districts, up to label permutations. Such a $\hat{\Theta}$ solves
$$
\min_{\hat{\Theta} \in \mathbb{M}^{N \times K}, P \in \mathbb{P}^{K \times K} } N^{-1} \lVert \hat{\Theta} P - \Theta \rVert_0
$$
where $\lVert M \rVert_0$ sums nonzero entries in $M$.




*need to add noise to $\bar{A}$ before we define the estimation problem*