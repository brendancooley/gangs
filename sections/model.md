## Model

There are $N$ districts in the city ($i, j \in \mathcal{N} = \left\{1, ..., N \right\}$). $r_i$ residents live in each district. The city is also inhabited by $K$ gangs ($k, \ell \in \mathcal{K} = \left\{1, ..., K \right\}$). Each gang is endowed with a $m_k$ soldiers. A partition function $\pi : \mathcal{N} \rightarrow \left\{ 0, \mathcal{K} \right\}$ assigns territories to the gangs that control them, where $\pi(i) = 0$ indicates the absence of any gang activity. $\mathcal{K}_k$ is the set of territories controlled by gang $k$ and $| \mathcal{K}_k |$ the number of territories controlled by gang $k$. The set of unoccupied territories is $\mathcal{K}_0$. We are interested in estimating the number of groups, $K$, and the territorial partition, $\pi$.

We observe data on geo-located shootings for $T$ periods, indexed $\left\{ 1, ..., T \right\}$. We hold the above quantities constant over time. There are three types of shootings that occur in the city -- inter-gang, intra-gang, and non-gang. Let $y_{it}$ denote non-gang related shootings in district $i$ during period $t$ and $x_{it}$ denote gang-related shootings in district $i$ during period $t$. Non-gang shootings are committed by residents with probability $eta_i$ and are independent across districts. Then, the expected number of shootings in district $i$ is $\eta_i r_i$ with variance $\eta_i (1 - eta_i) r_i$.^[In other words, non-gang shootings are distributed i.i.d. Binomial.]
  
Gang-related shootings are determined by the geographic distribution of gang activity and the state of relations between gangs. We assume the probability a given soldier from gang $k$ is operating in territory $i$ is constant and given by $| \mathcal{K}_k |^{-1}$. Members of the same gang sometimes commit violence against one another. The probability such violence occurs between members of gang $k$ during period $t$ is given by $\xi_{kt}$



The *violence potential* between a group $\pi(i)$ operating in district $i$ and another group $k$ is given by a function
\begin{equation} \label{eq:Q}
Q_i(\pi(i), k) = m_{\pi(i), i}^\alpha M_k^{1 - \alpha}
\end{equation}
$Q_i(\pi(i), k)$ is a Cobb-Douglas combination of gang $\pi(i)$'s footprint in territory $i$ and gang $k$'s total strength. This function encodes two features of the relationship between gang strength and violence outcomes: 1) if gang $\pi(i)$ has more soldiers in territory $i$, more shootings are possible there 2) if gang $k$ becomes stronger overall, it is more able to produce shootings in territory $i$. The total violence potential in territory $i$ depends on the violence potential between gang $\pi(i)$ and all other gangs $k \neq \pi(i)$.

Whether or not such potential materializes into violent conflict depends on the state of relations between gangs $\pi(i)$ and $k$. In each period, the intensity of conflict between these gangs is given by a random variable $\epsilon_{\pi(i), \ell}^t \in \mathbb{R}_{+}$. When $\epsilon_{\pi(i), k}^t = 0$ no shootings occur between members of gangs $\pi(i)$ and $k$ in period $t$. We make two assumptions regarding the distribution of the conflict shocks. 

**Assumption X:** Conflict shocks are drawn independently across gang dyads, $\E \left[ \epsilon_{\pi(i), k}^t \epsilon_{\pi(j), \ell}^t \right] - \E \left[ \epsilon_{\pi(i), k}^t  \right] \E \left[ \epsilon_{\pi(j), \ell}^t \right] = 0$.^[Of course, the intensity of conflict between any two gangs is almost certainly affected by the broader conflict environment. This assumption is made for purposes of model tractability. In future work, we plan to model the genesis of conflict shocks and perhaps relax this assumption.]

**Assumption X:** Each gang has a positive probability of fighting *at least 2* other gangs, $\E \left[ \epsilon_{\pi(i), k}^t \right], \E \left[ \epsilon_{\pi(i), \ell}^t \right] > 0$ for all $i$ and for some $k, \ell \neq \pi(i)$.

