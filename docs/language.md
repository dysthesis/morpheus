# Language

This document explores the options of languages to use for this project.

In general, there are two key characteristics that are essential for this project, namely

- the level of abstraction, and
- memory safety.

It should also be noted that there is a correlation between these two factors, as higher level languages tend to be more memory safe, since they would have features such as garbage collection to automatically manage memory.

## Level of abstraction

In general, higher level languages tend to be easier to develop in, as they tend to have batteries included. The higher-level a language is, the less implementation details one need to concern themselves with. For instance, one does not need to worry about memory management in a high-level language, and these languages tend to have more extensive standard libraries that contain reasonable implementations of common data structures and algorithms.

The trade-off tends to be performance. These abstractions often come with their own costs. For instance, a lack of memory management concerns is commonly afforded by a garbage collector, and a lack of synchronisation concerns is afforded by a [global interpreter lock](https://wiki.python.org/moin/GlobalInterpreterLock). As such, languages without these abstractions tend to be faster by a good margin.

### Considerations

Ultimately, the trade-off is between ease of development and performance. If we do not expect to support a large number of concurrent players, then high level languages would be reasonable chocies, such as Python, Java, or Elixir. If we do, however, then we would necessarily have to use low level languages, such as Rust, Zig, or C++. A good middle ground would be languages such as Go, which is relatively simple to use while still being quite performant.

## Memory safety

In general, the option between memory-safe and memory-unsafe languages would be clear in isolation; it would be foolish to pass up on additional safety. However, since the intent of this project is to provide an educational environment on exploitation, we may want to consider introducing memory vulnerabilities.

However, using memory-safe languages adds a degree of realism; there is a trend nowadays of shifting towards more memory safe languages. Using memory safe languages would therefore be more of a realistic environment for students, and would force them to consider other classes of vulnerabilities, such as logic vulnerabilities or social engineering.

## Conclusion

For prototyping attempts, I am going with Zig. It is easier to get things done in, as there are less rules. It is also, in my opinion, the best choice of language among the candidates, as it has a good level of memory safety that it's not easy to find memory vulnerabilities in, while not making it outright impossible to do so, and it is easy to onboard new developers who may not know any of these languages, as it is relatively simple to learn.
