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

Personally, I don't see the need to go any higher level than Go. It provides a high ease of development for relatively good performance. If we decide to go with a high level language, this would probably be the best option.

For lower level languages, the main candidates would be

- Rust as the memory-safe candidate,
- C++ as the memory-unsafe candidate, and
- Zig, which would
  - eliminate the low-hanging fruits that are the common footguns in C/C++ while not being entirely memory safe,
  - simple to learn, and
  - highly compatible with C, enabling easy use of C libraries.

Elixir is perhaps an honurable mention; it is a high level, functional language that is worth considering if fault-tolerance is of utmost importance.