The total number of gang-related shootings in territory $i$ in period $t$ is given by the product of the shock and the violence potential between gangs each pair of gangs $\pi(i)$ and $k \neq \pi(i)$
\begin{equation} \label{eq:xi}
x_{it} = \sum_{k \neq \pi(i)} \epsilon_{\pi(i), k} Q_i(\pi(i), k)
\end{equation}

The total number of shootings in territory $i$ in period $t$ is simply the sum of gang-related and non-gang-related shootings
\begin{equation} \label{eq:vi}
v_{it} = x_{it} + y_{it}
\end{equation}

The dyadic shocks produce positive correlations in violence across districts controlled by the same gang and gangs find themselves in conflict. In the Appendix, we show the covariance in shootings between districts $i$ and $j$ is
$$
\varphi_{ij} = \Cov [v_{it}, v_{jt}] = \begin{cases}
\sum_k \Var [ \epsilon_{\pi(i), k}^t ] Q_i(\pi(i), k)^2 + \eta (1 - \eta) N_i & \text{if } i = j \\
\sum_k \Var [ \epsilon_{\pi(i), k}^t ] Q_i(\pi(i), k) Q_j(\pi(j), k) & \text{if } \pi(i) = \pi(j) \\
\Var[ \epsilon_{\pi(i), \pi(j)}^t ] Q_i(\pi(i), \pi(j)) Q_j(\pi(j), \pi(i)) & \text{if } \pi(i) \neq \pi(j) \text{ and } \pi(i), \pi(j) \neq \emptyset \\
0 & \text{otherwise}
\end{cases}
$$
In the first case, the same gang owns both districts. The magnitude of the covariance depends on the variance of the conflict shocks this gang experiences with all other gangs and the violence potential of both territories. The second case is simply the within-district variance, which is also affected by the variance in resident violence. The last case captures covariance across gang territories, which is affected by the variance of the dyadic violence shocks between gangs $\pi(i)$ and $\pi(j)$.

**Corollary X:** $\pi(i) = \pi(j) \implies \Cov [v_{it}, v_{jt}] > \Cov [v_{it}, v_{kt}]$ for all districts $k \neq \pi(i)$.

Corollary X states that the covariance in shootings within a gang's set of territories is greater in expectation than the covariance in shootings across gang territories. 

Let $\rho: \mathcal{J} \rightarrow \mathcal{J}$ be a permutation on the set of districts such that $\rho(i) < \rho(j) \iff \pi(i) < \pi(j)$ and $\rho(i) < \rho(j)$ if $\pi(i) \neq \emptyset$ and $\pi(j) = \emptyset$. Let $J_k$ denote the number of districts belonging to gang $k$ where $J_\emptyset$ is the number of districts districts without gang activity. Then, the covariance matrix $\bm{A}_{\rho} = \left( \varphi_{i, j} \right) \in \mathbb{R}_{+}^{J \times J}$ can written in block diagonal form as shown in Figure X.

## Appendix

### Covariance Derivation

The covariance in organized violence between two districts $i$ and $j$ is
\begin{align*}
\Cov [v_{it}, v_{jt}] =& \E [v_{it} v_{jt}] - \E [v_{it}] \E [v_{jt}] \\
=& \E [ (x_{it} + y_{it}) (x_{jt} + y_{jt}) ] - \E [ x_{it} + y_{it} ] \E [ x_{jt} + y_{jt} ] \\
=& \left( \E [ x_{it} x_{jt} ] + \E [ x_{it} y_{jt} ] + \E [ x_{jt} y_{it} ] + \E [ y_{it} y_{jt} ] \right) - \\
 & \left( \E [ x_{it} ] \E [ x_{jt} ] + \E [ x_{it} ] \E [ y_{jt} ] + \E [ x_{jt} ] \E [ y_{it} ] + \E [ y_{it} ] \E [ y_{jt} ] \right) \\
