# A* Pathfinding algorithm written in WebAssembly

Yup. Handwritten. In. WebAssembly.
Documentation soon because my eyes are seeing smells rn.

Oh yeah, and also use the `--enable-mutil-memory` flag beacuase this utilizes mutiple `memory` slots for lists and structs.

And if you can optimize the `Node` structure by using an `i32x4` instead of  2 `i64`s that would be very appreciated.
Would warn you about the casting from `i64` to `i32` tho. 

If anyone can tell me what the `i32x4.extend_i16x8_high_u` do, HOW?!!
