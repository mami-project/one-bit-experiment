# Abstract
Whether explicit cooperation between Content & Service Providers (CSP) and the Mobile Network constitutes an effective strategy to get the best achievable scores in terms of Quality of Experience (QoE) for end users, device energy consumption, and utilization of RAN resources, is an argument that has been debated at length – see for example [draft-nrooney-marnew-report], [ACCORD], [ISOC-AC-Dallas], [draft-mm-wg-effect-encrypt].

The topic has become of great importance since large volumes of internet traffic have started migrating from clear-text to encrypted and multiplexed flows, thus preventing the mobile network to leverage *implicit* cooperation from the endpoints.  However, as often happens when experimental data is lacking, the conversation around this topic has morphed into a sterile fight between two polarized factions, and is currently stalled.

The authors aim at bringing the discussion back to life by providing a way to collect data in form of a fully automated and thus easily reproducible experimental framework that will allow any third party to run the test cases, collect, analyze and publish the relevant data using their own equipment in their own labs.

# Introduction 
The scope of this paper is to document the design and implementation of a fully automated experimental framework (including test setup, test cases execution, data collection, data analysis and publication) aimed at comparing the effect of cooperative vs non-cooperative schemes on end users’ QoE.  The framework is released as an open-source IaS [XXX?] that is explicitly versioned, allowing at the same time evolution and unambiguous reproducibility of the experiments.

The authors believe that, by making the experiments trivial to replicate, a significant number of datasets can be collected by multiple parties. This has two main consequences: on one side, it allows independent verification when the same exact setup is used, thus improving confidence in the results.  On the other side, it provides a valuable tool for interested parties, e.g., Mobile Network Operators, for benchmarking different vendors’ equipment with regards to its behaviour in a well-defined set of scenarios.

The open-source nature of the framework encourages independent groups to evolve the framework and maybe contribute their changes back upstream.

One per section:
Section TODO provides a brief intro on QoE in the 3GPP suite.
The cooperative and non-cooperative schemes are based on [draft-you-tsvwg-latency-loss-tradeoff] and Active Queue Management (AQM) techniques [TODO-REFs] respectively.
The measures will be taken at varying levels of congestion in the radio access network (RAN).
The modelling of flows that will be benchmarked for QoE as well as the background traffic is discussed in section TODO


# QoE in 3GPP
QoE is a first-class concept in the 3GPP protocol suite.  A core assumption that underpins 3GPP’s QoE model is that similar applications have same requirements in terms of their loss and latency budgets.  Therefore, it is possible to slice the application space into pre-defined tubes that cluster same applications.  3GPP calls these tubes “bearers”.
A bearer is essentially a tunnel that spans the radio and internal packet core segments of a 3GPP network.  Each bearer is associated with a given QoS class id (QCI) that precisely defines the loss and latency targets and scheduling priority for all the traffic that flows through that “tube”.  Each element in the mobile network is aware of the bearers’ QCIs and acts so to guarantee that the loss and latency targets are met.  In the radio segment, the QCI is used to inform the decisions taken by the radio scheduler that resides within the eNodeB.

# Default bearer
When a device attaches to the mobile network, it is given a so-called *default* bearer.  Apart from a few exceptions, Mobile Network Operators configure their networks so that all the traffic in and out the public internet is carried over the default bearer. This lack of differentiation is due to fear of net-neutrality, perceived setup / configuration complexity, and the fact that default bearer latency and loss targets are ok for best-effort services (file downloads, email and web browsing) but not so good for interactive traffic (thus penalizing of voice/video OTT apps…)

# (Near) congestion effects

Pen and paper modelling done by B-L colleagues

# Baseline Performance
An user is watching a live video stream, is having (video) call, or is playing an online multiplayer video game while attached to the mobile network.
We want to measure how her experience changes varying the congestion level in the RAN.
In the baseline experiment, the network is doing no traffic management.

# Explicit Cooperation with 1-bit
todo

## QoE in 3GPP 101
todo


## Typical Configuration
todo

## Experimental Setup
todo

# No Cooperation (0-bit)
todo

## AQM 101
todo

## Experimental Setup
todo



# Conclusions & Future work
- Add  energy efficiency and radio resource utilization measurements.
[TODO-EDIT] In [Nguyen], the authors explore the behaviour of TCP flows that go through different kinds of handover in LTE.  They find that seamless handover is low-latency friendly whereas lossless handover helps with high-throughput / low-loss flows.  A topic of future extension of this would be an evaluation of the impact of the 1-bit mechanism on QoE of flows that go through handover.


# Biblio
- [draft-you-tsvwg-latency-loss-tradeoff] J. You et al., “Latency Loss Tradeoff PHBGroup”, https://datatracker.ietf.org/doc/draft-you-tsvwg-latency-loss-tradeoff/
- [Nguyen] http://delivery.acm.org/10.1145/2630000/2627594/p41-nguyen.pdf
- [draft-nrooney-marnew-report] N. Rooney, “IAB Workshop on Managing Radio Networks in an Encrypted World (MaRNEW) Report”
- [ACCORD] “Alternatives to Content Classification for Operator Resource Deployment (accord) (BOF)”, https://www.ietf.org/proceedings/95/accord.html
- [ISOC-AC-Dallas] IETF#92 Dallas: ISOC Advisory Council, Informal meeting discuss encryption
- [draft-mm-wg-effect-encrypt] TODO

