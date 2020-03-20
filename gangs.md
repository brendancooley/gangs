---
title: | 
	| Gunshots and Turf Wars
	| \tiny \hfill
    | \Large Inferring Gang Territories from Administrative Data
author: 
	- name: Brendan Cooley
      affiliation: Ph.D. Candidate, Department of Politics, Princeton University
    - name: Noam Reich
      affiliation: Ph.D. Candidate, Department of Politics, Princeton University
date: \today
abstract: |
	|   Street gangs are conjectured to engage in violent territorial competition. This competition can be difficult to study empirically as the number of gangs and the division of territory between them are usually unobserved to the analyst. However, traces of gang conflict manifest themselves in police and administrative data on violent crime. In this paper, we show that the frequency and location of shootings are sufficient statistics number of gangs in operation and the territorial partition beween them under mild assumptions about the data generating processes for gang-related and non-gang related shootings. We then show how to estimate this territorial partition from a panel of geolocated shooting data. We apply our method to analyze the structure of gang territorial competition in Chicago using victim-based crime reports from the Chicago Police Department (CPD) and validate our methodology on gang territorial maps produced by the CPD. We detect the presence of 3-4 gangs whose estimated territorial footprints we match to CPD maps. After matching, 56-60 percent of our partition labels agree with those of the CPD. This performance compares favorably to an agreement rate of 35 percent when CPD labels are randomly permuted.
thanks: We thank Gleason Judd and the Empirical Studies of Conflict (ESOC) group at Princeton for feedback on an earlier version of this project. 
# jelcodes: JEL codes go here

bibliography: /Users/brendancooley/Dropbox (Princeton)/References/library.bib
biblio-style: apsr

papersize: letter
documentclass: article
geometry: margin=1.25in
link-citations: true

output:
	fig_caption: yes
    citation_package: natbib

---



\newpage

# Introduction




In 2019, 2,110 people were murdered or shot in the city of Chicago. Chicago is far from the most violent American city on a per capita basis — other large municipalities confront alarmingly high rates of interpersonal violence.  Law enforcement agencies and researchers believe much of this violence is connected to street gangs and disputes amongst their members. Between 1994 and 2006, law enforcement officials classified 35-50 percent of Chicago homicides as gang-related [@Papachristos2009; @NDIC2007].^[@Papachristos2009 reports that homicide detectives classified 35 percent of homicides as gang-related in the years 1994, 1998, and 2002. A Department of Justice report claims that 50 percent of Chicago homicides in 2006 were gang-related. According to @Howell2018, these numbers are not unusual -- other large police departments classify between 20 and 50 percent of local homicides as gang-related.] Inter-gang warfare and intra-gang violence feature prominently alongside drug-dealing in many ethnographic accounts of street gangs and their operations [@Sanchez1991; @Decker1996; @Papachristos2009; @Vargas2016]. In one oft-cited case, a gang's monthly costs of protection and aggression —- hiring mercenaries, paying tribute, procuring weapons, and staging funerals —- dwarfed the wholesale costs of all drugs sold by its dealers [@Levitt2000].