=& \left( \E [ x_{it} x_{jt} ] -  \E [ x_{it} ] \E [ x_{jt} ] \right) + \left( \E [ y_{it} y_{jt} ] - \E [ y_{it} ] \E [ y_{jt} ] \right) \\
=& \E \left[ \left( \sum_{k \neq \pi(i)} \epsilon_{\pi(i), k}^t Q_i(\pi(i), k) \right) \left( \sum_{\ell \neq \pi(j)} \epsilon_{\pi(j), \ell}^t Q_j(\pi(j), \ell) \right) \right] \\
& \E \left[ \sum_{k \neq \pi(i)} \epsilon_{\pi(i), k}^t Q_i(\pi(i), k) \right] \E \left[ \sum_{\ell \neq \pi(j)} \epsilon_{\pi(j), \ell}^t Q_j(\pi(j), \ell) \right] + \left( \E [ y_{it} y_{jt} ] - \E [ y_{it} ] \E [ y_{jt} ] \right) \\
=& \sum_{k \neq \pi(i)} \sum_{\ell \neq \pi(j)} \E \left[ \epsilon_{\pi(i), k}^t \epsilon_{\pi(j), \ell}^t \right] Q_i(\pi(i), k) Q_j(\pi(j), \ell) - \\ 
& \sum_{k \neq \pi(i)} \sum_{\ell \neq \pi(j)} \E \left[ \epsilon_{\pi(i), k}^t  \right] \E \left[ \epsilon_{\pi(j), \ell}^t \right] Q_i(\pi(i), k) Q_j(\pi(j), \ell) + \left( \E [ y_{it} y_{jt} ] - \E [ y_{it} ] \E [ y_{jt} ] \right) \\
=& \sum_{k \neq \pi(i)} \sum_{\ell \neq \pi(j)} \left( \E \left[ \epsilon_{\pi(i), k}^t \epsilon_{\pi(j), \ell}^t \right] - \E \left[ \epsilon_{\pi(i), k}^t  \right] \E \left[ \epsilon_{\pi(j), \ell}^t \right] \right) Q_i(\pi(i), k) Q_j(\pi(j), \ell) + \\
& \left( \E [ y_{it} y_{jt} ] - \E [ y_{it} ] \E [ y_{jt} ] \right)
\end{align*}

There are three cases to which to consider. First, let $i \neq j$ but $\pi(i) = \pi(j)$ -- the same gang owns territories $i$ and $j$. If $k = \ell$, then $\epsilon_{\pi(i), k}^t = \epsilon_{\pi(j), k}^t$ for each $k$ Otherwise, $\E \left[ \epsilon_{\pi(i), k}^t \epsilon_{\pi(j), \ell}^t \right] - \E \left[ \epsilon_{\pi(i), k}^t  \right] \E \left[ \epsilon_{\pi(j), \ell}^t \right] = 0$ by Assumption X. Since $i \neq j$ we have $\E [ y_{it} y_{jt} ] - \E [ y_{it} ] \E [ y_{jt} ] = 0$. If $i = j$ then $\pi(i) = \pi(j)$, and the within-district variance can be calculated analagously, with the exception that $\E [ y_{it} y_{jt} ] - \E [ y_{it} ] \E [ y_{jt} ] \neq 0$. Finally, let $\pi(i) = \ell$, $\pi(j) = k$, $k \neq \ell$ -- the two territories are owned by different gangs. Then, $\epsilon_{\pi(i), k}^t = \epsilon_{\pi(j), \ell}^t$. Otherwise, $\E \left[ \epsilon_{\pi(i), k}^t \epsilon_{\pi(j), \ell}^t \right] - \E \left[ \epsilon_{\pi(i), k}^t  \right] \E \left[ \epsilon_{\pi(j), \ell}^t \right] = 0$ by Assumption X. The expression above can therefore be written piecewise as in Equation \ref{eq:cov}.