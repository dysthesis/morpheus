# Scope

This document describes the goals and non-goals of this project.

## Goals

### Double ratchet encryption of the in-game chat

The [Double Ratchet algorithm](https://signal.org/docs/specifications/doubleratchet/) is a state-of-the-art message encryption algorithm, notably used by Signal. An aim of the project is to implement message encryption on the in-game chat with this algorithm, which we would implement ourselves, rather than relying on a third-party implementation.

While the common wisdom would be to never roll your own crypto, that only applies in general, when minimum risk to security is necessary. This project is intended to be, to a certain degree, vulnerable. Therefore, a home-made implementation of the algorithm is suitable for this project. This would serve to

- demonstrate the issues with rolling your own crypto, and
- allow students to practice auditing a potentially errorneous implementation of a cryptographic algorithm implemented by a non-expert.

> [!NOTE]
> It appears that a true end-to-end-encrypted chat may necessitate a custom client.