Gangs operate over well-defined territories from which they extract rents through racketeering, drug-selling monopolies, and other criminal activity [@Thrasher1927; @Sanchez1991; @Levitt2000; @Venkatesh2000]. Gangs war with one another over control of these rent streams and in response to challenges to their individual or collective reputations [@Brantingham2012; @Papachristos2013; @Ebdm2018]. Anecdotal evidence suggests that such wars are frequent and are a major source of gang-related violence [@Levitt2000]. However, our knowledge of gangs and their territorial footprints remains largely anecdotal because gangs are necessarily covert and opaque organizations. Information on gang activities or territories from law enforcement agencies is generally unavailable either because it is uncollected or because it is not shared with the public.^[The Chicago Police Department's gang maps are the most well-known and are available to researchers thanks to Freedom of Information requests by @Bruhn2019.] When such data are collected and shared, they are subject to various reporting biases and often come without the metadata necessary to assess the methods by which they were collected [@Kennedy1996; @Levitt1998; @Carr2016]. Existing open-source methodologies used to estimate gangs' territorial footprints require deep subject matter expertise that make them difficult to generalize beyond their target locale [@Sobrino2019; @Melnikov2019; @Signoret2020].

In this paper, we propose and implement a method to estimate the number of gangs operating in a given location and their territorial footprints. Our approach requires the analyst observe only the location and timing of all (gang-related and non-gang related) violent events within the area under study —- data that are widely available in administrative records on crime. We apply this method to study gangs in Chicago, a city in which a panel of gang maps produced by the Chicago Police Department (CPD) are publicly available [@Bruhn2019]. We detect the presence of 3 gangs on average, whose estimated territorial footprints correspond roughly to those of the Gangster Disciples, the Black P Stones, and the Vice Lords. While these constitute a small fraction of all gangs operating in Chicago, they are among the largest by membership and territorial extent. Together, these gangs own 57.3 percent of all gang turf in the city, according to CPD maps.

We begin by modeling the data-generating process for violent events, distinguishing between  non-gang, intra-gang, and inter-gang violence. We assume that gangs have been assigned to territories according to an unobserved partition function. In an any given period the amount of violence experienced in a particular gangs territory is a function of independent shocks. The level of intra-gang violence is determined by a shock that is common across each gang's territory, producing a pattern of violence that is common across its domain. Likewise, the level of inter-gang violence experienced any two gangs is the product of a bilateral shock, producing a pattern of violence that is common across both gangs' terriotries. By contrast, we assume that non-gang violence exhibits no spatial correlation. We show that this model generates a distinct pattern of spatial covariance in violent events and prove that this is a sufficient statistic for the underlying territorial partition. The model follows @Trebbi2019 closely. Our innovation is to generalize their approach, used to study terrorist groups in Afghanistan and Pakistan, to a setting featuring bilateral conflict between violent organizations.

Methodologically, this framework is most closely related to the literature on stochastic block models (SBMs), starting with @Holland1983. This literature partitions actors (nodes) into communities who interact with one another in a Bernoulli process according to community-dyad-specific probabilities. Various methods have been developed for "community detection" -- estimating the underlying communities from observed interactions [@Copic2009; @Jin2015]. Like @Trebbi2019, we replace the binary matrices that describe these interactions with continuous spatial covariance matrices describing the likelihood that shootings occur in a pair of locations during the same period. The model of @Trebbi2019 is akin to a special case of the SBM in which actors only interact (commit acts of violence) with members of their own community. In our model, interactions occur both within and between the underyling communities (gangs in our case).

We estimate the model on the observed spatial covariance in homicides and non-fatal shootings across Census tracts in Chicago from 2004-2017. Our data come from victim-based crime reports from the Chicago Police Department. Our estimation procedure is comprised of two steps. First, we estimate the number of gangs by iteratively estimating the model, holding the number of gangs fixed, until out-of-sample fit ceases to improve. We proceed to estimate the territorial partition following @Lei2015. This returns the set of census tracts belonging to each gang, as well as the "peaceful" set of territories in which no gang operates. It also produces estimates for the parameters relating to the intensity of between- and within-group conflict. We quantify our uncertainty surrounding the territorial partition and these parameters through non-parametric bootstrap, sampling the set of homicides and non-fatal shootings with replacement and re-estimating the number of gangs and the territorial partition amongst them. 

We permute our most-likely census tract labels to best-approximate a smoothed (over time) map of gang territories and peaceful tracts produced by the CPD. We then compare our estimated partition to the CPD gang maps. In 95 percent of bootstrap iterations, 56-60 percent of our census tract labels agree with those of the CPD.^[These agreement ratios are constructed by permuting our labels to most-closely match those of the CPD.] Random permutations of the CPD's labels produce agreement in only 35 percent of cases.

We leverage "spectral" estimators developed in the statistics literature to estimate our model [@Luxberg2007; @Jin2015; @Lei2015; @Chen2018]. These estimators exploit the relationship between an eigen-decomposition of the spatial covariance matrix and the underlying parameters. In doing so, they render the estimation problem solvable via k-means clustering. @Lei2015 provide conditions under which these estimators are asymptotically consistent for the parameters of the SBM *in the number of nodes*. We are not aware of any papers studying the properties of these estimators, applied to the covariance matrix, in the number of *periods*. We estimate the number of gangs in operation using the cross-validation approach of @Chen2018, which iteratively estimates model parameters on rectangular subsets of the covariance matrix and predicts held-out covariances under different assumptions about the underlying number of communities.^[Here we also depart from the approach of @Trebbi2019, who employ permutation tests on the geographic proximity of within-community locations to estimate the number of communities. Given the strong non-convexity of gang territory in Chicago [@Bruhn2019], we sought a more flexible approach.]

Substantively this paper joins a growing literature seeking to measure the territorial distribution of gangs. Previous work has relied on mixed method techniques which seek to invest human capital in gathering information though archival work or interviews. @Signoret2020 successfully use such methods to map cartel presence in Northern Mexico and @Blattman2019 in Colombia. However, these methods are very costly and only produce results limited to a particular locale. Some researchers have sought to automate this process via natural processing techniques, sacrificing accuracy in favor of speed. For example, @Sobrino2019 uses text analysis techniques to produce a dichotomous measure of cartle presence for Mexican cities. By contrast, our method is both granular and low cost.

The paper proceeds as follows. We first briefly review the substantive and methodological literature upon which our paper builds. We then describe the crime data and CPD gang maps, used for estimation and validation, respectively. Section IV introduces our model and derives the spatial covariance structure used for estimation. We develop our estimators for the number of gangs and the territorial partition in Section V. We present our results and validate them on the CPD gang maps in Section VI before concluding.

# Data




![ \label{fig:cpd_ethnic}](figure/unnamed-chunk-11-1.png)

# Model














